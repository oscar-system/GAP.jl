if LoadPackage("profiling") <> true then
    Print("ERROR: could not load profiling package");
    FORCE_QUIT_GAP(1);
fi;
d := DirectoryCurrent();
covs := [];
for f in DirectoryContents(d) do
    if EndsWith(f, ".coverage") then
      Add(covs, Filename(d, f));
    fi;
od;
Print("Merging coverage results from ", covs, "\n");
r := MergeLineByLineProfiles(covs);
Print("Outputting JSON\n");
OutputJsonCoverage(r, "gap-coverage.json");
QUIT_GAP(0);
