#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2018
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##

#! @Chapter Introduction to <Package>JuliaInterface</Package>
#!  The &GAP; package <Package>JuliaInterface</Package> is part of
#!  a bidirectional interface between &GAP; and &Julia;.
#!
#!  TODO: state the aims, describe the installation

#! @Chapter Using &Julia; from &GAP;
#! @Section Filters for <Package>JuliaInterface</Package>

#! @Arguments obj
#! @Returns <K>true</K> or <K>false</K>
#! @Description
#!  The result is <K>true</K> if and only if <A>obj</A> is a pointer to a
#!  &Julia; object.
#!  <P/>
#!  The results of <Ref Func="JuliaModule"/> are always in
#!  <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
#!  The results of <Ref Func="JuliaEvalString"/> are in
#!  <Ref Filt="IsArgumentForJuliaFunction" Label="for IsObject"/>
#!  but not necessarily in <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
#!  <!-- What about &Julia; functions (see <Ref Func="JuliaFunction"/>)? -->
#! @BeginExampleSession
#! gap> julia_fun:= JuliaEvalString( "sqrt" );
#! <Julia: sqrt>
#! gap> IsJuliaObject( julia_fun );
#! true
#! gap> julia_val:= julia_fun( 2 );
#! <Julia: 1.4142135623730951>
#! gap> IsJuliaObject( julia_val );
#! true
#! gap> julia_x:= JuliaEvalString( "x = 4" );
#! 4
#! gap> IsJuliaObject( julia_x );
#! false
#! gap> IsJuliaObject( JuliaModule( "Main" ) );
#! true
#! @EndExampleSession
DeclareCategory( "IsJuliaObject", IsObject );

BindGlobal( "JuliaObjectFamily", NewFamily( "JuliaObjectFamily" ) );

BindGlobal("TheTypeJuliaObject", NewType( JuliaObjectFamily, IsJuliaObject ));

#! @Arguments obj
#! @Description
#!  If the component or positional object <A>obj</A> is in this filter
#!  then calling a &Julia; function with <A>obj</A> as an argument
#!  will not pass <A>obj</A> as an <C>MPtr</C>,
#!  but instead its <Ref Attr="JuliaPointer" Label="for IsJuliaWrapper"/>
#!  value is passed, which must be a &Julia; object.
#!  This admits implementing high-level wrapper objects
#!  for &Julia; objects that behave just like the &Julia; objects
#!  when used as arguments in calls to &Julia; functions.
#!  <!-- No other functionality is implemented for IsJuliaWrapper -->
#!  <P/>
#!  Objects in <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>
#!  should <E>not</E> be in the filter
#!  <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
#!  <P/>
#!  Examples of objects in <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>
#!  are the return values of <Ref Func="JuliaModule"/>.
DeclareCategory( "IsJuliaWrapper", IsObject );

#! @Arguments obj
#! @Description
#!  is an attribute for &GAP; objects in the filter
#!  <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>.
#!  The value must be a &Julia; object.
#! @BeginExampleSession
#! gap> Julia;
#! <Julia module Main>
#! gap> IsJuliaObject( Julia );
#! false
#! gap> IsJuliaWrapper( Julia );
#! true
#! gap> ptr:= JuliaPointer( Julia );
#! <Julia: Main>
#! gap> IsJuliaObject( ptr );
#! true
#! @EndExampleSession
DeclareAttribute( "JuliaPointer", IsJuliaWrapper );

#! @Arguments obj
#! @Description
#!  This filter is set in those &GAP; objects that represent &Julia; modules.
#!  A submodule of a module can be accessed like a record component,
#!  provided that this submodule has already been imported,
#!  see <Ref Func="ImportJuliaModuleIntoGAP"/>.
#!  &Julia; variables from a module can be accessed like record components.
#! @BeginExampleSession
#! gap> IsJuliaModule( Julia );
#! true
#! gap> Julia.GAP;
#! <Julia module GAP>
#! gap> IsJuliaModule( Julia.GAP );
#! true
#! gap> Julia.GAP.julia_to_gap;
#! function( arg... ) ... end
#! gap> JuliaFunction( "julia_to_gap", "GAP" );  # the same function
#! function( arg... ) ... end
#! @EndExampleSession
DeclareCategory( "IsJuliaModule", IsJuliaWrapper  );

BindGlobal( "TheFamilyOfJuliaModules", NewFamily( "TheFamilyOfJuliaModules" ) );
BindGlobal( "TheTypeOfJuliaModules", NewType( TheFamilyOfJuliaModules, IsJuliaModule and IsAttributeStoringRep ) );

#! @Arguments obj
#! @Description
#!  This filter is set in all those &GAP; objects that can be used
#!  as arguments of &Julia; functions.
#!  These are the objects in
#!  <Ref Filt="IsJuliaObject" Label="for IsObject"/>,
#!  <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>,
#!  <Ref Filt="IsBool" BookName="ref"/>,
#!  <C>IsInt and IsSmallIntRep</C> (see <Ref Chap="Integers" BookName="ref"/>,
#!  and <C>IsFFE and IsInternalRep</C> (see <Ref Filt="IsFFE" BookName="ref"/>.
DeclareCategory( "IsArgumentForJuliaFunction", IsObject );

InstallTrueMethod( IsArgumentForJuliaFunction, IsJuliaObject );
InstallTrueMethod( IsArgumentForJuliaFunction, IsJuliaWrapper );
InstallTrueMethod( IsArgumentForJuliaFunction, IsBool );
InstallTrueMethod( IsArgumentForJuliaFunction, IsInt and IsSmallIntRep );
InstallTrueMethod( IsArgumentForJuliaFunction, IsFFE and IsInternalRep );


#! @Section Creating &Julia; objects

#! @Arguments string
#! @Description
#!  evaluates the string <A>string</A> in the current &Julia; session,
#!  in the <C>Main</C> module,
#!  and returns &Julia;'s return value.
#! @BeginExampleSession
#! gap> JuliaEvalString( "x = 2^2" );  # assignment to a variable in Julia
#! 4
#! gap> JuliaEvalString( "x" );        # access to this variable
#! 4
#! @EndExampleSession
#DeclareGlobalFunction( "JuliaEvalString" );

#! @Arguments filename
#! @Returns nothing.
#! @Description
#!  calls &Julia;'s <C>Base.include</C> with the string <A>filename</A>.
#!  This means that the &Julia; code in the file with this name gets
#!  executed in the current &Julia; session.
#!  If the file defines a new &Julia; module then the next step will be
#!  to import this module, see <Ref Func="ImportJuliaModuleIntoGAP"/>.
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


#! @Section Access to &Julia; objects

## Internal
BindGlobal( "_JuliaFunctions", rec( ) );

#! @Arguments function_name[, module_name]
#! @Returns a function
#! @Description
#! Returns a &GAP; function that wraps the &Julia; function with identifier
#! <A>function_name</A> from the module <A>module_name</A>.
#! Both arguments must be strings.
#! If <A>module_name</A> is not given,
#! the function is taken from &Julia;'s <C>Main</C> module.
#! The returned function can be called on arguments in
#! <Ref Filt="IsArgumentForJuliaFunction" Label="for IsObject"/>.
#! <!-- The result is not in IsJuliaObject, note that JuliaFunction calls
#!      _JuliaFunction, which calls NewJuliaFunc;
#!      and this returns a GAP function that delegates to
#!      DoCallJuliaFunc0Arg etc. -->
#! @BeginExampleSession
#! gap> fun:= JuliaFunction( "sqrt" );
#! function( arg... ) ... end
#! gap> Print( fun );
#! function ( arg... )
#!     <<kernel code>> from Julia:sqrt
#! end
#! @EndExampleSession
DeclareGlobalFunction( "JuliaFunction" );

#! @Arguments variable_name[, module_name]
#! @Returns a &Julia; object
#! @Description
#!  Returns the &Julia; object <A>variable_name</A> from the
#!  module <A>module_name</A>.
#!  Both arguments must be strings. If <A>module_name</A> is not given,
#!  the variable is taken from the <C>Main</C> module.
#!  <P/>
#!  The result of this function is in
#!  <Ref Filt="IsArgumentForJuliaFunction" Label="for IsObject"/>,
#!  <!-- but never in IsJuliaWrapper -->
#!  thus it can be passed as an argument to &Julia; functions.
#! @BeginExampleSession
#! gap> JuliaEvalString( "x = 17" );
#! 17
#! gap> JuliaGetGlobalVariable( "x" );
#! 17
#! @EndExampleSession
DeclareGlobalFunction( "JuliaGetGlobalVariable" );

#! @Description
#!  This global variable represents the &Julia; module <C>Main</C>,
#!  see <Ref Filt="IsJuliaModule" Label="for IsJuliaWrapper"/>.
DeclareGlobalVariable( "Julia" );

#! @Arguments module
#! @Returns a list of strings
#! @Description
#!  Returns a list of names of components currently bound
#!  in <A>module</A>. Note that this does usually
#!  not reflect all symbols bound to a module on the
#!  &Julia; side: Even if a module has been imported
#!  in &Julia;, this list of symbols does only
#!  reflect the variables currently stored in the &GAP;
#!  module object. It might be possible to access
#!  further &Julia; variables or functions in this module.
DeclareGlobalFunction( "JuliaSymbolsInModule" );

#! @Arguments name
#! @Returns nothing.
#! @Description
#!  The aim of this function is to make those global variables
#!  that are exported by the &Julia; module with name <A>name</A>
#!  available in the global object <Ref Var="Julia"/>.
#!  After the call, the <A>name</A> component of <Ref Var="Julia"/>
#!  will be bound to a record that contains the variables from the
#!  &Julia; module.
DeclareGlobalFunction( "ImportJuliaModuleIntoGAP" );

#! @Arguments name
#! @Returns a &Julia; object
#! @Description
#!  Returns the &Julia; object that points to the module
#!  with name <A>name</A>.
#!  Note that the module needs to be imported before being present,
#!  see <Ref Func="ImportJuliaModuleIntoGAP"/>.
#! @BeginExampleSession
#! gap> gapmodule:= JuliaModule( "GAP" );
#! <Julia: Main.GAP>
#! gap> gapmodule = JuliaPointer( Julia.GAP );
#! true
#! @EndExampleSession
DeclareGlobalFunction( "JuliaModule" );

#! @Arguments juliaobj
#! @Returns a string.
#! @Description
#!  Returns the string that describes the &Julia; type of the object
#!  <A>juliaobj</A>.
#! @BeginExampleSession
#! gap> JuliaTypeInfo( Julia.GAP );
#! "Module"
#! gap> JuliaTypeInfo( JuliaPointer( Julia.GAP ) );
#! "Module"
#! gap> JuliaTypeInfo( JuliaEvalString( "sqrt(2)" ) );
#! "Float64"
#! @EndExampleSession
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
#! @BeginExampleSession
#! gap> fun:= Julia.sqrt;;
#! gap> CallJuliaFunctionWithCatch( fun, [ 2 ] );
#! rec( ok := true, value := <Julia: 1.4142135623730951> )
#! gap> res:= CallJuliaFunctionWithCatch( fun, [ -1 ] );;
#! gap> res.ok;
#! false
#! gap> res.value{ [ 1 .. Position( res.value, '(' )-1 ] };
#! "DomainError"
#! @EndExampleSession
DeclareGlobalFunction( "CallJuliaFunctionWithCatch" );

#! @Section Calling &Julia; functions
#!  The simplest way to execute &Julia; code from &GAP; is to call
#!  <Ref Func="JuliaEvalString"/> with a string that contains
#!  the &Julia; code in question.
#!  However, it is usually more suitable to create &GAP; variables
#!  whose values are &Julia; objects, and to call &Julia; functions
#!  directly.
#!  The &GAP; function call syntax is used for that.
#! @BeginExampleSession
#! ...
#! @EndExampleSession
#!  In fact, there are three slightly different ways to achieve this.
#!
#!  <List>
#!  <Item>
#!    If we have an object <C>obj</C> in
#!    <Ref Filt="IsJuliaObject" Label="for IsObject"/>
#!    that points to a &Julia; function then we can call <C>obj</C> with
#!    suitable arguments.
#!    In this situation, the function call is executed via
#!    &Julia;'s <C>Core._apply</C>.
#!    <!-- see the installed CallFuncList methods -->
#!  </Item>
#!  <Item>
#!    If we have a &GAP; function that was created with
#!    <Ref Func="JuliaFunction"/> then calling this function results in
#!    ...
#!  </Item>
#!  <Item>
#!    If we have a &GAP; function that was created with
#!    <Ref Func="JuliaBindCFunction"/> then calling this function results in
#!    ...
#!  </Item>
#!  </List>
#!
#!  TODO: Add examples.

#! @Subsection Convenience methods for &Julia; objects
#!  For the following operations, methods are installed that require
#!  arguments in <Ref Filt="IsJuliaObject" Label="for IsObject"/>
#!  and delegate to the corresponding &Julia; functions.
#!
#!  <!-- These methods are contained in adapter.gi and calls.gi -->
#!  <List>
#!  <Item>
#!    <Ref Oper="CallFuncList" BookName="ref"/>,
#!    delegating to <C>Julia.Core._apply</C>
#!    (this yields the function call syntax in &GAP;,
#!    it is installed also for objects in
#!    <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>,
#!  </Item>
#!  <Item>
#!    access to and assignment of entries of arrays, via
#!    <Ref Oper="\[\]" BookName="ref"/>,
#!    <Ref Oper="\[\]\:\=" BookName="ref"/>,
#!    <Ref Oper="MatElm" BookName="ref"/>, and
#!    <Ref Oper="SetMatElm" BookName="ref"/>,
#!    delegating to
#!    <C>Julia.Base.getindex</C> and
#!    <C>Julia.Base.setindex</C>,
#!  </Item>
#!  <Item>
#!    access to and assignment of fields and properties, via
#!    <Ref Oper="\." BookName="ref"/> and
#!    <Ref Oper="\.\:\=" BookName="ref"/>,
#!    delegating to
#!    <C>Julia.Base.getproperty</C> and
#!    <C>Julia.Base.setproperty</C>,
#!  </Item>
#!  <Item>
#!    the unary arithmetic operations
#!    <Ref Oper="AdditiveInverseOp" BookName="ref"/>,
#!    <Ref Oper="ZeroOp" BookName="ref"/>, and
#!    <Ref Oper="OneOp" BookName="ref"/>,
#!    delegating to
#!    <C>Julia.Base.\-</C>,
#!    <C>Julia.Base.zero</C>, and
#!    <C>Julia.Base.one</C>,
#!  </Item>
#!  <Item>
#!    the binary arithmetic operations
#!    <Ref Oper="\+" BookName="ref"/>,
#!    <Ref Oper="\-" BookName="ref"/>,
#!    <Ref Oper="\*" BookName="ref"/>,
#!    <Ref Oper="\/" BookName="ref"/>,
#!    <Ref Oper="LQuo" BookName="ref"/>,
#!    <Ref Oper="\^" BookName="ref"/>,
#!    <Ref Oper="\=" BookName="ref"/>,
#!    <Ref Oper="\&lt;" BookName="ref"/>,
#!    delegating to
#!    <C>Julia.Base.\+</C>,
#!    <C>Julia.Base.\-</C>,
#!    <C>Julia.Base.\*</C>,
#!    <C>Julia.Base.\/</C>,
#!    <C>Julia.Base.\\</C>,
#!    <C>Julia.Base.\^</C>,
#!    <C>Julia.Base.\=\=</C>, and
#!    <C>Julia.Base.\&lt;</C>;
#!    the same methods are installed also for the case that only one argument
#!    is in <Ref Filt="IsJuliaObject" Label="for IsObject"/>,
#!    and the other argument is an immediate integer.
#!  </Item>
#!  </List>
#!
#! @BeginExampleSession
#! ...
#! @EndExampleSession
