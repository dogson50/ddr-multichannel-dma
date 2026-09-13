// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright (C) 2026 Xiao Jun
// Source Location: https://github.com/dogson50/ddr-multichannel-dma

`timescale 1ns / 1ps

// 将较窄的流数据打包成 DDR 侧数据宽度。
// lane 顺序固定为小端：
//   第 0 个输入 word 放在 out_data[IN_DW-1:0]
//   第 1 个输入 word 放在 out_data[2*IN_DW-1:IN_DW]
//   ...
// 例如 IN_DW=32, OUT_DW=128，输入 100,101,102,103 时，
// out_data = {32'h103, 32'h102, 32'h101, 32'h100}。
module dma_stream_packer #(
  parameter integer IN_DW  = 32,
  parameter integer OUT_DW = 128
)(
  input  wire                 clk,
  input  wire                 rst,

  input  wire                 in_valid,
  input  wire [IN_DW-1:0]     in_data,
  input  wire                 in_last,
  output wire                 in_ready,

  output reg                  out_valid,
  output reg  [OUT_DW-1:0]    out_data,
  input  wire                 out_ready
);

  function integer clog2;
    input integer value;
    integer i;
    begin
      clog2 = 0;
      for (i = value - 1; i > 0; i = i >> 1)
        clog2 = clog2 + 1;
    end
  endfunction

  localparam integer LANES = OUT_DW / IN_DW;
  localparam integer CNT_W = (LANES <= 1) ? 1 : clog2(LANES);
  localparam [CNT_W-1:0] LANE_LAST = LANES - 1;

  reg [OUT_DW-1:0] pack_data;
  reg [CNT_W-1:0]  lane_cnt;

  wire out_busy   = out_valid & ~out_ready;
  wire in_fire    = in_valid & in_ready;
  wire last_lane  = (lane_cnt == LANE_LAST);
  wire flush_pack = in_fire & (last_lane | in_last);

  assign in_ready = ~out_busy;

  integer k;
  reg [OUT_DW-1:0] pack_next;

  always @(*) begin
    pack_next = pack_data;
    for (k = 0; k < LANES; k = k + 1) begin
      if (lane_cnt == k)
        pack_next[k*IN_DW +: IN_DW] = in_data;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pack_data <= {OUT_DW{1'b0}};
      lane_cnt  <= {CNT_W{1'b0}};
      out_valid <= 1'b0;
      out_data  <= {OUT_DW{1'b0}};
    end else begin
      if (out_valid && out_ready)
        out_valid <= 1'b0;

      if (in_fire) begin
        pack_data <= flush_pack ? {OUT_DW{1'b0}} : pack_next;
        lane_cnt  <= flush_pack ? {CNT_W{1'b0}} : (lane_cnt + 1'b1);

        if (flush_pack) begin
          out_valid <= 1'b1;
          out_data  <= pack_next;
        end
      end
    end
  end

endmodule
