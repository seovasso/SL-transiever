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
  input wire  [9:0]wr_config_w,
  input wire wr_config_enable,
  output wire [9:0]r_config_w,
  output wire send_in_process,
  output reg  status_changed
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
reg [ 9:0] config_r;
reg [ 5:0] bitcnt_r;
reg [ 4:0] freq_devide_cnt_r;
reg parity_r;
reg sl0_r;
reg sl1_r;
reg status_r;

reg [4:0] freq_devide_cnt_max ;
wire[4:0] freq_devide_cnt_next;
wire[9:0] config_r_next; //Configuration register next value
wire[9:0] data_r_next; //Data register next value
wire      parity_next;
wire[5:0] bitcnt_r_next;
// Configuration register bits
parameter BQL  = 0, // bit quantity low bit
          BQH  = 5, // bit quantity high bit, BQH-BQL should be 5!
          IRQM = 6, // interrupt request mode
          FQL  = 7, // frequency mode low  bit
          FQH  = 9; // frequency mode high bit

assign SL0 = sl0_r;
assign SL1 = sl1_r;
assign r_config_w = config_r;
assign send_in_process = status_r;
//assign freq_devide_cnt_max = 6'b1 << config_r[FQH:FQH];

assign freq_devide_cnt_next = (freq_devide_cnt_r < freq_devide_cnt_max && !state_r[IDLE])? freq_devide_cnt_r+5'b1 : 5'd0;
assign bitcnt_r_next = (freq_devide_cnt_r == freq_devide_cnt_max ? bitcnt_r+1: bitcnt_r);
assign parity_next = (freq_devide_cnt_r == freq_devide_cnt_max ? ~parity_r : parity_r);

always @ ( * ) begin // frequency devider
  case (config_r[FQH:FQL])
  3'd0:   freq_devide_cnt_max = 5'b00001;//8МHz
  3'd1:   freq_devide_cnt_max = 5'b00011;//4МHz
  3'd2:   freq_devide_cnt_max = 5'b00111;//2МHz
  3'd3:   freq_devide_cnt_max = 5'b01111;//1МHz
  3'd4:   freq_devide_cnt_max = 5'b11111;//0.5МHz
  default:freq_devide_cnt_max = 5'b00001;//0.5МHz
  endcase
end

always @( posedge clk, negedge rst_n ) begin // frequency devider
  if( !rst_n ) begin
    freq_devide_cnt_r      <= 5'b0;
  end
  else  freq_devide_cnt_r <= freq_devide_cnt_next;
end

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
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[ START_SEND] = 1'b1;
      else if( txdata_r[bitcnt_r] )                                              next_r[        ONE] = 1'b1;
      else                                                                       next_r[       ZERO] = 1'b1;
    state_r[        ONE]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[        ONE] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[       ZERO]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[       ZERO] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[     PARITY]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[     PARITY] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[ BIT_ENDING]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[ BIT_ENDING] = 1'b1;
      else if( txdata_r[bitcnt_r] == 1'b1 && bitcnt_r[5:0] < config_r[BQH:BQL] ) next_r[        ONE] = 1'b1;
      else if( txdata_r[bitcnt_r] == 1'b0 && bitcnt_r[5:0] < config_r[BQH:BQL] ) next_r[       ZERO] = 1'b1;
      else if( bitcnt_r[5:0] == config_r[BQH:BQL])                               next_r[     PARITY] = 1'b1;
      else                                                                       next_r[       STOP] = 1'b1;
    state_r       [STOP]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[       STOP] = 1'b1;
      else                                                                       next_r[WORD_ENDING] = 1'b1;
    state_r[WORD_ENDING]:
      if( freq_devide_cnt_r != freq_devide_cnt_max)                              next_r[WORD_ENDING] = 1'b1;
      else                                                                       next_r[       IDLE] = 1'b1;
    //default:                                                                   next_r[       IDLE] = 1'b1;
  endcase
end

assign config_r_next = (wr_config_enable)? wr_config_w: config_r;
always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    txdata_r[31:0] <= 0;
    bitcnt_r[ 5:0] <= 0;
    config_r[ 9:0] <= 10'b0100001000;
    status_r       <= 0;
    parity_r       <= 0;
    sl0_r    <= 1;
    sl1_r    <= 1;
  end else begin
      case( 1'b1 ) // synopsys parallel_case
        next_r[        IDLE]: begin
                                if (send_imm && freq_devide_cnt_r == 5'b0) txdata_r <= data_a;
                                bitcnt_r <= 0;
                                status_r <= 1'b0;
                                config_r<=config_r_next;
                              end
        next_r[  START_SEND]: begin
                                if (send_imm && freq_devide_cnt_r == 5'b0) txdata_r <= data_a;
                                status_r <= 1'b1;
                              end
        next_r[         ONE]: begin
                                sl0_r    <= 1'b1;
                                sl1_r    <= 1'b0;
                                parity_r <= parity_next;
                              end
        next_r[        ZERO]: begin
                                sl0_r    <= 1'b0;
                                sl1_r    <= 1'b1;

                              end
        next_r[     PARITY]:  begin
                                sl0_r <=  ~parity_r;
                                sl1_r <=   parity_r;
                              end
        next_r[ BIT_ENDING]:  begin
                                bitcnt_r <= bitcnt_r_next;
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

wire status_changed_next;
assign status_changed_next =
      ((next_r[START_SEND] == 1'b1 && freq_devide_cnt_next == 5'd0) ||
       (next_r[IDLE] == 1'b1       && freq_devide_cnt_r==freq_devide_cnt_max))? 1:0;
always @(posedge clk, negedge rst_n)
if( !rst_n ) begin
  status_changed   <= 1'b0;
end else begin
  status_changed   <= status_changed_next;
end



endmodule
