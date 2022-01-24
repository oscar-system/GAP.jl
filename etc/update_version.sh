#!/bin/sh
set -e

# print error in red and exit
error() {
    printf '\033[31mERROR: %s\033[0m\n' "$*"
    exit 1
}


# error if version is too low
if test -z "$1"; then
    echo "Error, no version given"
    exit 1
fi

# release version
relvers=$1

# release date, default is today
reldate=$(date '+%d/%m/%Y')
reldate_iso=$(date '+%Y-%m-%d')

git update-index --refresh > /dev/null || error "uncommitted changes detected"
git diff-index --quiet HEAD -- || error "uncommitted changes detected"

echo "Setting version to $relvers, released $reldate_iso"

# check that CHANGES.md has correct entry
if egrep -q "^## Version ${relvers} " CHANGES.md ; then
    perl -pi -e "s;^## Version ${relvers} \([^)]+\)$;## Version ${relvers} (released ${reldate_iso});" CHANGES.md
elif [[ ${relvers} = *-DEV ]] ; then
    perl -pi -e "s;^(# Changes in GAP.jl)$;\1\n\n## Version ${relvers} (released YYYY-MM-DD);" CHANGES.md
else
    error "Error, CHANGES.md has no section for version ${relvers}"
fi

# update version in several files
perl -pi -e 's;version = "[^"]+";version = "'$relvers'";' Project.toml
perl -pi -e 's;Date := "[^"]+",;Date := "'$reldate'",;' pkg/Julia*/PackageInfo.g
perl -pi -e 's;Version := "[^"]+",;Version := "'$relvers'",;' pkg/Julia*/PackageInfo.g
perl -pi -e 's;\[ "JuliaInterface", ">=[^"]+" \];[ "JuliaInterface", ">='$relvers'" ];' pkg/JuliaExperimental/PackageInfo.g
perl -pi -e 's;\[ "JuliaInterface", ">=[^"]+" \];[ "JuliaInterface", ">='$relvers'" ];' gap/systemfile.g

# commit it
git commit -m "Version $relvers" Project.toml pkg/Julia*/PackageInfo.g gap/systemfile.g CHANGES.md
