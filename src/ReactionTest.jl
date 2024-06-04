module ReactionTest

export TestRound, play, whistle_sound, penguin_image

using GLMakie
using FileIO
using Observables

const ASSETS_PATH = joinpath(@__DIR__, "assets")

abstract type Test end

struct ImageTest <: Test
    name::String
    image::Matrix#{GLMakie.ColorTypes.RGB}
end

ImageTest(name::String, file_path::String) = ImageTest(name, FileIO.load(file_path))

struct Sound
    filepath::String
end
filepath(sound::Sound) = sound.filepath
function play(sound::Sound; async=true)
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
testname(test::SoundTest) = "sound"
testname(test::ImageTest) = "image"

whistle_sound = SoundTest("whistle", joinpath(ASSETS_PATH, "whistle-flute-1.wav"))
penguin_image = ImageTest("Penguin", joinpath(ASSETS_PATH, "penguin.jpg"))

struct TestRound
    name::String
    tests::Vector{T where T<:Test}
    figure::Figure
    current_img::Observables.Observable{Matrix}
    img_visible::Observables.Observable{Bool}
end
axis(tr::TestRound) = tr.figure.content[1]

function TestRound(name::String, tests::Vector{T where T<:Test})
    tr = TestRound(
        name,
        tests,
        Figure(),
        Observable(Matrix{GLMakie.ColorTypes.RGB}(undef, 100, 100)),
        Observable(false),
    )
    # empt
    image(tr.figure[1, 1], tr.current_img; visible=tr.img_visible)
    hidedecorations!(axis(tr))
    return tr
end

function play(tr::TestRound, iters::Int)
    display(tr.figure)
    for i in 1:iters
        sleep(2)
        test = tr.tests[rand(1:length(tr.tests))]
        if test isa SoundTest
            play(test.sound)
        end
        if test isa ImageTest
            tr.current_img[] = test.image
            tr.img_visible[] = true
            reset_limits!(axis(tr))
            notify(tr.current_img)
            sleep(1)
            tr.img_visible[] = false
        end
    end
end
# Write your package code here.

end
