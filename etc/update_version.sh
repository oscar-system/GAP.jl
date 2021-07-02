#!/bin/sh

set -e

# error if version is too low
if test -z "$1"; then
    echo "Error, no version given"
    exit 1
fi

# release version
relvers=$1

# release date, default is today
today=$(date '+%d/%m/%Y')
reldate=${2:-$today}

echo "Setting version to $relvers, released $reldate"

# TODO: verify that there are no uncommitted changes

#
perl -pi -e 's;version = "[^"]+";version = "'$relvers'";' Project.toml
perl -pi -e 's;Date := "[^"]+",;Date := "'$reldate'",;' pkg/Julia*/PackageInfo.g
perl -pi -e 's;Version := "[^"]+",;Version := "'$relvers'",;' pkg/Julia*/PackageInfo.g
perl -pi -e 's;\[ "JuliaInterface", ">=[^"]+" \];[ "JuliaInterface", ">='$relvers'" ];' pkg/JuliaExperimental/PackageInfo.g
perl -pi -e 's;\[ "JuliaInterface", ">=[^"]+" \];[ "JuliaInterface", ">='$relvers'" ];' lib/systemfile.g

# commit it
git commit -m "Version $relvers" Project.toml pkg/Julia*/PackageInfo.g lib/systemfile.g
