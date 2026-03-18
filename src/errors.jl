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

const last_error = Ref{String}("")

const disable_error_handler = Ref{Bool}(false)

function copy_gap_error_to_julia()
    global disable_error_handler
    if disable_error_handler[]
        return
    end
    last_error[] = String(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj)
    @ccall libgap.SET_LEN_STRING(Globals._JULIAINTERFACE_ERROR_BUFFER::GapObj, 0::Cuint)::Cvoid
end

function get_and_clear_last_error()
    err = last_error[]
    last_error[] = ""
    return err
end

function ThrowObserver(depth::Cint)
    global disable_error_handler
    if disable_error_handler[]
        return
    end

    # signal to the GAP interpreter that errors are handled
    @ccall libgap.ClearError()::Cvoid
    # reset global execution context
    @ccall libgap.SWITCH_TO_BOTTOM_LVARS()::Cvoid
    # at the top of GAP's exception handler chain, turn the GAP exception
    # into a Julia exception
    if depth <= 0
        error("Error thrown by GAP: $(get_and_clear_last_error())")
    end
end
