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
reg [31:0] shift_data_r;
reg [ 5:0] cycle_cnt_r;
reg [ 5:0] bit_cnt_r;
reg [ 4:0] state_r; //RECEIVER MODE: 0 - idle, 1 - receiveing started, 1a - bit detected, 1b - no bit, 1c - stop bit
                    //TRANSMITTER MODE: 0 - idle, 1 - sending a word

reg [31:0] buffered_data_r;
reg [31:0] data_to_send_r;
reg [15:0] config_r; //[0] - parity check, [6:1] - bit cnt(8-32bits), [7] - rxtx mode, [8] - IRQ mode ####address on config_r is 0 (zero)
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
reg [31:0] sync1_data_to_send_r;
reg [15:0] sync3_config_r;

reg [31:0] sync2_data_to_send_r;
reg [15:0] sync2_config_r;



reg [2:0] apb_state; //001 - IDLE, 010 - SETUP, 100 - ACCESS




assign pdata_a = ( penable_a && psel_a && !pwrite_a ) ? apb_muxed_out_r : 32'bz;






always @(posedge clk or negedge rst_n or negedge preset_n_a) begin 
if( !rst_n | !preset_n_a ) begin
  sl0_tmp_r[15:0]       <= 16'hAAAA;
  sl1_tmp_r[15:0]       <= 16'hAAAA;
  shift_data_r[31:0]    <= 0;
  cycle_cnt_r[5:0]      <= 0;
  bit_cnt_r[5:0]        <= 0;
  state_r[4:0]          <= 5'b00001;
  buffered_data_r[31:0] <= 0;
  data_to_send_r[31:0]  <= 0;
  config_r[15:0]        <= 16'h0020;
  status_r[15:0]        <= 0;   
  parity_zeroes         <= 0;
  parity_ones           <= 1;   
end else  if( !config_r[7] )  //RECEIVER ROUTINE
  begin
    sl0_tmp_r[15:0] <= ( sl0_tmp_r << 1 ) | serial_line_zeroes_a ;
    sl1_tmp_r[15:0] <= ( sl1_tmp_r << 1 ) | serial_line_ones_a;
    case (state_r)
      5'b00001: begin //IDLE state, waiting for active transmission sequence on one of input lines
                  if( (sl0_tmp_r[15:12] == 4'hF && sl0_tmp_r[3:0] == 4'h0) || (sl1_tmp_r[15:12] == 4'hF && sl1_tmp_r[3:0] == 4'h0) )
                  begin
                    state_r <= state_r << 1;
                    cycle_cnt_r <= 3;
                    status_r[0] <= 0; //word length ok
                    status_r[1] <= 1; //receiving process on
                    status_r[3] <= 0; //Word received flag off
                    status_r[4] <= 0; //no parity error atm
                    status_r[5] <= 0; //no level errors on line
                  end
                  else begin
                    status_r[0] <= 0; //word length ok
                    status_r[1] <= 0; //receiving process off
                    status_r[3] <= 0; //Word received flag off
                    status_r[4] <= 0; //no parity error atm
                    status_r[5] <= 0; //no level errors on line
                  end
                end
      5'b00010: begin //RECEIVING state
                  if( cycle_cnt_r == STROB_POS )
                  begin
                    state_r <= state_r << 1;
                    if ( !serial_line_ones_a && !serial_line_zeroes_a ) //Если стоп-бит
                    begin
                      parity_zeroes <= 0;
                      parity_ones   <= 1;
                      shift_data_r  <= 0;
                      bit_cnt_r     <= 0;
                      if( bit_cnt_r[5:0] == config_r[6:1] ) //Проверяем количество принятых разрядов
                      begin
                        status_r[0] <= 0; //word length ok
                        status_r[1] <= 0; //receiving process ended
                        status_r[2] <= 0; //as word correctly received, no noise on inout lines
                        status_r[3] <= 1; //word received

                        if( (parity_zeroes || !parity_ones ) && config_r[0] )  buffered_data_r <= 0;
                        else  buffered_data_r <= shift_data_r;
                      end
                      else begin
                        status_r[0] <= 1; //word length fail
                        status_r[1] <= 0; //receiving process ended
                        status_r[2] <= 0; //as word correctly received, no noise on inout lines
                        status_r[3] <= 0; //word is not received
                      end

                      if( !parity_zeroes && !parity_ones ) status_r[4] <= 0; //parity ok
                      else status_r[4] <= 1; //parity check fail
                    end
                    else 
                    begin
                      if( bit_cnt_r[5:0] < config_r[6:1] ) begin  //not parity bit
                        if ( !serial_line_ones_a ) //Если единичка
                          begin
                            shift_data_r <= ( shift_data_r >> 1 ) | ( 1 << config_r[6:1] - 1 ); //Store data in high bits of register
                            parity_ones  <= parity_ones ^ 1;
                            bit_cnt_r <= bit_cnt_r + 1;
                          end
                          else  if( !serial_line_zeroes_a )  //Если нолик
                            begin
                              shift_data_r  <= ( shift_data_r >> 1 ) & ~( 1 << config_r[6:1] -1 );
                              parity_zeroes <= parity_zeroes ^ 1;
                              bit_cnt_r <= bit_cnt_r + 1;
                            end
                            else begin // Expected data on line, but there is no data, so flush all registers and go back to IDEL state
                              status_r[0] <= 0; //word length ok
                              status_r[1] <= 0; //receiving process ended
                              status_r[2] <= 0; //as word correctly received, no noise on inout lines
                              status_r[3] <= 0; //word is not received
                              status_r[4] <= 0; //no parity error atm
                              status_r[5] <= 1; //level errors on line

                              sl0_tmp_r[15:0]       <= 16'hAAAA;
                              sl1_tmp_r[15:0]       <= 16'hAAAA;
                              shift_data_r[31:0]    <= 0;
                              cycle_cnt_r[5:0]      <= 0;
                              bit_cnt_r[5:0]        <= 0;
                              state_r[4:0]          <= 5'b00001;
                              buffered_data_r[31:0] <= 0;
                              data_to_send_r[31:0]  <= 0;
                              parity_zeroes         <= 0;
                              parity_ones           <= 1; 
                            end
                      end
                    end
                  end
                  else cycle_cnt_r <= cycle_cnt_r + 1;
                end    
      5'b00100: begin //WAITING for bit transmission end state
                  if( sl0_tmp_r[7:0] == 8'hFF && sl1_tmp_r[7:0] == 8'hFF )
                  begin
                    state_r <= state_r >> 2; //go to the IDLE state
                    cycle_cnt_r <= 0;
                  end
                  else cycle_cnt_r <= cycle_cnt_r + 1;
                end
      default: state_r <= 5'b00001;
    endcase
  end
  else begin //TRANSMITTER routine
    state_r <= 5'b00001;
  end

end

always @(posedge pclk_a or negedge rst_n or negedge preset_n_a) begin
  if ( !rst_n || !preset_n_a ) begin
    // sync1_buffered_data_r <= 32'h0000_0000;
    // sync1_config_r        <= 16'h0000;
    // sync1_status_r        <= 16'h0000;

    // apb_buffered_data_r   <= 32'h0000_0000;
    // apb_config_r          <= 16'h0000;
    // apb_status_r          <= 16'h0000;
    
        
    sync1_buffered_data_r <= 32'h0000_0000;
    sync1_config_r        <= config_r;
    sync1_status_r        <= status_r;

    //Second stage sync
    apb_buffered_data_r   <= sync1_buffered_data_r;
    apb_config_r          <= sync1_config_r;
    apb_status_r          <= sync1_status_r;

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

    // case( apb_state )
    // 3'b001: begin //IDLE state, PSELx = 0, PENABLE = 0
              if( psel_a && !penable_a ) begin
                // apb_state <= 3'b010;

                if( pwrite_a ) begin // WRITE sequence
                  case( paddr_a )
                    CONFIG_ADDRESS: begin
                                      config_r[15:0] <= in_pdata_r[15:0];
                                    end
                    DATA_ADDRESS_WR:  begin
                                        data_to_send_r[31:0] <= in_pdata_r[31:0];
                                      end
                    default:  begin
                              end
                  endcase            
                end
                else begin //READ sequence
                  case( paddr_a )
                    CONFIG_ADDRESS: begin
                                      apb_muxed_out_r[31:0] <= { 16'b0000_0000_0000_0000, apb_config_r[15:0] };
                                    end
                    DATA_ADDRESS_R: begin
                                      apb_muxed_out_r[31:0] <= apb_buffered_data_r[31:0];
                                    end
                    STATUS_ADDRESS: begin
                                      apb_muxed_out_r[31:0] <= { 16'b0000_0000_0000_0000, apb_status_r[15:0] };
                                    end
                    default:  begin
                                apb_muxed_out_r[31:0] <= 32'h0000_0000;
                              end
                  endcase
                end
              end

    //           end else apb_state <= 3'b001;
    //         end
    // 3'b010: begin //SETUP state, PSELx = 1, PENABLE = 0
    //           apb_state <= 3'b001;

    //         end
    // 3'b100: begin //ACCESS state, PSELx = 1, PENABLE = 1
    //           apb_state <= 3'b001;
    //         end
    // default: apb_state <= 3'b001;

    // endcase

  end
end


endmodule

