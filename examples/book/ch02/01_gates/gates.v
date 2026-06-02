// Chapter 2 — Example 1: Basic Gates (structural style)
// Instantiates Verilog gate primitives for AND, OR, NOT, NAND, NOR, XOR.
module gates (
    input  wire a, b,
    output wire y_and,
    output wire y_or,
    output wire y_not,
    output wire y_nand,
    output wire y_nor,
    output wire y_xor
);
    and  g_and  (y_and,  a, b);
    or   g_or   (y_or,   a, b);
    not  g_not  (y_not,  a);
    nand g_nand (y_nand, a, b);
    nor  g_nor  (y_nor,  a, b);
    xor  g_xor  (y_xor,  a, b);
endmodule
