if LoadPackage("profiling") <> true then
    Print("ERROR: could not load profiling package");
    FORCE_QUIT_GAP(1);
fi;
d := Directory("coverage");;
covs := [];;
for f in DirectoryContents(d) do
    if f in [".", ".."] then continue; fi;
    Add(covs, Filename(d, f));
od;
Print("Merging coverage results from ", covs, "\n");
r := MergeLineByLineProfiles(covs);;


# Outputs Lcov output
if not IsBound(OutputLcovCoverage) then
    BindGlobal("OutputLcovCoverage",
    function(data, outfile)
        local outstream, i, file, lines;

        outfile := UserHomeExpand(outfile);
        outstream := IO_File(outfile, "w");

        if not(IsRecord(data)) then
          data := ReadLineByLineProfile(data);
        fi;

        for file in data.line_info do
            if IsExistingFile(file[1]) then
                IO_Write(outstream, "TN:\n");
                IO_Write(outstream, Concatenation("SF:",file[1],"\n"));

                lines := file[2];
                for i in [1..Length(lines)] do
                  if lines[i][1] > 0 or lines[i][2] > 0 then
                    IO_Write(outstream, "DA:",i,",",lines[i][2],"\n");
                  fi;
                od;
                IO_Write(outstream, "end_of_record\n");
            fi;
        od;
        IO_Close(outstream);
    end);
fi;

prefix := UserHomeExpand("~/.julia");
r.line_info := Filtered(r.line_info, file -> not StartsWith(file[1], prefix));

Print("Outputting LCOV\n");
OutputLcovCoverage(r, "gap-lcov.info");;
QUIT_GAP(0);
