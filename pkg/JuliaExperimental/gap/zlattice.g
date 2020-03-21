##############################################################################
##
##  zlattice.g
##
##  The Julia utilities are implemented in 'julia/zlattice.jl'.
##


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "zlattice.jl" ) );


##############################################################################
##
#F  ShortestVectorsUsingJulia( <juliagrammat>, <bound> )
##
##  <Example>
##  gap> A:= [ [ 2, -1, -1, -1 ], [ -1, 2, 0, 0 ],
##  >          [ -1, 0, 2, 0 ], [ -1, 0, 0, 2 ] ];;
##  gap> jmat:= JuliaMatrixFromGapMatrix( A );;
##  gap> sv:= ShortestVectorsUsingJulia( jmat, 2 );;
##  gap> Length( sv.vectors );
##  12
##  </Example>
##
BindGlobal( "ShortestVectorsUsingJulia", function( juliagrammat, bound )
    local juliaresult, r;

    # Compute the shortest vectors in Julia.
    juliaresult:= Julia.GAPZLattice.ShortestVectors( juliagrammat, bound );

    # Convert the result to GAP.
    # We cannot simply unbox the rationals from the 'norms' component,
    # so we proceed in two steps.
    r:= JuliaToGAP( IsRecord, juliaresult );
    r.vectors:= JuliaToGAP( IsList, r.vectors, true );
#   r.norms:= ...
#T the entries can be Julia rationals; what to do?

    return r;
end );


##############################################################################
##
#F  OrthogonalEmbeddingsUsingJulia( <juliagrammat>[, <arec>] )
##
##  The supported components of <arec> are
##  <C>maxdim</C> (default <C>infinity</C>),
##  <C>mindim</C> (default <C>0</C>),
##  <C>nonnegative</C> (default <K>false</K>),
##
##  <Example>
##  gap> A:= [ [ 2, -1, -1, -1 ], [ -1, 2, 0, 0 ],
##  >          [ -1, 0, 2, 0 ], [ -1, 0, 0, 2 ] ];;
##  gap> jmat:= JuliaMatrixFromGapMatrix( A );;
##  gap> arec:= rec();;
##  gap> sv:= OrthogonalEmbeddingsUsingJulia( jmat, arec );;
##  gap> Length( sv.vectors );  Length( sv.solutions );
##  12
##  3
##  </Example>
##
BindGlobal( "OrthogonalEmbeddingsUsingJulia", function( juliagrammat, arec... )
    local dict, juliaresult, r;

    # Check the arguments.
    dict:= rec();
    if Length( arec ) <> 0 and IsRecord( arec[1] ) then
      if IsBound( arec[1].mindim ) then
        dict.mindim:= arec[1].mindim;
      fi;
      if IsBound( arec[1].maxdim ) then
        dict.maxdim:= arec[1].maxdim;
        if dict.maxdim = infinity then
          dict.maxdim:= -1;
        fi;
      fi;
      if IsBound( arec[1].nonnegative ) then
        dict.nonnegative:= arec[1].nonnegative;
      fi;
    fi;

    # Compute the shortest vectors in Julia.
    dict:= GAPToJulia( dict );
    juliaresult:= Julia.GAPZLattice.OrthogonalEmbeddings( juliagrammat, dict );

    # Convert the result to GAP.
    # We cannot simply unbox the rationals from the 'norms' component,
    # so we proceed in two steps.
    r:= JuliaToGAP( IsRecord, juliaresult );
    r.vectors:= JuliaToGAP( IsList, r.vectors, true );
    r.solutions:= JuliaToGAP( IsList, r.solutions, true );
#   r.norms:= ...
#T the entries can be Julia rationals; what to do?

    return r;
end );

