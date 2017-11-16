
module apb2fifoTb(

    );
    parameter clkPeriod = 10;
    parameter clkTimeDiff = 3;
    parameter paddrWidth = 10;
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
    logic [paddrWidth-1:0]  paddr;
    logic                   psel;
    logic                   penable;
    logic                   pwrite;
    logic [31:0]            pwdata;
    logic [31:0]            prdata;
    logic                   pready;
    logic                   pslverr;
    //variables for FIFO's interfaces
    logic                   fifo_read_emty;
    logic                   fifo_write_full;
    logic       [33:0]      fifo_read_data;
    logic                   fifo_read_inc;
    logic       [33:0]      fifo_write_data;
    logic                   fifo_write_inc;

         Apb2Fifo mod (
          .pclk(pclk),
          .preset_n(preset_n),
          .psel(psel),
          .pwrite(pwrite),
          .paddr(paddr),
          .pwdata(pwdata),
          .prdata(prdata),
          .penable(penable),
          .pready(pready),
          .pslverr(pslverr),
          .fifo_read_empty(fifo_read_empty),
          .fifo_read_inc(fifo_read_inc),
          .fifo_read_data(fifo_read_data),
          .fifo_write_inc(fifo_write_inc),
          .fifo_write_data(fifo_write_data),
          .fifo_write_full(fifo_write_full)
   );

   task writeTransaction;
     input bit [paddrWidth-1:0] wrAddr;
     input bit [31:0] wrData;
     begin
       #2;
       paddr=wrAddr;
       pwrite=1;
       penable=0;
       pwdata=wrData;
       psel=1;
       #clkPeriod;
       penable=1;
       #clkPeriod;
       //while(!pready)begin
       psel=0;
       penable=0;
       pwdata=0;
       paddr=0;
       pwrite=0;
       #(clkPeriod-2);

     end
   endtask;

   task readTransaction;
     input  bit [paddrWidth-1:0] rdAddr;
     begin
       #2;
       paddr=rdAddr;
       pwrite=0;
       penable=0;
       psel=1;
       #clkPeriod;
       penable=1;
       #clkPeriod;
       //while(!pready)begin
       //readedData=prdata;
       psel=0;
       penable=0;
       paddr=0;
       pwrite=0;
       #(clkPeriod-2);

     end
   endtask
   initial begin
      #(clkTimeDiff);
       forever #(clkPeriod/2) clk<=~clk;//������ ����
     end
   initial forever #(clkPeriod/2) pclk<=~pclk;//������ ����



    initial begin
    readedData=1;
    clk=0;
    pclk=1;
    preset_n=1;
    reset_n=1;
    paddr=0;
    psel=0;
    penable=0;
    pwrite=0;
    pwdata=0;
    #25;
    preset_n=0;
    reset_n=0;
    #15;
    preset_n=1;
    reset_n=1;
    #40
   writeTransaction(DATA_ADDR,32'd4453);
   writeTransaction(STATUS_ADDR,32'd0);
    #100;
   writeTransaction(CONFIG_ADDR,32'd1);
   #10;
//     readTransaction(10'd6);
    end


endmodule
