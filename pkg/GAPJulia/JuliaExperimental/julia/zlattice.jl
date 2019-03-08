###############################################################################
##
##  zlattice.jl
##
##  functions that have been translated from GAP library code
##

module GAPZLattice

import Core: Int, isa

import LinearAlgebra: diag

import Base: abs, convert, copy, deepcopy, haskey, inv, lcm, length,
             map, push!, sign, size, sum, trunc, zero, zeros

raw"""
    LLLReducedGramMat( grammatrix::Array{Int,2}, y::Rational{Int} = 3//4 )
> Return a dictionary with the following components.
>   `remainder`:      the reduced Gram matrix (`Array{Rational{Int},2}`)
>   `relations`:      basechange matrix `H` (`Array{Rational{Int},2}`)
>   `transformation`: basechange matrix `H` (`Array{Rational{Int},2}`)
>   `mue`:            matrix of scalar products (`Array{Rational{Int},2}`)
>   `B`:              list of norms of $b^{\ast}$ (`Array{Rational{Int},1}`)
"""
function LLLReducedGramMat( grammatrix::Array{Int,2}, y::Rational{Int} = 3//4 )

    local gram::Array{Rational{Int},2},      # the Gram matrix
          mmue::Rational{Int},      # buffer $\mue$
          kmax::Int,      # $k_{max}$
          H::Array{Rational{Int},2},         # basechange matrix $H$
          mue::Array{Rational{Int},2},       # matrix $\mue$ of scalar products
          B::Array{Rational{Int},1},         # list $B$ of norms of $b^{\ast}$
          BB::Rational{Int},        # buffer $B$
          q::Rational{Int},         # buffer $q$ for function `RED'
          qr::Array{Rational{Int},1},
          i::Int,         # loop variable $i$
          j::Int,         # loop variable $j$
          k::Int,         # loop variable $k$
          l::Int,         # loop variable $l$
          n::Int,         # length of `gram'
          RED,       # reduction subprocedure; `RED( l )'
                     # means `RED( k, l )' in Cohen's book
          ak::Array{Rational{Int},1}, # buffer vector in Gram-Schmidt procedure
          r::Int          # number of zero vectors found up to now

    function RED( l )

      # Terminate for $\|\mue_{k,l}\| \leq \frac{1}{2}$.
      if ( 1 < mue[k,l] * 2 ) || ( mue[k,l] * 2 < -1 )

        # Let $q = `Round( mue[k,l] )'$ (is never zero), \ldots
        q = trunc( mue[k,l] )
        if abs( mue[k,l] - q ) * 2 > 1
          q = q + sign( mue[k,l] )
        end

        # \ldots adjust the Gram matrix (rows and columns, but only
        # in the lower triangular half), \ldots
        gram[k,k] = gram[k,k] - q * gram[k,l]
        for i = (r+1):l
          gram[k,i] = gram[k,i] - q * gram[l,i]
        end
        for i = (l+1):k
          gram[k,i] = gram[k,i] - q * gram[i,l]
        end
        for i = (k+1):n
          gram[i,k] = gram[i,k] - q * gram[i,l]
        end

        # \ldots adjust `mue', \ldots
        mue[k,l] = mue[k,l] - q
        for i = (r+1):(l-1)
          if mue[l,i] != 0
            mue[k,i] = mue[k,i] - q * mue[l,i]
          end
        end

        # \ldots and the basechange.
        for i = 1:n
          H[k,i] = H[k,i] - q * H[l,i]
        end

      end
    end


    # Check the input parameters.
    gram = deepcopy( grammatrix )

    # Preset the ``sensitivity'' (value between $\frac{1}{4}$ and $1$).
    if ( 4 * y <= 1 ) || ( 1 < y )
      error( "sensitivity `y' must satisfy 1/4 < y <= 1" )
    end

    # step 1 (Initialize \ldots
    n    = size( gram, 1 )
    k    = 2
    kmax = 1
#   mue  = zeros( gram ) # this worked in earlier Julia versions ...
    mue  = zeros( Rational{Int}, n, n )
    r    = 0
    ak   = Array{Rational{Int},1}( undef, n )
#   H    = Array{Array{Rational{Int},1},1}( undef, n )
#    for i = 1:n
#      H[i] = zeros( Rational{Int}, n )
#      H[i][i] = 1
#    end
    H    = one( gram )

#   Info( InfoZLattice, 1,
#         "LLLReducedGramMat called with matrix of length ", n,
#         ", y = ", y );

    # \ldots and handle the case of leading zero vectors in the input.)
    i = 1
    while ( i <= n ) && ( gram[i,i] == 0 )
      i = i+1
    end
    if i > n

      r = n
      k = n+1

    elseif i > 1

      for j = (i+1):n
        gram[j,1] = gram[j,i]
        gram[j,i] = 0
      end
      gram[1,1] = gram[i,i]
      gram[i,i] = 0

      for j = 1:n
        q = H[i,j]
        H[i,j] = H[1,j]
        H[1,j] = q
      end
#      qr   = H[i]
#      H[i] = H[1]
#      H[1] = qr

    end

    B = Array{Rational{Int},1}( undef, n )
    B[1] = gram[1,1]

    while k <= n

      # step 2 (Incremental Gram-Schmidt)

      # If $k \leq k_{max}$ go to step 3.
      if k > kmax

#       Info( InfoZLattice, 2,
#             "LLLReducedGramMat: Take ", Ordinal( k ), " vector" );

        # Otherwise \ldots
        kmax = k
        B[k] = gram[k,k]
      # mue[k] = []
        for j = (r+1):(k-1)
          ak[j] = gram[k,j]
          for i = (r+1):(j-1)
            ak[j] = ak[j] - mue[j,i] * ak[i]
          end
          mue[k,j] = ak[j] // B[j]
          B[k] = B[k] - mue[k,j] * ak[j]
        end

      end

      # step 3 (Test LLL condition)
      RED( k-1 )
      while B[k] < ( y - mue[k,k-1] * mue[k,k-1] ) * B[k-1]

        # Execute Sub-algorithm SWAPG$( k )$\:
        # Exchange $H_k$ and $H_{k-1}$,
    #   qr     = H[k]
    #   H[k]   = H[k-1]
    #   H[k-1] = qr
        for j = 1:n
          q = H[k,j]
          H[k,j] = H[k-1,j]
          H[k-1,j] = q
        end

        # adjust the Gram matrix (rows and columns,
        # but only in the lower triangular half),
        for j = (r+1):(k-2)
          q           = gram[k,j]
          gram[k,j]   = gram[k-1,j]
          gram[k-1,j] = q
        end
        for j = (k+1):n
          q           = gram[j,k]
          gram[j,k]   = gram[j,k-1]
          gram[j,k-1] = q
        end
        q             = gram[k-1,k-1]
        gram[k-1,k-1] = gram[k,k]
        gram[k,k]     = q

        # and if $k > 2$, for all $j$ such that $1 \leq j \leq k-2$
        # exchange $\mue_{k,j}$ with $\mue_{k-1,j}$.
        for j = (r+1):(k-2)
          q          = mue[k,j]
          mue[k,j]   = mue[k-1,j]
          mue[k-1,j] = q
        end

        # Then set $\mue \leftarrow \mue_{k,k-1}$
        mmue = mue[k,k-1]

        # and $B \leftarrow B_k + \mue^2 B_{k-1}$.
        BB = B[k] + mmue^2 * B[k-1]

        # Now, in the case $B = 0$ (i.e. $B_k = \mue = 0$),
        if BB == 0

          # exchange $B_k$ and $B_{k-1}$
          B[k]   = B[k-1]
          B[k-1] = 0

          # and for $i = k+1, k+2, \ldots, k_{max}$
          # exchange $\mue_{i,k}$ and $\mue_{i,k-1}$.
          for i = (k+1):kmax
            q          = mue[i,k]
            mue[i,k]   = mue[i,k-1]
            mue[i,k-1] = q
          end

        # In the case $B_k = 0$ and $\mue \not= 0$,
        elseif ( B[k] == 0 ) && ( mmue != 0 )

          # set $B_{k-1} \leftarrow B$,
          B[k-1] = BB

          # $\mue_{k,k-1} \leftarrow \frac{1}{\mue}
          mue[k,k-1] = 1 // mmue

          # and for $i = k+1, k+2, \ldots, k_{max}$
          # set $\mue_{i,k-1} \leftarrow \mue_{i,k-1} / \mue$.
          for i = (k+1):kmax
            mue[i,k-1] = mue[i,k-1] // mmue
          end

        else

          # Finally, in the case $B_k \not= 0$,
          # set (in this order) $t \leftarrow B_{k-1} / B$,
          q = B[k-1] // BB

          # $\mue_{k,k-1} \leftarrow \mue t$,
          mue[k,k-1] = mmue * q

          # $B_k \leftarrow B_k t$,
          B[k] = B[k] * q

          # $B_{k-1} \leftarrow B$,
          B[k-1] = BB

          # then for $i = k+1, k+2, \ldots, k_{max}$ set
          # (in this order) $t \leftarrow \mue_{i,k}$,
          # $\mue_{i,k} \leftarrow \mue_{i,k-1} - \mue t$,
          # $\mue_{i,k-1} \leftarrow t + \mue_{k,k-1} \mue_{i,k}$.
          for i = (k+1):kmax
            q = mue[i,k]
            mue[i,k] = mue[i,k-1] - mmue * q
            mue[i,k-1] = q + mue[k,k-1] * mue[i,k]
          end

        end

        # Terminate the subalgorithm.

        if k > 2
          k = k-1
        end

        # Here we have always `k > r' since the loop is entered
        # for `k > r+1' only (because of `B[k-1] <> 0'),
        # so the only problem might be the case `k = r+1',
        # namely `mue[ r+1,r]' is used then; but this is bound
        # provided that the initial Gram matrix did not start
        # with zero columns, and its (perhaps not updated) value
        # does not matter because this would mean just to subtract
        # a multiple of a zero vector.

        RED( k-1 )

      end

      if B[ r+1 ] == 0
        r = r+1
      end

      for l = (k-2):-1:r+1
        RED( l )
      end
      k = k+1

    # step 4 (Finished?)
    # If $k \leq n$ go to step 2.

    end

    # Otherwise, let $r$ be the number of initial vectors $b_i$
    # which are equal to zero,
    # take the nonzero rows and columns of the Gram matrix
    # the transformation matrix $H \in GL_n(\Z)$
    # and terminate the algorithm.

    # adjust also upper half of the Gram matrix
    gram = gram[ (r+1):n, (r+1):n ]
    for i = 2:(n-r)
      for j = 1:(i-1)
        gram[j,i] = gram[i,j]
      end
    end

  # Info( InfoZLattice, 1,
  #       "LLLReducedGramMat returns matrix of length ", n-r );

    mue = mue[ (r+1):n, 1:n ]
    B = B[ (r+1):n ]

    return Dict( :remainder      => gram,
           #     :relations      => reshape( hcat( H[ 1:r ]... ), r, n ),
                 :relations      => H[ 1:r, : ],
           #     :transformation => reshape( hcat( H[ (r+1):n ]... ), n-r, n ),
                 :transformation => H[ (r+1):n, : ],
                 :mue            => mue,
                 :B              => B );
end


"""
    ShortestVectors( grammat::Array{Int,2}, bound::Int, positive::String = "" )
> Return a dictionary with the following components.
>   `vectors`:        shortest vectors (`Array{Array{Int,1},1}`),
>   `norms`:          norms of vectors (`Array{Rational{Int},1}`).
> (The code corresponds to the GAP code in `lib/zlattice.gi`.)
> 
> Example:
>   julia> A = [ 2 -1 -1 -1 ; -1 2 0 0 ; -1 0 2 0 ; -1 0 0 2 ];
>   julia> sv = ShortestVectors( A, 2 );
>   julia> size( sv[ "norms" ], 1 )
>   12
"""
function ShortestVectors( grammat::Array{Int,2}, bound::Int, positive::String = "" )
    local n::Int,
          c_vectors::Array{Array{Int,1},1},
          c_norms::Array{Rational{Int},1},
          v::Array{Int,1},
          nullv::Array{Int,1},
          checkpositiv::Bool,
          con::Bool,
          srt,
          vschr,
          mue::Array{Rational{Int},2},
          B::Array{Rational{Int},1},
          transformation::Array{Rational{Int},2}

    n = size( grammat, 1 )

    c_vectors = Array{Int,1}[]
    c_norms = Array{Rational{Int},1}[]
    v = zeros( Int, n )
    nullv = zeros( Int, n )

    checkpositiv = false
    if positive == "positive"
      checkpositiv = true
    end

    con = true

    srt = function( d, dam )
      local i, j, x, k, k1, q
      if d == 0
        if v == nullv
          con = false   # do not use 'global' in nested *function*!
        else
          vschr( dam )
        end
      else
        x = 0
        for j = d+1:n
          x = x + v[j] * mue[j,d]
        end
        if x > 0
          i = - Int( floor(x) )
        else
          i = Int( floor(-x) )
        end
        if abs( -x-i ) * 2 > 1
          i = i - sign( x )
        end
        k = i + x
        q = ( bound + 1/1000 - dam ) / B[d]
# println("before if: i = $i, x = $x, k = $k, q = $q")
        if k * k < q
# println("if")
          i = i + 1
          k = k + 1
          # no repeat loop ...
          while ! ( ( k * k > q ) && ( k > 0 ) )   # brackets are needed!
            i = i + 1
            k = k + 1
          end
          # until k * k > q and k > 0
          i = i - 1
          k = k - 1
          while ( k * k < q ) && con   # brackets are needed!
# println("while")
             v[d] = i
             k1 = B[d] * k * k + dam  # k1 is float?
             srt( d-1, k1 )
             i = i - 1
             k = k - 1
          end
        end
      end
    end

    # *extend* c_vectors and c_norms if necessary
    vschr = function( dam )
      local i::Int,
            j::Int,
            w::Int,
            neg::Bool,
            newv::Array{Int,1}

      newv = zeros( Int, n )  # Int because the *result* shall consist
                              # of integer vectors
      neg = false
      for i = 1:n
        w = 0
        for j = 1:n
          w = w + v[j] * transformation[j,i]
        end
        if w < 0
          neg = true
        end
        newv[i] = w
      end

      if ! ( checkpositiv && neg )
        push!( c_vectors, newv )
        push!( c_norms, dam )
      end
    end

    llg = LLLReducedGramMat( grammat )
    mue = llg[ :mue ]
    B = llg[ :B ]
    transformation = llg[ :transformation ]

    # main program
    srt( n, 0 )

    return Dict( :vectors => c_vectors, :norms => c_norms )
end


####################################################################
# GAP code: see ~/OrthEmb/orthemb.backup_2014_10_07

# A = [ 2 -1 -1 -1 ; -1 2 0 0 ; -1 0 2 0 ; -1 0 0 2 ];

"""
    OrthogonalEmbeddings( A::Array{Int,2}, arec::Dict )
> ...
"""
function OrthogonalEmbeddings( A::Array{Int,2}, arec::Dict )

    local ExtendAtPosition,
          maxdim::Int,
          mindim::Int,
          nonnegative::Bool,
          onesolution::Bool,
          checkdim::Bool,
          n::Int,
          Adiag::Array{Int,1},
          Ainv::Array{Rational{Int},2},
          AinvI::Array{Int,2},
          denom::Int,
          sv,
          x::Array{Array{Int,1},1},
          x2::Array{Array{Int,1},1},
          norms::Array{Rational{Int},1},
          m::Int,
          M::Array{Array{Rational{Int},1},1},
          increaserank::Array{Bool,1},
          D::Array{Rational{Int},1},
          f::Array{Int,1},
          sol::Array{Array{Int,1}},
          soldim::Array{Int,1},
          s::Int,
          k::Int,
          iota::Array{Int,1},
          mult::Array{Int,1},
          sumg::Array{Int,1},
          sumh::Array{Int,1},
          solcount::Int,
          tosort,
          phi::Array{Rational{Int},2},
          i::Int,
          ij::Int,
          prod::Array{Rational{Int},1},
          res::Rational{Int},
          j::Int,
          l::Int,
          out,
          minnorm::Rational{Int},
          normdiff::Rational{Int},
          repeat::Bool,
          exitrepeat::Bool

    ExtendAtPosition = function( i )
# s and normdiff are scalars that shall be treated as globals!

      local v::Array{Rational{Int},1},
            k1::Int,
            ii::Int,
            summ::Rational{Int},
            row::Array{Rational{Int},1},
            iii::Int,
            j::Int,
            r::Rational{Int}

      # Find v that solves the equation v D M^{tr} = - phi[i]
      # and adjust the data structures according to the addition of v
      # to the end of the matrix M.
      v = Rational{Int}[]
      k1 = 0

      for ii = 1:s-1
        # Here we have length( M[ii] ) == k1.
#         if k1 == 0
#           summ = 0
#         else
#           summ = sum( v .* M[ii] )
# # .* is slow!
#         end
        summ = 0
     #  if k1 != 0
row = M[ii]
          for iii = 1:k1
#           summ = summ + v[iii] * M[ii][iii]
            summ = summ + v[iii] * row[iii]
          end
     #  end
        if increaserank[ii]
          k1 = k1 + 1
          push!( v, -( phi[ i, f[ii] ] + summ ) // D[k1] )
        elseif summ != -phi[ i, f[ii] ]
          return false
        end
      end

      # Here we have k1 == k-1.
      r = denom - norms[i]
      for j = 1:k1
        r = r - v[j] * D[j] * v[j]
      end
      if r < 0
        return false
      elseif r == 0
        if length( increaserank ) < s
          push!( increaserank, false )
        else
          increaserank[s] = false
        end
      else
        if length( increaserank ) < s
          push!( increaserank, true )
        else
          increaserank[s] = true
        end

        # Extend the diagonal matrix.
        if length( D ) < k
          push!( D, r )
        else
          D[k] = r
        end
        k = k + 1
      end

      for j = 1:k1
        v[j] = v[j] * D[j]
      end

      # Extend the matrix M.
      if length( M ) < s
        push!( M, v )
      else
        M[s] = v
      end
      if length( f ) < s
        push!( f, i )
      else
        f[s] = i
      end
      s = s + 1
      iota[i] = iota[i] + 1
      normdiff = normdiff - norms[i] + minnorm

      return true
    end

    # ...
    maxdim = -1    # no 'fail'
    if haskey( arec, "maxdim" )
      maxdim = arec[ "maxdim" ]
    end
    mindim = 0
    if haskey( arec, "mindim" )
      mindim = arec[ "mindim" ]
    end
    nonnegative = haskey( arec, "nonnegative" ) && arec[ "nonnegative" ] == true
    onesolution = haskey( arec, "onesolution" ) && arec[ "onesolution" ] == true
    checkdim = ( maxdim != -1 )
    n = size( A, 1 )   # do not use length!

    # 'Ainv' is an integer matrix and 'denom' is an integer
    # such that 'Ainv = denom * Inverse( A )'.
    Adiag = diag( A )
    Ainv = inv( convert( Array{Rational{Int},2}, A ) )
    denom = lcm( map( denominator, Ainv ) )
    AinvI = denom * Ainv

    if haskey( arec, "vectors" )
      x = arec[ "vectors" ]
      if isa( x, Array )
        x = Dict( :vectors => x,
                  :norms => map( v -> sum( ( v * AinvI ) .* v ), x ) )
#T does not work at all!!
# and .* is slow!
      end
    else
      if nonnegative
        sv = ShortestVectors( AinvI, denom, "positive" )
      else
        sv = ShortestVectors( AinvI, denom )
      end
    end

    norms = sv[ :norms ]
    x = sv[ :vectors ]
    m = length( x )

    if m == 0
      return Dict( :vectors => x,
                   :norms => map( x -> x / denom, norms ),
                   :solutions => [] )
    end

#   println( "found $m vectors" )

    M = [ [] ]
    increaserank = Bool[]
    D = Rational{Int}[]
    f = Int[]
    sol = Array{Int,1}[]
    soldim = Int[]
    s = 1
    k = 1
    iota = zeros( Int, m )
    mult = zeros( Int, m )
    sumg = zeros( Int, n )
    sumh = zeros( Int, n )

    # Sort the vectors and the norms such that the norms are non-increasing,
    # and vectors of the same norm are sorted according to non-increasing
    # absolute values of the entries.
    tosort = map( i -> ( norms[i], x[i] ), [ 1:m; ] )
    sort!( tosort, lt = function( i, j )
        local v, w, k

        if i[1] == j[1]
          v = i[2]
          w = j[2]
          for k = 1:n
            if abs( v[k] ) > abs( w[k] )
              return true
            elseif abs( v[k] ) < abs( w[k] )
              return false
            end
          end
          # Now the result does not matter (in GAP it was 'false').
          return false
        else
          return j[1] < i[1]
        end
      end )
    norms = map( pair -> pair[1], tosort )
    x = map( pair -> pair[2], tosort )

    # Initialize the result record.
    out = Dict( :vectors => x,
                :norms => map( x -> x / denom, norms ),
                :solutions => [] )

    # 'x2[i]' stores the contribution of 'x[i]' to the diagonal of 'A'.
    x2 = map( v -> map( y -> y^2, v ), x )

    # Store the scalar product of x_i and x_j w.r.t. 'Ainv' in 'phi[i][j]'.
    phi = Array{Rational{Int}}( m, m )
    for i = 1:m
       prod = AinvI * x[i]
       for j = 1:i-1
         res = zero( prod[1] )
         for ij = 1:n
           res = res + prod[ij] * x[j][ij]
         end
         phi[i,j] = res
       end
       phi[i,i] = norms[i]
    end

    # Let $X = [ x_1, x_2, \ldots, x_k ]$ be a solution of $X^{tr} X = A$,
    # and let $P = X A^{-1} X^{tr}$ (see [Ple95, Prop. 2.2]).
    # The trace of $P$ is $n$, and the $i$-th diagonal entry of $P$ is
    # $x_i A^{-1} x_i^{tr}$,
    # thus $n$ is the sum of the norms of the $k$ involved vectors.
    # The a priori implication is that $n$ is at least $k$ times the smallest
    # norm that occurs.
    # (We have sorted the vectors according to non-increasing norm.)
    minnorm = norms[m]

    # Any solution $X$ of dimension $k$ for which the multiplicities
    # of involved vectors are at least the ones from $\iota_i$ satisfies
    # $n \geq \sum_{i=1}^m \iota_i x_i A^{-1} x_i^{tr} +
    # (k - \sum_{i=1}^m \iota_i) x_m A^{-1} x_m^{tr}$.
    # For minimal $k$, we get the condition that
    # 'n * denom - mindim * minnorm
    # - Sum( [ 1 .. m ], i -> iota[i] * ( norms[i] - minnorm ) )'
    # is nonnegative.
    normdiff = n * denom - mindim * minnorm
    if normdiff < 0
      # The a priori implication is that $n$ is at least $k$ times
      # the smallest norm that occurs.
      return out
    end

    # Start the enumeration of coefficient vectors.
    l = 1
    repeat = true
    while repeat

      # The multiplicities of the first 'l-1' vectors have been fixed.
      if 0 <= normdiff

        # Compute the maximal multiplicities of x_l, x_{l+1}, ...,
        # assuming that only one of these vectors occurs,
        # and store the contributions to the trace in 'sumh'.
        sumh = zeros( sumh )
        i = l
        while i <= m && ( ( ! checkdim ) || ( s <= maxdim ) )
          if mult[i] * norms[i] < denom
            exitrepeat = false
            while ! exitrepeat
              if ! ExtendAtPosition( i )
                break
              end
              exitrepeat = ( iota[i] * norms[i] >= denom
                             || ( checkdim && s > maxdim ) )
            end
            mult[i] = iota[i]

            # Reset the i-th coefficient to zero, adjust the data structures.
            while 0 < iota[i]
              s = s - 1
              if increaserank[s]
                k = k -1
              end
              iota[i] = iota[i] - 1
              normdiff = normdiff + norms[i] - minnorm
            end
          end
          if mult[i] != 0
#           for j = 1:length(x2[i])
            for j = 1:n
              sumh[j] = sumh[j] + mult[i] * x2[i][j]
            end
#           sumh = sumh + mult[i] * x2[i]
          end
          i = i + 1
        end

        # Proceed with the current initial part 'iota{ [ 1 .. l-1 ] }'
        # only if this part plus the sum of *all* possible vectors
        # is big enough for reaching the diagonal values.
        if all( i -> Adiag[i] <= sumg[i] + sumh[i], 1:n )
# expensive?
          # Increase the coefficients of the vectors x_l, x_{l+1}, ...
          # as much as possible.
          i = l
          while i <= m && ( ( ! checkdim ) || s <= maxdim )
            exitrepeat = false
            while ! exitrepeat
              if ExtendAtPosition( i )
#T we increase iota[i]: if this is the last position for a zero condition
#T then we know the unique possible multiplicity of this vector,
#T or we know that there is no such multiplicity!
#T if there are several zero conditions then use all of them!
#T (this criterion cannot be used in the comp. of 'mult[i]')
                sumg = sumg + x2[i]
                l = i
              else
                break
              end
              exitrepeat = ( iota[i] >= mult[i] || ( checkdim && maxdim < s ) )
            end
            mult[i] = 0
            i = i + 1
          end

          # Check whether this vector describes a solution.
          if s == n + k && mindim < s
   #        Info( InfoZLattice, 2,
   #              "OrthogonalEmbeddings: ",
   #              Ordinal( length( sol) ), " solution has dimension ", s - 1 );
# println( "solution ", length( sol ), " of dimension ", s-1 )
            push!( sol, copy( iota ) )
            push!( soldim, s - 1 )
            if onesolution then
              l = 0
            end
          end
        end
      end

      # elementary decrease step
      while l > 0
        if iota[l] != 0
          if l == m
            # Set the m-th coefficient to zero, adjust the data structures.
            sumg = sumg - iota[l] * x2[l]
            while iota[l] > 0
              s = s - 1
              if increaserank[s]
                k = k - 1
              end
              iota[l] = iota[l] - 1
              normdiff = normdiff + norms[l] - minnorm
            end
          else
            sumg = sumg - x2[l]
            s = s - 1
            if increaserank[s]
              k = k - 1
            end
            iota[l] = iota[l] - 1
            normdiff = normdiff + norms[l] - minnorm
            l = l + 1
            break
          end
        end
        l = l - 1
      end

      if l <= 1
        repeat = false
      end
    end

    # Format the solutions.
    # The solutions are sorted according to increasing dimension,
    # and such that two solutions of same dimension are sorted
    # reverse lexicographically.
    solcount = length( sol )
    tosort = map( i -> ( soldim[i], sol[i] ), [ 1:solcount; ] )
    sort!( tosort, lt = function( i, j )
          if i[1] == j[1]
            return j[2] < i[2]
          else
            return i[1] < j[1]
          end
        end )
    sol = map( x -> x[2], tosort )

    for i = 1:solcount
      single = Int[]
      for j = 1:m
        for k = 1:sol[i][j]
          push!( single, j )
        end
      end
      push!( out[ :solutions ], single )
    end

    return out
end

end

