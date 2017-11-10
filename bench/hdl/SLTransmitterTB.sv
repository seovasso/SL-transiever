`timescale 100ps / 1ps

module SlTransmitterTb();
    parameter clkPeriod=2;
    //
     logic        rst_n;
     logic        clk;

     logic        SL0;
     logic        SL1;

     logic [9:0]  wr_config_w;
     logic [9:0]  r_config_w;
     logic [31:0] data_a;
     logic        send_in_process;
     logic        send_imm;
     SL_transmitter trans(
        .rst_n          (rst_n          ),
        .clk            (clk            ),
        .SL0            (SL0            ),
        .SL1            (SL1            ),
        .data_a         (data_a         ),
        .send_imm       (send_imm       ),
        .wr_config_w    (wr_config_w    ),
        .r_config_w     (r_config_w     ),
        .send_in_process(send_in_process)
       );
       bit [31:0] message; // random message to send
       bit [5:0]  messageLength; // random message length to send
       logic  curTest,//текущий тест провален
              allTest;//все тесты провалены

  task sendRandomMassage;//отправляет SL посылку
    input int length;
    begin
    message = $urandom_range(2**length-1,0);
    data_a = message;
    #clkPeriod;
    send_imm = 1;
    #clkPeriod;
    data_a=0;
    send_imm=0;
    end
  endtask

  initial forever #(clkPeriod/2)clk=~clk;
  initial begin
  clk=0;
  data_a=0;
  send_imm=0;
  rst_n=1;
  #50;
  rst_n=0;
  #10;
  rst_n=1;
  #10;
  sendRandomMassage(5);
  end






endmodule
