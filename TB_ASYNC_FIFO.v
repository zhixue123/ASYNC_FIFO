`timescale 1ns/1ns

module TB_ASYNC_FIFO;

  reg wr_rst_n, rd_rst_n;
  reg wr_clk, rd_clk;
  reg wr_en, rd_en;
  reg [15:0] wr_data;
  wire [15:0] rd_data;
  wire full, empty;

  async_fifo dut (
    .wr_rst_n(wr_rst_n),
    .rd_rst_n(rd_rst_n),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .full(full),
    .empty(empty)
  );

  // 时钟
  always #5 wr_clk = ~wr_clk;
  always #7 rd_clk = ~rd_clk;

  integer i;
  initial begin
    // 初始化
    wr_clk = 0; rd_clk = 0;
    wr_rst_n = 0; rd_rst_n = 0;
    wr_en = 0; rd_en = 0;
    wr_data = 0;
    
    #100;
    wr_rst_n = 1; rd_rst_n = 1;
    #100;

    // 测试1：写4个数据
    $display("Writing 4 data...");
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge wr_clk);
      wr_en = 1;
      wr_data = i + 100;
      #1;
    end
    @(posedge wr_clk);
    wr_en = 0;
    #200; // 等待足够时间同步

    // 测试2：读4个数据
    $display("Reading 4 data...");
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge rd_clk);
      rd_en = 1;
      #1;
      $display("Read %0d: %d", i, rd_data);
      @(posedge rd_clk);
      rd_en = 0;
      #1;
    end

    $display("Test completed!");
    #100;
    $finish;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, TB_ASYNC_FIFO);
  end

endmodule