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
##  Read the implementation part of the package.
##

# ...
ReadPackage( "JuliaExperimental", "gap/utils.gi" );

ReadPackage( "JuliaExperimental", "gap/context.gd" );
ReadPackage( "JuliaExperimental", "gap/context.gi" );

# ReadPackage( "JuliaExperimental", "gap/convertcyc.g" );
# JuliaIncludeFile( Filename( dirs, "convertcyc.jl" ) );
# BindJuliaFunc( "juliabox_cycs" );
# 

# shortest vectors, LLL, orthogonal embeddings
ReadPackage( "JuliaExperimental", "gap/zlattice.g" );


# Use Julia to compute the HNF of an integer matrix.
if JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/hnf.g" );
fi;


# Julia permutations
ReadPackage( "JuliaExperimental", "gap/gapperm.g" );


# Nemo's number fields.
if JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/gapnemo.gd" );
  ReadPackage( "JuliaExperimental", "gap/gapnemo.gi" );

  # generic utilities for Nemo conversion
  ReadPackage( "JuliaExperimental", "gap/numfield.g" );
  ReadPackage( "JuliaExperimental", "gap/zmodnz.g" );
fi;


# Arb
if JuliaImportPackage( "Nemo" ) then
  ReadPackage( "JuliaExperimental", "gap/realcyc.g" );
fi;


# Singular
if JuliaImportPackage( "Singular" ) then
  ReadPackage( "JuliaExperimental", "gap/gapsingular.gd" );
  ReadPackage( "JuliaExperimental", "gap/gapsingular.gi" );
  ReadPackage( "JuliaExperimental", "gap/singular.g" );

  if LoadPackage( "RingsForHomalg" ) = true then
    ReadPackage( "JuliaExperimental", "gap/finvar.gd" );
    ReadPackage( "JuliaExperimental", "gap/finvar.gi" );
  fi;
fi;
