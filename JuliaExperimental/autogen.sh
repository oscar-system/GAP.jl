#!/bin/sh -ex
#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file is part of the build system of a GAP kernel extension.
# Requires GNU autoconf, GNU automake and GNU libtool.
#
autoreconf -vif `dirname "$0"`
