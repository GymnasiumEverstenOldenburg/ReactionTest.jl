using ReactionTest
using ReactionTest.CSV
using ReactionTest.DataFrames

dir = joinpath(pwd(), "..", "..")
files = readdir(dir)
df = DataFrame()
for filename in files
    filepath = joinpath(dir, filename)
    if split(filename, ".")[end] == "csv"
        loaded_df = CSV.read(filepath, DataFrame, delim='\t')
        append!(df, loaded_df)
    end
end

tr = TestRound("Alle", [penguin_image, whistle_edited_sound])
tr.data = df
play(tr, 0)