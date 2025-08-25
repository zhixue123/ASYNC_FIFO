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

  integer write_count = 0;
  integer read_count = 0;
  
  initial begin
    // 初始化
    wr_clk = 0; rd_clk = 0;
    wr_rst_n = 0; rd_rst_n = 0;
    wr_en = 0; rd_en = 0;
    wr_data = 0;
    
    #100;
    wr_rst_n = 1; rd_rst_n = 1;
    #100;

    $display("=== Starting交错读写测试 ===");
    $display("Time\tOperation\tData\t\tFull\tEmpty");
    $display("--------------------------------------------------");
    
    // 启动并发的读写进程
    fork
      // 写进程：写入20个数据
      begin
        for (write_count = 0; write_count < 20; write_count = write_count + 1) begin
          @(posedge wr_clk);
          if (!full) begin
            wr_en = 1;
            wr_data = write_count + 100; // 数据从100开始
            #1;
            $display("%0t\tWrite\t\t%4d\t\t%b\t%b", $time, wr_data, full, empty);
            @(posedge wr_clk);
            wr_en = 0;
            #1;
          end else begin
            $display("%0t\tWrite blocked\t-\t\t%b\t%b", $time, full, empty);
            #10; // 等待一段时间再尝试
          end
        end
        $display("=== 写入完成 ===");
      end
      
      // 读进程：读取20个数据
      begin
        #50; // 延迟开始读取，让FIFO中先有一些数据
        for (read_count = 0; read_count < 20; read_count = read_count + 1) begin
          @(posedge rd_clk);
          if (!empty) begin
            rd_en = 1;
            #1;
            $display("%0t\tRead\t\t%4d\t\t%b\t%b", $time, rd_data, full, empty);
            @(posedge rd_clk);
            rd_en = 0;
            #1;
          end else begin
            $display("%0t\tRead blocked\t-\t\t%b\t%b", $time, full, empty);
            #10; // 等待一段时间再尝试
          end
        end
        $display("=== 读取完成 ===");
      end
    join

    // 测试边界条件：写满和读空
    $display("\n=== 测试边界条件 ===");
    
    // 尝试写满FIFO
    $display("=== 尝试写满FIFO ===");
    while (!full) begin
      @(posedge wr_clk);
      wr_en = 1;
      wr_data = write_count + 100;
      write_count = write_count + 1;
      #1;
      $display("%0t\tWrite to full\t%4d\t\t%b\t%b", $time, wr_data, full, empty);
      @(posedge wr_clk);
      wr_en = 0;
      #1;
    end
    
    // 尝试读空FIFO
    $display("=== 尝试读空FIFO ===");
    while (!empty) begin
      @(posedge rd_clk);
      rd_en = 1;
      #1;
      $display("%0t\tRead to empty\t%4d\t\t%b\t%b", $time, rd_data, full, empty);
      @(posedge rd_clk);
      rd_en = 0;
      #1;
    end

    $display("=== 测试完成! ===");
    #100;
    $finish;
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, TB_ASYNC_FIFO);
    #2000; // 设置仿真超时
    $display("仿真超时!");
    $finish;
  end

  // 监控异常情况
  always @(posedge wr_clk) begin
    if (wr_en && full) begin
      $display("%0t\tERROR: 在满状态下写入!", $time);
    end
  end

  always @(posedge rd_clk) begin
    if (rd_en && empty) begin
      $display("%0t\tERROR: 在空状态下读取!", $time);
    end
  end

endmodule