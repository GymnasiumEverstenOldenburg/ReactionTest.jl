sudo snap install julia --classic
julia -e 'using Pkg; Pkg.add("https://github.com/GymnasiumEverstenOldenburg/ReactionTest.jl")'
curl https://github.com/GymnasiumEverstenOldenburg/ReactionTest.jl/blob/main/scripts/compare_sound_image.jl -o compare_sound_image.jl

julia -ie "include("compare_sound_image.jl")"

# open text file with results
xdg-open results.txt
