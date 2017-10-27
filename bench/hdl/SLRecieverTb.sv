`timescale 100ps / 1ps

module SlRecieverTb();
    parameter SlClkLength=32;
    parameter clkPeriod=2;
     logic        rst_n;
     logic        clk;
     logic        inSl0;
     logic        inSl1;
     logic [15:0] wr_config_w;
     logic [15:0] r_config_w;
     logic [31:0] data_w;
     logic [15:0] status_w;


task slTransaction;
          input bit [31:0] mess;//отправляемое сообщение
          input int mesLength;//длинна сообщения
          input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
          logic        parSl0;
          logic        parSl1;
   begin
   parSl0 =1'b1;
   parSl1 =1'b0;
     for (int i=0; i < mesLength; i=i+1) begin
      if(!mess[i])begin
           parSl0 = ~parSl0;
           #(SlClkLength/2) inSl0=1;
           inSl0=0;
           #(SlClkLength);
           inSl0=1;
           #(SlClkLength/2);
      end else begin
          parSl1 = ~parSl1;
          #(SlClkLength/2);
          inSl1=1;
          inSl1=0;
          #(SlClkLength);
          inSl1=1;
          #(SlClkLength/2);
      end
     end
     inSl1 = 1;
     inSl0 = 1;
     #(SlClkLength/2);
     if (parityRight)begin
       inSl0 = parSl0; // бит четности по 0
       inSl1 = parSl1; // бит четности по 1
     end else begin
       inSl0 = !parSl0; // неправильный бит четности по 0
       inSl1 = !parSl1; // неправильный бит четности по 1
     end
     #(SlClkLength);
     inSl1 = 1;
     inSl0 = 1;
     #(SlClkLength);
     inSl0=0;
     inSl1=0;
     #(SlClkLength);
     inSl0=1;
     inSl1=1;
     #(SlClkLength/2);
     end
endtask

    SL_receiver res (
        .rst_n                      (rst_n),
        .serial_line_zeroes_a       (inSl0),
        .serial_line_ones_a         (inSl1),
        .r_config_w                 (r_config_w),
        .data_w                     (data_w),
        .wr_config_w                (wr_config_w),
        .status_w                   (status_w),
        .clk(clk)
    );
 bit [31:0] mes;
 initial forever #(clkPeriod/2)clk=~clk;
logic curTest,allTest;
    initial begin
        clk=0;
        curTest=0;
        allTest=1;
        wr_config_w=16'h000e;
        inSl0 = 1;
        inSl1 = 1;
        rst_n = 1;
        #30
        rst_n = 0;
        #30
        rst_n = 1;
        #100

        $display("Test #1: 1 correct message l=8");
        //mes=$urandom_range(255,0);
        mes=$urandom();
        slTransaction(mes,32,1);
        if (mes==data_w)begin
          curTest=1;
        end else  begin
          curTest=0;
          allTest=0;
        end
        if(data_w==mes) begin
          $display("test passed");
        end else $display("test failed");

        // bitCount=5'd14;
        //
        // $display("Test #1: 1 correct message l=15");
        // mes=$urandom();
        // slTransaction(mes,16,1);
        // if ((data [31:17] == mes[14:0]) && bitCountValid && wordReady)begin
        //   curTest=1;
        // end else  begin
        //   curTest=0;
        //   allTest=0;
        // end
        // if(curTest) begin
        //   $display("test passed");
        // end else $display("test failed");



      if(allTest) begin
        $display("All test passed");
       end else $display("Some tests failed");
    end



endmodule
