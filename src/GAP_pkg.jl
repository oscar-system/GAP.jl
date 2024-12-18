import Artifacts: @artifact_str
using BinaryWrappers

function gap_pkg_artifact_dir(pkgname)
  d = @artifact_str("GAP_pkg_$(pkgname)")
  return joinpath(d, only(readdir(d)))
end

const pkg_bindirs = Dict{String, String}()

for pkg in [
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
    jll = Symbol("GAP_pkg_$(pkg)_jll")
    @eval begin
        import $jll
        # Crude heuristic: if the JLL has a `bin` directory then we assume it
        # contains executables the packages uses; otherwise assume it contains
        # a kernel extension `lib/gap/BLAH.so`.
        #
        # This fails if a package has both executables and a kernel extension.
        pkg_bindirs[realpath(gap_pkg_artifact_dir($pkg))] =
              if isdir(joinpath($jll.find_artifact_dir(), "bin"))
                  @generate_wrappers($jll)
              else
                  joinpath($jll.find_artifact_dir(), "lib", "gap")
              end
    end
end

# Special case for GAP package "grape" which uses `dreadnaut` from nauty_jll
import nauty_jll
pkg_bindirs[realpath(gap_pkg_artifact_dir("grape"))] = @generate_wrappers(nauty_jll)

function find_override(installationpath::String)
    rp = realpath(installationpath)
    op = get(pkg_bindirs, rp, nothing)
    if op !== nothing
        @debug "DirectoriesPackagePrograms override detected:\n    $installationpath\n => $op"
        return op
    end
    return joinpath(installationpath, "bin", String(GAP.Globals.GAPInfo.Architecture))
end
