module ReactionTest

export TestRound, play, whistle_sound, penguin_image, whistle_edited_sound

using GLMakie
GLMakie.activate!(; focus_on_show=true, float=true, fullscreen=true)
using FileIO
using Observables
using DataFrames
using CSV
using Dates
using Statistics

const ASSETS_PATH = joinpath(@__DIR__, "assets")

abstract type Test end

mutable struct TestRound
    name::String
    tests::Vector{T where T<:Test}
    figure::Figure
    current_img::Observables.Observable{Matrix}
    img_visible::Observables.Observable{Bool}
    sound_playing::Observables.Observable{Bool}
    data::DataFrame
end
testrunning(tr::TestRound) = tr.img_visible[] || tr.sound_playing[]
axis(tr::TestRound) = tr.figure.content[1]
scene(tr::TestRound) = tr.figure.scene
screen(tr::TestRound) = tr.screen
function close_window(tr::TestRound)
    GLMakie.GLFW.SetWindowShouldClose(GLMakie.to_native(screen(tr)), true)
    return nothing
end

function TestRound(name::String, tests::Vector{T}) where {T<:Test}
    df = DataFrame(;
        starttime=Float64[],
        name=String[],
        testtype=String[],
        testname=String[],
        missed=Bool[],
        reactiontime=Float64[],
        loadingtime=Float64[],
    )
    tr = TestRound(
        name,
        tests,
        Figure(;
        # resolution=primary_resolution()
    ),
        Observable(Matrix{GLMakie.ColorTypes.RGB}(undef, 100, 100)),
        Observable(false),
        Observable(false),
        df,
    )
    # empt
    image(tr.figure[1, 1], tr.current_img; visible=tr.img_visible)
    hidedecorations!(axis(tr))
    return tr
end

struct ImageTest <: Test
    name::String
    image::Matrix#{GLMakie.ColorTypes.RGB}
end

ImageTest(name::String, file_path::String) = ImageTest(name, FileIO.load(file_path))

function show(img::ImageTest, tr::TestRound; duration=1)
    @async begin
        while tr.img_visible[]
            sleep(0.0001)
        end
        tr.current_img[] = img.image
        tr.img_visible[] = true
        reset_limits!(axis(tr))
        notify(tr.current_img)
        sleep(duration)
        tr.img_visible[] = false
    end
end

struct Sound
    filepath::String
end
filepath(sound::Sound) = sound.filepath
function play(sound::Sound; async=false)
    if Sys.iswindows()
        cmd = `"C:\\Program Files\\VideoLAN\\VLC\\vlc" "$(filepath(sound))" --play-and-exit --no-interact -Idummy`
    else
        cmd = `vlc "$(filepath(sound))" --play-and-exit --no-interact -Idummy`
    end
    run(cmd; wait=!async)
    return nothing
end

struct SoundTest <: Test
    name::String
    sound::Sound
end
function SoundTest(name::String, file_path::String)
    return SoundTest(name, Sound(file_path))
end
function show(st::SoundTest, tr::TestRound)
    while testrunning(tr)
        sleep(0.00001)
    end
    tr.sound_playing[] = true
    @async begin
        play(st.sound)
        tr.sound_playing[] = false
    end
end

typename(test::SoundTest) = "Ton"
typename(test::ImageTest) = "Bild"

whistle_sound = SoundTest("Pfeife", joinpath(ASSETS_PATH, "whistle-flute-1.wav"))
empty_sound = SoundTest("Nichts", joinpath(ASSETS_PATH, "shortest.wav"))
whistle_edited_sound = SoundTest(
    "Pfeife (vorne gekürzt)", joinpath(ASSETS_PATH, "whistle-flute-1-edited.wav")
)
penguin_image = ImageTest("Pinguin", joinpath(ASSETS_PATH, "penguin.jpg"))

# from https://discourse.julialang.org/t/makie-figure-resolution-makie-primary-resolution-deprecated/93854/4
function primary_resolution()
    monitor = GLMakie.GLFW.GetPrimaryMonitor()
    videomode = GLMakie.MonitorProperties(monitor).videomode
    width, height = videomode.width, videomode.height
    width, height = convert(Int64, width), convert(Int64, height)
    return (width, height)
end

function dataprint(io::IOStream, df::DataFrame; prefix="")
    println(io, prefix * "Gesamtzahl Tests: $(length(df[:, 1]))")
    println(io, prefix * "Verpasste Tests: $(sum(df.missed))")
    println(io, prefix * "Durchschnittliche Reaktionszeit: $(mean(df.reactiontime))")
    println(io, prefix * "Median der Reaktionszeit: $(median(df.reactiontime))")
    println(io, prefix * "Kleinste Reaktionszeit: $(minimum(df.reactiontime))")
    println(io, prefix * "Größte Reaktionszeit: $(maximum(df.reactiontime))")
    return nothing
end

function data_evalutation(tr::TestRound)
    if Sys.iswindows()
        filename = joinpath(
            "..",
            "..",
            "reactiontest_$(Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS"))_$(tr.name)",
        )
    else
        filename = joinpath(
            "reactiontest_$(Dates.format(Dates.now(), "yyyy-mm-ddTHH-MM-SS"))_$(tr.name)"
        )
    end
    CSV.write(filename * ".csv", tr.data; delim='\t')
    empty!(tr.figure)
    ax = Axis(tr.figure[1, 1])
    colors = [:red, :blue, :green, :yellow]
    open(filename * ".txt"; create=true, write=true) do io
        println(io, "Reaktionszeitanalyse für $(tr.name)")
        println(
            io, "Alle Zeiten sind in Sekunden, die Ladezeiten wurden bereits abgezogen."
        )
        println(io, "INSGESAMT")
        dataprint(io, tr.data; prefix="\t")
        xcoord = 1
        for testtype in Set(tr.data.testtype)
            println(io, "")
            println(io, "TESTART: $testtype")
            type_df = tr.data[tr.data.testtype .== testtype, :]
            testnames = Set(type_df.testname)
            if length(testnames) <= 1
                println(io, "\tTestname: $(first(testnames))")
            end
            dataprint(io, type_df; prefix="\t")
            if length(testnames) > 1
                for testname in testnames
                    println(io, "\tTESTNAME: $testname")
                    dataprint(io, type_df[type_df.testname .== testname, :]; prefix="\t\t")
                end
            end
            reactiontimes = type_df.reactiontime
            avg = mean(reactiontimes)
            scatter!(
                ax,
                [xcoord for i in eachindex(reactiontimes)],
                reactiontimes;
                markersize=20,
                color=colors[xcoord],
                label=testtype,
            )
            scatter!(ax, [xcoord], [avg]; marker=:xcross, markersize=30, color=:black)
            println("$testtype: x = $xcoord")
            xcoord += 1
        end
    end
    axislegend(ax)
    return nothing
end

function play(tr::TestRound, iters::Int)
    display(tr.figure)
    finished = Observable(false)
    on(events(scene(tr)).keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.space
            finished[] = true
        end
    end
    while !finished[]
        sleep(0.00001)
    end
    finished[] = false
    if iters > 0
        sleep(1 + rand() * 1)
    end
    for i in 1:iters
        test = rand(tr.tests)
        finished[] = false
        loading_time = 0
        if test isa SoundTest
            start_time = time()
            play(empty_sound.sound)
            loading_time = time() - start_time
            show(test, tr)
        end
        if test isa ImageTest
            show(test, tr)
        end
        start_time = time()
        missed = false
        while !finished[]
            sleep(0.00001)
            if time() - start_time >= 2.0
                @warn "Missed input!"
                missed = true
                finished[] = true
            end
        end
        stop_time = time()
        push!(
            tr.data,
            (
                start_time,
                tr.name,
                typename(test),
                test.name,
                missed,
                stop_time - start_time - loading_time,
                loading_time,
            ),
        )
        sleep(1.5 + rand() * 2)
    end
    data_evalutation(tr)
    return filename
end

end
