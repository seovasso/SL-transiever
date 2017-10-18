module SL_receiver (
  //Common signals
  input wire rst_n,
  input wire clk, //16MHz

  // SL related signals
  inout wire SL0,
  inout wire SL1,


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
  inout wire [31:0] pdata_a,


  input wire [15:0] config_a,
  input wire [15:0] status_a,
  input wire [31:0] rx_data_a,
  output wire [31:0] tx_data_a,
    );

parameter STROB_POS = 8,
          CONFIG_ADDRESS  = 0'b0001,
          DATA_ADDRESS_WR = 0'b0010,
          DATA_ADDRESS_R  = 0'b0100,
          STATUS_ADDRESS  = 0'b1000;




//APB resynchronisation registers
reg [ 7:0] sync1_paddr_r;
reg [31:0] sync1_pdata_r;
reg [ 7:0] sync1_misc_r; //we DO NOT sync 'pclk' and 'preset_n'

reg [ 7:0] in_paddr_r;
reg [31:0] in_pdata_r;
reg [ 7:0] in_misc_r;

//wire {pprot, psel, penable, pwrite, pstrb[3:0]};

//assign {pprot, psel, penable, pwrite, pstrb[3:0]} = in_misc_r[7:0];

parameter PCE  = 0, // parity check enable
          BQL  = 1, // bit quantity low bit
          BQH  = 6, // bit quantity high bit
          MODE = 7, // rx tx mode
          IRQM = 8; //interrupt request mode

parameter WLC = 0, //word length check result
          WRP = 1, //word receiving status
          WRF = 3, //word received flag
          PEF = 4, //parity error flag
          LEF = 5; //level error on line flag

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


assign pdata_a = ( penable_a && psel_a && !pwrite_a ) ? apb_muxed_out_r : 32'bz;


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
    //First stage sync, have to do this cause we need to read data in two cycles,
    //so data must be ready every time and all routines must work related to APB clk
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
