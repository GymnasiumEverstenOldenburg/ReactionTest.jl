using ReactionTest
using Documenter

DocMeta.setdocmeta!(ReactionTest, :DocTestSetup, :(using ReactionTest); recursive=true)

makedocs(;
    modules=[ReactionTest],
    authors="Alexander Reimer <alexander.reimer2357@gmail.com> and contributors",
    sitename="ReactionTest.jl",
    format=Documenter.HTML(;
        canonical="https://GymnasiumEverstenOldenburg.github.io/ReactionTest.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/GymnasiumEverstenOldenburg/ReactionTest.jl",
    devbranch="main",
)
