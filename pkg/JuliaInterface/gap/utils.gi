#############################################################################
##
##  JuliaInterface package
##
#############################################################################

## Create a record from key value lists
BindGlobal( "CreateRecFromKeyValuePairList",
  function( keys, vals )
    local return_rec, i;
    return_rec := rec();
    for i in [1 .. Length( keys ) ] do
        return_rec.(keys[i]) := vals[i];
    od;
    return return_rec;
end );

BindGlobal( "StringDisplayObj",
function(obj)
  local str, out;
  str := "";
  out := OutputTextString(str, false);
  SetPrintFormattingStatus(out, false);
  STREAM_CALL(out, Display, obj);
  CloseStream(out);
  return str;
end );

BindGlobal( "StringViewObj",
function(obj)
  local str, out;
  str := "";
  out := OutputTextString(str, false);
  SetPrintFormattingStatus(out, false);
  STREAM_CALL(out, ViewObj, obj);
  CloseStream(out);
  return str;
end );

##  Compute the URLs of matching manual entries in the current &GAP;
##  online manuals.
##  (This should eventually be moved to the GAP help system.)
##
##  <A>str</A> must be a string of the form <C>label</C> or
##  <C>pkgname:label</C>,
##  for example <C>ref:Size</C> or <C>atlasrep:InfoAtlasRep</C>.
##
##  <A>prefix</A>, if given, must be the URL of a directory containing the
##  HTML versions of &GAP; manuals.
##
BindGlobal( "MatchURLs", function(str, prefix...)
  local pref, p, book, books, matches, urls, u, r;

  # check for given prefix
  if Length(prefix) > 0 then
    pref := prefix[1];
  else
    pref := false;
  fi;

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
  if Length(books) = 0 then return []; fi;

  # matches[1] are exact matches, and matches[2] further ones
  if Length(str) > 0 and str[1] = '?' then
      matches := HELP_GET_MATCHES(books, str{[2..Length(str)]}, false);
  else
      matches := HELP_GET_MATCHES(books, str, true);
  fi;

  # evaluate "url"s for all matches
  urls := List(Concatenation(matches), a->
              [a[1].bookname, StripEscapeSequences(a[1].entries[a[2]][1]),
               HELP_BOOK_HANDLER.(a[1].handler).HelpData(a[1], a[2], "url")]);

  # substitute GAP roots by prefix
  if pref <> false then
    for u in urls do
      if IsString(u[3]) then
        for r in GAPInfo.RootPaths do
          if PositionSublist(u[3], r) = 1 then
            u[3] := Concatenation(pref, u[3]{[Length(r)+1..Length(u[3])]});
          fi;
        od;
      fi;
    od;
  fi;

  return urls;
end );
