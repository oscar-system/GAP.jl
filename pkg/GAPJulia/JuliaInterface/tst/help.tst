#@local HelpTestFunction
gap> START_TEST( "help.tst" );

#
gap> HelpTestFunction:= topic -> IsString( HelpString( topic, false ) ) and
>                                IsString( HelpString( topic, true ) );;

#
gap> HelpTestFunction( "IsObject" );
true
gap> HelpTestFunction( "Unknow" );
true
gap> HelpTestFunction( "something for which no match is found" );
true

#
gap> STOP_TEST( "help.tst" );
