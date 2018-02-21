module SlTransmitter (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  output wire SL0,
  output wire SL1,

  // Data and command from master
  input   wire [31:0] d_in,
  input   wire        addr,
  input   wire        wr_en,
  output  wire [31:0] d_out
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

reg [ 5:0] bitcnt_r;
reg [ 4:0] freq_devide_cnt_r;
reg parity_r;
reg sl0_r;
reg sl1_r;

// регистры конфигурации и статуса
reg [15:0] config_r;
reg [15:0] status_r;

// провод состояния отправки
wire send_in_process;

reg [4:0] freq_devide_cnt_max ;
wire[4:0] freq_devide_cnt_next;
wire[9:0] config_r_next; //Configuration register next value
wire[9:0] data_r_next; //Data register next value
wire      parity_next;
wire[5:0] bitcnt_r_next;
// Configuration register bits

parameter SR   = 0,
          BQL  = 1, // bit quantity low bit
          BQH  = 6, // bit quantity high bit, BQH-BQL should be 5!
          IRQM = 7, // interrupt request mode
          FQL  = 8, // frequency mode low  bit
          FQH  = 10; // frequency mode high bit
// Ыtatus register bits
parameter SIP   = 0,// send in process
          IRQSM = 8,//interrupt request of sent message
          IRQWCC= 9,// interrupt request of wrong configuration changed
          IRQIC = 10,//interrupt request of incorrect configuration
          IRQDWE= 11;// interrupt request of data write error


assign SL0 = sl0_r;
assign SL1 = sl1_r;

assign d_out = (addr? txdata_r:{status_r, config_r}); //выходной мультиплексор выводов регистров


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
    state_r[       IDLE]: if( wr_en && !addr )                                   next_r[ START_SEND] = 1'b1;
                          else                                                   next_r[       IDLE] = 1'b1;
    state_r[ START_SEND]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[ START_SEND] = 1'b1;
      else if( txdata_r[bitcnt_r] )                                              next_r[        ONE] = 1'b1;
      else                                                                       next_r[       ZERO] = 1'b1;
    state_r[        ONE]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[        ONE] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[       ZERO]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[       ZERO] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[     PARITY]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[     PARITY] = 1'b1;
      else                                                                       next_r[ BIT_ENDING] = 1'b1;
    state_r[ BIT_ENDING]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[ BIT_ENDING] = 1'b1;
      else if( txdata_r[bitcnt_r] == 1'b1 && bitcnt_r[5:0] < config_r[BQH:BQL] ) next_r[        ONE] = 1'b1;
      else if( txdata_r[bitcnt_r] == 1'b0 && bitcnt_r[5:0] < config_r[BQH:BQL] ) next_r[       ZERO] = 1'b1;
      else if( bitcnt_r[5:0] == config_r[BQH:BQL])                               next_r[     PARITY] = 1'b1;
      else                                                                       next_r[       STOP] = 1'b1;
    state_r       [STOP]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[       STOP] = 1'b1;
      else                                                                       next_r[WORD_ENDING] = 1'b1;
    state_r[WORD_ENDING]:
      if( freq_devide_cnt_r < freq_devide_cnt_max)                              next_r[WORD_ENDING] = 1'b1;
      else                                                                       next_r[       IDLE] = 1'b1;
    //default:                                                                   next_r[       IDLE] = 1'b1;
  endcase
end

//проверка коорректности конфигурации
assign config_r_next = (wr_en && addr // идет запись в нужный регистр
                        && d_in[BQH:BQL]>=6'd8 && d_in[BQH:BQL]<=6'd32 //длинна сообщения верна
                         && !d_in[BQL] // длинна сообщения четная
                         )? d_in[9:0]: config_r;

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    txdata_r[31:0] <= 0;
    bitcnt_r[ 5:0] <= 0;
    config_r[ 9:0] <= 10'b_010_0_001000_0;
    parity_r       <= 0;
    sl0_r    <= 1;
    sl1_r    <= 1;
  end else begin
      case( 1'b1 ) // synopsys parallel_case
        next_r[        IDLE]: begin
                                if (wr_en && !addr && freq_devide_cnt_r == 5'b0) txdata_r <= d_in; //TODO: разобраться с этой строчкой
                                bitcnt_r <= 0;
                                config_r <= config_r_next;
                              end
        next_r[  START_SEND]: begin
                                if (wr_en && !addr && freq_devide_cnt_r == 5'b0) txdata_r <= d_in;
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

wire end_of_msg;
wire incorrect_config;
wire config_is_different;

assign send_in_process = !next_r[IDLE];
assign end_of_msg = (next_r[WORD_ENDING] && freq_devide_cnt_next == freq_devide_cnt_max);
assign config_is_incorrect = ((d_in[BQH:BQL] >= 6'd8 && d_in[BQH:BQL] <= 6'd32) //длинна сообщения верна
                                && !d_in[BQL] // длинна сообщения четная
                              );
assign config_is_different = (   d_in[BQH:BQL] != config_r[BQH:BQL] //длинна нового слова не совпадает
                              && d_in[FQH:FQL] != config_r[FQH:FQL] //другая частота
                              );

always @ (posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    status_r       <= 0;
  end else begin
    //SIP bit processing
      status_r[SIP] <= send_in_process;
    //IRQ BITS processing
      if (end_of_msg) status_r[IRQSM]  <= 1; // конец отправки
      else if (wr_en && addr && !d_in[IRQSM])   status_r[IRQSM]  <= 0; // сброс прерывания

      if (wr_en && addr && config_is_incorrect) status_r[IRQIC]  <= 1; //попытка записать неверную конфигурацию
      else if (wr_en && addr && !d_in[IRQIC])   status_r[IRQIC]  <= 0; // сброс прерывания

      if (wr_en && addr && config_is_different
                       && !config_is_incorrect) status_r[IRQWCC] <= 1; //изменение конфигцрации во время отправки сообщения
      else if (wr_en && addr && !d_in[IRQWCC])  status_r[IRQWCC] <= 0; // сброс прерывания

      if (wr_en && addr && send_in_process)     status_r[IRQDWE] <= 1; //попытка отправить сообщение во время отправки предыдущего
      else if (wr_en && addr && !d_in[IRQDWE])  status_r[IRQDWE] <= 0; // сброс прерывания

  end
end

// wire status_changed_next;
// assign status_changed_next =
//       ((next_r[START_SEND] == 1'b1 && freq_devide_cnt_next == 5'd0) ||
//        (next_r[IDLE] == 1'b1       && freq_devide_cnt_r==freq_devide_cnt_max))? 1:0;
// always @(posedge clk, negedge rst_n)
// if( !rst_n ) begin
//   status_changed   <= 1'b0;
// end else begin
//   status_changed   <= status_changed_next;
// end



endmodule
