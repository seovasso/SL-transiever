`timescale 100ps / 1ps

module AsincFifoTb();
  parameter clkPeriod   = 10;
  parameter clkTimeDiff = 3;
  parameter dataSize = 32;
  parameter addrSize = 4;

  logic [dataSize-1:0] rd_data, wr_data;
  logic                wr_full,
                       wr_empty,
                       wr_inc,
                       wr_rst_n,
                       wr_clk,
                       rd_inc,
                       rd_rst_n,
                       rd_clk;

  AsyncFifo#(addrSize,dataSize) fifo1 ( .rd_data  (rd_data),
                                        .wr_data  (wr_data),
                                        .wr_full  (wr_full),
                                        .wr_inc   (wr_inc),
                                        .rd_inc   (rd_inc),
                                        .wr_clk   (wr_clk),
                                        .rd_clk   (rd_clk),
                                        .rd_empty (rd_empty),
                                        .wr_rst_n (wr_rst_n),
                                        .rd_rst_n (rd_rst_n));

  initial begin
     #(clkTimeDiff);
      forever #(clkPeriod/2) wr_clk <= ~ wr_clk;
    end
  initial forever #(clkPeriod/2) rd_clk <= ~ rd_clk;

  initial begin
    wr_clk = 0;
    rd_clk = 0;
    wr_inc = 0;
    rd_inc = 0;
    wr_rst_n = 1;
    rd_rst_n = 1;
    #(clkPeriod*5) wr_rst_n=0;
    rd_rst_n = 0;
    #(clkPeriod*5) wr_rst_n=1;
    rd_rst_n=1;
  end




endmodule
