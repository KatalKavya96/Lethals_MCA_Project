`timescale 1ns/1ps
// instr_rom.v - Instruction memory (Harvard design)
// 256 x 32-bit, read-only, combinational read.
// Loaded at time 0 from a hex program file. Every program ends with HALT,
// so the PC never reaches the unloaded words.
// Note: do NOT add a for-loop that pre-fills the array before $readmemh.
// Icarus runs it in order, but Yosys applies $readmemh first and the loop
// afterwards, so the synthesised ROM would contain only the fill value.
module instr_rom #(
    parameter PROGRAM = "programs/p1_copy.hex"
) (
    input  wire [7:0]  addr,
    output wire [31:0] data
);
    reg [31:0] mem [0:255];
    initial
        $readmemh(PROGRAM, mem);

    assign data = mem[addr];
endmodule
