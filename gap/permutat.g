
# experimental code for dealing with julia permutations in GAP,
# enough for computing the order of a permutation group
# (add more methods as they are needed for other tasks)

DeclareCategory( "IsExtPerm", IsPerm );

ExtPermType:= NewType( PermutationsFamily,
    IsExtPerm and IsPositionalObjectRep );

PermutationInJulia:= gapperm -> Objectify( ExtPermType,
    [ JuliaCallFunc1Arg( GetJuliaFunc( "Permutation" ),
                         JuliaBox( ListPerm( gapperm ) ) ) ] );

WrappedPermutationInJulia:= jperm -> Objectify( ExtPermType, [ jperm ] );

InstallMethod( ViewString, [ IsExtPerm ], function( p )
    return Concatenation( "<ext. perm.:", String( p![1] ), ">" );
    end );

InstallMethod( ViewObj, [ IsExtPerm ], function( p )
    Print( "<ext. perm.:", String( p![1] ), ">" );
    end );

InstallMethod( \=, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return JuliaUnbox( JuliaCallFunc2Arg( GetJuliaFunc( "EqPerm22" ),
                           p1![1], p2![1] ) );
    end );

InstallMethod( \<, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return JuliaUnbox( JuliaCallFunc2Arg( GetJuliaFunc( "LtPerm22" ),
                           p1![1], p2![1] ) );
    end );

InstallMethod( \*, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return WrappedPermutationInJulia( JuliaCallFunc2Arg(
               GetJuliaFunc( "ProdPerm22" ), p1![1], p2![1] ) );
    end );

InstallMethod( \^, [ IsExtPerm, IsInt ], function( p1, n )
    return WrappedPermutationInJulia( JuliaCallFunc2Arg(
               GetJuliaFunc( "PowPerm2Int" ), p1![1], JuliaBox( n ) ) );
    end );

InstallMethod( \^, [ IsInt, IsExtPerm ], function( i, p )
    return JuliaUnbox( JuliaCallFunc2Arg( GetJuliaFunc( "PowIntPerm2" ),
                           JuliaBox( i ), p![1] ) );
    end );

InstallMethod( \/, [ IsInt, IsExtPerm ], function( i, p )
    return JuliaUnbox( JuliaCallFunc2Arg( GetJuliaFunc( "QuoIntPerm2" ),
                           JuliaBox( i ), p![1] ) );
    end );

InstallMethod( LargestMovedPoint, [ IsExtPerm ], function( p )
    return JuliaUnbox( JuliaCallFunc1Arg( GetJuliaFunc( "LargestMovedPointPerm" ),
                           p![1] ) );
    end );

InstallMethod( Order, [ IsExtPerm ], function( p )
    return JuliaUnbox( JuliaCallFunc1Arg( GetJuliaFunc( "OrderPerm" ),
                           p![1] ) );
    end );

InstallMethod( One, [ IsExtPerm ], function( p )
    return WrappedPermutationInJulia( JuliaCallFunc1Arg(
               GetJuliaFunc( "OnePerm" ), p![1] ) );
#T perhaps easier ...
    end );

InstallMethod( InverseOp, [ IsExtPerm ], function( p )
    return WrappedPermutationInJulia( JuliaCallFunc1Arg(
               GetJuliaFunc( "InvPerm" ), p![1] ) );
    end );

# same hack as for objects with memory:
InstallOtherMethod( One,
    "partial method for a group (beats to ask family)",
    [ IsMagmaWithOne and IsGroup ], 102,
    function( M )
      local gens;
      gens:= GeneratorsOfGroup( M );
      if Length( gens ) > 0 and IsExtPerm( gens[1] ) then
        return One( gens[1] );
      else
        TryNextMethod();
      fi;
    end );

