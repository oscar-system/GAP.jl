
DeclareCategory( "IsJuliaFunction", IsObject );
DeclareCategory( "IsJuliaObject", IsObject );

JuliaFunctionFamily := NewFamily( "JuliaFunctionFamily" );
JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );

BindGlobal("TheTypeJuliaFunction", NewType( JuliaFunctionFamily, IsJuliaFunction ));
BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));

BindGlobal( "gap_obj_gc_list", [ ] );
BindGlobal( "gap_obj_gc_list_positions", [ 1 ] );

BindGlobal( "Julia", rec( ) );
