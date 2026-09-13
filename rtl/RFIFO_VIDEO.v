`timescale 1ns / 1ps

module RFIFO_VIDEO#(
parameter   R0_DSIZEBITS=0,
parameter   R0_WR_DATA_COUNT_WIDTH=0,
parameter   R0_DATAWIDTH=0,
parameter   AXI_DATA_WIDTH=256,
parameter   ENABLE_VSYNC=1,
parameter   R0YBUF_SIZE=3,
parameter   R0Y_BURST_TIMES=0,
parameter   R0_XDIV=0,
parameter   R0X_BURST_ADDR_INC=0,
parameter   R0X_LAST_ADDR_INC=0,
parameter   FDMA_R0X_BURST=0,
parameter   R0_XSIZE=0,
parameter   R0_YSIZE=0,
parameter   R0_RD_DATA_COUNT_WIDTH=0,
parameter   R0FIFO_DEPTH=0,
parameter   RDDDR_mode=0,
parameter   STRICT_FRAME_COMMIT=0
)(
input I_ui_clk,
input I_ui_rstn,
input [AXI_DATA_WIDTH-1:0] I_fdma_r0data,
input I_fdma_r0valid,
input [3:0]ddr_read_mode,
output reg  [1 : 0]   R0_MS,
output reg  [R0_DSIZEBITS-1'b1:0]   R0_addr,
output reg [7 : 0]   O_fdma_r0bufn,
output reg   R0_REQ,
output reg  [1 :0] R0_MS_r,
input  I_fdma_rbusy,
input  wire            I_R0_en,        // 读取使能
input  wire            I_R0sync_en,    // 帧同步使能 (用于同步)
input  wire            I_R0_rclk,      // 读取 FIFO 时钟 (系统时钟)
input  wire            I_R0_tready,    // 读取数据就绪
output wire            O_R0_tuser,     // 读取帧头标志
output wire            O_R0_tvalid,    // 读取数据有效
output wire [R0_DATAWIDTH-1:0] O_R0_tdata,  // 读取数据
output wire            O_R0_vrst,      // 读取复位信号 (用于 FIFO 同步)
output wire            O_R0_tlast,     // 读取帧尾标志
output reg [7:0]       O_R0_sync_cnt,  // 读取缓冲区同步计数器
input  wire [7:0]      I_R0_buf,      // 读取缓冲区索引
input  wire            I_R0_frame_done,
input  wire [7:0]      I_R0_frame_bufn
 );

localparam    S_IDLE  = 2'd0;
localparam    S_RST   = 2'd1;
localparam    S_DATA1 = 2'd2;
localparam    S_DATA2 = 2'd3;


//synthesis keep

reg  [                          15:0]   R0_bcnt = 0;
wire [R0_WR_DATA_COUNT_WIDTH-1'b1 : 0]   R0_wcnt;
reg  [R0_WR_DATA_COUNT_WIDTH-1'b1 : 0]   R0_wcnt_r1,R0_wcnt_r2;

reg  [                         3 : 0]   r0div_cnt = 0;
reg  [                         7 : 0]   r0rst_cnt = 0;

always @(posedge I_ui_clk)      R0_MS_r <= R0_MS;
reg r0fifo_rst;
reg r0fs_r1,r0fs_r2,r0fs_r3,r0fs_r4;
wire          R0_empty;  //synthesis keep
wire          R0_tvalid;  //synthesis keep
assign        R0_tvalid        = ~R0_empty;
reg           r0_tuser_lock;  //synthesis keep
// reg r0_tuser;
reg           r0_tlast;  //synthesis keep
reg [15:0]    r0_xcnt;  //synthesis keep

reg [15:0]    r0_ycnt;  //synthesis keep
reg [20:0]    R0dl_cnt;
reg [7:0]     r0_committed_buf;
reg           r0_committed_valid;
wire [7:0]    r0_buf_sel_active = (STRICT_FRAME_COMMIT != 0) ? r0_committed_buf : I_R0_buf;


always @(posedge I_ui_clk) begin
              r0fs_r1            <= I_R0_en;
              r0fs_r2            <= r0fs_r1;
              r0fs_r3            <= r0fs_r2;
              r0fs_r4            <= r0fs_r3;
end


always @(posedge I_ui_clk) begin
  if (!I_ui_rstn) begin
              R0_MS              <= S_IDLE;
              R0_addr            <= 0;
              O_R0_sync_cnt      <= 0;
              R0_bcnt            <= 0;
              r0rst_cnt          <= 0;
              r0div_cnt          <= 0;
              O_fdma_r0bufn      <= 0;
              r0_committed_buf   <= 8'd0;
              r0_committed_valid <= 1'b0;
  end else begin
    if (I_R0_frame_done) begin
              r0_committed_buf   <= I_R0_frame_bufn;
              r0_committed_valid <= 1'b1;
    end
    case (R0_MS)
    S_IDLE: begin
              R0_addr          <= 0;
              R0_bcnt          <= 0;
              r0rst_cnt        <= 0;
              r0div_cnt        <= 0;
      if(({r0fs_r4,r0fs_r3} == 2'b10 | (ENABLE_VSYNC == 0)) &&
         ((STRICT_FRAME_COMMIT == 0) || r0_committed_valid)) begin
              R0_MS <= S_RST;
        if(O_R0_sync_cnt < R0YBUF_SIZE)
              O_R0_sync_cnt    <= O_R0_sync_cnt + 1'b1;
        else  O_R0_sync_cnt    <= 0;
      end

    end
    S_RST: begin
                   O_fdma_r0bufn    <= r0_buf_sel_active;
              R0_MS            <= S_DATA1;
    end
    S_DATA1: begin
      if (I_fdma_rbusy == 1'b1&&ddr_read_mode==RDDDR_mode) begin
              R0_MS            <= S_DATA2;
      end
    end
    S_DATA2: begin
      if (I_fdma_rbusy == 1'b0&&ddr_read_mode==RDDDR_mode) begin
        if (R0_bcnt == R0Y_BURST_TIMES - 1'b1)
              R0_MS            <= S_IDLE;
        else begin
          if(r0div_cnt < R0_XDIV - 1'b1)begin
              R0_addr          <= R0_addr + R0X_BURST_ADDR_INC;
              r0div_cnt        <= r0div_cnt + 1'b1;
          end else begin
              R0_addr          <= R0_addr + R0X_LAST_ADDR_INC;
              r0div_cnt        <= 0;
          end
              R0_bcnt          <= R0_bcnt + 1'b1;
              R0_MS            <= S_DATA1;
        end
      end
    end
    default:  R0_MS            <= S_IDLE;
    endcase
  end
end




always @(posedge I_ui_clk) begin
              R0_wcnt_r1       <= R0_wcnt;
              R0_wcnt_r2       <= R0_wcnt_r1;
end
always @(posedge I_ui_clk) R0_REQ <= (R0_wcnt_r2 < FDMA_R0X_BURST - 1 );

assign        O_R0_tvalid      = ~R0_empty &(I_R0_tready);


assign        O_R0_tuser = r0_tuser_lock & O_R0_tvalid;
assign        O_R0_tlast = (r0_xcnt == R0_XSIZE - 1) & O_R0_tvalid;

always @(posedge I_R0_rclk or negedge I_ui_rstn) begin
  if (~I_ui_rstn)
              r0_xcnt          <= 0;
  else if (O_R0_tvalid) begin
    if (r0_xcnt == R0_XSIZE - 1)
              r0_xcnt          <= 0;
    else
              r0_xcnt          <= r0_xcnt + 1'b1;
  end
end

always @(posedge I_R0_rclk or negedge I_ui_rstn) begin
  if (~I_ui_rstn) begin
              r0_tuser_lock    <= 1'b1;
              r0_ycnt          <= 0;
  end else begin
    if (O_R0_tlast) begin
      if (r0_ycnt == R0_YSIZE - 1) begin
              r0_tuser_lock    <= 1'b1;
              r0_ycnt          <= 0;
      end
      else
              r0_ycnt          <= r0_ycnt + 1'b1;
    end
    else if (O_R0_tuser)
              r0_tuser_lock    <= 1'b0;
  end
end


assign        O_R0_vrst        = ~R0dl_cnt[20];
always @(posedge I_R0_rclk or negedge I_ui_rstn) begin
  if(~I_ui_rstn)
              R0dl_cnt          <= 0;
  else if(~R0dl_cnt[20])
               R0dl_cnt         <= R0dl_cnt + 1'b1;
end



sfifo #(
.DATA_WIDTH_W(AXI_DATA_WIDTH),
.DATA_WIDTH_R(R0_DATAWIDTH),
.ADDR_WIDTH_W(R0_WR_DATA_COUNT_WIDTH),
.ADDR_WIDTH_R(R0_RD_DATA_COUNT_WIDTH),
.AL_FULL_NUM(R0FIFO_DEPTH-2),
.AL_EMPTY_NUM(2),
.SHOW_AHEAD_EN(1'b1) ,
.OUTREG_EN ("NOREG")
) r0HDMIbuf_fifo (
.rst       (I_ui_rstn == 1'b0             ),
.clkw      (I_ui_clk                      ),
.we        (I_fdma_r0valid                 ),
.di        (I_fdma_r0data                  ),
.wrusedw   (R0_wcnt                        ),
.clkr      (I_R0_rclk                      ),
.re        (O_R0_tvalid                    ),
.dout      (O_R0_tdata                     ),
.empty_flag(R0_empty                       )
);


endmodule
