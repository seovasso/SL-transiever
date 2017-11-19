module AsyncFifo  #(parameter ADDR_SIZE = 4,
                    parameter DATA_SIZE = 8)
                    ( output      [DATA_SIZE-1:0] rd_data,
                      output  reg                 wr_full,
                      output  reg                 rd_empty,
                      input       [DATA_SIZE-1:0] wr_data,
                      input                       wr_inc,
                      input                       wr_clk,
                      input                       wr_rst_n,
                      input                       rd_inc,
                      input                       rd_clk,
                      input                       rd_rst_n);



// memory part
localparam  MEM_DEPTH = 1<<ADDR_SIZE;
reg [DATA_SIZE-1:0] mem [0:MEM_DEPTH];

assign rd_data = mem [rd_addr];

always @(posedge wr_clk)
  if (wr_inc && !wr_full) mem[wr_addr]<= wr_data;



// read pointer part
reg  [ADDR_SIZE:0] rd_ptr; //gray_code pointer
reg  [ADDR_SIZE:0] rd_bin_cnt; //binary counter
wire [ADDR_SIZE:0] rd_gray_next, rd_bin_cnt_next;

wire  [ADDR_SIZE-1:0] rd_addr; //

assign rd_bin_cnt_next = rd_bin_cnt + (rd_inc & ~rd_empty);
assign rd_gray_next    = (rd_bin_cnt_next>>1) ^ rd_bin_cnt_next;

always @(posedge rd_clk or negedge rd_rst_n)
  if (!rd_rst_n) {rd_ptr, rd_bin_cnt} <= 0;
  else          {rd_ptr, rd_bin_cnt} <= {rd_gray_next, rd_bin_cnt_next};

assign rd_addr = rd_bin_cnt [ADDR_SIZE-1:0];


// read empty part
wire rd_empty_val;
assign rd_empty_val = rd_gray_next == wr_ptr_sync;

always @(posedge rd_clk or negedge rd_rst_n)
  if (!rd_rst_n) rd_empty <= 1 ;
  else rd_empty <= rd_empty_val;


// write pointer part
  reg  [ADDR_SIZE:0] wr_ptr; //gray_code pointer
  reg  [ADDR_SIZE:0] wr_bin_cnt; //binary counter
  wire [ADDR_SIZE:0] wr_gray_next, wr_bin_cnt_next;

  wire  [ADDR_SIZE-1:0] wr_addr; // memory write addres

  assign wr_bin_cnt_next = wr_bin_cnt + (wr_inc & ~wr_full);
  assign wr_gray_next    = (wr_bin_cnt_next>>1) ^ wr_bin_cnt_next;

  always @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) {wr_ptr, wr_bin_cnt} <= 0;
    else           {wr_ptr, wr_bin_cnt} <= {wr_gray_next, wr_bin_cnt_next};

  assign wr_addr = wr_bin_cnt [ADDR_SIZE-1:0];

  // write full part
  wire wr_full_val;

  assign wr_full_val = wr_gray_next == {~rd_ptr_sync[ADDR_SIZE: ADDR_SIZE-1],
                                         rd_ptr_sync[ADDR_SIZE-2:0]};

  always @(posedge wr_clk or negedge wr_rst_n)
    if (!wr_rst_n) wr_full <= 0;
    else           wr_full <= wr_full_val;

    // double sync parts
    reg [ADDR_SIZE:0] rd_ptr_sync;
    reg [ADDR_SIZE:0] rd2wr_ptr_buff;
    always @(posedge wr_clk, wr_rst_n)
      if (!wr_rst_n) {rd_ptr_sync, rd2wr_ptr_buff} <= 0;
      else             {rd_ptr_sync, rd2wr_ptr_buff}<={rd2wr_ptr_buff, rd_ptr};

    reg [ADDR_SIZE:0] wr_ptr_sync;
    reg [ADDR_SIZE:0] wr2rd_ptr_buff;
    always @(posedge rd_clk, rd_rst_n)
      if (!rd_rst_n) {wr_ptr_sync, wr2rd_ptr_buff} <= 0;
      else             {wr_ptr_sync, wr2rd_ptr_buff}<={wr2rd_ptr_buff, wr_ptr};

endmodule // async_fifo
