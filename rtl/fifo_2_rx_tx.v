


module Fifo2TxRx   #(parameter TX_CONFIG_REG_WIDTH = 16,
                    parameter RX_CONFIG_REG_WIDTH = 16,
                    parameter RX_STATUS_REG_WIDTH = 16
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
    output  reg  [31:0]                     wr_data_tx,
    output  reg                             data_we_tx,
    output  reg  [TX_CONFIG_REG_WIDTH-1:0]  wr_config_tx,
    output  reg                             config_we_tx,
    input                                   rd_status_tx,
    input        [TX_CONFIG_REG_WIDTH-1:0]  rd_config_tx,
    input                                   status_changed_tx,

    // rx  communication ports
    output  reg  [RX_CONFIG_REG_WIDTH-1:0]  wr_config_rx,
    output  reg                             config_we_rx,
    output  reg                             word_picked_rx,
    input        [RX_STATUS_REG_WIDTH-1:0]  rd_status_rx,
    input        [RX_CONFIG_REG_WIDTH-1:0]  rd_config_rx,
    input        [31:0]                     rd_data_rx,
    input                                   data_status_changed_rx
    );

reg channel_r;
// parameter RX_OR_TX_BIT=0;

// //transmitter mux outputs and dmux inputs
// reg    [31:0]  curr_wr_data_tx; //dmux
// reg            curr_data_we_tx; //dmux (current write_enable of transmitter data_r)
// reg    [15:0]  curr_wr_config_tx; //dmux (current write_enable of transmitter config_r)
// reg            curr_config_we_tx; //dmux
// reg            curr_rd_status_tx; //mux
// reg    [15:0]  curr_rd_config_tx; //mux
// //change tx markers
// reg            curr_config_changed_tx;
// reg            curr_status_changed_tx;
//
// //reciever mux outputs and dmux inputs
// reg    [15:0]  curr_wr_config_rx; //dmux
// reg            curr_config_we_rx; //dmux (current write_enable of reciever config_r)
// reg            curr_rd_status_rx; //mux
// reg    [15:0]  curr_rd_config_rx; //mux
// reg    [31:0]  curr_rd_data_rx;// dmux
// //change rx markers
// reg            curr_config_changed_rx;
// reg            curr_status_changed_rx;
// reg            curr_data_changed_rx;

//change channel marker
reg            channel_changed_r;

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
          WRITE_CHANNEL   = 4, // write to channel reg state
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
assign transmitter_is_busy = rd_status_tx;
assign reciever_is_busy = rd_status_rx[0];


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
localparam  MODIFIER_LENGTH = HMB-LMB+1;

wire [MODIFIER_LENGTH-1:0] in_modifier;
assign in_modifier = fifo_read_data [HMB:LMB];


always @* begin: in_fsm_next_calculate
  in_next = 6'b0;
  case (1'b1)
    in_state_r[WRITE_WAIT]:
      if (!fifo_read_empty)
        if (in_modifier == CHANNEL_MODIFIER)          in_next[WRITE_CHANNEL  ] = 1'b1;
        else
          if (channel_r) begin: rx_processing
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

    wr_data_tx   <= 32'b0;
    data_we_tx   <= 0;
    channel_r    <= 0;

    wr_config_rx   <= 16'b0;
    config_we_rx   <= 0;


    wr_config_tx <= 0;
    config_we_tx <= 0;

    fifo_read_inc     <= 0;

    channel_changed_r <= 0;
  end else begin
    case (1'b1)
      in_next [WRITE_WAIT     ]: begin
        data_we_tx   <= 0;
        config_we_rx <= 0;
        config_we_tx <= 0;
        fifo_read_inc     <= 0;
        channel_changed_r <= 0;
      end
      in_next [WRITE_CHANNEL]: begin
        channel_r <= fifo_read_data[0];
        channel_changed_r <= 1;
        fifo_read_inc     <= 1;
      end
      in_next [WRITE_RX_CONFIG]: begin
        wr_config_rx  <= fifo_read_data [15:0];
        config_we_rx  <= 1;
        fifo_read_inc <= 1;
      end
      in_next [WRITE_TX_CONFIG]:begin
        wr_config_tx <= fifo_read_data [15:0];
        config_we_tx <= 1;
        fifo_read_inc     <= 1;
      end
      in_next [WRITE_TX_DATA ]: begin
        wr_data_tx <= fifo_read_data [31:0];
        data_we_tx <= 1;
        fifo_read_inc <= 1;
      end
      in_next [WRITE_ERROR   ]: begin
        fifo_read_inc   <= 1;
      end
    endcase
    end
  end

wire config_changed_tx, config_changed_rx;
assign config_changed_tx = in_state_r[WRITE_TX_CONFIG] == 1'b1;
assign config_changed_rx = in_state_r[WRITE_RX_CONFIG] == 1'b1;


always @* begin: out_fsm_next_calculate
  out_next = 7'b0;
  case (1'b1)
    out_state_r [READ_WAIT     ]:
      if (!fifo_write_full)   begin
        if (channel_changed_r)                              out_next[READ_CHANNEL  ] = 1'b1;
        else if (config_changed_tx && !channel_r)           out_next[READ_TX_CONFIG] = 1'b1;
        else if (config_changed_rx &&  channel_r)           out_next[READ_RX_CONFIG] = 1'b1;
        else if (data_status_changed_rx && channel_r)       out_next[READ_RX_DATA  ] = 1'b1;
        else if (status_changed_tx &&  !channel_r)          out_next[READ_TX_STATUS] = 1'b1;
        else                                                out_next[READ_WAIT     ] = 1'b1;
      end else                                              out_next[READ_WAIT     ] = 1'b1;
    out_state_r [READ_CHANNEL  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)
          if (channel_r)                              out_next[READ_RX_DATA  ] = 1'b1;
          else                                        out_next[READ_TX_STATUS] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_DATA  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)                       out_next[READ_RX_STATUS] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_CONFIG  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)                       out_next[READ_WAIT     ] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_RX_STATUS  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)                       out_next[READ_RX_CONFIG] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_TX_CONFIG  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)                       out_next[READ_WAIT     ] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
      out_state_r [READ_TX_STATUS  ]:
      if (!fifo_write_full) begin
        if (!channel_changed_r)                       out_next[READ_TX_CONFIG] = 1'b1;
        else                                          out_next[READ_CHANNEL  ] = 1'b1;
      end else                                        out_next[READ_WAIT     ] = 1'b1;
  endcase
end: out_fsm_next_calculate

always @(posedge clk, negedge rst_n) begin
  if( !rst_n ) begin
    fifo_write_data <= 32'b0;
    fifo_write_inc  <= 0;
    word_picked_rx  <= 0;
  end else begin
    case (1'b1)
      out_next  [READ_WAIT     ]: begin
        fifo_write_inc <= 0;
        word_picked_rx <= 0;
      end
      out_next  [READ_CHANNEL  ]: begin
        fifo_write_data <= {CHANNEL_MODIFIER, 32'b0 | channel_r};
        fifo_write_inc <= 1;
        word_picked_rx <= 0;
      end
      out_next  [READ_RX_DATA  ]: begin
        word_picked_rx <= 1;
        fifo_write_data <= {DATA_MODIFIER,  32'b0 |  rd_data_rx};
        fifo_write_inc <= 1;
      end
      out_next  [READ_RX_CONFIG]:begin
        fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | rd_config_rx};
        fifo_write_inc <= 1;
        word_picked_rx <= 0;
      end
      out_next  [READ_RX_STATUS]:begin
        fifo_write_data <= {STATUS_MODIFIER, 32'b0 | rd_status_rx};
        fifo_write_inc <= 1;
        word_picked_rx <= 0;
      end
      out_next  [READ_TX_STATUS]:begin
        fifo_write_data <= {STATUS_MODIFIER, 32'b0 | rd_status_tx};
        fifo_write_inc <= 1;
      end
      out_next  [READ_TX_CONFIG]:begin
        fifo_write_data <= {CONFIG_MODIFIER, 32'b0 | rd_config_tx};
        fifo_write_inc <= 1;
      end
    endcase
    end
  end
endmodule
