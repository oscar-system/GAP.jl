

jl_module_t* get_module_from_string( char* name )
{
    jl_value_t* module_value = jl_eval_string( name );
    JULIAINTERFACE_EXCEPTION_HANDLER
    if(!jl_is_module(module_value))
        ErrorQuit("Not a module",0,0);
    return (jl_module_t*)module_value;
}
