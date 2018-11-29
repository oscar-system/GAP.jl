##
gap> START_TEST( "wrapper.tst" );

## create a type for wrapped objects
gap> fam := NewFamily("MyJuliaWrapperFamily");;
gap> type := NewType(fam, IsJuliaWrapper and IsAttributeStoringRep);;

## wrap a Julia object
gap> n := GAPToJulia(2^100);
<Julia: 1267650600228229401496703205376>
gap> N := Objectify(type, rec());;
gap> SetJuliaPointer(N, n);
gap> Julia.Base.typeof(N);
<Julia: BigInt>
gap> N(1);
Error, MethodError: objects of type BigInt are not callable

## wrap a Julia function
gap> f := Objectify(type, rec());;
gap> SetJuliaPointer(f, Julia.Base.sqrt);
gap> Julia.Base.typeof(f);
<Julia: typeof(sqrt)>
gap> f(4);
<Julia: 2.0>

##
gap> STOP_TEST( "wrapper.tst", 1 );
