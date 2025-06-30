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
##  This file is a script which compiles the package manual.
##

if fail = LoadPackage("AutoDoc", ">= 2014.03.27") then
    Error("AutoDoc version 2014.03.27 is required.");
fi;

# collect output messages
outputstring:= "";;
outputstream:= OutputTextString(outputstring, true);;
SetPrintFormattingStatus(outputstream, false);
SetInfoOutput(InfoGAPDoc, outputstream);
SetInfoOutput(InfoWarning, outputstream);

AutoDoc(rec(
    autodoc := true,
    extract_examples:= true,
    scaffold := rec(
        entities := rec(
            Julia := "<Package>Julia</Package>"
        ),
    ),
));

CloseStream(outputstream);
UnbindInfoOutput(InfoGAPDoc);
UnbindInfoOutput(InfoWarning);
Print(outputstring);

# evaluate the outputs
outputstring:= ReplacedString(outputstring, "\c", "");;
errors:= Filtered(SplitString(outputstring, "\n"),
           x -> StartsWith(x, "#W ") and x <> "#W There are overfull boxes:");;
if Length(errors) = 0 then
  QuitGap(true);
else
  Print(errors, "\n");
  QuitGap(false);
fi;
QUIT;
