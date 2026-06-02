// Chapter 2 — Example 3: MUX Testbench
`timescale 1ns/1ps
module tb_mux4to1;
    reg  [7:0] d0, d1, d2, d3;
    reg  [1:0] sel;
    wire [7:0] y;

    mux4to1 #(.WIDTH(8)) dut (
        .d0(d0), .d1(d1), .d2(d2), .d3(d3),
        .sel(sel), .y(y)
    );

    task check(input [1:0] s, input [7:0] expected);
        sel = s; #5;
        $display("sel=%0b y=%02h  %s", s, y,
                 (y == expected) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("mux4to1.vcd");
        $dumpvars(0, tb_mux4to1);
        d0 = 8'hAA; d1 = 8'hBB; d2 = 8'hCC; d3 = 8'hDD;
        check(2'b00, 8'hAA);
        check(2'b01, 8'hBB);
        check(2'b10, 8'hCC);
        check(2'b11, 8'hDD);
        $finish;
    end
endmodule
