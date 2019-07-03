@testset "help" begin
    function test_gap_help( topic::String )
      return isa( GAP.GAP_help_string( topic ), String ) &&
             isa( GAP.GAP_help_string( topic, true ), String )
    end

    @test test_gap_help( "" )
    @test test_gap_help( "&" )
    @test test_gap_help( "-" )
    @test test_gap_help( "+" )
    @test test_gap_help( "<" )
    @test test_gap_help( "<<" )
    @test test_gap_help( ">" )
    @test test_gap_help( ">>" )
    @test test_gap_help( "welcome to gap" )

    @test test_gap_help( "?determinant" )
    @test test_gap_help( "?IsJuliaWrapper" )
    println(GAP.GAP_help_string( "?IsJuliaWrapper" ))

    @test test_gap_help( "books" )
    @test test_gap_help( "tut:chapters" )
    @test test_gap_help( "tut:sections" )

    @test test_gap_help( "isobject" )
    @test test_gap_help( "tut:isobject" )
    @test test_gap_help( "ref:isobject" )
    @test test_gap_help( "unknow" )
    @test test_gap_help( "something for which no match is found" )
end

