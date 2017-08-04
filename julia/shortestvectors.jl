
##  julia code that was translated from the GAP function
##  'ShortestVectors' (excluding the LLL call)

shortestvectors = function( llg, bound::Int )
    local llg_B, llg_mue, llg_transformation, n, c_vectors, c_norms, v,
          nullv, checkpositiv, con, srt, vschr

    llg_mue = llg[1]
    llg_B = llg[2]
    llg_transformation = llg[3]

    n = length( llg_B )
    c_vectors = Array{Int32}[]   # right type?
    c_norms = Float64[]
    v = zeros( Int, n )
    nullv = zeros( Int, n )

    checkpositiv = false  # not yet supported, opt. argument
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
          x = x + v[j] * llg_mue[j,d]
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
        q = ( bound + 1/1000 - dam ) / llg_B[d]
        if k * k < q
          i = i + 1
          k = k + 1
          # no repeat loop ...
          while ! ( ( k * k > q ) & ( k > 0 ) )   # brackets are needed!
            i = i + 1
            k = k + 1
          end
          # until k * k > q and k > 0
          i = i - 1
          k = k - 1
          while ( k * k < q ) & con   # brackets are needed!
             v[d] = i
             k1 = llg_B[d] * k * k + dam  # k1 is float?
             srt( d-1, k1 )
             i = i - 1
             k = k - 1
          end
        end
      end
    end

    # *extend* c_vectors and c_norms if necessary
    vschr = function( dam )
      local i, j, w, neg, newv

      newv = zeros( Int, n )  # Int because the *result* shall consist
                              # of integer vectors
      neg = false
      for i = 1:n
        w = 0
        for j = 1:n
          w = w + v[j] * llg_transformation[j,i]
        end
        if w < 0
          neg = true
        end
        newv[i] = w
      end

      if ! ( checkpositiv & neg )
        push!( c_vectors, newv )
        push!( c_norms, dam )
      end
    end

    # main program
    srt( n, 0 )

    return c_vectors
# as soon as dictionaries are available for (un)boxing:
#   return Dict( "vectors" => c_vectors, "norms" => c_norms )
end

