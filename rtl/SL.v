module SL_transiever (
  //Common siglans
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  input wire serial_line_zeroes_a,
  input wire serial_line_ones_a
  // output wire sl0,
  // output wire sl1,

  //APB related signals
  // input wire pclk,
  // input wire preset_n,
  // input wire [7:0] paddr,
  // input wire pprot,
  // input wire psel,
  // input wire penable,
  // input wire pwrite,
  // inout wire [31:0]pdata,
  // input wire pstrb,
  // output wire pready,
  // output wire pslverr

    );

parameter STROB_POS = 8;

reg [15:0] sl0_tmp_r; //shift regs to temporary store input sequence
reg [15:0] sl1_tmp_r;
reg [31:0] shift_data_r;
reg [ 5:0]  cycle_cnt_r;
reg [ 5:0]  bit_cnt_r;
reg [ 4:0]  state_r; //RECEIVER MODE: 0 - idle, 1 - receiveing started, 1a - bit detected, 1b - no bit, 1c - stop bit
                    //TRANSMITTER MODE: 0 - idle, 1 - sending a word

reg [31:0] buffered_data_r;
reg [63:0] data_to_send_r;
reg [15:0] config_r; //[0] - parity check, [6:1] - bit cnt(8-32bits), [7] - rxtx mode, [8] - IRQ mode
reg [15:0] status_r; //[0] - word length fail, [1] - word receiveing process going, [2] - noise on input lines
                    //[3] - word received, [4] - parity error, [5] - level error on line,
reg parity_ones;
reg parity_zeroes;

always @(posedge clk)
begin
  if( rst_n == 1'b0 ) begin //| preset_n == 1'b0 )
    sl0_tmp_r[15:0]       <= 16'hAAAA;
    sl1_tmp_r[15:0]       <= 16'hAAAA;
    shift_data_r[31:0]    <= 0;
    cycle_cnt_r[5:0]      <= 0;
    bit_cnt_r[5:0]        <= 0;
    state_r[4:0]          <= 5'b00001;
    buffered_data_r[31:0] <= 0;
    data_to_send_r[63:0]  <= 0;
    config_r[15:0]        <= 16'b0000_0000_0010_0000;
    status_r[15:0]        <= 0;   
    parity_zeroes         <= 0;
    parity_ones           <= 1;   

  end
end


always @(posedge clk) begin 
  if( !config_r[7] )  //RECEIVER ROUTINE
  begin
    sl0_tmp_r[15:0] <= ( sl0_tmp_r << 1 ) | serial_line_zeroes_a ;
    sl1_tmp_r[15:0] <= ( sl1_tmp_r << 1 ) | serial_line_ones_a;
    case (state_r)
      5'b00001: begin //IDLE state, waiting for active transmission sequence on one of input lines
                  if( (sl0_tmp_r[15:12] == 4'b1111 && sl0_tmp_r[3:0] == 4'b0000) || (sl1_tmp_r[15:12] == 4'b1111 && sl1_tmp_r[3:0] == 4'b0000) )
                  begin
                    state_r <= state_r << 1;
                    cycle_cnt_r <= 3;
                    status_r[0] <= 0; //word length ok
                    status_r[1] <= 1; //receiving process on
                    status_r[2] <= 0; //as word correctly received, no noise on inout lines
                    status_r[3] <= 0; //Word received flag off
                    status_r[4] <= 0; //no parity error atm
                    status_r[5] <= 0; //no level errors on line
                  end
                  else if( sl0_tmp_r[2:0] == 3'b101 || sl1_tmp_r[2:0] == 3'b101 )  status_r[2] <= 1; //Noise on line
                    else status_r[2] <= 0;
                end
      5'b00010: begin //RECEIVING state
                  cycle_cnt_r <= cycle_cnt_r + 1;
                  if( cycle_cnt_r == STROB_POS )
                  begin
                    state_r <= state_r << 1;
                    if ( !serial_line_ones_a && !serial_line_zeroes_a ) //Если стоп-бит
                    begin
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

                      if( !parity_zeroes && parity_ones ) status_r[4] <= 0; //parity ok
                      else status_r[4] <= 1; //parity check fail
                    end
                    else 
                    begin
                      bit_cnt_r <= bit_cnt_r + 1;
                      if ( !serial_line_ones_a ) //Если единичка
                        begin
                          shift_data_r <= ( shift_data_r >> 1 ) | 32'h8000_0000; //Store data in high bits of register
                          parity_ones  <= parity_ones ^ 1;
                        end
                        else  //Если нолик
                          begin
                            shift_data_r  <= ( shift_data_r >> 1 ) & 32'h7FFF_FFFF;
                            parity_zeroes <= parity_zeroes ^ 1;
                          end
                    end
                  end
                end    
      5'b00100: begin //WAITING for bit transmission end state
                  if( sl0_tmp_r[3:0] == 4'h0 && sl1_tmp_r[3:0] == 4'h0 ) begin //IF we are here after STOP bit detection
                    parity_zeroes <= 0;
                    parity_ones   <= 1;
                    shift_data_r  <= 0;
                    bit_cnt_r     <= 0;
                  end

                  if( sl0_tmp_r[7:0] == 8'hFF && sl1_tmp_r[7:0] == 8'hFF )
                  begin
                    state_r <= 5'b00001; //go to the IDLE state
                    cycle_cnt_r <= 0;
                    status_r[1] <= 1; //Receiving going
                  end
                  else begin
                    cycle_cnt_r <= cycle_cnt_r + 1;
                    if( cycle_cnt_r >= 32 ) status_r[5] <= 1; //level error on line
                  end
                end
      default: state_r <= 5'b00001;
    endcase
  end
  else begin //TRANSMITTER routine
    state_r <= 5'b00001;
  end

end

endmodule

