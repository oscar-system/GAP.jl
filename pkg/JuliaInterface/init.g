#
# JuliaInterface: Test interface to julia
#
# Reading the declaration part of the package.
#

#! @BeginChunk IncludeJuliaStartupFile
#!  <Subsection Label="subsect:IncludeJuliaStartupFile">
#!  <Heading>User preference <C>IncludeJuliaStartupFile</C></Heading>
#!  <Index Key="IncludeJuliaStartupFile"><C>IncludeJuliaStartupFile</C></Index>
#!
#!  When one starts an interactive &Julia; session,
#!  the &Julia; startup file <F>~/.julia/config/startup.jl</F> gets
#!  included automatically by default,
#!  see <URL><Link>https://docs.julialang.org/en/v1/stdlib/REPL</Link>
#!  <LinkText>the section <Q>The Julia REPL</Q> in the &Julia; documentation</LinkText></URL>.
#!  Hence the effects of this inclusion can be used in a &GAP; session
#!  which one gets via the following input.
#!  <Listing Type="Julia">using GAP; GAP.prompt()</Listing>
#!  <P/>
#!  However,
#!  this &Julia; startup file is <E>not</E> included into &Julia; by default
#!  when &GAP; gets started via the <F>gap.sh</F> script that is created
#!  during the installation of &GAP; (controlled by &Julia;).
#!  <P/>
#!  The user preference <C>IncludeJuliaStartupFile</C> can be used to
#!  force that the startup file gets included also in the latter situation,
#!  as follows.
#!  <P/>
#!  If the value is <K>true</K> then the file
#!  <F>~/.julia/config/startup.jl</F>
#!  gets included into &Julia; after startup.
#!  If the value is a nonempty string that is the name of a directory
#!  then the <F>startup.jl</F> file in this directory gets included into
#!  &Julia;.
#!  Otherwise (this is the default) no <F>startup.jl</F> file will be
#!  included automatically.
#!  </Subsection>
#! @EndChunk IncludeJuliaStartupFile
##
DeclareUserPreference( rec(
    package:= "JuliaInterface",
    name:= "IncludeJuliaStartupFile",
    description:= [
      "If the value is 'true' then the file '~/.julia/config/startup.jl'",
      "gets included into Julia after startup.",
      "If the value is a nonempty string that is the name of a directory",
      "then the 'startup.jl' file in this directory gets imported into",
      "Julia.",
      "Otherwise no 'startup.jl' file will be imported automatically,",
      "since apparently 'libjulia' does not import such a file.",
    ],
    default:= "",
    ) );


_PATH_SO:=Filename(DirectoriesPackagePrograms("JuliaInterface"), "JuliaInterface.so");
if _PATH_SO <> fail then
    LoadDynamicModule(_PATH_SO);
fi;
Unbind(_PATH_SO);


##
##  Import the 'startup.jl' file if wanted.
##
CallFuncList( function()
    local dir, filename, res;

    if JuliaEvalString( "Int64(Base.JLOptions().startupfile)" ) <> 2 then
      # Julia has already read the file, do not read it again.
      return;
    fi;

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

ReadPackage( "JuliaInterface", "gap/convert.gd" );
