// Chapter 2 — Example 1: Gates Testbench
`timescale 1ns/1ps
module tb_gates;
    reg  a, b;
    wire y_and, y_or, y_not, y_nand, y_nor, y_xor;

    gates dut (
        .a(a), .b(b),
        .y_and(y_and), .y_or(y_or), .y_not(y_not),
        .y_nand(y_nand), .y_nor(y_nor), .y_xor(y_xor)
    );

    initial begin
        $dumpfile("gates.vcd");
        $dumpvars(0, tb_gates);
        {a, b} = 2'b00; #10;
        {a, b} = 2'b01; #10;
        {a, b} = 2'b10; #10;
        {a, b} = 2'b11; #10;
        $finish;
    end

    initial begin
        $monitor("t=%0t a=%b b=%b | AND=%b OR=%b NOT_a=%b NAND=%b NOR=%b XOR=%b",
                 $time, a, b, y_and, y_or, y_not, y_nand, y_nor, y_xor);
    end
endmodule
