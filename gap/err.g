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

# create output stream for use by JuliaInterface
BindGlobal("_JULIAINTERFACE_ORIGINAL_ERROR_OUTPUT", ERROR_OUTPUT);
BindGlobal("_JULIAINTERFACE_ERROR_BUFFER", "");
BindGlobal("_JULIAINTERFACE_ERROR_OUTPUT", OutputTextString(_JULIAINTERFACE_ERROR_BUFFER, true));
SetPrintFormattingStatus(_JULIAINTERFACE_ERROR_OUTPUT, false);

# set it as GAP's default error output stream
MakeReadWriteGlobal("ERROR_OUTPUT");
ERROR_OUTPUT := _JULIAINTERFACE_ERROR_OUTPUT;
MakeReadOnlyGlobal("ERROR_OUTPUT");

BindGlobal("_JULIAINTERFACE_ERROR_STACK", []);

BindGlobal("_JULIAINTERFACE_CLEAR_ERROR_STACK", function()
    MakeReadWriteGlobal("_JULIAINTERFACE_ERROR_STACK");
    _JULIAINTERFACE_ERROR_STACK := [];
    MakeReadOnlyGlobal("_JULIAINTERFACE_ERROR_STACK");
end);

BindGlobal("_JULIAINTERFACE_CAPTURE_STACK", function(context)
    local frames, bottom, vars, func, label, loc, file, line;

    frames := [];
    if context = fail then
        return frames;
    fi;

    bottom := GetBottomLVars();
    while context <> fail and context <> bottom do
        vars := ContentsLVars(context);
        if IsRecord(vars) and IsBound(vars.func) then
            func := vars.func;
            label := NameFunction(func);
            if label = fail then
                label := "unknown";
            fi;
        else
            label := "unknown";
        fi;

        file := fail;
        line := fail;
        loc := CURRENT_STATEMENT_LOCATION(context);
        if loc <> fail then
            file := loc[1];
            line := loc[2];
        fi;

        Add(frames, [label, file, line]);
        context := ParentLVars(context);
    od;

    return frames;
end);

# Capture the GAP stack here, while ErrorInner still receives the original
# error context explicitly. Probing from the later Julia callback is not
# reliable in GAP 4.15: ErrorLVars is already fail there, and GetCurrentLVars()
# has moved into GAP's error machinery. Walking up ParentLVars() from that
# callback does eventually reach the failing frame, but the number of internal
# frames to skip depends on the error kind (for example method selection, Error,
# and kernel errors differ).
#
# TODO: Revisit this for future GAP releases. If GAP eventually exposes a
# stable callback-time accessor for the original error context, this ErrorInner
# override may become unnecessary.
ReplaceBinding("ErrorInner", function(options, earlyMessage)
    local orig;

    MakeReadWriteGlobal("_JULIAINTERFACE_ERROR_STACK");
    _JULIAINTERFACE_ERROR_STACK := _JULIAINTERFACE_CAPTURE_STACK(options.context);
    MakeReadOnlyGlobal("_JULIAINTERFACE_ERROR_STACK");

    orig := VALUE_GLOBAL("_ORIG_ErrorInner");
    return orig(options, earlyMessage);
end);
