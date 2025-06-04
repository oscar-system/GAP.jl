#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
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

## wrap a Julia function
gap> f := Objectify(type, rec());;
gap> SetJuliaPointer(f, Julia.Base.sqrt);
gap> Julia.Base.typeof(GAP_jl.UnwrapJuliaFunc(f));
<Julia: typeof(sqrt)>
gap> f(4);
<Julia: 2.0>

##
gap> STOP_TEST( "wrapper.tst", 1 );
