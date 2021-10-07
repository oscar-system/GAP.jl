BindGlobal("_ORIG_ExecuteProcess", ExecuteProcess);
MakeReadWriteGlobal("ExecuteProcess");
ExecuteProcess := Julia.GAP.GAP_ExecuteProcess;
MakeReadOnlyGlobal("ExecuteProcess");
