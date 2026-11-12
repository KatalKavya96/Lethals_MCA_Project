`timescale 1ns/1ps
// shared_top.v - Shared-memory baseline: one memory, one port, used in turn
// for instruction fetches and data accesses.
module shared_top #(
    parameter PROGRAM = "programs/p1_copy.hex"
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] out,
    output wire [31:0] acc
);
    wire [7:0]  pc_val, m_addr;
    wire [31:0] m_wdata, mem_rdata, m_rdata;
    wire [3:0]  fetch_op, ir_op;
    wire        state, fetch_active, exec_active, pc_en;
    wire        f_rd, f_wr, fetch_needs_mem;
    wire        mem_rd, mem_wr;
    wire        instr_sel, ram_sel, out_sel, ram_we, out_we;

    pc u_pc (.clk(clk), .rst(rst), .en(pc_en), .pc(pc_val));

    shared_ctrl u_ctrl (
        .clk(clk), .rst(rst), .pc(pc_val), .m_rdata(m_rdata),
        .fetch_needs_mem(fetch_needs_mem),
        .fetch_op(fetch_op), .ir_op(ir_op), .state(state),
        .fetch_active(fetch_active), .exec_active(exec_active), .pc_en(pc_en),
        .m_addr(m_addr), .m_wdata(m_wdata), .acc(acc), .done(done)
    );

    // Same rw_control module as the Harvard design, used twice:
    // 1) during FETCH, to ask "does this instruction need the port again?"
    rw_control u_rw_fetch (.op(fetch_op), .active(fetch_active), .mem_rd(f_rd), .mem_wr(f_wr));
    assign fetch_needs_mem = f_rd | f_wr;
    // 2) during EXEC, to drive the real read/write strobes
    rw_control u_rw_exec  (.op(ir_op), .active(exec_active), .mem_rd(mem_rd), .mem_wr(mem_wr));

    shared_decoder u_dec (
        .addr(m_addr), .mem_wr(mem_wr),
        .instr_sel(instr_sel), .ram_sel(ram_sel), .out_sel(out_sel),
        .ram_we(ram_we), .out_we(out_we)
    );

    shared_mem #(.PROGRAM(PROGRAM)) u_mem (
        .clk(clk), .we(ram_we), .addr(m_addr), .wdata(m_wdata), .rdata(mem_rdata)
    );

    out_reg u_out (.clk(clk), .rst(rst), .we(out_we), .d(m_wdata), .q(out));

    // FETCH: the raw memory word is the instruction.
    // EXEC : data reads go through the decoder, exactly like the Harvard data side.
    assign m_rdata = (state == 1'b0) ? mem_rdata :
                     ram_sel         ? mem_rdata :
                     out_sel         ? out       : 32'd0;
endmodule
