


##############################################################################
##
##  Notify the Julia part.
##
JuliaIncludeFile(
    Filename( DirectoriesPackageLibrary( "JuliaExperimental", "julia" ),
    "utils.jl" ) );

ImportJuliaModuleIntoGAP( "GAPUtilsExperimental" );


#############################################################################
##
##  Declare filters.
##


#############################################################################
##
##
##
DeclareAttribute( "JuliaPointer", IsObject );


##############################################################################
##
#! @Arguments obj
#! @Returns a &Julia; object
#! @Description
#!  For an object <A>obj</A> with attribute <Ref Attr="JuliaPointer"/>,
#!  this function returns the value of this attribute.
InstallMethod( JuliaBox,
    [ "HasJuliaPointer" ],
    obj -> JuliaPointer( obj ) );


#############################################################################
##
#! @Arguments pkgname
#! @Returns <K>true</K> or <K>false</K>.
#! @Description
#!  This function triggers the execution of a <C>using</C> statement
#!  for the Julia package with name <A>pkgname</A>.
#!  It returns <K>true</K> if the call was successful,
#!  and <K>false</K> otherwise.
#!  <P/>
#!  Apparently <C>libjulia</C> throws an error
#!  when trying to compile the package, which happens when some files from
#!  the package have been modified since compilation.
#!  <P/>
#!  Thus &GAP; has to check whether the Julia package has been loaded
#!  successfully, and can then load and execute code that relies on this
#!  Julia package.
#!  In particular, we cannot just put the necessary <C>using</C> statements
#!  into the relevant <F>.jl</F> files,
#!  and then load these files with <Ref Func="JuliaIncludeFile"/>.
BindGlobal( "JuliaUsingPackage", function( pkgname )
    if not IsString( pkgname ) then
      Error( "<pkgname> must be a string, the name of a Julia package" );
    elif JuliaUnbox( JuliaEvalString( Concatenation(
             "try\nusing ", pkgname,
             "\nreturn true\ncatch e\nreturn e\nend" ) ) ) = true then
      return true;
    else
      Info( InfoWarning, 1,
            "The Julia package '", pkgname, "' cannot be loaded" );
      return false;
    fi;
    end );


#############################################################################
##
#! @Arguments juliaobj
#! @Returns a string.
#! @Description
#!  Returns the string that describes the julia type of the Julia object
#!  <A>juliaobj</A>.
BindGlobal( "JuliaTypeInfo",
    juliaobj -> JuliaUnbox( Julia.Base.string(
                                    Julia.Core.typeof( juliaobj ) ) ) );


#############################################################################
##
##
##  'result' is bound only if <A>func</A> returned a value.
##
##  'Julia_time' measures the wall clock time between the start and the end
##  of the computations;
##  this includes both the &GAP; and the Julia computations.
##
##  'GAP_time' measures the &GAP; runtime of the computations;
##  this does apparently include most of the time needed by computations
##  in Julia, but for example *not* times spent in <C>sleep</C> calls.
##
##  Try to understand better how this works!
##
BindGlobal( "CallFuncListWithTimings", function( func, args )
    local tic, toq, start, result, diff, stop;

    tic:= Julia.Base.tic;
    toq:= Julia.Base.toq;
    start:= Runtime();
    tic();
    result:= CallFuncListWrap( func, args );
    stop:= Runtime();
    diff:= toq();

    if Length( result ) = 1 then
      return rec( result:= result,
                  GAP_time:= stop - start,
                  Julia_time:= Int( 1000 * JuliaUnbox( diff ) ) );
    else
      return rec( result:= result,
                  GAP_time:= stop - start,
                  Julia_time:= Int( 1000 * JuliaUnbox( diff ) ) );
    fi;
    end );


#############################################################################
##
##
##  For a list <A>coeffs</A> of integers, this function creates
##  a Julia array that contains the corresponding Julia objects of type
##  <C>fmpz</C>.
##
BindGlobal( "JuliaArrayOfFmpz", function( coeffs )
    local arr, i, fmpz, parse, alp, entry, map;

    # Convert the entries to 'Nemo.fmpz' integers.
    arr:= [];
    i:= 1;
    fmpz:= JuliaFunction( "fmpz", "Nemo" );
    parse:= JuliaFunction( "parse", "Base" );
    alp:= JuliaBox( 16 );
    for entry in coeffs do
      if IsSmallIntRep( entry ) then
        arr[i]:= entry;
      else
        arr[i]:= parse( fmpz, HexStringInt( entry ), alp );
      fi;
      i:= i + 1;
    od;
    map:= JuliaFunction( "map", "Base" );
    arr:= map( fmpz, JuliaBox( arr ) );

    return arr;
    end );


##############################################################################
##
#F  JuliaMatrixFromGapMatrix( <gapmatrix> )
##
##  <gapmatrix> must be a matrix of small integers.
##
BindGlobal( "JuliaMatrixFromGapMatrix", function( gapmatrix )
    local juliamatrix;

    juliamatrix:= JuliaBox( gapmatrix );  # nested array
    return Julia.GAPUtilsExperimental.MatrixFromNestedArray( juliamatrix );
    end );


#############################################################################
##
#E

