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
DeclareGlobalFunction( "StructuralConvertedFromJulia" );

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


#! @Arguments pkgname
#! @Returns <K>true</K> or <K>false</K>.
#! @Description
#!  This function triggers the execution of an <C>import</C> statement
#!  for the &Julia; package with name <A>pkgname</A>.
#!  It returns <K>true</K> if the call was successful,
#!  and <K>false</K> otherwise.
#!  <P/>
#!  Note that we just want to load the package into &Julia;,
#!  we do <E>not</E> want to import variable names from the package
#!  into &Julia;'s <C>Main</C> module, because the &Julia; variables must be
#!  referenced relative to their modules if we want to be sure to access
#!  the correct values.
#!  <P/>
#!  Why is this function needed?
#!  <P/>
#!  Apparently <C>libjulia</C> throws an error
#!  when trying to compile the package, which happens when some files from
#!  the package have been modified since compilation.
#!  <P/>
#!  Thus &GAP; has to check whether the &Julia; package has been loaded
#!  successfully, and can then safely load and execute code
#!  that relies on this &Julia; package.
#!  In particular, we cannot just put the necessary <C>import</C> statements
#!  into the relevant <F>.jl</F> files,
#!  and then load these files with <Ref Func="JuliaIncludeFile"/>.
DeclareGlobalFunction( "JuliaImportPackage" );


#! @Arguments name
#! @Returns nothing.
#! @Description
#!  The aim of this function is to make those global variables
#!  that are exported by the &Julia; module with name <A>name</A>
#!  available in the global record <C>Julia</C>.
#!  After the call, the <A>name</A> component of this record will be bound
#!  to a record that contains the variables from the &Julia; module.
DeclareGlobalFunction( "ImportJuliaModuleIntoGAP" );


#! @Arguments juliaobj
#! @Returns a string.
#! @Description
#!  Returns the string that describes the julia type of the &Julia; object
#!  <A>juliaobj</A>.
DeclareGlobalFunction( "JuliaTypeInfo" );


#! @Arguments juliafunc, arguments
#! @Returns a record.
#! @Description
#!  The function calls the &Julia; function <A>juliafunc</A>
#!  with arguments in the list <A>arguments</A>,
#!  and returns a record with the components <C>ok</C> and <C>value</C>.
#!  If no error occured then <C>ok</C> has the value <K>true</K>,
#!  and <C>value</C> is the value returned by <A>juliafunc</A>.
#!  If an error occured then <C>ok</C> has the value <K>false</K>,
#!  and <C>value</C> is the error message as a &GAP; string.
DeclareGlobalFunction( "CallJuliaFunctionWithCatch" );


