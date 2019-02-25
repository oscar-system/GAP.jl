##############################################################################
##
##  gapperm.jl
##
##  This is an experimental implementation of permutations in Julia.
##  The code was translated more or less literally from GAP's 'src/permutat.c'.

#T use @inbounds for the loops
#T specify types for local variables

module GAPPermutations

import Base: length, similar, zeros, ==, isless, *, one, inv, ^, /

# import Base.hash

# create the julia types
struct Permutation2 # means permutations of positive 16 bit integers
    degree::UInt16
    imgs::Array{UInt16,1}
end

struct Permutation4 # means permutations of positive 32 bit integers 
    degree::UInt32
    imgs::Array{UInt32,1}
end

Permutation2or4 = Union{ Permutation2, Permutation4 }


#T *check* the input?
function Permutation( degree::UInt16, imgsarray::Array{UInt16,1} )
    return Permutation2( degree, imgsarray )
   end

function Permutation( degree::UInt32, imgsarray::Array{UInt32,1} )
    return Permutation4( degree, imgsarray )
   end

function Permutation( imgsarray::Array{UInt16,1} )
    return Permutation2( length( imgsarray ), imgsarray )
   end

function Permutation( imgsarray::Array{UInt32,1} )
    return Permutation4( length( imgsarray ), imgsarray )
   end

function Permutation( imgsarray::Array{Int,1} )
        local conv16, conv32

        if length( imgsarray ) <= 2^16
          conv16::Array{UInt16,1} = convert( Array{UInt16,1}, imgsarray )
          return Permutation2( length( conv16 ), conv16 )
        else
          conv32::Array{UInt32,1} = convert( Array{UInt32,1}, imgsarray )
          return Permutation4( length( conv32 ), conv32 )
        end
    end

# Note that 'GAPToJulia' creates Array{Any,1}.
function Permutation( imgsarray::Array{Any,1} )
        local conv16, conv32

        if length( imgsarray ) <= 2^16
          conv16::Array{UInt16,1} = convert( Array{UInt16,1}, imgsarray )
          return Permutation2( length( conv16 ), conv16 )
        else
          conv32::Array{UInt32,1} = convert( Array{UInt32,1}, imgsarray )
          return Permutation4( length( conv32 ), conv32 )
        end
    end


const IdentityPerm = Permutation2( 0, UInt16[] )

# Julia automatically abbreviates long lists.
Base.show( io::IO, perm::Permutation2or4 ) = print( io, "<permutation: ",
                                                    perm.imgs, ">" )

# Provide the methods
function EqPerm( pL::Permutation2or4, pR::Permutation2or4 )
    local degL, degR, pLimgs, pRimgs, p

    degL = pL.degree
    degR = pR.degree
    pLimgs = pL.imgs
    pRimgs = pR.imgs

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

    # search for a difference and return false if you find one
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


function LtPerm( pL::Permutation2or4, pR::Permutation2or4 )
    local degL, degR, pLimgs, pRimgs, p

    # get the degrees of the permutations
    degL = pL.degree
    degR = pR.degree
    pLimgs = pL.imgs
    pRimgs = pR.imgs

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


function ProdPerm( pL::Permutation2or4, pR::Permutation2or4 )
    local degL, degR, prd, len, img

    # get the degrees of the permutations
    degL = pL.degree
    degR = pR.degree
    pLimgs = pL.imgs
    pRimgs = pR.imgs

    # compute the size of the result and allocate a bag
    if degL < degR
      prd = similar( pRimgs )
      len = degR
    else
      prd = similar( pLimgs )
      len = degL
    end

    # if the left (inner) permutation has smaller degree, it is very easy
    if degL <= degR
      for p in 1:degL
        @inbounds prd[p] = pRimgs[ pLimgs[p] ]
      end
      for p in (degL+1):degR
        @inbounds prd[p] = pRimgs[p]
      end
    else
      for p in 1:degL
        @inbounds img = pLimgs[p]
        @inbounds prd[p] = ( img <= degR ? pRimgs[ img ] : img )
      end
    end

    # return the result
    return Permutation( len, prd )
end


function PowPermInt( pL::Permutation2or4, n::Int )
    local deg, pLimgs, pow

    # handle zeroth and first powers separately
    if ( n == 0 )
      return IdentityPerm
    elseif ( n == 1 )
      return pL
    end

    # get the operands and allocate the result list
    deg = pL.degree
    pLimgs = pL.imgs
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
        ptKnown = falses( deg )

        # loop over all cycles
        for p in 1:deg

            # if we haven't looked at this cycle so far
            if ! ptKnown[p]

                # find the length of this cycle
                len = 1
                q = pLimgs[p]
                while q != p
                  ptKnown[q] = true
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
        ptKnown = falses( deg )

        # get pointer to the permutation and the power
        exp = -n

        # loop over all cycles
        for p in 1:deg

            # if we haven't looked at this cycle so far
            if ! ptKnown[p]

                # find the length of this cycle
                len = 1
                q = pLimgs[p]
                while q != p
                  ptKnown[q] = true
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
    return Permutation( deg, pow )
end


function PowIntPerm( n::Int, pR::Permutation2or4 )
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


function QuoIntPerm( n::Int, pR::Permutation2or4 )
    local pre, pRimgs

    # permutations do not act on negative integers
    if n <= 0
      error( "Perm. Operations: <point> must be a positive integer (not %n)" )
    end

    pRimgs = pR.imgs

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


##  Here the syntax is different from that in GAP's C code.
function LargestMovedPointPerm( perm::Permutation2or4 )
    local permimgs, sup

    permimgs = perm.imgs

    # find the largest moved point
    for sup in perm.degree:-1:1
      if permimgs[ sup ] != sup
        return sup
      end
    end

    # return it
    return 0
end


function OrderPerm( perm::Permutation2or4 )
    local permimgs, ptKnown2, ord, p, len, q, gcd, s, t

    permimgs = perm.imgs

    # make sure that the buffer bag is large enough
    # clear the buffer bag
    ptKnown2 = falses( perm.degree )

    # start with order 1
    ord = 1

    # loop over all cycles
    for p in 1:perm.degree

        # if we haven't looked at this cycle so far
        if ( ! ptKnown2[p] && permimgs[p] != p )

            # find the length of this cycle
            len = 1
            q = permimgs[p]
            while q != p
              len += 1
              ptKnown2[q] = true
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


function OnePerm( perm::Permutation2or4 )
    return IdentityPerm
end


function InvPerm( perm::Permutation2or4 )
    return PowPermInt( perm, -1 )
end


# Overload the Julia operations.
function ==( pL::Permutation2or4, pR::Permutation2or4 )
    return EqPerm( pL, pR )
end

function isless( pL::Permutation2or4, pR::Permutation2or4 )
    return LtPerm( pL, pR )
end

function *( pL::Permutation2or4, pR::Permutation2or4 )
    return ProdPerm( pL, pR )
end

function one( perm::Permutation2or4 )
    return IdentityPerm
end

function inv( perm::Permutation2or4 )
    return InvPerm( perm )
end

function ^( perm::Permutation2or4, n::Int )
    return PowPermInt( perm, n )
end

function ^( n::Int, perm::Permutation2or4 )
    return PowIntPerm( n, perm )
end

function /( n::Int, perm::Permutation2or4 )
    return QuoIntPerm( n, perm )
end


# hash function so Permutations can be keys in dictionaries, etc.
# hash( p::Permutation2or4, h::UInt64 ) = hash( p.imgs, h );

# using Requests
# 
# function PermutationFromMeatAxeFile( filename::String )
#     local l::HttpCommon,
#           str::String,
#           spl::Array{String,1},
#           header::Array{String,1},
#           n::Integer,
#           imgs
# 
#     # Fetch and read the file.
#     if startswith( filename, "http://" )
#       l = get( url )
#       if l.status != 200
#         error( "file ", filename, " not found" )
#       end
#       str = readstring( l )
#       spl = split( str, "\n", keep = false )
#     else
#       try
#         spl = readlines( filename )
#       catch( e )
#         error( e )
#       end
#     end
# 
#     # Evaluate the file header.
#     header = split( shift!( spl ), " ", keep = false )
#     if length( header ) != 4
#       error( "corrupted header of MeatAxe file ", filename )
#       # or too large degree ...
#     elseif header[1] != "12"
#       error( "MeatAxe file ", filename, " does not contain a permutation" )
#     elseif header[2] != "1"
#       error( "MeatAxe file ", filename, " contains more than one permutation?" )
#     end
# 
#     # Turn the lines of the file into integers.
#     n = parse( Int, header[3] )
#     if n != length( spl )
#       error( "number of images does not fit" )
#     elseif n <= 2^16
#       imgs::Array{UInt16} = map( x -> parse( UInt16, x ), spl )
#     else
#       imgs::Array{UInt32} = map( x -> parse( UInt32, x ), spl )
#     end
# 
#     # Create the permutation.
#     return Permutation( n, imgs )
# end

# PermutationFromMeatAxeFile( "HSG1-p1100aB0.m1" )  # if locally available
# PermutationFromMeatAxeFile(
#     "http://brauer.maths.qmul.ac.uk/Atlas/spor/M11/mtx/M11G1-p11B0.m1" )

end

