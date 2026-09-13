# Third-party dependency: uiFDMA

`DMA4DDR_ctrl_v1` instantiates a module named `uiFDMA`, which bridges the internal
FDMA request/data interface to an AXI4 master interface.

The locally available `uiFDMA.v` is **not included in this repository** because
its header identifies MiLianKe Electronic Technology Co., Ltd. as the copyright
owner and states "All rights reserved." This repository must not redistribute
that file unless the copyright owner grants a suitable redistribution license.

## Local integration

If you are an authorized user of that implementation, place your local copy at:

```text
vendor/uiFDMA.v
```

The path is intentionally ignored by Git. Then run:

```powershell
./scripts/lint.ps1
```

Alternatively, provide a clean-room, interface-compatible AXI4 master named
`uiFDMA` under a license compatible with this repository.

## License scope

The repository's CERN-OHL-P-2.0 license applies only to the Covered Source
actually tracked here. It does not grant any rights to the excluded MiLianKe
`uiFDMA.v` implementation.