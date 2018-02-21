module SlTransiever#(parameter CHANNEL_COUNT = 1)
                    ( // sl ports
                      inout  [CHANNEL_COUNT-1:0] SL0,
                      inout  [CHANNEL_COUNT-1:0] SL1,

                      // apb ports
                      input                       pclk, //синхронизация шины
                      input                       preset_n, //ресет apb
                      input       [15:0]          paddr,
                      input                       psel,
                      input                       penable,
                      input                       pwrite,
                      input       [31:0]          pwdata,
                      output                      pready,
                      output      [31:0]          prdata,

                      input         rst_n,
                      input         clk
                      );
//провода для соединения буферов и ApbCommunicator
wire                 fifo_read_empty;
wire                 fifo_write_full;
wire                 fifo_write_empty;
wire  [33:0]         fifo_read_data;
wire                 fifo_read_inc;
wire  [33:0]         fifo_write_data;
wire                 fifo_write_inc;

wire  [CHANNEL_COUNT*2-1:0] soft_reset_n; // конфигурация софт ресета

ApbCommunicator#(CHANNEL_COUNT) mod (
               .pclk                 (pclk),
               .preset_n             (preset_n),
               .psel                 (psel),
               .pwrite               (pwrite),
               .paddr                (paddr),
               .pwdata               (pwdata),
               .prdata               (prdata),
               .penable              (penable),
               .pready               (pready),
               // .pslverr              (pslverr),
               .fifo_read_empty      (fifo_read_empty),
               .fifo_read_inc        (fifo_read_inc),
               .fifo_read_data       (fifo_read_data),
               .fifo_write_inc       (fifo_write_inc),
               .fifo_write_data      (fifo_write_data),
               .fifo_write_full      (fifo_write_full),
               .fifo_write_empty     (fifo_write_empty),
               .soft_reset_n           (soft_reset_n)
              );

parameter TX_CONFIG_REG_WIDTH  = 10;
parameter RX_CONFIG_REG_WIDTH  = 16;
parameter RX_STATUS_REG_WIDTH  = 8;


wire                   in_fifo_read_empty;
wire                   out_fifo_write_full;

wire       [33:0]      in_fifo_read_data;
wire                   in_fifo_read_inc;

wire       [33:0]      out_fifo_write_data;
wire                   out_fifo_write_inc;
AsyncFifo#(4,34) from_apb_fifo (.wr_data  (fifo_write_data),
                                .wr_full  (fifo_write_full),
                                .wr_empty (fifo_write_empty),
                                .wr_inc   (fifo_write_inc),
                                .wr_clk   (pclk),
                                .rd_data  (in_fifo_read_data),
                                .rd_inc   (in_fifo_read_inc),
                                .rd_clk   (clk),
                                .rd_empty (in_fifo_read_empty),
                                .wr_rst_n (preset_n),
                                .rd_rst_n (rst_n));
AsyncFifo#(4,34) to_apb_fifo (  .wr_data  (out_fifo_write_data),
                                .wr_full  (out_fifo_write_full),
                                .wr_inc   (out_fifo_write_inc),
                                .wr_clk   (clk),
                                .rd_data  (fifo_read_data),
                                .rd_inc   (fifo_read_inc),
                                .rd_clk   (pclk),
                                .rd_empty (fifo_read_empty),
                                .wr_rst_n (rst_n),
                                .rd_rst_n (preset_n));

//параметризуемое количество входов
wire    [CHANNEL_COUNT*TX_CONFIG_REG_WIDTH-1:0]  wr_config_tx;
wire    [CHANNEL_COUNT*TX_CONFIG_REG_WIDTH-1:0]  rd_config_tx;
wire    [32*CHANNEL_COUNT-1:0]  wr_data_tx;
wire    [CHANNEL_COUNT-1:0]     data_we_tx;
wire    [CHANNEL_COUNT-1:0]     config_we_tx;
wire    [CHANNEL_COUNT-1:0]     rd_status_tx;
wire    [CHANNEL_COUNT-1:0]     config_changed_tx;
wire    [CHANNEL_COUNT-1:0]     status_changed_tx;

// rx  communication ports
wire    [CHANNEL_COUNT*RX_CONFIG_REG_WIDTH-1:0]  wr_config_rx;
wire    [CHANNEL_COUNT*RX_STATUS_REG_WIDTH-1:0]  rd_status_rx;
wire    [CHANNEL_COUNT*RX_CONFIG_REG_WIDTH-1:0]  rd_config_rx;
wire    [32*CHANNEL_COUNT-1:0]  rd_data_rx;
wire    [CHANNEL_COUNT-1:0]     config_we_rx;
wire    [CHANNEL_COUNT-1:0]     word_picked_rx;
wire    [CHANNEL_COUNT-1:0]     config_changed_rx;
wire    [CHANNEL_COUNT-1:0]     data_status_changed_rx;

Router#(TX_CONFIG_REG_WIDTH,
          RX_CONFIG_REG_WIDTH,
          RX_STATUS_REG_WIDTH, CHANNEL_COUNT) router (
  .clk                    (clk),
  .rst_n                  (rst_n),
  .fifo_read_empty        (in_fifo_read_empty),
  .fifo_write_full        (out_fifo_write_full),
  .fifo_read_data         (in_fifo_read_data),
  .fifo_read_inc          (in_fifo_read_inc),
  .fifo_write_data        (out_fifo_write_data),
  .fifo_write_inc         (out_fifo_write_inc),
  .wr_data_tx             (wr_data_tx),
  .data_we_tx             ( data_we_tx),
  .wr_config_tx           (wr_config_tx),
  .wr_config_rx           (wr_config_rx),
  .config_we_tx           (config_we_tx),
  .rd_status_tx           (rd_status_tx),
  .rd_config_tx           (rd_config_tx),
  .status_changed_tx      (status_changed_tx),
  .config_we_rx           (config_we_rx),
  .word_picked_rx         (word_picked_rx),
  .rd_status_rx           (rd_status_rx),
  .rd_config_rx           (rd_config_rx),
  .rd_data_rx             (rd_data_rx),
  .data_status_changed_rx (data_status_changed_rx)
  );


  wire  [CHANNEL_COUNT-1:0] SL0_in;//входы созданных приемников
  wire  [CHANNEL_COUNT-1:0] SL1_in;
  wire  [CHANNEL_COUNT-1:0] SL0_out;//выходы созданных передатчиков
  wire  [CHANNEL_COUNT-1:0] SL1_out;
  genvar i;

  reg [2*CHANNEL_COUNT-1:0] combined_reset_n;
  reg [2*CHANNEL_COUNT-1:0] buff_reset_n;

  //сложение софтресета с основным ресетом
  always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) {combined_reset_n, buff_reset_n} <= 0;
    else {combined_reset_n, buff_reset_n} <= {combined_reset_n, soft_reset_n};
  end

  generate
  for (i=0; i<CHANNEL_COUNT; i=i+1) begin
    //создание приемников и передатчиков
    SlTransmitter trans(
       .rst_n            (combined_reset_n[i]),
       .clk              (clk),
       .SL0              (SL0_out [i]),
       .SL1              (SL1_out [i]),
       .data_a           (wr_data_tx [(i+1)*32-1:i*32]),
       .send_imm         (data_we_tx [i]),
       .wr_config_w      (wr_config_tx [(i+1)*TX_CONFIG_REG_WIDTH-1:i*TX_CONFIG_REG_WIDTH]),
       .r_config_w       (rd_config_tx [(i+1)*TX_CONFIG_REG_WIDTH-1:i*TX_CONFIG_REG_WIDTH]),
       .wr_config_enable (config_we_tx [i]),
       .send_in_process  (rd_status_tx [i]),
       .status_changed   (status_changed_tx [i])
      );
      SlReceiver#(RX_STATUS_REG_WIDTH, RX_CONFIG_REG_WIDTH) res (
          .rst_n                      (combined_reset_n[i+1]),
          .clk                        (clk),
          .word_picked                (word_picked_rx [i]),
          .serial_line_zeroes_a       (SL0_in [i]),
          .serial_line_ones_a         (SL1_in [i]),
          .r_config_w                 (rd_config_rx [(i+1)*RX_CONFIG_REG_WIDTH-1:i*RX_CONFIG_REG_WIDTH]),
          .data_w                     (rd_data_rx[(i+1)*32-1:i*32]),
          .wr_config_w                (wr_config_rx [(i+1)*RX_CONFIG_REG_WIDTH-1:i*RX_CONFIG_REG_WIDTH]),
          .status_w                   (rd_status_rx [(i+1)*RX_STATUS_REG_WIDTH-1:i*RX_STATUS_REG_WIDTH]),
          .wr_enable                  (config_we_rx[i]),
          .data_status_changed        (data_status_changed_rx[i])
      );

      // мультиплесор, коммтирующий выходы и входы SL канала
      assign {SL0[i], SL1[i]} = (combined_reset_n[i] && !combined_reset_n[i+1] )? {SL0_out [i], SL1_out [i]}:2'bzz; // если включен передатчик  и не включен приемник
      assign  {SL0_in [i], SL1_in [i]} = (combined_reset_n[i] && combined_reset_n[i+1] )? {SL0_out [i], SL1_out [i]} : // если включены оба то заымкаем приемник и ередатчик между собой
                                      ((!combined_reset_n[i] && combined_reset_n[i+1] )? {SL0[i], SL1[i]}:2'b11); // если аключен только приемник замыкаем входы блока на него.


  end
endgenerate

endmodule // SlTranciever
