import Artifacts: @artifact_str
using BinaryWrappers

const gap_pkgs_with_overrides = [
    "ace"
    "anupq"
    "browse"
    "caratinterface"
    "cddinterface"
    "cohomolo"
    "crypting"
    #"curlinterface"
    "cvec"
    "datastructures"
    "deepthought"
    "digraphs"
    "edim"
    #"example"          # not useful
    "ferret"
    "float"
    "fplsa"
    "gauss"
    #"grape"            # handled via nauty_jll below
    "guava"
    "io"
    "json"
    #"jupyterkernel"    # useful?
    "kbmag"
    "normalizinterface"
    "nq"
    "orb"
    "profiling"
    #"semigroups"
    "simpcomp"
    #"xgap"             # useful?
    "zeromqinterface"
    ]

# import JLLs from above
for pkg in gap_pkgs_with_overrides
    jll = Symbol("GAP_pkg_$(pkg)_jll")
    @eval import $jll
end

# GAP package "4ti2interface" uses executables from lib4ti2_jll
import lib4ti2_jll

# GAP package "grape" uses `dreadnaut` executable from nauty_jll
import nauty_jll

# GAP package "singular" uses `Singular` executable from Singular_jll
import Singular_jll

const pkg_bindirs = Dict{String, String}()

function gap_pkg_artifact_dir(pkgname)
  d = @artifact_str("GAP_pkg_$(pkgname)")
  return joinpath(d, only(readdir(d)))
end

function setup_overrides()
    for pkg in gap_pkgs_with_overrides
        jll = getproperty(GAP, Symbol("GAP_pkg_$(pkg)_jll"))

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

    # GAP package "4ti2interface" uses executables from lib4ti2_jll
    lib4ti2_path = @generate_wrappers(lib4ti2_jll)
    d = GAP.Globals.Directory(GapObj(lib4ti2_path))
    GAP.Globals.DirectoriesSystemPrograms()  # ensure GAPInfo.DirectoriesPrograms is initialized
    GAP.Globals.Add(GAP.Globals.GAPInfo.DirectoriesPrograms, d)

    # GAP package "grape" uses `dreadnaut` executable from nauty_jll
    pkg_bindirs[realpath(gap_pkg_artifact_dir("grape"))] = @generate_wrappers(nauty_jll)

    # GAP package "singular" uses `Singular` executable from Singular_jll
    singular_binpath = @generate_wrappers(Singular_jll)
    Globals.sing_exec = GapObj(joinpath(singular_binpath, "Singular"))
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
