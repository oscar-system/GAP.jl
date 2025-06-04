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
#@local HelpTestFunction, str
gap> START_TEST( "help.tst" );

#
gap> HelpTestFunction:= topic -> IsString( HelpString( topic, false ) ) and
>                                IsString( HelpString( topic, true ) );;

# navigate in the help
gap> HelpTestFunction( "" );  # first help access
true
gap> HelpTestFunction( "" );  # show the last shown entry again
true
gap> HelpTestFunction( "&" ); # show the last shown entry again
true
gap> HelpTestFunction( "-" ); # show the previous entry in help history
true
gap> HelpTestFunction( "+" ); # show the next entry in help history
true
gap> HelpTestFunction( "<" ); # show the topic before the last shown one
true
gap> HelpTestFunction( "<<" ); # show the last topic's chapter's start
true
gap> HelpTestFunction( ">" ); # show the topic after the last shown one
true
gap> HelpTestFunction( ">>" ); # show the next chapter's start
true
gap> HelpTestFunction( "welcome to gap" ); # show welcome info
true

# substring search
gap> HelpTestFunction( "?determinant" );
true

# ask for overviews
gap> HelpTestFunction( "books" );
true
gap> HelpTestFunction( "tut:chapters" );
true
gap> HelpTestFunction( "tut:sections" );
true

# ask for help about topics
gap> HelpTestFunction( "isobject" );
true
gap> HelpTestFunction( "tut:isobject" );
true
gap> HelpTestFunction( "ref:isobject" );
true
gap> HelpTestFunction( "unknow" );
true
gap> HelpTestFunction( "something for which no match is found" );
true

# help for documented Julia functions
gap> HelpString( "Julia:wrap_rng" ) = "Help: no matching entry found";
true
gap> str:= HelpString( "Julia:GAP.wrap_rng" );; # is not exported from GAP
gap> PositionSublist( str, "wrap_rng" ) <> fail;
true
gap> str:= HelpString( "Julia:GAP.GapObj" );;
gap> PositionSublist( str, "GapObj" ) <> fail;
true
gap> str:= HelpString( "Julia:sqrt" );; # is from Julia.Base
gap> PositionSublist( str, "sqrt" ) <> fail;
true

#
gap> STOP_TEST( "help.tst" );
