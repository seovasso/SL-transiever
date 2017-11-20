
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
    wire                   fifo_read_empty;
    wire                   fifo_write_full;
    wire       [33:0]      fifo_read_data;
    wire                   fifo_read_inc;
    wire       [33:0]      fifo_write_data;
    wire                   fifo_write_inc;

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
                                         .rd_data  (fifo_read_data),
                                         .rd_inc   (fifo_read_inc),
                                         .rd_clk   (pclk),
                                         .rd_empty (fifo_read_empty),
                                         .wr_rst_n (preset_n),
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
       readedData=prdata;
       psel=0;
       penable=0;
       paddr=0;
       pwrite=0;
       #(CLK_PERIOD-2);

     end
   endtask
// test clocks
   initial begin
      #(CLK_TIME_DELAY);
       forever #(CLK_PERIOD/2) clk<=~clk;
     end
   initial forever #(CLK_PERIOD/2) pclk<=~pclk;

// test Description
logic currTestPassed;
logic allTestsPassed;
    initial begin
    currTestPassed = 1;
    allTestsPassed = 1;
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
   writeTransaction(DATA_ADDR,32'd112356);
   writeTransaction(CHANNEL_ADDR,32'd2);
    #100;
   writeTransaction(CONFIG_ADDR,32'd633);
   #10;
   currTestPassed = 1;
   readTransaction(DATA_ADDR);
   if (readedData!=32'd112356) begin
   currTestPassed = 0;
   allTestsPassed = 0;
   end
   $display ("Test #1: DATA read %s ",(currTestPassed?"passed":"failed"));
   currTestPassed = 1;
   readTransaction(CHANNEL_ADDR);
   if (readedData!=32'd2) begin
   currTestPassed = 0;
   allTestsPassed = 0;
   end
   currTestPassed = 1;
   $display ("Test #2: CHANNEL read %s ",(currTestPassed?"passed":"failed"));
   readTransaction(CONFIG_ADDR);
   if (readedData!=32'd633) begin
   currTestPassed = 0;
   allTestsPassed = 0;
   end
   $display ("Test #2: CONFIG read %s ",(currTestPassed?"passed":"failed"));
   $display ("All Tests:  %s ",(allTestsPassed?"passed":"failed"));
  end
endmodule
