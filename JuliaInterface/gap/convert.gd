#############################################################################
##
##  JuliaInterface package
##
#############################################################################

#
DeclareConstructor("JuliaToGAP", [IsObject, IsObject]);

#
DeclareOperation("GAPToJulia", [IsJuliaObject, IsObject]);
