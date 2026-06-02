// Chapter 2 — Example 8: Shift-and-Add Multiplier — Datapath
// Holds the multiplicand (a_reg), multiplier (b_reg), accumulator (acc),
// and shift counter (cnt).  The controller drives load/shift/add;
// the datapath reports cnt_done and b_lsb back as status.
module datapath (
    input  wire        clk,
    input  wire        rst_n,
    // Control signals
    input  wire        load,    // synchronously load a_in/b_in, clear acc & cnt
    input  wire        shift,   // shift b_reg right; increment cnt
    input  wire        add,     // add shifted multiplicand to accumulator
    // Data inputs
    input  wire [7:0]  a_in,    // multiplicand
    input  wire [7:0]  b_in,    // multiplier
    // Status outputs
    output wire        cnt_done, // 1 when 8 shifts complete
    output wire        b_lsb,    // current LSB of b_reg (controls add)
    // Result
    output wire [15:0] product
);
    reg [7:0]  a_reg;
    reg [7:0]  b_reg;
    reg [15:0] acc;
    reg [3:0]  cnt;      // counts 0..8

    assign cnt_done = (cnt == 4'd8);
    assign b_lsb    = b_reg[0];
    assign product  = acc;

    always @(posedge clk) begin
        if (!rst_n) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
            acc   <= 16'd0;
            cnt   <= 4'd0;
        end else if (load) begin
            a_reg <= a_in;
            b_reg <= b_in;
            acc   <= 16'd0;
            cnt   <= 4'd0;
        end else begin
            // add must be evaluated before shift updates cnt
            if (add)
                acc <= acc + ({8'b0, a_reg} << (4'd8 - cnt - 1'b1));
            if (shift) begin
                b_reg <= b_reg >> 1;
                cnt   <= cnt + 1'b1;
            end
        end
    end
endmodule
