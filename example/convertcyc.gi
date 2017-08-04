LoadPackage( "JuliaInterface" );

mult:= JuliaFunction( "*" );
add:= JuliaFunction( "+" );

alpha:= EB(5);
julialpha:= JuliaBoxCyc( alpha, 5 );

res1:= JuliaCallFunc2Arg( add, julialpha, JuliaBox( 1 ) );
res2:= JuliaCallFunc2Arg( mult, julialpha, res1 );

list:= [ E(3), E(4) ];
julilist:= JuliaBoxCyc( list, 12 );

res3:= JuliaCallFunc2Arg( add, julilist, julilist );

