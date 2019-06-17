
@testset "integer_arithmetics" begin

    # Create some large integers
    large_int = GAP.EvalString( "2^100" )
    large_int_p1 = GAP.EvalString( "2^100 + 1" )
    large_int_m1 = GAP.EvalString( "2^100 - 1" )
    large_int_squared = GAP.EvalString( "2^200" )
    large_int_t2 = GAP.EvalString( "2^101" )

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

    z3_gen = GAP.EvalString( "Z(3)" )
    z3_one = GAP.EvalString( "Z(3)^0" )
    z3_zero = GAP.EvalString( "0 * Z(3)" )

    z3 = GAP.Globals.Z(3)

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
    list = GAP.EvalString( "[1,2,3]" )
    matrix = GAP.EvalString( "[[1,2],[3,4]]" )
    record = GAP.EvalString( "rec( one := 1 )" )

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

    sym5 = GAP.Globals.SymmetricGroup(5)
    @test sym5.:1 === GAP.Globals.GeneratorsOfGroup(sym5)[1]
    @test sym5.:1 === sym5."1"
end

## Need to be created outside of test
module test3 
    SymmetricGroup = 5
end

@testset "LoadPackageAndExposeGlobals" begin

    LoadPackageAndExposeGlobals("GAPDoc", "test1")
    @test isdefined(test1, :SymmetricGroup) == false

    LoadPackageAndExposeGlobals("GAPDoc", "test2", all_globals = true)
    @test isdefined(test2, :SymmetricGroup) == true

    LoadPackageAndExposeGlobals("GAPDoc", test3, all_globals = true)
    @test test3.SymmetricGroup == 5

end
