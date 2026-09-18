# Multi-channel DDR DMA Controller (FPGA RTL)

一个面向 FPGA DDR 数据通路的多通道 Verilog 控制器，提供视频流与普通
AXI-Stream 数据在多个写通道、读通道之间的缓存、地址生成和固定优先级仲裁。

> **开源许可证：CERN-OHL-P-2.0；Copyright © 2026 Xiao Jun。**
>
> `uiFDMA.v` 是外部第三方依赖，不随本仓库分发；详见
> [`docs/THIRD_PARTY.md`](docs/THIRD_PARTY.md)。

## 功能概览

- 4 路写通道：W0/W3 为视频帧通道，W1/W2 为普通流式 DMA 通道。
- 5 路读通道：R0/R1 为视频帧通道，R2/R3/R4 为普通流式 DMA 通道。
- 每个通道可通过参数独立启用或关闭。
- 支持异步 FIFO 跨时钟域。
- 支持窄位宽输入流打包到 DDR/AXI 数据宽度。
- 视频通道支持帧缓冲索引、行/帧地址推进和同步控制。
- 普通 DMA 通道支持运行时基地址、文件大小和启动控制。
- 控制器采用固定优先级仲裁，并通过 FDMA 请求接口驱动 AXI4 master bridge。
- 当前顶层会串行化完整的 FDMA 读写事务；裸 `uiFDMA` 的一读一写并发验证及控制器限制详见 [`docs/FDMA_DUPLEX_AND_CONTROLLER_LIMITATIONS.md`](docs/FDMA_DUPLEX_AND_CONTROLLER_LIMITATIONS.md)。

## 当前固定优先级

```text
W0 -> R0 -> R1 -> W1 -> W2 -> W3 -> R2 -> R3 -> R4
```

该顺序来自 `DMA4DDR_ctrl_v1.v` 当前仲裁状态机；如用于持续高负载场景，建议
评估低优先级通道的饥饿风险。

## 目录

```text
rtl/
  DMA4DDR_ctrl_v1.v   顶层：通道配置、复用、地址生成和仲裁
  WFIFO_VIDEO.v       视频写通道
  WFIFOdma_v1.v       普通流式写通道
  RFIFO_VIDEO.v       视频读通道
  RFIFOdma_v1.v       普通流式读通道
  sfifo.v             异步 FIFO / 位宽转换基础模块
  dma_stream_packer.v 窄流到宽拍打包器
scripts/
  lint.ps1            Icarus Verilog 编译检查
vendor/
  uiFDMA.v            本地外部依赖；被 .gitignore 排除
```

## 工具与语言

- Verilog/SystemVerilog-2012 编译模式
- 已使用 Icarus Verilog 做顶层 elaboration 检查
- 目标集成环境为带 AXI4 DDR/MIG 用户接口的 FPGA 系统

## 快速检查

1. 按授权条件自行取得兼容的 `uiFDMA.v`。
2. 将其放入 `vendor/uiFDMA.v`。
3. 在 PowerShell 中运行：

```powershell
./scripts/lint.ps1
```

也可以显式指定外部文件：

```powershell
./scripts/lint.ps1 -UiFdmaPath 'D:\path\to\authorized\uiFDMA.v'
```

## 已知事项

- 当前仲裁为固定优先级，不是 round-robin。
- 当前版本尚未附带公开 testbench；建议后续补充读写、背压、跨时钟域和
  多通道竞争测试。
- 发布副本修正了原顶层中 R0/R1 两个 `I_R0sync_en` 悬空连接；原工程文件未改动。
- `uiFDMA` 不属于本仓库可再许可的源码范围。

## License

本仓库中可公开的 Covered Source 由 Xiao Jun 以
[CERN Open Hardware Licence Version 2 - Permissive](LICENSE) 发布，
SPDX 标识为 `CERN-OHL-P-2.0`。源码位置为：

```text
https://github.com/dogson50/ddr-multichannel-dma
```

许可证不覆盖、也不重新许可第三方 `uiFDMA.v`；该文件不会随仓库分发。
