#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

@testset "integer_arithmetics" begin

    # Create some large integers
    large_int = GAP.evalstr("2^100")
    large_int_p1 = GAP.evalstr("2^100 + 1")
    large_int_m1 = GAP.evalstr("2^100 - 1")
    large_int_squared = GAP.evalstr("2^200")
    large_int_t2 = GAP.evalstr("2^101")

    @test zero(large_int) == 0
    @test one(large_int) == 1

    @test large_int + 1 == large_int_p1
    @test 1 + large_int == large_int_p1

    @test large_int + (-large_int) == 0

    @test large_int - 1 == large_int_m1

    @test large_int * 2 == large_int_t2
    @test 2 * large_int == large_int_t2

    @test large_int * large_int == large_int_squared
    @test large_int^2 == large_int_squared

    @test large_int / large_int == 1
    @test large_int / 2^50 == 2^50

    @test large_int \ large_int == 1
    @test 2^50 \ large_int == 2^50

    @test large_int < large_int_p1
    @test large_int <= large_int_p1
    @test large_int > large_int_m1
    @test large_int >= large_int_m1
    @test large_int == large_int

    @test mod(large_int, 2) == 0
    @test mod(large_int_p1, 2) == 1
end

@testset "ffe_arithmetics" begin

    z3_gen = GAP.evalstr("Z(3)")
    z3_one = GAP.evalstr("Z(3)^0")
    z3_zero = GAP.evalstr("0 * Z(3)")

    z3 = GAP.Globals.Z(3)

    @test z3_gen == z3
    @test z3_one == one(z3)
    @test z3_zero == zero(z3)

    @test z3 * 1 == z3_gen
    @test z3 + 1 == z3_zero
    @test z3 + 2 == z3_one
    @test z3^2 == z3_one
    @test z3 - 1 == z3_one
end

@testset "operators" begin
    sym5 = GAP.Globals.SymmetricGroup(5)
    pi = @gap "(1,2,3)(4,17)"
    @test !(pi in sym5)
    @test pi^2 in sym5
    @test pi^-1 == pi^5

    # Julia object in GAP list
    l = [ [ 1 2 ], [ 3 4 ] ]
    gaplist = GapObj( l )  # list of Julia arrays
    @test l[1] in gaplist
    @test !([ 5 6 ] in gaplist)
end

@testset "object_access" begin
    list = GAP.evalstr("[1,2,3]")
    matrix = GAP.evalstr("[[1,2],[3,4]]")
    record = GAP.evalstr("rec( one := 1 )")

    @test length(list) == 3
    @test list[1] == 1
    @test list[2] == 2
    @test list[3] == 3
    list[4] = 4
    @test length(list) == 4
    @test list[4] == 4

    @test list[1:2] == GAP.evalstr("[1,2]")
    @test list[1:2:3] == GAP.evalstr("[1,3]")
    @test list[[1, 2]] == GAP.evalstr("[1,2]")
    list[[1, 2]] = [0, 1]
    @test list[[1, 2]] == GAP.evalstr("[0,1]")
    list[1:2] = [2, 3]
    @test list[1:2] == GAP.evalstr("[2,3]")
    list[1:2:3] = [3, 4]
    @test list[1:2:3] == GAP.evalstr("[3,4]")
    @test list[1:1] == GAP.evalstr("[3]")
    list[1:1] = [5]
    @test list[1:1] == GAP.evalstr("[5]")
    @test list[[1]] == GAP.evalstr("[5]")
    list[[1]] = [6]
    @test list[[1]] == GAP.evalstr("[6]")
    @test list[Int[]] == GAP.evalstr("[]")
    list[Int[]] = []
    @test list[Int[]] == GAP.evalstr("[]")

    @test matrix[1, 1] == 1
    @test matrix[2, 1] == 3
    matrix[1, 2] = 5
    @test matrix[1, 2] == 5

    @test record.one == 1
    record.two = 2
    @test record.two == 2

    sym5 = GAP.Globals.SymmetricGroup(5)
    @test sym5.:1 === GAP.Globals.GeneratorsOfGroup(sym5)[1]
    @test sym5.:1 === sym5."1"
end

@testset "create_type" begin
    @test GAP.create_type(Vector, [Int]) === Vector{Int}
    @test GAP.create_type(Tuple, [Int, Int]) === Tuple{Int, Int}
    @test GAP.create_type(Tuple, [GAP.create_type(Vector, [Int]), GAP.create_type(Matrix, [Int])]) === Tuple{Vector{Int64}, Matrix{Int64}}
end

@testset "functionloc" begin

    file, line = Base.functionloc(GAP.Globals.BangComponent)
    @test Base.samefile(file, joinpath(@__DIR__, "../pkg/JuliaInterface/gap/utils.gi"))
    @test line == 13

    @test_throws ArgumentError Base.functionloc(GAP.Globals.LETTERS)
    @test_throws ErrorException Base.functionloc(GAP.Globals.IsAbelian)
end
