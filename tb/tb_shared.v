// tb_shared.v - The SAME directed tests for the shared-memory baseline.
// Data offsets live at absolute address 0x80 + offset in the single memory.
`timescale 1ns/1ps
module tb_shared;
    reg clk = 1'b0;
    reg rst = 1'b1;
    always #5 clk = ~clk;

    wire        d1, d2, d3;
    wire [31:0] o1, o2, o3, a1, a2, a3;

    shared_top #(.PROGRAM("programs/p1_copy.hex"))    s1 (.clk(clk), .rst(rst), .done(d1), .out(o1), .acc(a1));
    shared_top #(.PROGRAM("programs/p2_sum.hex"))     s2 (.clk(clk), .rst(rst), .done(d2), .out(o2), .acc(a2));
    shared_top #(.PROGRAM("programs/p3_compute.hex")) s3 (.clk(clk), .rst(rst), .done(d3), .out(o3), .acc(a3));

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
        $dumpfile("sim/shared.vcd");
        $dumpvars(0, tb_shared);

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;

        wait (d1 && d2 && d3);
        @(negedge clk);

        $display("");
        $display("=== SHARED : P1 block copy ===");
        check("ram[00]", s1.u_mem.mem[8'h80], 32'h0B);
        check("ram[03]", s1.u_mem.mem[8'h83], 32'h2C);
        check("ram[10]", s1.u_mem.mem[8'h90], 32'h0B);
        check("ram[11]", s1.u_mem.mem[8'h91], 32'h16);
        check("ram[12]", s1.u_mem.mem[8'h92], 32'h21);
        check("ram[13]", s1.u_mem.mem[8'h93], 32'h2C);
        check("OUT",     o1, 32'h2C);
        check("cycles",  c1, 18 + 13);

        $display("=== SHARED : P2 array sum ===");
        check("ram[20] sum", s2.u_mem.mem[8'hA0], 32'd50);
        check("acc",     a2, 32'd50);
        check("OUT",     o2, 32'd50);
        check("cycles",  c2, 16 + 11);

        $display("=== SHARED : P3 compute-heavy ===");
        check("ram[30]", s3.u_mem.mem[8'hB0], 32'd3);
        check("OUT",     o3, 32'd3);
        check("acc",     a3, 32'd3);
        // offset 0x90 + 0x80 wraps to absolute 0x10: inside the program region
        check("prog word 0x10 not overwritten", (s3.u_mem.mem[8'h10] === 32'h63) ? 32'd1 : 32'd0, 32'd0);
        check("cycles",  c3, 16 + 4);

        $display("");
        $display("SHARED cycles: P1=%0d P2=%0d P3=%0d", c1, c2, c3);
        if (errors == 0) $display("SHARED RESULT: ALL TESTS PASSED");
        else             $display("SHARED RESULT: %0d TEST(S) FAILED", errors);
        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: timeout, done never asserted");
        $finish;
    end
endmodule
