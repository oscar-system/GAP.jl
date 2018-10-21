##
gap> START_TEST( "utils.tst" );

##  We want to call some functions from the Julia module Base.
gap> ImportJuliaModuleIntoGAP( "Base" );
gap> ImportJuliaModuleIntoGAP( "GAPUtils" : NoImport := true );

##
gap> JuliaTypeInfo( ConvertedToJulia( 1 ) );
"Int64"
gap> JuliaTypeInfo( 0 );
"Int64"
gap> JuliaTypeInfo( ConvertedToJulia( [ 1, 2, 3 ] ) );
"Array{Any,1}"
gap> JuliaTypeInfo( Julia.Base.parse );
"typeof(parse)"

##
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ 4 ] );
rec( ok := true, value := <Julia: 2.0> )
gap> CallJuliaFunctionWithCatch( Julia.Base.sqrt, [ -1 ] );
rec( ok := false, 
  value := "DomainError(-1.0, \"sqrt will only return a complex result if call\
ed with a complex argument. Try sqrt(Complex(x)).\")" )

#
gap> JuliaSetVal("foo", JuliaEvalString("1"));
gap> JuliaGetGlobalVariable("foo");
<Julia: 1>

##
gap> STOP_TEST( "utils.tst", 1 );

