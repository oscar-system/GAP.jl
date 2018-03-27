#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file is part of the build system of a GAP kernel extension.
# Requires automake.
#
ACLOCAL_AMFLAGS = -I m4

BINARCHDIR = bin/$(GAPARCH)
GAPINSTALLLIB = $(abs_top_srcdir)/$(BINARCHDIR)/JuliaExperimental.so

lib_LTLIBRARIES = JuliaExperimental.la

JuliaExperimental_la_SOURCES = src/JuliaExperimental.c
JuliaExperimental_la_CPPFLAGS = $(GAP_CPPFLAGS) $(JULIA_CPPFLAGS) -DCONFIG_H -DJULIA_ENABLE_THREADING=1
# Note that the latter is only for GAP 4.4.12
JuliaExperimental_la_LDFLAGS = $(JULIA_LDFLAGS) -ljulia -R$(JULIA_LDPATH) -module -avoid-version $(JULIA_LDPATH)/libstdc++.so.6
if SYS_IS_DARWIN
# HACK to support linking against prebuilt Julia binaries from
# the Julia website.
JuliaExperimental_la_LDFLAGS += -Wl,-rpath,$(JULIA_LDPATH)
endif
if SYS_IS_CYGWIN
JuliaExperimental_la_LDFLAGS += -no-undefined -version-info 0:0:0 -Wl,$(GAPROOT)/bin/$(GAPARCH)/gap.dll
endif

all-local: JuliaExperimental.la
	$(mkdir_p) $(top_srcdir)/$(BINARCHDIR)
if SYS_IS_CYGWIN
	cp .libs/JuliaExperimental.dll $(GAPINSTALLLIB)
else
	cp .libs/JuliaExperimental.so $(GAPINSTALLLIB)
endif
	@echo "SUCCESS!"

distclean-local:
	rm -rf bin/*
	(cd doc ; ./clean)

doc: doc/manual.six

doc/manual.six: doc/*.xml PackageInfo.g
	($(GAPROOT)/bin/gap.sh -A makedoc.g)
