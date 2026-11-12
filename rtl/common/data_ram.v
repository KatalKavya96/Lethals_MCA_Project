`timescale 1ns/1ps
// data_ram.v - Data memory (Harvard design)
// 256 x 32-bit, one write port (synchronous) and one read port (combinational),
// the same structure as the register-file lab with more locations.
// The address decoder decides which addresses may actually be written.
module data_ram (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
    end

    assign rdata = mem[addr];
endmodule
