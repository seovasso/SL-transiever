module CommunicatorTb(

    );

    parameter CLK_PERIOD = 10;

    parameter CONFIG_MODIFIER    = 2'd0,
              DATA_MODIFIER      = 2'd1,
              STATUS_MODIFIER    = 2'd2,
              CHANNEL_MODIFIER   = 2'd3;


    logic clk; // system clock
    logic rst_n;

    //variables for FIFO's interfaces
    logic                   fifo_read_empty;
    logic                   fifo_write_full;

    logic       [33:0]      fifo_read_data;
    logic                   fifo_read_inc;

    logic       [33:0]      fifo_write_data;
    logic                   fifo_write_inc;

    logic    [31:0]  wr_data_tx_1;
    logic            data_we_tx_1;
    logic    [15:0]  wr_config_tx_1;
    logic            config_we_tx_1;
    logic            rd_status_tx_1;
    logic    [15:0]  rd_config_tx_1;
    logic            config_changed_tx_1;
    logic            status_changed_tx_1;

    logic    [31:0]  wr_data_tx_2;
    logic            data_we_tx_2;
    logic    [15:0]  wr_config_tx_2;
    logic            config_we_tx_2;
    logic            rd_status_tx_2;
    logic    [15:0]  rd_config_tx_2;
    logic            config_changed_tx_2;
    logic            status_changed_tx_2;

    // rx  communication ports
    logic    [15:0]  wr_config_rx_1;
    logic            config_we_rx_1;
    logic            word_picked_rx_1;
    logic    [15:0]  rd_status_rx_1;
    logic    [15:0]  rd_config_rx_1;
    logic    [31:0]  rd_data_rx_1;
    logic            config_changed_rx_1;
    logic            data_status_changed_rx_1;

    logic    [15:0]  wr_config_rx_2;
    logic            config_we_rx_2;
    logic            word_picked_rx_2;
    logic    [15:0]  rd_status_rx_2;
    logic    [15:0]  rd_config_rx_2;
    logic    [31:0]  rd_data_rx_2;
    logic            config_changed_rx_2;
    logic            data_status_changed_rx_2;

    Commutator#(16,16,16,2) test_module (

      .clk (clk),
      .rst_n (rst_n),
      .fifo_read_empty        (fifo_read_empty),
      .fifo_write_full        (fifo_write_full),
      .fifo_read_data         (fifo_read_data),
      .fifo_read_inc          (fifo_read_inc),
      .fifo_write_data        (fifo_write_data),
      .fifo_write_inc         (fifo_write_inc),
      .word_picked_rx({word_picked_rx_2,word_picked_rx_1}),
      .wr_data_tx             ({wr_data_tx_2, wr_data_tx_1}),
      .data_we_tx             ({data_we_tx_2, data_we_tx_1}),
      .wr_config_tx           ( {wr_config_tx_2, wr_config_tx_1}),
      .wr_config_rx           ( {wr_config_rx_2, wr_config_rx_1}),
      .config_we_tx           ( {config_we_tx_2, config_we_tx_1}),
      .rd_status_tx           ( {rd_status_tx_2, rd_status_tx_1}),
      .rd_config_tx           ( {rd_config_tx_2, rd_config_tx_1}),
      .status_changed_tx      ( {status_changed_tx_2, status_changed_tx_1}),
      .config_we_rx           ( {config_we_rx_2, config_we_rx_1}),
      .rd_status_rx           ( {rd_status_rx_2, rd_status_rx_1}),
      .rd_config_rx           ( {rd_config_rx_2, rd_config_rx_1}),
      .rd_data_rx             ( {rd_data_rx_2, rd_data_rx_1}),
      .data_status_changed_rx ( {data_status_changed_rx_2, data_status_changed_rx_1})
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

      task inMsg;
        input logic [1:0] modifier;
        begin
          message = $urandom_range(2**16-1,0) ;
          fifo_read_data  = message | modifier<<32;
          fifo_read_empty = 0;
          #CLK_PERIOD;
          fifo_read_empty = 1;
        end
      endtask

     initial forever #(CLK_PERIOD/2) clk<=~clk;

    // test variables
     logic currTestPassed;
     logic allTestsPassed;
     bit [31:0] message;

     initial begin
       clk = 0;
       currTestPassed = 1;
       allTestsPassed = 1;
       // inputs from fifo
       fifo_read_empty = 1;
       fifo_write_full = 0;
       fifo_read_data = 0;

       // inputs from tx
       rd_status_tx_1 = 0;
       rd_config_tx_1 = 0;
       config_changed_tx_1 = 0;
       status_changed_tx_1 = 0;

       rd_status_tx_2 = 0;
       rd_config_tx_2 = 0;
       config_changed_tx_2 = 0;
       status_changed_tx_2 = 0;
       // inputs from rx

       rd_status_rx_2 = 0;
       rd_config_rx_2 = 0;
       rd_data_rx_2 = 0;
       config_changed_rx_2 = 0;
       data_status_changed_rx_2 = 0;

       rd_status_rx_1 = 0;
       rd_config_rx_1 = 0;
       rd_data_rx_1 = 0;
       config_changed_rx_1 = 0;
       data_status_changed_rx_1 = 0;

       rst_n = 1;
       #50;
       rst_n = 0;
       #50;
       rst_n = 1;

       #CLK_PERIOD;

       inMsg(CONFIG_MODIFIER);
      if (!(fifo_read_inc && config_we_tx_1 && wr_config_tx_1 == message [15:0])) begin
        currTestPassed = 0;
        $display("%b != %b, %b != %b, %b != %b ", fifo_read_inc, 1, config_we_tx_1, 1, wr_config_tx_1, message [15:0] );
      end
       writeTestResult(currTestPassed , 1, "write tx_1 config");

        rd_config_tx_1 = message;
        #CLK_PERIOD;
        #CLK_PERIOD;
        if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| message [15:0]))) begin
          currTestPassed = 0;
          $display("%b != %b, %b != %b",fifo_write_inc, 1, fifo_write_data, (CONFIG_MODIFIER << 32| message [15:0]) );
        end
        writeTestResult(currTestPassed, 2, "read tx_1 config");

        inMsg(DATA_MODIFIER);
       if (!(fifo_read_inc && data_we_tx_1 && wr_data_tx_1 == message)) begin
         currTestPassed = 0;
         $display("%b != %b, %b != %b, %b != %b ",fifo_read_inc, 1, data_we_tx_1, 1, wr_data_tx_1,  message);
       end
        writeTestResult(currTestPassed , 1, "write tx_1 config");
       fifo_read_empty = 1;
       writeTestResult(fifo_read_inc && data_we_tx_1 && wr_data_tx_1 == message ,
          3, "write tx_1 data");

       #CLK_PERIOD;
       message = $urandom_range(2**16-1,0);
       fifo_read_data  = message | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx_1 && !config_we_tx_1 && !config_we_rx_1,
          4, "write tx_1 status (can't write)");

       #CLK_PERIOD;
       message = 1;
       fifo_read_data  = message | CHANNEL_MODIFIER<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;
       if (!(fifo_read_inc && !data_we_tx_1 && !config_we_tx_1 && !config_we_rx_1)) begin
         currTestPassed = 0;
         $display("error %b != %b, %b != %b, %b != %b, %b != %b ", fifo_read_inc, 1, data_we_tx_1, 0, config_we_tx_1,0 ,config_we_rx_1, 0);
       end
        writeTestResult(currTestPassed , 5, "change channel");


        rd_data_rx_1 = $urandom_range(2**26-1,0) ;
        rd_status_rx_1 = $urandom_range(2**16-1,0) ;
        rd_data_rx_2 = $urandom_range(2**26-1,0) ;
        rd_status_rx_2 = $urandom_range(2**16-1,0) ;
        data_status_changed_rx_1 = 1;
        #CLK_PERIOD;
        data_status_changed_rx_1  = 0;
        #CLK_PERIOD;
        if (!(fifo_write_inc && fifo_write_data == (DATA_MODIFIER << 32| rd_data_rx_1) && word_picked_rx_1 == 1)) begin
          currTestPassed = 0;
          $display("error with data reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data, ((34'b0|DATA_MODIFIER << 32)| rd_data_rx_1), word_picked_rx_1, 1);
        end
        #CLK_PERIOD;
        if (!(fifo_write_inc && fifo_write_data == (STATUS_MODIFIER << 32| rd_status_rx_1) && !word_picked_rx_1)) begin
          currTestPassed = 0;
          $display("error with status reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data, (STATUS_MODIFIER << 32| rd_status_rx_1), word_picked_rx_1, 0);
        end
        rd_config_rx_1 = message [15:0];
        #CLK_PERIOD;
        if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| rd_config_rx_1) && !word_picked_rx_1)) begin
          currTestPassed = 0;
          $display(" error with config reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data,(CONFIG_MODIFIER << 32| rd_config_rx_1), word_picked_rx_1, 0);
        end
        writeTestResult(currTestPassed,
             678, "read rx_1 data, status & sconfig");






       #CLK_PERIOD;
      rd_status_rx_1 = 0;
      inMsg(CONFIG_MODIFIER);
      if (!(fifo_read_inc && config_we_rx_1 && wr_config_rx_1 [15:0] == message [15:0])) begin
        currTestPassed = 0;
        $display(" error with config writing %b != %b, %b != %b, %b != %b",fifo_read_inc, 1'b1, config_we_rx_1, 1'b1, wr_config_rx_1 [15:0], message [15:0]);
      end
      writeTestResult(currTestPassed, 9, "write rx_1 config");
      rd_config_rx_1 = message [15:0];
      #CLK_PERIOD;
      #CLK_PERIOD;
      if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| rd_config_rx_1) && !word_picked_rx_1)) begin
        currTestPassed = 0;
        $display(" error with config reading %b != %b, %b != %b", fifo_write_inc, 1'b1, fifo_write_data,(CONFIG_MODIFIER << 32| rd_config_rx_1));
      end
      writeTestResult(currTestPassed, 10, "read rx_1 config");

       #CLK_PERIOD;
       message = $urandom_range(2**16-1,0);
       fifo_read_data  = message | 34'd1<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx_1 && !config_we_tx_1 && !config_we_rx_1,
          11, "write rx_1 data (can't write)");

       #CLK_PERIOD;
       fifo_read_data  = 34'd17 | 34'd2<<32;
       fifo_read_empty = 0;
       #CLK_PERIOD;
       fifo_read_empty = 1;

       writeTestResult(fifo_read_inc &&  !data_we_tx_1 && !config_we_tx_1 && !config_we_rx_1,
          12, "write rx_1 status (can't write)");





         #CLK_PERIOD;
          rd_data_rx_1 = 32'd456791;
          rd_status_rx_1 = 16'd76;
          data_status_changed_rx_1 = 1;
          #CLK_PERIOD;
          data_status_changed_rx_1  = 0;
          writeTestResult(fifo_write_inc && fifo_write_data == (34'd1 << 32| 32'd456791),
             13, "read rx_1 data");
          #CLK_PERIOD;
          writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| 32'd76),
            14, "read rx_1  status");
          rd_config_rx_1 = message [15:0];
          #CLK_PERIOD;
          writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32 | message [15:0]),
               15, "read rx_1 config");


          #CLK_PERIOD;
          fifo_read_data  = 34'd0 | CHANNEL_MODIFIER<<32;
          fifo_read_empty = 0;
          #CLK_PERIOD;
          fifo_read_empty = 1;
          #CLK_PERIOD;
          writeTestResult(fifo_write_inc && fifo_write_data == (CHANNEL_MODIFIER << 32| 32'd0),
             16, "read channel");
          rd_status_tx_1=message[0];
         #CLK_PERIOD;
         writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| message[0]),
            17, "read tx_1 status");
          rd_config_tx_1 = message [15:0];
          #CLK_PERIOD;
        writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32| message [15:0]),
           18, "read tx_1 config");



           #CLK_PERIOD;
            message = $urandom_range(2**16-1,0);
            rd_status_tx_1 = message;
            status_changed_tx_1 = 1;
            #CLK_PERIOD;
            status_changed_tx_1 = 0;

            writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| message[0]),
               19, "read tx_1 status");
              $display ("All Tests with first channel:  %s ",(allTestsPassed?"passed":"failed"));



              // second part
              #CLK_PERIOD;
              fifo_read_data  = 34'd2 | CHANNEL_MODIFIER<<32;
              fifo_read_empty = 0;
              #CLK_PERIOD;
              fifo_read_empty = 1;
              #CLK_PERIOD;
              writeTestResult(fifo_write_inc && fifo_write_data == (CHANNEL_MODIFIER << 32| 32'd2),
                 16, "read channel");
              #CLK_PERIOD;
              #CLK_PERIOD;
              #CLK_PERIOD;


              inMsg(CONFIG_MODIFIER);
             if (!(fifo_read_inc && config_we_tx_2 && wr_config_tx_2 == message [15:0])) begin
               currTestPassed = 0;
               $display("%b != %b, %b != %b, %b != %b ", fifo_read_inc, 1, config_we_tx_2, 1, wr_config_tx_2, message [15:0] );
             end
              writeTestResult(currTestPassed , 1, "write tx_2 config");

               rd_config_tx_2 = message;
               #CLK_PERIOD;
               #CLK_PERIOD;
               if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| message [15:0]))) begin
                 currTestPassed = 0;
                 $display("%b != %b, %b != %b",fifo_write_inc, 1, fifo_write_data, (CONFIG_MODIFIER << 32| message [15:0]) );
               end
               writeTestResult(currTestPassed, 2, "read tx_2 config");

               inMsg(DATA_MODIFIER);
              if (!(fifo_read_inc && data_we_tx_2 && wr_data_tx_2 == message)) begin
                currTestPassed = 0;
                $display("%b != %b, %b != %b, %b != %b ",fifo_read_inc, 1, data_we_tx_2, 1, wr_data_tx_2,  message);
              end
               writeTestResult(currTestPassed , 1, "write tx_2 config");
              fifo_read_empty = 1;
              writeTestResult(fifo_read_inc && data_we_tx_2 && wr_data_tx_2 == message ,
                 3, "write tx_2 data");

              #CLK_PERIOD;
              message = $urandom_range(2**16-1,0);
              fifo_read_data  = message | 34'd2<<32;
              fifo_read_empty = 0;
              #CLK_PERIOD;
              fifo_read_empty = 1;

              writeTestResult(fifo_read_inc &&  !data_we_tx_2 && !config_we_tx_2 && !config_we_rx_2,
                 4, "write tx_2 status (can't write)");

              #CLK_PERIOD;
              message = 3;
              fifo_read_data  = message | CHANNEL_MODIFIER<<32;
              fifo_read_empty = 0;
              #CLK_PERIOD;
              fifo_read_empty = 1;
              if (!(fifo_read_inc && !data_we_tx_2 && !config_we_tx_2 && !config_we_rx_2)) begin
                currTestPassed = 0;
                $display("error %b != %b, %b != %b, %b != %b, %b != %b ", fifo_read_inc, 1, data_we_tx_2, 0, config_we_tx_2,0 ,config_we_rx_2, 0);
              end
               writeTestResult(currTestPassed , 5, "change channel");


               rd_data_rx_2 = $urandom_range(2**26-1,0) ;
               rd_status_rx_2 = $urandom_range(2**16-1,0) ;
               rd_data_rx_2 = $urandom_range(2**26-1,0) ;
               rd_status_rx_2 = $urandom_range(2**16-1,0) ;
               data_status_changed_rx_2 = 1;
               #CLK_PERIOD;
               data_status_changed_rx_2  = 0;
               #CLK_PERIOD;
               if (!(fifo_write_inc && fifo_write_data == (DATA_MODIFIER << 32| rd_data_rx_2) && word_picked_rx_2 == 1)) begin
                 currTestPassed = 0;
                 $display("error with data reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data, ((34'b0|DATA_MODIFIER << 32)| rd_data_rx_2), word_picked_rx_2, 1);
               end
               #CLK_PERIOD;
               if (!(fifo_write_inc && fifo_write_data == (STATUS_MODIFIER << 32| rd_status_rx_2) && !word_picked_rx_2)) begin
                 currTestPassed = 0;
                 $display("error with status reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data, (STATUS_MODIFIER << 32| rd_status_rx_2), word_picked_rx_2, 0);
               end
               rd_config_rx_2 = message [15:0];
               #CLK_PERIOD;
               if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| rd_config_rx_2) && !word_picked_rx_2)) begin
                 currTestPassed = 0;
                 $display(" error with config reading %b != %b, %b != %b, %b != %b", fifo_write_inc, 1, fifo_write_data,(CONFIG_MODIFIER << 32| rd_config_rx_2), word_picked_rx_2, 0);
               end
               writeTestResult(currTestPassed,
                    678, "read rx_2 data, status & sconfig");






              #CLK_PERIOD;
             rd_status_rx_2 = 0;
             inMsg(CONFIG_MODIFIER);
             if (!(fifo_read_inc && config_we_rx_2 && wr_config_rx_2 [15:0] == message [15:0])) begin
               currTestPassed = 0;
               $display(" error with config writing %b != %b, %b != %b, %b != %b",fifo_read_inc, 1'b1, config_we_rx_2, 1'b1, wr_config_rx_2 [15:0], message [15:0]);
             end
             writeTestResult(currTestPassed, 9, "write rx_2 config");
             rd_config_rx_2 = message [15:0];
             #CLK_PERIOD;
             #CLK_PERIOD;
             if (!(fifo_write_inc && fifo_write_data == (CONFIG_MODIFIER << 32| rd_config_rx_2) && !word_picked_rx_2)) begin
               currTestPassed = 0;
               $display(" error with config reading %b != %b, %b != %b", fifo_write_inc, 1'b1, fifo_write_data,(CONFIG_MODIFIER << 32| rd_config_rx_2));
             end
             writeTestResult(currTestPassed, 10, "read rx_2 config");

              #CLK_PERIOD;
              message = $urandom_range(2**16-1,0);
              fifo_read_data  = message | 34'd1<<32;
              fifo_read_empty = 0;
              #CLK_PERIOD;
              fifo_read_empty = 1;

              writeTestResult(fifo_read_inc &&  !data_we_tx_2 && !config_we_tx_2 && !config_we_rx_2,
                 11, "write rx_2 data (can't write)");

              #CLK_PERIOD;
              fifo_read_data  = 34'd17 | 34'd2<<32;
              fifo_read_empty = 0;
              #CLK_PERIOD;
              fifo_read_empty = 1;

              writeTestResult(fifo_read_inc &&  !data_we_tx_2 && !config_we_tx_2 && !config_we_rx_2,
                 12, "write rx_2 status (can't write)");





                #CLK_PERIOD;
                 rd_data_rx_2 = 32'd456791;
                 rd_status_rx_2 = 16'd76;
                 data_status_changed_rx_2 = 1;
                 #CLK_PERIOD;
                 data_status_changed_rx_2  = 0;
                 writeTestResult(fifo_write_inc && fifo_write_data == (34'd1 << 32| 32'd456791),
                    13, "read rx_2 data");
                 #CLK_PERIOD;
                 writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| 32'd76),
                   14, "read rx_2  status");
                 rd_config_rx_2 = message [15:0];
                 #CLK_PERIOD;
                 writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32 | message [15:0]),
                      15, "read rx_2 config");


                 #CLK_PERIOD;
                 fifo_read_data  = 34'd2 | CHANNEL_MODIFIER<<32;
                 fifo_read_empty = 0;
                 #CLK_PERIOD;
                 fifo_read_empty = 1;
                 #CLK_PERIOD;
                 writeTestResult(fifo_write_inc && fifo_write_data == (CHANNEL_MODIFIER << 32| 32'd2),
                    16, "read channel");
                 rd_status_tx_2=message[0];
                #CLK_PERIOD;
                writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| message[0]),
                   17, "read tx_2 status");
                 rd_config_tx_2 = message [15:0];
                 #CLK_PERIOD;
               writeTestResult(fifo_write_inc && fifo_write_data == (34'd0 << 32| message [15:0]),
                  18, "read tx_2 config");



                  #CLK_PERIOD;
                   message = $urandom_range(2**16-1,0);
                   rd_status_tx_2 = message;
                   status_changed_tx_2 = 1;
                   #CLK_PERIOD;
                   status_changed_tx_2 = 0;

                   writeTestResult(fifo_write_inc && fifo_write_data == (34'd2 << 32| message[0]),
                      19, "read tx_2 status");
                     $display ("All Tests with second channel:  %s ",(allTestsPassed?"passed":"failed"));
               $stop();
     end

endmodule
