# Monkey patch the GAP tab completion code so we get nice TAB completion
# of members of the Julia record.
#
# This is code from https://github.com/gap-system/gap/pull/4667 and this hack
# should be removed once that PR is merged and contained in a GAP snapshot
# that we are using.
if IsBound(GAPInfo.CommandLineEditFunctions) then

GAPInfo.CommandLineEditFunctions.Functions.Completion := function(l)
    local cf, pos, word, wordplace, idbnd, i, cmps, r, searchlist, cand, c, j,
          completeFilter, completeExtender, extension, hasbang;

      completeFilter := function(filterlist, partial)
        local pref, lowpartial;
        pref := UserPreference("Autocompleter");
        if pref = "case-insensitive" then
          lowpartial := LowercaseString(partial);
          return Filtered(filterlist,
                          a -> PositionSublist(LowercaseString(a), lowpartial) = 1);
        elif pref = "default" then
          return Filtered(filterlist, a-> PositionSublist(a, partial) = 1);
        elif IsRecord(pref) and IsFunction(pref.completer) then
          return pref.completer(filterlist, partial);
        else
          ErrorNoReturn("Invalid setting of UserPreference 'Autocompleter'");
        fi;
    end;

    completeExtender := function(filterlist, partial)
      local pref;
      pref := UserPreference("Autocompleter");
      if pref = "case-insensitive" then
        return STANDARD_EXTENDERS.caseInsensitive(filterlist, partial);
      elif pref = "default" then
        return STANDARD_EXTENDERS.caseSensitive(filterlist, partial);
      elif IsRecord(pref) and IsFunction(pref.extender) then
        return pref.extender(filterlist, partial);
      else
        ErrorNoReturn("Invalid setting of UserPreference 'Autocompleter'");
      fi;
    end;

    # check if Ctrl-i was hit repeatedly in a row
  cf := GAPInfo.CommandLineEditFunctions;
  if Length(l)=6 and l[6] = true and cf.LastKey = 9 then
    cf.tabcount := cf.tabcount + 1;
  else 
    cf.tabcount := 1;
    Unbind(cf.tabrec);
    Unbind(cf.tabbang);
    Unbind(cf.tabcompnam);
  fi;
  pos := l[4]-1;
  # in whitespace in beginning of line \t is just inserted
  if ForAll([1..pos], i -> l[3][i] in " \t") then
     return ["\t"];
  fi;
  # find word to complete
  while pos > 0 and l[3][pos] in IdentifierLetters do 
    pos := pos-1;
  od;
  wordplace := [pos+1, l[4]-1];
  word := l[3]{[wordplace[1]..wordplace[2]]};
  # see if we are in the case of a component name
  while pos > 0 and l[3][pos] in " \n\t\r" do
    pos := pos-1;
  od;
  idbnd := IDENTS_BOUND_GVARS();
  if pos > 0 and l[3][pos] = '.' then
    cf.tabcompnam := true;
    if cf.tabcount = 1 then
      # try to find name of component object
      cmps := SplitString(l[3], ".");
      hasbang := [];
      i := Length(cmps);
      while i > 0 do
        # distinguish '.' from '!.' and record for each component which was used
        if Last(cmps[i]) = '!' then
            hasbang[i] := true;
            Remove(cmps[i]); # remove the trailing '!'
        else
            hasbang[i] := false;
        fi;
        NormalizeWhitespace(cmps[i]);
        if not IsValidIdentifier(cmps[i]) then
            break;
        fi;
        i := i-1;
      od;
      hasbang := hasbang{[i+1..Length(cmps)]};
      cmps := cmps{[i+1..Length(cmps)]};
      r := fail;
      if Length(cmps) > 0 and cmps[1] in idbnd then
        r := ValueGlobal(cmps[1]);
        for j in [2..Length(cmps)] do
          if not hasbang[j-1] and IsBound(r.(cmps[j])) then
            r := r.(cmps[j]);
          elif hasbang[j-1] and IsBound(r!.(cmps[j])) then
            r := r!.(cmps[j]);
          else
            r := fail;
            break;
          fi;
        od;
      fi;
      if IsRecord(r) or IsComponentObjectRep(r) then
        cf.tabrec := r;
        cf.tabbang := hasbang[Length(cmps)];
      fi;
    fi;
  fi;
  # now produce the searchlist
  if IsBound(cf.tabrec) then
    # the first two <TAB> hits try existing component names only first
    if cf.tabbang then
      searchlist := ShallowCopy(NamesOfComponents(cf.tabrec));
    else
      searchlist := ShallowCopy(RecNames(cf.tabrec));
    fi;
    if cf.tabcount > 2 then
      Append(searchlist, ALL_RNAMES());
    fi;
  else
    # complete variable name
    searchlist := idbnd;
  fi;

  cand := completeFilter(searchlist, word);
  #  in component name search we try again with all names if this is empty
  if IsBound(cf.tabcompnam) and Length(cand) = 0 and cf.tabcount < 3 then
    searchlist := ALL_RNAMES();
    cand := completeFilter(searchlist, word);
  fi;

  if (not IsBound(cf.tabcompnam) and cf.tabcount = 2) or 
     (IsBound(cf.tabcompnam) and cf.tabcount in [2,4]) then
    if Length(cand) > 0 then
      # we prepend the partial word which was completed
      return GAPInfo.CommandLineEditFunctions.Functions.DisplayMatches(
                                        Concatenation([word], Set(cand)));
    else
      # ring the bell
      return GAPInfo.CommandLineEditFunctions.Functions.RingBell();
    fi;
  fi;
  if Length(cand) = 0 then
    return [];
  elif Length(cand) = 1 then
      return [ wordplace[1], wordplace[2]+1, cand[1]{[1..Length(cand[1])]}];
  fi;
  extension := completeExtender(cand, word);
  if extension = fail then
    return [];
  else
    return [ wordplace[1], wordplace[2] + 1, extension ];
  fi;
end;
GAPInfo.CommandLineEditFunctions.Functions.(INT_CHAR('I') mod 32) :=
                     GAPInfo.CommandLineEditFunctions.Functions.Completion;

fi;
