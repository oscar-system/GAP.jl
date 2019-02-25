#############################################################################
##
##  JuliaInterface package
##
##  Copyright 2017
##    Thomas Breuer, RWTH Aachen University
##    Sebastian Gutsche, Siegen University
##
#! @Chapter Function integration
##
#############################################################################

#! @Section Julia functions in GAP

#! @Arguments julia_name, nr_args, arg_names
#! @Returns a function
#! @Description
#!  Returns a GAP function that acts like a kernel function in GAP,
#!  but calls the Julia function <A>julia_name</A>. The function in Julia
#!  must exist, bound to the global name <A>julia_name</A> in the module <C>Main</C>,
#!  and must be callable on <A>nr_args</A> arguments. <A>arg_name</A> must
#!  be a list of strings of length <A>nr_args</A> describing the argument names
#!  that are displayed in the function header by &GAP;.
DeclareGlobalFunction( "JuliaBindCFunction" );

#! @Section GAP functions in Julia

#! @Arguments func, name, argument_number
#! @Returns nothing
#! @Description
#!  Sets the function <A>func</A> in Julia as <C>GAP.</C><A>name</A>.
#!  The resulting function is then callable from Julia on <A>argument_number</A> arguments.
DeclareGlobalFunction( "JuliaSetGAPFuncAsJuliaObjFunc" );
