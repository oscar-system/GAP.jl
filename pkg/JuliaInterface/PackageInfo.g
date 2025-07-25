#############################################################################
##
##  This file is part of GAP.jl, a bidirectional interface between Julia and
##  the GAP computer algebra system.
##
##  Copyright of GAP.jl and its parts belongs to its developers.
##  Please refer to its README.md file for details.
##
##  SPDX-License-Identifier: LGPL-3.0-or-later
##
##  This file contains package meta data. For additional information on the
##  meaning and correct usage of these fields, please consult the manual of
##  the "Example" package as well as the comments in its PackageInfo.g file.
##
#############################################################################

SetPackageInfo( rec(

PackageName := "JuliaInterface",
Subtitle := "Interface to Julia",
Version := "0.15.0-DEV",
Date := "14/07/2025", # dd/mm/yyyy format
License := "LGPL-3.0-or-later",

Persons := [
  rec(
    LastName := "Breuer",
    FirstNames := "Thomas",
    IsAuthor := true,
    IsMaintainer := true,
    Email := "sam@math.rwth-aachen.de",
    WWWHome := "https://www.math.rwth-aachen.de/~Thomas.Breuer",
    PostalAddress := Concatenation(
                       "Thomas Breuer\n",
                       "Lehrstuhl für Algebra und Zahlentheorie\n",
                       "RWTH Aachen\n",
                       "Pontdriesch 14/16\n",
                       "52062 Aachen\n",
                       "Germany" ),
    Place := "Aachen",
    Institution := "RWTH Aachen",
  ),
  rec(
    IsAuthor := true,
    IsMaintainer := false,
    FirstNames := "Sebastian",
    LastName := "Gutsche",
    WWWHome := "https://sebasguts.github.io",
    Email := "gutsche@mathematik.uni-siegen.de",
    PostalAddress := Concatenation(
                       "Department Mathematik\n",
                       "Universität Siegen\n",
                       "Walter-Flex-Straße 3\n",
                       "57072 Siegen\n",
                       "Germany" ),
    Place := "Siegen",
    Institution := "University of Siegen",
  ),
  rec(
    LastName := "Horn",
    FirstNames := "Max",
    IsAuthor := true,
    IsMaintainer := true,
    Email := "mhorn@rptu.de",
    WWWHome := "https://www.quendi.de/math",
    PostalAddress := Concatenation(
                       "Fachbereich Mathematik\n",
                       "RPTU Kaiserslautern-Landau\n",
                       "Gottlieb-Daimler-Straße 48\n",
                       "67663 Kaiserslautern\n",
                       "Germany" ),
    Place := "Kaiserslautern, Germany",
    Institution := "RPTU Kaiserslautern-Landau",
  ),
],

SourceRepository := rec( Type := "git", URL := "https://github.com/oscar-system/GAP.jl" ),
IssueTrackerURL := "https://github.com/oscar-system/GAP.jl",
PackageWWWHome := "https://github.com/oscar-system/GAP.jl/issues",

ArchiveURL     := Concatenation( ~.PackageWWWHome, "JuliaInterface-", ~.Version ),
PackageInfoURL := Concatenation( ~.PackageWWWHome, "PackageInfo.g" ),
README_URL     := Concatenation( ~.PackageWWWHome, "README.md" ),

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
  HTMLStart := "doc/chap0_mj.html",
  PDFFile   := "doc/manual.pdf",
  SixFile   := "doc/manual.six",
  LongTitle := "Interface to &Julia;",
) ],

Dependencies := rec(
  GAP := ">= 4.11",    # need compatible code in GAP's src/julia_gc.c
  NeededOtherPackages := [ ],
  SuggestedOtherPackages := [ ],
  ExternalConditions := [ ],
),

AvailabilityTest := ReturnTrue,

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

Keywords := [ "GAP-Julia integration", "Julia", "Interface" ],

AutoDoc := rec(
  TitlePage := rec(
    Abstract := Concatenation(
      "The &GAP; package <Package>JuliaInterface</Package> is part of ",
      "a bidirectional interface between &GAP; and &Julia;.\n"
    ),
    Acknowledgements := Concatenation(
      "The development of this &GAP; package has been supported ",
      "by the German Research Foundation (DFG) within the ",
      "<URL><Link>https://www.computeralgebra.de/sfb/</Link>",
      "<LinkText>Collaborative Research Center TRR 195 ",
      "<Q>Symbolic Tools in Mathematics and their Applications</Q>",
      "</LinkText></URL> (from 2017 until 2028).\n",
      "<P/>\n"
    ),
    Copyright := """
      &copyright; 2017-2025 The OSCAR team<P/>

      <Package>JuliaInterface</Package> and <Package>GAP.jl</Package> are free
      software: you can redistribute them and/or modify them under the terms
      of the GNU Lesser General Public License as published by the Free
      Software Foundation, either version 3 of the License, or (at your
      option) any later version. <P/>

      <Package>JuliaInterface</Package> and <Package>GAP.jl</Package> are
      distributed in the hope that they will be useful, but WITHOUT ANY
      WARRANTY; without even the implied warranty of MERCHANTABILITY or
      FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
      License for more details. <P/>

      For a copy of the GNU Lesser General Public License, see the file
      <F>LICENSE</F> included with this software, or see
      <URL>https://www.gnu.org/licenses/lgpl.html</URL>.
      """,
  ),
),
));
