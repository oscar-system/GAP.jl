# the test setup and code in this file are based on stdlib/REPL/test/replcompletions.jl
using GAP.REPL.REPLCompletions
using GAP.REPL

function map_completion_text(completions)
    c, r, res = completions
    return map(completion_text, c), r, res
end

test_complete(s) = map_completion_text(@inferred(completions(s,lastindex(s))))

@testset "REPL completions" begin

# completing on GAP.Globals works out of the box
let s = "GAP.Globals.MT"
    c, r = test_complete(s)
    @test "MTX" in c
    @test r == 13:14
    @test s[r] == "MT"
end

# completing on members of GAP.Globals requires some hacking (see `globals.jl`)
let s = "GAP.Globals.MTX.IsI"
    c, r = test_complete(s)
    @test length(c) == 2
    @test "IsIndecomposable" in c
    @test r == 17:19
    @test s[r] == "IsI"
end

let s = "GAP.Globals.MTX.IsInd"
    c, r = test_complete(s)
    @test length(c) == 1
    @test "IsIndecomposable" in c
    @test r == 17:21
    @test s[r] == "IsInd"
end

# completing a non-record does nothing
let s = "GAP.Globals.fail."
    c, r = test_complete(s)
    @test isempty(c)
    @test r == 18:17
    @test s[r] == ""
end

end
