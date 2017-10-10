`timescale 1ns / 100ps

module sl_rt_tb;

reg reset;       // Common asycnhronous reset
reg clk;
// reg clk;         // Crystal input
//reg sl00;
//reg sl10;
// reg p0;
// reg p1;
parameter tck = 10; // clock tick
reg sl0;
reg sl1;


SL_transiever dut(reset, clk, sl0, sl1);

//Error injection parameters
reg ei_data_sl0;
reg ei_data_sl1;
reg ei_quantity;
reg ei_parity;
reg ei_fh;  //freq high
reg ei_fl;  //freq low
reg ei_noise_sl0;
reg ei_noise_sl1;


parameter pause_between_words = 0;
parameter value_of_pause = 160; //in clock cycles
parameter word_legth_min = 8;
parameter word_length_max = 32;
parameter word_length_incr = 1;

reg parity0;
reg parity1;

reg fl_ei_data_sl0; //
reg fl_ei_data_sl1;//
reg fl_ei_quantity;
reg fl_ei_fh;  //freq high
reg fl_ei_fl;  //freq low
reg fl_ei_noise_sl0;//
reg fl_ei_noise_sl1;//



//Other parameters
parameter reset_after_each_word = 0;
parameter start_word = 0;
parameter finish_word = 32'hFFFF_FFFF;
parameter increment_word = 8'h1E;


integer var = 0;
integer i = 0;
integer word = 0;
integer ini_word = 0;

always #(tck/2) clk <= ~clk; // clocking device

initial begin
  $dumpfile("sl_rt.vcd");
  $dumpvars(0, dut);
  $monitor($stime,, reset,, clk,,, sl0, sl1); 
end

// testbench actions
initial 
begin
  clk   = 0; 
  reset = 0;
  sl0   = 0;
  sl1   = 0;
  #(tck*10);
  reset = 1;
  #(tck*2);

  repeat ( 32 ) begin








  begin
    ini_word = $urandom_range(0,16'hFFFF);
    word = ini_word;
    ei_data_sl0   = $urandom_range(0,1);
    ei_data_sl1   = $urandom_range(0,1);
    ei_quantity   = $urandom_range(0,1);
    ei_parity     = $urandom_range(0,1);
    ei_fh         = $urandom_range(0,1);  //freq high
    ei_fl         = $urandom_range(0,1);  //freq low
    ei_noise_sl0  = $urandom_range(0,1);
    ei_noise_sl1  = $urandom_range(0,1);

    fl_ei_data_sl0 = 0; //
    fl_ei_data_sl1 = 0;//
    fl_ei_quantity = 0;
    fl_ei_fh = 0;  //freq high
    fl_ei_fl = 0;  //freq low
    fl_ei_noise_sl0 = 0;//
    fl_ei_noise_sl1 = 0;//
    sl0 = 1;
    sl1 = 1;
    parity0  = 0;
    parity1  = 0;
    #(tck*16);

      for( i = word_legth_min; i <= word_length_max; i = i + word_length_incr ) begin
        for( var = 0; var < i; var = var + 1) begin
          if( word & 1 ) begin

            sl1 = 0;
            parity1 = parity1 ^ 1;
            #(tck*16);
            sl1 = 1;
            #(tck*8);

            if( !fl_ei_data_sl1 && ei_data_sl1 ) begin
              sl1 = 0;
              #(tck*4);
              sl1 = 1;
              #(tck*4);
              fl_ei_data_sl0 = 1;
            end else if( !fl_ei_noise_sl1 && ei_noise_sl1 ) begin
              sl1 = 0;
              #(tck*1);
              sl1 = 1;
              #(tck*7);
              fl_ei_noise_sl1 = 1;
            end
            else #(tck*8);

          end
          else begin
            sl0 = 0;
            parity0 = parity0 ^ 1;
            #(tck*16);
            sl0 = 1;
            #(tck*4);

            if( !fl_ei_data_sl0 && ei_data_sl0 ) begin
              sl0 = 0;
              #(tck*4);
              sl0 = 1;
              #(tck*4);
              fl_ei_data_sl0 = 1;
            end
            else if( !fl_ei_noise_sl0 && ei_noise_sl0 ) begin
              sl0 = 0;
              #(tck*1);
              sl0 = 1;
              #(tck*7);
              fl_ei_noise_sl0 = 1;
            end
            else #(tck*8);

          end
          word = word >> 1;
        end

        // add parity bit
        if( parity1 && ei_parity ) begin
          sl0 = 0;
          #(tck*16);
          sl0 = 1;
          #(tck*16);
        end
        else begin
          sl1 = 0;
          #(tck*16);
          sl1 = 1;
          #(tck*16);
        end

        // add stop bit
        sl1 = 0;
        sl0 = 0;
        #(tck*16);
        sl0 = 1;
        sl1 = 1;
        #(tck*16);

        //add delay after word
        #(tck*160);


    end
  end

end



end

endmodule