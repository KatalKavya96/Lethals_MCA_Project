`timescale 1ns/1ps
// harvard_top.v - Harvard memory organisation.
// Two separate buses:
//   instruction bus: pc -> instr_rom -> controller
//   data bus:        controller -> rw_control -> decoder -> data_ram / out_reg
// Nothing ever multiplexes the two buses together.
module harvard_top #(
    parameter PROGRAM = "programs/p1_copy.hex"
) (
    input  wire        clk,
    input  wire        rst,
    output wire        done,
    output wire [31:0] out,       // memory-mapped OUT register
    output wire [31:0] acc
);
    // instruction bus
    wire [7:0]  i_addr;
    wire [31:0] i_data;

    // data bus
    wire [7:0]  d_addr;
    wire [31:0] d_wdata, d_rdata, ram_rdata;
    wire        mem_rd, mem_wr;
    wire        ram_sel, out_sel, ram_we, out_we;

    wire [3:0]  op;
    wire        active, pc_en;

    pc u_pc (.clk(clk), .rst(rst), .en(pc_en), .pc(i_addr));

    instr_rom #(.PROGRAM(PROGRAM)) u_imem (.addr(i_addr), .data(i_data));

    harvard_ctrl u_ctrl (
        .clk(clk), .rst(rst), .instr(i_data), .d_rdata(d_rdata),
        .op(op), .active(active), .pc_en(pc_en),
        .d_addr(d_addr), .d_wdata(d_wdata), .acc(acc), .done(done)
    );

    rw_control u_rw (.op(op), .active(active), .mem_rd(mem_rd), .mem_wr(mem_wr));

    harvard_decoder u_dec (
        .addr(d_addr), .mem_wr(mem_wr),
        .ram_sel(ram_sel), .out_sel(out_sel), .ram_we(ram_we), .out_we(out_we)
    );

    data_ram u_dmem (.clk(clk), .we(ram_we), .addr(d_addr), .wdata(d_wdata), .rdata(ram_rdata));

    out_reg  u_out  (.clk(clk), .rst(rst), .we(out_we), .d(d_wdata), .q(out));

    // read mux selected by the decoder
    assign d_rdata = ram_sel ? ram_rdata :
                     out_sel ? out       : 32'd0;
endmodule
