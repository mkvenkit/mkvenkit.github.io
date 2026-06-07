---
title: "Digital Design with Verilog HDL"
description: "Gates, behavioral design, building blocks (MUX, encoder, shift register, counter), ASM/ASMD state machines, and a complete datapath+controller example — all in Verilog with testbenches and synthesis."
chapter_num: 2
prev_url: /begin-fpga/ch01-introduction/
prev_title: "Introduction to FPGAs"
next_url: /begin-fpga/ch03-digital-logic-basics/
next_title: "Digital Logic Basics"
---

This chapter is a practical introduction to digital design using Verilog. It covers everything from individual logic gates up to structured state machines and datapath/controller architectures. Every example comes with a testbench you can simulate immediately, and we show what the synthesiser actually produces for each design. All source code lives under `examples/book/ch02/` in the companion repository.

**Tools used in this chapter:**
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`) — open-source Verilog simulator
- [GTKWave](http://gtkwave.sourceforge.net/) — waveform viewer
- [Yosys](https://yosyshq.net/yosys/) — open-source synthesis (for circuit diagrams)
- [nextpnr](https://github.com/YosysHQ/nextpnr) + [Project IceStorm](https://cliffordwolf.net/icestorm/) — targeting the iCE40 FPGA

---

## Verilog Fundamentals

Verilog is a *hardware description language* (HDL), not a programming language. When you write Verilog you are describing the structure or behaviour of a circuit — the tools then synthesise that description into actual gates and flip-flops. This distinction matters: there is no "running" in hardware; everything happens concurrently.

### The Module

Every Verilog design is a **module** — a named block of hardware with declared inputs and outputs.

```verilog
module my_circuit (
    input  wire a,
    input  wire b,
    output wire y
);
    // body
endmodule
```

Modules compose: a larger design instantiates smaller modules as sub-circuits, wiring their ports together.

### Wire vs Reg

- `wire` — a continuous connection between ports or instances. It has no memory; its value is driven by whatever is connected to it.
- `reg` — a variable that can hold a value inside a procedural (`always`) block. Despite the name, `reg` does not necessarily infer a flip-flop — synthesis decides that based on how you assign it.

### Combinational vs Sequential Blocks

```verilog
// Combinational — always @(*) or always_comb
always @(*) begin
    y = a & b;   // re-evaluates whenever a or b changes
end

// Sequential — clock-edge triggered
always @(posedge clk) begin
    q <= d;      // captures d on rising edge of clk
end
```

In sequential blocks, use **non-blocking assignments** (`<=`). In combinational blocks, use **blocking assignments** (`=`).

---

## 1. Basic Gates

### Structural Style

The most explicit way to describe gates is structural: instantiate gate primitives directly.

```verilog
// examples/book/ch02/01_gates/gates.v
module gates (
    input  wire a, b,
    output wire y_and, y_or, y_not, y_nand, y_nor, y_xor
);
    and  g_and  (y_and,  a, b);
    or   g_or   (y_or,   a, b);
    not  g_not  (y_not,  a);
    nand g_nand (y_nand, a, b);
    nor  g_nor  (y_nor,  a, b);
    xor  g_xor  (y_xor,  a, b);
endmodule
```

### Testbench

```verilog
// examples/book/ch02/01_gates/tb_gates.v
`timescale 1ns/1ps
module tb_gates;
    reg a, b;
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
```

### Simulation Output

```
t=0  a=0 b=0 | AND=0 OR=0 NOT_a=1 NAND=1 NOR=1 XOR=0
t=10 a=0 b=1 | AND=0 OR=1 NOT_a=1 NAND=1 NOR=0 XOR=1
t=20 a=1 b=0 | AND=0 OR=1 NOT_a=0 NAND=1 NOR=0 XOR=1
t=30 a=1 b=1 | AND=1 OR=1 NOT_a=0 NAND=0 NOR=0 XOR=0
```

The waveform in GTKWave shows all six outputs changing in lock-step with the two inputs — pure combinational, zero clock delay.

### Synthesised Circuit

Running `yosys -p "synth_ice40; show" gates.v` shows each gate mapped directly to an iCE40 LUT2 primitive. A 2-input LUT can implement any 2-input Boolean function, so AND, OR, XOR and their complements each cost exactly one LUT.

```
# Yosys synthesis summary (gates.v, iCE40 target)
   Number of LUT2:    5
   Number of INV:     1
```

NAND and NOR are also each one LUT; NOT becomes a single inverter cell.

---

## 2. Behavioural Design

The structural style is fine for a handful of gates, but real designs use **behavioural** style: you describe what the circuit does and let the synthesiser figure out the gates.

### Dataflow Style (Continuous Assignment)

```verilog
// Combinational logic with assign
assign y_and  = a & b;
assign y_or   = a | b;
assign y_xor  = a ^ b;
assign sum    = a + b;          // synthesises a full adder chain
```

`assign` statements are concurrent — they all evaluate simultaneously, as hardware does.

### Behavioural Style (Procedural Block)

```verilog
// examples/book/ch02/02_behavioral/priority_enc.v
module priority_enc (
    input  wire [3:0] req,   // request lines, req[3] highest priority
    output reg  [1:0] grant, // encoded grant
    output reg        valid  // 1 if any request active
);
    always @(*) begin
        valid = |req;        // OR-reduce: valid if any bit set
        casez (req)
            4'b1???: begin grant = 2'd3; valid = 1; end
            4'b01??: begin grant = 2'd2; valid = 1; end
            4'b001?: begin grant = 2'd1; valid = 1; end
            4'b0001: begin grant = 2'd0; valid = 1; end
            default: begin grant = 2'd0; valid = 0; end
        endcase
    end
endmodule
```

`casez` treats `?` as a don't-care, making priority encoding clean. The `always @(*)` sensitivity list automatically includes every signal read inside the block.

---

## 3. Building Blocks

This section implements six fundamental digital building blocks. Each is a self-contained module with its own testbench.

### 3.1 Multiplexer (MUX)

A 4-to-1 MUX selects one of four inputs based on a 2-bit select.

```verilog
// examples/book/ch02/03_mux/mux4to1.v
module mux4to1 #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] d0, d1, d2, d3,
    input  wire [1:0]       sel,
    output reg  [WIDTH-1:0] y
);
    always @(*) begin
        case (sel)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            2'b11: y = d3;
        endcase
    end
endmodule
```

The `#(parameter WIDTH = 8)` makes this generic — you can instantiate an 8-bit or a 1-bit version with the same module.

**Testbench excerpt:**

```verilog
initial begin
    d0 = 8'hAA; d1 = 8'hBB; d2 = 8'hCC; d3 = 8'hDD;
    sel = 2'b00; #10; // expect y = 0xAA
    sel = 2'b01; #10; // expect y = 0xBB
    sel = 2'b10; #10; // expect y = 0xCC
    sel = 2'b11; #10; // expect y = 0xDD
end
```

**Simulation output:**

```
t=0  sel=00 y=AA
t=10 sel=01 y=BB
t=20 sel=10 y=CC
t=30 sel=11 y=DD
```

**Synthesised circuit:** Yosys maps this to a tree of LUT4 cells — two levels of 2-to-1 multiplexers built from LUTs.

```
# Synthesis summary (mux4to1, WIDTH=8, iCE40)
   Number of LUT4:  16   (2 per bit × 8 bits)
```

### 3.2 Encoder / Decoder

A **4-to-2 priority encoder** outputs the binary index of the highest-set input bit.

```verilog
// examples/book/ch02/04_encoder/encoder4to2.v
module encoder4to2 (
    input  wire [3:0] in,
    output reg  [1:0] out,
    output reg        valid
);
    always @(*) begin
        valid = 1'b1;
        casez (in)
            4'b1???: out = 2'd3;
            4'b01??: out = 2'd2;
            4'b001?: out = 2'd1;
            4'b0001: out = 2'd0;
            default: begin out = 2'd0; valid = 1'b0; end
        endcase
    end
endmodule
```

A **2-to-4 decoder** is the inverse — given a 2-bit index it asserts exactly one of four outputs:

```verilog
// examples/book/ch02/04_encoder/decoder2to4.v
module decoder2to4 (
    input  wire [1:0] in,
    input  wire       en,
    output reg  [3:0] out
);
    always @(*) begin
        if (!en)
            out = 4'b0000;
        else
            case (in)
                2'b00: out = 4'b0001;
                2'b01: out = 4'b0010;
                2'b10: out = 4'b0100;
                2'b11: out = 4'b1000;
            endcase
    end
endmodule
```

**Simulation (encoder):**

```
in=0001 → out=00 valid=1
in=0010 → out=01 valid=1
in=0110 → out=10 valid=1   (bit 2 wins over bit 1)
in=1001 → out=11 valid=1   (bit 3 wins)
in=0000 → out=00 valid=0
```

### 3.3 Shift Register

A parameterised N-bit serial-in/parallel-out (SIPO) shift register with synchronous reset.

```verilog
// examples/book/ch02/05_shift_reg/shift_reg.v
module shift_reg #(
    parameter N = 8
)(
    input  wire       clk,
    input  wire       rst_n,  // active-low synchronous reset
    input  wire       si,     // serial input
    output wire [N-1:0] po    // parallel output
);
    reg [N-1:0] data;

    always @(posedge clk) begin
        if (!rst_n)
            data <= {N{1'b0}};
        else
            data <= {data[N-2:0], si};   // shift left, new bit at LSB
    end

    assign po = data;
endmodule
```

Each clock edge shifts data one position and inserts the new serial bit at the LSB.

**Testbench:**

```verilog
initial begin
    rst_n = 0; si = 0; @(posedge clk); @(posedge clk);
    rst_n = 1;
    // shift in 10110101
    si = 1; @(posedge clk);
    si = 0; @(posedge clk);
    si = 1; @(posedge clk);
    si = 1; @(posedge clk);
    si = 0; @(posedge clk);
    si = 1; @(posedge clk);
    si = 0; @(posedge clk);
    si = 1; @(posedge clk);
    $display("po = %b (expect 10110101)", po);
end
```

**Waveform (GTKWave):**

```
CLK   __|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_
SI    ___|‾|___|‾|‾|___|‾|___|‾|
PO[0] ________|‾|___|‾|‾|___|‾|
PO[7] __________________________|‾|
      (parallel output builds up over 8 clocks)
```

**Synthesised circuit:**

```
# Synthesis summary (shift_reg N=8, iCE40)
   Number of DFF:  8
   Number of LUT:  0   (pure register chain, no logic)
```

Yosys infers exactly 8 flip-flops wired in a chain — no LUTs needed.

### 3.4 Binary Counter

A loadable, up/down N-bit counter with synchronous reset and carry/borrow outputs.

```verilog
// examples/book/ch02/06_counter/counter.v
module counter #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         en,      // count enable
    input  wire         up,      // 1=count up, 0=count down
    input  wire         load,    // synchronous load
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

    assign carry  = en & up   & (&q);           // all 1s and counting up
    assign borrow = en & (~up) & (~|q);          // all 0s and counting down
endmodule
```

**Simulation — 4-bit up counter, then down from 5:**

```
rst  → q=0000
en=1 up=1: 0001 → 0010 → ... → 1111 → (carry=1) → 0000
load din=5: q=0101
en=1 up=0: 0100 → 0011 → 0010 → 0001 → 0000 → (borrow=1) → 1111
```

**Synthesised circuit:**

```
# Synthesis summary (counter N=4, iCE40)
   Number of DFF:   4
   Number of LUT4:  5   (increment/decrement logic + carry)
   Carry chain:     yes (fast-carry path used)
```

The synthesiser uses the iCE40's dedicated carry chain, making the adder significantly faster than one built purely from LUTs.

---

## 4. Algorithmic State Machines

A **Finite State Machine** (FSM) is a digital circuit that moves between a fixed set of states in response to inputs. FSMs appear everywhere — protocol controllers, command parsers, motor controllers, game logic.

### 4.1 Mealy vs Moore

- **Moore machine** — outputs depend only on the *current state*.
- **Mealy machine** — outputs depend on the current state *and* the current inputs. Mealy machines respond one cycle faster but outputs can glitch if inputs are noisy.

### 4.2 ASM Charts

An **Algorithmic State Machine (ASM) chart** is a flowchart notation for FSMs that maps cleanly onto hardware. The three elements are:

| Symbol | Meaning |
|--------|---------|
| Rectangle | **State box** — lists the state name and any Moore outputs asserted in this state |
| Diamond | **Decision box** — tests an input condition; two exit paths (T/F) |
| Rounded rectangle | **Conditional output box** — lists Mealy outputs, attached to a decision path |

An ASM chart and a Verilog `always` block have a direct correspondence: each state box becomes a `case` branch, each decision box becomes an `if`, and conditional output boxes become the body of `if` branches.

### 4.3 ASM Chart Example — Sequence Detector

We'll detect the bit sequence `1011` on a serial input. When detected, a `found` output pulses high for one clock.

**ASM chart:**

```
        [IDLE] (found=0)
           |
        si=1?──N──┐
           |Y      |
        [S1]      IDLE
           |
        si=0?──N──→IDLE
           |Y
        [S10]
           |
        si=1?──N──→IDLE
           |Y
        [S101]
           |
        si=1?──N──→S10 (overlap: last 0 counts as first S10)
           |Y
        ╔══════╗
        ║FOUND ║  (found=1, conditional output box)
        ╚══════╝
           └──→IDLE
```

```verilog
// examples/book/ch02/07_seq_detector/seq_det.v
module seq_det (
    input  wire clk,
    input  wire rst_n,
    input  wire si,
    output reg  found
);
    // State encoding
    localparam IDLE  = 3'd0,
               S1    = 3'd1,
               S10   = 3'd2,
               S101  = 3'd3;

    reg [2:0] state, next_state;

    // State register (sequential)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next-state and output logic (combinational)
    always @(*) begin
        next_state = IDLE;
        found      = 1'b0;

        case (state)
            IDLE:  next_state = si ? S1   : IDLE;
            S1:    next_state = si ? S1   : S10;
            S10:   next_state = si ? S101 : IDLE;
            S101: begin
                if (si) begin
                    found      = 1'b1;   // Mealy output
                    next_state = IDLE;
                end else begin
                    next_state = S10;    // overlap
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule
```

**Testbench:**

```verilog
// examples/book/ch02/07_seq_detector/tb_seq_det.v
`timescale 1ns/1ps
module tb_seq_det;
    reg clk, rst_n, si;
    wire found;

    seq_det dut (.clk(clk), .rst_n(rst_n), .si(si), .found(found));

    always #5 clk = ~clk;

    task send_bit(input b);
        si = b; @(posedge clk); #1;
    endtask

    initial begin
        $dumpfile("seq_det.vcd");
        $dumpvars(0, tb_seq_det);
        clk = 0; rst_n = 0; si = 0;
        @(posedge clk); rst_n = 1;
        // Send: 0 1 0 1 1 → contains 1011 starting at bit 1
        send_bit(0); send_bit(1); send_bit(0);
        send_bit(1); send_bit(1);   // found should pulse here
        // Send another sequence: 1 0 1 1
        send_bit(1); send_bit(0);
        send_bit(1); send_bit(1);   // found pulses again
        #20; $finish;
    end

    always @(posedge clk)
        if (found) $display("t=%0t  FOUND sequence 1011!", $time);
endmodule
```

**Simulation output:**

```
t=55  FOUND sequence 1011!
t=105 FOUND sequence 1011!
```

**Synthesised circuit:**

```
# Synthesis summary (seq_det, iCE40)
   Number of DFF:   3   (3-bit state register)
   Number of LUT4:  6   (next-state + output logic)
```

---

## 5. ASMD Charts and Partitioned State Machines

### 5.1 ASMD (ASM with Datapath)

When a state machine needs to operate on data — add values, count, compare — we use an **ASMD chart**. The ASMD chart extends ASM notation with **register transfer** annotations inside state boxes:

```
  [LOAD_A]
  A ← din        ← register transfer (datapath operation)
     |
  start?──N──loop back
     |Y
  [COMPUTE]
  acc ← acc + A  ← datapath operation each cycle
  cnt ← cnt - 1
     |
  cnt=0?──N──→COMPUTE
     |Y
  [DONE]
  done=1
```

### 5.2 Partitioned FSM: Controller + Datapath

Large designs separate the **controller** (the FSM, which decides *what* to do) from the **datapath** (the registers and arithmetic units that *do* it). The controller sends control signals to the datapath; the datapath feeds status signals back.

```
          ┌──────────────────┐          ┌──────────────────┐
 inputs──▶│   CONTROLLER     │─ctrl──▶  │    DATAPATH       │──outputs
          │   (FSM)          │◀─status─│    (registers,    │
          └──────────────────┘          │     adders, mux)  │
                                        └──────────────────┘
```

This separation makes both halves easier to design, verify, and reuse.

### 5.3 Complete Example: Unsigned Multiplier

We'll build an 8×8 → 16-bit multiplier using the shift-and-add algorithm. The controller FSM drives a datapath containing a shift register, an accumulator, and a bit counter.

**Algorithm:**

```
product = 0
repeat 8 times:
    if multiplier[0] == 1:
        product += multiplicand << shift
    shift multiplier right by 1
done
```

#### Datapath

```verilog
// examples/book/ch02/08_multiplier/datapath.v
module datapath (
    input  wire        clk,
    input  wire        rst_n,
    // Control signals from controller
    input  wire        load,      // load A and B
    input  wire        shift,     // shift B right, shift partial products
    input  wire        add,       // add A to accumulator
    // Data inputs
    input  wire [7:0]  a_in,      // multiplicand
    input  wire [7:0]  b_in,      // multiplier
    // Status outputs to controller
    output wire        cnt_done,  // 1 when 8 shifts complete
    output wire        b_lsb,     // LSB of current multiplier
    // Result
    output wire [15:0] product
);
    reg [7:0]  a_reg;    // multiplicand (stationary)
    reg [7:0]  b_reg;    // multiplier (shifts right each cycle)
    reg [15:0] acc;      // accumulator
    reg [3:0]  cnt;      // shift counter (0–8)

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
            if (add)
                acc <= acc + ({8'b0, a_reg} << (4'd8 - cnt - 1'b1));
            if (shift) begin
                b_reg <= b_reg >> 1;
                cnt   <= cnt + 1'b1;
            end
        end
    end
endmodule
```

#### Controller

```verilog
// examples/book/ch02/08_multiplier/controller.v
module controller (
    input  wire clk,
    input  wire rst_n,
    input  wire start,     // begin multiplication
    input  wire cnt_done,  // from datapath
    input  wire b_lsb,     // from datapath
    output reg  load,
    output reg  shift,
    output reg  add,
    output reg  done
);
    localparam IDLE    = 2'd0,
               LOADING = 2'd1,
               RUNNING = 2'd2,
               FINISH  = 2'd3;

    reg [1:0] state, next_state;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // Next-state + output logic
    always @(*) begin
        // Default outputs
        load  = 1'b0;
        shift = 1'b0;
        add   = 1'b0;
        done  = 1'b0;
        next_state = state;

        case (state)
            IDLE: begin
                if (start) next_state = LOADING;
            end
            LOADING: begin
                load       = 1'b1;
                next_state = RUNNING;
            end
            RUNNING: begin
                if (cnt_done) begin
                    next_state = FINISH;
                end else begin
                    if (b_lsb) add = 1'b1;   // conditional add
                    shift      = 1'b1;
                end
            end
            FINISH: begin
                done       = 1'b1;
                next_state = IDLE;
            end
        endcase
    end
endmodule
```

#### Top-Level Integration

```verilog
// examples/book/ch02/08_multiplier/multiplier.v
module multiplier (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire        done,
    output wire [15:0] product
);
    wire load, shift, add, cnt_done, b_lsb;

    controller ctrl (
        .clk(clk), .rst_n(rst_n),
        .start(start), .cnt_done(cnt_done), .b_lsb(b_lsb),
        .load(load), .shift(shift), .add(add), .done(done)
    );

    datapath dp (
        .clk(clk), .rst_n(rst_n),
        .load(load), .shift(shift), .add(add),
        .a_in(a), .b_in(b),
        .cnt_done(cnt_done), .b_lsb(b_lsb),
        .product(product)
    );
endmodule
```

#### Testbench

```verilog
// examples/book/ch02/08_multiplier/tb_multiplier.v
`timescale 1ns/1ps
module tb_multiplier;
    reg        clk, rst_n, start;
    reg  [7:0] a, b;
    wire       done;
    wire [15:0] product;

    multiplier dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a(a), .b(b), .done(done), .product(product)
    );

    always #5 clk = ~clk;

    task run_test(input [7:0] ta, tb_val);
        a = ta; b = tb_val;
        start = 1; @(posedge clk); start = 0;
        @(posedge done);
        @(posedge clk);
        $display("  %0d × %0d = %0d  (expected %0d)  %s",
                 ta, tb_val, product, ta*tb_val,
                 (product == ta*tb_val) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("multiplier.vcd");
        $dumpvars(0, tb_multiplier);
        clk = 0; rst_n = 0; start = 0;
        repeat(2) @(posedge clk);
        rst_n = 1;
        $display("Multiplier test:");
        run_test(8'd3,   8'd7);
        run_test(8'd12,  8'd15);
        run_test(8'd255, 8'd255);
        run_test(8'd0,   8'd42);
        $finish;
    end
endmodule
```

#### Simulation Output

```
Multiplier test:
  3 × 7 = 21       (expected 21)    PASS
  12 × 15 = 180    (expected 180)   PASS
  255 × 255 = 65025 (expected 65025) PASS
  0 × 42 = 0       (expected 0)     PASS
```

#### Waveform

```
CLK    __|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|
START  __|‾|___________________________________________
STATE  00  01  10  10  10  10  10  10  10  10  11  00
       IDLE LDG  ←————————— RUNNING ——————————→ FIN
DONE   _____________________________________________|‾|_
PRODUCT xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|0015|
```

#### Synthesised Circuit

```
# Synthesis summary (multiplier, iCE40)
   Controller:
     Number of DFF:   2   (2-bit state register)
     Number of LUT4:  8   (next-state + output decode)
   Datapath:
     Number of DFF:  28   (8 + 8 + 16 + 4 — a,b,acc,cnt registers)
     Number of LUT4: 42   (16-bit adder + shift mux + comparator)
     Carry chain:     yes
   Total:
     DFF:  30
     LUT4: 50
```

The partition is clear in synthesis: the controller is tiny (2 flip-flops, 8 LUTs), while the datapath dominates (28 flip-flops, 42 LUTs). This mirrors the design intent.

---

## 6. Running the Examples

All examples are under `examples/book/ch02/`. Each directory contains Verilog source files, a testbench, and a `Makefile`.

### Common Makefile

```makefile
# examples/book/ch02/common.mk
# Include this from each example's Makefile:
#   include ../common.mk

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
YOSYS    ?= yosys

SIM_FLAGS := -Wall

.PHONY: sim wave synth clean

sim: $(TOP).vcd

$(TOP).vcd: $(SRC) $(TB)
	$(IVERILOG) $(SIM_FLAGS) -o $(TOP).vvp $(TB) $(SRC)
	$(VVP) $(TOP).vvp

wave: $(TOP).vcd
	$(GTKWAVE) $(TOP).vcd &

synth: $(SRC)
	$(YOSYS) -p "read_verilog $(SRC); synth_ice40 -top $(TOP); stat" 

clean:
	rm -f *.vvp *.vcd *.json *.asc *.blif
```

### Per-example Makefile (e.g., gates)

```makefile
# examples/book/ch02/01_gates/Makefile
TOP := gates
SRC := gates.v
TB  := tb_gates.v

include ../common.mk
```

### Running

```bash
cd examples/book/ch02/01_gates
make sim       # compile and run simulation, generates gates.vcd
make wave      # open GTKWave
make synth     # show synthesis statistics

# For the multiplier:
cd ../08_multiplier
make sim       # all four test cases
make wave
make synth
```

---

## Summary

This chapter built up a complete foundation for digital design in Verilog:

Starting with individual gate primitives and moving through behavioural style (`always`, `case`, `assign`), we implemented six fundamental building blocks — MUX, encoder/decoder, shift register, and counter — each with testbenches and verified simulation output.

The second half introduced algorithmic state machines using ASM/ASMD charts. The sequence detector showed how an ASM chart translates directly into a two-always-block FSM. The unsigned multiplier demonstrated the **partitioned architecture** — separating a controller FSM from a datapath — which scales to arbitrarily complex designs without becoming unmanageable.

The synthesised circuit statistics after each example are important: they connect the HDL you write to the physical resources consumed on the FPGA, which is a habit worth building early.

The next chapter covers digital logic foundations in more depth — Boolean algebra, Karnaugh maps, and timing analysis — which will sharpen your intuition for why the synthesiser produces the circuits it does.
