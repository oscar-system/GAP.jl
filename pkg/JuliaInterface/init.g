#
# JuliaInterface: Test interface to julia
#
# Reading the declaration part of the package.
#

##
##  If the value is <K>true</K> then the file
##  <F>~/.julia/config/startup.jl</F>
##  gets imported into &Julia; after startup.
##  If the value is a nonempty string that is the name of a directory
##  then the <F>startup.jl</F> file in this directory gets imported into
##  &Julia;.
##  Otherwise no <F>startup.jl</F> file will be imported automatically,
##  since apparently <C>libjulia</C> does not import such a file.
##
DeclareUserPreference( rec(
    package:= "JuliaInterface",
    name:= "IncludeJuliaStartupFile",
    description:= [
      "If the value is 'true' then the file '~/.julia/config/startup.jl'",
      "gets imported into Julia after startup.",
      "If the value is a nonempty string that is the name of a directory",
      "then the 'startup.jl' file in this directory gets imported into",
      "Julia.",
      "Otherwise no 'startup.jl' file will be imported automatically,",
      "since apparently 'libjulia' does not import such a file.",
    ],
    default:= "",
    ) );


ReadPackage( "JuliaInterface", "gap/JuliaTypeDeclarations.gd");

_PATH_SO:=Filename(DirectoriesPackagePrograms("JuliaInterface"), ".libs/JuliaInterface.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);


##
##  Import the 'startup.jl' file if wanted.
##
CallFuncList( function()
    local dir, filename, res;

    dir:= UserPreference( "JuliaInterface", "IncludeJuliaStartupFile" );
    if dir = true then
      filename:= Filename( DirectoryHome(), ".julia/config/startup.jl" );
    elif IsString( dir ) and dir <> "" then
      filename:= Filename( Directory( dir ), "startup.jl" );
    else
      return;
    fi;

    if IsReadableFile( filename ) then
      res:= JuliaEvalString(
                Concatenation( "try include( \"", filename, "\" ); ",
                    "; return true; catch e; return e; end" ) );
      if res = true then
        return;
      fi;
    fi;

    Info( InfoWarning, 1,
          "The file '", filename, "' cannot be included by Julia." );
    end, [] );


ReadPackage( "JuliaInterface", "gap/JuliaInterface.gd");

ReadPackage( "JuliaInterface", "gap/BindCFunction.gd" );

ReadPackage( "JuliaInterface", "gap/convert.gd" );
