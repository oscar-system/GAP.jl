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
import polymake_jll

const pkg_bindirs = Dict{String, String}()

function gap_pkg_artifact_dir(pkgname)
  d = @artifact_str("GAP_pkg_$(pkgname)")
  # Artifact overrides may point directly at the GAP package root.
  isfile(joinpath(d, "PackageInfo.g")) && return d
  return joinpath(d, only(readdir(d)))
end

# GAP kernel major version the `GAP_pkg_*_jll` kernel extensions are built
# against; bump together with the `GAP_jll` compat bound
const GAP_JLL_KERNEL_MAJOR_VERSION = 11

kernel_major_versions_match() = parse(Int, sysinfo["GAP_KERNEL_MAJOR_VERSION"]) == GAP_JLL_KERNEL_MAJOR_VERSION

"""
    setup_overrides(; kernel_extensions::Bool = <kernel major versions match>)

Fill the global variable `pkg_bindirs`, which maps GAP package directories
to the JLL directories holding their executables and kernel extensions, for
use by `find_override`.

Called automatically when the JuliaInterface package is loaded.
This function should not be called in any other place.

If `kernel_extensions` is `false`, no entries for kernel extensions are
added, so GAP loads them from the `bin` directories of the packages
themselves. This is the default if the GAP kernel major version differs from
the global variable `GAP_JLL_KERNEL_MAJOR_VERSION`, which is only
allowed in sessions started via `etc/run_with_override.jl`.
"""
function setup_overrides(; kernel_extensions::Bool = kernel_major_versions_match())
    if !kernel_extensions
        @debug "Not using kernel extensions from GAP_pkg_*_jll due to GAP kernel version mismatch: " *
               "expected $(GAP_JLL_KERNEL_MAJOR_VERSION), have $(sysinfo["GAP_KERNEL_MAJOR_VERSION"])"
    end
    gap_pkg_jll_names = filter(startswith("GAP_pkg"), String.(names(GAP; imported=true)))
    for pkg in gap_pkg_jll_names
        jll = getproperty(GAP, Symbol(pkg))
        @assert jll isa Module
        push!(gap_pkg_jlls, jll)
        pkg = pkg[9:end-4]

        # Crude heuristic: if the JLL has a `bin` directory then we assume it
        # contains executables the package uses; if it has a `lib/gap`
        # directory, we assume it contains a kernel extension `BLAH.so`.
        #
        # This fails if a package has both executables and a kernel extension.
        if isdir(joinpath(jll.find_artifact_dir(), "bin"))
            pkg_bindirs[realpath(gap_pkg_artifact_dir(pkg))] = @generate_wrappers(jll)
        elseif isdir(joinpath(jll.find_artifact_dir(), "lib", "gap"))
            if kernel_extensions
                pkg_bindirs[realpath(gap_pkg_artifact_dir(pkg))] = joinpath(jll.find_artifact_dir(), "lib", "gap")
            end
        else
            error("$(jll) has neither a `bin` nor a `lib/gap` directory")
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
    polymake_binpath = @generate_wrappers(polymake_jll)
    GAP.Globals.POLYMAKE_COMMAND = GapObj(joinpath(polymake_binpath, "polymake"))
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
