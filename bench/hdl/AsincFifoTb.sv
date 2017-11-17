`timescale 100ps / 1ps

module AsincFifoTb();
  parameter CLK_PERIOD   = 10;
  parameter CLK_PERIOD = 3;
  parameter FIFO_DATA_SIZE = 32;
  parameter addrSize = 3;

  logic [FIFO_DATA_SIZE-1:0] rd_data, wr_data;
  logic                wr_full,
                       rd_empty,
                       wr_inc,
                       wr_rst_n,
                       wr_clk,
                       rd_inc,
                       rd_rst_n,
                       rd_clk;

  AsyncFifo#(addrSize,FIFO_DATA_SIZE) fifo1 ( .rd_data  (rd_data),
                                        .wr_data  (wr_data),
                                        .wr_full  (wr_full),
                                        .wr_inc   (wr_inc),
                                        .rd_inc   (rd_inc),
                                        .wr_clk   (wr_clk),
                                        .rd_clk   (rd_clk),
                                        .rd_empty (rd_empty),
                                        .wr_rst_n (wr_rst_n),
                                        .rd_rst_n (rd_rst_n));
task writeToBuffer;
  input logic [FIFO_DATA_SIZE-1:0] dataToSend;
  begin
    #(CLK_PERIOD);
    wr_data = dataToSend;
    if (!wr_full) wr_inc = 1;
    else $display("Write operation aborted: buffer is full");
    #CLK_PERIOD;
    wr_inc = 0;
    wr_data = 0;
    #(CLK_PERIOD-CLK_PERIOD);
  end
endtask
logic [FIFO_DATA_SIZE-1:0] readedData;
task readFromBuffer;
  begin
    if (!rd_empty) begin
      readedData = rd_data;
      rd_inc = 1;
      #CLK_PERIOD;
      rd_inc = 0;
      #CLK_PERIOD;
    end
    else $display("Read operation aborted: buffer is empty");
    rd_inc = 0;
  end
endtask
  initial begin
     #(CLK_PERIOD);
      forever #(CLK_PERIOD/2) wr_clk <= ~ wr_clk;
    end
  initial forever #(CLK_PERIOD/2) rd_clk <= ~ rd_clk;


  logic [FIFO_DATA_SIZE-1:0] testDataArr [(1 << addrSize)-1:0];
  logic currTestPassed;
  logic allTestsPassed;
  initial begin
  // making reset
    currTestPassed = 1;
    allTestsPassed = 1;
    readedData = 0;
    wr_clk = 0;
    rd_clk = 0;
    wr_inc = 0;
    rd_inc = 0;
    wr_rst_n = 1;
    rd_rst_n = 1;
    #(CLK_PERIOD*5) wr_rst_n=0;
    rd_rst_n = 0;
    #(CLK_PERIOD*5) wr_rst_n=1;
    rd_rst_n=1;
  //Test 1;
    #(CLK_PERIOD*2);
    if (!rd_empty) begin
    currTestPassed = 0;
    allTestsPassed = 0;
    end
    $display ("Test #1: Empty flag %s ",(currTestPassed?"passed":"failed"));
    // Test 2
    currTestPassed = 1;
    for (int i=0;  i < (1<<addrSize); i++) begin
      testDataArr [i] = $urandom_range((1<<FIFO_DATA_SIZE-1),0);
      writeToBuffer( testDataArr [i] );
    end

    #(CLK_PERIOD);
    if (!wr_full) begin
    currTestPassed = 0;
    allTestsPassed = 0;
    end
    $display ("Test #1: Full flag %s ",(currTestPassed?"passed":"failed"));
    //Test 3
    currTestPassed = 1;
    for (int i=0;  i < (1<<addrSize); i++) begin
      readFromBuffer();
      if (readedData != testDataArr[i]) begin
      currTestPassed = 0;
      allTestsPassed = 0;
      end
    end
    $display ("Test #3: load and store %s ",(currTestPassed?"passed":"failed"));
    $display ("All Tests:  %s ",(allTestsPassed?"passed":"failed"));
  end

endmodule
