#
# JuliaInterface: Test interface to julia
#
# Reading the declaration part of the package.
#

##
##  If the value is <K>true</K> then the file <F>~/.juliarc.jl</F>
##  gets imported into &Julia; after startup.
##  If the value is a nonempty string that is the name of a directory
##  then the <F>.juliarc.jl</F> file in this directory gets imported into
##  &Julia;.
##  Otherwise no <F>.juliarc.jl</F> file will be imported automatically,
##  since <C>libjulia</C> does not import such a file.
##
DeclareUserPreference( rec(
    package:= "JuliaInterface",
    name:= "IncludeJuliarcFile",
    description:= [
      "If the value is 'true' then the file '~/.juliarc.jl'",
      "gets imported into Julia after startup.",
      "If the value is a nonempty string that is the name of a directory",
      "then the '.juliarc.jl' file in this directory gets imported into",
      "Julia.",
      "Otherwise no '.juliarc.jl' file will be imported automatically,",
      "since 'libjulia' does not import such a file.",
    ],
    default:= "",
    ) );


ReadPackage( "JuliaInterface", "gap/JuliaTypeDeclarations.gd");

_PATH_SO:=Filename(DirectoriesPackagePrograms("JuliaInterface"), "JuliaInterface.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);


##
##  Import the 'juliarc.jl' file if wanted.
##
CallFuncList( function()
    local dotjuliarcdir, filename, res;

    dotjuliarcdir:= UserPreference( "JuliaInterface", "IncludeJuliarcFile" );
    if dotjuliarcdir = true then
      filename:= Filename( DirectoryHome(), ".juliarc.jl" );
    elif IsString( dotjuliarcdir ) and dotjuliarcdir <> "" then
      filename:= Filename( Directory( dotjuliarcdir ), ".juliarc.jl" );
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
