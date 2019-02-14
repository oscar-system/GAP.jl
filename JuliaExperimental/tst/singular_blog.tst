#############################################################################
##
#W  singular_blog.tst  GAP 4 package JuliaExperimental          Thomas Breuer
##
##  Run the examples from a blog post by Bill Hart, see
##  'https://wbhart.blogspot.de/2017/01/singular-and-julia.html'.
##
##  The examples use (mainly) the Singular objects and the Julia functions,
##  not GAP wrappers.
##
gap> START_TEST( "singular_blog.tst" );

##  Load the package.
gap> LoadPackage( "JuliaExperimental", false );;

##  Now Singular has been loaded into Julia.
##  Create a Nemo residue ring over Singular's ring of integers.
gap> R:= Julia.Nemo.ResidueRing( Julia.Singular.ZZ, 23 );
<Julia: Residue Ring of Integer Ring modulo 23>
gap> R(12) + R(7);
<Julia: 19>
gap> JuliaTypeInfo( R(12) );
"Singular.n_Zn"
gap> Julia.Base.parent( R(12) );
<Julia: Residue Ring of Integer Ring modulo 23>

##  polynomial rings, polynomials
gap> indetnames:= Julia.Base.convert( JuliaEvalString( "Array{String,1}" ),
>                     GAPToJulia( [ "x", "y", "z", "t" ] ) );
<Julia: ["x", "y", "z", "t"]>
gap> Rinfo:= Julia.Singular.PolynomialRing( Julia.Singular.QQ, indetnames );
<Julia: (Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C), Singular.spoly{Sin\
gular.n_Q}[x, y, z, t])>
gap> R:= Rinfo[1];
<Julia: Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)>
gap> indets:= JuliaToGAP( IsList, Rinfo[2] );
[ <Julia: x>, <Julia: y>, <Julia: z>, <Julia: t> ]
gap> x:= indets[1];; y:= indets[2];; z:= indets[3];; t:= indets[4];;
gap> f:= (x+y+z)*(x^2*y + 2*x);
<Julia: x^3*y+x^2*y^2+x^2*y*z+2*x^2+2*x*y+2*x*z>
gap> g:= (x+y+z)*(x+z+t);
<Julia: x^2+x*y+2*x*z+y*z+z^2+x*t+y*t+z*t>
gap> Julia.Base.gcd( f, g );
<Julia: x+y+z>

##  ideals
gap> I1:= Julia.Singular.Ideal( R );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators ()>
gap> I2:= Julia.Singular.Ideal( R, x, t*z + x );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x, z*t+x)>
gap> Julia.Singular.ngens( I2 );
2
gap> I2[2];
<Julia: z*t+x>

##  Groebner basis
gap> I:= Julia.Singular.Ideal( R, x*y + 1, x+y, 2*x+y+z );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x*y+1, x+y, 2*x+y+z)>
gap> gbasis:= Julia.Singular.std( I );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (y-z, 2*x+y+z, z^2-1)>
gap> Julia.Singular.ngens( gbasis );
3

##  syzygy matrix
##  (Currently there is no 'Julia.Singular.Matrix'.)
gap> M:= Julia.Singular.syz( I );
<Julia: Singular Module over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)\
, with Generators:
x*gen(3)-2*x*gen(2)+y*gen(3)-y*gen(2)-z*gen(2)
y^2*gen(3)-y^2*gen(2)-y*z*gen(2)-y*gen(1)+z*gen(1)-gen(3)+2*gen(2)
x*y*gen(2)-x*gen(1)-y*gen(1)+gen(2)>
gap> JuliaFunction( "Matrix", "Singular" )( M );
<Julia: [0, -y+z, -x-y
-2*x-y-z, -y^2-y*z+2, x*y+1
x+y, y^2-1, 0]>

##  ideal arithmetic
gap> I:= Julia.Singular.Ideal( R, x*y + 1, x+y, 2*x+y+z );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x*y+1, x+y, 2*x+y+z)>
gap> J:= Julia.Singular.Ideal( R, 2*x-y + 1, 2*z+x);
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (2*x-y+1, x+2*z)>
gap> I^2;
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x^2*y^2+2*x*y+1, x^2*y+x*y^2+x+y, 2*x^2*y+x*y^2+x*y*z+2*x+y+z\
, x^2+2*x*y+y^2, 2*x^2+3*x*y+y^2+x*z+y*z, 4*x^2+4*x*y+y^2+4*x*z+2*y*z+z^2)>
gap> I * J;
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (2*x^2*y-x*y^2+x*y+2*x-y+1, x^2*y+2*x*y*z+x+2*z, 2*x^2+x*y-y^2\
+x+y, x^2+x*y+2*x*z+2*y*z, 4*x^2-y^2+2*x*z-y*z+2*x+y+z, 2*x^2+x*y+5*x*z+2*y*z+\
2*z^2)>
gap> Julia.Singular.lead( I );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x*y, x, 2*x)>

##  resolutions
gap> I:= Julia.Singular.MaximalIdeal( R, 1 );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (x, y, z, t)>
gap> I:= Julia.Singular.std( I );
<Julia: Singular Ideal over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C) \
with generators (t, z, y, x)>
gap> r:= Julia.Singular.sres( I, 5 );
<Julia: Singular Resolution:
R^1 <- R^4 <- R^6 <- R^4 <- R^1>

##  access to modules in the resolution
gap> r[2];
<Julia: Singular Module over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)\
, with Generators:
-z*gen(1)+t*gen(2)
-y*gen(1)+t*gen(3)
-y*gen(2)+z*gen(3)
-x*gen(1)+t*gen(4)
-x*gen(2)+z*gen(4)
-x*gen(3)+y*gen(4)>
gap> r[3];
<Julia: Singular Module over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)\
, with Generators:
y*gen(1)-z*gen(2)+t*gen(3)
x*gen(1)-z*gen(4)+t*gen(5)
x*gen(2)-y*gen(4)+t*gen(6)
x*gen(3)-y*gen(5)+z*gen(6)>
gap> r[3][1];
<Julia: y*gen(1)-z*gen(2)+t*gen(3)>

##  arithmetic on module elements
gap> r[2][1] * 3;
<Julia: -3*z*gen(1)+3*t*gen(2)>
gap> # no: r[2][1] * (x*y+1);
gap> r[2][1] + r[2][2];
<Julia: -y*gen(1)-z*gen(1)+t*gen(3)+t*gen(2)>

##  standard bases and resolutions of modules
gap> J:= Julia.Singular.std( r[3] );
<Julia: Singular Module over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)\
, with Generators:
y*gen(1)-z*gen(2)+t*gen(3)
x*gen(1)-z*gen(4)+t*gen(5)
x*gen(2)-y*gen(4)+t*gen(6)
x*gen(3)-y*gen(5)+z*gen(6)>
gap> J1:= Julia.Singular.sres( J, 4 );
<Julia: Singular Resolution:
R^6 <- R^4 <- R^1>
gap> J1[2];
<Julia: Singular Module over Singular Polynomial Ring (QQ),(x,y,z,t),(dp(4),C)\
, with Generators:
-x*gen(1)+y*gen(2)-z*gen(3)+t*gen(4)>

##  generic multivariate polynomial code in Nemo,
##  over a Singular coefficient ring
##  (strange: runs into Julia MethodError over QQ instead of ZZ ...)
gap> Rinfo:= Julia.Nemo.PolynomialRing( Julia.Singular.ZZ, indetnames );
<Julia: (Multivariate Polynomial Ring in x, y, z, t over Integer Ring, Abstrac\
tAlgebra.Generic.MPoly{Singular.n_Z}[x, y, z, t])>
gap> R:= Rinfo[1];;
gap> indets:= JuliaToGAP( IsList, Rinfo[2] );;
gap> x:= indets[1];; y:= indets[2];; z:= indets[3];; t:= indets[4];;
gap> f:= (2*t^2078*z^15*y^53-28*t^1080*z^15*y^44+98*t^82*z^15*y^35)*x^9
>       +(t^2003*y^40-14*t^1005*y^31+49*t^7*y^22)*x^7
>       +((t^2100+t^2000)*y^40 +(-4*t^1079*z^16+156*t^1078*z^15)*y^33
>         +(-14*t^1102-14*t^1002)*y^31+(28*t^81*z^16-1092*t^80*z^15)*y^24
>         +(49*t^104+49*t^4)*y^22)*x^6
>       +((-2*t^1004*z+78*t^1003)*y^20+(14*t^6*z-546*t^5)*y^11)*x^4
>       +(((-2*t^1101-2*t^1001)*z+(78*t^1100+78*t^1000))*y^20
>         +(2*t^80*z^17-156*t^79*z^16+3042*t^78*z^15)*y^13
>         +((14*t^103+14*t^3)*z+(-546*t^102-546*t^2))*y^11)*x^3
>       +(t^5*z^2-78*t^4*z+1521*t^3)*x
>       +((t^102+t^2)*z^2+(-78*t^101-78*t)*z+(1521*t^100+1521));;
gap> g:= (4*t^1156*z^30*y^46-28*t^158*z^30*y^37)*x^9
>       +(4*t^1081*z^15*y^33-28*t^83*z^15*y^24)*x^7
>       +((4*t^1178+4*t^1078)*z^15*y^33+(-4*t^157*z^31+156*t^156*z^30)*y^26
>         +(-28*t^180-28*t^80)*z^15*y^24)*x^6
>       +(t^1006*y^20-7*t^8*y^11)*x^5
>       +((2*t^1103+2*t^1003)*y^20+(-4*t^82*z^16+156*t^81*z^15)*y^13
>         +(-14*t^105-14*t^5)*y^11)*x^4
>       +((t^1200+2*t^1100+t^1000)*y^20+((-4*t^179-4*t^79)*z^16
>         +(156*t^178+156*t^78)*z^15)*y^13+(-7*t^202-14*t^102-7*t^2)*y^11)*x^3
>       +(-t^7*z+39*t^6)*x^2
>       +((-2*t^104-2*t^4)*z+(78*t^103+78*t^3))*x
>       +((-t^201-2*t^101-t)*z+(39*t^200+78*t^100+39));;
gap> p:= Julia.Base.gcd( f, g );
<Julia: -2*x^6*y^33*z^15*t^1078+14*x^6*y^24*z^15*t^80-x^4*y^20*t^1003+7*x^4*y^\
11*t^5-x^3*y^20*t^1100-x^3*y^20*t^1000+2*x^3*y^13*z^16*t^79-78*x^3*y^13*z^15*t\
^78+7*x^3*y^11*t^102+7*x^3*y^11*t^2+x*z*t^4-39*x*t^3+z*t^101+z*t-39*t^100-39>

##
gap> STOP_TEST( "singular_blog.tst" );

