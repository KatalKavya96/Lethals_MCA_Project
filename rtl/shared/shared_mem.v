`timescale 1ns/1ps
// shared_mem.v - ONE memory, ONE port (von Neumann-style baseline).
// Instructions and data live in the same 256 x 32-bit array.
// The program is loaded into 0x00 - 0x7F; data lives at 0x80 and above.
// Because there is only one address port, an instruction fetch and a data
// access can never happen in the same cycle.
module shared_mem #(
    parameter PROGRAM = "programs/p1_copy.hex"
) (
    input  wire        clk,
    input  wire        we,
    input  wire [7:0]  addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:255];
    initial
        $readmemh(PROGRAM, mem, 0, 127);   // program only; see note in instr_rom.v

    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
    end

    assign rdata = mem[addr];
endmodule
