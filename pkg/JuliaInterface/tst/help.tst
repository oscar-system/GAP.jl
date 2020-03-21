#@local HelpTestFunction
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

#
gap> STOP_TEST( "help.tst" );
