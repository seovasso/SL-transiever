`timescale 100ps / 1ps

module SlTransmitterTb();
    parameter clkPeriod=2;
    //for ideal reciever
    logic wordInProces;
    logic wordReady;
    logic [6:0] bitCount;
    logic [31:0] dataOut;
    logic parityValid;


    // for transmitter
     logic        rst_n;
     logic        clk;

     logic        SL0;
     logic        SL1;

     logic [9:0]  wr_config_w;
     logic [9:0]  r_config_w;
     logic [31:0] data_a;
     logic        send_in_process;
     logic        send_imm;
     logic        wr_config_enable;
     logic        status_changed;
     SL_transmitter trans(
        .rst_n            (rst_n           ),
        .clk              (clk             ),
        .SL0              (SL0             ),
        .SL1              (SL1             ),
        .data_a           (data_a          ),
        .send_imm         (send_imm        ),
        .wr_config_w      (wr_config_w     ),
        .r_config_w       (r_config_w      ),
        .wr_config_enable (wr_config_enable),
        .send_in_process  (send_in_process ),
        .status_changed   (status_changed  )
       );
    SlTestIdeallReciever rec (.rst_n(rst_n),
                              .sl0(SL0),
                              .sl1(SL1),
                              .wordInProces(wordInProces),
                              .wordReady(wordReady),
                              .bitCount(bitCount),
                              .dataOut(dataOut),
                              .parityValid(parityValid));

     logic [31:0] message; // random message to send
     int  messageLength; // random message length to send
     logic  currTestPassed,//текущий тест пройден
            allTestsPassed;//все тесты пройены
     int  frequency_mode;

  task sendRandomMassage;//отправляет SL посылку
    input int length;
    begin
    message = $urandom_range((1<<length-1),0);
    data_a = message;
    send_imm = 1;
    #clkPeriod;
    data_a = 0;
    send_imm = 0;
    end
  endtask
  task configureTransmitter;//отправляет SL посылку
    input int length;
    input int frequency_mode;
    begin
    #(1);
    wr_config_w={frequency_mode[2:0],1'b0,length[5:0]};
    wr_config_enable=1;
    #(clkPeriod);
    wr_config_w=0;
    wr_config_enable=0;
    #(clkPeriod-1);

    end
  endtask


  initial forever #(clkPeriod/2)clk=~clk;
  initial begin
  wr_config_w = 0;
  wr_config_enable = 0;
  clk = 0;
  data_a = 0;
  send_imm = 0;
  rst_n = 1;
  #(clkPeriod/2);
  #50;
  rst_n = 0;
  #10;
  rst_n = 1;
  #10;
  //Test 1
  for (int i=0; i<6; i++) begin: test_N
    currTestPassed = 1;
    frequency_mode = $urandom_range(0,5);
    messageLength = 8+$urandom_range(0,12)*2;
    configureTransmitter(messageLength,frequency_mode);
    sendRandomMassage(messageLength);
    wait(~send_in_process);
    if (dataOut != message || bitCount != messageLength || !parityValid) begin
    currTestPassed = 0;
    allTestsPassed = 0;
    end
    $display ("Test #1: massage length=%d frequency=%d %s ",
    frequency_mode,messageLength,(currTestPassed?"passed":"failed"));
  end: test_N
  $display ("All Tests:  %s ",(allTestsPassed?"passed":"failed"));

  end
always @send_in_process begin
    if (!status_changed) begin
      $display ("status_changed test failed");
      allTestsPassed = 0;
    end
end





endmodule
