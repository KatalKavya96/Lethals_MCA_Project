`timescale 1ns/1ps
// harvard_ctrl.v - Controller for the Harvard design. ONE cycle per instruction.
//
// In every cycle, at the same time:
//   - the instruction at PC is fetched from instr_rom (instruction bus), and
//   - if it is LOAD / STORE / ADD, data_ram is accessed (data bus).
// This works only because the two memories are separate.
//
// Instruction word: {opcode[31:28], imm[27:8], addr[7:0]}
//   0 NOP    nothing
//   1 LOAD   acc <- mem[addr]
//   2 STORE  mem[addr] <- acc
//   3 LDI    acc <- imm
//   4 ADD    acc <- acc + mem[addr]
//   F HALT   done <- 1, PC stops
// Any other opcode behaves as NOP.
module harvard_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] instr,     // from instruction memory
    input  wire [31:0] d_rdata,   // from data side (after the decoder's read mux)
    output wire [3:0]  op,
    output wire        active,    // 1 while the program is running
    output wire        pc_en,
    output wire [7:0]  d_addr,
    output wire [31:0] d_wdata,
    output reg  [31:0] acc,
    output reg         done
);
    localparam OP_LOAD = 4'h1, OP_LDI = 4'h3, OP_ADD = 4'h4, OP_HALT = 4'hF;

    // Decode is purely combinational
    assign op      = instr[31:28];
    assign d_addr  = instr[7:0];
    assign d_wdata = acc;
    assign active  = ~rst & ~done;
    assign pc_en   = active & (op != OP_HALT);

    // The only clocked state here: accumulator and done flag
    always @(posedge clk) begin
        if (rst) begin
            acc  <= 32'd0;
            done <= 1'b0;
        end else if (active) begin
            case (op)
                OP_LOAD: acc  <= d_rdata;
                OP_LDI:  acc  <= {12'd0, instr[27:8]};
                OP_ADD:  acc  <= acc + d_rdata;
                OP_HALT: done <= 1'b1;
                default: ;                  // NOP, STORE: nothing to latch here
            endcase
        end
    end
endmodule
