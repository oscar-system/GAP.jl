using BinaryWrappers

const pkg_bindirs = Dict{Symbol, String}()

for pkg in [
    :ace,
    :anupq,
    :browse,
    #:caratinterface,
    :cddinterface,
    #:cohomolo,
    :crypting,
    #:curlinterface,
    :cvec,
    :datastructures,
    :deepthought,
    :digraphs,
    :edim,
    #:example,          # not useful
    :ferret,
    :float,
    :fplsa,
    :gauss,
    :grape,
    :guava,
    :io,
    :json,
    #:jupyterkernel,    # useful?
    #:kbmag,
    :normalizinterface,
    :nq,
    :orb,
    :profiling,
    #:semigroups,
    :simpcomp,
    #:xgap,             # useful?
    #:zeromqinterface,
    ]
    jll = Symbol("GAP_pkg_$(pkg)_jll")
    @eval begin
        using $jll
        # Crude heuristic: if the JLL has a `bin` directory then we assume it
        # contains executables the packages uses; otherwise assume it contains
        # a kernel extension `lib/gap/BLAH.so`.
        #
        # This fails if a package has both executables and a kernel extension.
        pkg_bindirs[Symbol($(string(pkg)))] =
              if isdir(joinpath($jll.find_artifact_dir(), "bin"))
                  @generate_wrappers($jll)
              else
                  joinpath($jll.find_artifact_dir(), "lib", "gap")
              end
    end
end

# Special case for GAP package "grape" which uses `dreadnaut` from nauty_jll
using nauty_jll
pkg_bindirs[:grape] = @generate_wrappers(nauty_jll)

function setup_gap_pkg_overrides()
    @debug "running setup_gap_pkg_overrides()"
    for (pkg, dir) in pkg_bindirs
        setproperty!(GAP.Globals.DirectoriesPackageProgramsOverrides, pkg, GapObj(dir))
    end
end
