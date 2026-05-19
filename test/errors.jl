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

using IOCapture

function capture_exception(f)
    try
        f()
        return nothing
    catch err
        return err
    end
end

@testset "error backtraces" begin
    @testset "pure GAP helper captures stack shape" begin
        GAP.evalstr_ex("""
        gapjl_stack_helper_inner := function()
            return _JULIAINTERFACE_CAPTURE_STACK(GetCurrentLVars());
        end;;
        gapjl_stack_helper_outer := function()
            return gapjl_stack_helper_inner();
        end;;
        """)

        frames = GAP.Globals.gapjl_stack_helper_outer()
        @test Vector{Tuple{String,String,Int}}(frames) ==
                [
                 ("gapjl_stack_helper_inner", "stream", 2)
                 ("gapjl_stack_helper_outer", "stream", 5)
                ]
    end

    @testset "direct GAP calls expose structured backtraces" begin
        GAP.evalstr_ex("""
        gapjl_traceback_inner := function()
            Error("boom");
        end;;
        gapjl_traceback_outer := function()
            gapjl_traceback_inner();
        end;;
        """)

        err = capture_exception() do
            GAP.Globals.gapjl_traceback_outer()
        end

        @test err isa GAPError
        @test occursin("boom", err.message)

        frames = err.gap_frames
        @test frames isa Vector{GAP.GAPStackFrame}
        @test length(frames) == 2
        @test frames == [ GAP.GAPStackFrame("gapjl_traceback_inner", "stream", 2),
                          GAP.GAPStackFrame("gapjl_traceback_outer", "stream", 5) ]

        shown = sprint(showerror, err)
        expected_msg = """
                       Error thrown by GAP: boom
                       GAP stacktrace:
                        [1] gapjl_traceback_inner
                            @ stream:2
                        [2] gapjl_traceback_outer
                            @ stream:5
                       """
        # in GAP <= 4.15.x, the error includes `at stream:2` in the first line;
        # in GAP >= 4.16.0, this is gone
        @test replace(shown, " at stream:2" => "") == chomp(expected_msg)
    end

    @testset "evalstr preserves the captured GAP error" begin
        err = capture_exception() do
            GAP.evalstr("""
            gapjl_evalstr_inner := function()
                Error("evalstr boom");
            end;
            gapjl_evalstr_outer := function()
                gapjl_evalstr_inner();
            end;
            gapjl_evalstr_outer();
            """)
        end

        @test err isa GAPError
        @test occursin("evalstr boom", err.message)

        frames = err.gap_frames
        @test frames isa Vector{GAP.GAPStackFrame}
        @test length(frames) == 2
        @test frames == [ GAP.GAPStackFrame("gapjl_evalstr_inner", "stream", 2),
                          GAP.GAPStackFrame("gapjl_evalstr_outer", "stream", 5) ]
    end

    @testset "showerror prints the captured Julia stacktrace for evalstr" begin
        julia_evalstr_wrapper() = GAP.evalstr("Error(\"evalstr display boom\");")

        err = capture_exception() do
            julia_evalstr_wrapper()
        end

        @test err isa GAPError

        shown = try
            throw(err)
        catch thrown
            sprint(showerror, thrown, catch_backtrace())
        end
        @test occursin("julia_evalstr_wrapper", shown)
        top_level = findfirst("top-level scope", shown)
        @test top_level !== nothing
        @test !occursin("eval(m::Module", shown[first(top_level):end])
    end

    @testset "anonymous functions still render usable frames" begin
        anon = GAP.evalstr("""
        function()
            local inner;
            inner := function()
                Error("anonymous boom");
            end;
            inner();
        end
        """)

        err = capture_exception() do
            anon()
        end

        @test err isa GAPError

        frames = err.gap_frames
        labels = [frame.function_label for frame in frames]
        @test any(label -> occursin("unknown", label) || occursin("anonymous", label), labels)

        shown = sprint(showerror, err)
        @test occursin("anonymous boom", shown)
        @test occursin("GAP stacktrace", shown)
    end

    @testset "showerror uses Julia-style frame formatting" begin
        err = GAP.GAPError(
            "format boom",
            [GAP.GAPStackFrame("framefunc", joinpath(homedir(), "tmp", "frame.g"), 12)],
            "",
        )

        shown = sprint(showerror, err)
        @test occursin("Error thrown by GAP: format boom", shown)
        @test occursin("\n [1] framefunc\n     @ ~/tmp/frame.g:12", shown)
    end

    @testset "showerror prints the captured Julia stacktrace" begin
        julia_gap_traceback_inner() = GAP.Globals.SymmetricGroup(-3)
        julia_gap_traceback_outer() = julia_gap_traceback_inner()

        err = capture_exception() do
            julia_gap_traceback_outer()
        end

        @test err isa GAPError

        shown = try
            throw(err)
        catch thrown
            sprint(showerror, thrown, catch_backtrace())
        end
        @test occursin(r"\[3\] [^\n]+julia_gap_traceback_inner", shown)
        @test occursin("[4] julia_gap_traceback_outer", shown)
        @test !occursin("throw_gap_error", shown)
        @test !occursin("call_gap_func_nokw", shown)
        top_level = findfirst("top-level scope", shown)
        @test top_level !== nothing
        @test !occursin("eval(m::Module", shown[first(top_level):end])
    end

    @testset "disabling custom error handling clears stale state" begin
        @test GAP.is_error_handler_disabled() === false

        err = capture_exception() do
            GAP.Globals.gapjl_traceback_outer()
        end
        @test err isa GAPError
        @test !isempty(err.gap_frames)

        GAP.set_error_handler_disabled(true)
        try
            @test GAP.is_error_handler_disabled() === true
            @test GAP.last_error_snapshot[] === nothing
            @test isempty(GAP.capture_gap_error_frames())
            @test length(GAP.Globals._JULIAINTERFACE_ERROR_STACK) == 0
            @test isempty(String(GAP.Globals._JULIAINTERFACE_ERROR_BUFFER))
        finally
            GAP.set_error_handler_disabled(false)
        end

        @test GAP.is_error_handler_disabled() === false
    end

    @testset "evalstr clears stale GAP error text before running" begin
        GAP.clear_gap_error()
        GAP.Globals.PrintTo(
            GAP.Globals._JULIAINTERFACE_ERROR_OUTPUT,
            "stale GAP error text",
        )
        GAP.clear_gap_error_frames()
        GAP.Globals.Add(
            GAP.Globals._JULIAINTERFACE_ERROR_STACK,
            GapObj(Any["stale_frame", "stale.g", 1]; recursive=true),
        )

        captured = IOCapture.capture() do
            println(typeof(GAP.evalstr("(1,2,3)")))
        end

        @test occursin("GapObj", captured.output)
        @test !occursin("stale GAP error text", captured.output)
        @test GAP.last_error_snapshot[] === nothing
        @test isempty(String(GAP.Globals._JULIAINTERFACE_ERROR_BUFFER))
        @test isempty(GAP.capture_gap_error_frames())
    end
end
