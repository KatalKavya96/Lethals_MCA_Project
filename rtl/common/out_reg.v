`timescale 1ns/1ps
// out_reg.v - Memory-mapped output register
// A STORE to the OUT address writes here instead of RAM. Its value drives a
// top-level output port, so a program's result is visible outside the chip.
module out_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [31:0] d,
    output reg  [31:0] q
);
    always @(posedge clk) begin
        if (rst)
            q <= 32'd0;
        else if (we)
            q <= d;
    end
endmodule
