##############################################################################
##
##  utils.jl
##
##  some general utility functions
##

module GAPUtilsExperimental

"""
    MatrixFromNestedArray( lst )
> Return a 2-dim array created from the 1-dim array of 1-dim arrays `lst`.
> (Note that GAP's `GAPToJulia` creates nested arrays.)
"""
function MatrixFromNestedArray( lst ) return copy( hcat( lst... )' ) end


"""
    NestedArrayFromMatrix( lst )
> Return an array of 1-dim arrays created from the 2-dim array `lst`.
> (Note that GAP's `JuliaToGAP` expects nested arrays.)
"""
function NestedArrayFromMatrix( mat )
    return map( i -> mat[i,:], 1:size(mat,1) )
end


"""
    JuliaSourceFile( func, types )
> Return the tuple `( filename, startline )`
> such that the source code of the method `func`
> that expects arguments of the types given in the tuple `types`
> can be found in the file `filename`, starting at line `startline`.
"""
function JuliaSourceFile( func, types )
    local meth::Method

    meth = which( func, types )
    return ( string( meth.file ), meth.line )
end

end

