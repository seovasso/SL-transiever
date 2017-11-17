
module apb2fifoTb(

    );
    parameter CLK_PERIOD = 10;
    parameter CLK_TIME_DELAY = 3;
    parameter APB_ADDR_SIZE = 16;
    parameter FIFO_DATA_SIZE = 34;

    parameter CONFIG_ADDR    = 16'd1,
              DATA_ADDR      = 16'd2,
              STATUS_ADDR    = 16'd3,
              CHANNEL_ADDR   = 16'd4;

    logic clk; // system clock
    logic pclk;// apb clock

    //variables for apb interface
    logic   [31:0]          readedData;
    logic                   preset_n;
    logic                   reset_n;
    logic [APB_ADDR_SIZE-1:0]  paddr;
    logic                   psel;
    logic                   penable;
    logic                   pwrite;
    logic [31:0]            pwdata;
    logic [31:0]            prdata;
    logic                   pready;
    logic                   pslverr;
    //variables for FIFO's interfaces
    logic                   fifo_read_empty;
    logic                   fifo_write_full;
    logic       [33:0]      fifo_read_data;
    logic                   fifo_read_inc;
    logic       [33:0]      fifo_write_data;
    logic                   fifo_write_inc;
    //variaples for fifo buffers
    logic [33:0] rd_data, wr_data;
    logic                wr_full,
                         rd_empty,
                         wr_inc,
                         rd_inc;
//instances


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
          .pslverr              (pslverr),
          .fifo_read_empty      (fifo_read_empty),
          .fifo_read_inc        (fifo_read_inc),
          .fifo_read_data       (fifo_read_data),
          .fifo_write_inc       (fifo_write_inc),
          .fifo_write_data      (fifo_write_data),
          .fifo_write_full      (fifo_write_full)
   );
   AsyncFifo#(4,34) from_apb_fifo (      .wr_data  (fifo_write_data),
                                         .wr_full  (fifo_write_full),
                                         .wr_inc   (fifo_write_inc),
                                         .wr_clk   (pclk),
                                         .rd_data  (rd_data),
                                         .rd_inc   (rd_inc),
                                         .rd_clk   (clk),
                                         .rd_empty (rd_empty),
                                         .wr_rst_n (preset_n),
                                         .rd_rst_n (reset_n));
   AsyncFifo#(4,34) to_apb_fifo (        .wr_data  (wr_data),
                                         .wr_full  (wr_full),
                                         .wr_inc   (wr_inc),
                                         .wr_clk   (clk),
                                         .rd_data  (fifo_read_data),
                                         .rd_inc   (fifo_read_inc),
                                         .rd_clk   (pclk),
                                         .rd_empty (fifo_read_empty),
                                         .wr_rst_n (reset_n),
                                         .rd_rst_n (preset_n));
 // Apb Transactions tasks
   task writeTransaction;
     input bit [APB_ADDR_SIZE-1:0] wrAddr;
     input bit [31:0] wrData;
     begin
       #2;
       paddr=wrAddr;
       pwrite=1;
       penable=0;
       pwdata=wrData;
       psel=1;
       #CLK_PERIOD;
       penable=1;
       #CLK_PERIOD;
       //while(!pready)begin
       psel=0;
       penable=0;
       pwdata=0;
       paddr=0;
       pwrite=0;
       #(CLK_PERIOD-2);

     end
   endtask;

   task readTransaction;
     input  bit [APB_ADDR_SIZE-1:0] rdAddr;
     begin
       #2;
       paddr=rdAddr;
       pwrite=0;
       penable=0;
       psel=1;
       #CLK_PERIOD;
       penable=1;
       #CLK_PERIOD;
       //while(!pready)begin
       //readedData=prdata;
       psel=0;
       penable=0;
       paddr=0;
       pwrite=0;
       #(CLK_PERIOD-2);

     end
   endtask
// buffer transactions tasks
task writeToBuffer;
  input logic [FIFO_DATA_SIZE-1:0] dataToSend;
  begin
    #(CLK_TIME_DELAY);
    wr_data = dataToSend;
    if (!wr_full) wr_inc = 1;
    else $display("Write operation aborted: buffer is full");
    #CLK_PERIOD;
    wr_inc = 0;
    wr_data = 0;
    #(CLK_PERIOD-CLK_TIME_DELAY);
  end
endtask
logic [FIFO_DATA_SIZE-1:0] readedFifoData;
task readFromBuffer;
  begin
    if (!rd_empty) begin
      readedFifoData = rd_data;
      rd_inc = 1;
      #CLK_PERIOD;
      rd_inc = 0;
      #CLK_PERIOD;
    end
    else $display("Read operation aborted: buffer is empty");
    rd_inc = 0;
  end
endtask
// tests
   initial begin
      #(CLK_TIME_DELAY);
       forever #(CLK_PERIOD/2) clk<=~clk;//������ ����
     end
   initial forever #(CLK_PERIOD/2) pclk<=~pclk;//������ ����



    initial begin
    rd_inc = 0;
    wr_inc = 0;

    readedData = 1;
    clk = 0;
    pclk = 1;
    preset_n = 1;
    reset_n = 1;
    paddr = 0;
    psel = 0;
    penable = 0;
    pwrite = 0;
    pwdata = 0;
    #25;
    preset_n = 0;
    reset_n = 0;
    #15;
    preset_n = 1;
    reset_n = 1;
    #40
   writeTransaction(DATA_ADDR,32'd4453);
   writeTransaction(CHANNEL_ADDR,32'd0);
    #100;
   writeTransaction(CONFIG_ADDR,32'd1);
   #10;
//     readTransaction(10'd6);
    end


endmodule
