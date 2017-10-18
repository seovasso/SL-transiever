module SL_transmitter (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  output wire SL0,
  output wire SL1,

  // Data and command from master
  input wire [31:0] data_a,
  input wire send_imm
    );



parameter IDLE        = 0,
          START_SEND  = 1,
          ONE         = 2,
          ZERO        = 3,
          PARITY      = 4,
          BIT_ENDING  = 5,
          STOP        = 6,
          WORD_ENDING = 7;

reg [ 7:0] state_r, next_r;
reg send_now;
reg parity_r;
reg sl0_r, sl1_r;
// SL transmitter related registers
reg [ 5:0] bit_cnt_r;

reg [31:0] data_r;

reg [15:0] config_r;
parameter PCE  = 0, // parity check enable
          BQL  = 1, // bit quantity low bit
          BQH  = 6, // bit quantity high bit, BQH-BQL should be 5!
          MODE = 7, // rx tx mode
          IRQM = 8; //interrupt request mode

reg [15:0] status_r;

parameter WLC = 0, //word length check result
          WRP = 1, //word receiving status
          WRF = 3, //word received flag
          PEF = 4, //parity error flag
          LEF = 5, //level error on line flag
          SIP = 6; //sending in process

          assign SL0 = sl0_r;
          assign SL1 = sl1_r;



always @( posedge clk, negedge rst_n ) begin
  if( !rst_n ) begin
    state_r <= 8'b0;
    state_r[IDLE] <= 1'b1;
  end
  else  state_r <= next_r;
end



always @* begin
  next_r = 8'b0;
  case( 1'b1 ) // synopsys parallel_case
  //were (state_r), but here we using reverse case to make sure it compare only one bit in a vector
    state_r[       IDLE]: if( send_imm && !status_r[SIP])                        next_r[       SEND] = 1'b1;
                          else                                                   next_r[       IDLE] = 1'b1;
    state_r[ START_SEND]:
      if(    data_r[bit_cnt_r] == 1'b1 && bit_cnt_r[5:0] <= config_r[BQH:BQL])   next_r[  ONE] = 1'b1;
      else ( data_r[bit_cnt_r] == 1'b0 && bit_cnt_r[5:0] <= config_r[BQH:BQL] )  next_r[ ZERO] = 1'b1;
    state_r[        ONE]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[       ZERO]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[     PARITY]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[ BIT_ENDING]:
      if(      data_r[bit_cnt_r] == 1'b1 && bit_cnt_r[5:0] < config_r[BQH:BQL])  next_r[   ONE] = 1'b1;
      else if( data_r[bit_cnt_r] == 1'b0 && bit_cnt_r[5:0] < config_r[BQH:BQL] ) next_r[  ZERO] = 1'b1;
      else if( bit_cnt_r[5:0] == config_r[BQH:BQL])                              next_r[PARITY] = 1'b1;
      else                                                                       next_r[       STOP] = 1'b1;
    state_r       [STOP]:                                                        next_r[WORD_ENDING] = 1'b1;
    state_r[WORD_ENDING]:                                                        next_r[       IDLE] = 1'b1;
  endcase
end


always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    data_r[31:0]  <= 0;
    bit_cnt_r[5:0]        <= 0;
    config_r[15:0]        <= 16'h0020;
    status_r[15:0]        <= 0;
    parity_r              <= 0;
    next_r                <= 0;
    sl0_r <= 1;
    sl1_r <= 1;
    send_now <= 0;

  end else begin
      case( 1'b1 ) // synopsys parallel_case
        next_r[        IDLE]: begin
                                send_now  <= send_imm;
                                data_r    <= data_a;
                                bit_cnt_r <= 0;
                              end
        next_r[  START_SEND]: begin
                                send_now <= 1'b0;
                                status_r[SIP] <= 1'b1;
                              end
        next_r[         ONE]: begin
                                sl0_r <= 1'b1;
                                sl1_r <= 1'b0;
                                parity_r <= parity_r ^ 1;
                              end
        next_r[        ZERO]: begin
                                sl0_r <= 1'b0;
                                sl1_r <= 1'b1;
                                parity_r <= parity_r ^ 0;
                              end
        next_r[     PARITY]:  begin
                                sl0_r <=  ~parity_r;
                                sl1_r <=   parity_r;
                              end
        next_r[ BIT_ENDING]:  begin
                                bit_cnt_r <= bit_cnt_r + 1;
                                sl1_r <= 1'b1;
                                sl0_r <= 1'b1;
                              end
        next_r[       STOP]:  begin
                                sl1_r <= 1'b0;
                                sl0_r <= 1'b0;
                              end
        next_r[WORD_ENDING]:  begin
                                sl1_r <= 1'b1;
                                sl0_r <= 1'b1;
                                status_r[SIP] <= 1'b0;
                              end

      endcase
    end
end

endmodule
