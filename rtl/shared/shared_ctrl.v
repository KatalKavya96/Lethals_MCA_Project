`timescale 1ns/1ps
// shared_ctrl.v - Controller for the shared-memory (von Neumann-style) baseline.
// 2-state FSM driving the ONE memory port:
//
//   FETCH : port carries PC; the word read is the instruction.
//           NOP / LDI / HALT finish in this same cycle -> stay in FETCH.
//           LOAD / STORE / ADD need the port again   -> latch into IR, go to EXEC.
//   EXEC  : port carries DATA_BASE + offset; do the LOAD / STORE / ADD -> FETCH.
//
// An instruction costs 1 cycle, plus 1 more only if it touches data memory.
// The baseline is never charged for a data access it does not need, so the
// comparison with the Harvard design is fair.
module shared_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  pc,
    input  wire [31:0] m_rdata,          // instruction in FETCH, data in EXEC
    input  wire        fetch_needs_mem,  // from rw_control on the fetched opcode
    output wire [3:0]  fetch_op,         // opcode of the word on the port (FETCH)
    output wire [3:0]  ir_op,            // opcode held in IR (EXEC)
    output reg         state,            // 0 = FETCH, 1 = EXEC
    output wire        fetch_active,
    output wire        exec_active,
    output wire        pc_en,
    output wire [7:0]  m_addr,
    output wire [31:0] m_wdata,
    output reg  [31:0] acc,
    output reg         done
);
    localparam FETCH = 1'b0, EXEC = 1'b1;
    localparam [7:0] DATA_BASE = 8'h80;
    localparam OP_LOAD = 4'h1, OP_LDI = 4'h3, OP_ADD = 4'h4, OP_HALT = 4'hF;

    reg [31:0] ir;                       // instruction register

    wire running = ~rst & ~done;
    assign fetch_active = running & (state == FETCH);
    assign exec_active  = running & (state == EXEC);

    assign fetch_op = m_rdata[31:28];
    assign ir_op    = ir[31:28];

    // ONE port: it carries either the instruction address or the data address
    assign m_addr  = (state == FETCH) ? pc : (DATA_BASE + ir[7:0]);
    assign m_wdata = acc;

    // PC moves on at the end of every FETCH, except on HALT
    assign pc_en = fetch_active & (fetch_op != OP_HALT);

    always @(posedge clk) begin
        if (rst) begin
            state <= FETCH;
            ir    <= 32'd0;
            acc   <= 32'd0;
            done  <= 1'b0;
        end else if (fetch_active) begin
            ir <= m_rdata;
            if (fetch_needs_mem) begin
                state <= EXEC;                         // second cycle needed
            end else begin
                case (fetch_op)                        // completes now
                    OP_LDI:  acc  <= {12'd0, m_rdata[27:8]};
                    OP_HALT: done <= 1'b1;
                    default: ;                         // NOP
                endcase
            end
        end else if (exec_active) begin
            case (ir_op)
                OP_LOAD: acc <= m_rdata;
                OP_ADD:  acc <= acc + m_rdata;
                default: ;                             // STORE: written by the memory
            endcase
            state <= FETCH;
        end
    end
endmodule
