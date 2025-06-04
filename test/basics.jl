#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##

@testset "basics" begin
    @test GAP.CSTR_STRING(GAP.Globals.String(GAP.Globals.PROD(2^59, 2^59))) ==
          "332306998946228968225951765070086144"

    l = GapObj([1, 2, 3])

    @test l[1] == 1
    @test l[end] == 3
    @test firstindex(l) == 1
    @test lastindex(l) == 3

    x = GAP.NewPlist(0)
    x[1] = 1
    @test x[1] == 1
    @test length(x) == 1

    x = GAP.NewPrecord(0)
    x.a = 1
    @test x.a == 1

    xx = GapObj([1, 2, 3])
    @test_throws ErrorException xx[4]

    @test string(GapObj("x")) == "x"

    # equality and hashing
    x = GAP.evalstr("[]")
    y = GAP.evalstr("[]")
    @test !(x === y)
    @test (x == y)
    @test_throws ErrorException hash(x)

    x = GAP.evalstr("Z(2)")
    y = GAP.evalstr("Z(4)^3")
    @test !(x === y)
    @test (x == y)
    @test_throws ErrorException hash(x)
end

@testset "globals" begin

    @test Symbol("Print") in propertynames(GAP.Globals, false)
    @test hasproperty(GAP.Globals, :Print)
    @test !hasproperty(GAP.Globals, :foobar)

    @test_throws ErrorException GAP.Globals.FOOBARQUX

    str = GAP.gap_to_julia(String, GAP.ValueGlobalVariable("IdentifierLetters"))
    @test str == "0123456789@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"

    @test GAP.CanAssignGlobalVariable("Read") == false
    @test GAP.CanAssignGlobalVariable("foobar")

    GAP.AssignGlobalVariable("foobar", 42)

    @test GAP.ValueGlobalVariable("foobar") == 42
    @test GAP.Globals.foobar == 42

    GAP.AssignGlobalVariable("foobar", false)
    @test GAP.ValueGlobalVariable("foobar") == false
    @test GAP.Globals.foobar == false

    GAP.AssignGlobalVariable("foobar", "julia_string")
    @test GAP.ValueGlobalVariable("foobar") == "julia_string"
    @test GAP.Globals.foobar == "julia_string"

    @test hasproperty(GAP.Globals, :foobar)
    GAP.Globals.foobar = nothing
    @test !hasproperty(GAP.Globals, :foobar)

    @test string(GAP.Globals) == "\"table of global GAP objects\""
end

@testset "gapcalls" begin
    f = GAP.evalstr("{x...} -> x")

    @test GapObj([]) == f()
    @test GapObj([1]) == f(1)
    @test GapObj([1, 2]) == f(1, 2)
    @test GapObj([1, 2, 3]) == f(1, 2, 3)
    @test GapObj([1, 2, 3, 4]) == f(1, 2, 3, 4)
    @test GapObj([1, 2, 3, 4, 5]) == f(1, 2, 3, 4, 5)
    @test GapObj([1, 2, 3, 4, 5, 6]) == f(1, 2, 3, 4, 5, 6)
    @test GapObj([1, 2, 3, 4, 5, 6, 7]) == f(1, 2, 3, 4, 5, 6, 7)

    @test [] == Vector{String}(f())
    @test ["1"] == Vector{String}(f("1"))
    @test ["1", "2"] == Vector{String}(f("1", "2"))
    @test ["1", "2", "3"] == Vector{String}(f("1", "2", "3"))
    @test ["1", "2", "3", "4"] == Vector{String}(f("1", "2", "3", "4"))
    @test ["1", "2", "3", "4", "5"] == Vector{String}(f("1", "2", "3", "4", "5"))
    @test ["1", "2", "3", "4", "5", "6"] == Vector{String}(f("1", "2", "3", "4", "5", "6"))
    @test ["1", "2", "3", "4", "5", "6", "7"] == Vector{String}(f("1", "2", "3", "4", "5", "6", "7"))

    g = GAP.evalstr("""{x...} -> [x,ValueOption("option")]""")

    @test GapObj([[], 42], recursive=true) == g(; option=42)
    @test GapObj([[1], 42], recursive=true) == g(1; option=42)
    @test GapObj([[1, 2], 42], recursive=true) == g(1, 2; option=42)
    @test GapObj([[1, 2, 3], 42], recursive=true) == g(1, 2, 3; option=42)
    @test GapObj([[1, 2, 3, 4], 42], recursive=true) == g(1, 2, 3, 4; option=42)
    @test GapObj([[1, 2, 3, 4, 5], 42], recursive=true) == g(1, 2, 3, 4, 5; option=42)
    @test GapObj([[1, 2, 3, 4, 5, 6], 42], recursive=true) == g(1, 2, 3, 4, 5, 6; option=42)
    @test GapObj([[1, 2, 3, 4, 5, 6, 7], 42], recursive=true) == g(1, 2, 3, 4, 5, 6, 7; option=42)

    # check to see if a non-basic object (here: a tuple) can be
    # passed and then extracted again
    @test f((1, 2, 3))[1] == (1, 2, 3)

    @test !(GAP.Globals.IdFunc(2^62) isa Int64)

    x = GAP.Globals.Indeterminate(GAP.Globals.Rationals)
    f = x^4 + 1
    i1 = GAP.Globals.IdealDecompositionsOfPolynomial(f)
    i2 = GAP.Globals.IdealDecompositionsOfPolynomial(f, onlyone = true)
    @test i1 != i2
    @test GAP.Globals.Length(GAP.Globals.OptionsStack) == 0
    @test_throws ErrorException GAP.Globals.Error(onlyone = true)
    @test GAP.Globals.Length(GAP.Globals.OptionsStack) == 0

end

@testset "bugfixes" begin
    # from issue #324:
    l = GAP.evalstr("[1,~,3]")
    @test l[2] === l
    @test GAP.gap_to_julia(GAP.Globals.StringViewObj(l)) == "[ 1, ~, 3 ]"

    # from issue #1058:
    c = IOCapture.capture() do
           GAP.evalstr("function() res:= 1; return res; end")
       end
    #
    expected = """
               Syntax warning: Unbound global variable in stream:1
               function() res:= 1; return res; end;
                          ^^^
               Syntax warning: Unbound global variable in stream:1
               function() res:= 1; return res; end;
                                          ^^^
               """
    @test c.output == expected
end

@testset "randseed!" begin
    G = GAP.Globals.SymmetricGroup(9)
    random = GAP.Globals.Random
    GMT = GAP.Globals.GlobalMersenneTwister
    GRS = GAP.Globals.GlobalRandomSource

    GAP.randseed!()
    g1 = random(G)
    g2 = random(GMT, G)
    g3 = random(GRS, G)
    GAP.randseed!() # should initialize to a different state than before
    @test g1 != random(G)
    @test g2 != random(GMT, G)
    @test g3 != random(GRS, G)

    seed = rand(UInt128)
    GAP.randseed!(seed)
    gs1 = [random(G) for _=1:30]
    gs2 = [random(GMT, G) for _=1:30]
    gs3 = [random(GRS, G) for _=1:30]
    GAP.randseed!(seed)
    @test gs1 == [random(G) for _=1:30]
    @test gs2 == [random(GMT, G) for _=1:30]
    @test gs3 == [random(GRS, G) for _=1:30]

end

@testset "printing" begin
    io = IOBuffer()
    io = GAP.AbstractAlgebra.pretty(io)
    print(io, GAP.AbstractAlgebra.Lowercase(), GapObj([1, 2, 3]))
    @test String(take!(io)) == "GAP: [ 1, 2, 3 ]"
end

@testset "versioninfo" begin
    io = IOBuffer()
    GAP.versioninfo(io; full = true)
    str = String(take!(io))
    @test startswith(str, "GAP.jl version")
end
