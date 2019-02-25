#############################################################################
##
##  loewy.jl
##
##  Examine the Loewy structure of the algebras A(q,n,e)
##

module LoewyStructure

import Primes

"""
    MinimalDegreeCache
> a dictionary that stores at the key `e`, if bound,
> a dictionary that stores at the key `q`, if bound,
> the value `m(q,e)`;
> the values get stored by calls of `MinimalDegree`.
"""
MinimalDegreeCache = Dict();


"""
    PrimeFactors( n::T ) where {T<:Integer}
> Returns the array of prime factors of the integer n
"""
function PrimeFactors( n::T ) where {T<:Integer}
    return map( x -> x[1], collect( Primes.factor( n ) ) )
end;


"""
"""
function RootInt( n, k = 2 )
    local   r, s, t;

    # check the arguments and handle trivial cases
    if k <= 0
      error( "<k> must be positive" )
    elseif k == 1
      return n
    elseif n < 0 && mod( k, 2 ) == 0
      error( "<n> must be positive" )
    elseif n < 0 && mod( k, 2 ) == 1
      return -RootInt( -n, k )
    elseif n == 0
      return 0
    elseif n <= k
      return 1
    end

    # r is the first approximation, s the second, we need: root <= s < r
    r = n
    s = 2^( div( LogInt(n,2), k ) + 1 ) - 1;

    # do Newton iterations until the approximations stop decreasing
    while s < r
      r = s
      t = r^(k-1)
      s = div( n + (k-1)*r*t, k*t )
    end

    # and that's the integer part of the root
    return r
end


"""
    SmallestRootInt( n::T ) where {T<:Integer}
> The smallest root of an integer `n` is the integer `r` of smallest absolute
> value for which a positive integer `k` exists such that `n == r^k`.

"""
function SmallestRootInt( n::T ) where {T<:Integer}
    local   k, r, s, p, l, q;

    # check the argument
    if n > 0
      k = 2
      s = 1
    elseif n < 0
      k = 3
      s = -1
      n = -n
    else
      return 0
    end

    # exclude small divisors, and thereby large exponents
    if mod( n, 2 ) == 0
      p = 2
    else
      p = 3
      while p < 100 && mod( n, p ) != 0
        p = p+2
      end
    end
    l = LogInt( n, p )

    # loop over the possible prime divisors of exponents
    # use Euler's criterion to cast out impossible ones
    while k <= l
      q = 2*k+1
      while ! Primes.isprime( q )
        q = q+2*k
      end
      if powermod( n, div( q-1, k ), q ) <= 1
        r = RootInt( n, k )
        if r ^ k == n
          n = r;
          l = div( l, k )
        else
          k = Primes.nextprime( k+1 )
        end
      else
        k = Primes.nextprime( k+1 )
      end
    end

    return s * n
end


"""
    IsPrimePowerInt( n::T ) where {T<:Integer}
> Returns `true` if `n` is a prime power, and `false` otherwise
"""
function IsPrimePowerInt( n::T ) where {T<:Integer}
    return Primes.isprime( SmallestRootInt( n ) )
end


"""
    Lambda( m::T ) where {T<:Integer}
> Returns the exponent of the group of prime residues modulo the integer m
"""
function Lambda( m::T ) where {T<:Integer}
    local  lambda, p, q, k

    # make <m> it nonnegative, handle trivial cases
    if m < 0
      m = -m
    end
#   if m < Length(PrimeResiduesCache) then
#     return Length(PrimeResiduesCache[m+1]);
#   end

    # loop over all prime factors $p$ of $m$
    lambda = 1
    for p in PrimeFactors( m )

        # compute $p^e$ and $k = (p-1) p^(e-1)$
        q = p
        k = p-1
        while mod( m, (q * p) ) == 0
          q = q * p
          k = k * p
        end

        # multiples of 8 are special
        if mod( q, 8 ) == 0
          k = div( k, 2 )
        end

        # combine with the value known so far
        lambda = lcm( lambda, k )
    end

    return lambda
end;


raw"""
    LogInt( n::Int, base::Int )
> Returns the integer part of the logarithm of the positive integer n
> with respect to the positive integer base,
> i. e., the largest positive integer `e` such that `base^e <= n`.
"""
function LogInt( n::T, base::Int ) where {T<:Integer}
    return Int( floor( log( base, n ) ) )
end;


raw"""
    ModInv( n::Int, m::Int )
> Returns the inverse of the integer n modulo the integer m,
> i. e., the unique integer k in the interval from 1 to m-1
> such that $n * k \equiv 1 \pmod{m}$.
"""
function ModInv( n::Int, m )
    local a, aL, b, bL, hdQ, c, cL

    a = m
    aL = 0
    b = n
    bL = 1
    while a != 1
      while b != 0
        hdQ = div( a, b )
        c = b
        cL = bL
        b = a - hdQ * b
        bL = aL - hdQ * bL
        a = c
        aL = cL
      end
      if a != 1
        error( "<n> not invertible mod <m>" )
      end
    end

    return mod( aL, m )
end;


raw"""
    OrderMod( n::Int, m )
> Returns the multiplicative order of the integer n modulo the
> positive integer m,
> i. e., the smallest positive integer i such that $n^i \equiv 1 \pmod{m}$.
> The function returns 0 if n and m are not coprime.
"""
# function OrderMod( n::Int, m::Int )  -- example where this fails?
function OrderMod( n::Int, m )
    local x, o, d

    # check the arguments and reduce $n$ into the range $0..m-1$
    if m <= 0
      error( "<m> must be positive")
    end
    if n < 0
      n = mod( n, m ) + m
    end
    if m <= n
      n = mod( n, m )
    end

    # return 0 if the $n$ is not coprime to $n$
    if gcd( m, n ) != 1
      o = 0

    # compute the order simply by iterated multiplying, $x= n^o$ mod $m$
    elseif m < 100
      x = n
      o = 1
      while x > 1
        x = mod( x * n, m )
        o = o + 1
      end

    # otherwise try the divisors of $\lambda(m)$ and their divisors, etc.
    else
      o = Lambda( m )
      for d in PrimeFactors( o )
        while mod( o, d ) == 0 && powermod( n, div( o, d ), m ) == 1
          o = div( o, d )
        end
      end
    end

    return Int( o )
#T why Int? (was not in alternative version)
end;


"""
    DuplicateFree( v )
> Returns a vector that contains the same entries as the array v,
> but each entry occurs exactly once.
"""
function DuplicateFree( v )
  v1 = Vector{eltype(v)}()
  if length( v ) > 0
    push!( v1, v[1] )
    for elm in v
      if ! ( elm in v1 )
        push!( v1, elm )
      end
    end
  end

  return v1
end;


"""
    PrimeResidues( m::Int )
> Returns the array of integers from the range `0:(abs(m)-1)`
> that are coprime to the integer `m`.
"""
function PrimeResidues( m::Int )
    local  residues, p, i

    # make <m> it nonnegative, handle trivial cases
    if m < 0
      m = -m
    end
 #  if m < Length(PrimeResiduesCache)  then
 #    return ShallowCopy(PrimeResiduesCache[m+1]);
 #  fi;

    # remove the multiples of all prime divisors
    residues = collect( 1:(m-1) )
    for p in PrimeFactors( m )
      for i in 1:(div(m,p)-1)
        residues[p*i] = 1
      end
    end

    # return the set of residues
    residues = DuplicateFree( residues )
    sort!( residues )
    return residues
end;

"""
    DivisorsInt( n::Int )
> Returns an array of all divisors of the integer `n`. This array is sorted,
> so that it starts with `1` and ends with `n`.
> We define that `DivisorsInt( -n ) == DivisorsInt( n )`.
"""
function DivisorsInt( n::Int )
    local  factors, divs

    # make <n> nonnegative, handle trivial cases, and get prime factors
    if n < 0
      n = -n
    end
    if n == 0
      error( "DivisorsInt: <n> must not be 0" )
    end
#   if n <= Length(DivisorsIntCache)  then
#     return DivisorsIntCache[n];
#   fi;
    factors = Primes.factor( Vector, n )

    # recursive function to compute the divisors
#T without local function?
    divs = function( i::Int, m::Int )
      if length( factors ) < i
        return [ m ]
      elseif mod( m, factors[i] ) == 0
        return divs( i+1, m*factors[i] )
      else
        res = divs(i+1,m)
        append!( res, divs(i+1,m*factors[i]) )
        return res
      end
    end;

    return sort( divs( 1, 1 ) )
end;

"""
>   VectorIterator( m, n, s )
> Iterate over all vectors of length `n`
> with entries in the set { 0, 1, 2, ... `m` }
> and coefficient sum `s`.
> The vectors are enumerated in lexicographical order.
> (The functions change the vectors in place,
> just collecting the results makes no sense.)
"""
mutable struct VectorIterator
    m::Int
    n::Int
    s::Int
end

# Auxiliary function for the iterator:
# Distribute `s` to the first `n` positions in the array `v`
# such that as many initial entries are `m`.
function VectorIterator_ResetPrefix( v::Array{Int,1}, m::Int, n::Int, s::Int )
    local rest::Int, i::Int, j::Int

    rest = s
    i = 1
    while m < rest
      v[i] = m
      rest = rest - m
      i = i + 1
    end
    v[i] = rest
    for j in (i+1):n
      v[j] = 0
    end

    return v
end

# Initialize the iterator.
function Base.iterate( vi::VectorIterator )
    local next::Array{Int,1}

    if vi.s > vi.m * vi.n
      # The iterator is empty.
      return
    end
    next = VectorIterator_ResetPrefix( zeros( Int, vi.n ), vi.m, vi.n, vi.s )
    return ( next, next )
end

# Define the iteration step.
# Note that `state` is changed in place.
function Base.iterate( vi::VectorIterator, state::Array{Int,1} )
    local sum::Int, i::Int

    # Find the first position with a nonzero value
    # such that the value on the right is smaller than m.
    sum = -1
    for i in 1:(vi.n-1)
      sum = sum + state[i]
      if state[i] != 0 && state[ i+1 ] < vi.m
        state[i] = state[i] - 1
        state[i+1] = state[i+1] + 1
        VectorIterator_ResetPrefix( state, vi.m, i, sum )
        return ( state, state )
      end
    end

    # There is no such position, we are done.
    return
end

"""
    MinimalDegreeCheap( q::Int, n::Int, e )
> Return either 0 or the number m(q,e),
> which is the smallest number of powers of q
> such that e divides the sum of these powers.
> The value 0 means that the cheap criteria do not suffice.
> The argument n must be a multiple of OrderMod( q, e ).
"""
function MinimalDegreeCheap( q::Int, n::Int, e::T ) where {T<:Integer}
    local minq, i, modpow

    if e == 1
      return 1
    end

    q = mod( q, e )
    if q == 1
      return e
    elseif q == e-1
      return 2
    end

    # Decide the case m = 2.
    if any( d -> mod( n/d, 2 ) == 0 && powermod( q, d, e ) == e-1,
            DivisorsInt( n ) )
      return 2
    end

    # Replace q by the smallest generator of the cyclic subgroup
    # of prime residues modulo e that is generated by q.
    minq = q
    for i in PrimeResidues( n )
      modpow = powermod( q, i, e )
      if modpow < minq
        minq = modpow
      end
    end
    if q != minq
      q = minq
    end

    # Deal with those cases where e is a prime power,
    # and where we know the value of m(q,e).
    if IsPrimePowerInt( e )
      if mod( e, 2 ) == 0 && 4 < e
        # Part II, Prop. 2.5
        if mod( q, 4 ) == 1
          return gcd( e, q-1 )
        elseif mod( q, e ) != q-1
          return 4
        end
      elseif mod( e, 2 ) == 1
        # Part II, Prop. 2.6
        m = gcd( e, q-1 )
        if m != 1
          return m
        end
      end
    end

    if haskey( MinimalDegreeCache, e ) &&
       haskey( MinimalDegreeCache[e], q )
      return MinimalDegreeCache[e][q]
    end

    return 0
end;


"""
    MinimalDegreeHard( q::Int, n::Int, e )
> Return the number `m(q,e)`, which is the smallest number of powers of `q`
> such that `e` divides the sum of these powers.
> The argument `n` must be a multiple of `OrderMod( q, e )`.
"""
function MinimalDegreeHard( q::Int, n::Int, e::T ) where {T<:Integer}
    local powers, m, v

    powers = map( i -> powermod( q, i, e ), 1:(n-1) )
    m = 3

    while true
      for a in 1:m
        for v in VectorIterator( a, n-1, m-a )
          if mod( a + sum( v .* powers ), e ) == 0
# is there no dot( v, powers ) anymore in Julia 1.0??
# ('.*' needs same length of its operands)
            if ! haskey( MinimalDegreeCache, e )
              MinimalDegreeCache[e] = Dict()
            end
            MinimalDegreeCache[e][q] = m
            return m
          end
        end
      end
      m = m + 1
    end
end;


"""
    MinimalDegree( q::Int, e )
> Return the number `m(q,e)`, which is the smallest number of powers of `q`
> such that `e` divides the sum of these powers.
"""
function MinimalDegree( q::Int, e::T ) where {T<:Integer}
    local n::Int, m::Int

    n = OrderMod( q, e )
    m = MinimalDegreeCheap( q, n, e )
    if m == 0
      m = MinimalDegreeHard( q, n, e )
    end

    return m
end;


function coeffs( res::Array{Int,1}, k::T, q::Int, n::Int ) where {T<:Integer}
  local i::Int, r::Int

  for i in 1:n
    k, r = divrem( k, q )
    res[i] = r
  end

  return res
end;

function islessorequal( mon1::Array{Int,1}, mon2::Array{Int,1}, n::Int )
  local i::Int

  for i in 1:n
    if mon2[i] < mon1[i]
      return false
    end
  end

  return true
end;

"""
    LoewyLayersData( q::Int, n::Int, e::T ) where {T<:Integer}
> Return a dictionary with the following keys.
> :monomials
>     the array of `q`-adic expansions of length `n` for multiples of `e`,
> :layers
>     the array of the Loewy layers to which the monomials belong,
> :chain
>     an array of positions of monomials of a longest ascending chain,
> :m
>     the value `m(q,e)`,
> :ll
>     the Loewy length of `A(n,q,e)`,
>     equal to the length of the `:layers` value plus 1,
> :inputs
>     the array `[ q, n, e ]`.
"""
function LoewyLayersData( q::Int, n::Int, e::T ) where {T<:Integer}
    local ord, zeromon, monomials, layers, degrees, predecessors, m, i, ii,
          mon, lambda, pred, mm, j

    if ( e != 1 && powermod( q, n, e ) != 1 )
      error( "<e> must divide <q>^<n> - 1" )
    elseif Float32( q )^n > typemax( Int )
      ord = BigInt( q )^n - 1
    else
      ord = q^n - 1
    end

    zeromon = zeros( Int, n )
    monomials = [ zeromon ]
    layers = [ 1 ]
    degrees = [ 0 ]
    predecessors = Int[ 0 ]
    m = e
    i = 0
    ii = 1
    while i < ord
      i = i + e
      mon = coeffs( similar( zeromon ), i, q, n )
      lambda = 1
      pred = 1
      mm = sum( mon )
      for j in 2:ii
        if lambda < layers[j] && degrees[j] < mm &&
                                 islessorequal( monomials[j], mon, n )
          lambda = layers[j]
          pred = j
        end
      end
      ii = ii + 1
      push!( monomials, mon )
      push!( layers, lambda + 1 )
      push!( degrees, mm )
      push!( predecessors, pred )

      if lambda == 1
        if mm < m
          m = mm
        end
      end
    end

    # Extract information about one longest chain.
    i = length( monomials )
    pred = Int[ i ]
    while i > 0
      i = predecessors[i]
      push!( pred, i )
    end

    return Dict( :monomials => monomials,
                 :layers => layers,
                 :chain => pred,
                 :m => m,
                 :ll => lambda + 1,
                 :inputs => [ q, n, e ] )
end;


"""
    LoewyVector( data::Dict )
> Returns an array that stores at position `i` the dimension of the `i`-th
> Loewy layer of the Singer algebra described by `data`.
"""
function LoewyVector( data::Dict ) Array{Int,1}
    local v, i

    v = zeros( Int, data[ :ll ] )
    for i in data[ :layers ]
      v[i] = v[i] + 1
    end

    return v
end;


function test_this_module()
    ok::Bool = true

    # PrimeFactors
    if prod( PrimeFactors( 100 ) ) != 10
      ok = false
    end
    n = BigInt(2)^70 - 1
    if prod( PrimeFactors( n ) ) != n
      ok = false
    end

    # RootInt
    if RootInt( 361 ) != 19
      ok = false
    end
    if RootInt( 2 * 10^12 ) != 1414213
      ok = false
    end
    if RootInt( 17000, 5 ) != 7
      ok = false
    end

    # SmallestRootInt
    if SmallestRootInt( 2^30 ) != 2
      ok = false
    end
    if SmallestRootInt( 279936 ) != 6
      ok = false
    end
    if SmallestRootInt( 1001 ) != 1001
      ok = false
    end

    # IsPrimePowerInt
    if ! IsPrimePowerInt( 2^31-1 )
      ok = false
    end
    if IsPrimePowerInt( 2^63-1 )
      ok = false
    end

    # Lambda
    if Lambda( 100 ) != 20
      ok = false
    end
    if Lambda( BigInt(2)^70 - 1 ) != 1361830680
      ok = false
    end

    # LogInt
    if LogInt( 1030, 2 ) != 10
      ok = false
    end
    if LogInt( 1, 10 ) != 0
      ok = false
    end

    # ModInv
    if ModInv( 5, 3 ) != 2
      ok = false
    end
    if ModInv( 21, 55 ) != 21
      ok = false
    end

    # OrderMod
    if OrderMod( 2, 7 ) != 3
      ok = false
    end
    if OrderMod( 3, 7 ) != 6
      ok = false
    end

    # DuplicateFree
    if DuplicateFree( [ 1, 2, 3, 2, 1, 5, 3, 4 ] ) != [ 1, 2, 3, 5, 4 ]
      ok = false
    end

    # PrimeResidues
    if PrimeResidues( 20 ) != [ 1, 3, 7, 9, 11, 13, 17, 19 ]
      ok = false
    end

    # DivisorsInt
    if DivisorsInt( 20 ) != [ 1, 2, 4, 5, 10, 20 ]
      ok = false
    end

    # VectorIterator( m, n, s )
    n = 0
    for i in VectorIterator( 2, 5, 7 )
      n = n + 1
    end
    if n != 30
      ok = false
    end

    # MinimalDegreeCheap( q::Int, n::Int, e )
    # MinimalDegreeHard( q::Int, n::Int, e )
    # MinimalDegree( q, e )
    for e in 2:30
      for q in PrimeResidues( e )
        MinimalDegree( q, e )
      end
    end

    # LoewyLayersData( q::Int, n::Int, e::T ) where {T<:Integer}
    d = LoewyLayersData( 2, 20, 33 )
    if size( d[ :monomials ], 1 ) != 31776
      ok = false
    end

    return ok
end

end

