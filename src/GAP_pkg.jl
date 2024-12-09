#using BinaryWrappers


import GAP_pkg_ace_jll
import GAP_pkg_anupq_jll
import GAP_pkg_browse_jll
import GAP_pkg_cddinterface_jll
import GAP_pkg_crypting_jll
import GAP_pkg_cvec_jll
import GAP_pkg_datastructures_jll
import GAP_pkg_deepthought_jll
import GAP_pkg_digraphs_jll
import GAP_pkg_edim_jll
import GAP_pkg_ferret_jll
import GAP_pkg_float_jll
import GAP_pkg_fplsa_jll
import GAP_pkg_gauss_jll
import GAP_pkg_guava_jll
import GAP_pkg_io_jll
import GAP_pkg_json_jll
import GAP_pkg_normalizinterface_jll
import GAP_pkg_nq_jll
import GAP_pkg_orb_jll
import GAP_pkg_simpcomp_jll



function set_up_gap_pkg_overrides()
    # set up a few package JLLs providing kernel extensions
    for pkg in [:browse, :cddinterface, :crypting, :cvec, :datastructures,
                :deepthought, :digraphs, :edim, :ferret, :float, :io, :json,
                :normalizinterface, :orb]
        @eval begin
            dir = joinpath($(Symbol("GAP_pkg_$(pkg)_jll")).find_artifact_dir(), "lib", "gap")
            GAP.Globals.DirectoriesPackageProgramsOverrides.$(pkg) = GapObj(dir)
        end
    end

    # set up a few package JLLs providing binaries
#    for pkg in [:ace. :anupq, :fplsa, :nq, :simpcomp]
#        @eval begin
#            dir = BinaryWrappers.@generate_wrappers($(Symbol("GAP_pkg_$(pkg)_jll")))
#            GAP.Globals.DirectoriesPackageProgramsOverrides.$(pkg) = GapObj(dir)
#        end
#    end

end
