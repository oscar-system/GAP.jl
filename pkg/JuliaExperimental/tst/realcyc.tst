#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##
#@local a,b,c,d,z
gap> START_TEST( "realcyc.tst" );

# need 16 bits precision
gap> IsPositiveRealPartCyclotomic( ER(5) - 223/100 : ShowPrecision );
#I  precision needed: 16
true
gap> IsPositiveRealPartCyclotomic( ER(5) - 2 );
true

# need 32 bits precision
gap> IsPositiveRealPartCyclotomic( ER(5) - 2236/1000 : ShowPrecision );
#I  precision needed: 32
true
gap> IsPositiveRealPartCyclotomic( ER(5) - 2236067/1000000 );
true

# need 64 bits precision
gap> IsPositiveRealPartCyclotomic( ER(5) - 2236067977499/1000000000000
>        : ShowPrecision );
#I  precision needed: 64
true
gap> IsPositiveRealPartCyclotomic( ER(5) - 2236067977500/1000000000000 );
false

# example from Frank L"ubeck's 'futil' package,
# needs 256 bits precision
gap> a:= EY(5);;  b:= EY(7);;  c:= EY(11);;  d:= EY(12);;
gap> z:= [ -12230241886849032, -27721673763224765,
>           19808983844326917,   5079707604555803 ] * [ a, b, c, d ];;
gap> IsPositiveRealPartCyclotomic( z : ShowPrecision );
#I  precision needed: 256
false

##
gap> Julia.GAPRealCycModule.test_this_module();
true

##
gap> STOP_TEST( "realcyc.tst" );
