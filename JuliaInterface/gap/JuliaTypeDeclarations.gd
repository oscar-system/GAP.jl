#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2018
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##
#############################################################################

## Internal
DeclareCategory( "IsJuliaObject", IsObject );

JuliaObjectFamily := NewFamily( "JuliaObjectFamily" );

BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));
