
@testset "integer_arithmetics" begin

    # Create some large integers
    large_int = GAP.EvalString( "2^100;" )[1][2]
    large_int_p1 = GAP.EvalString( "2^100 + 1;" )[1][2]
    large_int_m1 = GAP.EvalString( "2^100 - 1;" )[1][2]
    large_int_squared = GAP.EvalString( "2^200;" )[1][2]
    large_int_t2 = GAP.EvalString( "2^101;" )[1][2]

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

    @test mod(large_int,2) == 0
    @test mod(large_int_p1,2) == 1
end

@testset "ffe_arithmetics" begin

    z3_gen = GAP.EvalString( "Z(3);" )[1][2]
    z3_one = GAP.EvalString( "Z(3)^0;" )[1][2]
    z3_zero = GAP.EvalString( "0 * Z(3);" )[1][2]

    z3 = GAP.GAPFuncs.Z(3)

    @test z3_gen == z3
    @test z3_one == one(z3)
    @test z3_zero == zero(z3)

    @test z3 * 1 == z3_gen
    @test z3 + 1 == z3_zero
    @test z3 + 2 == z3_one
    @test z3 ^ 2 == z3_one
    @test z3 - 1 == z3_one
end

@testset "object_access" begin
    list = GAP.EvalString( "[1,2,3];" )[1][2]
    matrix = GAP.EvalString( "[[1,2],[3,4]];" )[1][2]
    record = GAP.EvalString( "rec( one := 1 );" )[1][2]

    @test length(list) == 3
    @test list[1] == 1
    @test list[2] == 2
    @test list[3] == 3
    list[4] = 4
    @test length(list) == 4
    @test list[4] == 4

    @test matrix[1,1] == 1
    @test matrix[2,1] == 3
    matrix[1,2] = 5
    @test matrix[1,2] == 5

    @test record.one == 1
    record.two = 2
    @test record.two == 2
end
