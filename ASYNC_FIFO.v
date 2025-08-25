`timescale 1ns/1ns

module async_fifo
#(
  parameter DATA_WIDTH    = 16,
  parameter FIFO_DEPTH    = 8,               
  parameter ADDR_WIDTH    = 3                 
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
  output wire                       full,
  output wire                      empty
);


reg [DATA_WIDTH-1:0] memory [0:FIFO_DEPTH-1];

// 写指针
reg  [ADDR_WIDTH:0] wr_ptr;
wire [ADDR_WIDTH:0] wr_ptr_gray;
reg  [ADDR_WIDTH:0] wr_ptr_gray_sync1;
reg  [ADDR_WIDTH:0] wr_ptr_gray_sync2;

// 读指针
reg  [ADDR_WIDTH:0] rd_ptr;
wire [ADDR_WIDTH:0] rd_ptr_gray;
reg  [ADDR_WIDTH:0] rd_ptr_gray_sync1;
reg  [ADDR_WIDTH:0] rd_ptr_gray_sync2;

// 地址
wire [ADDR_WIDTH-1:0] wr_addr;
wire [ADDR_WIDTH-1:0] rd_addr;


always @(posedge wr_clk or negedge wr_rst_n) begin
  if (!wr_rst_n) begin
    wr_ptr <= 0;
  end
  else if (wr_en && !full) begin
    wr_ptr <= wr_ptr + 1;
  end
end


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


assign full = ((wr_ptr_gray[ADDR_WIDTH] != rd_ptr_gray_sync2[ADDR_WIDTH]) &&
             (wr_ptr_gray[ADDR_WIDTH-1] != rd_ptr_gray_sync2[ADDR_WIDTH-1]) &&
             (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_gray_sync2[ADDR_WIDTH-2:0]));



assign    empty = (rd_ptr_gray == wr_ptr_gray_sync2);



assign wr_addr = wr_ptr[ADDR_WIDTH-1:0];
assign rd_addr = rd_ptr[ADDR_WIDTH-1:0];


always @(posedge wr_clk or negedge wr_rst_n) begin

  if (wr_en && !full) begin
    memory[wr_addr] <= wr_data;
  end
end


always @(posedge rd_clk or negedge rd_rst_n) begin
  if (!rd_rst_n) begin
    rd_data <= 0;
  end
  else if (rd_en && !empty) begin
    rd_data <= memory[rd_addr];
  end
end

endmodule