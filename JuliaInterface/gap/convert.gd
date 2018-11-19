#############################################################################
##
##  JuliaInterface package
##
#############################################################################

#
DeclareConstructor("JuliaToGAP", [IsObject, IsObject]);
DeclareConstructor("JuliaToGAP", [IsObject, IsObject, IsBool]);

#
DeclareGlobalFunction("GAPToJulia");
