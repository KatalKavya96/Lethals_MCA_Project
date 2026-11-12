`timescale 1ns/1ps
// pc.v - 8-bit Program Counter
// Same pattern as the synchronous counter lab: synchronous active-high reset,
// count up by one when enabled, hold otherwise.
module pc (
    input  wire       clk,
    input  wire       rst,
    input  wire       en,      // 1 = advance to the next instruction
    output reg  [7:0] pc
);
    always @(posedge clk) begin
        if (rst)
            pc <= 8'd0;
        else if (en)
            pc <= pc + 8'd1;
    end
endmodule
