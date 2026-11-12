`timescale 1ns/1ps
// harvard_decoder.v - Address decoder on the DATA side of the Harvard design.
// The instruction fetch path never passes through this decoder.
//
// Data address map (8-bit offset):
//   0x00 - 0x6F  data RAM
//   0x70         OUT register (memory-mapped output)
//   0x71 - 0xFF  unmapped: writes ignored, reads return 0
module harvard_decoder (
    input  wire [7:0] addr,
    input  wire       mem_wr,
    output wire       ram_sel,
    output wire       out_sel,
    output wire       ram_we,
    output wire       out_we
);
    assign ram_sel = (addr <  8'h70);
    assign out_sel = (addr == 8'h70);
    assign ram_we  = mem_wr & ram_sel;
    assign out_we  = mem_wr & out_sel;
endmodule
