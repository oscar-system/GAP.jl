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
##  This file runs package tests. It is also referenced in the package
##  metadata in PackageInfo.g.
##
LoadPackage("JuliaInterface");
dir:=DirectoriesPackageLibrary("JuliaInterface", "tst");
Assert(0, dir <> fail);

CompareUpToWhitespaceAndMatches:= function( pairs )
    return function( a, b )
      local pair;

      a:= ShallowCopy( a );
      b:= ShallowCopy( b );
      for pair in pairs do
        if ForAll( [ a, b ],
               str -> ForAny( pair,
                          x -> PositionSublist( str, x ) <> fail ) ) then
          if pair[1] <> "" then
            a:= ReplacedString( a, pair[1], "" );
            b:= ReplacedString( b, pair[1], "" );
          fi;
          if pair[2] <> "" then
            a:= ReplacedString( a, pair[2], "" );
            b:= ReplacedString( b, pair[2], "" );
          fi;
        fi;
      od;

      return TEST.compareFunctions.uptowhitespace( a, b );
    end;
end;

# Several Julia types are shown differently in Julia 1.6.0-DEV
# and older Julia versions.
compare:= CompareUpToWhitespaceAndMatches(
    [ [ "Vector{Any}", "Vector{Any}" ],
      [ "Maybe you forgot to use an operator such as *, ^, %, / etc. ?", "" ] ] );

# The testfiles assume that no traceback is printed.
AlwaysPrintTracebackOnError:= false;
#TODO: This can be removed as soon as GAP's `Test` sets the value to `false`-

TestDirectory(dir, rec(exitGAP := true,
                       testOptions := rec(compareFunction := compare) ) );
FORCE_QUIT_GAP(1);
