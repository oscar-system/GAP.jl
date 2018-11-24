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
BindGlobal( "_JuliaFunctions", rec( ) );

#! @Arguments function_name[, module_name]
#! @Returns a Julia function
#! @Description
#!  Returns the Julia function <A>function_name</A> from the module <A>module_name</A>.
#!  Both arguments must be strings. If <A>module_name</A> is not given,
#!  the function is taken from the <C>Main</C> module.
#!  The resulting Julia function can be called on either Julia objects
#!  or objects that can be boxed to Julia objects.
#!
#!  The result will always be a Julia object.
DeclareGlobalFunction( "JuliaFunction" );

#! @Arguments variable_name[, module_name]
#! @Returns a Julia object
#! @Description
#!  Returns the Julia object <A>variable_name</A> from the module <A>module_name</A>.
#!  Both arguments must be strings. If <A>module_name</A> is not given, 
#!  the variable is taken from the <C>Main</C> module.
#!
#!  The result of this function is a Julia object, that can
#!  be passed as argument to Julia functions.
DeclareGlobalFunction( "JuliaGetGlobalVariable" );

#! @Arguments filename
#! @Returns nothing.
#! @Description
#!  TODO.
DeclareGlobalFunction( "JuliaIncludeFile" );


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

#! @Description
#!  If any component or positional object <C>obj</C> is in this category,
#!  then calling a Julia function with <C>obj</C> as an argument
#!  will not pass it as an <C>MPtr</C>,
#!  but instead <C>JuliaPointer(obj)</C> is passed, which must be a Julia object.
#!  This allows implementing high-level wrapper objects
#!  for Julia object that behave just like the wrapped Julia
#!  objects when used as arguments in calls to Julia functions.
DeclareCategory( "IsJuliaWrapper", IsObject );

#! @Description
#!  Attribute for objects in the category <C>IsJuliaWrapper</C>.
#!  The value of this attribute must be a Julia object.
DeclareAttribute( "JuliaPointer", IsJuliaWrapper );

DeclareCategory( "IsJuliaModule", IsObject and IsJuliaWrapper  );
BindGlobal( "TheFamilyOfJuliaModules", NewFamily( "TheFamilyOfJuliaModules" ) );
BindGlobal( "TheTypeOfJuliaModules", NewType( TheFamilyOfJuliaModules, IsJuliaModule and IsAttributeStoringRep ) );

#! @Description
#!  TODO
DeclareGlobalVariable( "Julia" );

#! @Arguments module
#! @Returns a list of strings
#! @Description
#!  Returns a list of names of components currently bound
#!  in <A>module</A>. Please note that this does usually
#!  not reflect all symbols bound to a module on the
#!  &Julia; side: Even if a module has been imported
#!  in Julia, this list of symbols does only
#!  reflect the variables currently stored in the GAP
#!  module object. It might be possible to access
#!  further Julia variables or functions in this module.
DeclareGlobalFunction( "JuliaSymbolsInModule" );


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

#! @Arguments name
#! @Returns a julia object
#! @Description
#!  Returns the Julia objects that points to the module
#!  with <A>name</A>. Note that the module needs to be
#!  imported before being present.
DeclareGlobalFunction( "JuliaModule" );
