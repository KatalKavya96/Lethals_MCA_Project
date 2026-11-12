`timescale 1ns/1ps
// shared_decoder.v - Address decoder for the single shared memory.
// Data offsets are translated to absolute addresses by adding 0x80, so:
//   0x00 - 0x7F  instruction region (fetch only; data writes blocked)
//   0x80 - 0xEF  data RAM            (offset 0x00 - 0x6F)
//   0xF0         OUT register         (offset 0x70)
//   0xF1 - 0xFF  unmapped
// This gives exactly the same data map as the Harvard design.
module shared_decoder (
    input  wire [7:0] addr,
    input  wire       mem_wr,
    output wire       instr_sel,
    output wire       ram_sel,
    output wire       out_sel,
    output wire       ram_we,
    output wire       out_we
);
    assign instr_sel = (addr <  8'h80);
    assign ram_sel   = (addr >= 8'h80) & (addr < 8'hF0);
    assign out_sel   = (addr == 8'hF0);
    assign ram_we    = mem_wr & ram_sel;   // the program can never overwrite itself
    assign out_we    = mem_wr & out_sel;
endmodule
