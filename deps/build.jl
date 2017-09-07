oldwdir = pwd()
const nemodir = Pkg.dir("Nemo")

pkgdir = dirname(dirname(@__FILE__))
wdir = joinpath(pkgdir, "deps")
vdir = joinpath(pkgdir, "local")
nemovdir = "$nemodir/local"

if is_apple() && !("CC" in keys(ENV))
   ENV["CC"] = "clang"
   ENV["CXX"] = "clang++"
end

if !ispath(vdir)

    mkdir(vdir)

    if !ispath(joinpath(vdir, "lib"))
        mkdir(joinpath(vdir, "lib"))
    end
else
    println("Deleting old $vdir")
    rm(vdir, force=true, recursive=true)
    mkdir(vdir)
    mkdir(joinpath(vdir, "lib"))
end

LDFLAGS = "-Wl,-rpath,$vdir/lib -Wl,-R,$vdir/lib  -Wl,-R,$nemovdir/lib -Wl,-R,\$\$ORIGIN/../share/julia/site/v$(VERSION.major).$(VERSION.minor)/Nemo/local/lib"

if is_windows()
   error("Sorry LibGAP is not currently available on native Windows")
end

cd(wdir)

# Build libGAP

   println("Building GAP ... ")
   
   try
      println("Cloning GAP ... ")
      run(`git clone https://github.com/markuspf/gap/`)
      cd(joinpath("$wdir", "gap"))
      run(`git checkout gap-library`)
   catch
      if ispath(joinpath("$wdir", "gap"))
         cd(joinpath("$wdir", "gap"))
         run(`git fetch`)
         run(`git checkout gap-library`)
      end
   end
      
   run(`./autogen.sh`)
   withenv("LD_LIBRARY_PATH"=>"$nemovdir/lib", "LDFLAGS"=>LDFLAGS) do
      run(`./configure --enable-libgap --prefix=$vdir --with-gmp=$nemovdir`)
      run(`make bootstrap-pkg-minimal`)
      run(`make libgap`)
      cp(".libs/libgap.so.0.0.0", "$vdir/lib/libgap.so", remove_destination=true)
   end

   cd(wdir)

# done building GAP

push!(Libdl.DL_LOAD_PATH, joinpath(vdir, "lib"))

cd(oldwdir)
