module SlTranciever ( input SL0_in,
                      input SL1_in,
                      output SL0_out,
                      output SL1_out,

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
wire                 fifo_read_empty;
wire                 fifo_write_full;
wire                 fifo_write_empty;
wire  [33:0]         fifo_read_data;
wire                 fifo_read_inc;
wire  [33:0]         fifo_write_data;
wire                 fifo_write_inc;
Apb2Fifo mod (
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
               .fifo_write_empty     (fifo_write_empty)
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



wire    [31:0]  wr_data_tx;
wire            data_we_tx;
wire    [TX_CONFIG_REG_WIDTH-1:0]  wr_config_tx;
wire            config_we_tx;
wire            rd_status_tx;
wire    [TX_CONFIG_REG_WIDTH-1:0]  rd_config_tx;
wire            config_changed_tx;
wire            status_changed_tx;

// rx  communication ports
wire    [RX_CONFIG_REG_WIDTH-1:0]  wr_config_rx;
wire            config_we_rx;
wire            word_picked_rx;
wire    [RX_STATUS_REG_WIDTH-1:0]  rd_status_rx;
wire    [RX_CONFIG_REG_WIDTH-1:0]  rd_config_rx;
wire    [31:0]  rd_data_rx;
wire            config_changed_rx;
wire            data_status_changed_rx;

Router#(TX_CONFIG_REG_WIDTH,
          RX_CONFIG_REG_WIDTH,
          RX_STATUS_REG_WIDTH,1) test_module (
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
  SL_transmitter trans(
     .rst_n            (rst_n),
     .clk              (clk),
     .SL0              (SL0_out),
     .SL1              (SL1_out),
     .data_a           (wr_data_tx),
     .send_imm         (data_we_tx),
     .wr_config_w      (wr_config_tx),
     .r_config_w       (rd_config_tx),
     .wr_config_enable (config_we_tx),
     .send_in_process  (rd_status_tx ),
     .status_changed   (status_changed_tx )
    );
    SlReceiver#(RX_STATUS_REG_WIDTH, RX_CONFIG_REG_WIDTH) res (
        .word_picked                (word_picked_rx),
        .rst_n                      (rst_n),
        .serial_line_zeroes_a       (SL0_in),
        .serial_line_ones_a         (SL1_in),
        .r_config_w                 (rd_config_rx),
        .data_w                     (rd_data_rx),
        .wr_config_w                (wr_config_rx),
        .status_w                   (rd_status_rx),
        .clk                        (clk),
        .wr_enable                  (config_we_rx),
        .data_status_changed(data_status_changed_rx)
    );


endmodule // SlTranciever
