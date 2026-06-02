// Chapter 2 — Example 8: Shift-and-Add Multiplier — Top Level
// Wires together the controller FSM and the datapath.
module multiplier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  a,         // multiplicand
    input  wire [7:0]  b,         // multiplier
    output wire        done,
    output wire [15:0] product
);
    wire load, shift, add;
    wire cnt_done, b_lsb;

    controller ctrl (
        .clk(clk),       .rst_n(rst_n),
        .start(start),   .cnt_done(cnt_done), .b_lsb(b_lsb),
        .load(load),     .shift(shift),       .add(add),
        .done(done)
    );

    datapath dp (
        .clk(clk),       .rst_n(rst_n),
        .load(load),     .shift(shift),       .add(add),
        .a_in(a),        .b_in(b),
        .cnt_done(cnt_done), .b_lsb(b_lsb),
        .product(product)
    );
endmodule
