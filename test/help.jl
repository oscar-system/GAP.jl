@testset "help" begin
    @test isa( GAP.GAP_help_string( "IsObject" ), String )
    @test isa( GAP.GAP_help_string( "IsObject", true ), String )
    @test isa( GAP.GAP_help_string( "unknow" ), String )
    @test isa( GAP.GAP_help_string( "unknow", true ), String )
    @test isa( GAP.GAP_help_string( "something for which no match is found" ), String )
    @test isa( GAP.GAP_help_string( "something for which no match is found", true ), String )
end

