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
#! @Section Aims of the <Package>JuliaInterface</Package> package
#!  The low level interface between &GAP; and &Julia; allows one
#!  to access &GAP; objects and to call &GAP; functions
#!  in a &Julia; session,
#!  to access &Julia; objects and to call &Julia; functions
#!  in a &GAP; session,
#!  and to convert low level data such as integers, booleans, strings,
#!  arrays/lists, dictionaries/records between the two systems.
#!
#!  In particular, this interface is <E>not</E> intended to provide
#!  a very <Q>&Julia;-ish</Q> interface to &GAP; objects and functions,
#!  nor a <Q>&GAP;-ish</Q> interface to &Julia; objects and functions.
#!
#!  Also, the interface does not provide conversions to &GAP;
#!  for &Julia; objects whose types are defined in &Julia; packages
#!  (that is, not in the <Q>core &Julia;</Q>).
#!  For example, the &Julia; package <Package>Oscar.jl</Package> provides
#!  several data types that correspond to objects in &GAP;.
#!  Their conversions between &Julia; and &GAP; are handled in
#!  <Package>Oscar.jl</Package>, see its <F>src/GAP</F> subdirectory,
#!  <Package>JuliaInterface</Package> does not deal with these issues.
#!
#!  The interface consists of
#!
#!  <List>
#!  <Item>
#!    the integration of &Julia;'s garbage collector into &GAP;
#!    (which belongs to the &GAP; core system),
#!  </Item>
#!  <Item>
#!    <C>C</C> code for converting and wrapping low level objects
#!    (which belongs to <Package>JuliaInterface</Package>),
#!  </Item>
#!  <Item>
#!    &Julia; code for converting low level objects
#!    (which belongs to the &Julia; package <C>GAP.jl</C>,
#!    see <URL>https://github.com/oscar-system/GAP.jl</URL>),
#!  </Item>
#!  <Item>
#!    and &GAP; code (again in <Package>JuliaInterface</Package>)
#!    which is described in this manual.
#!  </Item>
#!  </List>
#!
#!  The <Package>JuliaInterface</Package> manual takes the viewpoint
#!  of a &GAP; session from where one wants to use &Julia; functionality.
#!  The opposite direction, using &GAP; functionality in a &Julia; session,
#!  is described in the documentation of the &Julia; package <C>GAP.jl</C>.
#!
#! @Section Installation of the <Package>JuliaInterface</Package> package
#!  The package can be used only when the underlying &GAP; has been
#!  compiled with the &Julia; garbage collector,
#!  and the recommended way to install such a &GAP; is to install &Julia;
#!  first (see <URL>https://julialang.org/downloads/</URL>)
#!  and then to ask &Julia;'s package manager to download and install &GAP;,
#!  by entering
#!  <Listing Type="Julia">using Pkg; Pkg.add( "GAP" )</Listing>
#!  at the &Julia; prompt.
#!
#!  One way to start a &GAP; session from the &Julia; session is to enter
#!  <Listing Type="Julia">using GAP; GAP.prompt()</Listing>
#!  at the &Julia; prompt,
#!  afterwards the package <Package>JuliaInterface</Package> is already
#!  installed and loaded.
#!
#!  Alternatively, one can start &GAP; in the traditional way, by executing
#!  a shell script. Such a script can be created in a location of your choice
#!  via the following &Julia; command, where <F>dstdir</F> is a directory
#!  path in which a <F>gap.sh</F> script plus some auxiliary files will be placed:
#!  <Listing Type="Julia">using GAP; GAP.create_gap_sh(dstdir)</Listing>
#!
#!  Note that the <Package>JuliaInterface</Package> code belongs to
#!  <URL><Link>https://github.com/oscar-system/GAP.jl</Link>
#!  <LinkText>the &Julia; package <C>GAP.jl</C></LinkText></URL>,
#!  hence it can be found there.

#! @Chapter Using &Julia; from &GAP;
#! @Section Filters for <Package>JuliaInterface</Package>

#! @Arguments obj
#! @Returns <K>true</K> or <K>false</K>
#! @Description
#!  The result is <K>true</K> if and only if <A>obj</A> is a pointer to a
#!  &Julia; object.
#!
#!  The results of <Ref Func="JuliaModule"/> are always in
#!  <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
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
#!  will not pass <A>obj</A> as an <C>GapObj</C>,
#!  but instead its <Ref Attr="JuliaPointer" Label="for IsJuliaWrapper"/>
#!  value is passed, which must be a &Julia; object.
#!  This admits implementing high-level wrapper objects
#!  for &Julia; objects that behave just like the &Julia; objects
#!  when used as arguments in calls to &Julia; functions.
#!  <!-- No other functionality is implemented for IsJuliaWrapper -->
#!
#!  Objects in <Ref Filt="IsJuliaWrapper" Label="for IsObject"/>
#!  should <E>not</E> be in the filter
#!  <Ref Filt="IsJuliaObject" Label="for IsObject"/>.
#!
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
#!  Members of a &Julia; module can be accessed like record components.
#! @BeginExampleSession
#! gap> IsJuliaModule( Julia );
#! true
#! gap> Julia.GAP;
#! <Julia module GAP>
#! gap> IsJuliaModule( Julia.GAP );
#! true
#! gap> Julia.GAP.julia_to_gap;
#! <Julia: julia_to_gap>
#! gap> JuliaFunction( "julia_to_gap", "GAP" );  # the same function
#! <Julia: julia_to_gap>
#! @EndExampleSession
DeclareCategory( "IsJuliaModule", IsJuliaWrapper and IsRecord  );

BindGlobal( "TheFamilyOfJuliaModules", NewFamily( "TheFamilyOfJuliaModules" ) );
BindGlobal( "TheTypeOfJuliaModules", NewType( TheFamilyOfJuliaModules, IsJuliaModule and IsAttributeStoringRep ) );

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

#! @Arguments filename[, module_name]
#! @Returns nothing.
#! @Description
#!  calls &Julia;'s <C>Base.include</C> with the strings <A>filename</A>
#!  (an absolute filename, as returned by
#!  <Ref Oper="Filename" BookName="ref"/>) and <A>module_name</A>
#!  (the name of a &Julia; module, the default is <C>"Main"</C>).
#!  This means that the &Julia; code in the file with name <A>filename</A>
#!  gets executed in the current &Julia; session,
#!  in the context of the &Julia; module <A>module_name</A>.
DeclareGlobalFunction( "JuliaIncludeFile" );

#! @Arguments pkgname
#! @Returns <K>true</K> or <K>false</K>.
#! @Description
#!  This function triggers the execution of an <C>import</C> statement
#!  for the &Julia; package with name <A>pkgname</A>.
#!  It returns <K>true</K> if the call was successful,
#!  and <K>false</K> otherwise.
#!
#!  Note that we just want to load the package into &Julia;,
#!  we do <E>not</E> want to import variable names from the package
#!  into &Julia;'s <C>Main</C> module, because the &Julia; variables must be
#!  referenced relative to their modules if we want to be sure to access
#!  the correct values.
#!
#!  Why is this function needed?
#!
#!  Apparently <C>libjulia</C> throws an error
#!  when trying to compile the package, which happens when some files from
#!  the package have been modified since compilation.
#!
#!  Thus &GAP; has to check whether the &Julia; package has been loaded
#!  successfully, and can then safely load and execute code
#!  that relies on this &Julia; package.
#!  In particular, we cannot just put the necessary <C>import</C> statements
#!  into the relevant <F>.jl</F> files,
#!  and then load these files with <Ref Func="JuliaIncludeFile"/>.
DeclareGlobalFunction( "JuliaImportPackage" );


#! @Section Access to &Julia; objects

#! @Arguments function_name[, module_name]
#! @Returns a function
#! @Description
#! Returns a &GAP; function that wraps the &Julia; function with identifier
#! <A>function_name</A> from the module <A>module_name</A>.
#! Both arguments must be strings.
#! If <A>module_name</A> is not given,
#! the function is taken from &Julia;'s <C>Main</C> module.
#!
#! @BeginExampleSession
#! gap> fun:= JuliaFunction( "sqrt" );
#! <Julia: sqrt>
#! gap> Print( fun );
#! function ( arg... )
#!     <<kernel code>> from Julia:sqrt
#! end
#! gap> IsFunction( fun );
#! true
#! gap> IsJuliaObject( fun );
#! false
#! @EndExampleSession
#!
#! Alternatively, one can access &Julia; functions also via the global object
#! <Ref Var="Julia"/>, as follows.
#!
#! @BeginExampleSession
#! gap> Julia.sqrt;
#! <Julia: sqrt>
#! @EndExampleSession
#!
#! Note that each call to <Ref Func="JuliaFunction"/> and each component
#! access to <Ref Var="Julia"/> create a <E>new</E> &GAP; object.
#!
#! @BeginExampleSession
#! gap> IsIdenticalObj( JuliaFunction( "sqrt" ), JuliaFunction( "sqrt" ) );
#! false
#! gap> IsIdenticalObj( Julia.sqrt, Julia.sqrt );
#! false
#! @EndExampleSession
DeclareGlobalFunction( "JuliaFunction" );

#! @Description
#!  This global variable represents the &Julia; module <C>Main</C>,
#!  see <Ref Filt="IsJuliaModule" Label="for IsJuliaWrapper and IsRecord"/>.
#!
#!  The variables from the underlying &Julia; session can be accessed via
#!  <Ref Var="Julia"/>, as follows.
#!
#! @BeginExampleSession
#! gap> Julia.sqrt;  # a Julia function
#! <Julia: sqrt>
#! gap> JuliaEvalString( "x = 1" );  # an assignment in the Julia session
#! 1
#! gap> Julia.x;  # access to the value that was just assigned
#! 1
#! gap> Julia.Main.x;
#! 1
#! @EndExampleSession
DeclareGlobalVariable( "Julia" );

#! @Arguments name
#! @Returns a &Julia; object
#! @Description
#!  Returns the &Julia; object that points to the &Julia; module
#!  with name <A>name</A>.
#! @BeginExampleSession
#! gap> gapmodule:= JuliaModule( "GAP" );
#! <Julia: GAP>
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
#! gap> JuliaTypeInfo( 1 );
#! "Int64"
#! @EndExampleSession
DeclareGlobalFunction( "JuliaTypeInfo" );

#! @Arguments juliafunc, arguments
#! @Returns a record.
#! @Description
#!  The function calls the &Julia; function <A>juliafunc</A>
#!  with arguments in the &GAP; list <A>arguments</A>,
#!  and returns a record with the components <C>ok</C> and <C>value</C>.
#!  If no error occurred then <C>ok</C> has the value <K>true</K>,
#!  and <C>value</C> is the value returned by <A>juliafunc</A>.
#!  If an error occurred then <C>ok</C> has the value <K>false</K>,
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
#! gap> inv:= Julia.inv;;
#! gap> m:= GAPToJulia( JuliaEvalString( "Matrix{Int}" ), [[1,2],[2,4]] );
#! <Julia: [1 2; 2 4]>
#! gap> res:= CallJuliaFunctionWithCatch( inv, [ m ] );;
#! gap> res.ok;
#! false
#! gap> res.value{ [ 1 .. Position( res.value, '(' )-1 ] };
#! "LinearAlgebra.SingularException"
#! @EndExampleSession
DeclareGlobalFunction( "CallJuliaFunctionWithCatch" );

#! @Arguments juliafunc, arguments, arec
#! @Returns the result of the &Julia; function call.
#! @Description
#!  The function calls the &Julia; function <A>juliafunc</A>
#!  with ordinary arguments in the &GAP; list <A>arguments</A>
#!  and keyword arguments given by the component names (keys) and values
#!  of the record <A>arec</A>,
#!  and returns the function value.
#!
#!  Note that the entries of <A>arguments</A> and the components of
#!  <A>arec</A> are not implicitly converted to &Julia;.
#! @BeginExampleSession
#! gap> CallJuliaFunctionWithKeywordArguments( Julia.Base.round,
#! >        [ GAPToJulia( Float( 1/3 ) ) ], rec( digits:= 5 ) );
#! <Julia: 0.33333>
#! gap> CallJuliaFunctionWithKeywordArguments(
#! >        Julia.Base.range, [ 2 ], rec( length:= 5, step:= 2 ) );
#! <Julia: 2:2:10>
#! gap> m:= GAPToJulia( JuliaEvalString( "Matrix{Int}" ),
#! >            [ [ 1, 2 ], [ 3, 4 ] ] );
#! <Julia: [1 2; 3 4]>
#! gap> CallJuliaFunctionWithKeywordArguments(
#! >        Julia.Base.reverse, [ m ], rec( dims:= 1 ) );
#! <Julia: [3 4; 1 2]>
#! gap> CallJuliaFunctionWithKeywordArguments(
#! >        Julia.Base.reverse, [ m ], rec( dims:= 2 ) );
#! <Julia: [2 1; 4 3]>
#! gap> tuptyp:= JuliaEvalString( "Tuple{Int,Int}" );;
#! gap> t1:= GAPToJulia( tuptyp, [ 2, 1 ] );
#! <Julia: (2, 1)>
#! gap> t2:= GAPToJulia( tuptyp, [ 1, 3 ] );
#! <Julia: (1, 3)>
#! gap> CallJuliaFunctionWithKeywordArguments(
#! >        Julia.Base.( "repeat" ), [ m ],
#! >        rec( inner:= t1, outer:= t2 ) );
#! <Julia: [1 2 1 2 1 2; 1 2 1 2 1 2; 3 4 3 4 3 4; 3 4 3 4 3 4]>
#! @EndExampleSession
DeclareGlobalFunction( "CallJuliaFunctionWithKeywordArguments" );

#! @Section Calling &Julia; functions
#!  The simplest way to execute &Julia; code from &GAP; is to call
#!  <Ref Func="JuliaEvalString"/> with a string that contains
#!  the &Julia; code in question.
#! @BeginExampleSession
#! gap> JuliaEvalString( "sqrt( 2 )" );
#! <Julia: 1.4142135623730951>
#! @EndExampleSession
#!  However, it is usually more suitable to create &GAP; variables
#!  whose values are &Julia; objects, and to call &Julia; functions
#!  directly.
#!  The &GAP; function call syntax is used for that.
#! @BeginExampleSession
#! gap> jsqrt:= JuliaEvalString( "sqrt" );
#! <Julia: sqrt>
#! gap> jsqrt( 2 );
#! <Julia: 1.4142135623730951>
#! @EndExampleSession
#!  In fact, there are slightly different kinds of function calls.
#!  A &Julia; function such as <C>Julia.sqrt</C>
#!  (or equivalently <C>JuliaFunction( "sqrt" )</C>) is represented by
#!  a &GAP; function object,
#!  and calls to it are executed on the C level,
#!  using &Julia;'s <C>jl_call</C>.
#! @BeginExampleSession
#! gap> fun:= Julia.sqrt;
#! <Julia: sqrt>
#! gap> IsJuliaObject( fun );
#! false
#! gap> IsFunction( fun );
#! true
#! gap> fun( 2 );
#! <Julia: 1.4142135623730951>
#! @EndExampleSession
#!  Note that in &Julia; any object (not just functions) is potentially callable
#!  (in fact this is the same as in &GAP;), for example &Julia; types can be
##  called like functions. This is also fully supported on the GAP side:
#! @BeginExampleSession
#! gap> smalltype:= Julia.Int32;
#! <Julia: Int32>
#! gap> IsJuliaObject( smalltype );
#! true
#! gap> IsFunction( smalltype );
#! false
#! gap> val:= smalltype( 1 );
#! <Julia: 1>
#! gap> JuliaTypeInfo( val );
#! "Int32"
#! gap> JuliaTypeInfo( 1 );
#! "Int64"
#! @EndExampleSession

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
#!    <!-- <Ref Oper="MatElm" BookName="ref"/>, and
#!    <Ref Oper="SetMatElm" BookName="ref"/>, -->
#!    and the (up to &GAP; 4.11 undocumented) operations <C>MatElm</C> and
#!    <C>SetMatElm</C>,
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
#!    <Ref Oper="LeftQuotient" BookName="ref"/>,
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
#! gap> m:= GAPToJulia( JuliaEvalString( "Matrix{Int}" ),
#! >            [ [ 1, 2 ], [ 3, 4 ] ] );
#! <Julia: [1 2; 3 4]>
#! gap> m[1,2];
#! 2
#! gap> - m;
#! <Julia: [-1 -2; -3 -4]>
#! gap> m + m;
#! <Julia: [2 4; 6 8]>
#! @EndExampleSession
#TODO: add the cross-references to MatElm, SetMatElm when they are documented

#! @InsertChunk JuliaHelpInGAP

#! @Section Utilities

#! @Arguments key
#! @Returns a string
#! @Description
#!  Returns the path of a &Julia; scratchspace associated to the given key.
#!  This scratchspace gets created if it did not exist already,
#!  one can rely on the fact that the returned path describes a writable
#!  directory.
#!  Subsequent calls with the same key yield the same result,
#!  and calls with different keys yield different results.
#!  The directory may be removed by &Julia; as soon as the &Julia; package
#!  <C>GAP.jl</C> gets uninstalled.
DeclareGlobalFunction( "GetJuliaScratchspace" );
