# create output stream for use by JuliaInterface
BindGlobal("_JULIAINTERFACE_ORIGINAL_ERROR_OUTPUT", ERROR_OUTPUT);
BindGlobal("_JULIAINTERFACE_ERROR_BUFFER", "");
BindGlobal("_JULIAINTERFACE_ERROR_OUTPUT", OutputTextString(_JULIAINTERFACE_ERROR_BUFFER, true));
SetPrintFormattingStatus(_JULIAINTERFACE_ERROR_OUTPUT, false);

# set it as GAP's default error output stream
MakeReadWriteGlobal("ERROR_OUTPUT");
ERROR_OUTPUT := _JULIAINTERFACE_ERROR_OUTPUT;
MakeReadOnlyGlobal("ERROR_OUTPUT");
