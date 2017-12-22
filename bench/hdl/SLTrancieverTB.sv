
module SlTrancieverTB(

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
    logic   [31:0]            readedData;
    logic                     preset_n;
    logic                     reset_n;
    logic [APB_ADDR_SIZE-1:0] paddr;
    logic                     psel;
    logic                     penable;
    logic                     pwrite;
    logic [31:0]              pwdata;
    logic [31:0]              prdata;
    logic                     pready;
    // logic                     pslverr;
    // vars for SLChannels
    logic SL0_in;
    logic SL1_in;
    logic SL0_out;
    logic SL1_out;
//instances


         SlTranciever test_module (
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
          .rst_n                (reset_n),
          .clk                  (clk),
          .SL0_in               (SL0_in),
          .SL1_in               (SL1_in),
          .SL0_out              (SL0_out),
          .SL1_out              (SL1_out)
   );

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
    SL0_in = 0;
    SL1_in = 0;
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
    #40;
    writeTransaction(DATA_ADDR,32'd112356);
   // writeTransaction(DATA_ADDR,32'd112356);
   // writeTransaction(CHANNEL_ADDR,32'd2);
   // #100;
   // writeTransaction(CONFIG_ADDR,32'd633);
   // #10;
   end

endmodule
