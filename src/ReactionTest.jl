module ReactionTest

export TestRound, play, whistle_sound, penguin_image

using GLMakie
GLMakie.activate!(; focus_on_show=true, float=true, fullscreen=true)
using FileIO
using Observables

const ASSETS_PATH = joinpath(@__DIR__, "assets")

abstract type Test end

struct TestRound
    name::String
    tests::Vector{T where T<:Test}
    screen::GLMakie.Screen
    figure::Figure
    current_img::Observables.Observable{Matrix}
    img_visible::Observables.Observable{Bool}
    sound_playing::Observables.Observable{Bool}
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
    tr = TestRound(
        name,
        tests,
        GLMakie.Screen(; resolution=primary_resolution()),
        Figure(;
        # resolution=primary_resolution()
    ),
        Observable(Matrix{GLMakie.ColorTypes.RGB}(undef, 100, 100)),
        Observable(false),
        Observable(false),
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
    cmd = `vlc $(filepath(sound)) --play-and-exit --no-interact -Idummy`
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

testname(test::SoundTest) = "sound"
testname(test::ImageTest) = "image"

whistle_sound = SoundTest("whistle", joinpath(ASSETS_PATH, "whistle-flute-1.wav"))
penguin_image = ImageTest("Penguin", joinpath(ASSETS_PATH, "penguin.jpg"))

# from https://discourse.julialang.org/t/makie-figure-resolution-makie-primary-resolution-deprecated/93854/4
function primary_resolution()
    monitor = GLMakie.GLFW.GetPrimaryMonitor()
    videomode = GLMakie.MonitorProperties(monitor).videomode
    width, height = videomode.width, videomode.height
    width, height = convert(Int64, width), convert(Int64, height)
    return (width, height)
end

function play(tr::TestRound, iters::Int)
    # close_window(tr)
    sleep(0.5)
    display(screen(tr), tr.figure)
    finished = Observable(false)
    on(events(scene(tr)).keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.space
            finished[] = true
        end
    end
    for i in 1:iters
        test = rand(tr.tests)
        finished[] = false
        if test isa SoundTest
            show(test, tr)
        end
        if test isa ImageTest
            show(test, tr)
        end
        start_time = time()
        @info "Started"
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
        @info "Done: $(stop_time - start_time)"
    end
end

end
