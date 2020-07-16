#
# JuliaInterface: Test interface to julia
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
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
          a:= ReplacedString( a, pair[1], "" );
          a:= ReplacedString( a, pair[2], "" );
          b:= ReplacedString( b, pair[1], "" );
          b:= ReplacedString( b, pair[2], "" );
        fi;
      od;
      return TEST.compareFunctions.uptowhitespace( a, b );
    end;
end;

# Several Julia types are shown differently in Julia 1.6.0-DEV
# and older Julia versions.
compare:= CompareUpToWhitespaceAndMatches(
    [ [ "Array{Any,1}", "Vector{Any}" ] ] );

TestDirectory(dir, rec(exitGAP := true,
                       testOptions := rec(compareFunction := compare) ) );
FORCE_QUIT_GAP(1);
