module SL_transiever (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  input wire serial_line_zeroes_a,
  input wire serial_line_ones_a,
  // output wire sl0,
  // output wire sl1,

 // APB related signals
 //Master APB signals
  input wire pclk_a,
  input wire preset_n_a,
  input wire [ 7:0] paddr_a, //let's pretend that this is HIGHER bits of address space, i mean sys_addr[31:24].
  //input wire [ 3:0] pstrb_a, //remove this also
  //input wire pprot_a[2:0], //dont need this also
  input wire psel_a, //Cant work only with address checking cause of bi-directional data bus
  input wire penable_a,
  input wire pwrite_a,
  //Slave APB signals
  //output wire pready_a, //lets think we dont need this signal cause we'll make fixed two cycles access
  //output wire pslverr_a, //all status info there is in `status` register which is freely accessed any time
  inout wire [31:0] pdata_a

    );

parameter STROB_POS = 8;
parameter CONFIG_ADDRESS  = 0'b0001;
parameter DATA_ADDRESS_WR = 0'b0010;
parameter DATA_ADDRESS_R  = 0'b0100;
parameter STATUS_ADDRESS  = 0'b1000;

// parameter S0 = 5'b0_0000,
//           S1 = 5'b0_0001,
//           S2 = 5'b0_0010,
//           S3 = 5'b0_0011,
//           S4 = 5'b0_0100,
//           S5 = 5'b0_0101,
//           S6 = 5'b0_0110,
//           S7 = 5'b0_0111,
//           S8 = 5'b0_1000,
//           S9 = 5'b0_1001,
//           S10= 5'b0_1010;

parameter BIT_WAIT_FLUSH    = 0, //S0
          BIT_WAIT_NO_FLUSH = 1, //S1
          BIT_DETECTED      = 2, //S2
          STOP_BIT          = 3, //S3
          ONE_BIT           = 4, //S4
          ZERO_BIT          = 5, //S5
          GOT_WORD          = 6, //S6
          PAR_ERR           = 7, //S7
          LEN_ERR           = 8, //S8
          LEV_ERR           = 9, //S9
          WAIT_BIT_END     = 10; //S10

reg [ 10:0] state_r, next_r; //RECEIVER MODE: 0 - idle, 1 - receiveing started, 1a - bit detected, 1b - no bit, 1c - stop bit
                    //TRANSMITTER MODE: 0 - idle, 1 - sending a word



//APB resynchronisation registers
reg [ 7:0] sync1_paddr_r;
reg [31:0] sync1_pdata_r;
reg [ 7:0] sync1_misc_r; //we DO NOT sync 'pclk' and 'preset_n'

reg [ 7:0] in_paddr_r;
reg [31:0] in_pdata_r;
reg [ 7:0] in_misc_r;

//wire {pprot, psel, penable, pwrite, pstrb[3:0]};

//assign {pprot, psel, penable, pwrite, pstrb[3:0]} = in_misc_r[7:0];


// SL receiver related registers
reg [15:0] sl0_tmp_r; //shift regs to temporary store input sequence
reg [15:0] sl1_tmp_r;
reg [32:0] shift_data_r;
reg [ 5:0] cycle_cnt_r;
reg [ 5:0] bit_cnt_r;


reg [31:0] buffered_data_r;
reg [31:0] data_to_send_r;
reg [15:0] config_r; //[0] - parity check, [6:1] - bit cnt(8-32bits), [7] - rxtx mode, [8] - IRQ mode ####address on config_r is 0 (zero)
parameter PCE = 0;
reg [15:0] status_r; //[0] - word length fail, [1] - word receiveing process going, [2] - empty
                    //[3] - word received, [4] - parity error, [5] - level error on line,
reg parity_ones;
reg parity_zeroes;

//Synchronisation registers to read from corresponding registers via APB
reg [31:0] sync1_buffered_data_r;
reg [15:0] sync1_config_r;
reg [15:0] sync1_status_r;

reg [31:0] apb_buffered_data_r;
reg [15:0] apb_config_r;
reg [15:0] apb_status_r;
reg [31:0] apb_muxed_out_r;

//Synchronisation registers to write to corresponding registers via APB
reg [31:0] apb2sl_sync1_data_to_send_r;
reg [15:0] apb2sl_sync1_config_r;

reg [31:0] apb2sl_sync2_data_to_send_r;
reg [15:0] apb2sl_sync2_config_r;



reg [2:0] apb_state; //001 - IDLE, 010 - SETUP, 100 - ACCESS

wire bit_ended;
wire bit_started;


assign pdata_a = ( penable_a && psel_a && !pwrite_a ) ? apb_muxed_out_r : 32'bz;
assign bit_ended   = (sl0_tmp_r[7:0] == 8'hFF && sl1_tmp_r[7:0] == 8'hFF) ? 1 : 0;
assign bit_started = (sl0_tmp_r[15:12] == 4'hF && sl0_tmp_r[3:0] == 4'h0) || (sl1_tmp_r[15:12] == 4'hF && sl1_tmp_r[3:0] == 4'h0) ? 1 : 0;




always @(posedge clk or negedge rst_n or negedge preset_n_a) begin
  if( !rst_n || !preset_n_a ) begin
    state_r <= 10'b0;
    state_r[BIT_WAIT_FLUSH] <= 1'b1;
  end
  else  state_r <= next_r;
end



//always @(state_r or serial_line_ones_a or serial_line_zeroes_a or cycle_cnt_r or bit_cnt_r or bit_ended or parity_ones or parity_zeroes or config_r[PCE] or clk) begin
always @* begin
  next_r = 10'b0;
  case( 1'b1 ) // synopsys parallel_case
  //were (state_r), but here we using reverse case to make sure it compare only one bit in a vector
    state_r[   BIT_WAIT_FLUSH]: if( bit_started && bit_cnt_r[5:0] == 6'b00_0000 )                                   next_r[BIT_WAIT_NO_FLUSH] = 1'b1; //S1 - wait state w/ flush
                                else if( bit_started )                                                              next_r[     BIT_DETECTED] = 1'b1; //S0 - wait state w/o flush
                                else                                                                                next_r[   BIT_WAIT_FLUSH] = 1'b1;
    state_r[BIT_WAIT_NO_FLUSH]:                                                                                     next_r[     BIT_DETECTED] = 1'b1;
    state_r[     BIT_DETECTED]: if( cycle_cnt_r < STROB_POS )                                                       next_r[     BIT_DETECTED] = 1'b1; //
                                else if( !serial_line_ones_a && !serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[         STOP_BIT] = 1'b1; //Go to STOP bit routine
                                else if( !serial_line_ones_a &&  serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[          ONE_BIT] = 1'b1; //Go to ONE bit routine
                                else if(  serial_line_ones_a && !serial_line_zeroes_a && cycle_cnt_r == STROB_POS ) next_r[         ZERO_BIT] = 1'b1; //Go to ZERO bit routine
                                else                                                                                next_r[          LEV_ERR] = 1'b1; //Error condition, go to S9
    state_r[        STOP_BIT]: if( bit_cnt_r[5:0] == config_r[6:1] + 1 && (!config_r[PCE] | !(parity_ones | parity_zeroes)) )      next_r[GOT_WORD] = 1'b1; //Go to data ok routine
                               else if( bit_cnt_r[5:0] == config_r[6:1] + 1  && config_r[PCE] &&  (parity_ones | parity_zeroes) )  next_r[ PAR_ERR] = 1'b1;//Go to PEF routine
                               else                                                                                                next_r[ LEN_ERR] = 1'b1; //Go to WLF routine
    state_r[         ONE_BIT]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[        ZERO_BIT]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[        GOT_WORD]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[         PAR_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[         LEN_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[         LEV_ERR]: next_r[BIT_WAIT_FLUSH] = 1'b1;
    state_r[    WAIT_BIT_END]: if( bit_ended ) next_r[BIT_WAIT_FLUSH] = 1'b1;
                                 else          next_r[  WAIT_BIT_END] = 1'b1;
  endcase
end


always @(posedge clk or negedge rst_n or negedge preset_n_a) begin
  if( !rst_n | !preset_n_a ) begin
    sl0_tmp_r[15:0]       <= 16'hAAAA;
    sl1_tmp_r[15:0]       <= 16'hAAAA;
    shift_data_r[32:0]    <= 0;
    cycle_cnt_r[5:0]      <= 0;
    bit_cnt_r[5:0]        <= 0;
    buffered_data_r[31:0] <= 0;
    data_to_send_r[31:0]  <= 0;
    config_r[15:0]        <= 16'h0020;
    status_r[15:0]        <= 0;
    parity_zeroes         <= 0;
    parity_ones           <= 1;
    apb2sl_sync1_data_to_send_r <= 32'h0000_0000;
    apb2sl_sync1_config_r       <= 16'h0000;
    apb2sl_sync2_data_to_send_r <= 32'h0000_0000;
    apb2sl_sync2_config_r       <= 16'h0000;
    next_r <= 0;


  end else begin
      sl0_tmp_r[15:0] <= ( sl0_tmp_r << 1 ) | serial_line_zeroes_a ;
      sl1_tmp_r[15:0] <= ( sl1_tmp_r << 1 ) | serial_line_ones_a;

    //  case(next_r)
      case( 1'b1 ) // synopsys parallel_case
        next_r[BIT_WAIT_FLUSH], next_r[STOP_BIT], next_r[WAIT_BIT_END]: begin
              cycle_cnt_r <= 0;
            end
        next_r[BIT_WAIT_NO_FLUSH]: begin //wait state with flush
              status_r[15:0] <= 0;
            end
          next_r[BIT_DETECTED]: begin
              cycle_cnt_r <= cycle_cnt_r + 1;
              status_r[0] <= 0; //word length ok
              status_r[1] <= 1; //receiving process on
              status_r[3] <= 0; //Word received flag off
              status_r[4] <= 0; //no parity error atm
              status_r[5] <= 0; //no level errors on line
            end
        // S3: begin
        //
        //     end
        next_r[ONE_BIT]: begin
              shift_data_r <= ( shift_data_r >> 1 ) | ( 1 << config_r[6:1] ); //Store data in high bits of register
              parity_ones  <= parity_ones ^ 1;
              bit_cnt_r    <= bit_cnt_r + 1;
            end
        next_r[ZERO_BIT]: begin
              shift_data_r  <= ( shift_data_r >> 1 ) & ~( 1 << config_r[6:1] );
              parity_zeroes <= parity_zeroes ^ 1;
              bit_cnt_r     <= bit_cnt_r + 1;
            end
        next_r[GOT_WORD]: begin //DATA recevied correctly
              parity_zeroes <= 0;
              parity_ones   <= 1;
              shift_data_r  <= 0;
              bit_cnt_r     <= 0;
              cycle_cnt_r   <= 0;
              status_r[0]   <= 0; //word length ok
              status_r[1]   <= 0; //receiving process ended
              status_r[2]   <= 0; //as word correctly received, no noise on inout lines
              status_r[3]   <= 1; //word received
              status_r[4]   <= 0; //Dont care about parity value
              status_r[5]   <= 0; //no level errors on line
              buffered_data_r <= shift_data_r & ~( 1 << config_r[6:1] ); //Dont forget to wipeout parity bit
            end
        next_r[PAR_ERR]: begin
              parity_zeroes <= 0;
              parity_ones   <= 1;
              shift_data_r  <= 0;
              bit_cnt_r     <= 0;
              cycle_cnt_r   <= 0;
              status_r[0]   <= 0; //word length ok
              status_r[1]   <= 0; //receiving process ended
              status_r[2]   <= 0; //as word correctly received, no noise on inout lines
              status_r[3]   <= 1; //word received
              status_r[4]   <= 1; //Parity error detected
              status_r[5]   <= 0; //no level errors on line
              buffered_data_r <= 32'h0000_0000;
            end
        next_r[LEN_ERR]: begin
              parity_zeroes <= 0;
              parity_ones   <= 1;
              shift_data_r  <= 0;
              bit_cnt_r     <= 0;
              cycle_cnt_r   <= 0;
              status_r[0]   <= 1; //word length check error
              status_r[1]   <= 0; //receiving process ended
              status_r[2]   <= 0; //as word correctly received, no noise on inout lines
              status_r[3]   <= 1; //word received
              status_r[4]   <= 0; //Parity error detected
              status_r[5]   <= 0; //no level errors on line
              buffered_data_r <= 32'h0000_0000;
            end
        next_r[LEV_ERR]: begin
              parity_zeroes <= 0;
              parity_ones   <= 1;
              shift_data_r  <= 0;
              bit_cnt_r     <= 0;
              cycle_cnt_r   <= 0;
              status_r[0]   <= 0; //word length check error
              status_r[1]   <= 0; //receiving process ended
              status_r[2]   <= 0; //as word correctly received, no noise on inout lines
              status_r[3]   <= 0; //word received
              status_r[4]   <= 0; //Parity error detected
              status_r[5]   <= 1; // level errors on line
              buffered_data_r <= 32'h0000_0000;
            end
      endcase
    end
end



always @(posedge pclk_a or negedge rst_n or negedge preset_n_a) begin
  if ( !rst_n || !preset_n_a ) begin
    sync1_buffered_data_r <= 32'h0000_0000;
    sync1_config_r        <= 16'h0000;
    sync1_status_r        <= 16'h0000;

    apb_buffered_data_r   <= 32'h0000_0000;
    apb_config_r          <= 16'h0000;
    apb_status_r          <= 16'h0000;

  end
  else begin
    //First stage sync, have to do this cause we need to read data in two cycles, so data must be ready every time and all routines must work related to APB clk
    sync1_buffered_data_r <= buffered_data_r;
    sync1_config_r        <= config_r;
    sync1_status_r        <= status_r;

    //Second stage sync
    apb_buffered_data_r   <= sync1_buffered_data_r;
    apb_config_r          <= sync1_config_r;
    apb_status_r          <= sync1_status_r;

    if( psel_a && !penable_a ) begin
      if( pwrite_a ) begin // WRITE sequence
        case( paddr_a )
          CONFIG_ADDRESS:
            begin
              config_r[15:0] <= in_pdata_r[15:0];
            end
          DATA_ADDRESS_WR:
            begin
              data_to_send_r[31:0] <= in_pdata_r[31:0];
            end
          default:
            begin

            end
        endcase
      end
      else begin //READ sequence
        case( paddr_a )
          CONFIG_ADDRESS:
            begin
              apb_muxed_out_r[31:0] <= { 16'h0000, apb_config_r[15:0] };
            end
          DATA_ADDRESS_R:
            begin
              apb_muxed_out_r[31:0] <= apb_buffered_data_r[31:0];
            end
          STATUS_ADDRESS:
            begin
              apb_muxed_out_r[31:0] <= { 16'h0000, apb_status_r[15:0] };
            end
          default:
            begin
              apb_muxed_out_r[31:0] <= 32'h0000_0000;
            end
        endcase
      end
    end

  end
end


endmodule
