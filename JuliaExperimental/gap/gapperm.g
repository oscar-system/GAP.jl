##############################################################################
##
##  gapperm.g
##
##  This is experimental code for dealing with Julia permutations in GAP
##  (which are implemented in 'julia/gapperm.jl');
##  enough for computing the order of a permutation group
##
##  The permutation arithmetics of the Julia permutations in Julia
##  is comparable with the one in GAP.
##
##  Of course it is a bad idea to handle the Julia permutations
##  by low level GAP code:
##  First there is GAP's method selection,
##  then the Julia function must be fetched,
##  then there is Julia's method selection,
##  and finally the result must be either wrapped into a GAP object or
##  get unboxed.
##
##  This approach would become practically interesting
##  if a sufficient amount of GAP code for permutation groups would become
##  available as Julia code.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "gapperm.jl" ) );

ImportJuliaModuleIntoGAP( "Base" );
ImportJuliaModuleIntoGAP( "GAPPermutations" );


##############################################################################
##
##  Provide global variables.
##
DeclareCategory( "IsExtPerm", IsPerm );

BindGlobal( "ExtPermType",
    NewType( PermutationsFamily, IsExtPerm and IsPositionalObjectRep ) );

BindGlobal( "PermutationInJulia",
    gapperm -> Objectify( ExtPermType,
       [ Julia.GAPPermutations.Permutation( ConvertedToJulia( ListPerm( gapperm ) ) ) ] ) );

BindGlobal( "WrappedPermutationInJulia",
    jperm -> Objectify( ExtPermType, [ jperm ] ) );

BindGlobal( "JuliaIdentityPerm",
    WrappedPermutationInJulia( Julia.GAPPermutations.IdentityPerm ) );


##############################################################################
##
##  Install the methods.
##
InstallMethod( ViewString, [ IsExtPerm ], function( p )
    return Concatenation( "<ext. perm.:", String( p![1] ), ">" );
    end );

InstallMethod( ViewObj, [ IsExtPerm ], function( p )
    Print( "<ext. perm.:", String( p![1] ), ">" );
    end );

InstallMethod( \=, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return ConvertedFromJulia( Julia.Base.("==")( p1![1], p2![1] ) );
    end );

InstallMethod( \<, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return ConvertedFromJulia( Julia.Base.isless( p1![1], p2![1] ) );
    end );

InstallMethod( \*, [ IsExtPerm, IsExtPerm ], function( p1, p2 )
    return WrappedPermutationInJulia( Julia.Base.("*")(
               p1![1], p2![1] ) );
    end );

InstallMethod( \^, [ IsExtPerm, IsInt ], function( p1, n )
    return WrappedPermutationInJulia( Julia.Base.("^")(
               p1![1], ConvertedToJulia( n ) ) );
    end );

InstallMethod( \^, [ IsInt, IsExtPerm ], function( i, p )
    return ConvertedFromJulia( Julia.Base.("^")( ConvertedToJulia( i ), p![1] ) );
    end );

InstallMethod( \/, [ IsInt, IsExtPerm ], function( i, p )
    return ConvertedFromJulia( Julia.Base.("/")( ConvertedToJulia( i ), p![1] ) );
    end );

InstallMethod( LargestMovedPoint, [ IsExtPerm ], function( p )
    return ConvertedFromJulia( Julia.GAPPermutations.LargestMovedPointPerm( p![1] ) );
    end );

InstallMethod( Order, [ IsExtPerm ], function( p )
    return ConvertedFromJulia( Julia.GAPPermutations.OrderPerm( p![1] ) );
    end );

InstallMethod( One, [ IsExtPerm ], p -> JuliaIdentityPerm );

InstallMethod( InverseOp, [ IsExtPerm ], function( p )
    return WrappedPermutationInJulia( Julia.Base.inv( p![1] ) );
    end );

# Use the same hack as for objects with memory,
# in order to avoid fetching the GAP object '()'.
InstallOtherMethod( One,
    "partial method for a group (beats to ask family)",
    [ IsMagmaWithOne and IsGroup ], 102,
#T and IsPermCollection
    function( M )
      local gens;
      gens:= GeneratorsOfGroup( M );
      if Length( gens ) > 0 and IsExtPerm( gens[1] ) then
        return One( gens[1] );
      else
        TryNextMethod();
      fi;
    end );


##############################################################################
##
#E

