module SlChannelMuxTb(

    );
    logic [2:0] control;
    logic [2:0] trans;
    wire   [1:0] channel_w;
    logic [1:0] rec;
    logic [2:0] channel_r;

    SlChannel test_module (
  .trans_active   (control[0]),
  .rec_active     (control[1]),
  .sl_0_trans     (trans[0]),
  .sl_1_trans     (trans[1]),
  .sl_0_rec       (rec[0]),
  .sl_1_rec       (rec[1]),
  .sl_zeroes_inout(channel_w[0]),
  .sl_ones_inout  (channel_w[1]));

//assign channel_w = channel_r;

  initial begin
  control = 0;
  trans = 0;
  channel_r = 0;
    for (control = 0; control <= 3; control++)
      for (trans = 0; trans <= 3; trans++) begin
        #5;
        if (control == 2'b10) for (channel_r = 0; channel_r < 4; channel_r++) #5;
      end
  $stop;
  end

endmodule: SlChannelMuxTb
