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
     logic [31:0] d_in;
     logic [31:0] d_out;
     logic wr_en;
     logic addr;
     SlTransmitter trans(
        .rst_n            (rst_n),
        .clk              (clk  ),
        .SL0              (SL0  ),
        .SL1              (SL1  ),
        .d_in             (d_in ),
        .d_out            (d_out),
        .wr_en            (wr_en),
        .addr             (addr )
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
    #(1);
    d_in    = message;
    addr    = 0;
    wr_en   = 1;
    #clkPeriod;
    d_in    = 0;
    addr    = 0;
    wr_en   = 0;
    #(clkPeriod-1);
    end
  endtask
  task configureTransmitter;//отправляет SL посылку
    input int length;
    input int frequency_mode;
    begin
    #(1);
    d_in=32'b0|{frequency_mode[2:0],1'b0,length[5:0]};
    addr    = 1;
    wr_en   = 1;
    #(clkPeriod);
    d_in    = 0;
    addr    = 0;
    wr_en   = 0;
    #(clkPeriod-1);

    end
  endtask
int buff;

  initial forever #(clkPeriod/2)clk=~clk;
  initial begin

  wr_en = 0;
  clk = 0;
  d_in = 0;
  addr = 0;
  rst_n = 1;
  #(clkPeriod/2);
  #50;
  rst_n = 0;
  #10;
  rst_n = 1;
  #10;

    sendRandomMassage(8);
    addr = 1;
    #clkPeriod;
    wait(~d_out[16]);
    #clkPeriod;
    sendRandomMassage(8);
    addr = 1;
    #(clkPeriod*10);
    buff = d_out;
    buff = buff & ~(32'b1<<24);
    d_in = buff;
    wr_en = 1;
    #clkPeriod;
    wr_en=0;


  #500;
  //Test 1
  // for (int i=0; i<6; i++) begin: test_N
  //   currTestPassed = 1;
  //   frequency_mode = $urandom_range(0,5);
  //   messageLength = 8+$urandom_range(0,12)*2;
  //   configureTransmitter(messageLength,frequency_mode);
  //   sendRandomMassage(messageLength);
  //   addr = 1;
  //   #clkPeriod;
  //   $display("%b", d_out[16])ж
  //   wait(~d_out[16]);
  //
  //   addr    = 0;
  //   if (dataOut != message)  begin
  //     $display("Косяк в сообщении %b != %b", dataOut, message);
  //     currTestPassed = 0;
  //     allTestsPassed = 0;
  //   end
  //   if ( bitCount != messageLength) begin
  //     $display("Косяк в количестве бит %d != %d",  bitCount, messageLength);
  //     currTestPassed = 0;
  //     allTestsPassed = 0;
  //   end
  //   if ( parityValid) begin
  //     $display("Косяк в четности",  bitCount, messageLength);
  //     currTestPassed = 0;
  //     allTestsPassed = 0;
  //   end
  //   addr = 0;
  //   $display ("Test #1: massage length=%d frequency=%d %s ",
  //   frequency_mode,messageLength,(currTestPassed?"passed":"failed"));
  // end: test_N
  // $display ("All Tests:  %s ",(allTestsPassed?"passed":"failed"));
  $stop();
  end






endmodule
