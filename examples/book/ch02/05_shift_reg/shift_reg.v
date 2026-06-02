// Chapter 2 — Example 5: Parameterised N-bit Shift Register (SIPO)
// Serial-in, parallel-out with synchronous active-low reset.
// Data shifts left on each rising clock edge; si enters at LSB.
module shift_reg #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst_n,   // active-low synchronous reset
    input  wire         si,      // serial input
    output wire [N-1:0] po       // parallel output
);
    reg [N-1:0] data;

    always @(posedge clk) begin
        if (!rst_n)
            data <= {N{1'b0}};
        else
            data <= {data[N-2:0], si};   // shift left, insert at LSB
    end

    assign po = data;
endmodule
