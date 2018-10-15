OSCAR - LibGAP
--------------

This is some prototype code that uses a version of GAP as a library,
for example as currently to be found at https://github.com/gap-system/gap/pull/1205
to be able to call GAP functions from Julia.

Please don't use for any production code just yet, but do use it for
prototyping and let me know what's wrong with it.

How to use
----------

This is a very rough guide, and your program might crash or otherwise burn.

First you need to get a libgap-capable gap. I will be assuming that
you have a clone of the GAP git repository around, in `$gaprepo`

```
$gaprepo > git checkout -b markuspf-gap-library master
$gaprepo > git pull https://github.com/markuspf/gap.git gap-library
$gaprepo > sh autogen.sh
$gaprepo > ./configure --enable-libgap
$gaprepo > make libgap
```

now you checkout this repository into $oscarrepo, and start julia, telling it about
the location of libgap.so

```
$oscarrepo > env LD_LIBRARY_PATH=$gaprepo/.libs:$LD_LIBRARY_PATH julia 
julia> include("src/libgap.jl")
julia> libgap_initialize( [ ""
                     , "-l", "$gaprepo"
                     , "-T", "-r", "-A", "-q"
                     , "-m", "512m" ] )
julia> o = libgap_eval_string("Group((1,2,3));")
```

