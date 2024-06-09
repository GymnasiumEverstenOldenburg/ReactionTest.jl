using ReactionTest

println("Was ist dein Name?")
name = readline()

iterations = 0
while true
    println("Wie viele Runden willst du machen? (>0)")
    global iterations = tryparse(Int, readline())
    if iterations !== nothing && iterations > 0
        break
    end
end

tr = TestRound(name, [penguin_image, whistle_edited_sound])
play(tr, iterations)