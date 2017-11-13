`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 27.09.2017 15:02:47
// Design Name:
// Module Name: SlReciever
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module SlTestIdeallReciever(
    input logic           rst_n,
    input logic           sl0,
    input logic           sl1,
    output logic          wordInProces,
    output logic          wordReady,
    output logic [6:0]    bitCount,
    output logic [31:0]   dataOut,
    output logic          parityValid
    );
logic [6:0] counter;//счетчик количества бит в слове
logic parSl0;//контроль четности sl0
logic parSl1;//конроль четности sl1
logic [32:0] data;//сдвиговый регистр
logic paritySumm;
assign paritySumm=parSl1&parSl0;
always_ff @(negedge sl0, negedge sl1, negedge rst_n) begin
    if (!rst_n) begin

        data <= 0;
        counter <= 0;
        wordReady <= 0;
        wordInProces <= 0;
        dataOut <= 0;
        parityValid <= 0;
        parSl0 <= 1'b1;
        parSl1 <= 1'b0;
    end else begin
            case({sl0,sl1})
            2'b01: begin
                    wordInProces <= 1;
                    wordReady <= 0;
                    parityValid<=0;
                    parSl0<=!parSl0;
                    data[32]<=0;
                    for (int i=31; i >= 0; i=i-1)
                    data[i]<=data[i+1];
                    counter <= counter+1;
                 end
            2'b10: begin
                    wordInProces <= 1;
                    wordReady <= 0;
                    parityValid<=0;
                    parSl1<=!parSl1;
                    data[32]<=1;
                    for (int i=31; i >= 0; i=i-1)
                    data[i]<=data[i+1];
                    counter <= counter+1;
                 end
            2'b00: begin
                 bitCount <= counter-1;
                 wordReady <= 1;
                 wordInProces<=0;
                 parityValid <= paritySumm;
                 dataOut<= data[31:0]>>(32-counter+1);
                 parSl0 <= 1'b1;
                 parSl1 <= 1'b0;
                 counter <=0;
                 end
             endcase
        end
    end

endmodule
