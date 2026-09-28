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
##  Run by the testset "GAP errors raised below a call from GAP into Julia"
##  in errors.jl.
##
##  When GAP code calls a Julia function and that function calls GAP, a GAP
##  error raised there can leave in two ways: by GAP's longjmp to its
##  innermost catch point, or as a Julia exception. The longjmp is only safe
##  if no Julia frames lie between the error and that catch point. Otherwise
##  Julia's exception handling is left pointing at a dead stack frame, and
##  the next Julia exception crashes or hangs as soon as that part of the
##  stack has been reused, which is why this runs in a separate process.
##
##  Each testset below sets up such a situation in a way real code does.
##  `GAP.evalstr` provides a GAP catch point underneath: its reader runs
##  inside one.

using Test
using GAP

# A GAP error to raise from Julia; any would do. SymmetricGroup has no
# method for a negative argument.
raise_gap_error() = GAP.Globals.SymmetricGroup(-3)
is_raised_error(e) = e isa GAPError && occursin("no method found", e.message)

function exception_of(f)
    try
        f()
    catch e
        return e
    end
    return nothing
end

# GAP counts nested calls of GAP functions and stops at a limit. The GAP
# functions a GAP error abandons never decrement that count, so it must end
# up where it was before each test.
recursion_depth() = GAP.Globals.GetRecursionDepth()
const depth_at_start = recursion_depth()

# GAP code can call a Julia function in two ways, which reach Julia along
# different paths: as Julia.Main.<name>, which calls it directly, or through
# a GAP global holding it, which calls it through a GAP method.
GAP.Globals.gapjl_raise = raise_gap_error
swallow_gap_error() = (exception_of(raise_gap_error); 0)
GAP.Globals.gapjl_swallow = swallow_gap_error

@testset "GAP errors raised below a call from GAP into Julia" begin
    @testset "one call into Julia" begin
        @test is_raised_error(exception_of(() -> GAP.evalstr("gapjl_raise()")))
    end

    @testset "several nested calls into Julia" begin
        # descend(n) passes from Julia to GAP and back n times, alternating
        # between evalstr and a direct call, then raises the error
        function descend(n)
            n == 0 && return raise_gap_error()
            isodd(n) && return GAP.evalstr("gapjl_descend($(n - 1))")
            return GAP.Globals.gapjl_descend(n - 1)
        end
        GAP.Globals.gapjl_descend = descend
        @test is_raised_error(exception_of(() -> descend(6)))
    end

    @testset "a Julia catch in between lets the GAP code continue" begin
        # the GAP functions must still see their own local variables
        GAP.evalstr_ex("""
        gapjl_via_global := function(a)
            local b;
            b := a + 1;
            gapjl_swallow();
            return [a, b];
        end;;
        gapjl_via_julia_main := function(a)
            local b;
            b := a + 1;
            Julia.Main.swallow_gap_error();
            return [a, b];
        end;;
        """)
        @test Vector{Int}(GAP.evalstr("gapjl_via_global(5)")) == [5, 6]
        @test Vector{Int}(GAP.evalstr("gapjl_via_julia_main(5)")) == [5, 6]
    end

    @testset "a Julia rethrow in between" begin
        GAP.Globals.gapjl_rethrow = () -> try
            raise_gap_error()
        catch
            rethrow()
        end
        @test is_raised_error(exception_of(() -> GAP.evalstr("gapjl_rethrow()")))
    end

    @testset "a different Julia exception in between" begin
        GAP.Globals.gapjl_replace = () -> try
            raise_gap_error()
        catch
            error("replacement")
        end
        e = exception_of(() -> GAP.evalstr("gapjl_replace()"))
        @test e isa GAPError && occursin("replacement", e.message)
    end

    @testset "a GAP catch in between" begin
        r = GAP.evalstr("CALL_WITH_CATCH(function() return gapjl_raise(); end, [])")
        @test r[1] === false
    end

    @testset "JuliaEvalString is a call into Julia too" begin
        GAP.evalstr_ex("""
        gapjl_eval_with_locals := function(a)
            local b;
            b := a + 1;
            JuliaEvalString("try GAP.Globals.SymmetricGroup(-3) catch end");
            return [a, b];
        end;;
        """)
        @test Vector{Int}(GAP.evalstr("gapjl_eval_with_locals(5)")) == [5, 6]
        @test is_raised_error(exception_of(
            () -> GAP.evalstr("JuliaEvalString(\"GAP.Globals.SymmetricGroup(-3)\")")))
    end

    @testset "with GAP.jl's error handler disabled" begin
        # as in GAP.prompt(): GAP reports errors itself and handles them at its
        # own catch points, but must not skip Julia frames to reach one
        function reports_of(f)
            output = GapObj("")
            GAP.replace_global!(:ERROR_OUTPUT, GAP.Globals.OutputTextString(output, true))
            f()
            return count("no method found", String(output))
        end
        result = nothing
        GAP.set_error_handler_disabled(true)
        try
            @test reports_of(() -> (result = GAP.evalstr("gapjl_via_global(5)"))) == 1
            @test Vector{Int}(result) == [5, 6]
            @test reports_of(() -> (result = GAP.evalstr("gapjl_via_julia_main(5)"))) == 1
            @test Vector{Int}(result) == [5, 6]

            # uncaught in Julia, the error reaches GAP's catch point, reported once
            @test reports_of(() -> (result = GAP.evalstr_ex("gapjl_raise(); 7;"))) == 1
            @test result[1][1] === false
            @test result[2][2] == 7
        finally
            GAP.set_error_handler_disabled(false)
            GAP.replace_global!(:ERROR_OUTPUT, GAP.Globals._JULIAINTERFACE_ERROR_OUTPUT)
        end
    end

    @testset "GAP's recursion depth is restored" begin
        # raise the error ten GAP calls deep, from GAP code called by Julia
        # or by GAP code, and catch it in Julia or in GAP
        GAP.evalstr_ex("""
        gapjl_deep := function(n, raise)
            if n = 0 then
                return raise();
            fi;
            return gapjl_deep(n - 1, raise);
        end;;
        gapjl_in_gap := function() return SymmetricGroup(-3); end;;
        """)
        deep(raise) = GAP.Globals.gapjl_deep(10, raise)
        deep_below_julia() = deep(GAP.Globals.gapjl_raise)
        GAP.Globals.gapjl_deep_below_julia = deep_below_julia
        GAP.Globals.gapjl_catch_deep = () -> (exception_of(deep_below_julia); 0)
        for _ in 1:20
            @test is_raised_error(exception_of(() -> deep(GAP.Globals.gapjl_in_gap)))
            @test is_raised_error(exception_of(() -> deep(GAP.Globals.gapjl_raise)))
            @test is_raised_error(exception_of(
                () -> GAP.Globals.gapjl_deep(10, GAP.Globals.gapjl_deep_below_julia)))
            @test GAP.Globals.gapjl_deep(10, GAP.Globals.gapjl_catch_deep) == 0
        end
        @test recursion_depth() == depth_at_start
    end

    @testset "GAP's own error handling still works afterwards" begin
        @test exception_of(() -> GAP.evalstr("1/0")) isa GAPError
        @test GAP.evalstr("1 + 1") == 2
        # covers every testset above
        @test recursion_depth() == depth_at_start
    end
end
