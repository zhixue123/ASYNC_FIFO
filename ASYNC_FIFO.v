`timescale 1ns/1ns

module async_fifo
#(
  parameter DATA_WIDTH    = 16,
  parameter FIFO_DEPTH    = 8,
  parameter PTR_WIDTH     = 4,                // log2(FIFO_DEPTH) + 1
  parameter ADDR_WIDTH    = 3                 // log2(FIFO_DEPTH)
)
(
  // 复位信号
  input  wire                      wr_rst_n,
  input  wire                      rd_rst_n,

  // 写接口
  input  wire                      wr_clk,
  input  wire                      wr_en,
  input  wire    [DATA_WIDTH-1:0]  wr_data,

  // 读接口
  input  wire                      rd_clk,
  input  wire                      rd_en,
  output reg     [DATA_WIDTH-1:0]  rd_data,

  // 状态标志
  output reg                       full,
  output reg                       empty
);

// 存储器阵列
reg [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];

// 写指针
reg  [PTR_WIDTH-1:0] wr_ptr;
wire [PTR_WIDTH-1:0] wr_ptr_gray;
reg  [PTR_WIDTH-1:0] wr_ptr_gray_sync1;
reg  [PTR_WIDTH-1:0] wr_ptr_gray_sync2;

// 读指针
reg  [PTR_WIDTH-1:0] rd_ptr;
wire [PTR_WIDTH-1:0] rd_ptr_gray;
reg  [PTR_WIDTH-1:0] rd_ptr_gray_sync1;
reg  [PTR_WIDTH-1:0] rd_ptr_gray_sync2;

// 地址
wire [ADDR_WIDTH-1:0] wr_addr;
wire [ADDR_WIDTH-1:0] rd_addr;

// ==================== 写指针逻辑 ====================
always @(posedge wr_clk or negedge wr_rst_n) begin
  if (!wr_rst_n) begin
    wr_ptr <= 0;
  end
  else if (wr_en && !full) begin
    wr_ptr <= wr_ptr + 1;
  end
end

// 二进制转格雷码
assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

// 同步到读时钟域
always @(posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    wr_ptr_gray_sync1 <= 0;
    wr_ptr_gray_sync2 <= 0;
  end
  else begin
    wr_ptr_gray_sync1 <= wr_ptr_gray;
    wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
  end
end

// ==================== 读指针逻辑 ====================
always @(posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    rd_ptr <= 0;
  end
  else if (rd_en && !empty) begin
    rd_ptr <= rd_ptr + 1;
  end
end

// 二进制转格雷码
assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

// 同步到写时钟域
always @(posedge wr_clk or negedge wr_rst_n) begin
  if (!wr_rst_n) begin
    rd_ptr_gray_sync1 <= 0;
    rd_ptr_gray_sync2 <= 0;
  end
  else begin
    rd_ptr_gray_sync1 <= rd_ptr_gray;
    rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
  end
end

// ==================== 空满标志 ====================
// 满标志：写指针比读指针多一圈
wire [PTR_WIDTH-1:0] rd_ptr_bin_sync;
// 格雷码转二进制（同步后的读指针）
assign rd_ptr_bin_sync[PTR_WIDTH-1] = rd_ptr_gray_sync2[PTR_WIDTH-1];
generate
  genvar k;
  for (k = PTR_WIDTH-2; k >= 0; k = k-1) begin
    assign rd_ptr_bin_sync[k] = rd_ptr_bin_sync[k+1] ^ rd_ptr_gray_sync2[k];
  end
endgenerate

always @(posedge wr_clk or negedge wr_rst_n) begin
  if (!wr_rst_n) begin
    full <= 0;
  end
  else begin
    full <= ((wr_ptr - rd_ptr_bin_sync) >= FIFO_DEPTH);
  end
end

// 空标志：读写指针相等
always @(posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    empty <= 1;
  end
  else begin
    empty <= (rd_ptr == wr_ptr_gray_sync2);
  end
end

// ==================== 地址生成 ====================
assign wr_addr = wr_ptr[ADDR_WIDTH-1:0];
assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];

// ==================== 写操作 ====================
always @(posedge wr_clk) begin
  if (wr_en && !full) begin
    memory[wr_addr] <= wr_data;
  end
end

// ==================== 读操作 ====================
always @(posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    rd_data <= 0;
  end
  else if (rd_en && !empty) begin
    rd_data <= memory[rd_addr];
  end
end

endmodule