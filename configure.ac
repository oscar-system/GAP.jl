#
# JuliaInterface: Test interface to julia
#
# This file is part of the build system of a GAP kernel extension.
# Requires GNU autoconf, GNU automake and GNU libtool.
#

dnl ##
dnl ## Setup autoconf
dnl ##
AC_PREREQ([2.68])
AC_INIT([JuliaInterface], m4_esyscmd([tr -d '\n' < VERSION]))
AC_CONFIG_SRCDIR([src/JuliaInterface.c])
AC_CONFIG_HEADER([src/pkgconfig.h:cnf/pkgconfig.h.in])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([cnf])

dnl ##
dnl ## Get canonical host info
dnl ##
AC_CANONICAL_HOST

dnl ##
dnl ## Setup automake
dnl ##
AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects])
AM_SILENT_RULES([yes])
AM_PROG_AR

dnl ##
dnl ## Set the language
dnl ##
AC_PROG_CC
AC_LANG([C])

dnl ##
dnl ## Setup libtool (for building the GAP kernel extension)
dnl ##
LT_PREREQ([2.4.2])
LT_INIT([disable-static dlopen win32-dll])

dnl ##
dnl ## Locate the GAP root dir
dnl ##
AC_FIND_GAP

dnl ##
dnl ## Set julia
dnl ##
AC_ARG_WITH([julia],
    [AC_HELP_STRING([--with-julia=<path>], [specify root of julia installation])],
    [JULIA="$with_julia"],
    [JULIA="$PWD"]
)
JULIA_CPPFLAGS="-I$JULIA/include/julia"
JULIA_LDPATH="$JULIA/lib"
JULIA_LDFLAGS="-L$JULIA_LDPATH"
AC_SUBST(JULIA_LDPATH)
AC_SUBST(JULIA_LDFLAGS)
AC_SUBST(JULIA_CPPFLAGS)

AC_DEFINE_UNQUOTED(JULIA_LDPATH, ["$JULIA_LDPATH"], [path to Julia installation])

dnl ##
dnl ## Detect pointer size to distinguish 32 and 64 bit builds
dnl ##
AC_CHECK_SIZEOF([void **])

dnl ##
dnl ## Detect Windows resp. Cygwin
dnl ##
case $host_os in
  *cygwin* ) CYGWIN=yes;;
         * ) CYGWIN=no;;
esac
AM_CONDITIONAL([SYS_IS_CYGWIN], [test "$CYGWIN" = "yes"])
if test "$CYGWIN" = "yes"; then
  AC_DEFINE(SYS_IS_CYGWIN32, 1, [are we on CYGWIN?])
else
  AC_DEFINE(SYS_IS_CYGWIN32, 0, [are we on CYGWIN?])
fi

case $host_os in
  *darwin* ) DARWIN=yes;;
         * ) DARWIN=no;;
esac
AM_CONDITIONAL([SYS_IS_DARWIN], [test "$DARWIN" = "yes"])


dnl ##
dnl ## Rebuild configure if VERSION file changes
dnl ##
AC_SUBST([CONFIG_STATUS_DEPENDENCIES], ['$(top_srcdir)/VERSION'])

dnl ##
dnl ## Output everything
dnl ##
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
