`timescale 1ns/1ps
// rw_control.v - Read/Write control
// Looks at an opcode and says whether it reads or writes data memory.
// 'active' is low during reset, after HALT, or when the controller is not in a
// data-access cycle, and it forces both strobes low so nothing is written by accident.
//
// Opcodes: 0 NOP, 1 LOAD, 2 STORE, 3 LDI, 4 ADD, F HALT
module rw_control (
    input  wire [3:0] op,
    input  wire       active,
    output wire       mem_rd,
    output wire       mem_wr
);
    localparam OP_LOAD  = 4'h1;
    localparam OP_STORE = 4'h2;
    localparam OP_ADD   = 4'h4;

    assign mem_rd = active & ((op == OP_LOAD) | (op == OP_ADD));
    assign mem_wr = active &  (op == OP_STORE);
endmodule
