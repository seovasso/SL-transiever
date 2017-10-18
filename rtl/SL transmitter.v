module SL_transmitter (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  output wire SL0,
  output wire SL1,

  // Data and command from master
  input wire [31:0] data_a,
  input wire send_imm,
  input wire  [7:0]wr_config_w,
  output wire [7:0]r_config_w,
  output wire send_in_process
    );



parameter IDLE        = 0,
          START_SEND  = 1,
          ONE         = 2,
          ZERO        = 3,
          PARITY      = 4,
          BIT_ENDING  = 5,
          STOP        = 6,
          WORD_ENDING = 7;

reg [31:0] txdata_r;
reg [ 7:0] state_r;
reg [ 7:0] next_r;
reg [ 7:0] config_r;
reg [ 5:0] bitcnt_r;
reg parity_r;
reg sl0_r;
reg sl1_r;
reg status_r;





// Configuration register bits
parameter BQL  = 0, // bit quantity low bit
          BQH  = 5, // bit quantity high bit, BQH-BQL should be 5!
          IRQM = 6; // interrupt request mode

assign SL0 = sl0_r;
assign SL1 = sl1_r;
assign send_in_process = status_r;


always @( posedge clk, negedge rst_n ) begin
  if( !rst_n ) begin
    state_r       <= 8'b0;
    state_r[IDLE] <= 1'b1;
  end
  else  state_r <= next_r;
end



always @* begin
  next_r = 8'b0;
  case( 1'b1 ) // synopsys parallel_case
  //were (state_r), but here we using reverse case to make sure it compare only one bit in a vector
    state_r[       IDLE]: if( send_imm && !status_r )                            next_r[ START_SEND] = 1'b1;
                          else                                                   next_r[       IDLE] = 1'b1;
    state_r[ START_SEND]:
      if( txdata_r[bitcnt_r] )                                                   next_r[        ONE] = 1'b1;
      else                                                                       next_r[       ZERO] = 1'b1;
    state_r[        ONE]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[       ZERO]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[     PARITY]:                                                        next_r[ BIT_ENDING] = 1'b1;
    state_r[ BIT_ENDING]:
      if(      txdata_r[bitcnt_r] == 1'b1 && bitcnt_r[5:0] < config_r[BQH:BQL])  next_r[        ONE] = 1'b1;
      else if( txdata_r[bitcnt_r] == 1'b0 && bitcnt_r[5:0] < config_r[BQH:BQL] ) next_r[       ZERO] = 1'b1;
      else if( bitcnt_r[5:0] == config_r[BQH:BQL])                               next_r[     PARITY] = 1'b1;
      else                                                                       next_r[       STOP] = 1'b1;
    state_r       [STOP]:                                                        next_r[WORD_ENDING] = 1'b1;
    state_r[WORD_ENDING]:                                                        next_r[       IDLE] = 1'b1;
  endcase
end


always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    txdata_r[31:0] <= 0;
    bitcnt_r[ 5:0] <= 0;
    config_r[ 7:0] <= 16'h0020;
    status_r       <= 0;
    parity_r       <= 0;
    next_r         <= 0;
    sl0_r    <= 1;
    sl1_r    <= 1;
    send_now <= 0;

  end else begin
      case( 1'b1 ) // synopsys parallel_case
        next_r[        IDLE]: begin
                                txdata_r <= data_a;
                                bitcnt_r <= 0;
                                status_r <= 1'b0;
                              end
        next_r[  START_SEND]: begin
                                send_now <= 1'b0;
                                status_r <= 1'b1;
                              end
        next_r[         ONE]: begin
                                sl0_r    <= 1'b1;
                                sl1_r    <= 1'b0;
                                parity_r <= parity_r ^ 1;
                              end
        next_r[        ZERO]: begin
                                sl0_r    <= 1'b0;
                                sl1_r    <= 1'b1;
                                parity_r <= parity_r ^ 0;
                              end
        next_r[     PARITY]:  begin
                                sl0_r <=  ~parity_r;
                                sl1_r <=   parity_r;
                              end
        next_r[ BIT_ENDING]:  begin
                                bitcnt_r <= bitcnt_r + 1;
                                sl1_r    <= 1'b1;
                                sl0_r    <= 1'b1;
                              end
        next_r[       STOP]:  begin
                                sl1_r <= 1'b0;
                                sl0_r <= 1'b0;
                              end
        next_r[WORD_ENDING]:  begin
                                sl1_r <= 1'b1;
                                sl0_r <= 1'b1;
                              end

      endcase
    end
end

endmodule
