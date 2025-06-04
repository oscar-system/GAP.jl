#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: GPL-3.0-or-later
##
##  Reading the implementation part of the package.
##

ReadPackage( "JuliaInterface", "gap/JuliaInterface.gi");

ReadPackage( "JuliaInterface", "gap/adapter.gi");
ReadPackage( "JuliaInterface", "gap/calls.gi");
ReadPackage( "JuliaInterface", "gap/convert.gi");
ReadPackage( "JuliaInterface", "gap/utils.gi");
ReadPackage( "JuliaInterface", "gap/helpstring.g");
ReadPackage( "JuliaInterface", "gap/juliahelp.g");

ReadPackage( "JuliaInterface", "gap/override.g");

# setup JLL overrides
GAP_jl.setup_overrides();
