`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/05/04 18:28:14
// Design Name:
// Module Name: DMA4DDR_ctrl
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module DMA4DDR_ctrl_v1#(
    // ========== AXI 接口参数 ==========
    parameter integer AXI_DATA_WIDTH = 128,  // AXI 数据总线宽度 (128-bit)
    parameter integer AXI_ADDR_WIDTH = 32,   // AXI 地址总线宽度 (32-bit)

    // ========== 功能使能参数 ==========
    parameter integer ENABLE_VSYNC = 1,      // 是否启用垂直同步信号 (1=启用, 0=禁用)
    parameter integer ENABLE_W0 = 1,
    parameter integer ENABLE_W1 = 1,
    parameter integer ENABLE_W2 = 1,
    parameter integer ENABLE_W3 = 1,
    parameter integer ENABLE_R0 = 1,
    parameter integer ENABLE_R1 = 1,
    parameter integer ENABLE_R2 = 1,
    parameter integer ENABLE_R3 = 1,
    parameter integer ENABLE_R4 = 1,

    // ========== 写入路径 (W0_FIFO) 参数 ==========
    //AXIS视频数据写入接口参数
    parameter integer W0_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer W0_DATAWIDTH    = 32,    // 写入 FIFO 数据宽度 (32-bit)
    parameter [AXI_ADDR_WIDTH-1:0] W0_BASEADDR = 0,  // 写入缓冲区基地址
    parameter integer W0_DSIZEBITS    = 24,    // 地址偏移位宽 (用于计算 FDMA 地址)
    parameter integer W0_XSIZE        = 1920,  // X 方向图像宽度 (像素)
    parameter integer W0_XSTRIDE      = 1920,  // X 方向步长 (像素), 通常等于 XSIZE (无 padding)
    parameter integer W0_YSIZE        = 1080,  // Y 方向图像高度 (行)
    parameter integer W0_XDIV         = 2,     // X 方向分块因子 (每块 XSIZE/XDIV 像素)
    parameter integer W0_BUFSIZE      = 3,     // 写入缓冲区大小 (单位: 128 像素块)

    // ========== 写入路径 (W1_FIFO) 参数 ==========
    //AXIS普通数据写入接口参数
    parameter integer W1_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer W1_DATAWIDTH    = 32,    // 写入 FIFO 数据宽度 (32-bit)

    // ========== 写入路径 (W1_FIFO) 参数 ==========
    //AXIS普通数据写入接口参数
    parameter integer W2_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer W2_DATAWIDTH    = 32,    // 写入 FIFO 数据宽度 (32-bit)

    // ========== 写入路径 (W3_FIFO) 参数 ==========
    //AXIS视频数据写入接口参数
    parameter integer W3_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer W3_DATAWIDTH    = 32,    // 写入 FIFO 数据宽度 (32-bit)
    parameter [AXI_ADDR_WIDTH-1:0] W3_BASEADDR = 0,  // 写入缓冲区基地址
    parameter integer W3_DSIZEBITS    = 24,    // 地址偏移位宽 (用于计算 FDMA 地址)
    parameter integer W3_XSIZE        = 1920,  // X 方向图像宽度 (像素)
    parameter integer W3_XSTRIDE      = 1920,  // X 方向步长 (像素), 通常等于 XSIZE (无 padding)
    parameter integer W3_YSIZE        = 1080,  // Y 方向图像高度 (行)
    parameter integer W3_XDIV         = 2,     // X 方向分块因子 (每块 XSIZE/XDIV 像素)
    parameter integer W3_BUFSIZE      = 3,     // 写入缓冲区大小 (单位: 128 像素块)

    // ========== 读取路径 (R0_FIFO) 参数 ==========
    //AXIS视频数据读取接口参数
    parameter integer R0_BUFDEPTH     = 2048,  // 读取 FIFO 深度
    parameter integer R0_DATAWIDTH    = 32,    // 读取 FIFO 数据宽度
    parameter [AXI_ADDR_WIDTH-1:0] R0_BASEADDR = 0,  // 读取缓冲区基地址
    parameter integer R0_DSIZEBITS    = 24,    // 地址偏移位宽
    parameter integer R0_XSIZE        = 1920,  // 读取 X 方向宽度
    parameter integer R0_XSTRIDE      = 1920,  // 读取 X 方向步长
    parameter integer R0_YSIZE        = 1080,  // 读取 Y 方向高度
    parameter integer R0_XDIV         = 2,     // 读取 X 方向分块因子
    parameter integer R0_BUFSIZE      = 3,      // 读取缓冲区大小

    // ========== 读取路径 (R1_FIFO) 参数 ==========
    //AXIS视频数据读取接口参数
    parameter integer R1_BUFDEPTH     = 2048,  // 读取 FIFO 深度
    parameter integer R1_DATAWIDTH    = 32,    // 读取 FIFO 数据宽度
    parameter [AXI_ADDR_WIDTH-1:0] R1_BASEADDR = 0,  // 读取缓冲区基地址
    parameter integer R1_DSIZEBITS    = 24,    // 地址偏移位宽
    parameter integer R1_XSIZE        = 1920,  // 读取 X 方向宽度
    parameter integer R1_XSTRIDE      = 1920,  // 读取 X 方向步长
    parameter integer R1_YSIZE        = 1080,  // 读取 Y 方向高度
    parameter integer R1_XDIV         = 2,     // 读取 X 方向分块因子
    parameter integer R1_BUFSIZE      = 3,      // 读取缓冲区大小

    // ========== 读取路径 (R2_FIFO) 参数 ==========
    //AXIS普通数据读取接口参数
    parameter integer R2_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer R2_DATAWIDTH    = 32,    // 写入 FIFO 数据宽度 (32-bit)

     // ========== 读取路径 (R3_FIFO) 参数 ==========
    //AXIS普通数据读取接口参数
    parameter integer R3_BUFDEPTH     = 2048,  // 写入 FIFO 深度 (FIFO 存储单元数)
    parameter integer R3_DATAWIDTH    = 64,    // 写入 FIFO 数据宽度 (32-bit)

     // ========== 读取路径 (R4_FIFO) 参数 ==========
    //AXIS普通数据读取接口参数，默认8bit给UART字节流
    parameter integer R4_BUFDEPTH     = 2048,
    parameter integer R4_DATAWIDTH    = 8
) (
  // ========== 时钟/复位信号 ==========
    input  wire            I_ui_clk,      // 模块主时钟 (UI_CLK)
    input  wire            I_ui_rstn,     // 异步低有效复位
    input  wire            sys_rst_n,

    // ========== 写入路径 (W0_FIFO) 接口 ==========
    //AXIS视频数据写入接口
    input  wire            I_W0_en,        // 写入使能 (来自传感器)
    input  wire            I_W0_wclk,      // 写入 FIFO 时钟 (传感器时钟)
    input  wire            I_W0_tuser,     // 写入帧头标志 (1=帧头, 0=数据)
    input  wire            I_W0_tvalid,    // 写入数据有效
    input  wire [W0_DATAWIDTH-1:0] I_W0_tdata,  // 写入数据
    input  wire            I_W0_tlast,     // 写入帧尾标志
    output wire            O_W0_tready,    // 写入 FIFO 准备就绪 (始终为 1)
    output wire [7:0]       O_W0_sync_cnt,  // 写入缓冲区同步计数器 (用于帧同步)
    input  wire [7:0]      I_W0_buf,       // 写入缓冲区索引 (来自 FDMA)

   // ========== 写入路径 (W1_FIFO) 接口 ==========
   //AXIS视频数据写入接口
    input [AXI_ADDR_WIDTH-1:0] W1_addr_base,
    input [31:0]               W1_filesize,
    input                      W1_write_start,
    input                      I_W1_wclk,      // 写入 FIFO 时钟 (传感器时钟)
    input                      I_W1_tvalid,    // 写入数据有效
    input   [W1_DATAWIDTH-1:0] I_W1_tdata,  // 写入数据
    output                     O_W1_tready,
    output                     O_W1_done,
    output               [1:0] W1_MS,

    // ========== 写入路径 (W2_FIFO) 接口 ==========
    //AXIS视频数据写入接口
    input [AXI_ADDR_WIDTH-1:0] W2_addr_base,
    input [31:0]               W2_filesize,
    input                      W2_write_start,
    input                      I_W2_wclk,      // 写入 FIFO 时钟 (传感器时钟)
    input                      I_W2_tvalid,    // 写入数据有效
    input   [W2_DATAWIDTH-1:0] I_W2_tdata,  // 写入数据
    output                     O_W2_tready,
    output                     O_W2_done,
    output               [1:0] W2_MS,


    // ========== 写入路径 (W3_FIFO) 接口 ==========
    //AXIS视频数据写入接口
    input  wire            I_W3_en,        // 写入使能 (来自传感器)
    input  wire            I_W3_wclk,      // 写入 FIFO 时钟 (传感器时钟)
    input  wire            I_W3_tuser,     // 写入帧头标志 (1=帧头, 0=数据)
    input  wire            I_W3_tvalid,    // 写入数据有效
    input  wire [W3_DATAWIDTH-1:0] I_W3_tdata,  // 写入数据
    input  wire            I_W3_tlast,     // 写入帧尾标志
    output wire            O_W3_tready,    // 写入 FIFO 准备就绪 (始终为 1)
    output wire [7:0]       O_W3_sync_cnt,  // 写入缓冲区同步计数器 (用于帧同步)
    input  wire [7:0]      I_W3_buf,       // 写入缓冲区索引 (来自 FDMA)


      // ========== 读取路径 (R0_FIFO) 接口 ==========
      //AXIS视频数据读取接口
    input  wire            I_R0_en,        // 读取使能
    input  wire            I_R0sync_en,    // 帧同步使能 (用于同步)
    input  wire            I_R0_rclk,      // 读取 FIFO 时钟 (系统时钟)
    input  wire            I_R0_tready,    // 读取数据就绪
    output wire            O_R0_tuser,     // 读取帧头标志
    output wire            O_R0_tvalid,    // 读取数据有效
    output wire [R0_DATAWIDTH-1:0] O_R0_tdata,  // 读取数据
    output wire            O_R0_vrst,      // 读取复位信号 (用于 FIFO 同步)
    output wire            O_R0_tlast,     // 读取帧尾标志
    output wire [7:0]      O_R0_sync_cnt,  // 读取缓冲区同步计数器

    input  wire [7:0]      I_R0_buf,       // 读取缓冲区索引

    // ========== 读取路径 (R1_FIFO) 接口 ==========
    //AXIS视频数据读取接口
    input  wire            I_R1_en,        // 读取使能
    input  wire            I_R1sync_en,    // 帧同步使能 (用于同步)
    input  wire            I_R1_rclk,      // 读取 FIFO 时钟 (系统时钟)
    input  wire            I_R1_tready,    // 读取数据就绪
    output wire            O_R1_tuser,     // 读取帧头标志
    output wire            O_R1_tvalid,    // 读取数据有效
    output wire [R1_DATAWIDTH-1:0] O_R1_tdata,  // 读取数据
    output wire            O_R1_vrst,      // 读取复位信号 (用于 FIFO 同步)
    output wire            O_R1_tlast,     // 读取帧尾标志
    output wire [7:0]      O_R1_sync_cnt,  // 读取缓冲区同步计数器

    input  wire [7:0]      I_R1_buf,       // 读取缓冲区索引

    //AXIS普通数据读取接口
    input [AXI_ADDR_WIDTH-1:0]R2_addr_base,
    input [31:0]              R2_filesize,
    input R2_read_start,
    input  wire            I_R2_rclk,      // 读取 FIFO 时钟 (系统时钟)
    input  wire            I_R2_tready,    // 读取数据就绪
    output wire [R2_DATAWIDTH-1:0] O_R2_tdata,
    output [1:0]R2_MS,
    output [31:0]R2_rdusedw,

    //AXIS普通数据读取接口
    input [AXI_ADDR_WIDTH-1:0]R3_addr_base,
    input R3_read_start,
    input [31:0]R3_filesize,
    input  wire            I_R3_rclk,      // 读取 FIFO 时钟 (系统时钟)
    input  wire            I_R3_tready,    // 读取数据就绪
    output wire [R3_DATAWIDTH-1:0] O_R3_tdata,
    output [1:0]R3_MS,
    output wire O_R3_tvalid,
    output wire O_R3_tuser,
    output wire O_R3_tlast,

    //AXIS普通数据读取接口，预留给DDR->UART
    input [AXI_ADDR_WIDTH-1:0]R4_addr_base,
    input R4_read_start,
    input [31:0]R4_filesize,
    input  wire            I_R4_rclk,
    input  wire            I_R4_tready,
    output wire [R4_DATAWIDTH-1:0] O_R4_tdata,
    output [1:0]R4_MS,
    output wire O_R4_tvalid,
    output wire O_R4_tuser,
    output wire O_R4_tlast,
    output reg  O_R4_done,

  input  wire         M_AXI_ACLK,
  input  wire         M_AXI_ARESETn,
    output wire [3:0]   M_AXI_AWID,
    output wire [29:0]  M_AXI_AWADDR,
    output wire [7:0]   M_AXI_AWLEN,
    output wire [2:0]   M_AXI_AWSIZE,
    output wire [1:0]   M_AXI_AWBURST,
    output wire [0:0]   M_AXI_AWLOCK,
    output wire [3:0]   M_AXI_AWCACHE,
    output wire [2:0]   M_AXI_AWPROT,
    output wire [3:0]   M_AXI_AWQOS,
    output wire         M_AXI_AWVALID,
  input  wire         M_AXI_AWREADY,
    output wire [127:0] M_AXI_WDATA,
    output wire [15:0]  M_AXI_WSTRB,
    output wire         M_AXI_WLAST,
    output wire         M_AXI_WVALID,
  input  wire         M_AXI_WREADY,
  input  wire [3:0]   M_AXI_BID,
  input  wire [1:0]   M_AXI_BRESP,
  input  wire         M_AXI_BVALID,
    output wire         M_AXI_BREADY,
    output wire [3:0]   M_AXI_ARID,
    output wire [29:0]  M_AXI_ARADDR,
    output wire [7:0]   M_AXI_ARLEN,
    output wire [2:0]   M_AXI_ARSIZE,
    output wire [1:0]   M_AXI_ARBURST,
    output wire [0:0]   M_AXI_ARLOCK,
    output wire [3:0]   M_AXI_ARCACHE,
    output wire [2:0]   M_AXI_ARPROT,
    output wire [3:0]   M_AXI_ARQOS,
    output wire         M_AXI_ARVALID,
  input  wire         M_AXI_ARREADY,
  input  wire [3:0]   M_AXI_RID,
  input  wire [127:0] M_AXI_RDATA,
  input  wire [1:0]   M_AXI_RRESP,
  input  wire         M_AXI_RLAST,
  input  wire         M_AXI_RVALID,
    output wire         M_AXI_RREADY
    );


 // ========== 辅助函数: 计算 log2(N) ==========
function integer clog2;
    input integer value;
    begin
        for (clog2 = 0; value > 0; clog2 = clog2 + 1) value = value >> 1;
    end
endfunction


localparam    S_IDLE  = 2'd0;
localparam    S_RST   = 2'd1;
localparam    S_DATA1 = 2'd2;
localparam    S_DATA2 = 2'd3;

// ========== 写入路径关键参数计算 ==========
//isp写入ddr路径参数
localparam W0FIFO_DEPTH          = W0_BUFDEPTH;  // 写入 FIFO 深度
localparam W0_WR_DATA_COUNT_WIDTH = clog2(W0FIFO_DEPTH);  // 写端 FIFO 深度位宽
localparam W0_RD_DATA_COUNT_WIDTH = clog2(W0FIFO_DEPTH * W0_DATAWIDTH / AXI_DATA_WIDTH);// 读端 FIFO 深度 (考虑 AXI 数据宽度与 FIFO 宽度比)
localparam W0YBUF_SIZE = (W0_BUFSIZE - 1);  // 写入缓冲区大小 (单位: 128 像素块)
localparam W0Y_BURST_TIMES = (W0_YSIZE * W0_XDIV);  // 总 Burst 次数 (Y方向 * X分块)
localparam FDMA_W0X_BURST = (W0_XSIZE * W0_DATAWIDTH / AXI_DATA_WIDTH) / W0_XDIV;
// 每次 FDMA Burst 的 AXI 数据单元数 (X方向分块后)
localparam W0X_BURST_ADDR_INC = (W0_XSIZE * (W0_DATAWIDTH/8)) / W0_XDIV;
// 每次 Burst 的地址增量 (字节单位)
localparam W0X_LAST_ADDR_INC = (W0_XSTRIDE - W0_XSIZE) * (W0_DATAWIDTH/8) + W0X_BURST_ADDR_INC;
// 每行结束后的偏移量 (含 stride)

//Core写入ddr路径
localparam W1FIFO_DEPTH          = W1_BUFDEPTH;  // 写入 FIFO 深度
localparam W1_WR_DATA_COUNT_WIDTH = clog2(W1FIFO_DEPTH);  // 写端 FIFO 深度位宽
localparam W1_RD_DATA_COUNT_WIDTH = clog2(W1FIFO_DEPTH * W1_DATAWIDTH / AXI_DATA_WIDTH);

//sd写入ddr路径
localparam W2FIFO_DEPTH          = W2_BUFDEPTH;  // 写入 FIFO 深度
localparam W2_WR_DATA_COUNT_WIDTH = clog2(W2FIFO_DEPTH);  // 写端 FIFO 深度位宽
localparam W2_RD_DATA_COUNT_WIDTH = clog2(W2FIFO_DEPTH * W2_DATAWIDTH / AXI_DATA_WIDTH);

// ========== 写入路径关键参数计算 ==========
//isp写入ddr路径参数
localparam W3FIFO_DEPTH          = W3_BUFDEPTH;  // 写入 FIFO 深度
localparam W3_WR_DATA_COUNT_WIDTH = clog2(W3FIFO_DEPTH);  // 写端 FIFO 深度位宽
localparam W3_RD_DATA_COUNT_WIDTH = clog2(W3FIFO_DEPTH * W3_DATAWIDTH / AXI_DATA_WIDTH);// 读端 FIFO 深度 (考虑 AXI 数据宽度与 FIFO 宽度比)
localparam W3YBUF_SIZE = (W3_BUFSIZE - 1);  // 写入缓冲区大小 (单位: 128 像素块)
localparam W3Y_BURST_TIMES = (W3_YSIZE * W3_XDIV);  // 总 Burst 次数 (Y方向 * X分块)
localparam FDMA_W3X_BURST = (W3_XSIZE * W3_DATAWIDTH / AXI_DATA_WIDTH) / W3_XDIV;
// 每次 FDMA Burst 的 AXI 数据单元数 (X方向分块后)
localparam W3X_BURST_ADDR_INC = (W3_XSIZE * (W3_DATAWIDTH/8)) / W3_XDIV;
// 每次 Burst 的地址增量 (字节单位)
localparam W3X_LAST_ADDR_INC = (W3_XSTRIDE - W3_XSIZE) * (W3_DATAWIDTH/8) + W3X_BURST_ADDR_INC;

localparam R0YBUF_SIZE = (R0_BUFSIZE - 1'b1);
localparam R0Y_BURST_TIMES             = (R0_YSIZE*R0_XDIV);
localparam FDMA_R0X_BURST              = (R0_XSIZE*R0_DATAWIDTH/AXI_DATA_WIDTH)/R0_XDIV;
localparam R0X_BURST_ADDR_INC          = (R0_XSIZE*(R0_DATAWIDTH/8))/R0_XDIV;
localparam R0X_LAST_ADDR_INC           = (R0_XSTRIDE-R0_XSIZE)*(R0_DATAWIDTH/8) + R0X_BURST_ADDR_INC;

localparam R0FIFO_DEPTH                = R0_BUFDEPTH*R0_DATAWIDTH/AXI_DATA_WIDTH;
localparam R0_WR_DATA_COUNT_WIDTH      = clog2(R0FIFO_DEPTH);
localparam R0_RD_DATA_COUNT_WIDTH      = clog2(R0_BUFDEPTH);

localparam R1YBUF_SIZE = (R1_BUFSIZE - 1'b1);
localparam R1Y_BURST_TIMES             = (R1_YSIZE*R1_XDIV);
localparam FDMA_R1X_BURST              = (R1_XSIZE*R1_DATAWIDTH/AXI_DATA_WIDTH)/R1_XDIV;
localparam R1X_BURST_ADDR_INC          = (R1_XSIZE*(R1_DATAWIDTH/8))/R1_XDIV;
localparam R1X_LAST_ADDR_INC           = (R1_XSTRIDE-R1_XSIZE)*(R1_DATAWIDTH/8) + R1X_BURST_ADDR_INC;

localparam R1FIFO_DEPTH                = R1_BUFDEPTH*R1_DATAWIDTH/AXI_DATA_WIDTH;
localparam R1_WR_DATA_COUNT_WIDTH      = clog2(R1FIFO_DEPTH);
localparam R1_RD_DATA_COUNT_WIDTH      = clog2(R1_BUFDEPTH);

localparam R2FIFO_DEPTH                = R2_BUFDEPTH*R2_DATAWIDTH/AXI_DATA_WIDTH;
localparam R2_WR_DATA_COUNT_WIDTH      = clog2(R2FIFO_DEPTH);
localparam R2_RD_DATA_COUNT_WIDTH      = clog2(R2_BUFDEPTH);

localparam R3FIFO_DEPTH                = R3_BUFDEPTH*R3_DATAWIDTH/AXI_DATA_WIDTH;
localparam R3_WR_DATA_COUNT_WIDTH      = clog2(R3FIFO_DEPTH);
localparam R3_RD_DATA_COUNT_WIDTH      = clog2(R3_BUFDEPTH);

localparam R4FIFO_DEPTH                = R4_BUFDEPTH*R4_DATAWIDTH/AXI_DATA_WIDTH;
localparam R4_WR_DATA_COUNT_WIDTH      = clog2(R4FIFO_DEPTH);
localparam R4_RD_DATA_COUNT_WIDTH      = clog2(R4_BUFDEPTH);

localparam integer UI_FDMA_ADDR_WIDTH = 30;
localparam integer UI_FDMA_ID_WIDTH = 4;

wire [AXI_ADDR_WIDTH-1:0] O_fdma_waddr;
wire O_fdma_wareq;
wire [15:0] O_fdma_wsize;
wire I_fdma_wbusy;
wire [AXI_DATA_WIDTH-1:0] O_fdma_wdata;
wire I_fdma_wvalid;
wire O_fdma_wready;

wire [AXI_ADDR_WIDTH-1:0] O_fdma_raddr;
wire O_fdma_rareq;
wire [15:0] O_fdma_rsize;
wire I_fdma_rbusy;
wire [AXI_DATA_WIDTH-1:0] I_fdma_rdata;
wire I_fdma_rvalid;
wire O_fdma_rready;

wire O_fdma_wirq;
wire O_fdma_rirq;
reg  [7:0] O_fdma_wbuf;
reg  [7:0] O_fdma_rbuf;


reg           O_fdma_wareq_r      = 1'b0;
assign O_fdma_wareq = O_fdma_wareq_r;
reg           O_fdma_rareq_r      = 1'b0;
assign        O_fdma_rareq         = O_fdma_rareq_r;








reg [3:0]ddr_write_mode;
localparam isp2ddr_mode=0,
           core2ddr_mode=1,
           sd2ddr_mode=2,
           resize2ddr_mode=3,
           accel2ddr_mode=4;
reg [3:0]ddr_read_mode;
localparam ddr2lcd_mode=0,
           ddr2udp_mode=1,
           ddr2core_mode=2,
           ddr2accel_mode=3,
           ddr2uart_mode=4;
// 语义化通道命名（不改变原模式编码）
localparam WR_MODE_CAM0_TO_DDR = isp2ddr_mode;     // W0
localparam WR_MODE_CPU_TO_DDR  = core2ddr_mode;    // W1
localparam WR_MODE_SD_TO_DDR   = sd2ddr_mode;      // W2
localparam WR_MODE_CAM1_TO_DDR = resize2ddr_mode;  // W3
localparam RD_MODE_DDR_TO_LCD  = ddr2lcd_mode;     // R0
localparam RD_MODE_DDR_TO_UDP  = ddr2udp_mode;     // R1
localparam RD_MODE_DDR_TO_CPU  = ddr2core_mode;    // R2
localparam RD_MODE_DDR_TO_SD   = ddr2accel_mode;   // R3
localparam RD_MODE_DDR_TO_UART = ddr2uart_mode;    // R4
reg [AXI_DATA_WIDTH-1:0] I_fdma_r0data;reg I_fdma_r0valid;
always @(posedge I_ui_clk)
if(ddr_read_mode==ddr2lcd_mode)
begin
I_fdma_r0valid<=I_fdma_rvalid;
I_fdma_r0data<=I_fdma_rdata;
end
else I_fdma_r0valid<=0;


reg [AXI_DATA_WIDTH-1:0] I_fdma_r1data;reg I_fdma_r1valid;
always @(posedge I_ui_clk)
if(ddr_read_mode==ddr2udp_mode)
begin
I_fdma_r1valid<=I_fdma_rvalid;
I_fdma_r1data<=I_fdma_rdata;
end
else I_fdma_r1valid<=0;

reg [AXI_DATA_WIDTH-1:0] I_fdma_r2data;reg I_fdma_r2valid;
always @(posedge I_ui_clk)
if(ddr_read_mode==ddr2core_mode)
begin
I_fdma_r2valid<=I_fdma_rvalid;
I_fdma_r2data<=I_fdma_rdata;
end
else I_fdma_r2valid<=0;

reg [AXI_DATA_WIDTH-1:0] I_fdma_r3data;reg I_fdma_r3valid;
always @(posedge I_ui_clk)
if(ddr_read_mode==ddr2accel_mode)
begin
I_fdma_r3valid<=I_fdma_rvalid;
I_fdma_r3data<=I_fdma_rdata;
end
else I_fdma_r3valid<=0;

reg [AXI_DATA_WIDTH-1:0] I_fdma_r4data;reg I_fdma_r4valid;
always @(posedge I_ui_clk)
if(ddr_read_mode==ddr2uart_mode)
begin
I_fdma_r4valid<=I_fdma_rvalid;
I_fdma_r4data<=I_fdma_rdata;
end
else I_fdma_r4valid<=0;

wire I_fdma_w0valid;wire [AXI_DATA_WIDTH-1:0] O_fdma_w0data;
assign I_fdma_w0valid=(ddr_write_mode==isp2ddr_mode)?I_fdma_wvalid:0;

wire I_fdma_w1valid;wire [AXI_DATA_WIDTH-1:0] O_fdma_w1data;
assign I_fdma_w1valid=(ddr_write_mode==core2ddr_mode)?I_fdma_wvalid:0;

wire I_fdma_w2valid;wire [AXI_DATA_WIDTH-1:0] O_fdma_w2data;
assign I_fdma_w2valid=(ddr_write_mode==sd2ddr_mode)?I_fdma_wvalid:0;

wire I_fdma_w3valid;wire [AXI_DATA_WIDTH-1:0] O_fdma_w3data;
assign I_fdma_w3valid=(ddr_write_mode==resize2ddr_mode)?I_fdma_wvalid:0;
reg [AXI_DATA_WIDTH-1:0] O_fdma_wdata_r;
always@(*)
case(ddr_write_mode)
isp2ddr_mode:O_fdma_wdata_r=O_fdma_w0data;
core2ddr_mode:O_fdma_wdata_r=O_fdma_w1data;
sd2ddr_mode:O_fdma_wdata_r=O_fdma_w2data;
resize2ddr_mode:O_fdma_wdata_r=O_fdma_w3data;
endcase
assign O_fdma_wdata=O_fdma_wdata_r;





reg [5 : 0]   wirq_dly_cnt        = 0;
// 例化WFIFO_VIDEO模块，实例名为u_WFIFO_VIDEO
wire [7 : 0]   O_fdma_w0bufn;
wire           O_w0_frame_done;
wire [7:0]     O_w0_frame_bufn;
wire  [                         1 : 0]   W0_MS;//synthesis keep
wire  [            W0_DSIZEBITS-1'b1:0]   W0_addr;
wire  [1 :0] W0_MS_r;
wire W0_REQ;
generate
if (ENABLE_W0 != 0) begin : g_w0_enabled
WFIFO_VIDEO#(
    .W0_DSIZEBITS         (W0_DSIZEBITS),          // 地址位宽（示例：8个地址空间）
    .W0_WR_DATA_COUNT_WIDTH(W0_WR_DATA_COUNT_WIDTH),         // 写数据计数宽度（示例：最大31）
    .W0_DATAWIDTH          (W0_DATAWIDTH),       // 输入数据宽度（示例：128bit）
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH),       // AXI数据宽度（保持定义的256bit）
    .ENABLE_VSYNC          (ENABLE_VSYNC),         // 使能场同步（1=使能）
    .W0YBUF_SIZE           (W0YBUF_SIZE),         // Y缓冲区大小（示例：3个缓冲区）
    .W0Y_BURST_TIMES       (W0Y_BURST_TIMES),         // Y方向突发次数（示例：4次）
    .W0_XDIV               (W0_XDIV),         // X方向分频（示例：2分频）
    .W0X_BURST_ADDR_INC    (W0X_BURST_ADDR_INC),        // X方向突发地址增量（示例：64）
    .W0X_LAST_ADDR_INC     (W0X_LAST_ADDR_INC),        // X方向最后一次突发地址增量（示例：32）
    .FDMA_W0X_BURST        (FDMA_W0X_BURST),        // FDMA的X方向突发长度（示例：16）
    .W0_XSIZE              (W0_XSIZE),      // X方向尺寸（示例：1024像素）
    .W0_YSIZE              (W0_YSIZE),       // Y方向尺寸（示例：768像素）
    .W0_RD_DATA_COUNT_WIDTH(W0_RD_DATA_COUNT_WIDTH),         // 读数据计数宽度（示例：最大31）
    .W0FIFO_DEPTH          (W0FIFO_DEPTH),      // FIFO深度（示例：1024）
    .WDDDR_mode            (isp2ddr_mode)          // DDR模式（0=默认模式）
) u_W0FIFO_VIDEO (
    .I_ui_clk              (I_ui_clk),   // 系统UI时钟（例：100MHz）
    .I_ui_rstn             (I_ui_rstn),  // 系统复位（低有效）
    .O_fdma_w0data         (O_fdma_w0data), // FDMA写入数据总线
    .I_fdma_w0valid        (I_fdma_w0valid),// FDMA写入有效信号
    .ddr_write_mode        (ddr_write_mode),  // DDR写入模式（例：来自配置寄存器）
    .W0_MS                 (W0_MS),     // W0模式选择输出
    .W0_addr               (W0_addr),   // W0地址输出
    .O_fdma_w0bufn         (O_fdma_w0bufn),// FDMA缓冲区索引输出
    .W0_REQ                (W0_REQ),    // W0请求信号输出
    .W0_MS_r               (W0_MS_r),   // W0模式选择寄存器输出
    .I_fdma_wbusy          (I_fdma_wbusy),// FDMA忙信号输入
    .I_W0_en               (I_W0_en),// 传感器写入使能输入
    .I_W0_wclk             (I_W0_wclk),// 传感器时钟（写入FIFO时钟）
    .I_W0_tuser            (I_W0_tuser),// 传感器帧头标志（1=帧头）
    .I_W0_tvalid           (I_W0_tvalid),// 传感器数据有效
    .I_W0_tdata            (I_W0_tdata),// 传感器输入数据
    .I_W0_tlast            (I_W0_tlast),// 传感器帧尾标志
    .O_W0_tready           (O_W0_tready), // FIFO准备就绪输出（接传感器ready）
    .O_W0_sync_cnt         (O_W0_sync_cnt),// 缓冲区同步计数器输出
    .I_W0_buf              (I_W0_buf),// FDMA提供的缓冲区索引输入
    .O_W0_frame_done       (O_w0_frame_done),
    .O_W0_frame_bufn       (O_w0_frame_bufn)
);
end else begin : g_w0_disabled
    assign O_fdma_w0data = {AXI_DATA_WIDTH{1'b0}};
    assign O_fdma_w0bufn = 8'd0;
    assign O_w0_frame_done = 1'b0;
    assign O_w0_frame_bufn = 8'd0;
    assign W0_MS = S_IDLE;
    assign W0_addr = {W0_DSIZEBITS{1'b0}};
    assign W0_MS_r = S_IDLE;
    assign W0_REQ = 1'b0;
    assign O_W0_tready = 1'b0;
    assign O_W0_sync_cnt = 8'd0;
end
endgenerate


wire  [AXI_ADDR_WIDTH-1'b1:0]   W1_addr;
wire  [1 :0] W1_MS_r;
wire W1_REQ;
wire [15:0] W1_burst_size_auto;
wire [7:0] W1_sync_cnt_unused;
wire [7:0] W1_bufn_unused;
// W1: CPU普通AXIS写DDR（走WFIFOdma）
WFIFOdma_v1 #(
    .W0_DSIZEBITS           (AXI_ADDR_WIDTH),
    .W0_DATAWIDTH           (W1_DATAWIDTH),
    .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
    .ENABLE_VSYNC           (ENABLE_VSYNC),
    .AXI_ADDR_WIDTH         (AXI_ADDR_WIDTH),
    .W0_RD_DATA_COUNT_WIDTH (W1_RD_DATA_COUNT_WIDTH),
    .W0FIFO_DEPTH           (W1FIFO_DEPTH),
    .WDDDR_mode             (core2ddr_mode)
) u_wfifo_dma_w1 (
    .I_ui_clk        (I_ui_clk),
    .I_ui_rstn       (I_ui_rstn),
    .O_fdma_w0data   (O_fdma_w1data),
    .I_fdma_w0valid  (I_fdma_w1valid),
    .ddr_write_mode  (ddr_write_mode),
    .W0_addr_base    (W1_addr_base),
    .W0_filesize     (W1_filesize),
    .W0_write_start  (W1_write_start),
    .W0_MS           (W1_MS),
    .W0_addr         (W1_addr),
    .O_fdma_w0bufn   (W1_bufn_unused),
    .W0_REQ          (W1_REQ),
    .W0_MS_r         (W1_MS_r),
    .O_W0_burst_size (W1_burst_size_auto),
    .I_fdma_wbusy    (I_fdma_wbusy),
    .I_W0_en         (1'b1),
    .I_W0_wclk       (I_W1_wclk),
    .I_W0_tuser      (1'b0),
    .I_W0_tvalid     (I_W1_tvalid),
    .I_W0_tdata      (I_W1_tdata),
    .I_W0_tlast      (1'b0),
    .O_W0_tready     (O_W1_tready),
    .O_W0_sync_cnt   (W1_sync_cnt_unused),
    .I_W0_buf        (8'd0)
);

assign O_W1_done = (W1_MS_r == S_DATA2) && (W1_MS == S_IDLE);



wire  [AXI_ADDR_WIDTH-1'b1:0]   W2_addr;
wire  [1 :0] W2_MS_r;
wire W2_REQ;
wire [15:0] W2_burst_size_auto;
wire [7:0] W2_sync_cnt_unused;
wire [7:0] W2_bufn_unused;

// W2: SD普通AXIS写DDR（走WFIFOdma）
generate
if (ENABLE_W2 != 0) begin : g_w2_enabled
WFIFOdma_v1 #(
    .W0_DSIZEBITS           (AXI_ADDR_WIDTH),
    .W0_DATAWIDTH           (W2_DATAWIDTH),
    .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
    .ENABLE_VSYNC           (ENABLE_VSYNC),
    .AXI_ADDR_WIDTH         (AXI_ADDR_WIDTH),
    .W0_RD_DATA_COUNT_WIDTH (W2_RD_DATA_COUNT_WIDTH),
    .W0FIFO_DEPTH           (W2FIFO_DEPTH),
    .WDDDR_mode             (sd2ddr_mode)
) u_wfifo_dma_w2 (
    .I_ui_clk        (I_ui_clk),
    .I_ui_rstn       (I_ui_rstn),
    .O_fdma_w0data   (O_fdma_w2data),
    .I_fdma_w0valid  (I_fdma_w2valid),
    .ddr_write_mode  (ddr_write_mode),
    .W0_addr_base    (W2_addr_base),
    .W0_filesize     (W2_filesize),
    .W0_write_start  (W2_write_start),
    .W0_MS           (W2_MS),
    .W0_addr         (W2_addr),
    .O_fdma_w0bufn   (W2_bufn_unused),
    .W0_REQ          (W2_REQ),
    .W0_MS_r         (W2_MS_r),
    .O_W0_burst_size (W2_burst_size_auto),
    .I_fdma_wbusy    (I_fdma_wbusy),
    .I_W0_en         (1'b1),
    .I_W0_wclk       (I_W2_wclk),
    .I_W0_tuser      (1'b0),
    .I_W0_tvalid     (I_W2_tvalid),
    .I_W0_tdata      (I_W2_tdata),
    .I_W0_tlast      (1'b0),
    .O_W0_tready     (O_W2_tready),
    .O_W0_sync_cnt   (W2_sync_cnt_unused),
    .I_W0_buf        (8'd0)
);
end else begin : g_w2_disabled
    assign W2_addr = {AXI_ADDR_WIDTH{1'b0}};
    assign W2_MS_r = S_IDLE;
    assign W2_REQ = 1'b0;
    assign W2_burst_size_auto = 16'd0;
    assign W2_sync_cnt_unused = 8'd0;
    assign W2_bufn_unused = 8'd0;
    assign O_fdma_w2data = {AXI_DATA_WIDTH{1'b0}};
    assign W2_MS = S_IDLE;
    assign O_W2_tready = 1'b0;
end
endgenerate

assign O_W2_done = (W2_MS_r == S_DATA2) && (W2_MS == S_IDLE);


// 例化WFIFO_VIDEO模块，实例名为u_WFIFO_VIDEO
wire  [7 : 0]   O_fdma_w3bufn;
wire           O_w3_frame_done;
wire [7:0]     O_w3_frame_bufn;
wire  [1 : 0]   W3_MS;//synthesis keep
wire  [W3_DSIZEBITS-1'b1:0]   W3_addr;
wire  [1 :0] W3_MS_r;
wire W3_REQ;
/*
WFIFO_VIDEO#(
     .W0_DSIZEBITS         (W3_DSIZEBITS),          // 地址位宽（示例：8个地址空间）
    .W0_WR_DATA_COUNT_WIDTH(W3_WR_DATA_COUNT_WIDTH),         // 写数据计数宽度（示例：最大31）
    .W0_DATAWIDTH          (W3_DATAWIDTH),       // 输入数据宽度（示例：128bit）
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH),       // AXI数据宽度（保持定义的256bit）
    .ENABLE_VSYNC          (ENABLE_VSYNC),         // 使能场同步（1=使能）
    .W0YBUF_SIZE           (W3YBUF_SIZE),         // Y缓冲区大小（示例：3个缓冲区）
    .W0Y_BURST_TIMES       (W3Y_BURST_TIMES),         // Y方向突发次数（示例：4次）
    .W0_XDIV               (W3_XDIV),         // X方向分频（示例：2分频）
    .W0X_BURST_ADDR_INC    (W3X_BURST_ADDR_INC),        // X方向突发地址增量（示例：64）
    .W0X_LAST_ADDR_INC     (W3X_LAST_ADDR_INC),        // X方向最后一次突发地址增量（示例：32）
    .FDMA_W0X_BURST        (FDMA_W3X_BURST),        // FDMA的X方向突发长度（示例：16）
    .W0_XSIZE              (W3_XSIZE),      // X方向尺寸（示例：1024像素）
    .W0_YSIZE              (W3_YSIZE),       // Y方向尺寸（示例：768像素）
    .W0_RD_DATA_COUNT_WIDTH(W3_RD_DATA_COUNT_WIDTH),         // 读数据计数宽度（示例：最大31）
    .W0FIFO_DEPTH          (W3FIFO_DEPTH),      // FIFO深度（示例：1024）
    .WDDDR_mode            (resize2ddr_mode)          // DDR模式（0=默认模式）
) u_W3FIFO_VIDEO (
    .I_ui_clk              (I_ui_clk),   // 系统UI时钟（例：100MHz）
    .I_ui_rstn             (I_ui_rstn),  // 系统复位（低有效）
    .O_fdma_w0data         (O_fdma_w3data), // FDMA写入数据总线
    .I_fdma_w0valid        (I_fdma_w3valid),// FDMA写入有效信号
    .ddr_write_mode        (ddr_write_mode),  // DDR写入模式（例：来自配置寄存器）
    .W0_MS                 (W3_MS),     // W0模式选择输出
    .W0_addr               (W3_addr),   // W0地址输出
    .O_fdma_w0bufn         (O_fdma_w3bufn),// FDMA缓冲区索引输出
    .W0_REQ                (W3_REQ),    // W0请求信号输出
    .W0_MS_r               (W3_MS_r),   // W0模式选择寄存器输出
    .I_fdma_wbusy          (I_fdma_wbusy),// FDMA忙信号输入
    .I_W0_en               (I_W3_en),// 传感器写入使能输入
    .I_W0_wclk             (I_W3_wclk),// 传感器时钟（写入FIFO时钟）
    .I_W0_tuser            (I_W3_tuser),// 传感器帧头标志（1=帧头）
    .I_W0_tvalid           (I_W3_tvalid),// 传感器数据有效
    .I_W0_tdata            (I_W3_tdata),// 传感器输入数据
    .I_W0_tlast            (I_W3_tlast),// 传感器帧尾标志
    .O_W0_tready           (O_W3_tready), // FIFO准备就绪输出（接传感器ready）
    .O_W0_sync_cnt         (O_W3_sync_cnt),// 缓冲区同步计数器输出
    .I_W0_buf              (I_W3_buf)// FDMA提供的缓冲区索引输入
);

*/
generate
if (ENABLE_W3 != 0) begin : g_w3_enabled
WFIFO_VIDEO #(
    .W0_DSIZEBITS          (W3_DSIZEBITS),
    .W0_WR_DATA_COUNT_WIDTH(W3_WR_DATA_COUNT_WIDTH),
    .W0_DATAWIDTH          (W3_DATAWIDTH),
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH),
    .ENABLE_VSYNC          (ENABLE_VSYNC),
    .W0YBUF_SIZE           (W3YBUF_SIZE),
    .W0Y_BURST_TIMES       (W3Y_BURST_TIMES),
    .W0_XDIV               (W3_XDIV),
    .W0X_BURST_ADDR_INC    (W3X_BURST_ADDR_INC),
    .W0X_LAST_ADDR_INC     (W3X_LAST_ADDR_INC),
    .FDMA_W0X_BURST        (FDMA_W3X_BURST),
    .W0_XSIZE              (W3_XSIZE),
    .W0_YSIZE              (W3_YSIZE),
    .W0_RD_DATA_COUNT_WIDTH(W3_RD_DATA_COUNT_WIDTH),
    .W0FIFO_DEPTH          (W3FIFO_DEPTH),
    .WDDDR_mode            (resize2ddr_mode)
) u_W3FIFO_VIDEO (
    .I_ui_clk       (I_ui_clk),
    .I_ui_rstn      (I_ui_rstn),
    .O_fdma_w0data  (O_fdma_w3data),
    .I_fdma_w0valid (I_fdma_w3valid),
    .ddr_write_mode (ddr_write_mode),
    .W0_MS          (W3_MS),
    .W0_addr        (W3_addr),
    .O_fdma_w0bufn  (O_fdma_w3bufn),
    .W0_REQ         (W3_REQ),
    .W0_MS_r        (W3_MS_r),
    .I_fdma_wbusy   (I_fdma_wbusy),
    .I_W0_en        (I_W3_en),
    .I_W0_wclk      (I_W3_wclk),
    .I_W0_tuser     (I_W3_tuser),
    .I_W0_tvalid    (I_W3_tvalid),
    .I_W0_tdata     (I_W3_tdata),
    .I_W0_tlast     (I_W3_tlast),
    .O_W0_tready    (O_W3_tready),
    .O_W0_sync_cnt  (O_W3_sync_cnt),
    .I_W0_buf       (I_W3_buf),
    .O_W0_frame_done(O_w3_frame_done),
    .O_W0_frame_bufn(O_w3_frame_bufn)
);
end else begin : g_w3_disabled
    assign O_fdma_w3bufn = 8'd0;
    assign O_w3_frame_done = 1'b0;
    assign O_w3_frame_bufn = 8'd0;
    assign W3_MS = S_IDLE;
    assign W3_addr = {W3_DSIZEBITS{1'b0}};
    assign W3_MS_r = S_IDLE;
    assign W3_REQ = 1'b0;
    assign O_fdma_w3data = {AXI_DATA_WIDTH{1'b0}};
    assign O_W3_tready = 1'b0;
    assign O_W3_sync_cnt = 8'd0;
end
endgenerate

always @(posedge I_ui_clk) begin
    if (I_ui_rstn == 1'b0) begin
              wirq_dly_cnt      <= 6'd0;
              O_fdma_wbuf       <= 0;
    end else if ((W0_MS_r == S_DATA2) && (W0_MS == S_IDLE)) begin
              wirq_dly_cnt      <= 60;
              O_fdma_wbuf       <= O_fdma_w0bufn;
    end else if ((W3_MS_r == S_DATA2) && (W3_MS == S_IDLE)) begin
              wirq_dly_cnt      <= 60;
              O_fdma_wbuf       <= O_fdma_w3bufn;
    end else if (wirq_dly_cnt > 0)
              wirq_dly_cnt      <= wirq_dly_cnt - 1'b1;
end







reg  [                         5 : 0]   rirq_dly_cnt = 0;
// 重要提示：R0_XDIV 必须固定为 0！若动态变化会导致图像左右偏移持续漂移
// R0_X_BURST_ADDR_INC 必须与 R0_XSIZE 一致（通常为 1），否则数据读取偏移
wire [7 : 0]   O_fdma_r0bufn;
wire  [                         1 : 0]   R0_MS;//synthesis keep
wire  [            R0_DSIZEBITS-1'b1:0]   R0_addr;
wire  [1 :0] R0_MS_r;
wire R0_REQ;
generate
if (ENABLE_R0 != 0) begin : g_r0_enabled
RFIFO_VIDEO #(
    .R0_DSIZEBITS          (R0_DSIZEBITS),          // 数据宽度位宽（通常为0，由R0_DATAWIDTH决定）
    .R0_WR_DATA_COUNT_WIDTH  (R0_WR_DATA_COUNT_WIDTH),          // 写入计数位宽（通常为0）
    .R0_DATAWIDTH          (R0_DATAWIDTH),           // ★★ 关键：图像数据位宽（如RGB888=24bit）
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH),          // ★★ 与传输端一致（如256bit）
    .ENABLE_VSYNC          (ENABLE_VSYNC),            // 使能帧同步（需与传输端一致）
    .R0YBUF_SIZE           (R0YBUF_SIZE),            // Y轴缓冲区大小（按需调整）
    .R0Y_BURST_TIMES       (R0Y_BURST_TIMES),            // Y轴突发次数（通常0）
    .R0_XDIV               (R0_XDIV),            // ★★★★★★★★★★★★★★★★★★★★★★★★★★
    .R0X_BURST_ADDR_INC    (R0X_BURST_ADDR_INC),            // ★★★★★★★★★★★★★★★★★★★★★★★★★★
    .R0X_LAST_ADDR_INC     (R0X_LAST_ADDR_INC),            // 通常为1
    .FDMA_R0X_BURST        (FDMA_R0X_BURST),            // 突发传输使能（按需设）
    .R0_XSIZE              (R0_XSIZE),         // ★★ 图像X分辨率（如1920）
    .R0_YSIZE              (R0_YSIZE),         // ★★ 图像Y分辨率（如1080）
    .R0_RD_DATA_COUNT_WIDTH(R0_RD_DATA_COUNT_WIDTH),            // 读取计数位宽
    .R0FIFO_DEPTH          (R0FIFO_DEPTH),           // FIFO深度（按需调整）
    .RDDDR_mode            (ddr2lcd_mode),            // 时钟模式（通常0）
    .STRICT_FRAME_COMMIT   (1)
) u_r0fifo_video (
    .I_ui_clk             (I_ui_clk),      // 系统时钟
    .I_ui_rstn            (I_ui_rstn),      // 低有效复位
    .I_fdma_r0data        (I_fdma_r0data),   // 以太网接收数据（256bit）
    .I_fdma_r0valid       (I_fdma_r0valid),  // 数据有效
    .ddr_read_mode        (ddr_read_mode),
    .R0_MS                (R0_MS),       // 读取使能（输出）
    .R0_addr              (R0_addr),     // 读取地址（输出）
    .O_fdma_r0bufn        (O_fdma_r0bufn), // 写使能（输出）
    .I_fdma_rbusy         (I_fdma_rbusy),
    .R0_REQ               (R0_REQ),      // 请求信号（输出）
    .R0_MS_r              (R0_MS_r),     // 读取使能复位（输出）
    .I_R0_en              (I_R0_en),        // 读取使能（固定使能）
    .I_R0sync_en          (I_R0sync_en), // 帧同步使能
    .I_R0_rclk            (I_R0_rclk),      // 读取时钟（需与I_ui_clk同步）
    .I_R0_tready          (I_R0_tready),     // 数据就绪（输入）
    .O_R0_tuser           (O_R0_tuser),    // 帧头标志
    .O_R0_tvalid          (O_R0_tvalid),   // 数据有效
    .O_R0_tdata           (O_R0_tdata),    // 读取数据（24bit）
    .O_R0_vrst            (O_R0_vrst),     // 读取复位
    .O_R0_tlast           (O_R0_tlast),    // 帧尾标志
    .O_R0_sync_cnt        (O_R0_sync_cnt),   // 同步计数器
    .I_R0_buf             (I_R0_buf),
    .I_R0_frame_done      (O_w0_frame_done),
    .I_R0_frame_bufn      (O_w0_frame_bufn)
);
end else begin : g_r0_disabled
    assign O_fdma_r0bufn = 8'd0;
    assign R0_MS = S_IDLE;
    assign R0_addr = {R0_DSIZEBITS{1'b0}};
    assign R0_MS_r = S_IDLE;
    assign R0_REQ = 1'b0;
    assign O_R0_tuser = 1'b0;
    assign O_R0_tvalid = 1'b0;
    assign O_R0_tdata = {R0_DATAWIDTH{1'b0}};
    assign O_R0_vrst = 1'b0;
    assign O_R0_tlast = 1'b0;
    assign O_R0_sync_cnt = 8'd0;
end
endgenerate


wire [7 : 0]   O_fdma_r1bufn;
wire  [                         1 : 0]   R1_MS;//synthesis keep
wire  [            R1_DSIZEBITS-1'b1:0]   R1_addr;
wire  [1 :0] R1_MS_r;
wire R1_REQ;
generate
if (ENABLE_R1 != 0) begin : g_r1_enabled
RFIFO_VIDEO #(
    .R0_DSIZEBITS          (R1_DSIZEBITS),          // 数据宽度位宽（通常为0，由R0_DATAWIDTH决定）
    .R0_WR_DATA_COUNT_WIDTH  (R1_WR_DATA_COUNT_WIDTH),          // 写入计数位宽（通常为0）
    .R0_DATAWIDTH          (R1_DATAWIDTH),           // ★★ 关键：图像数据位宽（如RGB888=24bit）
    .AXI_DATA_WIDTH        (AXI_DATA_WIDTH),          // ★★ 与传输端一致（如256bit）
    .ENABLE_VSYNC          (ENABLE_VSYNC),            // 使能帧同步（需与传输端一致）
    .R0YBUF_SIZE           (R1YBUF_SIZE),            // Y轴缓冲区大小（按需调整）
    .R0Y_BURST_TIMES       (R1Y_BURST_TIMES),            // Y轴突发次数（通常0）
    .R0_XDIV               (R1_XDIV),            // ★★★★★★★★★★★★★★★★★★★★★★★★★★
    .R0X_BURST_ADDR_INC    (R1X_BURST_ADDR_INC),            // ★★★★★★★★★★★★★★★★★★★★★★★★★★
    .R0X_LAST_ADDR_INC     (R1X_LAST_ADDR_INC),            // 通常为1
    .FDMA_R0X_BURST        (FDMA_R1X_BURST),            // 突发传输使能（按需设）
    .R0_XSIZE              (R1_XSIZE),         // ★★ 图像X分辨率（如1920）
    .R0_YSIZE              (R1_YSIZE),         // ★★ 图像Y分辨率（如1080）
    .R0_RD_DATA_COUNT_WIDTH(R1_RD_DATA_COUNT_WIDTH),            // 读取计数位宽
    .R0FIFO_DEPTH          (R1FIFO_DEPTH),           // FIFO深度（按需调整）
    .RDDDR_mode            (ddr2udp_mode),            // 时钟模式（通常0）
    .STRICT_FRAME_COMMIT   (1)
) u_r1fifo_video (
    .I_ui_clk             (I_ui_clk),      // 系统时钟
    .I_ui_rstn            (I_ui_rstn),      // 低有效复位
    .I_fdma_r0data        (I_fdma_r1data),   // 以太网接收数据（256bit）
    .I_fdma_r0valid       (I_fdma_r1valid),  // 数据有效
    .ddr_read_mode        (ddr_read_mode),
    .R0_MS                (R1_MS),       // 读取使能（输出）
    .R0_addr              (R1_addr),     // 读取地址（输出）
    .O_fdma_r0bufn        (O_fdma_r1bufn), // 写使能（输出）
    .I_fdma_rbusy         (I_fdma_rbusy),
    .R0_REQ               (R1_REQ),      // 请求信号（输出）
    .R0_MS_r              (R1_MS_r),     // 读取使能复位（输出）
    .I_R0_en              (I_R1_en),        // 读取使能（固定使能）
    .I_R0sync_en          (I_R1sync_en), // 帧同步使能
    .I_R0_rclk            (I_R1_rclk),      // 读取时钟（需与I_ui_clk同步）
    .I_R0_tready          (I_R1_tready),     // 数据就绪（输入）
    .O_R0_tuser           (O_R1_tuser),    // 帧头标志
    .O_R0_tvalid          (O_R1_tvalid),   // 数据有效
    .O_R0_tdata           (O_R1_tdata),    // 读取数据（24bit）
    .O_R0_vrst            (O_R1_vrst),     // 读取复位
    .O_R0_tlast           (O_R1_tlast),    // 帧尾标志
    .O_R0_sync_cnt        (O_R1_sync_cnt),   // 同步计数器
    .I_R0_buf             (I_R1_buf),
    .I_R0_frame_done      (O_w3_frame_done),
    .I_R0_frame_bufn      (O_w3_frame_bufn)
);
end else begin : g_r1_disabled
    assign O_fdma_r1bufn = 8'd0;
    assign R1_MS = S_IDLE;
    assign R1_addr = {R1_DSIZEBITS{1'b0}};
    assign R1_MS_r = S_IDLE;
    assign R1_REQ = 1'b0;
    assign O_R1_tuser = 1'b0;
    assign O_R1_tvalid = 1'b0;
    assign O_R1_tdata = {R1_DATAWIDTH{1'b0}};
    assign O_R1_vrst = 1'b0;
    assign O_R1_tlast = 1'b0;
    assign O_R1_sync_cnt = 8'd0;
end
endgenerate

always @(posedge I_ui_clk) begin
  if (I_ui_rstn == 1'b0) begin
              rirq_dly_cnt        <= 6'd0;
              O_fdma_rbuf         <= 0;
  end else if ((R0_MS_r == S_DATA2) && (R0_MS == S_IDLE)) begin
              rirq_dly_cnt        <= 60;
              O_fdma_rbuf         <= O_fdma_r0bufn;
  end else if ((R1_MS_r == S_DATA2) && (R1_MS == S_IDLE)) begin
              rirq_dly_cnt        <= 60;
              O_fdma_rbuf         <= O_fdma_r1bufn;
  end else if (rirq_dly_cnt > 0)
              rirq_dly_cnt        <= rirq_dly_cnt - 1'b1;
end


wire  [AXI_ADDR_WIDTH-1'b1:0]   R2_addr;
wire  [1 :0] R2_MS_r;
wire R2_REQ;
wire [15:0] R2_burst_size_auto;
wire [R2_RD_DATA_COUNT_WIDTH-1:0] r2_rdusedw_int;
generate
if (ENABLE_R2 != 0) begin : g_r2_enabled
RFIFOdma_v1 #(
    .R0_WR_DATA_COUNT_WIDTH(R2_WR_DATA_COUNT_WIDTH),
    .R0_DATAWIDTH(R2_DATAWIDTH),           // ★★ 关键：图像数据位宽（RGB888=24bit）
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),        // ★★ 与传输端一致（必须为256）
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),         // ★★ 地址总线宽度（通常32位）
    .ENABLE_VSYNC(ENABLE_VSYNC),            // ★★ 必须为1（使能帧同步）
    .R0_RD_DATA_COUNT_WIDTH(R2_RD_DATA_COUNT_WIDTH),
    .R0FIFO_DEPTH(R2FIFO_DEPTH),           // FIFO深度（按需调整）
    .RDDDR_mode(ddr2core_mode)
) u_rfifo_dma_r2 (
    .I_ui_clk         (I_ui_clk),    // 系统时钟
    .I_ui_rstn        (I_ui_rstn),      // 低有效复位
    .I_fdma_r0data    (I_fdma_r2data), // 以太网接收数据（256bit）
    .I_fdma_r0valid   (I_fdma_r2valid), // 数据有效
    .ddr_read_mode    (ddr_read_mode),     // 读取模式（通常0）
    .R0_MS            (R2_MS),       // 读取使能（输出）
    .R0_addr          (R2_addr),     // 读取地址（输出）
    .R0_addr_base     (R2_addr_base), //
    .R0_read_start    (R2_read_start),
    .R0_filesize      (R2_filesize),
    // 1920x1080@24bit: (1920*1080*24)/(256*15) = 12960 = 0x32A0
    .R0_REQ           (R2_REQ),      // 请求信号（输出）
    .R0_MS_r          (R2_MS_r),     // 读取使能复位（输出）
    .O_R0_burst_size  (R2_burst_size_auto),
    .I_fdma_rbusy     (I_fdma_rbusy),        // DMA忙信号（通常0）
    .I_R0_rclk        (I_R2_rclk),    // 读取FIFO时钟
    .I_R0_tready      (I_R2_tready),   // 数据就绪（输入）
    .O_R0_tdata       (O_R2_tdata),   // 读取数据（24bit）
    .R0_rdusedw     (r2_rdusedw_int)
);
end else begin : g_r2_disabled
    assign R2_addr = {AXI_ADDR_WIDTH{1'b0}};
    assign R2_MS_r = S_IDLE;
    assign R2_REQ = 1'b0;
    assign R2_burst_size_auto = 16'd0;
    assign r2_rdusedw_int = {R2_RD_DATA_COUNT_WIDTH{1'b0}};
    assign R2_MS = S_IDLE;
    assign O_R2_tdata = {R2_DATAWIDTH{1'b0}};
end
endgenerate
        assign R2_rdusedw = {32{1'b0}} | r2_rdusedw_int;



wire  [            AXI_ADDR_WIDTH-1'b1:0]   R3_addr;
wire  [1 :0] R3_MS_r;
wire R3_REQ;
wire [15:0] R3_burst_size_auto;
RFIFOdma_v1
#(
    // -------------------------- 必配参数（根据系统调整）--------------------------
    .R0_WR_DATA_COUNT_WIDTH(R3_WR_DATA_COUNT_WIDTH),    // R0 FIFO 写侧已用深度位宽（需 ≥ log2(R0FIFO_DEPTH)）
    .R0_DATAWIDTH(R3_DATAWIDTH),             // R0 FIFO 数据位宽（建议与 AXI_DATA_WIDTH 一致）
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),           // AXI 数据总线位宽（固定 256，与模块定义一致）
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),           // AXI 地址总线位宽（固定 256，与模块定义一致）
    .ENABLE_VSYNC(ENABLE_VSYNC),               // 使能 VSYNC 同步（1=使能，0=禁用）
    .R0_RD_DATA_COUNT_WIDTH(R3_RD_DATA_COUNT_WIDTH),    // R0 FIFO 读侧已用深度位宽（需 ≥ log2(R0FIFO_DEPTH)）
    .R0FIFO_DEPTH(R3FIFO_DEPTH),            // R0 FIFO 深度（建议为 2 的幂，如 512/1024/2048）
    .RDDDR_mode(ddr2accel_mode)                  // DDR 读取模式（0=默认模式，需根据 DDR 控制器配置）
)
u_RFIFOdma
(
    // -------------------------- 时钟与复位 --------------------------
    .I_ui_clk(I_ui_clk),            // UI 时钟（如 100MHz/200MHz，需与 AXI 时钟同步）
    .I_ui_rstn(I_ui_rstn),          // UI 复位（低有效，同步于 I_ui_clk）

    // -------------------------- FDMA 数据输入 --------------------------
    .I_fdma_r0data(I_fdma_r3data),  // FDMA 输出的 R0 数据（位宽=AXI_DATA_WIDTH）
    .I_fdma_r0valid(I_fdma_r3valid),// FDMA R0 数据有效信号（高有效）
    .I_fdma_rbusy(I_fdma_rbusy),    // FDMA 忙信号（高表示 FDMA 正在传输）

    // -------------------------- DDR 控制信号 --------------------------
    .ddr_read_mode(ddr_read_mode),  // DDR 读取模式选择（4bit 控制信号）

    // -------------------------- 地址与突发配置 --------------------------
    .R0_addr_base(R3_addr_base),    // R0 读取基地址（256bit，来自配置寄存器）
    .R0_filesize(R3_filesize),      // R0 文件大小（31bit，单位：8字节）

    // -------------------------- 控制信号 --------------------------
    .R0_read_start(R3_read_start),  // R0 读取启动信号（高有效，脉冲触发）

    // -------------------------- 输出信号 --------------------------
    .R0_MS(R3_MS),                  // R0 模式选择信号（2bit，模块输出）
    .R0_addr(R3_addr),              // R0 读取地址（256bit，模块输出）
    .R0_REQ(R3_REQ),                // R0 读取请求（高有效，模块输出）
    .R0_MS_r(R3_MS_r),              // R0 模式选择寄存器（2bit，模块输出）
    .O_R0_burst_size(R3_burst_size_auto),
    .R0_rdusedw(),        // R0 FIFO 读侧已用深度（位宽=R0_RD_DATA_COUNT_WIDTH）

    // -------------------------- FIFO 读取接口（系统时钟域）--------------------------
    .I_R0_rclk(I_R3_rclk),          // R0 FIFO 读时钟（系统时钟，如 100MHz）
    .I_R0_tready(I_R3_tready),      // 下游模块就绪信号（高表示可接收数据）
    .O_R0_tdata(O_R3_tdata),        // R0 FIFO 输出数据（位宽=R0_DATAWIDTH）
    .O_R0_tvalid(O_R3_tvalid),
    .O_R0_tlast(O_R3_tlast),
    .O_R0_tuser(O_R3_tuser),
    .O_R0_done()           // R0 读取完成信号（高有效，脉冲输出）
);


wire  [            AXI_ADDR_WIDTH-1'b1:0]   R4_addr;
wire  [1 :0] R4_MS_r;
wire R4_REQ;
wire [15:0] R4_burst_size_auto;
generate
if (ENABLE_R4 != 0) begin : g_r4_enabled
RFIFOdma_v1
#(
    .R0_WR_DATA_COUNT_WIDTH(R4_WR_DATA_COUNT_WIDTH),
    .R0_DATAWIDTH(R4_DATAWIDTH),
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .ENABLE_VSYNC(ENABLE_VSYNC),
    .R0_RD_DATA_COUNT_WIDTH(R4_RD_DATA_COUNT_WIDTH),
    .R0FIFO_DEPTH(R4FIFO_DEPTH),
    .RDDDR_mode(ddr2uart_mode)
)
u_RFIFOdma_r4
(
    .I_ui_clk(I_ui_clk),
    .I_ui_rstn(I_ui_rstn),
    .I_fdma_r0data(I_fdma_r4data),
    .I_fdma_r0valid(I_fdma_r4valid),
    .I_fdma_rbusy(I_fdma_rbusy),
    .ddr_read_mode(ddr_read_mode),
    .R0_addr_base(R4_addr_base),
    .R0_filesize(R4_filesize),
    .R0_read_start(R4_read_start),
    .R0_MS(R4_MS),
    .R0_addr(R4_addr),
    .R0_REQ(R4_REQ),
    .R0_MS_r(R4_MS_r),
    .O_R0_burst_size(R4_burst_size_auto),
    .R0_rdusedw(),
    .I_R0_rclk(I_R4_rclk),
    .I_R0_tready(I_R4_tready),
    .O_R0_tdata(O_R4_tdata),
    .O_R0_tvalid(O_R4_tvalid),
    .O_R0_tlast(O_R4_tlast),
    .O_R0_tuser(O_R4_tuser),
    .O_R0_done()
);
end else begin : g_r4_disabled
    assign R4_addr = {AXI_ADDR_WIDTH{1'b0}};
    assign R4_MS_r = S_IDLE;
    assign R4_REQ = 1'b0;
    assign R4_burst_size_auto = 16'd0;
    assign R4_MS = S_IDLE;
    assign O_R4_tdata = {R4_DATAWIDTH{1'b0}};
    assign O_R4_tvalid = 1'b0;
    assign O_R4_tlast = 1'b0;
    assign O_R4_tuser = 1'b0;
end
endgenerate

always @(posedge I_R4_rclk or negedge sys_rst_n) begin
  if (!sys_rst_n) begin
    O_R4_done <= 1'b0;
  end else if (R4_read_start) begin
    O_R4_done <= 1'b0;
  end else if (O_R4_tvalid && I_R4_tready && O_R4_tlast) begin
    O_R4_done <= 1'b1;
  end else if (O_R4_tvalid && I_R4_tready && O_R4_tuser) begin
    O_R4_done <= 1'b0;
  end
end

reg [3:0]WR_S;//synthesis keep
localparam IDLE=0,
           WDDR_REQ=1,
           WDDR=2,
           RDDR_REQ=3,
           RDDR=4,
           DDR_WAIT=5;

reg  [15:0]O_fdma_wsize_r;
reg  [15:0]O_fdma_rsize_r;
reg [AXI_ADDR_WIDTH-1:0]O_fdma_waddr_r,O_fdma_raddr_r;
always @(posedge I_ui_clk) begin
  if(!I_ui_rstn)begin
              WR_S            <= 2'd0;
              O_fdma_wareq_r  <= 1'd0;
              O_fdma_rareq_r  <= 1'd0;
              O_fdma_wsize_r  <= 16'd0;
              O_fdma_rsize_r  <= 16'd0;
              O_fdma_waddr_r  <= {AXI_ADDR_WIDTH{1'b0}};
              O_fdma_raddr_r  <= {AXI_ADDR_WIDTH{1'b0}};
              ddr_write_mode<=core2ddr_mode;
              ddr_read_mode<=ddr2core_mode;
  end
  else begin
    case(WR_S)
    IDLE:begin
     if(I_fdma_wbusy == 1'b0 && W0_REQ && W0_MS == S_DATA1)begin
              O_fdma_wsize_r<=FDMA_W0X_BURST;
              O_fdma_waddr_r<=W0_BASEADDR + {O_fdma_w0bufn,W0_addr};
               ddr_write_mode<=isp2ddr_mode;
              WR_S            <= WDDR_REQ;
      end
         else if(I_fdma_rbusy == 1'b0 && R0_REQ  && R0_MS == S_DATA1)begin
            O_fdma_rsize_r<=FDMA_R0X_BURST;
            O_fdma_raddr_r<=R0_BASEADDR + {O_fdma_r0bufn,R0_addr};
            ddr_read_mode<=ddr2lcd_mode;
            WR_S            <= RDDR_REQ;
           end
         else if(I_fdma_rbusy == 1'b0 && R1_REQ  && R1_MS == S_DATA1)begin
            O_fdma_rsize_r<=FDMA_R1X_BURST;
            O_fdma_raddr_r<=R1_BASEADDR + {O_fdma_r1bufn,R1_addr};
            ddr_read_mode<=ddr2udp_mode;
            WR_S            <= RDDR_REQ;
          end
      else  if(I_fdma_wbusy == 1'b0 && W1_REQ && W1_MS == S_DATA1)begin
              O_fdma_wsize_r<=W1_burst_size_auto;
              O_fdma_waddr_r<=W1_addr_base+W1_addr;
               ddr_write_mode<=core2ddr_mode;
              WR_S            <= WDDR_REQ;
     end
     else if(I_fdma_wbusy == 1'b0 && W2_REQ && W2_MS == S_DATA1)begin
              O_fdma_wsize_r<=W2_burst_size_auto;
              O_fdma_waddr_r<=W2_addr_base+W2_addr;
               ddr_write_mode<=sd2ddr_mode;
              WR_S            <= WDDR_REQ;
     end
     else if(I_fdma_wbusy == 1'b0 && W3_REQ && W3_MS == S_DATA1)begin
              O_fdma_wsize_r<=FDMA_W3X_BURST;
              O_fdma_waddr_r<=W3_BASEADDR + {O_fdma_w3bufn,W3_addr};
               ddr_write_mode<=resize2ddr_mode;
              WR_S            <= WDDR_REQ;
     end
     else if(I_fdma_rbusy == 1'b0 && R2_REQ  && R2_MS == S_DATA1)begin
              O_fdma_rsize_r<=R2_burst_size_auto;
              O_fdma_raddr_r<=R2_addr_base+R2_addr;
              ddr_read_mode<=ddr2core_mode;
              WR_S            <= RDDR_REQ;
      end
     else if(I_fdma_rbusy == 1'b0 && R3_REQ  && R3_MS == S_DATA1)begin
              O_fdma_rsize_r<=R3_burst_size_auto;
              O_fdma_raddr_r<=R3_addr_base+R3_addr;
              ddr_read_mode<=ddr2accel_mode;
              WR_S            <= RDDR_REQ;
      end
     else if(I_fdma_rbusy == 1'b0 && R4_REQ  && R4_MS == S_DATA1)begin
              O_fdma_rsize_r<=R4_burst_size_auto;
              O_fdma_raddr_r<=R4_addr_base+R4_addr;
              ddr_read_mode<=ddr2uart_mode;
              WR_S            <= RDDR_REQ;
      end





    end
    WDDR_REQ: begin
              O_fdma_wareq_r  <= 1'b1;
              WR_S            <= WDDR;
    end

    WDDR:begin
      if(I_fdma_wbusy == 1'b1) begin
              O_fdma_wareq_r  <= 1'b0;
              WR_S            <= DDR_WAIT;
      end
    end

    RDDR_REQ: begin
              O_fdma_rareq_r  <= 1'b1;
              WR_S            <= RDDR;
    end

    RDDR:begin
      if(I_fdma_rbusy == 1'b1) begin
              O_fdma_rareq_r  <= 1'b0;
              WR_S            <= DDR_WAIT;
      end
    end


    DDR_WAIT:begin
      if(I_fdma_wbusy==0&&I_fdma_rbusy==0)
              WR_S            <= 0;
      end
    default:  WR_S            <= 0;
    endcase
    end
end

assign    O_fdma_wirq         = (wirq_dly_cnt > 0);
assign    O_fdma_rirq         = (rirq_dly_cnt > 0);



assign O_fdma_wready = 1'b1;
assign O_fdma_rready = 1'b1;
assign O_fdma_wsize        = O_fdma_wsize_r;
assign O_fdma_rsize        = O_fdma_rsize_r;

assign    O_fdma_waddr        = O_fdma_waddr_r;

assign    O_fdma_raddr        = O_fdma_raddr_r;

uiFDMA #(
    .M_AXI_B2B_SET(1),
    .M_AXI_ID_WIDTH(UI_FDMA_ID_WIDTH),
    .M_AXI_ID(0),
    .M_AXI_ADDR_WIDTH(UI_FDMA_ADDR_WIDTH),
    .M_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
    .M_AXI_MAX_BURST_LEN(16)
) u_uiFDMA (
    .I_fdma_waddr(O_fdma_waddr[UI_FDMA_ADDR_WIDTH-1:0]),
    .I_fdma_wareq(O_fdma_wareq),
    .I_fdma_wsize(O_fdma_wsize),
    .O_fdma_wbusy(I_fdma_wbusy),
    .I_fdma_wdata(O_fdma_wdata),
    .O_fdma_wvalid(I_fdma_wvalid),
    .I_fdma_wready(O_fdma_wready),
    .I_fdma_raddr(O_fdma_raddr[UI_FDMA_ADDR_WIDTH-1:0]),
    .I_fdma_rareq(O_fdma_rareq),
    .I_fdma_rsize(O_fdma_rsize),
    .O_fdma_rbusy(I_fdma_rbusy),
    .O_fdma_rdata(I_fdma_rdata),
    .O_fdma_rvalid(I_fdma_rvalid),
    .I_fdma_rready(O_fdma_rready),
    .M_AXI_ACLK(M_AXI_ACLK),
    .M_AXI_ARESETN(M_AXI_ARESETn),
    .M_AXI_AWID(M_AXI_AWID),
    .M_AXI_AWADDR(M_AXI_AWADDR),
    .M_AXI_AWLEN(M_AXI_AWLEN),
    .M_AXI_AWSIZE(M_AXI_AWSIZE),
    .M_AXI_AWBURST(M_AXI_AWBURST),
    .M_AXI_AWLOCK(M_AXI_AWLOCK),
    .M_AXI_AWCACHE(M_AXI_AWCACHE),
    .M_AXI_AWPROT(M_AXI_AWPROT),
    .M_AXI_AWQOS(M_AXI_AWQOS),
    .M_AXI_AWVALID(M_AXI_AWVALID),
    .M_AXI_AWREADY(M_AXI_AWREADY),
    .M_AXI_WID(),
    .M_AXI_WDATA(M_AXI_WDATA),
    .M_AXI_WSTRB(M_AXI_WSTRB),
    .M_AXI_WLAST(M_AXI_WLAST),
    .M_AXI_WVALID(M_AXI_WVALID),
    .M_AXI_WREADY(M_AXI_WREADY),
    .M_AXI_BID(M_AXI_BID),
    .M_AXI_BRESP(M_AXI_BRESP),
    .M_AXI_BVALID(M_AXI_BVALID),
    .M_AXI_BREADY(M_AXI_BREADY),
    .M_AXI_ARID(M_AXI_ARID),
    .M_AXI_ARADDR(M_AXI_ARADDR),
    .M_AXI_ARLEN(M_AXI_ARLEN),
    .M_AXI_ARSIZE(M_AXI_ARSIZE),
    .M_AXI_ARBURST(M_AXI_ARBURST),
    .M_AXI_ARLOCK(M_AXI_ARLOCK),
    .M_AXI_ARCACHE(M_AXI_ARCACHE),
    .M_AXI_ARPROT(M_AXI_ARPROT),
    .M_AXI_ARQOS(M_AXI_ARQOS),
    .M_AXI_ARVALID(M_AXI_ARVALID),
    .M_AXI_ARREADY(M_AXI_ARREADY),
    .M_AXI_RID(M_AXI_RID),
    .M_AXI_RDATA(M_AXI_RDATA),
    .M_AXI_RRESP(M_AXI_RRESP),
    .M_AXI_RLAST(M_AXI_RLAST),
    .M_AXI_RVALID(M_AXI_RVALID),
    .M_AXI_RREADY(M_AXI_RREADY)
);



endmodule
