
#############################################################################
##
##  Install methods for 'IsJuliaObject' objects.
##

InstallOtherMethod( AdditiveInverseOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.("-")( obj );
    end );

InstallOtherMethod( ZeroOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.zero( obj );
    end );

InstallOtherMethod( OneOp,
    [ "IsJuliaObject" ],
    function( obj )
      return Julia.Base.one( obj );
    end );

Perform([[ "IsJuliaObject", "IsJuliaObject" ],
         [ "IsJuliaObject", "IsInt and IsSmallIntRep" ],
         [ "IsInt and IsSmallIntRep", "IsJuliaObject" ]],
    function(argTypes)
        InstallOtherMethod( \+, argTypes, Julia.Base.\+ );
        InstallOtherMethod( \*, argTypes, Julia.Base.\* );
        InstallOtherMethod( \-, argTypes, Julia.Base.\- );
        InstallOtherMethod( \/, argTypes, Julia.Base.\/ );
        InstallOtherMethod( LQUO, argTypes, Julia.Base.\\ );
        InstallOtherMethod( \^, argTypes, Julia.Base.\^ );
        InstallOtherMethod( \=, argTypes, Julia.Base.\=\= );
        InstallOtherMethod( \<, argTypes, Julia.Base.\< );
    end);


#
# lists
#
InstallOtherMethod( \[\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, i )
      return Julia.Base.getindex( obj, i );
    end );

InstallOtherMethod( \[\]\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, i, val )
      return Julia.Base.setindex\!( obj, val, i );
    end );

#
# "matrices" / lists of lists
#
InstallOtherMethod( \[\,\],
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep" ],
    function( obj, i, j )
      return Julia.Base.getindex( obj, i, j );
    end );

InstallOtherMethod( \[\,\]\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep",
                       "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, i, j, val )
      return Julia.Base.setindex\!( obj, val, i, j );
    end );

#
# access to fields and properties
#
BindGlobal("_JL_RNAM_TO_JULIA_SYMBOL_CACHE", rec());
BindGlobal("_JL_RNAM_TO_JULIA_SYMBOL", function(rnam)
    local symbol;
    if ISB_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam) then
        symbol := ELM_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam);
    else;
        symbol := JuliaSymbol( NameRNam( rnam ) );
        ASS_REC(_JL_RNAM_TO_JULIA_SYMBOL_CACHE, rnam, symbol);
    fi;
    return symbol;
end);

InstallOtherMethod( \.,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep" ],
    function( obj, rnam )
      return Julia.Base.getproperty( obj, _JL_RNAM_TO_JULIA_SYMBOL( rnam ) );
    end );

InstallOtherMethod( \.\:\=,
    [ "IsJuliaObject", "IsPosInt and IsSmallIntRep", "IsObject" ],
    function( obj, rnam, val )
      return Julia.Base.setproperty\!( obj, _JL_RNAM_TO_JULIA_SYMBOL( rnam ), val );
    end );


#############################################################################
##
##  Create random numbers via Julia random number generators.
##
BindGlobal( "RandomSourceJulia",
    rng -> RandomSource( IsRandomSourceJulia, rng ) );

InstallMethod( State,
    [ "IsRandomSourceJulia and HasJuliaPointer" ],
    rng -> Julia.Base.copy( JuliaPointer( rng ) ) );

# If the 'JuliaPointer' value is already set then we want to reset
# an already initialized random source.
# Then the pair given by 'rng' and its 'JuliaPointer' value may be cached
# in the Julia session.
# Thus we cannot replace the 'JuliaPointer' value by a copy.
# Instead we change the value in place.
InstallMethod( Init,
    [ "IsRandomSourceJulia", "IsObject" ],
    function( rng, seed )
    ImportJuliaModuleIntoGAP( "Random" );
    if IsInt( seed ) then
      # This means a prescribed seed.
      seed:= AbsInt( seed );
      if HasJuliaPointer( rng ) then
        Julia.Random.seed\!( JuliaPointer( rng ), GAPToJulia( seed ) );
      else
        SetFilterObj( rng, IsAttributeStoringRep );
        # We did not get a Julia rng, thus we create one by taking
        # a copy of the default one and then initializing it.
        SetJuliaPointer( rng,
            Julia.Random.seed\!( Julia.Base.copy( Julia.Random.default_rng() ),
                                 GAPToJulia( seed ) ) );
      fi;
    elif IsJuliaObject( seed ) and
         Julia.Base.isa( seed, Julia.Random.AbstractRNG ) then
      # This means a prescribed state.
      if HasJuliaPointer( rng ) then
        Julia.Base.copy\!( JuliaPointer( rng ), seed );
      else
        SetFilterObj( rng, IsAttributeStoringRep );
        # Here we do *not* copy the given Julia rng,
        # in order to use exactly this rng.
        SetJuliaPointer( rng, seed );
      fi;
    else
      Error( "<seed> must be a nonnegative integer ",
             "or a Julia random number generator" );
    fi;
    return rng;
    end );

# The pair given by 'rng' and its 'JuliaPointer' value may be cached
# in the Julia session.
# Thus we cannot replace the 'JuliaPointer' value by a copy.
# Instead we change the value in place.
InstallMethod( Reset,
    [ "IsRandomSourceJulia and HasJuliaPointer", "IsObject" ],
    function( rng, seed )
    local old;

    old:= State( rng );
    ImportJuliaModuleIntoGAP( "Random" );
    if IsInt( seed ) then
      # This means a prescribed seed.
      seed:= AbsInt( seed );
      Julia.Random.seed\!( JuliaPointer( rng ), GAPToJulia( seed ) );
    elif IsJuliaObject( seed ) and
         Julia.Base.isa( seed, Julia.Random.AbstractRNG ) then
      # This means a prescribed state.
      Julia.Base.copy\!( JuliaPointer( rng ), seed );
    else
      Error( "<seed> must be a nonnegative integer ",
             "or a Julia random number generator" );
    fi;

    return old;
    end );

InstallMethod( Random,
    [ "IsRandomSourceJulia and HasJuliaPointer", "IsInt and IsSmallIntRep",
      "IsInt and IsSmallIntRep" ],
    { rng, from, to } -> Julia.Base.rand( JuliaPointer( rng ),
                             Julia.Base.UnitRange( from, to ) ) );

InstallMethod( Random,
    [ "IsRandomSourceJulia and HasJuliaPointer", "IsInt", "IsInt" ],
    { rng, from, to } -> JuliaToGAP( IsInt,
        Julia.Base.rand( JuliaPointer( rng ),
            Julia.Base.UnitRange( GAPToJulia( from ), GAPToJulia( to ) ) ) ) );


#############################################################################
##
#E

