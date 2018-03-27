
DeclareCategory( "IsJuliaFunction", IsObject );
DeclareCategory( "IsJuliaObject", IsObject );

JuliaFunctionFamily := NewFamily( "JuliaFunctionFamily" );
JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );

BindGlobal("TheTypeJuliaFunction", NewType( JuliaFunctionFamily, IsJuliaFunction ));
BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));

BindGlobal( "gap_obj_gc_list", [ true ] );
gap_obj_gc_list[1000] := true;
BindGlobal( "gap_obj_gc_list_positions", List( [ 1 .. 1000 ], IdFunc ) );

BindGlobal( "Julia", rec( ) );
