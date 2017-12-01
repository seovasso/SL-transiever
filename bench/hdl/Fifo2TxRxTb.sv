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
      .data_we_tx          ( data_we_tx),
      .wr_config_tx           (wr_config_tx),
      .config_we_tx        (config_we_tx),
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
     initial forever #(CLK_PERIOD/2) clk<=~clk;
     initial begin
       clk = 0;
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
       fifo_read_data  = 34'd87 | 34'd0<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd87 | 34'd1<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd97 | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd1 | 34'd3<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd77 | 34'd0<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd47 | 34'd1<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       #CLK_PERIOD;
       fifo_read_data  = 34'd17 | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;



        #CLK_PERIOD;
         rd_config_rx = 16'd34;
         config_changed_rx = 1;
         #CLK_PERIOD;
         config_changed_rx = 0;

         #CLK_PERIOD;
          rd_data_rx = 32'd34;
          rd_status_rx = 16'd34;
          data_status_changed_rx = 1;
          #CLK_PERIOD;
          data_status_changed_rx  = 0;


          #CLK_PERIOD;
          fifo_read_data  = 34'd1 | 34'd3<<32;
          fifo_read_empty = 0;
          #CLK_PERIOD;
          fifo_read_empty = 1;


          #CLK_PERIOD;
           rd_config_tx = 16'd698;
           config_changed_tx = 1;
           #CLK_PERIOD;
           config_changed_tx = 0;

           #CLK_PERIOD;
            rd_status_tx = 16'd567;
            status_changed_tx = 1;
            #CLK_PERIOD;
            status_changed_tx = 0;
     end

endmodule
