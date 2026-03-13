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

function capture_exception(f)
    try
        f()
        return nothing
    catch err
        return err
    end
end

gap_error_type() = isdefined(GAP, :GAPError) ? getfield(GAP, :GAPError) : Exception
gap_frame_type() = isdefined(GAP, :GAPStackFrame) ? getfield(GAP, :GAPStackFrame) : Any

message_of(err) = hasproperty(err, :message) ? getproperty(err, :message) : ""
gap_frames_of(err) = hasproperty(err, :gap_frames) ? getproperty(err, :gap_frames) : Any[]

frame_label(frame) = getproperty(frame, :function_label)
frame_file(frame) = getproperty(frame, :file)
frame_line(frame) = getproperty(frame, :line)

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
        @test frames isa GapObj
        @test length(frames) >= 2
        @test String(frames[1][1]) == "gapjl_stack_helper_inner"
        @test String(frames[2][1]) == "gapjl_stack_helper_outer"
        @test frames[1][2] != GAP.Globals.fail
        @test frames[1][3] != GAP.Globals.fail
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

        @test err !== nothing
        @test isdefined(GAP, :GAPError)
        @test err isa gap_error_type()
        @test hasproperty(err, :message)
        @test occursin("boom", message_of(err))
        @test hasproperty(err, :gap_frames)

        frames = gap_frames_of(err)
        @test frames isa Vector
        @test !isempty(frames)
        @test all(frame -> frame isa gap_frame_type(), frames)

        labels = [frame_label(frame) for frame in frames]
        @test "gapjl_traceback_inner" in labels
        @test "gapjl_traceback_outer" in labels
        @test any(frame -> frame_file(frame) !== nothing, frames)
        @test any(frame -> frame_line(frame) !== nothing, frames)

        shown = sprint(showerror, err)
        @test occursin("GAP stacktrace", shown)
        @test occursin("gapjl_traceback_outer", shown)
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

        @test err !== nothing
        @test isdefined(GAP, :GAPError)
        @test err isa gap_error_type()
        @test !isempty(strip(message_of(err)))
        @test occursin("evalstr boom", message_of(err))

        frames = gap_frames_of(err)
        labels = [frame_label(frame) for frame in frames]
        @test "gapjl_evalstr_inner" in labels
        @test "gapjl_evalstr_outer" in labels
    end

    @testset "showerror prints the captured Julia stacktrace for evalstr" begin
        julia_evalstr_wrapper() = GAP.evalstr("Error(\"evalstr display boom\");")

        err = capture_exception() do
            julia_evalstr_wrapper()
        end

        @test err isa gap_error_type()

        shown = try
            throw(err)
        catch thrown
            sprint(showerror, thrown, catch_backtrace())
        end
        @test occursin("Julia stacktrace", shown)
        @test occursin("julia_evalstr_wrapper", shown)
        @test occursin("top-level scope", shown)
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

        @test err !== nothing
        @test isdefined(GAP, :GAPError)
        @test err isa gap_error_type()

        frames = gap_frames_of(err)
        labels = [frame_label(frame) for frame in frames]
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
        @test occursin("\n [1] framefunc @ ~/tmp/frame.g:12", shown)
    end

    @testset "showerror prints the captured Julia stacktrace" begin
        julia_gap_traceback_inner() = GAP.Globals.SymmetricGroup(-3)
        julia_gap_traceback_outer() = julia_gap_traceback_inner()

        err = capture_exception() do
            julia_gap_traceback_outer()
        end

        @test err isa gap_error_type()

        shown = try
            throw(err)
        catch thrown
            sprint(showerror, thrown, catch_backtrace())
        end
        @test occursin("Julia stacktrace", shown)
        @test occursin("julia_gap_traceback_inner", shown)
        @test occursin("julia_gap_traceback_outer", shown)
        @test !occursin("throw_gap_error", shown)
        @test !occursin("call_gap_func_nokw", shown)
        @test occursin("top-level scope", shown)
        top_level = findfirst("top-level scope", shown)
        @test top_level !== nothing
        @test !occursin("eval(m::Module", shown[first(top_level):end])
    end
end
