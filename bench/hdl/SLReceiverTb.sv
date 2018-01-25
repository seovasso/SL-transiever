`timescale 100ps / 1ps

module SlReceiverTb();
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
     logic word_picked;

 SlReceiver res (
     .word_picked                (word_picked),
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
   $display ("Test : %s : %s ", testName, (currTestPassed? "OK" : "failed"));
   currTestPassed = 1;
 end
endtask

task makeConfig;
  input int confLength;//длинна сообщения
  input bit PCE_on;//включить контроль четности
    begin
      wr_config_w=(confLength<<1)|PCE_on;//задаем конфигруацию
      wr_enable=1;
      #(clkPeriod);
      wr_enable=0;
      wr_config_w=16'h0000;
    end
endtask
task testMassage;//конфигуриррует приемник и отправляет SL посылку
         input int msgLength;//сконфигурированая длинна
         input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
  begin
  msg=$urandom_range(2**msgLength-1,0);
  slTransaction(msg,msgLength,parityRight);
  end
endtask
task testMassageWithLE;//конфигуриррует приемник и отправляет SL посылку
         input int msgLength;//сконфигурированая длинна
         input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
         int errorPlace; //переменная для определения бита с LE ошибкой
  begin
  msg=$urandom_range(2**msgLength-1,0);
  errorPlace = $urandom_range(msgLength-1,0);
  slTransactionWithLevelError(msg,msgLength,parityRight,errorPlace);
  end
endtask
task slTransaction;
          input bit [31:0] msg;//отправляемое сообщение
          input int msgLength;//длинна сообщения
          input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
          logic        parSl0;
          logic        parSl1;
   begin
   parSl0 =1'b1;
   parSl1 =1'b0;
     for (int i=0; i < msgLength; i=i+1) begin
      if(!msg[i])begin
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
task bitPulse;
  input logic Bit;
  input int bitLength;
  fork
  begin
    if(Bit) begin
      inSl1=0;
      #(bitLength);
      inSl1=1;

    end else begin
      inSl1=1;
      #(bitLength);
    end
  end
  begin
    if(!Bit) begin
      inSl0=0;
      #(bitLength);
      inSl0=1;
    end else begin
      inSl0=1;
      #(bitLength);
    end
  end
  join
endtask
task slTransactionWithLevelError;
          input bit [31:0] msg;//отправляемое сообщение
          input int msgLength;//длинна сообщения
          input bit parityRight;//если 1, то правильная четность, если 0 то неправильная
          input int defectBitNumber;
          logic        parSl0;
          logic        parSl1;
   begin
   parSl0 =1'b1;
   parSl1 =1'b0;
     for (int i=0; i < msgLength; i=i+1) begin
      if(!msg[i])begin
           parSl0 = parSl0^1;
           #(SlClkLength/2) inSl0=1;
           inSl0 = 0;
           #(SlClkLength/2);
           if (defectBitNumber == i) inSl1 = 0;
           #(SlClkLength/2);
           inSl0=1;
           #(SlClkLength/2);
      end else begin
          parSl1 = parSl1^1;
          #(SlClkLength/2);
          inSl1=0;
          #(SlClkLength/2);
          if (defectBitNumber == i) inSl0 = 0;
          #(SlClkLength/2);
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
 bit [31:0] msg;
 bit [31:0] lastCorrMsg;
 initial forever #(clkPeriod/2)clk=~clk;

    initial begin
        word_picked = 0;
        clk=0;
        currTestPassed = 1;
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
        for (SlClkLength = 32*clkPeriod; SlClkLength>=8*clkPeriod; SlClkLength/=2) begin // testing on all frequences
            $display ("Running all test on frequency: %d kHz", 16000/ SlClkLength *clkPeriod);
            for (int i=8;i<=32;i=i+2)begin // test on all word length
              makeConfig(i,0);
              testMassage(i,1);
                if (msg==data_w && status_w==16'b1000)begin
                  int gi;//$display("OK \n",i); // do nothing
                end else begin
                  $display("error with length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b1000);
                  currTestPassed = 0; //if erroe occurs we write error message
                end
            end
            writeTestResult(currTestPassed, 0, "1.a: 1 correct message all Length and PCE=0");
            for (int i=8;i<=32;i=i+2)begin // test on all word length
                makeConfig(i,1);
                testMassage(i,1);
                  if (msg==data_w && status_w==16'b1000)begin
                    int gi;//$display("OK \n",i); // do nothing
                  end else begin
                    $display("error with length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b1000);
                    currTestPassed = 0; //if erroe occurs we write error message
                  end
            end
            writeTestResult(currTestPassed, 0, "1.b: 1 correct message all Length and PCE=1  ");

            for (int i=8;i<=32;i=i+2)begin // test on all word length
                makeConfig(i,0);
                testMassage(i,1);
                testMassage(i,1);
                testMassage(i,1);
                  if (msg==data_w && status_w==16'b1000)begin
                    int gi;//$display("OK \n",i); // do nothing
                  end else begin
                    $display("error with length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b1000);
                    currTestPassed = 0; //if erroe occurs we write error message
                  end
             end
             writeTestResult(currTestPassed, 0, "2.a: 3 correct message all Length and PCE=0");
             for (int i=8;i<=32;i=i+2)begin // test on all word length
                 makeConfig(i,1);
                 testMassage(i,1);
                 testMassage(i,1);
                 testMassage(i,1);
                   if (msg==data_w && status_w==16'b1000)begin
                     int gi;//$display("OK \n",i); // do nothing
                   end else begin
                     $display("error with length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b1000);
                     currTestPassed = 0; //if erroe occurs we write error message
                   end
              end
              writeTestResult(currTestPassed, 0, "2.b: 3 correct message all Length and PCE=1");

           for (int i=8;i<=32;i=i+2)begin // test on all word length
               makeConfig(i,1);
               testMassage(i,1);
               lastCorrMsg = msg;
               testMassage(i,0);
               if (data_w != lastCorrMsg || status_w!=16'b11000)begin
                 $display("error with parity error, msg length = %d, %d != %d, %d != %d", i,  data_w, lastCorrMsg,  status_w, 16'b11000);
                 currTestPassed = 0; //if erroe occurs we write error message
               end
               testMassage(i,1);
               if (msg==data_w && status_w==16'b1000)begin
                 int gi;//$display("OK \n",i); // do nothing
               end else begin
                 $display("error with length = %d, %d != %d, %d != %d", i,  data_w, msg, status_w, 16'b1000);
                 currTestPassed = 0; //if erroe occurs we write error message
               end
            end
            writeTestResult(currTestPassed, 0, "3.a: one correct message then one with parity error and then one correct, PCE=1");

            for (int i=8;i<=32;i=i+2)begin // test on all word length
                makeConfig(i,1);
                testMassage(i,1);
                lastCorrMsg = msg;
                testMassage(i+2,0);
                if (data_w != lastCorrMsg || status_w!=16'b1001)begin
                  $display("error with length error, msg length = %d, %d != %d, %d != %d", i, msg, data_w,  status_w, 16'b1001);
                  currTestPassed = 0; //if erroe occurs we write error message
                end
                testMassage(i,1);
                if (msg==data_w && status_w==16'b1000)begin
                  int gi;//$display("OK \n",i); // do nothing
                end else begin
                  $display("error with length = %d, %d != %d, %d != %d", i,  data_w, msg, status_w, 16'b1000);
                  currTestPassed = 0; //if erroe occurs we write error message
                end
             end
             writeTestResult(currTestPassed, 0, "3.b: one correct message then one with length error and then one correct");


             for (int i=8;i<=32;i=i+2)begin // test on all word length
                 makeConfig(i,0);
                 testMassage(i,1);
                 lastCorrMsg = msg;
                 testMassage(i,0);
                 if (data_w != msg || status_w!=16'b11000)begin
                   $display("error with parity error, msg length = %d, %d != %d, %d != %d", i, msg, data_w,  status_w, 16'b11000);
                   currTestPassed = 0; //if erroe occurs we write error message
                 end
                 testMassage(i,1);
                 if (msg==data_w && status_w==16'b1000)begin
                   int gi;//$display("OK \n",i); // do nothing
                 end else begin
                   $display("error with length = %d, %d != %d, %d != %d", i,  data_w, msg, status_w, 16'b1000);
                   currTestPassed = 0; //if erroe occurs we write error message
                 end
              end
              writeTestResult(currTestPassed, 0, "3.c: one correct message then one with parity error and then one correct, PCE=0");

              for (int i=8;i<=32;i=i+2)begin // test on all word length
                  makeConfig(i,0);
                  testMassage(i,1);
                  lastCorrMsg = msg;
                  #40
                  bitPulse(0,1400);

                  if (status_w[5] != 1)begin
                    $display("error with level error, msg length = %d, %d != %d, %d != %d", i, lastCorrMsg , data_w,  status_w, 16'b100000);
                    currTestPassed = 0; //if erroe occurs we write error message
                  end
                  #40
                  bitPulse(1,1400);
                  if (status_w[5] != 1)begin
                    $display("error with level error, msg length = %d, %d != %d, %d != %d", i, lastCorrMsg , data_w,  status_w, 16'b100000);
                    currTestPassed = 0; //if erroe occurs we write error message
                  end
                  #40
                  testMassage(i,1);
                  if (msg==data_w && status_w==16'b1000)begin
                    int gi;//$display("OK \n",i); // do nothing
                  end else begin
                    $display("error with length = %d, %d != %d, %d != %d", i,  data_w, msg, status_w, 16'b1000);
                    currTestPassed = 0; //if erroe occurs we write error message
                  end
               end
               writeTestResult(currTestPassed, 0, "3.d: one correct message then level error and then one correct");

               for (int i=8;i<=32;i=i+2)begin // test on all word length
                 makeConfig(i,0);
                 testMassage(i,1);
                   if (msg==data_w && status_w==16'b1000)begin
                     int gi;//$display("OK \n",i); // do nothing
                   end else begin
                     $display("error with length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b1000);
                     currTestPassed = 0; //if erroe occurs we write error message
                   end
                   #clkPeriod;
                   word_picked = 1;
                   #clkPeriod;
                   word_picked = 0;
                   if (msg==data_w && status_w==16'b0000)begin
                     int gi;//$display("OK \n",i); // do nothing
                   end else begin
                     $display("error with word_picked with msg length = %d, %d != %d, %d != %d", i, msg, data_w, status_w, 16'b0000);
                     currTestPassed = 0; //if erroe occurs we write error message
                   end
               end
               writeTestResult(currTestPassed, 0, "5.e: word_picked test");
            $display("\n");
          end




          // SlClkLength = 32*clkPeriod;
          // makeConfig(8,1);
          // testMassage(8,1);
          // lastCorrMsg = msg;
          // writeTestResult((data_w==msg && data_w != lastCorrMsg && status_w==16'b1000), 0, "");
          // #40
          // bitPulse(0,1400);
          // writeTestResult(( status_w==16'b100000), 0, "");
          // #40
          // //writeTestResult((data_w == lastCorrMsg && status_w==16'b101000), 0, "");
          // bitPulse(1,1400);
          // writeTestResult(( status_w==16'b100000), 0, "");
          // #40
          //
          // testMassage(8,1);



          // makeConfig(8,1);
          // testMassageWithLE(8,1);
          $stop;
        end

        // for (int i=1;i<=3;i=i+1)begin
        //   int l = 8+$urandom_range(1,16)*2;
        //   $display("Test #%d: 1 correct message width PCE=0 l=%d",i,l);
        //   testMassage(l,l,0,1);
        //   writeTestResult((mes == data_w && status_w==16'b1000), 1, "");
      //
      // if(allTestsPassed) begin
      //   $display("All test passed");
      //  end else $display("Some tests failed");
      //  $stop;
      // end



endmodule
