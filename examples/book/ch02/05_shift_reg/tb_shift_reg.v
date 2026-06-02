// Chapter 2 — Example 5: Shift Register Testbench
`timescale 1ns/1ps
module tb_shift_reg;
    parameter N = 8;
    reg         clk, rst_n, si;
    wire [N-1:0] po;

    shift_reg #(.N(N)) dut (.clk(clk), .rst_n(rst_n), .si(si), .po(po));

    always #5 clk = ~clk;

    // Shift in one bit per clock
    task shift_in(input b);
        si = b;
        @(posedge clk); #1;
    endtask

    initial begin
        $dumpfile("shift_reg.vcd");
        $dumpvars(0, tb_shift_reg);
        clk = 0; rst_n = 0; si = 0;
        repeat(2) @(posedge clk); #1;
        rst_n = 1;

        // Shift in 8'b10110101 MSB first
        shift_in(1); shift_in(0); shift_in(1); shift_in(1);
        shift_in(0); shift_in(1); shift_in(0); shift_in(1);

        #1;
        $display("po = %b (expect 10110101)  %s",
                 po, (po == 8'b10110101) ? "PASS" : "FAIL");

        // Test reset
        @(posedge clk); rst_n = 0; @(posedge clk); #1;
        $display("after reset po = %b (expect 00000000)  %s",
                 po, (po == 8'b00000000) ? "PASS" : "FAIL");

        $finish;
    end
endmodule
