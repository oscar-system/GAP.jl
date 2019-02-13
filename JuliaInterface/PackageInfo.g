#
# JuliaInterface: Test interface to julia
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "JuliaInterface",
Subtitle := "Test interface to julia",
Version := "0.2",
Date := "09/05/2017", # dd/mm/yyyy format

Persons := [
  rec(
    IsAuthor := true,
    IsMaintainer := true,
    FirstNames := "Sebastian",
    LastName := "Gutsche",
    WWWHome := "http://TODO",
    Email := "gutsche@mathematik.uni-siegen.de",
    PostalAddress := "TODO",
    Place := "Siegen",
    Institution := "University of Siegen",
  ),
  rec(
    LastName      := "Horn",
    FirstNames    := "Max",
    IsAuthor      := true,
    IsMaintainer  := true,
    Email         := "max.horn@math.uni-giessen.de",
    WWWHome       := "https://www.quendi.de/math",
    PostalAddress := Concatenation(
                       "AG Algebra\n",
                       "Mathematisches Institut\n",
                       "Justus-Liebig-Universität Gießen\n",
                       "Arndtstraße 2\n",
                       "35392 Gießen\n",
                       "Germany" ),
    Place         := "Gießen",
    Institution   := "Justus-Liebig-Universität Gießen"
  ),
],

PackageWWWHome := "http://TODO/",

ArchiveURL     := Concatenation( ~.PackageWWWHome, "JuliaInterface-", ~.Version ),
README_URL     := Concatenation( ~.PackageWWWHome, "README" ),
PackageInfoURL := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),

ArchiveFormats := ".tar.gz",

##  Status information. Currently the following cases are recognized:
##    "accepted"      for successfully refereed packages
##    "submitted"     for packages submitted for the refereeing
##    "deposited"     for packages for which the GAP developers agreed
##                    to distribute them with the core GAP system
##    "dev"           for development versions of packages
##    "other"         for all other packages
##
Status := "dev",

AbstractHTML   :=  "",

PackageDoc := [ rec(
  BookName  := "JuliaInterface",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Test interface to julia",
) ],

Dependencies := rec(
  GAP := ">= 4.10",    # need support for the component 'BannerFunction'
  NeededOtherPackages := [ ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := function()
  if Filename( DirectoriesPackagePrograms( "JuliaInterface" ),
               "JuliaInterface.so" ) = fail then
    LogPackageLoadingMessage( PACKAGE_WARNING,
        [ "The kernel module of JuliaInterface is not available." ] );
    return false;
  fi;
  return true;
end,

# Show the julia version number in the banner string.
# (We assume that this function gets called *after* the package has been
# loaded, in particular after Julia has been started.)
BannerFunction := function( info )
  local str, version;

  str:= DefaultPackageBannerString( info );
  if not IsBoundGlobal( "JuliaEvalString" ) then
    return str;
  fi;
  version:= ValueGlobal( "JuliaEvalString" )( "string( VERSION )" );
  if not IsBoundGlobal( "JuliaToGAP" ) then
    return str;
  fi;
  version:= ValueGlobal( "JuliaToGAP" )( IsString, version );

  return ReplacedString( str, "Homepage",
             Concatenation( "(julia version is ", version, ")\nHomepage" ) );
end,

TestFile := "tst/testall.g",

#Keywords := [ "TODO" ],

));

