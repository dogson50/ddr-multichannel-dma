`timescale 1ns/1ps
// Simple async FIFO with optional width conversion (pack/unpack).
module sfifo #(
  parameter integer DATA_WIDTH_W = 32,
  parameter integer DATA_WIDTH_R = 32,
  parameter integer ADDR_WIDTH_W = 8,
  parameter integer ADDR_WIDTH_R = 8,
  parameter integer AL_FULL_NUM  = 0,
  parameter integer AL_EMPTY_NUM = 0,
  parameter integer SHOW_AHEAD_EN = 1,
  parameter         OUTREG_EN = "NOREG"
) (
  input  wire                         rst,
  input  wire                         clkw,
  input  wire                         we,
  input  wire [DATA_WIDTH_W-1:0]      di,
  output wire                         full_flag,
  output wire                         afull,
  input  wire                         clkr,
  input  wire                         re,
  output wire [DATA_WIDTH_R-1:0]      dout,
  output wire                         empty_flag,
  output wire [ADDR_WIDTH_R-1:0]      rdusedw,
  output wire [ADDR_WIDTH_W-1:0]      wrusedw
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

  localparam integer WIDE_W = (DATA_WIDTH_W >= DATA_WIDTH_R) ? DATA_WIDTH_W : DATA_WIDTH_R;
  localparam integer NARROW_W = (DATA_WIDTH_W >= DATA_WIDTH_R) ? DATA_WIDTH_R : DATA_WIDTH_W;
  localparam integer RATIO = (WIDE_W / NARROW_W);
  localparam integer RD_RATIO = (DATA_WIDTH_R < DATA_WIDTH_W) ? RATIO : 1;
  localparam integer FIFO_AW = (DATA_WIDTH_W >= DATA_WIDTH_R) ? ADDR_WIDTH_W : ADDR_WIDTH_R;
  localparam integer DEPTH = (1 << FIFO_AW);
  localparam integer CNT_AW = (RATIO <= 1) ? 1 : clog2(RATIO);
  localparam integer USED_AW = (ADDR_WIDTH_W >= ADDR_WIDTH_R) ? ADDR_WIDTH_W : ADDR_WIDTH_R;

  // --------------------------------------------------------------------------
  // Core async FIFO for wide words.
  // --------------------------------------------------------------------------
  (* ram_style = "block" *) reg [WIDE_W-1:0] mem [0:DEPTH-1];

  reg [FIFO_AW:0] wptr_bin;
  reg [FIFO_AW:0] wptr_gray;
  reg [FIFO_AW:0] rptr_bin;
  reg [FIFO_AW:0] rptr_gray;
  reg             fifo_full_r;

  (* ASYNC_REG = "TRUE" *) reg [FIFO_AW:0] rptr_gray_wsync1, rptr_gray_wsync2;
  (* ASYNC_REG = "TRUE" *) reg [FIFO_AW:0] wptr_gray_rsync1, wptr_gray_rsync2;

  wire [FIFO_AW:0] wptr_bin_inc   = wptr_bin + {{FIFO_AW{1'b0}}, 1'b1};
  wire [FIFO_AW:0] rptr_bin_next  = rptr_bin + {{FIFO_AW{1'b0}}, 1'b1};
  wire [FIFO_AW:0] rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;

  wire fifo_full  = fifo_full_r;
  wire fifo_empty = (rptr_gray == wptr_gray_rsync2);

  function [FIFO_AW:0] gray2bin;
    input [FIFO_AW:0] g;
    integer i;
    begin
      gray2bin[FIFO_AW] = g[FIFO_AW];
      for (i = FIFO_AW-1; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ g[i];
    end
  endfunction

  // --------------------------------------------------------------------------
  // Write-side packer (narrow -> wide) if needed.
  // --------------------------------------------------------------------------
  reg [CNT_AW-1:0] pack_cnt;
  reg [WIDE_W-1:0] pack_reg;

  wire pack_last = (RATIO <= 1) ? 1'b1 : (pack_cnt == (RATIO - 1));

  wire wr_accept = we && !full_flag;
  wire fifo_wr_en = (DATA_WIDTH_W >= DATA_WIDTH_R)
                      ? (we && !fifo_full_r)
                      : (wr_accept && pack_last);
  wire [FIFO_AW:0] wptr_bin_next = fifo_wr_en ? wptr_bin_inc : wptr_bin;
  wire [FIFO_AW:0] wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
  wire fifo_full_next =
      (wptr_gray_next == {~rptr_gray_wsync2[FIFO_AW:FIFO_AW-1], rptr_gray_wsync2[FIFO_AW-2:0]});
  reg [WIDE_W-1:0] pack_next;
  integer pack_i;

  always @(*) begin
    pack_next = pack_reg;
    if (DATA_WIDTH_W < DATA_WIDTH_R) begin
      for (pack_i = 0; pack_i < RATIO; pack_i = pack_i + 1) begin
        if (pack_cnt == pack_i)
          pack_next[(pack_i * DATA_WIDTH_W) +: DATA_WIDTH_W] = di;
      end
    end
  end

  wire [WIDE_W-1:0] fifo_wr_data = (DATA_WIDTH_W >= DATA_WIDTH_R) ? di : pack_next;

  always @(posedge clkw or posedge rst) begin
    if (rst) begin
      pack_cnt <= {CNT_AW{1'b0}};
      pack_reg <= {WIDE_W{1'b0}};
    end else if (DATA_WIDTH_W < DATA_WIDTH_R) begin
      if (wr_accept) begin
        pack_reg <= pack_last ? {WIDE_W{1'b0}} : pack_next;
        if (pack_last)
          pack_cnt <= {CNT_AW{1'b0}};
        else
          pack_cnt <= pack_cnt + 1'b1;
      end
    end
  end

  // Write pointer/memory update.
  always @(posedge clkw) begin
    if (fifo_wr_en)
      mem[wptr_bin[FIFO_AW-1:0]] <= fifo_wr_data;
  end

  always @(posedge clkw or posedge rst) begin
    if (rst) begin
      wptr_bin  <= {(FIFO_AW+1){1'b0}};
      wptr_gray <= {(FIFO_AW+1){1'b0}};
      fifo_full_r <= 1'b0;
    end else begin
      if (fifo_wr_en) begin
        wptr_bin  <= wptr_bin_next;
        wptr_gray <= wptr_gray_next;
      end
      fifo_full_r <= fifo_full_next;
    end
  end

  always @(posedge clkw or posedge rst) begin
    if (rst) begin
      rptr_gray_wsync1 <= {(FIFO_AW+1){1'b0}};
      rptr_gray_wsync2 <= {(FIFO_AW+1){1'b0}};
    end else begin
      rptr_gray_wsync1 <= rptr_gray;
      rptr_gray_wsync2 <= rptr_gray_wsync1;
    end
  end

  // --------------------------------------------------------------------------
  // Read-side prefetch + unpack (wide -> narrow) if needed.
  //
  // RD_RATIO <= 1 (pack or equal-width):
  //   Show-ahead via BRAM address offset, same pattern as udp_pkg_buf.
  //   BRAM always enabled, address = rptr + (re && !empty).
  //   dout = fifo_dout (1-cycle registered BRAM output).  No buf_valid FSM.
  //
  // RD_RATIO > 1 (unpack):
  //   Original buf_word + buf_index FSM for multi-cycle wide-word unpack.
  // --------------------------------------------------------------------------
  reg [WIDE_W-1:0] fifo_dout;
  reg [WIDE_W-1:0] buf_word;
  reg [CNT_AW-1:0] buf_index;
  reg              buf_valid;
  reg              prefetch_pending;
  reg              rd_empty_r;

  // ---- RD_RATIO <= 1 : show-ahead BRAM addressing ----
  wire              rd_empty   = (RD_RATIO <= 1) ? rd_empty_r : fifo_empty;
  wire              rd_consume = re && !rd_empty;     // valid read this cycle
  wire              fifo_rd_en = (RD_RATIO > 1) ? (!buf_valid && !prefetch_pending && !fifo_empty)
                                                : 1'b1;   // BRAM always enabled in show-ahead
  wire [FIFO_AW-1:0] bram_rd_addr_cur  = rptr_bin[FIFO_AW-1:0];
  wire [FIFO_AW-1:0] bram_rd_addr_next = rptr_bin_next[FIFO_AW-1:0];
  wire [FIFO_AW-1:0] bram_rd_addr =
      (RD_RATIO <= 1) ? (rd_consume ? bram_rd_addr_next : bram_rd_addr_cur) :
                        bram_rd_addr_cur;

  always @(posedge clkr) begin
    if (fifo_rd_en)
      fifo_dout <= mem[bram_rd_addr];
  end

  always @(posedge clkr or posedge rst) begin
    if (rst) begin
      rptr_bin          <= {(FIFO_AW+1){1'b0}};
      rptr_gray         <= {(FIFO_AW+1){1'b0}};
      wptr_gray_rsync1  <= {(FIFO_AW+1){1'b0}};
      wptr_gray_rsync2  <= {(FIFO_AW+1){1'b0}};
      buf_word          <= {WIDE_W{1'b0}};
      buf_index         <= {CNT_AW{1'b0}};
      buf_valid         <= 1'b0;
      prefetch_pending  <= 1'b0;
      rd_empty_r        <= 1'b1;
    end else begin
      wptr_gray_rsync1 <= wptr_gray;
      wptr_gray_rsync2 <= wptr_gray_rsync1;

      // ---- read-pointer advance ----
      if (RD_RATIO <= 1) begin
        if (rd_consume) begin
          rptr_bin  <= rptr_bin_next;
          rptr_gray <= rptr_gray_next;
          rd_empty_r <= (rptr_gray_next == wptr_gray_rsync2);
        end else begin
          rd_empty_r <= fifo_empty;
        end
      end else begin
        if (fifo_rd_en) begin
          rptr_bin        <= rptr_bin_next;
          rptr_gray       <= rptr_gray_next;
          prefetch_pending <= 1'b1;
        end
      end

      // ---- data-path / valid ----
      if (RD_RATIO <= 1) begin
        // empty_flag driven combinatorially by fifo_empty; nothing to do here
      end else begin
        // Multi-cycle wide word (unpack): original FSM.
        if (prefetch_pending) begin
          buf_word         <= fifo_dout;
          buf_index        <= {CNT_AW{1'b0}};
          buf_valid        <= 1'b1;
          prefetch_pending <= 1'b0;
        end else if (buf_valid && re) begin
          if (buf_index == (RD_RATIO - 1)) begin
            buf_valid <= 1'b0;
            buf_index <= {CNT_AW{1'b0}};
          end else begin
            buf_index <= buf_index + 1'b1;
          end
        end
      end
    end
  end

  // --------------------------------------------------------------------------
  // Status and outputs.
  // --------------------------------------------------------------------------
  wire [USED_AW:0] used_wide_w =
    {{(USED_AW-FIFO_AW){1'b0}}, wptr_bin} - {{(USED_AW-FIFO_AW){1'b0}}, gray2bin(rptr_gray_wsync2)};
  wire [USED_AW:0] used_wide_r =
    {{(USED_AW-FIFO_AW){1'b0}}, gray2bin(wptr_gray_rsync2)} - {{(USED_AW-FIFO_AW){1'b0}}, rptr_bin};

  wire [USED_AW:0] used_wr_words = (DATA_WIDTH_W >= DATA_WIDTH_R)
                                    ? used_wide_w
                                    : (used_wide_w * RATIO + pack_cnt);

  // rdusedw: for RD_RATIO<=1 the BRAM-address show-ahead has no extra
  // pipeline buffer (dout = fifo_dout, always one word in flight that
  // used_wide_r already accounts for), so no buf_valid correction needed.
  wire [USED_AW:0] used_rd_words = (DATA_WIDTH_R >= DATA_WIDTH_W)
                                    ? used_wide_r
                                    : (used_wide_r * RATIO + (buf_valid ? (RATIO - buf_index) : 0));

  wire [ADDR_WIDTH_W-1:0] used_wr_words_ext = used_wr_words;
  wire [ADDR_WIDTH_R-1:0] used_rd_words_ext = used_rd_words;

  assign wrusedw   = used_wr_words_ext;
  assign rdusedw   = used_rd_words_ext;

  assign full_flag = (DATA_WIDTH_W < DATA_WIDTH_R) ? (fifo_full && pack_last) : fifo_full;

  assign afull = (AL_FULL_NUM == 0) ? full_flag
               : (used_wide_w >= (DEPTH - AL_FULL_NUM));

  // empty_flag: combinatorial from fifo_empty when RD_RATIO<=1 (show-ahead),
  //             registered via buf_valid for the unpack path.
  assign empty_flag = (RD_RATIO <= 1) ? rd_empty_r : ~buf_valid;

  // dout: fifo_dout for RD_RATIO<=1 (single-cycle pipeline),
  //       buf_word with index slicing for the unpack path.
  assign dout = (RD_RATIO <= 1)
                  ? fifo_dout[DATA_WIDTH_R-1:0]
                  : ((DATA_WIDTH_R == WIDE_W)
                      ? buf_word[DATA_WIDTH_R-1:0]
                      : buf_word[(buf_index * DATA_WIDTH_R) +: DATA_WIDTH_R]);

endmodule
