#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2018
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##
#! @Chapter Functions
#! @Section Functions
##
#############################################################################

## Internal
BindGlobal( "__JuliaFunctions", rec( ) );

#! @Arguments function_name[, module_name]
#! @Returns a Julia function
#! @Description
#!  Returns the Julia function <A>function_name</A> from the module <A>module_name</A>.
#!  Both arguments must be strings. If <A>module_name</A> is not given, the function
#!  is taken from the <C>Main</C> module. The resulting Julia function can be called on either Julia objects
#!  or objects that can be boxed to Julia objects. The result will always be a Julia object.
DeclareGlobalFunction( "JuliaFunction" );

#! @Arguments variable_name[, module_name]
#! @Returns a Julia object
#! @Description
#!  Returns the Julia object <A>variable_name</A> from the module <A>module_name</A>.
#!  Both arguments must be strings. If <A>module_name</A> is not given, the variable
#!  is taken from the <C>Main</C> module. The result of this function is a Julia object, that can
#!  be passed as argument to Julia functions.
DeclareGlobalFunction( "JuliaGetGlobalVariable" );

#! @Arguments object
#! @Returns julia_object
#! @Description
#!  Retuns a Julia object that is a sensible conversion to Julia of the object <A>object</A>.
#!  If no conversion exists, <C>fail</C> is returned.
DeclareOperation( "ConvertedToJulia", [ IsObject ] );

#! @Arguments julia_object
#! @Returns object
#! @Description
#!  Retuns an object that is a sensible conversion from the Julia object <A>julia_object</A>.
#!  If no conversion exists, <C>fail</C> is returned.
DeclareOperation( "ConvertedFromJulia", [ IsJuliaObject ] );

#! @Arguments julia_object
#! @Returns an object
#! @Description
#!  Like structural copy, also converts the contents of a Julia list recursively to GAP objects.
DeclareGlobalFunction( "JuliaStructuralUnbox" );

## Internal
BindGlobal( "__JULIAINTERFACE_MODULE_NAME",
  function( module_name )
    if Length( module_name ) = 0 then
        return "Main";
    else
        return module_name[ 1 ];
    fi;
end );

## Internal
BindGlobal( "__JULIAINTERFACE_PREPARE_RECORD",
  function( module_name )

    if module_name = "Main" and IsBound( Julia.Main ) then
        return module_name;
    fi;
    
    if IsBound( Julia.(module_name) ) and ( not IsBound( Julia.(module_name).__JULIAINTERFACE_NOT_IMPORTED_YET ) ) then
        return fail;
    fi;

    if not IsBound( Julia.(module_name) ) then
        JuliaEvalString( Concatenation( "import ", module_name ) );
        Julia.(module_name) := rec( __JULIAINTERFACE_NOT_IMPORTED_YET := true );
    fi;

    return module_name;

end );

#! @Arguments function_name[, module_name]
#! @Description
#!  Stores the Julia function <A>function_name</A> from the module <A>module_name</A>
#!  in the <C>Julia</C> record, as <C>Julia</C>.<A>module_name</A>.<A>function_name</A>,
#!  to have quick access if the function is needed in several places. The default value for
#!  <A>module_name</A> is <C>"Main"</C>.
DeclareGlobalFunction( "BindJuliaFunc" );
InstallGlobalFunction( BindJuliaFunc,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    if IsBound( Julia.(module_name) ) and IsBound( Julia.(module_name).(julia_name) ) then
        return;
    fi;
    module_name := __JULIAINTERFACE_PREPARE_RECORD( module_name );
    if module_name = fail then
        return;
    fi;
    Julia.(module_name).(julia_name) := JuliaFunction( julia_name, module_name );
end );

#! @Arguments object_name[, module_name]
#! @Description
#!  Stores the Julia object <A>object_name</A> from the module <A>module_name</A>
#!  in the <C>Julia</C> record, as <C>Julia</C>.<A>module_name</A>.<A>object_name</A>,
#!  to have quick access if the object is needed in several places. The default value for
#!  <A>module_name</A> is <C>"Main"</C>.
DeclareGlobalFunction( "BindJuliaObj" );
InstallGlobalFunction( BindJuliaObj,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    if IsBound( Julia.(module_name) ) and IsBound( Julia.(module_name).(julia_name) ) then
        return;
    fi;
    module_name := __JULIAINTERFACE_PREPARE_RECORD( module_name );
    if module_name = fail then
        return;
    fi;
    Julia.(module_name).(julia_name) := JuliaGetGlobalVariable( julia_name, module_name );
end );

#! @Arguments function_name[, module_name]
#! @Description
#!  Returns the julia function <A>function_name</A> from the module <A>module_name</A>.
#!  As a side effect, it also
#!  stores the Julia function <A>function_name</A> from the module <A>module_name</A>
#!  in the <C>Julia</C> record, as <C>Julia</C>.<A>module_name</A>.<A>function_name</A>,
#!  to have quick access if the function is needed in several places. The default value for
#!  <A>module_name</A> is <C>"Main"</C>.
DeclareGlobalFunction( "GetJuliaFunc" );
InstallGlobalFunction( GetJuliaFunc,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    BindJuliaFunc( julia_name, module_name );
    return Julia.(module_name).(julia_name);
end );

#! @Arguments object_name[, module_name]
#! @Description
#!  Returns the julia object <A>object_name</A> from the module <A>module_name</A>.
#!  As a side effect, it also
#!  stores the Julia object <A>object_name</A> from the module <A>module_name</A>
#!  in the <C>Julia</C> record, as <C>Julia</C>.<A>module_name</A>.<A>object_name</A>,
#!  to have quick access if the object is needed in several places. The default value for
#!  <A>module_name</A> is <C>"Main"</C>.
DeclareGlobalFunction( "GetJuliaObj" );
InstallGlobalFunction( GetJuliaObj,
  function( julia_name, module_name... )
    module_name := __JULIAINTERFACE_MODULE_NAME( module_name );
    BindJuliaObj( julia_name, module_name );
    return Julia.(module_name).(julia_name);
end );

DeclareGlobalFunction( "ImportJuliaModuleIntoGAP" );
