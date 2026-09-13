`timescale 1ns / 1ps

module WFIFO_VIDEO#(
parameter   W0_DSIZEBITS=0,
parameter   W0_WR_DATA_COUNT_WIDTH=0,
parameter   W0_DATAWIDTH=0,
parameter   AXI_DATA_WIDTH=256,
parameter   ENABLE_VSYNC=1,
parameter   W0YBUF_SIZE=3,
parameter   W0Y_BURST_TIMES=0,
parameter   W0_XDIV=0,
parameter   W0X_BURST_ADDR_INC=0,
parameter   W0X_LAST_ADDR_INC=0,
parameter   FDMA_W0X_BURST=0,
parameter   W0_XSIZE=0,
parameter   W0_YSIZE=0,
parameter   W0_RD_DATA_COUNT_WIDTH=0,
parameter   W0FIFO_DEPTH=0,
parameter   WDDDR_mode=0
)(
input I_ui_clk,
input I_ui_rstn,
output [AXI_DATA_WIDTH-1:0] O_fdma_w0data,
input I_fdma_w0valid,
input [3:0]ddr_write_mode,
output reg  [1 : 0]   W0_MS,
output reg  [W0_DSIZEBITS-1'b1:0]   W0_addr,
output reg [7 : 0]   O_fdma_w0bufn,
output reg   W0_REQ,
output reg  [1 :0] W0_MS_r,
input  I_fdma_wbusy,
input  wire            I_W0_en,        // 写入使能 (来自传感器)
input  wire            I_W0_wclk,      // 写入 FIFO 时钟 (传感器时钟)
input  wire            I_W0_tuser,     // 写入帧头标志 (1=帧头, 0=数据)
input  wire            I_W0_tvalid,    // 写入数据有效
input  wire [W0_DATAWIDTH-1:0] I_W0_tdata,  // 写入数据
input  wire            I_W0_tlast,     // 写入帧尾标志
output wire            O_W0_tready,    // 写入 FIFO 准备就绪 (始终为 1)
output reg [7:0]       O_W0_sync_cnt,  // 写入缓冲区同步计数器 (用于帧同步)
input  wire [7:0]      I_W0_buf,      // 写入缓冲区索引 (来自 FDMA)
output reg             O_W0_frame_done,
output reg [7:0]       O_W0_frame_bufn
);
localparam    S_IDLE  = 2'd0;
localparam    S_RST   = 2'd1;
localparam    S_DATA1 = 2'd2;
localparam    S_DATA2 = 2'd3;
wire                              W0_empty;

wire[W0_RD_DATA_COUNT_WIDTH-1 : 0] W0_rcnt;
reg [W0_RD_DATA_COUNT_WIDTH-1 : 0] W0_rcnt_r1,W0_rcnt_r2;
reg [8  : 0]                      w0rst_cnt;
reg                               w0fifo_rst_done;
reg                               w0fifo_rst_lock;


reg                               W0_tuser_r3,W0_tuser_r2, W0_tuser_r1;
reg                               W0_tvalid_r1;
reg                               W0_tlast_r1,W0_tlast_r2;
reg [W0_DATAWIDTH -1 : 0]          W0_tdata_r1;



reg [15:0]    W0_bcnt              = 0;


reg [3 : 0]   w0div_cnt            = 0;

wire   w0fifo_rst  = (w0rst_cnt >10) & (w0rst_cnt <80) ;

always @(posedge I_ui_clk) W0_MS_r <= W0_MS;
reg           W0_FIFO_Rst          = 0;
wire          W0_full_pro;
wire          O_W0_full;
assign        O_W0_tready = 1'b1;

wire   w0fifo_wen  = W0_tvalid_r1 & w0fifo_rst_done;
reg          w0fifo_rst_done_r1 = 1'b0, w0fifo_rst_done_r2 = 1'b0, w0fifo_rst_done_r3 = 1'b0;
reg           w0fs_r1,w0fs_r2,w0fs_r3,w0fs_r4;

wire            w0_fs;
assign          w0_fs              = {w0fs_r4,w0fs_r3} == 2'b10 ? 1 : 0;







always @(posedge I_W0_wclk) begin
              W0_tuser_r1        <= I_W0_tuser;
              W0_tuser_r2        <= W0_tuser_r1;
              W0_tlast_r1        <= I_W0_tlast;
              W0_tlast_r2        <= W0_tlast_r1;
              W0_tvalid_r1       <= I_W0_tvalid;
              W0_tdata_r1        <= I_W0_tdata;
              W0_tuser_r3        <= W0_tuser_r2|W0_tuser_r1|I_W0_tuser;
end





always @(posedge I_W0_wclk or negedge I_ui_rstn) begin
  if (~I_ui_rstn) begin
              w0rst_cnt          <= 0;
              w0fifo_rst_done    <= 0;
              w0fifo_rst_lock    <= 0;
  end
  else if(I_W0_tuser & (W0_empty == 1'b0)) begin
              w0fifo_rst_lock    <= 1;
              w0fifo_rst_done    <= 0;
              w0rst_cnt          <= 0;
  end
  else if(w0fifo_rst_lock & (w0rst_cnt[8] == 0))
              w0rst_cnt          <= w0rst_cnt + 1'b1;
  else if(W0_MS == S_IDLE & I_W0_tuser)begin
              w0rst_cnt          <= 0;
              w0fifo_rst_done    <= 1;
              w0fifo_rst_lock    <= 0;
  end
end






always @(posedge I_ui_clk) begin
              w0fifo_rst_done_r1 <= w0fifo_rst_done;
              w0fifo_rst_done_r2 <= w0fifo_rst_done_r1;
end


always @(posedge I_ui_clk) begin
              w0fs_r1            <= W0_tuser_r3;
              w0fs_r2            <= w0fs_r1;
              w0fs_r3            <= w0fs_r2;
              w0fs_r4            <= w0fs_r3;
end




always @(posedge I_ui_clk)begin
              W0_rcnt_r1           <= W0_rcnt;
              W0_rcnt_r2           <= W0_rcnt_r1;
end

always @(posedge I_ui_clk) W0_REQ <= (W0_rcnt_r2 > FDMA_W0X_BURST - 1);





always @(posedge I_ui_clk) begin
  if (!I_ui_rstn) begin
              W0_MS              <= S_IDLE;
              W0_FIFO_Rst        <= 0;
              W0_addr            <= 0;
              O_W0_sync_cnt      <= 0;
              W0_bcnt            <= 0;
              w0div_cnt          <= 0;
              O_fdma_w0bufn      <= 0;
              O_W0_frame_done    <= 1'b0;
              O_W0_frame_bufn    <= 8'd0;
    end else begin
              O_W0_frame_done    <= 1'b0;
      case (W0_MS)
        S_IDLE: begin
              W0_addr            <= 0;
              W0_bcnt            <= 0;
              w0div_cnt          <= 0;
          if((I_W0_en & (w0fifo_rst_done_r2 & w0_fs) )) begin
            if (O_W0_sync_cnt < W0YBUF_SIZE)
              O_W0_sync_cnt      <= O_W0_sync_cnt + 1'b1;
            else
              O_W0_sync_cnt      <= 0;
              W0_MS              <= S_RST;
          end
        end
        S_RST:begin
              O_fdma_w0bufn      <= I_W0_buf;
              W0_MS              <= S_DATA1;
        end
        S_DATA1: begin
          if (w0fifo_rst_done_r1 == 1'b0)
              W0_MS              <= S_IDLE;
          else if (I_fdma_wbusy == 1'b1&&ddr_write_mode==WDDDR_mode) begin
              W0_MS              <= S_DATA2;
          end
        end
        S_DATA2: begin
          if (I_fdma_wbusy == 1'b0&&ddr_write_mode==WDDDR_mode) begin
            if (W0_bcnt == W0Y_BURST_TIMES - 1'b1) begin
              O_W0_frame_done    <= 1'b1;
              O_W0_frame_bufn    <= O_fdma_w0bufn;
              W0_MS              <= S_IDLE;
            end else begin
              if(w0div_cnt < W0_XDIV - 1'b1)begin
                W0_addr          <= W0_addr + W0X_BURST_ADDR_INC;
                w0div_cnt        <= w0div_cnt + 1'b1;
              end else begin
                W0_addr          <= W0_addr + W0X_LAST_ADDR_INC;
                w0div_cnt        <= 0;
              end
                W0_bcnt          <= W0_bcnt + 1'b1;
                W0_MS            <= S_DATA1;
            end
          end
        end
        default: W0_MS           <= S_IDLE;
      endcase
    end
end




sfifo #(
.DATA_WIDTH_W(W0_DATAWIDTH),
.DATA_WIDTH_R(AXI_DATA_WIDTH),
.ADDR_WIDTH_W(W0_WR_DATA_COUNT_WIDTH),
.ADDR_WIDTH_R(W0_RD_DATA_COUNT_WIDTH),
.AL_FULL_NUM(W0FIFO_DEPTH-2),
.AL_EMPTY_NUM(2),
.SHOW_AHEAD_EN(1'b1) ,
.OUTREG_EN ("NOREG")
) w0_ISPbuf_fifo (
.rst          ((I_ui_rstn == 1'b0) | w0fifo_rst  ),
.clkw         (I_W0_wclk                         ),
.we           (w0fifo_wen                        ),
.di           (W0_tdata_r1                       ),
.full_flag    (O_W0_full                         ),
.afull        (W0_full_pro                       ),
.clkr         (I_ui_clk                         ),
.re           (I_fdma_w0valid                    ),
.dout         (O_fdma_w0data                     ),
.empty_flag   (W0_empty                          ),
.rdusedw      (W0_rcnt                           )
);



endmodule
