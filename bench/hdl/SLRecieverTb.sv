`timescale 100ps / 1ps

module SlRecieverTb();
    int    SlClkLength = 32;
    parameter clkPeriod = 2;
     logic        rst_n;
     logic        clk;
     logic        inSl0;
     logic        inSl1;
     logic        wr_enable;
     logic [15:0] wr_config_w;
     logic [15:0] r_config_w;
     logic [31:0] data_w;
     logic [15:0] status_w;
     logic data_status_changed;

 SL_receiver res (
     .rst_n                      (rst_n),
     .serial_line_zeroes_a       (inSl0),
     .serial_line_ones_a         (inSl1),
     .r_config_w                 (r_config_w),
     .data_w                     (data_w),
     .wr_config_w                (wr_config_w),
     .status_w                   (status_w),
     .clk                        (clk),
     .wr_enable                  (wr_enable),
     .data_status_changed(data_status_changed)
 );

 logic currTestPassed,allTestsPassed;
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


task testMassage;//конфигуриррует приемник и отправляет SL посылку
         input int mesLength;//длинна сообщения
         input int confLength;//сконфигурированая длинна
         input bit PCE_on;//включить контроль четности
         input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
  begin
  mes=$urandom_range(2**mesLength-1,0);
  wr_config_w=(confLength<<1)|PCE_on;//задаем конфигруацию
  wr_enable=1;
  #(clkPeriod);
  wr_enable=0;
  wr_config_w=16'h0000;
  slTransaction(mes,mesLength,parityRight);
  end
endtask
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
           parSl0 = parSl0^1;
           #(SlClkLength/2) inSl0=1;
           inSl0=0;
           #(SlClkLength);
           inSl0=1;
           #(SlClkLength/2);
      end else begin
          parSl1 = parSl1^1;
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
 bit [31:0] mes;
 bit [31:0] lastCorrMess;
 initial forever #(clkPeriod/2)clk=~clk;

    initial begin
        clk=0;
        currTestPassed = 0;
        allTestsPassed = 1;
        wr_enable = 0;
        wr_config_w = 16'h0014;
        inSl0 = 1;
        inSl1 = 1;
        rst_n = 1;
        #30
        rst_n = 0;
        #30
        rst_n = 1;
        #100
        for (int i=1;i<=3;i=i+1)begin
          int l = 8+$urandom_range(1,16)*2;
          $display("Test #%d: 1 correct message width PCE=0 l=%d",i,l);
          testMassage(l,l,0,1);
          writeTestResult((mes == data_w && status_w==16'b1000), 1, "");

          $display("Test #1.%d.2 : 1 correct message with PCE=1 l=%d",i,l);
          testMassage(l,l,1,1);
          writeTestResult((mes == data_w && status_w==16'b1000), 1, "");


        //  int messCount = $urandom_range(4,10);
          $display("Test #2.%d:2.2 : %d correct message with PCE=1 l=%d",i,5,l);
          for (int iterator = 0; iterator < 5; iterator++)
              testMassage(l,l,1,1);
          writeTestResult((mes == data_w && status_w==16'b1000), 1, "");

        $display("Test 3.%d:2 : 5 correct message then 1 incorrect then 5 correct  l=%d",i,l);
        for (int iterator = 0; iterator < 5; iterator++)
            testMassage(l,l,1,1);

            testMassage(l+2,l,1,1);//некорректное
            for (int iterator = 0; iterator < 5; iterator++)
                testMassage(l,l,1,1);
        writeTestResult((mes == data_w && status_w==16'b1000), 1, "");

        $display("Test 4.%d:2 : 5 incorrect message  l=%d",i,l);

        for (int iterator = 0; iterator < 5; iterator++) begin
        testMassage(l+$urandom_range(1,3)*2,l,1,1);//некорректное
        end
        writeTestResult((status_w==16'b1001), 1, "");


      $display("Test 5.a.2. %d   incorrect message L>N  l=%d",i,l);

      testMassage(l+$urandom_range(1,3)*2,l,1,1);//некорректное сообщение
      writeTestResult((status_w==16'b1001), 0, "");


    $display( "Test 5.a.1. %d  : incorrect message L<N  l=%d", i, l );
    testMassage(l-$urandom_range(1,3)*2,l,1,1);//некорректное сообщение
    writeTestResult((status_w==16'b1001), 0, "");

    $display( "Test 5.b.1. %d  :  message with parity error l=%d PCE=1", i, l );
    testMassage(l,l,1,1);//корректное сообщение
    lastCorrMess=mes;
    testMassage(l,l,1,0);//некорректное сообщение
    writeTestResult((status_w==16'b11000 && lastCorrMess == 0), 0, "");

    $display( "Test 5.b.2. %d  :  message with parity error l=%d PCE=0", i, l );
    testMassage(l,l,0,0);//некорректное сообщение
    writeTestResult((status_w==16'b01000 && mes == data_w), 0, "");

      if(allTestsPassed) begin
        $display("All test passed");
       end else $display("Some tests failed");
       $stop;
      end
    end


endmodule
