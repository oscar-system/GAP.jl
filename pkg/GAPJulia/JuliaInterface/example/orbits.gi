LoadPackage( "JuliaInterface" );

bahn := function( element, generators, action )
  local orb, dict, b, g, c;
  orb := [ element ];
  dict := NewDictionary(element, true);
  AddDictionary(dict, element, 1);
  for b in orb do
    for g in generators do
      c := action(b, g);
      if not KnowsDictionary(dict, c) then
        Add(orb, c);
        AddDictionary(dict, c, Length(orb));
      fi;
    od;
  od;
  return orb;
end;

example_dirs := DirectoriesPackageLibrary( "JuliaInterface", "example" );
JuliaIncludeFile( Filename( example_dirs, "orbits.jl" ) );

bahn_jl := JuliaFunction( "bahn" );

grp := SymmetricGroup( 10000 );
gens := GeneratorsOfGroup( grp );;

bahn(1, gens, OnPoints);;time;
bahn_jl(1, gens, OnPoints);;time;
