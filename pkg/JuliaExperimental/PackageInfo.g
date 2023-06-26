#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file contains package meta data. For additional information on
# the meaning and correct usage of these fields, please consult the
# manual of the "Example" package as well as the comments in its
# PackageInfo.g file.
#
SetPackageInfo( rec(

PackageName := "JuliaExperimental",
Subtitle := "Experimental code for the GAP Julia integration",
Version := "0.9.7",
Date := "26/06/2023", # dd/mm/yyyy format
License := "GPL-2.0-or-later",

Persons := [
  rec(
    IsAuthor := true,
    IsMaintainer := true,
    FirstNames := "Thomas",
    LastName := "Breuer",
    WWWHome := "http://www.math.rwth-aachen.de/~Thomas.Breuer",
    Email := "sam@math.rwth-aachen.de",
    PostalAddress := Concatenation(
               "Thomas Breuer\n",
               "Lehrstuhl D für Mathematik\n",
               "Pontdriesch 14/16\n",
               "52062 Aachen\n",
               "Germany" ),
    Place := "Aachen",
    Institution := "Lehrstuhl D für Mathematik, RWTH Aachen",
  ),
  rec(
    IsAuthor := true,
    IsMaintainer := true,
    FirstNames := "Sebastian",
    LastName := "Gutsche",
    WWWHome := "https://sebasguts.github.io",
    Email := "gutsche@mathematik.uni-siegen.de",
    PostalAddress := Concatenation(
               "Department Mathematik\n",
               "Universität Siegen\n",
               "Walter-Flex-Straße 3\n",
               "57068 Siegen\n",
               "Germany" ),
    Place := "Siegen",
    Institution := "University of Siegen",
  ),
],

PackageWWWHome := "https://github.com/oscar-system/GAP.jl",

ArchiveURL     := Concatenation( ~.PackageWWWHome, "JuliaExperimental-", ~.Version ),
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

PackageDoc := rec(
  BookName  := "JuliaExperimental",
  ArchiveURLSubset := ["doc"],
  HTMLStart := "doc/chap0.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Experimental code for the GAP Julia integration",
),

Dependencies := rec(
  GAP := ">= 4.11",
  NeededOtherPackages := [ ],
  OtherPackagesLoadedInAdvance := [ [ "JuliaInterface", ">=0.9.7" ] ], 
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := ReturnTrue,

TestFile := "tst/testall.g",

));


