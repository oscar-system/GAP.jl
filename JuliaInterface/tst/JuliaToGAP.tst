#
gap> START_TEST( "JuliaToGAP.tst" );

#
gap> JuliaToGAP(IsBool, true);
true
gap> JuliaToGAP(IsBool, false);
false
gap> JuliaToGAP(IsBool, fail);
fail

#
gap> JuliaToGAP(IsInt, JuliaEvalString("0"));
0
gap> JuliaToGAP(IsInt, JuliaEvalString("2"));
2
gap> JuliaToGAP(IsInt, JuliaEvalString("big(2)"));
2
gap> JuliaToGAP(IsInt, JuliaEvalString("big(2)^100"));
1267650600228229401496703205376

#
# TODO: add more tests

#
gap> STOP_TEST( "JuliaToGAP.tst", 1 );
