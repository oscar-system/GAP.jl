@testset "iteration" begin
    l = GAP.evalstr("[1, 2, 3]")
    lj = collect(l)
    @test lj isa Vector{Any}
    @test lj == [1, 2, 3]
    lj = collect(Int, l)
    @test lj isa Vector{Int}
    @test lj == [1, 2, 3]

    s = GAP.Globals.SymmetricGroup(3)
    xs = []
    for x in s
        push!(xs, x)
    end
    @test length(xs) == 6
end
