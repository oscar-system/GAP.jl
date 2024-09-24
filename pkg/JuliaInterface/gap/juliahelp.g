#! @BeginChunk JuliaHelpInGAP
#! @Chapter Using &Julia; from &GAP;
#! @Section Access &Julia; help from a &GAP; session
#!  In a &Julia; session, one can ask for help about the object with the name
#!  <C>obj</C> (a function or a type) by entering <C>?obj</C>,
#!  and &Julia; prints all matches to the screen.
#!  One can get the same output in a &GAP; session by entering
#!  <C>?Julia:obj</C>,
#!  cf. Section <Ref Sect="Invoking the Help" BookName="ref"/>
#!  in the &GAP; Reference Manual.
#!  For example, <C>?Julia:sqrt</C> shows the &Julia; help about the
#!  &Julia; function <C>sqrt</C>
#!  (which is available in &GAP; as <C>Julia.sqrt</C>).
#!  <P/>
#!  Note that this way to access the &Julia; help is different from the usual
#!  access to &GAP; help books, in the following sense.
#!  <List>
#!  <Item>
#!   The qualifying prefix <C>Julia:</C> is mandatory.
#!   Thus the help request <C>?sqrt</C> will show matches from usual
#!   &GAP; help books (there is one match in the &GAP; Reference Manual),
#!   but not the help about the &Julia; function <C>sqrt</C>.
#!  </Item>
#!  <Item>
#!   Since the prefix <C>Julia:</C> does not belong to a <Q>preprocessed</Q>
#!   help book with chapters, sections, index, etc.,
#!   help requests of the kinds
#!   <C>?&lt;</C>, <C>?&lt;&lt;</C>, <C>?&gt;</C>, <C>?&gt;&gt;</C>
#!   are not meaningful when the previous help request had the prefix
#!   <C>?Julia:</C>.
#!   (Also requests with the prefix <C>??Julia:</C> do not work,
#!   but this holds also for usual &GAP; help books.)
#!  </Item>
#!  <Item>
#!   The &Julia; help system is case sensitive.
#!   Thus <C>?Julia:sqrt</C> yields a match but <C>?Julia:Sqrt</C> does not,
#!   and <C>?Julia:Set</C> yields a match but <C>?Julia:set</C> does not.
#!  </Item>
#!  <Item>
#!   The &Julia; help system does currently not support menus
#!   in case of multiple matches, all matches are shown at once,
#!   and this happens also in a &GAP; session.
#!  </Item>
#!  <Item>
#!   No PDF or HTML version of the &Julia; help is supported in &GAP;,
#!   only the text format can be shown on the screen.
#!   Thus it does not make sense to change the help viewer,
#!   cf. Section <Ref Sect="Changing the Help Viewer" BookName="ref"/>
#!   in the &GAP; Reference Manual.
#!  </Item>
#!  <Item>
#!   &Julia; functions belong to &Julia; modules.
#!   Many &Julia; functions can be accessed only relative to their modules,
#!   and then also the help requests work only for the qualified names.
#!   For example, <C>?Julia:GAP.wrap_rng</C> yields the description
#!   of the &Julia; function <C>wrap_rng</C> that is defined in the
#!   &Julia; module <C>GAP</C>,
#!   whereas no match is found for the input <C>?Julia:wrap_rng</C>.
#!  </Item>
#!  </List>
#! @EndChunk

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

    ShowChapters:= book -> [ "" ],  # This feature is not supported for Julia.
#T In GAP 4.11.0, PAGER_BUILTIN would run into an error when called with an empty list.

    ShowSections:= book -> [ "" ],   # This feature is not supported for Julia.

    MatchPrevChap:= { info, i } -> [ , fail ],   # This feature is not supported for Julia.

    MatchNextChap:= { info, i } -> [ , fail ],   # This feature is not supported for Julia.

    MatchPrev:= { info, i } -> [ , fail ],   # This feature is not supported for Julia.

    MatchNext:= { info, i } -> [ , fail ],   # This feature is not supported for Julia.

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
      func:= Julia.GAP.UnwrapJuliaFunc( module.( func ) );
      res:= JuliaToGAP( IsString, Julia.GAP.julia_help_string( func ) );

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

