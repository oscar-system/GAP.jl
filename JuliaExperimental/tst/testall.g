#
# JuliaExperimental: Experimental code for the GAP Julia integration
#
# This file runs package tests. It is also referenced in the package
# metadata in PackageInfo.g.
#
LoadPackage( "JuliaExperimental" );

dirs := DirectoriesPackageLibrary( "JuliaExperimental", "tst" );

HasSuffix := function(list, suffix)
  local len;
  len := Length(list);
  if Length(list) < Length(suffix) then return false; fi;
  return list{[len-Length(suffix)+1..len]} = suffix;
end;

# Load all tests in that directory
tests := DirectoryContents(dirs[1]);
tests := Filtered(tests, name -> HasSuffix(name, ".tst"));
Sort(tests);

# Convert tests to filenames
tests := List(tests, test -> Filename(dirs,test));

# Run the tests
for test in tests do
    Print("Running test '",test,"'\n");
    if Test(test, rec(compareFunction := "uptowhitespace")) then
        Print("Test '",test,"' succeeded\n");
    else
        Print("Test '",test,"' failed\n");
    fi;
od;

