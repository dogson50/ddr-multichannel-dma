# Release checklist

- [x] Copy the top module and its redistributable transitive submodules.
- [x] Exclude the third-party `uiFDMA.v` implementation.
- [x] Add a local-only integration/lint path for `uiFDMA.v`.
- [x] Scan tracked RTL for obvious secrets, personal paths, and copyright markers.
- [x] Run Icarus Verilog elaboration with the locally authorized dependency.
- [ ] Confirm ownership/provenance of every tracked RTL file.
- [ ] Choose and add an open-source license.
- [ ] Add copyright holder name/year.
- [ ] Add at least one public testbench or simulation example.
- [ ] Configure the public GitHub/GitLab/Gitee remote.
- [ ] Commit and push `main`.
