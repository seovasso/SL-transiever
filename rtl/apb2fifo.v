

module Apb2Fifo(
//Apb ports
input                       pclk, //синхронизация шины
input                       preset_n, //ресет apb
input       [15:0]          paddr,
input                       psel,
input                       penable,
input                       pwrite,
input       [31:0]          pwdata,
output  reg                 pready,
output  reg [31:0]          prdata,
output  reg                 pslverr,
//Fifo ports
input                       fifo_read_empty,
input                       fifo_write_full,
input        [33:0]         fifo_read_data,
output  reg                 fifo_read_inc,
output  reg  [33:0]         fifo_write_data,
output  reg                 fifo_write_inc
    );
parameter CONFIG_ADDR    = 16'd1,
          DATA_ADDR      = 16'd2,
          STATUS_ADDR    = 16'd3,
          CHANNEL_ADDR   = 16'd4;

// modifiers
parameter CONFIG_MODIFIER    = 2'd0,
          DATA_MODIFIER      = 2'd1,
          STATUS_MODIFIER    = 2'd2,
          CHANNEL_MODIFIER   = 2'd3;

parameter APB_ADDR_WIDTH     = 16;
parameter CONFIG_REG_WIDTH   = 16;
parameter STATUS_REG_WIDTH   = 16;
parameter CHANNEL_REG_WIDTH  = 2;

//States
parameter IDLE        = 0,
          WRITE       = 1,
          READ        = 2,
          WRITE_END   = 3,
          READ_END    = 4;
reg [ 4:0] state_r;
reg [ 4:0] next_r;

// State machine
always @( posedge pclk, negedge preset_n ) begin
  if( !preset_n ) begin
    state_r       <= 5'b0;
    state_r[IDLE] <= 1'b1;
  end
  else  state_r <= next_r;
end

always @* begin
  next_r = 5'b0;
  case( 1'b1 ) // synopsys parallel_case
  //were (state_r), but here we using reverse case to make sure it compare only one bit in a vector
    state_r[IDLE]:
      if (psel && (paddr == CONFIG_ADDR || paddr == DATA_ADDR
        || paddr == CHANNEL_ADDR  )  && pwrite)                       next_r[    WRITE] = 1'b1 ;
      else if ((psel && (paddr == CONFIG_ADDR || paddr == DATA_ADDR
        || paddr == CHANNEL_ADDR || paddr == STATUS_ADDR)&& !pwrite)) next_r[     READ] = 1'b1 ;
      else                                                            next_r[     IDLE] = 1'b1 ;
    state_r[WRITE]:                                                   next_r[WRITE_END] = 1'b1 ;
    state_r[READ]:                                                    next_r[ READ_END] = 1'b1 ;
    state_r[READ_END]:                                                next_r[     IDLE] = 1'b1 ;
    state_r[WRITE_END]:                                               next_r[     IDLE] = 1'b1 ;
    default:                                                          next_r[     IDLE] = 1'b1 ;
  endcase
end


reg [ 1:0] modifier;
reg [31:0] reg_out;

// registers model
reg [ CONFIG_REG_WIDTH-1:0]  config_r;
reg [ STATUS_REG_WIDTH-1:0]  status_r;
reg                  [31:0]  rec_data_r;
reg [CHANNEL_REG_WIDTH-1:0]  channel_r;

always @* case (paddr)
  CONFIG_ADDR :{modifier,reg_out} = {CONFIG_MODIFIER , 32'd0|config_r  };
  DATA_ADDR   :{modifier,reg_out} = {DATA_MODIFIER   ,       rec_data_r};
  STATUS_ADDR :{modifier,reg_out} = {STATUS_MODIFIER , 32'd0|status_r  };
  CHANNEL_ADDR:{modifier,reg_out} = {CHANNEL_MODIFIER, 32'd0|channel_r };
  default     :{modifier,reg_out} = {STATUS_MODIFIER , 32'd0};
endcase





always @(posedge pclk, negedge preset_n)
  if( !preset_n ) begin
    pready <= 0;
    prdata <= 32'd0;
    fifo_write_data <= 33'b0;
    fifo_write_inc  <= 0;
  end else begin
      case( 1'b1 ) // synopsys parallel_case
        next_r[IDLE     ]: begin
                             pready<= 0;
                             prdata<=32'd0;
                             fifo_write_data <= 33'b0;
                             fifo_write_inc  <= 0;
                           end
        next_r[WRITE    ]: begin //write apb transaction: writing to async fifo
                             pready <= 1;
                             fifo_write_data <= {modifier,pwdata};
                             fifo_write_inc  <= 1;
                           end
        next_r[WRITE_END]: begin
                            fifo_write_data <= 33'b0;
                            fifo_write_inc  <= 0;
                           end
        next_r[READ     ]: begin //read apb transaction: reading from registers
                             pready <= 1;
                             prdata <= reg_out;
                           end
        next_r[READ_END ]: begin

                           end
      endcase
  end


// read from fifo
reg read_from_fifo;
wire read_from_fifo_next;

assign read_from_fifo_next = (!fifo_read_empty && next_r[IDLE])? 1:0;

always @( posedge pclk, negedge preset_n ) begin
  if( !preset_n ) read_from_fifo<=0;
  else  read_from_fifo <= read_from_fifo_next;
end

always @( posedge pclk, negedge preset_n ) begin
  if( !preset_n ) begin
    rec_data_r      <= 0;
    config_r        <= 0;
    status_r        <= 0;
    channel_r       <= 0;
    fifo_read_inc   <= 0;
  end
  else begin
    if (read_from_fifo_next) begin //reading from fifo buffer
      case (fifo_read_data [33:32])
        CONFIG_MODIFIER : config_r  <= fifo_read_data[ CONFIG_REG_WIDTH-1:0];
        DATA_MODIFIER   : rec_data_r<= fifo_read_data[                 31:0];
        STATUS_MODIFIER : status_r  <= fifo_read_data[ STATUS_REG_WIDTH-1:0];
        CHANNEL_MODIFIER: channel_r <= fifo_read_data[CHANNEL_REG_WIDTH-1:0];
      endcase
      fifo_read_inc<=1;
    end else begin
      fifo_read_inc<=0;
    end
  end
end
endmodule
