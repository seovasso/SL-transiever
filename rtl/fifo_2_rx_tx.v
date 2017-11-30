


module Apb2TxRx   #(parameter TX_COUNT = 1,
                    parameter RX_COUNT = 1)
    (
    input                       clk,
    input                       rst_n,
    //fifo communication ports
    input                       fifo_read_empty,
    input                       fifo_write_full,
    input        [33:0]         fifo_read_data,
    output  reg                 fifo_read_inc,
    output  reg  [33:0]         fifo_write_data,
    output  reg                 fifo_write_inc
    // tx  communication ports
    output    [(32*TX_COUNT-1):0]  wr_data_tx,
    output    [TX_COUNT-1:0]       data_wr_en_tx,
    output    [(16*TX_COUNT-1):0]  wr_config_tx,
    output    [TX_COUNT-1:0]       config_wr_en_tx,
    input     [TX_COUNT-1:0]       rd_status_tx,
    input     [(16*TX_COUNT-1):0]  rd_config_tx,
    input     [TX_COUNT-1:0]       config_changed_tx,
    input     [TX_COUNT-1:0]       status_changed_tx,

    // rx  communication ports
    output    [(16*RX_COUNT-1):0]  wr_config_rx,
    output    [RX_COUNT-1:0]       config_wr_en_rx,
    input     [(16*RX_COUNT-1):0]  rd_status_rx,
    input     [(16*RX_COUNT-1):0]  rd_config_rx,
    output    [(32*RX_COUNT-1):0]  rd_data_rx,
    input     [TX_COUNT-1:0]       config_changed_rx,
    input     [TX_COUNT-1:0]       data_changed_rx,
    input     [TX_COUNT-1:0]       status_changed_rx
    );
localparam  CHANNEL_REG_SIZE = $clog2(TX_COUNT)+1;
reg channel_r [CHANNEL_REG_SIZE:0];
parameter RX_OR_TX_BIT=0

//transmitter mux outputs and dmux inputs
reg    [31:0]  curr_wr_data_tx; //dmux
reg            curr_data_we_tx; //dmux (current write_enable of transmitter data_r)
reg    [15:0]  curr_wr_config_tx; //dmux (current write_enable of transmitter config_r)
reg            curr_config_we_tx; //dmux
reg            curr_rd_status_tx; //mux
reg    [15:0]  curr_rd_config_tx; //mux
//change tx markers
reg            curr_config_changed_tx;
reg            curr_status_changed_tx;

//reciever mux outputs and dmux inputs
reg    [15:0]  curr_wr_config_rx; //dmux
reg            curr_config_we_rx; //dmux (current write_enable of reciever config_r)
reg            curr_rd_status_rx; //mux
reg    [15:0]  curr_rd_config_rx; //mux
reg    [31:0]  curr_rd_data_rx;// dmux
//change rx markers
reg            curr_config_changed_rx;
reg            curr_status_changed_rx;
reg            curr_data_changed_rx;

//change channel marker
reg            channel_changed_r;

//mux and dmux description
always @*
    if (channel[CHANNEL_REG_SIZE:1]<TX_COUNT) begin
        curr_rd_status_tx = rd_status_tx[channel[CHANNEL_REG_SIZE:1]];
        curr_rd_config_tx = rd_config_tx[channel[CHANNEL_REG_SIZE:1]* 16+15:channel[CHANNEL_REG_SIZE:1]*16];
        else begin
        curr_rd_status_tx = rd_status_tx[channel[CHANNEL_REG_SIZE:1]];
        curr_rd_config_tx = rd_config_tx[channel[CHANNEL_REG_SIZE:1]* 16+15:channel[CHANNEL_REG_SIZE:1]*16];
        end


//writing to registers state machine
reg [5:0] in_state_r;
reg [5:0] in_next;
parameter WRITE_WAIT      = 0,
          WRITE_TX_CONFIG = 1, // write to transmitter register states
          WRITE_TX_DATA   = 2,
          WRITE_RX_CONFIG = 3, // write to reciever register states
          WRITE_CHANNEL   = 4; // write to channel reg state
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
          READ_CHANNEL   = 6; // write to channel reg state
wire transmitter_is_busy; //status busy bit
wire reciever_is_busy; // reciever busy bit

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
          CHANNEL_MODIFIER   = 2'd3;
parameter HMB = 33, // high modifier bit
          LMB = 32; // low modifier bit
localparam  MODIFIER_LENGTH = HLM-LMB+1;

wire [MODIFIER_LENGTH-1:0] in_modifier;
assign in_modifier = fifo_read_data [HMB:LMB]


always @* begin: in_fsm_next_calculate
  in_next = 6'b0;
  case (1'b1)
    in_state_r[WRITE_WAIT]:
      if (!fifo_read_empty)
        if (in_modifier == CHANNEL_MODIFIER)          in_next[WRITE_CHANNEL  ] = 1'b1;
        else
          if (channel_r[RX_OR_TX_BIT]) begin: rx_processing
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
    in_state_r [WRITE_CHANNEL],
    in_state_r [WRITE_RX_CONFIG],
    in_state_r [WRITE_TX_CONFIG],
    in_state_r [WRITE_TX_DATA],
    in_state_r [WRITE_ERROR]:                         in_next[WRITE_WAIT     ] = 1'b1;
  endcase
end: in_fsm_next_calculate

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    curr_wr_data_tx   <= 0;
    curr_data_we_tx   <= 0;
    curr_wr_config_rx <= 0;
    curr_config_we_rx <= 0;
    curr_wr_config_tx <= 0;
    curr_config_we_tx <= 0;
    channel_changed_r <= 0;
  end else begin
  case (1'b1)
    in_next [WRITE_WAIT     ]: begin
      curr_data_we_tx   <= 0;
      curr_config_we_rx <= 0;
      curr_config_we_tx <= 0;
      fifo_read_inc     <= 0;
      channel_changed_r <= 0;
    end
    in_next [WRITE_CHANNEL]: begin
      channel_r <= fifo_read_data[CHANNEL_REG_SIZE:0];
      channel_changed_r <= 1;
    end
    in_next [WRITE_RX_CONFIG]: begin
      // curr_wr_config_rx <= fifo_read_data [15:0];
      curr_config_we_rx <= 1;
      fifo_read_inc     <= 1;
    end
    in_next [WRITE_TX_CONFIG]:begin
      // curr_wr_config_tx <= fifo_read_data [15:0];
      curr_config_we_tx <= 1;
      fifo_read_inc     <= 1;
    end
    in_next [WRITE_TX_DATA ]: begin
      // curr_wr_data_tx <= fifo_read_data [31:0];
      curr_data_we_tx <= 1;
      fifo_read_inc   <= 1;
    end
    in_next [WRITE_ERROR   ]: begin
      fifo_read_inc   <= 1;
    end
  endcase
  end

always @* begin: out_fsm_next_calculate
  out_next = 7'b0;
  case (1'b1)
    out_state_r [READ_WAIT     ]:
      if (!fifo_write_full)
        if (channel_changed_r)                        out_next[READ_CHANNEL  ] = 1'b1;
        else
          if (channel_r[RX_OR_TX_BIT]) begin: rx_processing
              if (data_changed_rx)                    out_next[READ_RX_DATA  ] = 1'b1;
              else if (config_changed_rx)             out_next[READ_RX_CONFIG] = 1'b1;
              else if (status_changed_rx)             out_next[READ_RX_STATUS] = 1'b1;
              else                                    out_next[READ_WAIT     ] = 1'b1;
          end: rx_processing
          else
          begin: tx_processing
              if      (config_changed_rx)             out_next[READ_TX_CONFIG] = 1'b1;
              else if (status_changed_rx)             out_next[READ_TX_STATUS] = 1'b1;
              else                                    out_next[READ_WAIT     ] = 1'b1;
          end: tx_processing
      else                                            out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_CHANNEL  ],
      out_state_r [READ_RX_DATA  ],
      out_state_r [READ_RX_CONFIG],
      out_state_r [READ_RX_STATUS],
      out_state_r [READ_TX_STATUS],
      out_state_r [READ_TX_CONFIG]:                   out_next[READ_WAIT     ] = 1'b1;
  endcase
end: out_fsm_next_calculate

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    fifo_write_data <= 32'b0;
    fifo_write_inc  <= 0;
  end else begin
  case (1'b1)
    out_next  [READ_WAIT     ]: begin
      fifo_write_inc <= 0;
    end
    out_next  [READ_CHANNEL  ]:out_next  [READ_WAIT     ]: begin
      fifo_write_data <= {CHANNEL_MODIFIER, 32'b0 | channel_r};
      fifo_write_inc <= 1;
    end
    out_next  [READ_RX_DATA  ]: begin
      fifo_write_data <= {DATA_MODIFIER,       curr_rd_data_rx};
      fifo_write_inc <= 1;
    end
    out_next  [READ_RX_CONFIG]:begin
      fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | curr_rd_config_rx};
      fifo_write_inc <= 1;
    end;
    out_next  [READ_RX_STATUS]:begin
      fifo_write_data <= {STATUS_MODIFIER, 32'b0 | curr_rd_status_rx};
      fifo_write_inc <= 1;
    end;
    out_next  [READ_TX_STATUS]:begin
      fifo_write_data <= {STATUS_MODIFIER, 32'b0 | curr_rd_status_tx};
      fifo_write_inc <= 1;
    end;;
    out_next  [READ_TX_CONFIG]:begin
      fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | curr_rd_config_tx_rx};
      fifo_write_inc <= 1;
    end;;
    end
  endcase
  end





endmodule