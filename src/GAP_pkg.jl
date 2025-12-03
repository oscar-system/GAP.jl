#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##

import Artifacts: @artifact_str
import Scratch: get_scratch!
using BinaryWrappers

import GAP_pkg_ace_jll
import GAP_pkg_anupq_jll
import GAP_pkg_browse_jll
import GAP_pkg_caratinterface_jll
import GAP_pkg_cddinterface_jll
import GAP_pkg_cohomolo_jll
import GAP_pkg_crypting_jll
import GAP_pkg_curlinterface_jll
import GAP_pkg_cvec_jll
import GAP_pkg_datastructures_jll
import GAP_pkg_deepthought_jll
import GAP_pkg_digraphs_jll
import GAP_pkg_edim_jll
#import GAP_pkg_example_jll          # not useful
import GAP_pkg_ferret_jll
import GAP_pkg_float_jll
import GAP_pkg_fplsa_jll
import GAP_pkg_gauss_jll
#import GAP_pkg_grape_jll            # handled via nauty_jll below
import GAP_pkg_guava_jll
import GAP_pkg_io_jll
import GAP_pkg_json_jll
#import GAP_pkg_jupyterkernel_jll    # useful?
import GAP_pkg_kbmag_jll
import GAP_pkg_normalizinterface_jll
import GAP_pkg_nq_jll
import GAP_pkg_orb_jll
import GAP_pkg_profiling_jll
import GAP_pkg_semigroups_jll
import GAP_pkg_simpcomp_jll
#import GAP_pkg_xgap_jll             # useful?
import GAP_pkg_zeromqinterface_jll

const gap_pkg_jlls = Module[]

# GAP package "4ti2interface" uses executables from lib4ti2_jll
import lib4ti2_jll

# GAP package "grape" uses `dreadnaut` executable from nauty_jll
import nauty_jll

# GAP package "singular" uses `Singular` executable from Singular_jll
import Singular_jll

# GAP package "polymaking" uses the 'polymake' Perl script from polymake_jll
# which means we need to access Perl_jll a well
import polymake_jll
import polymake_jll: Perl_jll, JLLWrappers

const pkg_bindirs = Dict{String, String}()

function gap_pkg_artifact_dir(pkgname)
  d = @artifact_str("GAP_pkg_$(pkgname)")
  return joinpath(d, only(readdir(d)))
end

function setup_overrides()
    gap_pkg_jll_names = filter(startswith("GAP_pkg"), String.(names(GAP; imported=true)))
    for pkg in gap_pkg_jll_names
        jll = getproperty(GAP, Symbol(pkg))
        @assert jll isa Module
        pkg = pkg[9:end-4]

        # Crude heuristic: if the JLL has a `bin` directory then we assume it
        # contains executables the packages uses; otherwise assume it contains
        # a kernel extension `lib/gap/BLAH.so`.
        #
        # This fails if a package has both executables and a kernel extension.
        pkg_bindirs[realpath(gap_pkg_artifact_dir(pkg))] =
              if isdir(joinpath(jll.find_artifact_dir(), "bin"))
                  @generate_wrappers(jll)
              else
                  joinpath(jll.find_artifact_dir(), "lib", "gap")
              end
    end

    # ensure GAPInfo.DirectoriesPrograms is initialized
    GAP.Globals.DirectoriesSystemPrograms()

    # GAP package "4ti2interface" uses executables from lib4ti2_jll
    lib4ti2_path = @generate_wrappers(lib4ti2_jll)
    d = GAP.Globals.Directory(GapObj(lib4ti2_path))
    GAP.Globals.Add(GAP.Globals.GAPInfo.DirectoriesPrograms, d)

    # GAP package "grape" uses `dreadnaut` executable from nauty_jll
    pkg_bindirs[realpath(gap_pkg_artifact_dir("grape"))] = @generate_wrappers(nauty_jll)

    # GAP package "singular" uses `Singular` executable from Singular_jll
    singular_binpath = @generate_wrappers(Singular_jll)
    GAP.Globals.sing_exec = GapObj(joinpath(singular_binpath, "Singular"))
    d = GAP.Globals.Directory(GapObj(singular_binpath))
    GAP.Globals.Add(GAP.Globals.GAPInfo.DirectoriesPrograms, d)

    # GAP package "polymaking" uses the 'polymake' Perl script from polymake_jll
    polymake_base = generate_polymake_wrapper()
    GAP.Globals.POLYMAKE_COMMAND = GapObj(joinpath(polymake_base, "polymake"))
    GAP.Globals.POLYMAKE_PATH = GapObj(joinpath(polymake_base, "polymakeLegacy "))
end

function find_override(installationpath::String)
    rp = realpath(installationpath)
    op = get(pkg_bindirs, rp, nothing)
    if op !== nothing
        @debug "DirectoriesPackagePrograms override detected:\n    $installationpath\n => $op"
        return op
    end
    return joinpath(installationpath, "bin", String(GAP.Globals.GAPInfo.Architecture))
end

function generate_polymake_wrapper()

    # we generate wrappers per minor julia version
    # the scratch will belong to the jll which the wrappers are generated for
    # and the usage is tied to the module calling the `@generate` macro.
    target = get_scratch!(polymake_jll, BinaryWrappers.wrapper_key, GAP)

    binpath(name) = joinpath(target, "bin", name)
    mkpath(binpath(""))

    bindir = joinpath(polymake_jll.find_artifact_dir(), "bin")
    polymakescript = polymake_jll.get_polymake_path()
    perlbinary = polymake_jll.Perl_jll.get_perl_path()
    libpath = polymake_jll.LIBPATH[]

    wrapper = """
        #!/bin/sh
        # Since we cannot run these binaries through the usual julia commands we need
        # this wrapper that sets up the correct library paths.
        export $(JLLWrappers.LIBPATH_env)="$(libpath)"
        exec $(perlbinary) -- $(polymakescript) "\$@"
        """

    (tmpfile, tmpio) = mktemp(binpath(""),cleanup=false)
    write(tmpio, wrapper)
    close(tmpio)
    chmod(tmpfile, 0o755)
    # using mv would introduce some race conditions due to concurrent deletes
    Base.Filesystem.rename(tmpfile, binpath("polymake"))

    # extra script for HAP
    polymakeLegacy = raw"""
    #!/bin/bash
    file=$1;

    if [ $# == 2 ]
    then
      opt1=$2;
      \""""*binpath("polymake")*raw"""\" "my \$c=load(\\"$file\\");  print \\"$opt1\n\\", \$c->$opt1, \\"\n\n\\";" ;
    fi

    if [ $# == 3 ]
    then
      opt1=$2;
      opt2=$3;
      \""""*binpath("polymake")*raw"""\" "my \$c=load(\\"$file\\");  print \\"$opt1\n\\", \$c->$opt1, \\"\n\n\\", \\"$opt2\n\\", \$c->$opt2,  \\"\n\n\\";" ;
    fi

    if [ $# == 4 ]
    then
      opt1=$2;
      opt2=$3;
      opt3=$4;
      \""""*binpath("polymake")*raw"""\" "my \$c=load(\\"$file\\");  print \\"$opt1\n\\", \$c->$opt1, \\"\n\n\\", \\"$opt2\n\\", \$c->$opt2,  \\"\n\n\\", \\"$opt3\n\\", \$c->$opt3, \\"\n\n\\" ;"
    fi
    """

    (tmpfile, tmpio) = mktemp(binpath(""),cleanup=false)
    write(tmpio, polymakeLegacy)
    close(tmpio)
    chmod(tmpfile, 0o755)
    # using mv would introduce some race conditions due to concurrent deletes
    Base.Filesystem.rename(tmpfile, binpath("polymakeLegacy"))

    return binpath("")
end
