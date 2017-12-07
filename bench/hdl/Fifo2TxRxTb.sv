module Fifo2TxRxTb(

    );

    parameter CLK_PERIOD = 10;



    logic clk; // system clock
    logic rst_n;

    //variables for FIFO's interfaces
    logic                   fifo_read_empty;
    logic                   fifo_write_full;

    logic       [33:0]      fifo_read_data;
    logic                   fifo_read_inc;

    logic       [33:0]      fifo_write_data;
    logic                   fifo_write_inc;

    logic    [31:0]  wr_data_tx;
    logic            data_we_tx;
    logic    [15:0]  wr_config_tx;
    logic            config_we_tx;
    logic            rd_status_tx;
    logic    [15:0]  rd_config_tx;
    logic            config_changed_tx;
    logic            status_changed_tx;

    // rx  communication ports
    logic    [15:0]  wr_config_rx;
    logic            config_we_rx;
    logic    [15:0]  rd_status_rx;
    logic    [15:0]  rd_config_rx;
    logic    [15:0]  rd_data_rx;
    logic            config_changed_rx;
    logic            data_status_changed_rx;

    Fifo2TxRx test_module (
      .clk (clk),
      .rst_n (rst_n),
      .fifo_read_empty        (fifo_read_empty),
      .fifo_write_full        (fifo_write_full),
      .fifo_read_data         (fifo_read_data),
      .fifo_read_inc          (fifo_read_inc),
      .fifo_write_data        (fifo_write_data),
      .fifo_write_inc         (fifo_write_inc),
      .wr_data_tx             (wr_data_tx),
      .data_we_tx             ( data_we_tx),
      .wr_config_tx           (wr_config_tx),
      .wr_config_rx           (wr_config_rx),
      .config_we_tx           (config_we_tx),
      .rd_status_tx           (rd_status_tx),
      .rd_config_tx           (rd_config_tx),
      .config_changed_tx      (config_changed_tx),
      .status_changed_tx      (status_changed_tx),
      .config_we_rx        (config_we_rx),
      .rd_status_rx           (rd_status_rx),
      .rd_config_rx           (rd_config_rx),
      .rd_data_rx             (rd_data_rx),
      .config_changed_rx      (config_changed_rx),
      .data_status_changed_rx (data_status_changed_rx)
      );

      task writeTestResult;
        input logic condition;
        input int testNumber;
        input string testName;
          begin
          if (!condition) begin
            currTestPassed = 0;
            allTestsPassed = 0;
          end
          $display ("Test # %d: %s : %s ",testNumber, testName, (currTestPassed? "OK" : "failed"));
          currTestPassed = 1;
        end
      endtask


     initial forever #(CLK_PERIOD/2) clk<=~clk;

    // test variables
     logic currTestPassed;
     logic allTestsPassed;
     logic [31:0] message;

     initial begin
       clk = 0;
       currTestPassed = 1;
       allTestsPassed = 1;
       // inputs from fifo
       fifo_read_empty = 1;
       fifo_write_full = 0;
       fifo_read_data = 0;

       // inputs from tx
       rd_status_tx = 0;
       rd_config_tx = 0;
       config_changed_tx = 0;
       status_changed_tx = 0;
       // inputs from rx
       wr_config_rx = 0;
       rd_status_rx = 0;
       rd_config_rx = 0;
       rd_data_rx = 0;
       config_changed_rx = 0;
       data_status_changed_rx = 0;

       rst_n = 1;
       #50;
       rst_n = 0;
       #50;
       rst_n = 1;
       #CLK_PERIOD;
       message = 34'd87;
       fifo_read_data  = message | 34'd0<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       //
       writeTestResult(fifo_read_inc && config_we_tx&& wr_config_tx == message [15:0] ,
          1, "write tx config");

       #CLK_PERIOD;
       message = 34'd91;
       fifo_read_data  = message | 34'd1<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;
       writeTestResult(fifo_read_inc && data_we_tx && wr_data_tx == message ,
          2, "write tx data");

       #CLK_PERIOD;
       message = 34'd99;
       fifo_read_data  = message | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx && !config_we_tx && !config_we_rx,
          3, "write tx status (can't write)");

       #CLK_PERIOD;
       message = 34'd1;
       fifo_read_data  = message | 34'd3<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc && !data_we_tx && !config_we_tx && !config_we_rx,
          4, "change channel");

       #CLK_PERIOD;
       message = 34'd88;
       fifo_read_data  = message  | 34'd0<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc && config_we_rx && wr_config_rx [15:0] == message [15:0],
          5, "write rx config");

       #CLK_PERIOD;
       message = 34'd88;
       fifo_read_data  = message | 34'd1<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx && !config_we_tx && !config_we_rx,
          6, "write rx data (can't write)");

       #CLK_PERIOD;
       fifo_read_data  = 34'd17 | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx && !config_we_tx && !config_we_rx,
          7, "write rx status (can't write)");



        #CLK_PERIOD;
         message = 16'd34;
         rd_config_rx = message [15:0];
         config_changed_rx = 1;
         #CLK_PERIOD;
         config_changed_rx = 0;
         writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32 | message [15:0]),
            8, "read rx config");

         #CLK_PERIOD;
          rd_data_rx = 32'd4567;
          rd_status_rx = 16'd76;
          data_status_changed_rx = 1;
          #CLK_PERIOD;
          data_status_changed_rx  = 0;
          writeTestResult(fifo_write_inc && fifo_write_data == (34'd1 << 32| 32'd456791),
             9, "read rx data");
          #CLK_PERIOD;
          writeTestResult(fifo_write_inc && fifo_write_data == (34'd1 << 32| 32'd456791),
            10, "read rx  status");


          #CLK_PERIOD;
          fifo_read_data  = 34'd1 | 34'd3<<32;
          fifo_read_empty = 0;
          #CLK_PERIOD;
          fifo_read_empty = 1;

          writeTestResult(fifo_write_inc && fifo_write_data == (34'd3 << 32| 34'd1),
             11, "read channel");

          #CLK_PERIOD;
           rd_config_tx = 16'd698;
           config_changed_tx = 1;
           #CLK_PERIOD;
           config_changed_tx = 0;

           writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32| message [15:0]),
              12, "read tx config");

           #CLK_PERIOD;
            message = 32'b1;
            rd_status_tx = message;
            status_changed_tx = 1;
            #CLK_PERIOD;
            status_changed_tx = 0;

            writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| message[0]),
               13, "read tx config");
              $display ("All Tests:  %s ",(allTestsPassed?"passed":"failed"));
     end

endmodule
