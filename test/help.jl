@testset "help" begin
    using REPL
    tt = REPL.TerminalMenus.terminal

    function test_gap_help(topic::String)
        inp = Base.IOBuffer("qq") # exit the menu if applicable
        term = REPL.Terminals.TTYTerminal( "dumb", inp, tt.out_stream, tt.err_stream)
        return isa(GAP.gap_help_string(topic, false, term, suppress_output = true), String) &&
               isa(GAP.gap_help_string(topic, true, term, suppress_output = true), String)
    end

    @test test_gap_help("")
    @test test_gap_help("&")
    @test test_gap_help("-")
    @test test_gap_help("+")
    @test test_gap_help("<")
    @test test_gap_help("<<")
    @test test_gap_help(">")
    @test test_gap_help(">>")
    @test test_gap_help("welcome to gap")

    @test test_gap_help("?determinant")
    @test test_gap_help("?PermList")
    @test test_gap_help("?IsJuliaWrapper")

    @test test_gap_help("books")
    @test test_gap_help("tut:chapters")
    @test test_gap_help("tut:sections")

    @test test_gap_help("isobject")
    @test test_gap_help("tut:isobject")
    @test test_gap_help("ref:isobject")
    @test test_gap_help("unknow")
    @test test_gap_help("something for which no match is found")

    REPL.TerminalMenus.config(supress_output = false)
end
