module SL_receiver (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  input wire serial_line_zeroes_a,
  input wire serial_line_ones_a,
  input wire [15:0]wr_config_w,
  input wire       wr_enable, //signal enable write to config_r

  //Output data signals
  output wire [15:0]status_w,
  output wire [31:0]data_w,
  output wire [15:0]r_config_w
    );

parameter STROB_POS = 8,
          CONFIG_ADDRESS  = 0'b0001,
          DATA_ADDRESS_WR = 0'b0010,
          DATA_ADDRESS_R  = 0'b0100,
          STATUS_ADDRESS  = 0'b1000;

parameter BIT_WAIT_FLUSH    = 0,
          BIT_WAIT_NO_FLUSH = 1,
          BIT_DETECTED      = 2,
          STOP_BIT          = 3,
          ONE_BIT           = 4,
          ZERO_BIT          = 5,
          GOT_WORD          = 6,
          PAR_ERR           = 7,
          LEN_ERR           = 8,
          LEV_ERR           = 9,
          WAIT_BIT_END     = 10;

reg [ 10:0] state_r, next_r;

// SL receiver related registers
reg [15:0] sl0_tmp_r, sl1_tmp_r;   //shift regs to multisample input sequence
reg [32:0] shift_data_r;           //temp shift reg to store sl word
reg [31:0] buffered_data_r;        //last got SL word
reg [ 5:0] cycle_cnt_r, bit_cnt_r; //misc counters
reg parity_ones, parity_zeroes;    //parity registers

reg [15:0] config_r;
parameter PCE  = 0, // parity check enable
          BQL  = 1, // bit quantity low bit
          BQH  = 6, // bit quantity high bit
          MODE = 7, // rx tx mode
          IRQM = 8; //interrupt request mode

reg [15:0] status_r;
parameter WLC = 0, //word length check result
          WRP = 1, //word receiving status
          WRF = 3, //word received flag
          PEF = 4, //parity error flag
          LEF = 5; //level error on line flag

wire bit_ended, bit_started;
wire [15:0] config_r_next; //change config_r wire

assign config_r_next = (wr_enable && bit_cnt_r == 6'd0 && wr_config_w[BQH:BQL]>6'd7)? wr_config_w: config_r;
assign status_w = status_r;
assign r_config_w=config_r;
assign data_w   = buffered_data_r;
assign bit_ended   = (sl0_tmp_r[7:0] == 8'hFF && sl1_tmp_r[7:0] == 8'hFF) ? 1 : 0;
assign bit_started = (sl0_tmp_r[15:12] == 4'hF && sl0_tmp_r[3:0] == 4'h0) || (sl1_tmp_r[15:12] == 4'hF && sl1_tmp_r[3:0] == 4'h0) ? 1 : 0;
assign config_r_next = (wr_enable && bit_cnt_r == 6'd0 && wr_config_w[BQH:BQL]>6'd8)? wr_config_w: config_r;

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    state_r <= 10'b0;
    state_r[BIT_WAIT_FLUSH] <= 1'b1;
  end
  else  state_r <= next_r;
end


//always @(state_r or serial_line_ones_a or serial_line_zeroes_a or cycle_cnt_r or bit_cnt_r or bit_ended or parity_ones or parity_zeroes or config_r[PCE] or clk) begin
always @* begin
  next_r = 10'b0;
  case( 1'b1 ) // synopsys parallel_case
  //here we using reverse case to make sure it compare only one bit in a vector
    state_r[BIT_WAIT_FLUSH]: if( bit_started && bit_cnt_r[5:0] == 6'b00_0000 )                         next_r[BIT_WAIT_NO_FLUSH] = 1'b1;
                                else if( bit_started )                                                 next_r[     BIT_DETECTED] = 1'b1;
                                else                                                                   next_r[   BIT_WAIT_FLUSH] = 1'b1;
    state_r[BIT_WAIT_NO_FLUSH]:                                                                        next_r[     BIT_DETECTED] = 1'b1;
    state_r[ BIT_DETECTED]: if( cycle_cnt_r < STROB_POS )                                              next_r[     BIT_DETECTED] = 1'b1;
                            else if( !serial_line_ones_a && !serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[STOP_BIT] = 1'b1;
                            else if( !serial_line_ones_a &&  serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[ ONE_BIT] = 1'b1;
                            else if(  serial_line_ones_a && !serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[ZERO_BIT] = 1'b1;
                            else                                                                                next_r[ LEV_ERR] = 1'b1;
    state_r[     STOP_BIT]: if( bit_cnt_r[5:0] == config_r[BQH:BQL] + 1 && (!config_r[PCE] | !(parity_ones | parity_zeroes)) )      next_r[GOT_WORD] = 1'b1;
                            else if( bit_cnt_r[5:0] == config_r[BQH:BQL] + 1  && config_r[PCE] &&  (parity_ones | parity_zeroes) )  next_r[ PAR_ERR] = 1'b1;
                            else                                                                                                    next_r[ LEN_ERR] = 1'b1;
    state_r[      ONE_BIT]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[     ZERO_BIT]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[     GOT_WORD]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[      PAR_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[      LEN_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[      LEV_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[ WAIT_BIT_END]: if( bit_ended ) next_r[BIT_WAIT_FLUSH] = 1'b1;
                            else            next_r[  WAIT_BIT_END] = 1'b1;
    //default:                next_r[BIT_WAIT_FLUSH] = 1'b1;
  endcase
end


always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    sl0_tmp_r[15:0]       <= 16'hAAAA;
    sl1_tmp_r[15:0]       <= 16'hAAAA;
    shift_data_r[32:0]    <= 1'b0;
    cycle_cnt_r[5:0]      <= 1'b0;
    bit_cnt_r[5:0]        <= 1'b0;
    buffered_data_r[31:0] <= 1'b0;
    config_r[15:0]        <= 16'h0010;
    status_r[15:0]        <= 1'b0;
    parity_zeroes         <= 1'b0;
    parity_ones           <= 1'b1;


  end else begin
      sl0_tmp_r[15:0] <= ( sl0_tmp_r << 1 ) | serial_line_zeroes_a ;
      sl1_tmp_r[15:0] <= ( sl1_tmp_r << 1 ) | serial_line_ones_a;

      case( 1'b1 ) // synopsys parallel_case
      next_r[BIT_WAIT_FLUSH]: begin
            cycle_cnt_r <= 0;
            config_r<=config_r_next;
          end
        next_r[STOP_BIT], next_r[WAIT_BIT_END]: begin
              cycle_cnt_r <= 0;
            end
        next_r[BIT_WAIT_NO_FLUSH]: begin
              status_r[15:0] <= 0;
            end
        next_r[BIT_DETECTED]: begin
              cycle_cnt_r <= cycle_cnt_r + 1;
              status_r[WLC] <= 0;
              status_r[WRP] <= 1;
              status_r[WRF] <= 0;
              status_r[PEF] <= 0;
              status_r[LEF] <= 0;
            end
        next_r[ONE_BIT]: begin
              //Store data in high bits of register
              shift_data_r <= ( shift_data_r >> 1 ) | ( 1 << config_r[BQH:BQL] );
              parity_ones  <= parity_ones ^ 1;
              bit_cnt_r    <= bit_cnt_r + 1;
            end
        next_r[ZERO_BIT]: begin
              shift_data_r  <= ( shift_data_r >> 1 ) & ~( 1 << config_r[BQH:BQL] );
              parity_zeroes <= parity_zeroes ^ 1;
              bit_cnt_r     <= bit_cnt_r + 1;
            end
        next_r[GOT_WORD]: begin
              parity_zeroes   <= 0;
              parity_ones     <= 1;
              shift_data_r    <= 0;
              bit_cnt_r       <= 0;
              cycle_cnt_r     <= 0;
              status_r[WLC]   <= 0;
              status_r[WRP]   <= 0;
              status_r[WRF]   <= 1;
              status_r[PEF]   <= 0;
              status_r[LEF]   <= 0;
              //Dont forget to wipeout parity bit
              buffered_data_r <= shift_data_r & ~( 1 << config_r[BQH:BQL] );
            end
        next_r[PAR_ERR]: begin
              parity_zeroes   <= 0;
              parity_ones     <= 1;
              shift_data_r    <= 0;
              bit_cnt_r       <= 0;
              cycle_cnt_r     <= 0;
              status_r[WLC]   <= 0;
              status_r[WRP]   <= 0;
              status_r[WRF]   <= 1;
              status_r[PEF]   <= 1;
              status_r[LEF]   <= 0;
              buffered_data_r <= 32'h0000_0000;
            end
        next_r[LEN_ERR]: begin
              parity_zeroes   <= 0;
              parity_ones     <= 1;
              shift_data_r    <= 0;
              bit_cnt_r       <= 0;
              cycle_cnt_r     <= 0;
              status_r[WLC]   <= 1;
              status_r[WRP]   <= 0;
              status_r[WRF]   <= 1;
              status_r[PEF]   <= 0;
              status_r[LEF]   <= 0;
              buffered_data_r <= 32'h0000_0000;
            end
        next_r[LEV_ERR]: begin
              parity_zeroes   <= 0;
              parity_ones     <= 1;
              shift_data_r    <= 0;
              bit_cnt_r       <= 0;
              cycle_cnt_r     <= 0;
              status_r[WLC]   <= 0;
              status_r[WRP]   <= 0;
              status_r[WRF]   <= 0;
              status_r[PEF]   <= 0;
              status_r[LEF]   <= 1;
              buffered_data_r <= 32'h0000_0000;
            end
      endcase
    end
end

endmodule
