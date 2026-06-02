// Chapter 2 — Example 6: Parameterised Up/Down Counter
// Features: synchronous reset, enable, up/down, synchronous load.
// carry pulses when counting up from all-1s.
// borrow pulses when counting down from all-0s.
module counter #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst_n,   // active-low synchronous reset
    input  wire         en,      // count enable
    input  wire         up,      // 1 = count up, 0 = count down
    input  wire         load,    // synchronous load (overrides en)
    input  wire [N-1:0] din,     // load value
    output reg  [N-1:0] q,
    output wire         carry,   // overflow on up-count
    output wire         borrow   // underflow on down-count
);
    always @(posedge clk) begin
        if (!rst_n)
            q <= {N{1'b0}};
        else if (load)
            q <= din;
        else if (en) begin
            if (up)
                q <= q + 1'b1;
            else
                q <= q - 1'b1;
        end
    end

    // Carry: enabled, counting up, and currently at max value
    assign carry  = en & up   & (&q);
    // Borrow: enabled, counting down, and currently at zero
    assign borrow = en & (~up) & (~|q);
endmodule
