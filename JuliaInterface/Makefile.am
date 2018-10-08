#
# JuliaInterface: Test interface to julia
#
# This file is part of the build system of a GAP kernel extension.
# Requires automake.
#
ACLOCAL_AMFLAGS = -I m4

BINARCHDIR = bin/$(GAPARCH)
GAPINSTALLLIB = $(abs_top_srcdir)/$(BINARCHDIR)/JuliaInterface.so

lib_LTLIBRARIES = JuliaInterface.la

JuliaInterface_la_SOURCES = src/JuliaInterface.c
JuliaInterface_la_CPPFLAGS = $(GAP_CPPFLAGS) $(JULIA_CPPFLAGS) -DJULIA_ENABLE_THREADING=1
JuliaInterface_la_CFLAGS = $(GAP_CFLAGS)
JuliaInterface_la_LDFLAGS = $(JULIA_LDFLAGS) -ljulia -R$(JULIA_LDPATH) -module -avoid-version $(JULIA_LDPATH)/libstdc++.so.6
## Set rpath
JuliaInterface_la_LDFLAGS += -R $(JULIA_LDPATH)
if SYS_IS_CYGWIN
JuliaInterface_la_LDFLAGS += -no-undefined -version-info 0:0:0 -Wl,$(GAPROOT)/bin/$(GAPARCH)/gap.dll
endif

all-local: JuliaInterface.la
	$(mkdir_p) $(top_srcdir)/$(BINARCHDIR)
if SYS_IS_CYGWIN
	cp .libs/JuliaInterface.dll $(GAPINSTALLLIB)
else
	cp .libs/JuliaInterface.so $(GAPINSTALLLIB)
endif
	@echo "SUCCESS!"

distclean-local:
	rm -rf bin/*
	(cd doc ; ./clean)

doc: doc/manual.six

doc/manual.six: doc/*.xml PackageInfo.g
	($(GAPROOT)/bin/gap.sh -A makedoc.g)
