// tb_harvard.v - Directed tests for the Harvard design.
// Runs the three programs on three copies of harvard_top, checks the final
// memory / OUT / accumulator values, and measures the cycle count of each.
//
// Cycle counting rule (identical in tb_shared.v):
//   count every rising clock edge where the design is out of reset and not yet done.
//   HALT itself is counted.
`timescale 1ns/1ps
module tb_harvard;
    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;                 // 100 MHz simulation clock (10 ns period)

    wire        d1, d2, d3;
    wire [31:0] o1, o2, o3, a1, a2, a3;

    harvard_top #(.PROGRAM("programs/p1_copy.hex"))    h1 (.clk(clk), .rst(rst), .done(d1), .out(o1), .acc(a1));
    harvard_top #(.PROGRAM("programs/p2_sum.hex"))     h2 (.clk(clk), .rst(rst), .done(d2), .out(o2), .acc(a2));
    harvard_top #(.PROGRAM("programs/p3_compute.hex")) h3 (.clk(clk), .rst(rst), .done(d3), .out(o3), .acc(a3));

    integer c1 = 0, c2 = 0, c3 = 0;
    always @(posedge clk) begin
        if (!rst && !d1) c1 = c1 + 1;
        if (!rst && !d2) c2 = c2 + 1;
        if (!rst && !d3) c3 = c3 + 1;
    end

    integer errors = 0;
    task check;
        input [255:0] name;
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got === exp)
                $display("  PASS  %0s = %0d (0x%h)", name, got, got);
            else begin
                $display("  FAIL  %0s = %0d (0x%h), expected %0d (0x%h)", name, got, got, exp, exp);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/harvard.vcd");
        $dumpvars(0, tb_harvard);

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;                     // release reset just after an edge

        wait (d1 && d2 && d3);
        @(negedge clk);                    // let the last writes settle

        $display("");
        $display("=== HARVARD : P1 block copy ===");
        check("ram[00]", h1.u_dmem.mem[8'h00], 32'h0B);
        check("ram[03]", h1.u_dmem.mem[8'h03], 32'h2C);
        check("ram[10]", h1.u_dmem.mem[8'h10], 32'h0B);
        check("ram[11]", h1.u_dmem.mem[8'h11], 32'h16);
        check("ram[12]", h1.u_dmem.mem[8'h12], 32'h21);
        check("ram[13]", h1.u_dmem.mem[8'h13], 32'h2C);
        check("OUT",     o1, 32'h2C);
        check("cycles",  c1, 18);

        $display("=== HARVARD : P2 array sum ===");
        check("ram[20] sum", h2.u_dmem.mem[8'h20], 32'd50);
        check("acc",     a2, 32'd50);
        check("OUT",     o2, 32'd50);
        check("cycles",  c2, 16);

        $display("=== HARVARD : P3 compute-heavy ===");
        check("ram[30]", h3.u_dmem.mem[8'h30], 32'd3);
        check("OUT",     o3, 32'd3);
        check("acc",     a3, 32'd3);
        check("unmapped 0x90 not written", (h3.u_dmem.mem[8'h90] === 32'h63) ? 32'd1 : 32'd0, 32'd0);
        check("cycles",  c3, 16);

        $display("");
        $display("HARVARD cycles: P1=%0d P2=%0d P3=%0d", c1, c2, c3);
        if (errors == 0) $display("HARVARD RESULT: ALL TESTS PASSED");
        else             $display("HARVARD RESULT: %0d TEST(S) FAILED", errors);
        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: timeout, done never asserted");
        $finish;
    end
endmodule
