
# experimental code for permutations in julia,
# translated more or less literally from GAP's src/permutat.c

#T JuliaInterface seems not to support 'using' statements (?),
#T we have only 'include'
# module GAPPermutations
# 
# import Base.length, Base.similar, Base.zeros
# import Base.==, Base.<, Base.*, Base.^
# import Base.hash
# 
# export Permutation
# export IdentityPerm
# export EqPerm22, LtPerm22, ProdPerm22, PowPerm2Int, PowIntPerm2, QuoIntPerm2
# export LargestMovedPointPerm, OrderPerm, OnePerm, InvPerm
# 
# export hash

#T use @inbounds for the loops!
#T specify types for local variables!

# create the julia type
#T for the moment, only `Perm2' is considered,
#T meaning permutations of positive 16 bit integers;
#T `Perm4' would mean permutations of 32 bit integers
immutable Permutation2
    degree::UInt16
    imgs::Array{UInt16,1}

#   function Permutation( imgsarray::Array{UInt16,1} )
#       new( length( imgsarray ), imgsarray )
#   end
end

function Permutation( imgsarray::Array{UInt16,1} )
#T *check* the input?
    return Permutation2( length( imgsarray ), imgsarray )
   end

function Permutation( imgsarray::Array{Int,1} )
        local conv

        conv::Array{UInt16,1} = convert( Array{UInt16,1}, imgsarray )

        return Permutation2( length( conv ), conv )
    end

#T JuliaBox creates Array{Any,1}
function Permutation( imgsarray::Array{Any,1} )
        local conv

        conv::Array{UInt16,1} = convert( Array{UInt16,1}, imgsarray )

        return Permutation2( length( conv ), conv )
    end


const IdentityPerm = Permutation2( 0, UInt16[] )

# (julia abbreviates long lists automatically)
Base.show( io::IO, perm::Permutation2 ) = print( io, "<permutation: ", perm.imgs, ">" )

# provide the methods
EqPerm22 = function( pL::Permutation2, pR::Permutation2 )
    local degL, degR, pLimgs, pRimgs, p

    degL::UInt16 = pL.degree
    degR::UInt16 = pR.degree
    pLimgs::Array{UInt16,1} = pL.imgs
    pRimgs::Array{UInt16,1} = pR.imgs

    # if perms/trans are different sizes, check final element as an early
    # check
    if degL != degR
      if degL < degR
        if pRimgs[ degR ] != degR
          return false
        end
      else
        if pLimgs[ degL ] != degL
          return false
        end
      end
    end

    # search for a difference and return False if you find one
    if degL <= degR
      for p in (degL+1):degR
        if pRimgs[p] != p
          return false
        end
      end
     #if (memcmp(ptLstart, ptRstart, degL * sizeof(UInt2)) != 0) {
     #  return 0L;
     #end
      for p in 1:degL
        if pLimgs[p] != pRimgs[p]
          return false
        end
      end
    else
      for p in (degR+1):degL
        if pLimgs[p] != p
          return false
        end
      end
     #if (memcmp(ptLstart, ptRstart, degR * sizeof(UInt2)) != 0) {
     #  return 0L;
     #end
      for p in 1:degR
        if pLimgs[p] != pRimgs[p]
          return false
        end
      end
    end

    # otherwise they must be equal
    return true
end


LtPerm22 = function( pL::Permutation2, pR::Permutation2 )
    local degL, degR, pLimgs, pRimgs, p

    # get the degrees of the permutations
    degL::Int = pL.degree
    degR::Int = pR.degree
    pLimgs::Array{UInt16,1} = pL.imgs
    pRimgs::Array{UInt16,1} = pR.imgs

    # search for a difference and return if you find one
    if degL <= degR
        for p in 1:degL
            if pLimgs[p] < pRimgs[p]
              return true
            elseif pLimgs[p] != pRimgs[p]
              return false
            end
        end
        for  p in (degL+1):degR
            if p < pRimgs[p]
              return true
            elseif p != pRimgs[p]
              return false
            end
        end
    else
        for p in 1:degR
            if pLimgs[p] < pRimgs[p]
              return true
            elseif pLimgs[p] != pRimgs[p]
              return false
            end
        end
        for p in (degR+1):degL
            if pLimgs[p] < p
              return true
            elseif pLimgs[p] != p
              return false
            end
        end
    end

    # otherwise they must be equal
    return false
end


ProdPerm22 = function( pL::Permutation2, pR::Permutation2 )
    local degL, degR, prd, img

    # get the degrees of the permutations
    degL::UInt16 = pL.degree
    degR::UInt16 = pR.degree
    pLimgs::Array{UInt16,1} = pL.imgs
    pRimgs::Array{UInt16,1} = pR.imgs

    # compute the size of the result and allocate a bag
    if degL < degR
      prd = similar( pRimgs )
    else
      prd = similar( pLimgs )
    end

    # if the left (inner) permutation has smaller degree, it is very easy
    if degL <= degR
      for p in 1:degL
        @inbounds prd[p] = pRimgs[ pLimgs[p] ]
      end
      for p in (degL+1):degR
        @inbounds prd[p] = pRimgs[p]
      end
    # otherwise we have to use the macro 'IMAGE'
    else
      for p in 1:degL
        @inbounds img = pLimgs[p]
        @inbounds prd[p] = ( img <= degR ? pRimgs[ img ] : img )
      end
    end

    # return the result
    return Permutation2( length( prd ), prd )
end


PowPerm2Int = function( pL::Permutation2, n::Int )
    local deg, pLimgs, pow

    # handle zeroth and first powers separately
    if ( n == 0 )
      return IdentityPerm
    elseif ( n == 1 )
      return pL
    end

    # get the operands and allocate the result list
    deg::Int = pL.degree
    pLimgs::Array{UInt16,1} = pL.imgs
    pow = similar( pLimgs )

    # compute the power by repeated mapping for small positive exponents
    if 2 <= n && n < 8

        # loop over the points of the permutation
        for p in 1:deg
            q = p
            for e in 1:n
                q = pLimgs[q]
            end
            pow[p] = q
        end

    # compute the power by raising the cycles individually for large exps
    elseif 8 <= n

        # make sure that the buffer bag is large enough
        # clear the buffer bag
        ptKnown = zeros( pLimgs )

        # loop over all cycles
        for p in 1:deg

            # if we haven't looked at this cycle so far
            if ptKnown[p] == 0

                # find the length of this cycle
                len = 1
                q = pLimgs[p]
                while q != p
                  ptKnown[q] = 1
                  len += 1
                  q = pLimgs[q]
                end
            
                # raise this cycle to the power <n> mod <len>
                r = p
                for e in 1:mod( n, len )
                    r = pLimgs[r]
                end
                pow[p] = r
                r = pLimgs[r]
                q = pLimgs[p]
                while q != p
                  pow[q] = r
                  r = pLimgs[r]
                  q = pLimgs[q]
                end
            end
        end

    # special case for inverting permutations
    elseif n == -1

        # invert the permutation
        for p in 1:deg
            pow[ pLimgs[p] ] = p
        end

    # compute the power by repeated mapping for small negative exponents
    elseif -8 < n && n < 0

        # get pointer to the permutation and the power
        exp = -n

        # loop over the points
        for p in 1:deg
            q = p
            for e in 1:exp
                q = pLimgs[q]
            end
            pow[q] = p
        end

    # compute the power by raising the cycles individually for large exps
    elseif n <= -8

        # make sure that the buffer bag is large enough
        # clear the buffer bag
        ptKnown = zeros( pLimgs )

        # get pointer to the permutation and the power
        exp = -n

        # loop over all cycles
        for p in 1:deg

            # if we haven't looked at this cycle so far
            if ptKnown[p] == 0

                # find the length of this cycle
                len = 1
                q = pLimgs[p]
                while q != p
                  ptKnown[q] = 1
                  len += 1
                  q = pLimgs[q]
                end

                # raise this cycle to the power <exp> mod <len>
                r = p
                for e in 1:mod( exp, len )
                    r = pLimgs[r]
                end
                pow[p] = r
                r = pLimgs[r]
                q = pLimgs[p]
                while q != p
                  pow[q] = r
                  r = pLimgs[r]
                  q = pLimgs[q]
                end
            end
        end
    end

    # return the result
    return Permutation2( length( pow ), pow )
end


PowIntPerm2 = function( n::Int, pR::Permutation2 )
    local img

    # permutations do not act on negative integers
    if n <= 0
      error( "Perm. Operations: <point> must be a positive integer (not %n)" )
    end

    # compute the image
    if n <= pR.degree
      img = pR.imgs[n]
    else
      img = n
    end

    # return it
    return img
end


QuoIntPerm2 = function( n::Int, pR::Permutation2 )
    local pre, pRimgs

    # permutations do not act on negative integers
    if n <= 0
      error( "Perm. Operations: <point> must be a positive integer (not %n)" )
    end

    pRimgs::Array{UInt16,1} = pR.imgs

    # compute the preimage
    pre = n
    if n <= pR.degree
        while ( pRimgs[ pre ] != n )
            pre = pRimgs[ pre ]
        end
    end

    # return it
    return pre
end


LargestMovedPointPerm = function( perm::Permutation2 )
    local permimgs, sup

    permimgs::Array{UInt16,1} = perm.imgs
    sup = 0

    # find the largest moved point
    for sup in perm.degree:-1:1
      if permimgs[ sup ] != sup
        break
      end
    end

    # return it
    return sup
end


OrderPerm = function( perm::Permutation2 )
    local permimgs, ptKnown2, ord, p, len, q, gcd, s, t

    permimgs::Array{UInt16,1} = perm.imgs

    # make sure that the buffer bag is large enough
    # clear the buffer bag
    ptKnown2 = zeros( permimgs )
#T better booleans? or shorter integers, indep. of permimgs?

    # start with order 1
    ord = 1

    # loop over all cycles
    for p in 1:perm.degree

        # if we haven't looked at this cycle so far
        if ( ptKnown2[p] == 0 && permimgs[p] != p )

            # find the length of this cycle
            len = 1
            q = permimgs[p]
            while q != p
              len += 1
              ptKnown2[q] = 1
              q = permimgs[q]
            end

#T call julia's lcm directly?
            # compute the gcd with the previously order ord
            # Note that since len is single precision, ord % len is, too.
            gcd = len
            s = mod( ord, len )
            while ( s != 0 )
              t = s
              s = mod( gcd, s )
              gcd = t
            end
            ord = ord * div( len, gcd )
        end
    end

    # return the order
    return ord
end


OnePerm = function( perm::Permutation2 )
    return IdentityPerm
end


InvPerm = function( perm::Permutation2 )
    return PowPerm2Int( perm, -1 )
end

# overload the multiplication operator
#function *( pL::Permutation2, pR::Permutation2 )
#    return ProdPerm22( pL, pR )
#end;

# hash function so Permutations can be keys in dictionaries, etc.
hash( p::Permutation2, h::UInt64 ) = hash( p.imgs, h );

# end


