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

@testset "deepcopy" begin
    p = GAP.evalstr("(1,2,3)")
    @test copy(p) === p

    l = GAP.evalstr("[[]]")
    @test !(copy(l) === l)
    @test copy(l)[1] === l[1]
    @test !(deepcopy(l)[1] === l[1])

    l = [p, p]
    cp = deepcopy(l)
    @test !(l === cp)
    @test cp[1] === cp[2]

    # The following is NOT what we want,
    # eventually we want that `deepcopy` to be applied
    # also to Julia subobjects of GAP objects.
    # As soon as this changed behaviour is available,
    # `deepcopy` for GAP objects should become documented.
    l = GAP.evalstr("[]")
    li = [1, 2, 3]
    l[1] = li
    cp = deepcopy(l)
    @test !(deepcopy( li ) === li)
    @test cp[1] === l[1]
end

@testset "GapObj" begin
    io = IOBuffer();
    print(io, GAP.GapObj)
    @test String(take!(io)) == "GapObj"

    L = [ GAP.evalstr( "()" ) ]
    print(io, L)
    @test String(take!(io)) == "GapObj[GAP: ()]"

    ioc = IOContext(io, :module => nothing);
    print(ioc, GAP.GapObj)
    @test String(take!(io)) == "GAP_jll.GapObj"
end
