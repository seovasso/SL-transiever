


module Router  #(parameter TX_CONFIG_REG_WIDTH = 16,
                    parameter RX_CONFIG_REG_WIDTH = 16,
                    parameter RX_STATUS_REG_WIDTH = 16,
                    parameter CHANNEL_COUNT       = 2

                    )
    (
    input                       clk,
    input                       rst_n,
    //fifo communication ports
    input                       fifo_read_empty,
    input                       fifo_write_full,
    input        [33:0]         fifo_read_data,
    output  reg                 fifo_read_inc,
    output  reg  [33:0]         fifo_write_data,
    output  reg                 fifo_write_inc,
    // tx  communication ports
    output  wire  [32*CHANNEL_COUNT-1:0]                   wr_data_tx,
    output  wire  [CHANNEL_COUNT-1:0]                      data_we_tx,
    output  wire  [TX_CONFIG_REG_WIDTH*CHANNEL_COUNT-1:0]  wr_config_tx,
    output  wire  [CHANNEL_COUNT-1:0]                      config_we_tx,
    input         [CHANNEL_COUNT-1:0]                      rd_status_tx,
    input         [TX_CONFIG_REG_WIDTH*CHANNEL_COUNT-1:0]  rd_config_tx,
    input         [CHANNEL_COUNT-1:0]                      status_changed_tx,

    // rx  communication ports
    output  wire  [RX_CONFIG_REG_WIDTH*CHANNEL_COUNT-1:0]  wr_config_rx,
    output  wire  [CHANNEL_COUNT-1:0]                      config_we_rx,
    output  wire  [CHANNEL_COUNT-1:0]                      word_picked_rx,
    input        [RX_STATUS_REG_WIDTH*CHANNEL_COUNT-1:0]  rd_status_rx,
    input        [RX_CONFIG_REG_WIDTH*CHANNEL_COUNT-1:0]  rd_config_rx,
    input        [32*CHANNEL_COUNT-1:0]                   rd_data_rx,
    input        [CHANNEL_COUNT-1:0]                      data_status_changed_rx
    );

localparam  INST_ADDR_REG_SIZE = 6;
reg  [INST_ADDR_REG_SIZE-1:0] inst_addr_r; // регистр адреса устройства
wire [INST_ADDR_REG_SIZE-2:0] channel_w; // номером канала является адрес устройства деленный на два (на 1 канал - один приемник или передатчик)
assign channel_w = inst_addr_r [INST_ADDR_REG_SIZE-1:1];

wire is_rec_w;// первый бит адреса определяет приемник это или передатчик
assign is_rec_w = inst_addr_r [0];
// tx  communication ports
reg  [31:0]                     wr_data_tx_arr              [0:CHANNEL_COUNT-1];
reg                             data_we_tx_arr              [0:CHANNEL_COUNT-1];
reg  [TX_CONFIG_REG_WIDTH-1:0]  wr_config_tx_arr            [0:CHANNEL_COUNT-1];
reg                             config_we_tx_arr            [0:CHANNEL_COUNT-1];
wire                            rd_status_tx_arr            [0:CHANNEL_COUNT-1];
wire [TX_CONFIG_REG_WIDTH-1:0]  rd_config_tx_arr            [0:CHANNEL_COUNT-1];
wire                            status_changed_tx_arr       [0:CHANNEL_COUNT-1];

// rx  communication ports
reg  [RX_CONFIG_REG_WIDTH-1:0]  wr_config_rx_arr            [0:CHANNEL_COUNT-1];
reg                             config_we_rx_arr            [0:CHANNEL_COUNT-1];
reg                             word_picked_rx_arr          [0:CHANNEL_COUNT-1];

wire [RX_STATUS_REG_WIDTH-1:0]  rd_status_rx_arr            [0:CHANNEL_COUNT-1];
wire [RX_CONFIG_REG_WIDTH-1:0]  rd_config_rx_arr            [0:CHANNEL_COUNT-1];
wire [31:0]                     rd_data_rx_arr              [0:CHANNEL_COUNT-1];
wire                            data_status_changed_rx_arr  [0:CHANNEL_COUNT-1];

// далее следует страшный костыль, призванный компенсировать отсутствие в ерилоге возможности делать выходы и входы массивами
genvar i;
generate
  for (i = 0; i < CHANNEL_COUNT; i = i+1)begin
    assign wr_config_tx   [TX_CONFIG_REG_WIDTH*(i+1)-1:i*TX_CONFIG_REG_WIDTH] = wr_config_tx_arr[i];
    assign wr_config_rx   [RX_CONFIG_REG_WIDTH*(i+1)-1:i*RX_CONFIG_REG_WIDTH] = wr_config_rx_arr[i];
    assign wr_data_tx     [32*(i+1)-1:i*32] = wr_data_tx_arr[i];
    assign data_we_tx     [i] = data_we_tx_arr    [i];
    assign config_we_tx   [i] = config_we_tx_arr  [i];
    assign config_we_rx   [i] = config_we_rx_arr  [i];
    assign word_picked_rx [i] = word_picked_rx_arr[i];

    assign rd_status_tx_arr            [i] = rd_status_tx         [i];
    assign rd_config_tx_arr            [i] = rd_config_tx         [TX_CONFIG_REG_WIDTH*(i+1)-1:i*TX_CONFIG_REG_WIDTH];
    assign status_changed_tx_arr       [i] = status_changed_tx    [i];
    assign rd_status_rx_arr            [i] = rd_status_rx         [RX_STATUS_REG_WIDTH*(i+1)-1:i*RX_STATUS_REG_WIDTH];
    assign rd_config_rx_arr            [i] = rd_config_rx         [RX_CONFIG_REG_WIDTH*(i+1)-1:i*RX_CONFIG_REG_WIDTH];
    assign rd_data_rx_arr              [i] = rd_data_rx           [32*(i+1)-1:i*32];
    assign data_status_changed_rx_arr  [i] = data_status_changed_rx  [i];

  end
endgenerate
//change channel marker
reg            addr_changed_r;

//mux and dmux description
// always @*
//     if (channel[CHANNEL_REG_SIZE:1]<TX_COUNT) begin
//         curr_rd_status_tx = rd_status_tx[channel[CHANNEL_REG_SIZE:1]];
//         curr_rd_config_tx = rd_config_tx[channel[CHANNEL_REG_SIZE:1]* 16+15:channel[CHANNEL_REG_SIZE:1]*16];
//         else begin
//         curr_rd_status_tx = rd_status_tx[channel[CHANNEL_REG_SIZE:1]];
//         curr_rd_config_tx = rd_config_tx[channel[CHANNEL_REG_SIZE:1]* 16+15:channel[CHANNEL_REG_SIZE:1]*16];
//         end


//writing to registers state machine
reg [5:0] in_state_r;
reg [5:0] in_next;
parameter WRITE_WAIT      = 0,
          WRITE_TX_CONFIG = 1, // write to transmitter register states
          WRITE_TX_DATA   = 2,
          WRITE_RX_CONFIG = 3, // write to reciever register states
          WRITE_INST_ADDR   = 4, // write to channel reg state
          WRITE_ERROR     = 5;
//reading from registers state machine
reg [6:0] out_state_r;
reg [6:0] out_next;
parameter READ_WAIT      = 0,
          READ_TX_CONFIG = 1, // write to transmitter register states
          READ_TX_STATUS = 2,
          READ_RX_CONFIG = 3, // write to reciever register states
          READ_RX_STATUS = 4,
          READ_RX_DATA   = 5,
          READ_INST_ADDR   = 6; // write to channel reg state
wire transmitter_is_busy; //status busy bit
wire reciever_is_busy; // reciever busy bit
assign transmitter_is_busy = rd_status_tx_arr[channel_w];
assign reciever_is_busy = rd_status_rx_arr[channel_w] [0];


always @( posedge clk, negedge rst_n ) begin
  if( !rst_n ) begin: fsm_initialize
    in_state_r    <= 6'b0;
    out_state_r   <= 7'b0;
    in_state_r [WRITE_WAIT ] <= 1;
    out_state_r[READ_WAIT] <= 1;
  end: fsm_initialize
  else  begin: fsm_processing
    in_state_r  <= in_next;
    out_state_r <= out_next;
  end: fsm_processing
end

parameter CONFIG_MODIFIER    = 2'd0,
          DATA_MODIFIER      = 2'd1,
          STATUS_MODIFIER    = 2'd2,
          INST_ADDR_MODIFIER   = 2'd3;
parameter HMB = 33, // high modifier bit
          LMB = 32; // low modifier bit
localparam  MODIFIER_LENGTH = HMB-LMB+1;

wire [MODIFIER_LENGTH-1:0] in_modifier;
assign in_modifier = fifo_read_data [HMB:LMB];


always @* begin: in_fsm_next_calculate
  in_next = 6'b0;
  case (1'b1)
    in_state_r[WRITE_WAIT]:
      if (!fifo_read_empty)
        if (in_modifier == INST_ADDR_MODIFIER)          in_next[WRITE_INST_ADDR  ] = 1'b1;
        else
          if (is_rec_w) begin: rx_processing
            if (!reciever_is_busy) begin
              if (in_modifier==CONFIG_MODIFIER)       in_next[WRITE_RX_CONFIG] = 1'b1;
              else                                    in_next[WRITE_ERROR    ] = 1'b1;
            end else                                  in_next[WRITE_WAIT     ] = 1'b1;
          end: rx_processing
          else
          begin: tx_processing
            if (!transmitter_is_busy) begin
              if (in_modifier == CONFIG_MODIFIER)     in_next[WRITE_TX_CONFIG] = 1'b1;
              else if (in_modifier == DATA_MODIFIER)  in_next[WRITE_TX_DATA  ] = 1'b1;
              else                                    in_next[WRITE_ERROR    ] = 1'b1;
            end else                                  in_next[WRITE_WAIT     ] = 1'b1;
          end: tx_processing
      else                                            in_next[WRITE_WAIT     ] = 1'b1;
    in_state_r [WRITE_INST_ADDR],
    in_state_r [WRITE_RX_CONFIG],
    in_state_r [WRITE_TX_CONFIG],
    in_state_r [WRITE_TX_DATA],
    in_state_r [WRITE_ERROR]:                         in_next[WRITE_WAIT     ] = 1'b1;
  endcase
end: in_fsm_next_calculate

genvar l;
generate
  for (l = 0; l < CHANNEL_COUNT; l = l +1) begin
    always @(posedge clk, negedge rst_n) begin
      if( !rst_n ) begin

        wr_data_tx_arr [l]    <= 0;
        data_we_tx_arr [l]   <= 0;
        inst_addr_r       <= 0;

        wr_config_rx_arr [l]  <= 0;
        config_we_rx_arr [l]  <= 0;


        wr_config_tx_arr [l] <= 0;
        config_we_tx_arr [l] <= 0;


      end
    end
  end
endgenerate

  always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    inst_addr_r          <= 0;
    fifo_read_inc   <= 0;
    addr_changed_r  <= 0;
  end else  begin
    case (1'b1)
      in_next [WRITE_WAIT     ]: begin
        data_we_tx_arr [channel_w]   <= 0;
        config_we_rx_arr [channel_w] <= 0;
        config_we_tx_arr [channel_w] <= 0;
        fifo_read_inc     <= 0;
        addr_changed_r <= 0;
      end
      in_next [WRITE_INST_ADDR]: begin
        inst_addr_r <= (fifo_read_data[INST_ADDR_REG_SIZE-1:1] <= CHANNEL_COUNT)? fifo_read_data[INST_ADDR_REG_SIZE-1:0]:0 ;
        addr_changed_r <= 1;
        fifo_read_inc     <= 1;
      end
      in_next [WRITE_RX_CONFIG]: begin
        wr_config_rx_arr [channel_w]  <= fifo_read_data [15:0];
        config_we_rx_arr [channel_w]  <= 1;
        fifo_read_inc <= 1;
      end
      in_next [WRITE_TX_CONFIG]:begin
        wr_config_tx_arr [channel_w] <= fifo_read_data [15:0];
        config_we_tx_arr [channel_w] <= 1;
        fifo_read_inc     <= 1;
      end
      in_next [WRITE_TX_DATA ]: begin
        wr_data_tx_arr [channel_w] <= fifo_read_data [31:0];
        data_we_tx_arr [channel_w] <= 1;
        fifo_read_inc <= 1;
      end
      in_next [WRITE_ERROR   ]: begin
        fifo_read_inc   <= 1;
      end
    endcase
    end
  end


reg config_changed_tx, config_changed_rx;
always @(posedge clk, negedge rst_n)
  if( !rst_n ) {config_changed_tx,config_changed_rx} <= 0;
  else begin
    config_changed_tx <= in_state_r[WRITE_TX_CONFIG] == 1'b1;
    config_changed_rx <= in_state_r[WRITE_RX_CONFIG] == 1'b1;
  end

always @* begin: out_fsm_next_calculate
  out_next = 7'b0;
  case (1'b1)
    out_state_r [READ_WAIT     ]:
      if (!fifo_write_full)   begin
        if (addr_changed_r)                                out_next[READ_INST_ADDR  ] = 1'b1;
        else if (config_changed_tx && !is_rec_w)           out_next[READ_TX_CONFIG] = 1'b1;
        else if (config_changed_rx &&  is_rec_w)           out_next[READ_RX_CONFIG] = 1'b1;
        else if (data_status_changed_rx_arr [channel_w] && is_rec_w)       out_next[READ_RX_DATA  ] = 1'b1;
        else if (status_changed_tx_arr [channel_w] &&  !is_rec_w)          out_next[READ_TX_STATUS] = 1'b1;
        else                                                out_next[READ_WAIT     ] = 1'b1;
      end else                                              out_next[READ_WAIT     ] = 1'b1;
    out_state_r [READ_INST_ADDR  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r)
          if (is_rec_w)                              out_next[READ_RX_DATA  ] = 1'b1;
          else                                        out_next[READ_TX_STATUS] = 1'b1;
        else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_DATA  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r)                       out_next[READ_RX_STATUS] = 1'b1;
        else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_CONFIG  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r) begin
          if (!config_changed_rx)                         out_next[READ_WAIT     ] = 1'b1;
          else                                            out_next[READ_RX_CONFIG] = 1'b1;
        end else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_STATUS  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r)                       out_next[READ_RX_CONFIG] = 1'b1;
        else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_TX_CONFIG  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r) begin
          if (!config_changed_tx)                         out_next[READ_WAIT     ] = 1'b1;
          else                                            out_next[READ_TX_CONFIG] = 1'b1;
        end else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_TX_STATUS  ]:
      if (!fifo_write_full) begin
        if (!addr_changed_r)                       out_next[READ_TX_CONFIG] = 1'b1;
        else                                          out_next[READ_INST_ADDR  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
  endcase
end: out_fsm_next_calculate

genvar iter;
generate
  for (iter = 0; iter < CHANNEL_COUNT; iter = iter +1) begin
    always @(posedge clk, negedge rst_n) begin
      if( !rst_n ) begin
        word_picked_rx_arr [iter] <= 0;
      end
    end
  end
endgenerate

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    fifo_write_data <= 32'b0;
    fifo_write_inc  <= 0;
  end else begin
    case (1'b1)
      out_next  [READ_WAIT     ]: begin
        fifo_write_inc <= 0;
        word_picked_rx_arr [channel_w] <= 0;
      end
      out_next  [READ_INST_ADDR  ]: begin
        fifo_write_data <= {INST_ADDR_MODIFIER, 32'b0 | inst_addr_r};
        fifo_write_inc <= 1;
        word_picked_rx_arr [channel_w] <= 0;
      end
      out_next  [READ_RX_DATA  ]: begin
        word_picked_rx_arr [channel_w] <= 1;
        fifo_write_data <= {DATA_MODIFIER,  32'b0 |  rd_data_rx_arr [channel_w]};
        fifo_write_inc <= 1;
      end
      out_next  [READ_RX_CONFIG]:begin
        fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | rd_config_rx_arr [channel_w]};
        fifo_write_inc <= 1;
        word_picked_rx_arr [channel_w] <= 0;
      end
      out_next  [READ_RX_STATUS]:begin
        fifo_write_data <= {STATUS_MODIFIER, 32'b0 | rd_status_rx_arr [channel_w]};
        fifo_write_inc <= 1;
        word_picked_rx_arr [channel_w] <= 0;
      end
      out_next  [READ_TX_STATUS]:begin
        fifo_write_data <= {STATUS_MODIFIER, 32'b0 | rd_status_tx_arr [channel_w]};
        fifo_write_inc <= 1;
      end
      out_next  [READ_TX_CONFIG]:begin
        fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | rd_config_tx_arr [channel_w]};
        fifo_write_inc <= 1;
      end
    endcase
    end
  end
endmodule
