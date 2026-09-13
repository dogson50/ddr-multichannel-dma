# Release checklist

- [x] Copy the top module and its redistributable transitive submodules.
- [x] Exclude the third-party `uiFDMA.v` implementation.
- [x] Add a local-only integration/lint path for `uiFDMA.v`.
- [x] Scan tracked RTL for obvious secrets, personal paths, and copyright markers.
- [x] Run Icarus Verilog elaboration with the locally authorized dependency.
- [x] Confirm ownership/provenance of every tracked RTL file.
- [x] Choose and add an open-source license (`CERN-OHL-P-2.0`).
- [x] Add copyright holder name/year (`Copyright (C) 2026 Xiao Jun`).
- [ ] Add at least one public testbench or simulation example.
- [x] Configure the public GitHub remote.
- [x] Commit and push `main`.
