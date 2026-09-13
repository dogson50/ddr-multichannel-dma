// SPDX-License-Identifier: CERN-OHL-P-2.0
// Copyright (C) 2026 Xiao Jun
// Source Location: https://github.com/dogson50/ddr-multichannel-dma

`timescale 1ns / 1ps

module WFIFOdma_v1
#(
parameter   W0_DSIZEBITS=0,
parameter   W0_DATAWIDTH=64,
parameter   AXI_DATA_WIDTH=256,
parameter   ENABLE_VSYNC=1,
parameter   W0YBUF_SIZE=3,
parameter   AXI_ADDR_WIDTH=0,
parameter   W0Y_BURST_TIMES=0,
parameter   W0X_LAST_ADDR_INC=0,
parameter   FDMA_W0X_BURST=0,
parameter   W0_RD_DATA_COUNT_WIDTH=128,
parameter   W0FIFO_DEPTH=0,
parameter   WDDDR_mode=0,
parameter integer MAX_BURST_LEN = 64
)(
input I_ui_clk,
input I_ui_rstn,
output [AXI_DATA_WIDTH-1:0] O_fdma_w0data,
input I_fdma_w0valid,
input [3:0]ddr_write_mode,
input [AXI_ADDR_WIDTH-1:0]W0_addr_base,
input [31:0]W0_filesize,
input W0_write_start,
output reg  [1 : 0]   W0_MS,
output reg  [W0_DSIZEBITS-1'b1:0]   W0_addr,
output reg [7 : 0]   O_fdma_w0bufn,
output reg   W0_REQ,
output reg  [1 :0] W0_MS_r,
output wire [15:0] O_W0_burst_size,
input  I_fdma_wbusy,
input  wire            I_W0_en,
input  wire            I_W0_wclk,
input  wire            I_W0_tuser,
input  wire            I_W0_tvalid,
input  wire [W0_DATAWIDTH-1:0] I_W0_tdata,
input  wire            I_W0_tlast,
output wire            O_W0_tready,
output reg [7:0]       O_W0_sync_cnt,
input  wire [7:0]      I_W0_buf
);

localparam    S_IDLE  = 2'd0;
localparam    S_RST   = 2'd1;
localparam    S_DATA1 = 2'd2;
localparam    S_DATA2 = 2'd3;
localparam integer AXI_BYTES = AXI_DATA_WIDTH / 8;

function [15:0] choose_burst;
  input [AXI_ADDR_WIDTH-1:0] beats_left;
begin
  if (beats_left == 0)
    choose_burst = 16'd0;
  else if (beats_left > MAX_BURST_LEN)
    choose_burst = MAX_BURST_LEN;
  else
    choose_burst = beats_left[15:0];
end
endfunction

reg W0_write_start_r;
reg W0_write_start_meta, W0_write_start_sync;
always@(posedge I_ui_clk)
if(!I_ui_rstn) begin
W0_write_start_meta<=1'b0;
W0_write_start_sync<=1'b0;
end else begin
W0_write_start_meta<=W0_write_start;
W0_write_start_sync<=W0_write_start_meta;
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn)
    W0_write_start_r <= 1'b0;
  else if (W0_write_start_sync)
    W0_write_start_r <= 1'b1;
  else if (W0_MS != S_IDLE)
    W0_write_start_r <= 1'b0;
end

wire [31:0] effective_words_w = W0_filesize;
wire [63:0] total_bits_w = effective_words_w * W0_DATAWIDTH;
wire [AXI_ADDR_WIDTH-1:0] beats_total_w =
  (total_bits_w == 0) ? {AXI_ADDR_WIDTH{1'b0}} :
  ((total_bits_w + AXI_DATA_WIDTH - 1) / AXI_DATA_WIDTH);

reg [15:0]                 w0_burst_size_m;
reg [AXI_ADDR_WIDTH-1:0]   beats_left_m;
reg                        burst_size_pending_m;
assign O_W0_burst_size = w0_burst_size_m;

wire                              W0_empty;
wire [W0_RD_DATA_COUNT_WIDTH-1 : 0] W0_rcnt;
reg  [W0_RD_DATA_COUNT_WIDTH-1 : 0] W0_rcnt_r1,W0_rcnt_r2;

wire          W0_full_pro;
wire          O_W0_full;

reg W0fifo_rst;
wire fifo_rst = (I_ui_rstn == 1'b0) | W0fifo_rst;

reg  [31:0] w_word_cnt;
wire        pack_in_ready;
wire        pack_out_valid;
wire [AXI_DATA_WIDTH-1:0] pack_out_data;
wire        pack_out_ready;
wire        in_last_word;
wire        in_hs;
wire        fifo_we;

assign O_W0_tready = I_W0_en & pack_in_ready & (~O_W0_full);
assign in_hs       = I_W0_en & I_W0_tvalid & O_W0_tready;
assign in_last_word = (effective_words_w != 0) && (w_word_cnt == effective_words_w - 1);

always @(posedge I_W0_wclk or posedge fifo_rst) begin
  if (fifo_rst) begin
    w_word_cnt <= 32'd0;
    O_W0_sync_cnt <= 8'd0;
    O_fdma_w0bufn <= 8'd0;
  end else if (in_hs) begin
    if (in_last_word)
      w_word_cnt <= 32'd0;
    else
      w_word_cnt <= w_word_cnt + 1'b1;

    if (I_W0_tuser) begin
      O_W0_sync_cnt <= O_W0_sync_cnt + 1'b1;
      O_fdma_w0bufn <= I_W0_buf;
    end
  end
end

dma_stream_packer #(
  .IN_DW (W0_DATAWIDTH),
  .OUT_DW(AXI_DATA_WIDTH)
) u_dma_stream_packer (
  .clk      (I_W0_wclk),
  .rst      (fifo_rst),
  .in_valid (I_W0_en & I_W0_tvalid),
  .in_data  (I_W0_tdata),
  .in_last  (in_last_word),
  .in_ready (pack_in_ready),
  .out_valid(pack_out_valid),
  .out_data (pack_out_data),
  .out_ready(pack_out_ready)
);

assign pack_out_ready = ~O_W0_full;
assign fifo_we        = pack_out_valid & pack_out_ready;

sfifo #(
.DATA_WIDTH_W(AXI_DATA_WIDTH),
.DATA_WIDTH_R(AXI_DATA_WIDTH),
.ADDR_WIDTH_W(W0_RD_DATA_COUNT_WIDTH),
.ADDR_WIDTH_R(W0_RD_DATA_COUNT_WIDTH),
.AL_FULL_NUM(W0FIFO_DEPTH-2),
.AL_EMPTY_NUM(2),
.SHOW_AHEAD_EN(1'b1),
.OUTREG_EN ("NOREG")
) w0_ISPbuf_fifo (
.rst          (fifo_rst),
.clkw         (I_W0_wclk),
.we           (fifo_we),
.di           (pack_out_data),
.full_flag    (O_W0_full),
.afull        (W0_full_pro),
.clkr         (I_ui_clk),
.re           (I_fdma_w0valid),
.dout         (O_fdma_w0data),
.empty_flag   (W0_empty),
.rdusedw      (W0_rcnt)
);

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn || W0fifo_rst) begin
    W0_rcnt_r1 <= {W0_RD_DATA_COUNT_WIDTH{1'b0}};
    W0_rcnt_r2 <= {W0_RD_DATA_COUNT_WIDTH{1'b0}};
  end else begin
    W0_rcnt_r1 <= W0_rcnt;
    W0_rcnt_r2 <= W0_rcnt_r1;
  end
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn || W0fifo_rst)
    W0_REQ <= 1'b0;
  else
    W0_REQ <= (W0_MS == S_DATA1) && (w0_burst_size_m != 0) && (W0_rcnt_r2 >= w0_burst_size_m);
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn)
    W0_MS_r <= S_IDLE;
  else
    W0_MS_r <= W0_MS;
end

initial W0_MS=S_IDLE;
always @(posedge I_ui_clk) begin
  if (!I_ui_rstn) begin
    W0_MS      <= S_IDLE;
    W0_addr    <= 0;
    W0fifo_rst <= 0;
    w0_burst_size_m  <= 0;
    beats_left_m     <= 0;
    burst_size_pending_m <= 1'b0;
  end else begin
    case (W0_MS)
      S_IDLE: begin
        W0_addr    <= 0;
        W0fifo_rst <= 0;
        burst_size_pending_m <= 1'b0;
        if(W0_write_start_r && (effective_words_w != 0)) begin
          beats_left_m     <= beats_total_w;
          w0_burst_size_m  <= choose_burst(beats_total_w);
          W0_MS      <= S_RST;
          W0fifo_rst <= 1;
        end
      end
      S_RST: begin
        W0fifo_rst <= 0;
        W0_MS      <= S_DATA1;
      end
      S_DATA1: begin
        if (burst_size_pending_m) begin
          w0_burst_size_m <= choose_burst(beats_left_m);
          burst_size_pending_m <= 1'b0;
        end else if (I_fdma_wbusy == 1'b1 && ddr_write_mode==WDDDR_mode) begin
          W0_MS <= S_DATA2;
        end
      end
      S_DATA2: begin
        if (I_fdma_wbusy == 1'b0 && ddr_write_mode==WDDDR_mode) begin
          if (beats_left_m <= w0_burst_size_m) begin
            beats_left_m     <= 0;
            w0_burst_size_m  <= 0;
            burst_size_pending_m <= 1'b0;
            W0_MS            <= S_IDLE;
          end else begin
            beats_left_m     <= beats_left_m - w0_burst_size_m;
            W0_addr          <= W0_addr + (w0_burst_size_m * AXI_BYTES);
            w0_burst_size_m  <= 0;
            burst_size_pending_m <= 1'b1;
            W0_MS            <= S_DATA1;
          end
        end
      end
      default: W0_MS <= S_IDLE;
    endcase
  end
end

endmodule
