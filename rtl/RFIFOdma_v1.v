`timescale 1ns / 1ps

module RFIFOdma_v1
#(
parameter   R0_WR_DATA_COUNT_WIDTH=0,
parameter   R0_DATAWIDTH=0,
parameter   AXI_DATA_WIDTH=256,
parameter   AXI_ADDR_WIDTH=256,
parameter   ENABLE_VSYNC=1,
parameter   R0_RD_DATA_COUNT_WIDTH=0,
parameter   R0FIFO_DEPTH=0,
parameter   RDDDR_mode=0,
parameter integer MAX_BURST_LEN = 64
)(
input I_ui_clk,
input I_ui_rstn,
input [AXI_DATA_WIDTH-1:0] I_fdma_r0data,
input I_fdma_r0valid,
input [3:0]ddr_read_mode,
output reg  [1 : 0]   R0_MS,
output reg  [AXI_ADDR_WIDTH-1'b1:0]   R0_addr,
input [AXI_ADDR_WIDTH-1:0]R0_addr_base,
input  R0_read_start,
input [31:0]R0_filesize,
output [R0_RD_DATA_COUNT_WIDTH-1:0]R0_rdusedw,
output reg   R0_REQ,
output reg  [1 :0] R0_MS_r,
output wire [15:0] O_R0_burst_size,
input  I_fdma_rbusy,
input  wire            I_R0_rclk,
input  wire            I_R0_tready,
output reg [R0_DATAWIDTH-1:0] O_R0_tdata,
output wire O_R0_tvalid,
output wire O_R0_tuser,
output wire O_R0_tlast,
output wire O_R0_done
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

reg R0_read_start_d;
reg R0_read_start_meta, R0_read_start_sync;
reg R0_read_start_toggle;
wire R0_read_start_pos = R0_read_start_sync & ~R0_read_start_d;

wire [31:0] effective_words_r = R0_filesize;
wire [63:0] total_bits_r = effective_words_r * R0_DATAWIDTH;
wire [AXI_ADDR_WIDTH-1:0] beats_total_r =
  (total_bits_r == 0) ? {AXI_ADDR_WIDTH{1'b0}} :
  ((total_bits_r + AXI_DATA_WIDTH - 1) / AXI_DATA_WIDTH);

reg [15:0]               r0_burst_size_m;
reg [AXI_ADDR_WIDTH-1:0] beats_left_m;
reg                      burst_size_pending_m;
assign O_R0_burst_size = r0_burst_size_m;
wire [R0_WR_DATA_COUNT_WIDTH-1'b1 : 0] R0_wcnt;
reg  [R0_WR_DATA_COUNT_WIDTH-1'b1 : 0] R0_wcnt_r1,R0_wcnt_r2;

reg R0fifo_rst;
wire fifo_rst = !I_ui_rstn | R0fifo_rst;

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn)
    R0_MS_r <= S_IDLE;
  else
    R0_MS_r <= R0_MS;
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn) begin
    R0_read_start_meta <= 1'b0;
    R0_read_start_sync <= 1'b0;
    R0_read_start_d <= 1'b0;
    R0_read_start_toggle <= 1'b0;
  end else begin
    R0_read_start_meta <= R0_read_start;
    R0_read_start_sync <= R0_read_start_meta;
    R0_read_start_d <= R0_read_start_sync;
    if (R0_read_start_pos && (effective_words_r != 0))
      R0_read_start_toggle <= ~R0_read_start_toggle;
  end
end

initial R0_MS=S_IDLE;
always @(posedge I_ui_clk or negedge I_ui_rstn) begin
  if (!I_ui_rstn) begin
    R0_MS      <= S_IDLE;
    R0_addr    <= 0;
    R0fifo_rst <= 0;
    r0_burst_size_m  <= 0;
    beats_left_m     <= 0;
    burst_size_pending_m <= 1'b0;
  end else begin
    case (R0_MS)
      S_IDLE: begin
        R0_addr    <= 0;
        R0fifo_rst <= 0;
        burst_size_pending_m <= 1'b0;
        if (R0_read_start_pos && (effective_words_r != 0)) begin
          beats_left_m     <= beats_total_r;
          r0_burst_size_m  <= choose_burst(beats_total_r);
          R0_MS      <= S_RST;
          R0fifo_rst <= 1;
        end
      end
      S_RST: begin
        R0fifo_rst <= 0;
        R0_MS      <= S_DATA1;
      end
      S_DATA1: begin
        if (burst_size_pending_m) begin
          r0_burst_size_m <= choose_burst(beats_left_m);
          burst_size_pending_m <= 1'b0;
        end else if (I_fdma_rbusy == 1'b1 && ddr_read_mode==RDDDR_mode) begin
          R0_MS <= S_DATA2;
        end
      end
      S_DATA2: begin
        if (I_fdma_rbusy == 1'b0 && ddr_read_mode==RDDDR_mode) begin
          if (beats_left_m <= r0_burst_size_m) begin
            beats_left_m     <= 0;
            r0_burst_size_m  <= 0;
            burst_size_pending_m <= 1'b0;
            R0_MS            <= S_IDLE;
          end else begin
            beats_left_m     <= beats_left_m - r0_burst_size_m;
            R0_addr          <= R0_addr + (r0_burst_size_m * AXI_BYTES);
            r0_burst_size_m  <= 0;
            burst_size_pending_m <= 1'b1;
            R0_MS            <= S_DATA1;
          end
        end
      end
      default: R0_MS <= S_IDLE;
    endcase
  end
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn || R0fifo_rst) begin
    R0_wcnt_r1 <= {R0_WR_DATA_COUNT_WIDTH{1'b0}};
    R0_wcnt_r2 <= {R0_WR_DATA_COUNT_WIDTH{1'b0}};
  end else begin
    R0_wcnt_r1 <= R0_wcnt;
    R0_wcnt_r2 <= R0_wcnt_r1;
  end
end

always @(posedge I_ui_clk) begin
  if (!I_ui_rstn || R0fifo_rst)
    R0_REQ <= 1'b0;
  else
    R0_REQ <= (R0_MS == S_DATA1) && (r0_burst_size_m != 0) && (R0_wcnt_r2 < r0_burst_size_m);
end

wire [R0_DATAWIDTH-1:0] R0_dout;
wire R0_empty;
wire [R0_RD_DATA_COUNT_WIDTH-1:0] R0_rdusedw_i;
wire                  out_last_word;
wire                  out_axis_valid;
wire                  out_hs;
wire                  R0_re;
reg  [31:0]           out_words_left;
reg                   out_active;
reg                   out_first_word;
reg                   out_start_pending;
reg                   out_start_toggle_r1;
reg                   out_start_toggle_r2;
reg                   out_start_toggle_r3;
wire                  out_start_pulse;

sfifo #(
.DATA_WIDTH_W(AXI_DATA_WIDTH),
.DATA_WIDTH_R(R0_DATAWIDTH),
.ADDR_WIDTH_W(R0_WR_DATA_COUNT_WIDTH),
.ADDR_WIDTH_R(R0_RD_DATA_COUNT_WIDTH),
.AL_FULL_NUM(R0FIFO_DEPTH-2),
.AL_EMPTY_NUM(2),
.SHOW_AHEAD_EN(1'b1),
.OUTREG_EN ("NOREG")
) r0DMAbuf_fifo (
.rst       (fifo_rst),
.clkw      (I_ui_clk),
.we        (I_fdma_r0valid),
.di        (I_fdma_r0data),
.wrusedw   (R0_wcnt),
.clkr      (I_R0_rclk),
.re        (R0_re),
.dout      (R0_dout),
.empty_flag(R0_empty),
.rdusedw   (R0_rdusedw_i)
);

assign out_start_pulse   = out_start_toggle_r2 ^ out_start_toggle_r3;
assign out_last_word     = out_active & (out_words_left == 32'd1);
assign out_axis_valid    = out_active & (~R0_empty);
assign R0_re             = I_R0_tready & out_axis_valid;
assign out_hs            = R0_re;
assign R0_rdusedw        = R0_rdusedw_i;

always @(posedge I_R0_rclk or negedge I_ui_rstn) begin
  if (!I_ui_rstn) begin
    out_start_toggle_r1 <= 1'b0;
    out_start_toggle_r2 <= 1'b0;
    out_start_toggle_r3 <= 1'b0;
    out_start_pending   <= 1'b0;
  end else begin
    out_start_toggle_r1 <= R0_read_start_toggle;
    out_start_toggle_r2 <= out_start_toggle_r1;
    out_start_toggle_r3 <= out_start_toggle_r2;

    if (out_start_pulse)
      out_start_pending <= 1'b1;
    else if (out_start_pending && !fifo_rst)
      out_start_pending <= 1'b0;
  end
end

always @(posedge I_R0_rclk or posedge fifo_rst) begin
  if (fifo_rst) begin
    out_words_left <= 32'd0;
    out_active     <= 1'b0;
    out_first_word <= 1'b0;
  end else if (out_start_pending) begin
    out_words_left <= effective_words_r;
    out_active     <= (effective_words_r != 0);
    out_first_word <= (effective_words_r != 0);
  end else if (out_hs) begin
    if (out_last_word) begin
      out_words_left <= 32'd0;
      out_active     <= 1'b0;
      out_first_word <= 1'b0;
    end else begin
      out_words_left <= out_words_left - 1'b1;
      out_first_word <= 1'b0;
    end
  end
end

always @(*) begin
  O_R0_tdata = R0_dout;
end

assign O_R0_tvalid = out_axis_valid;
assign O_R0_tuser  = out_first_word & O_R0_tvalid;
assign O_R0_tlast  = out_last_word & O_R0_tvalid;
assign O_R0_done   = O_R0_tlast & I_R0_tready;

endmodule
