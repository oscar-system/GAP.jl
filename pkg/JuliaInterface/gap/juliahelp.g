##  Make the Julia help available in the GAP session,
##  via a (virtual) help book called `Julia`,
##  which uses a custom handler called `juliahelpformat`.
##  This works only for the `"text"` help in the terminal,
##  we cannot access PDF and HTML formats.
##
##  The idea is to enter `?Julia:sqrt` or `?Base.isdefined`,
##  to get one entry for the book `Julia` in the list of choices
##  if Julia knows documentation for the topic,
##  and to show *all* matching docstrings from Julia when this entry
##  is chosen from the menu (since this is the way how Julia behaves).

HELP_ADD_BOOK( "Julia", "dummy entry for accessing Julia documentation",
    DirectoriesPackageLibrary( "JuliaInterface", "help" )[1] );

HELP_BOOK_HANDLER.juliahelpformat:= rec(
    # see "The Help Book Handler"
    ReadSix:= stream -> rec( bookname:= "Julia", entries:= [] ),

    ShowChapters:= book -> "",  # This feature is not supported for Julia.

    ShowSection:= book -> "",   # This feature is not supported for Julia.

    SearchMatches:= function( book, topic, frombegin )
      local module, start, pos, sub, func, res;

      # `topic` may contain a prefix that describes a Julia module.
      module:= Julia;
      start:= 1;
      for pos in Positions( topic, '.' ) do
        sub:= topic{ [ start .. pos-1 ] };
        # hack:
        # 'topic' was turned to lowercase in 'HELP' (by 'SIMPLE_STRING')
        # but module names involve uppercase letters.
        if sub = "gap" then
          sub:= "GAP";
        else
          sub[1]:= UppercaseChar( sub[1] );
        fi;
        if not IsBound( module.( sub ) ) then
          return [ [], [] ];
        fi;
        module:= module.( sub );
        if not IsJuliaModule( module ) then
          return [ [], [] ];
        fi;
        start:= pos + 1;
      od;
      func:= topic{ [ start .. Length( topic ) ] };
      if not IsBound( module.( func ) ) then
        # Give up.
        return [ [], [] ];
      fi;
      
      res:= JuliaToGAP( IsString,
                Julia.GAP.julia_help_string( module.( func ) ) );

      # Store the information such that `HelpData` will find it.
      HELP_BOOKS_INFO.julia.entries:= [ [ topic, res ] ];
      HELP_BOOKS_INFO.julia.topic:= topic;

      # Return the result, meaning that there is one (non-exact) match
      # at position 1, which has been set in the `entries` list.
      return [ [], [ 1 ] ];
    end,

    HelpData:= function( book, entrynr, type )
      local res;

      if type <> "text" then
        # We cannot access PDF and HTML versions of the Julia documentation.
        return fail;
      elif not IsBound( HELP_BOOKS_INFO.julia.topic ) then
        # We expect that the component has been bound by `SearchMatches`.
        return fail;
      fi;

      res:= HELP_BOOKS_INFO.julia.entries[1][2];
      return rec( formatted:= true, lines:= res, start:= 1 );
    end,
    );

