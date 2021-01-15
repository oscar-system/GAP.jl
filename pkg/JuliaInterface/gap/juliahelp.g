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
      local orig_topic, start, module, pos, sub, func, res;

      # Access the original (case sensitive) search string.
      # Note that `HELP` has turned `topic` to lowercase,
      # and has removed the prefix that specifies the help book.
      orig_topic:= ValueOption( "HELP_TOPIC" );
      if not IsString( orig_topic ) then
        # GAP's `HELP` has not set the option,
        # we are using a too old GAP version.
        return [ [], [] ];
      fi;

      # `orig_topic` is case sensitive,
      # and it includes the given `<book>:` prefix.
      # We accept the search string only if `Julia:` occurs.
      start:= PositionSublist( orig_topic, "Julia:" );
      if start = fail then
        return [ [], [] ];
      fi;
      orig_topic:= orig_topic{ [ start + 6 .. Length( orig_topic ) ] };

      # `orig_topic` may have a prefix that describes a (nested) Julia module.
      module:= Julia;
      start:= 1;
      for pos in Positions( orig_topic, '.' ) do
        sub:= orig_topic{ [ start .. pos-1 ] };
        if not IsBound( module.( sub ) ) then
          return [ [], [] ];
        fi;
        module:= module.( sub );
        if not IsJuliaModule( module ) then
          return [ [], [] ];
        fi;
        start:= pos + 1;
      od;
      func:= orig_topic{ [ start .. Length( orig_topic ) ] };
      if not IsBound( module.( func ) ) then
        # Give up.
        return [ [], [] ];
      fi;
      
      res:= JuliaToGAP( IsString,
                Julia.GAP.julia_help_string( module.( func ) ) );

      # Store the information such that `HelpData` will find it.
      HELP_BOOKS_INFO.julia.entries:= [ [ orig_topic, res ] ];
      HELP_BOOKS_INFO.julia.topic:= orig_topic;

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

