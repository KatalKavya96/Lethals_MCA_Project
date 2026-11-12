// tb_units.v - Unit tests for the small control modules:
// pc, rw_control, harvard_decoder, shared_decoder.
// Each check compares an output with the value expected from the address map / opcode table.
`timescale 1ns/1ps
module tb_units;
    integer errors = 0;

    task expect1;
        input [255:0] name;
        input got;
        input exp;
        begin
            if (got !== exp) begin
                $display("  FAIL  %0s = %b (expected %b)", name, got, exp);
                errors = errors + 1;
            end else
                $display("  PASS  %0s = %b", name, got);
        end
    endtask

    // ---------- rw_control ----------
    reg  [3:0] op;
    reg        active;
    wire       rd, wr;
    rw_control u_rw (.op(op), .active(active), .mem_rd(rd), .mem_wr(wr));

    // ---------- harvard_decoder ----------
    reg  [7:0] haddr;
    reg        hwr;
    wire       h_ram_sel, h_out_sel, h_ram_we, h_out_we;
    harvard_decoder u_hd (.addr(haddr), .mem_wr(hwr), .ram_sel(h_ram_sel), .out_sel(h_out_sel),
                          .ram_we(h_ram_we), .out_we(h_out_we));

    // ---------- shared_decoder ----------
    reg  [7:0] saddr;
    reg        swr;
    wire       s_instr_sel, s_ram_sel, s_out_sel, s_ram_we, s_out_we;
    shared_decoder u_sd (.addr(saddr), .mem_wr(swr), .instr_sel(s_instr_sel), .ram_sel(s_ram_sel),
                         .out_sel(s_out_sel), .ram_we(s_ram_we), .out_we(s_out_we));

    // ---------- pc ----------
    reg        clk = 1'b0, rst = 1'b1, en = 1'b0;
    wire [7:0] pcv;
    pc u_pc (.clk(clk), .rst(rst), .en(en), .pc(pcv));
    always #5 clk = ~clk;

    initial begin
        $display("=== rw_control ===");
        active = 1;
        op = 4'h0; #1 expect1("NOP   rd", rd, 0); expect1("NOP   wr", wr, 0);
        op = 4'h1; #1 expect1("LOAD  rd", rd, 1); expect1("LOAD  wr", wr, 0);
        op = 4'h2; #1 expect1("STORE rd", rd, 0); expect1("STORE wr", wr, 1);
        op = 4'h3; #1 expect1("LDI   rd", rd, 0); expect1("LDI   wr", wr, 0);
        op = 4'h4; #1 expect1("ADD   rd", rd, 1); expect1("ADD   wr", wr, 0);
        op = 4'hF; #1 expect1("HALT  rd", rd, 0); expect1("HALT  wr", wr, 0);
        active = 0; op = 4'h2; #1 expect1("STORE while inactive wr", wr, 0);

        $display("=== harvard_decoder ===");
        hwr = 1;
        haddr = 8'h00; #1 expect1("0x00 ram_we", h_ram_we, 1); expect1("0x00 out_we", h_out_we, 0);
        haddr = 8'h6F; #1 expect1("0x6F ram_we", h_ram_we, 1); expect1("0x6F out_we", h_out_we, 0);
        haddr = 8'h70; #1 expect1("0x70 ram_we", h_ram_we, 0); expect1("0x70 out_we", h_out_we, 1);
        haddr = 8'h71; #1 expect1("0x71 ram_we", h_ram_we, 0); expect1("0x71 out_we", h_out_we, 0);
        haddr = 8'h90; #1 expect1("0x90 ram_we", h_ram_we, 0); expect1("0x90 out_we", h_out_we, 0);
        hwr = 0; haddr = 8'h10; #1 expect1("read 0x10 ram_we", h_ram_we, 0); expect1("read 0x10 ram_sel", h_ram_sel, 1);

        $display("=== shared_decoder ===");
        swr = 1;
        saddr = 8'h10; #1 expect1("0x10 instr_sel", s_instr_sel, 1); expect1("0x10 ram_we (blocked)", s_ram_we, 0);
        saddr = 8'h7F; #1 expect1("0x7F ram_we (blocked)", s_ram_we, 0);
        saddr = 8'h80; #1 expect1("0x80 ram_we", s_ram_we, 1);
        saddr = 8'hEF; #1 expect1("0xEF ram_we", s_ram_we, 1);
        saddr = 8'hF0; #1 expect1("0xF0 out_we", s_out_we, 1); expect1("0xF0 ram_we", s_ram_we, 0);
        saddr = 8'hF1; #1 expect1("0xF1 ram_we", s_ram_we, 0); expect1("0xF1 out_we", s_out_we, 0);

        $display("=== pc ===");
        @(posedge clk); #1 expect1("reset -> 0", (pcv == 8'd0), 1);
        rst = 0; en = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); #1 expect1("3 enabled edges -> 3", (pcv == 8'd3), 1);
        en = 0;
        @(posedge clk); @(posedge clk); #1 expect1("disabled -> holds 3", (pcv == 8'd3), 1);

        $display("");
        if (errors == 0) $display("UNIT RESULT: ALL TESTS PASSED");
        else             $display("UNIT RESULT: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
