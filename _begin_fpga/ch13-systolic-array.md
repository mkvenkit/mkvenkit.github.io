---
title: "Project: Systolic Array Matrix Multiplier"
description: "Build a 4×4 systolic array in Verilog that computes C = A × B for 8-bit integer matrices on the iCE40UP5K — the same dataflow used in Google's TPU."
chapter_num: 13
prev_url: /begin-fpga/ch12-sn76489/
prev_title: "Project: Replicating the SN76489 Sound Generator"
next_url: /begin-fpga/changelog/
next_title: "Changelog"
published: true
---

<style>
.svg-anim {
  display: flex; flex-direction: column; align-items: center;
  gap: 0.75rem; margin: 2rem 0;
}
.svg-anim__btn {
  width: 220px; padding: 0.55rem 0;
  font-size: 0.9rem; font-weight: 600; letter-spacing: 0.03em;
  font-family: ui-monospace, SFMono-Regular, monospace;
  border: none; border-radius: 6px;
  cursor: pointer; transition: background 0.15s, transform 0.1s;
}
.svg-anim__btn[data-running="true"]  { background: #16a34a; color: #fff; }
.svg-anim__btn[data-running="false"] { background: #dc2626; color: #fff; }
.svg-anim__btn:hover { filter: brightness(1.1); transform: translateY(-1px); }
.svg-anim__btn:active { transform: translateY(0); }
.svg-anim__caption {
  font-size: 0.8rem; color: #64748b; font-style: italic; text-align: center;
  max-width: 100%; line-height: 1.45;
}
</style>

<script>
function svgAnimToggle(btn) {
  var svg = btn.closest('.svg-anim').querySelector('svg');
  if (btn.dataset.running === 'true') {
    svg.pauseAnimations();
    btn.textContent = '▶  Play Animation';
    btn.dataset.running = 'false';
  } else {
    svg.unpauseAnimations();
    btn.textContent = '⏸  Pause Animation';
    btn.dataset.running = 'true';
  }
}
</script>

A **systolic array** is a grid of simple processing elements (PEs) where data flows through in a regular rhythm — like a pulse through a heart. Every clock cycle each PE multiplies two inputs, adds the product to a local accumulator, and passes both inputs along to its neighbours. No PE ever waits for a result from a distant memory address; everything it needs arrives one hop away, one clock edge later.

Google's first TPU (2016) is a 256×256 systolic array. This chapter builds a structurally identical 4×4 version on the iCE40UP5K: same dataflow, same diagonal skewing, same output-stationary accumulation — 64× smaller in each dimension, but architecturally the same machine.

All source lives under `examples/systolic_array/` in the companion repository.

**Tools used:**
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`) — simulation
- [GTKWave](http://gtkwave.sourceforge.net/) — waveform viewer
- [Yosys](https://yosyshq.net/yosys/) + [nextpnr](https://github.com/YosysHQ/nextpnr) — synthesis and place-and-route

---

## What is a Systolic Array?

In a conventional matrix multiply, a CPU or GPU fetches values from memory repeatedly for each multiply-accumulate. Three nested loops, N³ iterations, 2×N³ memory reads. For N=256 that is 16.7 million MACs and 33 million DRAM accesses per matrix pair.

A systolic array eliminates that bottleneck by keeping data moving through a grid of PEs — each one feeds its inputs to its neighbours every clock cycle. Memory traffic drops from 2×N³ to 2×N² reads because each value is fetched once and reused N times as it ripples through the grid. Compute time drops from O(N³) cycles to O(N) because all N² PEs work in parallel.

| | Naive (sequential) | Systolic array |
|---|---|---|
| Cycles (N=4) | 64 | 10 |
| Cycles (N=256) | 16,777,216 | 766 |
| Memory reads | 2 × N³ | 2 × N² |
| MACs per cycle (steady state) | 1 | N² |

The trade-off is fixed structure. A systolic array commits to one dataflow pattern at design time and cannot be repurposed. For workloads where matrix multiply dominates — neural network inference being the clearest example — it wins decisively.

---

## Processing Element (`pe.v`)

Each PE does exactly three things every clock edge:

1. Multiply its two inputs: `product = a_in * b_in`
2. Accumulate: `c_out += product`
3. Pass inputs through: `a_out <= a_in`, `b_out <= b_in`

`a` flows horizontally (left to right). `b` flows vertically (top to bottom). `c` never moves — it accumulates in place. After N clock cycles of valid data, `c_out` holds the complete dot product of the A-row and B-column that passed through this PE.

```verilog
module pe #(
    parameter DW = 8,   // data width
    parameter AW = 20   // accumulator width (must be >= 2*DW)
)(
    input  wire          clk,
    input  wire          rst,
    input  wire [DW-1:0] a_in,
    input  wire [DW-1:0] b_in,
    output reg  [DW-1:0] a_out,
    output reg  [DW-1:0] b_out,
    output reg  [AW-1:0] c_out
);

wire [2*DW-1:0] product = a_in * b_in;

always @(posedge clk) begin
    if (rst) begin
        a_out <= 0;
        b_out <= 0;
        c_out <= 0;
    end else begin
        a_out <= a_in;
        b_out <= b_in;
        c_out <= c_out + {{(AW-2*DW){1'b0}}, product};
    end
end

endmodule
```

The accumulator is wider than the inputs: 8-bit inputs can produce a 16-bit product, and summing N of those needs more bits still. `AW = 20` is enough for 4 × 255 × 255 = 260,100, which fits in 18 bits with margin.

The sign extension `{{(AW-2*DW){1'b0}}, product}` zero-pads the 16-bit product up to 20 bits before adding it to `c_out`. The outer `{}` is Verilog's concatenation operator; the inner `{N{bit}}` is replication.

---

## Array Structure (`systolic_array.v`)

A 4×4 grid of PEs is wired so that the right-output of each PE feeds the left-input of the PE one column over, and the bottom-output feeds the top-input of the PE one row below. Boundary inputs are driven by the `a_row` and `b_col` ports.

```verilog
module systolic_array #(
    parameter N  = 4,
    parameter DW = 8,
    parameter AW = 20
)(
    input  wire              clk,
    input  wire              rst,
    input  wire [N*DW-1:0]   a_row,   // a_row[i*DW +: DW] = A value entering row i
    input  wire [N*DW-1:0]   b_col,   // b_col[j*DW +: DW] = B value entering col j
    output wire [N*N*AW-1:0] c_flat   // c_flat[(i*N+j)*AW +: AW] = C[i][j]
);
```

The wiring uses two 2-D arrays of wires — `a_wire[row][col]` for horizontal flow and `b_wire[row][col]` for vertical flow — with one extra column/row at each boundary so the generate loop doesn't need special-casing:

```verilog
wire [DW-1:0] a_wire [0:N-1][0:N];   // a_wire[i][0] = input; a_wire[i][N] = discard
wire [DW-1:0] b_wire [0:N][0:N-1];   // b_wire[0][j] = input; b_wire[N][j] = discard

genvar i, j;
generate
    for (i = 0; i < N; i = i + 1) begin : g_row
        for (j = 0; j < N; j = j + 1) begin : g_col
            pe #(.DW(DW), .AW(AW)) u_pe (
                .clk   (clk), .rst (rst),
                .a_in  (a_wire[i][j]),   .b_in  (b_wire[i][j]),
                .a_out (a_wire[i][j+1]), .b_out (b_wire[i+1][j]),
                .c_out (c_wire[i][j])
            );
        end
    end
endgenerate
```

`generate` / `genvar` is Verilog's way of writing a loop that the synthesiser unrolls into actual hardware at compile time. Each iteration produces one PE instance connected to its neighbours via the wire arrays. The result is 16 independent PE modules wired in a 4×4 mesh — no run-time logic, just wires.

---

## Diagonal Skewing

For PE[i][j] to compute `C[i][j]` correctly it must receive `A[i][k]` and `B[k][j]` on the *same* clock cycle for every k. Without any adjustments, row 0 of A would enter all four PEs in its row simultaneously — but PE[0][1] is one hop to the right, so it sees any value from the left edge one cycle *later* than PE[0][0] does. The fix is **diagonal skewing**: stagger the inputs so that row i of A is delayed by i cycles before entering the array, and column j of B is delayed by j cycles.

The dashed lines in the diagram below show which elements are injected on the same cycle:

![Skewing diagram]({{ site.baseurl }}/begin-fpga/figures/systolic-array-skew.svg)

`A[0][0]` enters at t=0, `A[1][0]` at t=1, `A[2][0]` at t=2, `A[3][0]` at t=3. By the time `A[1][0]` reaches PE[1][1]` (one hop right, one cycle later), it meets `A[0][1]` arriving at PE[0][1]` — and both had the same k=0. Everything lines up automatically because the propagation delay through the PE chain equals the stagger at the input.

The skewing is implemented in `top.v` with combinational logic. At cycle `cnt`, row i gets element `A[i][cnt-i]` if `i <= cnt < i+N`, and zero otherwise:

```verilog
always @(*) begin
    for (ii = 0; ii < N; ii = ii + 1) begin
        if (cnt >= ii && cnt < N + ii)
            a_row[ii*DW +: DW] = A_mem[ii*N + (cnt - ii)];
        else
            a_row[ii*DW +: DW] = 0;
    end
end
```

The same pattern applies to `b_col` with column index `jj`.

---

## Data Flow Animation

The animation below shows one complete 10-cycle computation. Red circles are A values streaming right through each row. Blue circles are B values flowing down each column. A PE flashes green each time it performs a multiply-accumulate. Notice the diagonal wave: PE[0][0] starts accumulating immediately, while PE[3][3] doesn't see its first data until cycle 6 — that stagger is the skewing at work.

<div class="svg-anim">
  <svg viewBox="0 0 490 415" xmlns="http://www.w3.org/2000/svg"
       font-family="ui-monospace,SFMono-Regular,monospace">

  <text x="245" y="13" text-anchor="middle" font-size="10" fill="#64748b">4x4 systolic array · C = A x B · 10 cycles · 833 ns at 12 MHz</text>

  <!-- PE boxes -->
  <rect x="77" y="70" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.3200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="110" y="95" text-anchor="middle" fill="#64748b" font-size="10">C[0][0]<animate attributeName="fill" values="#ffffff;#64748b;#64748b" keyTimes="0.0000;0.3200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="167" y="70" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.0800;0.4000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="200" y="95" text-anchor="middle" fill="#64748b" font-size="10">C[0][1]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.0800;0.4000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="257" y="70" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="290" y="95" text-anchor="middle" fill="#64748b" font-size="10">C[0][2]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="347" y="70" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="380" y="95" text-anchor="middle" fill="#64748b" font-size="10">C[0][3]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="77" y="150" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.0800;0.4000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="110" y="175" text-anchor="middle" fill="#64748b" font-size="10">C[1][0]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.0800;0.4000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="167" y="150" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="200" y="175" text-anchor="middle" fill="#64748b" font-size="10">C[1][1]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="257" y="150" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="290" y="175" text-anchor="middle" fill="#64748b" font-size="10">C[1][2]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="347" y="150" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="380" y="175" text-anchor="middle" fill="#64748b" font-size="10">C[1][3]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="77" y="230" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="110" y="255" text-anchor="middle" fill="#64748b" font-size="10">C[2][0]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.1600;0.4800;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="167" y="230" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="200" y="255" text-anchor="middle" fill="#64748b" font-size="10">C[2][1]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="257" y="230" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="290" y="255" text-anchor="middle" fill="#64748b" font-size="10">C[2][2]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="347" y="230" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.4000;0.7200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="380" y="255" text-anchor="middle" fill="#64748b" font-size="10">C[2][3]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.4000;0.7200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="77" y="310" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="110" y="335" text-anchor="middle" fill="#64748b" font-size="10">C[3][0]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.2400;0.5600;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="167" y="310" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="200" y="335" text-anchor="middle" fill="#64748b" font-size="10">C[3][1]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.3200;0.6400;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="257" y="310" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.4000;0.7200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="290" y="335" text-anchor="middle" fill="#64748b" font-size="10">C[3][2]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.4000;0.7200;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>
  <rect x="347" y="310" width="66" height="40" rx="4" fill="#f8fafc" stroke="#94a3b8" stroke-width="1.2">
    <animate attributeName="fill" values="#f8fafc;#16a34a;#f8fafc;#f8fafc" keyTimes="0.0000;0.4800;0.8000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="380" y="335" text-anchor="middle" fill="#64748b" font-size="10">C[3][3]<animate attributeName="fill" values="#64748b;#ffffff;#64748b;#64748b" keyTimes="0.0000;0.4800;0.8000;1.0000" calcMode="discrete" dur="10.0s" repeatCount="indefinite"/></text>

  <!-- Connectors -->
  <line x1="144" y1="90" x2="166" y2="90" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="234" y1="90" x2="256" y2="90" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="324" y1="90" x2="346" y2="90" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="144" y1="170" x2="166" y2="170" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="234" y1="170" x2="256" y2="170" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="324" y1="170" x2="346" y2="170" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="144" y1="250" x2="166" y2="250" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="234" y1="250" x2="256" y2="250" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="324" y1="250" x2="346" y2="250" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="144" y1="330" x2="166" y2="330" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="234" y1="330" x2="256" y2="330" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="324" y1="330" x2="346" y2="330" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="110" y1="111" x2="110" y2="149" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="200" y1="111" x2="200" y2="149" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="290" y1="111" x2="290" y2="149" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="380" y1="111" x2="380" y2="149" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="110" y1="191" x2="110" y2="229" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="200" y1="191" x2="200" y2="229" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="290" y1="191" x2="290" y2="229" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="380" y1="191" x2="380" y2="229" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="110" y1="271" x2="110" y2="309" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="200" y1="271" x2="200" y2="309" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="290" y1="271" x2="290" y2="309" stroke="#e2e8f0" stroke-width="1.5"/>
  <line x1="380" y1="271" x2="380" y2="309" stroke="#e2e8f0" stroke-width="1.5"/>

  <!-- Input edges -->
  <line x1="22" y1="90" x2="76" y2="90" stroke="#fca5a5" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="14" y="81" text-anchor="middle" font-size="9" fill="#dc2626">A[0]</text>
  <line x1="22" y1="170" x2="76" y2="170" stroke="#fca5a5" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="14" y="161" text-anchor="middle" font-size="9" fill="#dc2626">A[1]</text>
  <line x1="22" y1="250" x2="76" y2="250" stroke="#fca5a5" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="14" y="241" text-anchor="middle" font-size="9" fill="#dc2626">A[2]</text>
  <line x1="22" y1="330" x2="76" y2="330" stroke="#fca5a5" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="14" y="321" text-anchor="middle" font-size="9" fill="#dc2626">A[3]</text>
  <line x1="110" y1="18" x2="110" y2="69" stroke="#93c5fd" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="123" y="26" font-size="9" fill="#2563eb">B[0]</text>
  <line x1="200" y1="18" x2="200" y2="69" stroke="#93c5fd" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="213" y="26" font-size="9" fill="#2563eb">B[1]</text>
  <line x1="290" y1="18" x2="290" y2="69" stroke="#93c5fd" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="303" y="26" font-size="9" fill="#2563eb">B[2]</text>
  <line x1="380" y1="18" x2="380" y2="69" stroke="#93c5fd" stroke-width="1" stroke-dasharray="3,2"/>
  <text x="393" y="26" font-size="9" fill="#2563eb">B[3]</text>

  <!-- A bubbles -->
  <circle r="8" fill="#dc2626" cx="22" cy="90" opacity="0">
    <animate attributeName="cx" values="22;110;200;290;380;460;22;22" keyTimes="0.0000;0.0800;0.1600;0.2400;0.3200;0.4000;0.4010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="1;1;0;0" keyTimes="0.0000;0.3990;0.4000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="90" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.0790;0.0800;0.1600;0.2400;0.3200;0.4000;0.4800;0.4810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.0790;0.0800;0.4790;0.4800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="90" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="90" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="170" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.0790;0.0800;0.1600;0.2400;0.3200;0.4000;0.4800;0.4810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.0790;0.0800;0.4790;0.4800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="170" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="170" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="170" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="250" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="250" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="250" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="250" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.3990;0.4000;0.4800;0.5600;0.6400;0.7200;0.8000;0.8010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3990;0.4000;0.7990;0.8000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="330" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="330" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="330" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.3990;0.4000;0.4800;0.5600;0.6400;0.7200;0.8000;0.8010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3990;0.4000;0.7990;0.8000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#dc2626" cx="22" cy="330" opacity="0">
    <animate attributeName="cx" values="22;22;22;110;200;290;380;460;22;22" keyTimes="0.0000;0.4790;0.4800;0.5600;0.6400;0.7200;0.8000;0.8800;0.8810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.4790;0.4800;0.8790;0.8800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>

  <!-- B bubbles -->
  <circle r="8" fill="#2563eb" cx="110" cy="18" opacity="0">
    <animate attributeName="cy" values="18;90;170;250;330;370;18;18" keyTimes="0.0000;0.0800;0.1600;0.2400;0.3200;0.4000;0.4010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="1;1;0;0" keyTimes="0.0000;0.3990;0.4000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="200" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.0790;0.0800;0.1600;0.2400;0.3200;0.4000;0.4800;0.4810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.0790;0.0800;0.4790;0.4800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="290" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="380" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="110" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.0790;0.0800;0.1600;0.2400;0.3200;0.4000;0.4800;0.4810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.0790;0.0800;0.4790;0.4800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="200" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="290" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="380" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="110" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.1590;0.1600;0.2400;0.3200;0.4000;0.4800;0.5600;0.5610;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="200" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="290" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="380" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.3990;0.4000;0.4800;0.5600;0.6400;0.7200;0.8000;0.8010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3990;0.4000;0.7990;0.8000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="110" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.2390;0.2400;0.3200;0.4000;0.4800;0.5600;0.6400;0.6410;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="200" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.3190;0.3200;0.4000;0.4800;0.5600;0.6400;0.7200;0.7210;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="290" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.3990;0.4000;0.4800;0.5600;0.6400;0.7200;0.8000;0.8010;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3990;0.4000;0.7990;0.8000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>
  <circle r="8" fill="#2563eb" cx="380" cy="18" opacity="0">
    <animate attributeName="cy" values="18;18;18;90;170;250;330;370;18;18" keyTimes="0.0000;0.4790;0.4800;0.5600;0.6400;0.7200;0.8000;0.8800;0.8810;1.0000" dur="10.0s" calcMode="linear" repeatCount="indefinite"/>
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.4790;0.4800;0.8790;0.8800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/>
  </circle>

  <!-- Cycle counter -->
  <text x="446" y="13" text-anchor="end" font-size="10" fill="#94a3b8">cycle:</text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=0<animate attributeName="opacity" values="0;1;0;0" keyTimes="0.0000;0.0790;0.0800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=1<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.0790;0.0800;0.1590;0.1600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=2<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.1590;0.1600;0.2390;0.2400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=3<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.2390;0.2400;0.3190;0.3200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=4<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3190;0.3200;0.3990;0.4000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=5<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.3990;0.4000;0.4790;0.4800;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=6<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.4790;0.4800;0.5590;0.5600;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=7<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.5590;0.5600;0.6390;0.6400;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=8<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.6390;0.6400;0.7190;0.7200;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>
  <text x="484" y="13" text-anchor="end" font-size="10" fill="#1e293b" opacity="0">t=9<animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0.0000;0.7190;0.7200;0.7990;0.8000;1.0000" dur="10.0s" calcMode="discrete" repeatCount="indefinite"/></text>

  <!-- Done overlay -->
  <rect x="125" y="175" width="235" height="40" rx="8" fill="#16a34a" opacity="0">
    <animate attributeName="opacity" values="0;0;0.9;0.9;0;0" keyTimes="0;0.8199;0.82;0.96;0.9601;1" dur="10.0s" repeatCount="indefinite"/>
  </rect>
  <text x="242" y="200" text-anchor="middle" fill="white" font-size="13" opacity="0">all 16 results valid
    <animate attributeName="opacity" values="0;0;1;1;0;0" keyTimes="0;0.8199;0.82;0.96;0.9601;1" dur="10.0s" repeatCount="indefinite"/>
  </text>

  <!-- Legend -->
  <circle cx="28" cy="400" r="7" fill="#dc2626"/>
  <text x="40" y="404" font-size="10" fill="#dc2626">A rows (right)</text>
  <circle cx="140" cy="400" r="7" fill="#2563eb"/>
  <text x="152" y="404" font-size="10" fill="#2563eb">B cols (down)</text>
  <rect x="250" y="393" width="13" height="13" rx="2" fill="#16a34a" stroke="#15803d" stroke-width="1"/>
  <text x="268" y="404" font-size="10" fill="#16a34a">PE accumulating</text>
  </svg>
  <button class="svg-anim__btn" data-running="true" onclick="svgAnimToggle(this)">⏸  Pause Animation</button>
  <p class="svg-anim__caption"><strong>Figure 1.</strong> One complete 10-cycle computation on the 4×4 systolic array. Red circles are A-row values flowing right; blue circles are B-column values flowing down. A PE flashes green on each cycle it accumulates. The diagonal wave is the skewing at work — PE[3][3] doesn't see its first data until cycle 6.</p>
</div>

---

## Timing

For an N×N array, all results are valid after `3*(N-1) + 1` clock cycles from reset. Breaking that down: the last skewed input element (`A[N-1][N-1]` or `B[N-1][N-1]`) is fed at cycle `2*(N-1)`, and it must then travel another `N-1` hops through the PE chain before reaching the corner PE. Total: `3*(N-1)` cycles of accumulation, with the result registered on the next clock edge.

For N=4: **10 cycles** at 12 MHz = 833 ns.

`top.v` tracks this with a simple counter and raises `done` — driving the LED — when the count reaches `TOTAL - 1`:

```verilog
localparam TOTAL = 3*(N-1) + 1;   // 10 for N=4

reg [3:0] cnt  = 0;
reg       done = 0;

always @(posedge clk) begin
    if (!resetn) begin
        cnt  <= 0;
        done <= 0;
    end else if (!done) begin
        cnt <= cnt + 1;
        if (cnt == TOTAL - 1) done <= 1;
    end
end
```

The LED lights up roughly 1 µs after reset. The result stays valid indefinitely because the PE accumulators hold their values once `done` is asserted.

---

## Test Matrices and Verification

`top.v` loads matrices from hex files at synthesis time using `$readmemh`. The defaults are:

```
A = [[1,1,1,1],    B = [[1,2,3,4],
     [2,2,2,2],         [1,2,3,4],
     [3,3,3,3],         [1,2,3,4],
     [4,4,4,4]]         [1,2,3,4]]
```

The expected result is `C[i][j] = (i+1) × 4 × (j+1)`, so C[0][0] = 4, C[3][3] = 64. Edit `a_matrix.hex` and `b_matrix.hex` (one byte per line in hex, row-major) and re-run `make` to try different matrices.

The testbench (`testbench.v`) verifies all 16 results against a reference computed in Verilog and dumps a waveform for GTKWave:

```
make sim       # run testbench with iverilog/vvp
make sim-show  # open waveform in gtkwave
```

---

## A Note on DSP Blocks

The iCE40UP5K has 8 `SB_MAC16` hardware multiplier blocks. This design has 16 PEs (each with an 8×8 multiplier), so it synthesises entirely in soft logic (LUTs) — which fits comfortably in the 5280 available LCs at 12 MHz. You can add `-dsp` to the `synth_ice40` call in the Makefile to let Yosys attempt DSP inference, though 8-bit operands may not trigger it depending on Yosys version.

---

## Build and Flash

```
make              # synthesize, place-and-route, pack bitstream
make sim          # simulate with iverilog
make sim-show     # open GTKWave
make hiprog       # flash via hiprog (set PORT= if needed)
```

---

## Connection to Google's TPU

Google's first TPU (2016) was designed around a single observation: neural network inference is dominated by one operation, matrix multiply. A forward pass through a fully-connected layer is C = A × B, where A is the weight matrix and B is a batch of input activations. Convolutions reduce to the same thing once the input is unrolled. Google measured that over 95% of inference compute in their data centres was matrix multiply, so they built an ASIC optimised for exactly that.

The core of TPU v1 is a 256×256 systolic array of 8-bit MAC units — 65,536 PEs at 700 MHz, delivering around 92 tera-operations per second. The architecture is weight-stationary: the weight matrix is pre-loaded once and held in the array while successive activation batches stream through from the left. Each weight value is read from DRAM once and reused across every input in the batch; a GPU running the same workload reads the same weights repeatedly, burning bandwidth with each access.

The array in this chapter is structurally identical: same dataflow, same diagonal skewing, same output-stationary accumulation. It is 64× smaller in each dimension (4 vs 256), runs at 12 MHz instead of 700 MHz, and produces its result in 10 clock cycles instead of ~500. The difference is only scale, not architecture.
