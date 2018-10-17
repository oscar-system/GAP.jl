OSCAR - LibGAP
--------------

This is some prototype code that uses a version of GAP as a library,
as found the GAP master branch, respectively in GAP 4.11,
to be able to call GAP functions from Julia.

Please don't use for any production code just yet, but do use it for
prototyping and let me know what's wrong with it.

How to use
----------

This is a very rough guide, and your program might crash or otherwise burn.

You need the following ingredients:

- GAP 4.11 or newer (possibly the master branch), in directory `$gapdir`

- Julia 1.1 or newer (possibly the master branch), installed into directory `$juliadir`
  (if you did not install Julia but built it in director `$juliasrc`, then set
  `$juliadir` to `$juliasrc/usr`)

- The `GAPJulia` repository, checked out under `$oscarrepo`

First we compile a version of GAP using the Julia installation in `$juliadir`,
and make sure a `libgap` shared library is compiled:

    cd $oscardir
    mkdir -p gap
    cd gap
    $gapdir/configure --with-gc=julia --with-julia=$juliadir
    make
    make libgap.la

Now we can compile JuliaInterface and JuliaExperimental:

    cd $oscardir
    ./configure $oscardir/gap
    make

Finally, we are ready to start julia and load LibGAP into it

    cd $oscardir/LibGAP.jl
    $juliadir/bin/julia

Then enter:

    include("src/initialization.jl")
    oscardir = ENV["oscardir"]
    libgap.run_it("$oscardir/gap")

You should now see the GAP banner, after which you are ready to use the
rest of LibGAP.jl.
