

module SlChannel
    (
    input                       trans_active,
    input                       rec_active,
    input                       sl_0_trans,
    input                       sl_1_trans,
    output                      sl_0_rec,
    output                      sl_1_rec,
    inout wire                   sl_zeroes_inout,
    inout wire                   sl_ones_inout
    );

assign {sl_zeroes_inout, sl_ones_inout} = (trans_active && !rec_active )? {sl_0_trans, sl_1_trans}:2'bzz;
assign  {sl_0_rec, sl_1_rec} = (trans_active && rec_active )? {sl_0_trans, sl_1_trans} :
                                ((!trans_active && rec_active )? {sl_zeroes_inout, sl_ones_inout}:2'b11);
endmodule: SlChannel
