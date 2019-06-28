#############################################################################
##  
##  copied from GAP's 'lib/helpbase.gi', then adjusted
##
##  The aim of these functions is to collect the information printed by
##  GAP's HELP function in a string instead of printing it to the screen.
##  In particular, if several matches are found then their help strings
##  are concatenated.
##


#############################################################################
##  
#F  HELP_DESC_BOOKS( ignored... ) . . . . . . . . . . .  show available books
##  
BindGlobal( "HELP_DESC_BOOKS", function( arg )
  local books;

  books := ["             Table of currently available help books",
            FILLED_LINE( "short name for ? commands", "Description", '_')];
  Append(books, List(HELP_KNOWN_BOOKS[2], a-> FILLED_LINE(a[1], a[2], ' ')));
  return [ true, books ];
end);

#############################################################################
##
#F  HELP_DESC_CHAPTERS( <book> )  . . . . . . . . . . . . . show all chapters
##
BindGlobal( "HELP_DESC_CHAPTERS", function(book)
  local info;
  # delegate to handler 
  info := HELP_BOOK_INFO(book);
  if info = fail then
    return [ true, [ Concatenation( "#W Help: Book ", book, " not found." ) ] ];
  else
    HELP_LAST.BOOK := book;
    HELP_LAST.MATCH := 1;
    # The second entry can be a string or a list of strings
    # or a record with the components 'lines' and 'start'.
    return [ true, HELP_BOOK_HANDLER.(info.handler).ShowChapters(info) ];
  fi;
end);

#############################################################################
##
#F  HELP_DESC_SECTIONS( <book> )  . . . . . . . . . . . . . show all sections
##
BindGlobal( "HELP_DESC_SECTIONS", function(book)
  local info;
  # delegate to handler 
  info := HELP_BOOK_INFO(book);
  if info = fail then
    return [ true, [ Concatenation( "#W Help: Book ", book, " not found." ) ] ];
  else
    HELP_LAST.BOOK := book;
    HELP_LAST.MATCH := 1;
    # The second entry can be a string or a list of strings
    # or a record with the components 'lines' and 'start'.
    return [ true, HELP_BOOK_HANDLER.(info.handler).ShowSections(info) ];
  fi;
end);

#############################################################################
##  
#F  HELP_DESC_MATCH( <match> )  . . . . . . the core function which finally
##  gets the data for displaying the help it
##
##  <match> is [book, entrynr]
##
BindGlobal( "HELP_DESC_MATCH", function(match)
  local book, entrynr, viewer, hv, pos, type, data,
        nextn, nextentry, firstline, lastline, lines;

  book := HELP_BOOK_INFO(match[1]);
  entrynr := match[2];
# viewer:= UserPreference("HelpViewers");
  viewer:= [ "screen" ];
  if HELP_LAST.NEXT_VIEWER = false then
    hv := viewer;
  else
    pos := Position( viewer, HELP_LAST.VIEWER );
    if pos = fail then
      hv := viewer;
    else
      hv := viewer{Concatenation([pos+1..Length(viewer)],[1..pos])};
    fi;
    HELP_LAST.NEXT_VIEWER := false;
  fi;
  data:= fail;
  for viewer in hv do
    # type of data we need now depends on help viewer 
    type := HELP_VIEWER_INFO.(viewer).type;
    # get the data via appropriate handler
    data := HELP_BOOK_HANDLER.(book.handler).HelpData(book, entrynr, type);
    if data <> fail then
      # Find the end of the subsection in question.
      # This is defined either by the start of the next subsection
      # of the same section, or by the start of the next section or chapter.
      nextn:= book.entries[ entrynr ][3] + [ ,, 1 ];
      nextentry:= PositionProperty( book.entries, x -> x[3] = nextn );
      if nextentry = fail then
        nextn:= nextn + [ , 1, -nextn[3] ];
        nextentry:= PositionProperty( book.entries, x -> x[3] = nextn );
      fi;
      if IsBound( data.start ) then
        firstline:= data.start;
      else
        # Perhaps the '.txt' file is not available.
        firstline:= 1;
      fi;
      if nextentry = fail then
        lastline:= fail;
      else
        # Just taking 'book.entries[ nextentry ][4]' as the startline
        # would not be correct.
        lastline:= HELP_BOOK_HANDLER.( book.handler ).HelpData( book,
                       nextentry, type );
        if IsBound( lastline.start ) then
          lastline:= lastline.start - 1;
        else
          lastline:= fail;
        fi;
      fi;
      break;
    fi;
    HELP_LAST.VIEWER := viewer;
  od;
  HELP_LAST.BOOK := book;
  HELP_LAST.MATCH := entrynr;
  HELP_LAST.VIEWER := viewer;
  if data <> fail then
    if IsString( data.lines ) then
      # GAPDoc format manuals
      lines:= SplitString( data.lines, "\n" );
    else
      # gapmacro.tex format manuals
      lines:= data.lines;
    fi;
    if lastline = fail then
      lastline:= Length( lines );
    fi;
    return [ true, lines{ [ firstline .. lastline ] } ];
  else
    return [ false, [] ];
  fi;
end);

#############################################################################
##  
#F  HELP_DESC_PREV_CHAPTER( <book> ) . . . . . . . . show chapter introduction
##  
BindGlobal( "HELP_DESC_PREV_CHAPTER", function( arg )
  local   info,  match;
  if HELP_LAST.BOOK = 0 then
    return [ true, [ "Help: no history so far." ] ];
  fi;
  info := HELP_BOOK_INFO(HELP_LAST.BOOK);
  match := HELP_BOOK_HANDLER.(info.handler).MatchPrevChap(info, 
                   HELP_LAST.MATCH);
  if match[2] = fail then
    return [ true, [ "Help:  no match found." ] ];
  else
    HELP_LAST.MATCH := match[2];
    return HELP_DESC_MATCH( match );
  fi;
end);

#############################################################################
##
#F  HELP_DESC_NEXT_CHAPTER( <book> )  . . . . . . . . . . . show next chapter
##
BindGlobal( "HELP_DESC_NEXT_CHAPTER", function( arg )
  local   info,  match;
  if HELP_LAST.BOOK = 0 then
    return [ true, [ "Help: no history so far." ] ];
  fi;
  info := HELP_BOOK_INFO(HELP_LAST.BOOK);
  match := HELP_BOOK_HANDLER.(info.handler).MatchNextChap(info, 
                   HELP_LAST.MATCH);
  if match[2] = fail then
    return [ true, [ "Help:  no match found." ] ];
  else
    HELP_LAST.MATCH := match[2];
    return HELP_DESC_MATCH( match );
  fi;
end);

#############################################################################
##
#F  HELP_DESC_PREV( <book> )  . . . . . . . . . . . . . show previous section
##
BindGlobal( "HELP_DESC_PREV", function( arg )
  local   info,  match;
  if HELP_LAST.BOOK = 0 then
    return [ true, [ "Help: no history so far." ] ];
  fi;
  info := HELP_BOOK_INFO(HELP_LAST.BOOK);
  match := HELP_BOOK_HANDLER.(info.handler).MatchPrev(info, 
                   HELP_LAST.MATCH);
  if match[2] = fail then
    return [ true, [ "Help:  no match found." ] ];
  else
    HELP_LAST.MATCH := match[2];
    return HELP_DESC_MATCH( match );
  fi;
end);

#############################################################################
##
#F  HELP_DESC_NEXT( <book> )  . . . . . . . . . . . . . . . show next section
##
BindGlobal( "HELP_DESC_NEXT", function( arg )
  local   info,  match;
  if HELP_LAST.BOOK = 0 then
    return [ true, [ "Help: no history so far." ] ];
  fi;
  info := HELP_BOOK_INFO(HELP_LAST.BOOK);
  match := HELP_BOOK_HANDLER.(info.handler).MatchNext(info, 
                   HELP_LAST.MATCH);
  if match[2] = fail then
    return [ true, [ "Help:  no match found." ] ];
  else
    HELP_LAST.MATCH := match[2];
    return HELP_DESC_MATCH( match );
  fi;
end);

#############################################################################
##
#F  HELP_DESC_WELCOME() . . . . . . . . . . . . . . . .  show welcome message
##
BindGlobal( "HELP_DESC_WELCOME", function()
    return [ true, [
"    Welcome to GAP 4\n",
" Try '?tutorial: The Help system' (without quotes) for an introduction to",
" the help system.",
"",
" '?chapters' and '?sections' will display tables of contents."
    ] ];
end);


#############################################################################
##
#F  HELP_GET_MATCHES2( <book>, <topic>, <frombegin> ) . . .  search through
#F  the books
##
##  This function returns a list of two lists [exact, match] and these lists
##  consist of  pairs [book,  entrynumber], where  book is  a help  book and
##  entrynumber is the number of a  match in book.entries. As the names say,
##  the  first list  "exact"  contains  the exact  matches  and "match"  the
##  remaining ones.
##
BindGlobal( "HELP_GET_MATCHES2", function( books, topic, frombegin )
  local exact, match, em, b, x, topics, transatl, pair, newtopic, getsecnum;

  # First we try to produce some suggestions for possible different spellings
  # (see the global variable 'TRANSATL' for the list of spelling patterns).
  if topic = "size" then # "size" is a notable exception (lowercase is guaranteed)
    topics:=[ topic ];
  else
    topics:=HELP_SEARCH_ALTERNATIVES( topic );
  fi;

  # <exact> and <match> contain the topics matching
  exact := [];
  match := [];

  if IsString(books) or IsRecord(books) then
    books := [books];
  fi;

  # collect the matches (by number)
  books := List(books, HELP_BOOK_INFO);
  for b in books do
    for topic in topics do
      # now delegate the work to the handler functions
      if b<>fail then
        em := HELP_BOOK_HANDLER.(b.handler).SearchMatches(b, topic, frombegin);
        for x in em[1] do
          Add(exact, [b, x]);
        od;
        for x in em[2] do
          Add(match, [b, x]);
        od;
      fi;
    od;
  od;

  # different from GAP's function:  Do *NOT* join the two lists.
  # match := Concatenation(exact, match);
  # exact := [];

  # check if all matches point to the same subsection of the same book,
  # in that case we only keep the first match which then will be displayed
  # immediately

  # this function makes sure that nothing breaks if the help book handler
  # has no support for SubsectionNumber
  getsecnum := function(m)
    if IsBound(HELP_BOOK_HANDLER.(m[1].handler).SubsectionNumber) then
      return HELP_BOOK_HANDLER.(m[1].handler).SubsectionNumber(m[1], m[2]);
    else
      return m[2];
    fi;
  end;
  if Length(match) > 1 and Length(Set(List(match,
                            m-> [m[1].bookname,getsecnum(m)]))) = 1 then
    match := [match[1]];
  fi;

  return [exact, match];
end);


#############################################################################
##
#F  HELP_DESC_MATCHES( <book>, <topic>, <frombegin> )  . . .  collect matches
##  
BindGlobal( "HELP_DESC_MATCHES", function( books, topic, frombegin, onlyexact... )
  local   exact,  match,  x,  lines,  cnt,  i,  str,  n, sep, known, desc;

  # first get lists of exact and other matches
  x := HELP_GET_MATCHES2( books, topic, frombegin );
  exact := x[1];
  if Length( onlyexact ) = 1 and onlyexact[1] = true then
    match:= [];
  else
    match:= x[2];
  fi;
  
  # no topic found
  if 0 = Length(match) and 0 = Length(exact)  then
    return [ false, [ "Help: no matching entry found" ] ];
    
#   # one exact or together one topic found
#   elif 1 = Length(exact) or (0 = Length(exact) and 1 = Length(match)) then
#     if Length(exact) = 0 then exact := match; fi;
#     i := exact[1];
#     str := Concatenation("Help: Showing `", i[1].bookname,": ", 
#                          StripEscapeSequences( i[1].entries[i[2]][1] ), "'");
#     # to avoid line breaking when str contains escape sequences:
#     n := 0;
#     lines:= [];
#     while n < Length(str) do
#       Add( lines, str{[n+1..Minimum(Length(str), 
#                                     n + QuoInt(SizeScreen()[1] ,2))]} );
#       n := n + QuoInt(SizeScreen()[1] ,2);
#     od;
#     return [ true, Concatenation( lines, HELP_DESC_MATCH(i)[2] ) ];
# 
#   # more than one topic found, show all entries
  else
    if 1 = Length(exact) or (0 = Length(exact) and 1 = Length(match)) then
      # one topic found
      lines:= [];
    else
      # more than one topic found, show all entries
      lines := [ "Help: several entries match this topic", "" ];
    fi;
    sep:= [ "", RepeatedUTF8String( "─", SizeScreen()[1] ), "" ];
    HELP_LAST.TOPICS:=[];
    # show exact matches first
    match := Concatenation(exact, match);
    known:= [];
    for i  in match  do
      desc:= HELP_DESC_MATCH(i)[2];
      if not desc in known then
        Add( lines, Concatenation( i[1].bookname, ":" ) );
        Append( lines, desc );
        Append( lines, sep );
        AddSet( known, desc );
      fi;
      Add(HELP_LAST.TOPICS, i);
    od;
    return [ true, lines ];
  fi;
end);


# choosing one of last shown  list of matches
BindGlobal( "HELP_DESC_FROM_LAST_TOPICS", function(nr)
  if nr = 0 or Length(HELP_LAST.TOPICS) < nr then
    return [ false, [ "Help:  No such topic." ] ];
  fi;
  return [ true, HELP_DESC_MATCH(HELP_LAST.TOPICS[nr])[2] ];
end);


#############################################################################
##  
#F  HELP_String( <string>, <onlyexact> ) . . . . . . deal with a help request
##  
##  The return value is a list.
##  Each of its entries is either a list of strings
##  or a record with the components 'lines' (a string or a list of strings)
##  and 'start' (the position of the first line to show).
##
DeclareGlobalFunction( "HELP_String" );

InstallGlobalFunction( HELP_String, function( str, onlyexact )
  local origstr, nwostr, p, book, books, move, add,
        match;

  origstr := ShallowCopy(str);
  nwostr := NormalizedWhitespace(origstr);
  
  # extract the book
  p := Position( str, ':' );
  if p <> fail  then
      book := str{[1..p-1]};
      str  := str{[p+1..Length(str)]};
  else
      book := "";
  fi;
  
  # normalizing for search
  book := SIMPLE_STRING(book);
  str := SIMPLE_STRING(str);
  
  # we check if `book' MATCH_BEGINs some of the available books
  books := Filtered(HELP_KNOWN_BOOKS[1], bn-> MATCH_BEGIN(bn, book));
  if Length(book) > 0 and Length(books) = 0 then
    return [ [ "Help: None of the available books matches (try: '?books')." ] ];
  fi;
  
  # function to add a topic to the ring
  move := false;
  add  := function( books, topic )
      if not move  then
          HELP_RING_IDX := (HELP_RING_IDX+1) mod HELP_RING_SIZE;
          HELP_BOOK_RING[HELP_RING_IDX+1]  := books;
          HELP_TOPIC_RING[HELP_RING_IDX+1] := topic;
      fi;
  end;
  
  # if the topic is empty show the last shown one again 
  if  book = "" and str = ""  then
       if HELP_LAST.BOOK = 0 then
         return HELP_String( "Tutorial: Help", onlyexact );
       else
         return [ HELP_DESC_MATCH( [HELP_LAST.BOOK, HELP_LAST.MATCH] )[2] ];
       fi;

  # if topic is "&" show last topic again, but with next viewer in viewer
  # list, or with last viewer again if there is no next one
  elif book = "" and str = "&" and Length(nwostr) = 1 then
       if HELP_LAST.BOOK = 0 then
         return HELP_String( "Tutorial: Help", onlyexact );
       else
         HELP_LAST.NEXT_VIEWER := true;
         return [ HELP_DESC_MATCH( [HELP_LAST.BOOK, HELP_LAST.MATCH] )[2] ];
       fi;
  
  # if the topic is '-' we are interested in the previous search again
  elif book = "" and str = "-" and Length(nwostr) = 1  then
      HELP_RING_IDX := (HELP_RING_IDX-1) mod HELP_RING_SIZE;
      books := HELP_BOOK_RING[HELP_RING_IDX+1];
      str  := HELP_TOPIC_RING[HELP_RING_IDX+1];
      move := true;

  # if the topic is '+' we are interested in the last section again
  elif book = "" and str = "+" and Length(nwostr) = 1  then
      HELP_RING_IDX := (HELP_RING_IDX+1) mod HELP_RING_SIZE;
      books := HELP_BOOK_RING[HELP_RING_IDX+1];
      str  := HELP_TOPIC_RING[HELP_RING_IDX+1];
      move := true;
  fi;
  
  # number means topic from HELP_LAST.TOPICS list
  if book = "" and ForAll(str, a-> a in "0123456789") then
      return [ HELP_DESC_FROM_LAST_TOPICS(Int(str))[2] ];
    
  # if the topic is '<' we are interested in the one before 'LastTopic'
  elif book = "" and str = "<" and Length(nwostr) = 1  then
      return [ HELP_DESC_PREV()[2] ];

  # if the topic is '>' we are interested in the one after 'LastTopic'
  elif book = "" and str = ">" and Length(nwostr) = 1  then
      return [ HELP_DESC_NEXT()[2] ];

  # if the topic is '<<' we are interested in the previous chapter intro
  elif book = "" and str = "<<"  then
      return [ HELP_DESC_PREV_CHAPTER()[2] ];

  # if the topic is '>>' we are interested in the next chapter intro
  elif book = "" and str = ">>"  then
      return [ HELP_DESC_NEXT_CHAPTER()[2] ];

  # if the subject is 'Welcome to GAP' display a welcome message
  elif book = "" and str = "welcome to gap"  then
      str:= HELP_DESC_WELCOME();
      if str[1] = true then
          add( books, "Welcome to GAP" );
      fi;
      return [ str[2] ];

  # if the topic is 'books' display the table of books
  elif book = "" and str = "books"  then
      str:= HELP_DESC_BOOKS();
      if str[1] = true then
          add( books, "books" );
      fi;
      return [ str[2] ];

  # if the topic is 'chapters' display the table of chapters
  elif str = "chapters"  or str = "contents" or book <> "" and str = "" then
      str:= List( books, HELP_DESC_CHAPTERS );
      if ForAll( str, b -> b[1] = true ) then
        add( books, "chapters" );
      fi;
      return List( str, x -> x[2] );

  # if the topic is 'sections' display the table of sections
  elif str = "sections"  then
      str:= List( books, HELP_DESC_SECTIONS );
      if ForAll( str, b -> b[1] = true ) then
        add(books, "sections");
      fi;
      return List( str, x -> x[2] );

  # if the topic is '?<string>' search the index for any entries for
  # which <string> is a substring (as opposed to an abbreviation)
  elif Length(str) > 0 and str[1] = '?'  then
      str := str{[2..Length(str)]};    
      NormalizeWhitespace(str);
      match:= HELP_DESC_MATCHES( books, str, false, onlyexact );
      if match[1] = true then
          add( books, str );
      fi;
      return [ match[2] ];

  # search for this topic
  else
    match:= HELP_DESC_MATCHES( books, str, true, onlyexact );
    if match[1] = true then
      add( books, str );
      return [ match[2] ];
    elif origstr in NAMES_SYSTEM_GVARS then
      return [ [ Concatenation( "Help: '", origstr, "' is currently undocumented." ),
               "      For details, try ?Undocumented Variables" ] ];
    elif book = "" and 
                 ForAny(HELP_KNOWN_BOOKS[1], bk -> MATCH_BEGIN(bk, str)) then
      return Concatenation( [ [ Concatenation(
          "Help: Are you looking for a certain book? (Trying '?", origstr, 
          ":' ...)" ) ] ],
          HELP_String( Concatenation( origstr, ":" ), onlyexact ) );
    else
      return [ match[2] ];
    fi;
  fi;
end);


#############################################################################
##  
#F  HelpString( <topic>[, <onlyexact>] )
##
BindGlobal( "HelpString", function( topic, onlyexact... )
    local res, entry, lines, start;

    onlyexact:= ( Length( onlyexact ) = 1 and onlyexact[1] = true );

    res:= "";
    for entry in HELP_String( topic, onlyexact ) do
      if IsRecord( entry ) then
        lines:= entry.lines;
        if IsString( lines ) then
          lines:= SplitString( lines, "\n" );
        fi;
        if IsBound( entry.start ) then
          start:= entry.start;
        else
          start:= 1;
        fi;
        Append( res, JoinStringsWithSeparator(
            lines{ [ start .. Length( lines ) ] },
            "\n" ) );
      elif IsList( entry ) and ForAll( entry, IsString ) then
        Append( res, JoinStringsWithSeparator( entry, "\n" ) );
      else
        Error( "<entry> must be a record or a list of strings" );
      fi;
    od;

    return res;
end );


