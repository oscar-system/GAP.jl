#############################################################################
##
#W  record.tst         GAP 4 package JuliaExperimental          Thomas Breuer
##
##
gap> START_TEST( "record.tst" );

##  empty record
gap> dict:= ConvertedToJulia( rec() );
<Julia: Dict{Any,Any}()>
gap> JuliaUnbox( dict );
fail
gap> JuliaUnboxRecordFromDictionary( dict );
rec(  )
gap> JuliaStructuralUnbox_AlsoRecord( dict );
rec(  )

##  something which cannot be boxed
gap> ConvertedToJulia( rec( GAPfunc:= ( x -> 1 ) ) );
fail

##  something which is recursive
gap> dict:= ConvertedToJulia( rec( bool:= true,
>                          string:= "abc",
>                          list:= [ 1, 2, 3 ],
>                          Juliafunc:= Julia.Base.map,
>                        ) );;
gap> JuliaUnboxRecordFromDictionary( dict );
rec( Juliafunc := <Julia: map>, bool := <Julia: true>, 
  list := <Julia: Any[1, 2, 3]>, string := <Julia: abc> )
gap> JuliaStructuralUnbox_AlsoRecord( dict );
rec( Juliafunc := fail, bool := true, list := [ 1, 2, 3 ], string := "abc" )

##
gap> STOP_TEST( "record.tst", 1 );

