LoadPackage( "JuliaInterface" );

bahn := function( element, generators, action )
  local return_set, work_set, current_element, current_generator, current_result;
    work_set := [ element ];
    return_set := [ element ];
    while not IsEmpty( work_set ) do
        current_element := Remove( work_set );
        for current_generator in generators do
            current_result := action( current_element, current_generator );
            if not ForAny( return_set, i -> i = current_result ) then
                Add( work_set, current_result );
                Add( return_set, current_result );
            fi;
        od;
    od;
    return return_set;
end;

example_dirs := DirectoriesPackageLibrary( "JuliaInterface", "example" );
JuliaIncludeFile( Filename( example_dirs, "orbits.jl" ) );

JuliaBindCFunction( "bahn", "bahn_jl", 3, "elem,gens,oper" );
