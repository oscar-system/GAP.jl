@testset "convenience" begin

# Create some large integers

large_int = GAP.EvalString( "2^100;" )[1][2]
large_int_p1 = GAP.EvalString( "2^100 + 1;" )[1][2]
large_int_m1 = GAP.EvalString( "2^100 - 1;" )[1][2]
large_int_double = GAP.EvalString( "2^200;" )[1][2]
large_int_t2 = GAP.EvalString( "2^101;" )[1][2]

    @testset "integer_arithmetics" begin
        @test large_int + 1 == large_int_p1
        @test 1 + large_int == large_int_p1

        @test large_int - 1 == large_int_m1

        @test large_int * 2 == large_int_t2
        @test 2 * large_int == large_int_t2

        @test large_int * large_int == large_int_double
        @test large_int / large_int == 1
        @test large_int / 2^50 == 2^50

        @test large_int < large_int_p1
        @test large_int <= large_int_p1
        @test large_int > large_int_m1
        @test large_int >= large_int_m1
        @test large_int == large_int

        @test mod(large_int,2) == 0
        @test mod(large_int_p1,2) == 1
    end

end