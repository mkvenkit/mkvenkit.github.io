---
title: "Getting Started with Humble iCE"
description: "Install the open-source iCE40 toolchain on Windows, macOS, or Linux, then build, simulate, and flash your first Verilog design — a blinking LED."
chapter_num: 1
prev_url: /begin-fpga/
prev_title: "Overview"
next_url: /begin-fpga/ch02-digital-design-with-verilog/
next_title: "Digital Design with Verilog"
---

This chapter gets you from a bare board and an empty terminal to a blinking LED programmed over USB — entirely with open-source tools. Along the way you will write your first Verilog module, run a simulation, inspect the waveform, synthesize to a bitstream, and flash it to the iCE40.

All source code lives under `examples/book/blinky/` in the companion repository.

---

## The Humble iCE Board

Humble iCE is a compact development board built around the **Lattice iCE40 UP5K** FPGA. An RP2040 microcontroller lives alongside the FPGA and serves two roles: it generates the 12 MHz clock the FPGA needs, and it acts as the USB programmer — no separate JTAG probe required.

Key facts about the iCE40 UP5K:

| Resource | Count |
|---|---|
| Logic cells (4-LUT + FF) | 5280 |
| SPRAM (single-port RAM) | 4 × 256 Kb |
| BRAM (block RAM) | 30 × 4 Kbit |
| DSP blocks | 8 |
| PLLs | 1 |
| Package | SG48 (QFN-48) |

The UP5K is small enough that synthesis and place-and-route finish in seconds, which makes it ideal for learning.

---

## Installing the Toolchain

The open-source iCE40 toolchain has three main components:

- **Yosys** — synthesis: turns Verilog into a netlist of logic primitives
- **nextpnr-ice40** — place and route: maps the netlist onto iCE40 fabric
- **IceStorm** (`icepack`, `iceprog`) — packs the routed design into a bitstream and programs the chip

You also need **Icarus Verilog** (`iverilog`) and **GTKWave** for simulation.

### macOS

The easiest path is [Homebrew](https://brew.sh):

```bash
brew install icestorm yosys nextpnr
brew install icarus-verilog gtkwave
```

Verify the tools are on your PATH:

```bash
yosys --version
nextpnr-ice40 --version
icepack --version
iverilog -V
```

### Linux (Ubuntu / Debian)

```bash
sudo apt update
sudo apt install fpga-icestorm nextpnr-ice40 yosys iverilog gtkwave
```

For newer versions of any tool, build from source following the instructions at [github.com/YosysHQ](https://github.com/YosysHQ).

On Linux, add yourself to the `dialout` group so you can access the USB serial port without `sudo`:

```bash
sudo usermod -aG dialout $USER
# Log out and back in for the change to take effect
```

### Windows

The recommended approach on Windows is [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), a self-contained bundle with all tools pre-built:

1. Download the latest `oss-cad-suite-windows-x64-*.tgz` from the [releases page](https://github.com/YosysHQ/oss-cad-suite-build/releases).
2. Extract it to a folder such as `C:\oss-cad-suite`.
3. Activate the environment in each terminal session before using the tools:

```bat
C:\oss-cad-suite\environment.bat
```

Or add `C:\oss-cad-suite\bin` to your `PATH` permanently via System Properties → Environment Variables → Path.

Verify from a Command Prompt or PowerShell:

```bat
yosys --version
nextpnr-ice40 --version
icepack --version
iverilog -V
```

### Programmer: hiprog

Humble iCE uses a custom programmer called **hiprog** that communicates with the RP2040 over USB. It is a Python script bundled in the companion repository:

```
hiprog/hiprog.py
```

Install its only dependency:

```bash
pip install pyserial
```

Plug in the board. The RP2040 enumerates as a USB serial port:

- **macOS** — `/dev/cu.usbmodemHI_V3_0011` (or similar)
- **Linux** — `/dev/ttyACM0`
- **Windows** — `COM3` (check Device Manager)

The Makefile defaults to `/dev/cu.usbmodemHI_V3_0011`. Override it on the command line if yours differs:

```bash
make hiprog PORT=/dev/ttyACM0        # Linux
make hiprog PORT=COM3                # Windows
```

---

## The Blinky Project

The blinky project toggles the blue LED (D2) at about 1.4 Hz — slow enough to see, fast enough to confirm the clock is running.

```
examples/book/blinky/
├── top.v        ← Verilog design
├── blinky.pcf   ← Pin constraints
└── Makefile     ← Build rules
```

### Pin Constraints (`blinky.pcf`)

The Physical Constraints File maps Verilog port names to physical FPGA pins:

```
set_io clk 35
set_io led 13
```

Pin 35 is connected to the RP2040's GP21, which outputs a 12 MHz clock. Pin 13 drives the blue LED D2 through a current-limiting resistor.

### The Verilog Design (`top.v`)

```verilog
`default_nettype none

module blinky(
  input  clk,   // 12 MHz from RP2040 GP21 — FPGA pin 35
  output led    // D2 Blue LED — FPGA pin 13
);
```

**Always open with `` `default_nettype none ``.** Without it, any undeclared signal is implicitly a 1-bit wire, silently turning typos into phantom nets. With it, the tools error on any undeclared name.

#### Reset Synchronizer

```verilog
reg [7:0] resetn_counter = 0;
wire resetn = &resetn_counter;

always @(posedge clk) begin
    if (!resetn)
        resetn_counter <= resetn_counter + 1;
end
```

iCE40 registers always power up as 0. The 8-bit counter starts at `8'h00` and increments every clock cycle. `&resetn_counter` is a **reduction AND** — it returns 1 only when every bit is 1, i.e., after 255 cycles. Until then `resetn` is 0 and the rest of the design stays in reset. At 12 MHz, 255 cycles is about 21 µs — enough time for power rails to stabilise before logic starts running.

#### Blink Counter

```verilog
reg RL;
reg [22:0] counter;

always @(posedge clk) begin
    if (!resetn) begin
        counter <= 0;
    end else begin
        counter <= counter + 1;
        if (!counter)
            RL <= ~RL;
    end
end

assign led = RL;
```

A 23-bit free-running counter wraps from `2^23 − 1` back to 0 once every:

```
2^23 / 12 000 000 Hz  ≈  0.70 s
```

Each wrap, `!counter` is momentarily true and `RL` toggles. Since RL toggles every 0.70 s, the LED completes a full on/off cycle every **~1.4 s**.

---

## Simulation

Simulation lets you inspect every internal signal before touching the hardware. You can verify the reset sequence fires correctly and the counter is counting — all in a few seconds.

Create `testbench.v` alongside `top.v`:

```verilog
`default_nettype none
`timescale 1ns/1ps

module tb();

reg clk = 0;
wire led;

blinky dut (
    .clk(clk),
    .led(led)
);

// 12 MHz clock: period ≈ 83 ns → half-period ≈ 42 ns
always #42 clk = ~clk;

initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, tb);
    #50000
    $finish;
end

endmodule
```

Compile and run:

```bash
iverilog -o tb.out -s tb testbench.v top.v
vvp tb.out
```

Open the waveform:

```bash
gtkwave testbench.vcd
```

In GTKWave, drag `clk`, `resetn_counter`, `resetn`, `counter`, and `led` into the signals pane. What you should see:

1. `resetn_counter` incrementing from 0 on every rising clock edge.
2. `resetn` going high once `resetn_counter` reaches `8'hFF`.
3. `counter` resetting to 0 then counting freely.
4. At simulation scale the 23-bit wrap takes millions of cycles, so you won't see the LED toggle — but you can confirm reset behaviour and that the counter is incrementing correctly.

The Makefile wraps both steps:

```bash
make sim       # compile and run
make sim-show  # open GTKWave
```

---

## Synthesis and Place-and-Route

Running `make` triggers the three-stage build:

```
top.v
  │
  ▼  yosys — synthesis
blinky.json   (technology-mapped netlist)
  │
  ▼  nextpnr-ice40 — place and route
blinky.asc    (placed-and-routed design)
  │
  ▼  icepack — bitstream packing
blinky.bin    (binary bitstream ready to flash)
```

```bash
make
```

**Synthesis (Yosys)** parses the Verilog, applies optimisations, and maps to iCE40 primitives — `SB_LUT4`, `SB_DFF`, `SB_CARRY`. It writes `blinky.json` and a log file (`blinky-yosys.log`) worth reading once to understand what the synthesiser decided.

**Place and route (nextpnr-ice40)** assigns each logic cell to a physical iCE40 cell and routes all connections through the programmable interconnect. It reads `blinky.json` and `blinky.pcf` and writes `blinky.asc`.

**Bitstream packing (icepack)** converts the ASCII routing description to the compact binary `blinky.bin`.

### Visualising the Design

The Makefile has four targets that open synthesis diagrams as SVG:

```bash
make show-rtl    # RTL view — closest to the Verilog you wrote
make show-gates  # gate-level after synthesis (AND/OR/NOT/DFF)
make show-synth  # iCE40 primitives (SB_LUT4, SB_DFF)
make show-pnr    # place-and-routed result in nextpnr GUI
```

For blinky the RTL view shows the counter register, the reduction AND feeding `resetn`, and the toggle flip-flop driving `led`. The synth view shows how Yosys packed all of that into a handful of `SB_LUT4` and `SB_DFF` primitives — confirming the design is tiny.

---

## Uploading to the Board

With the board connected over USB:

```bash
make hiprog
```

This runs hiprog, which sends the bitstream to the RP2040 which streams it to the iCE40 over SPI. The transfer takes under a second. If everything is correct the blue LED starts blinking at ~1.4 Hz.

### Troubleshooting

**LED doesn't blink** — Check that `blinky.bin` has a non-zero size (`ls -lh blinky.bin`). A zero-byte binary usually means a port name mismatch between the PCF and the Verilog module.

**`hiprog` can't open the port on Linux** — Verify you are in the `dialout` group (`groups $USER`). If not: `sudo usermod -aG dialout $USER`, then log out and back in.

**`hiprog` can't find the port on Windows** — Check Device Manager for the correct COM port number and pass it explicitly: `make hiprog PORT=COM5`.

**nextpnr reports an error placing cells** — This won't happen with blinky, but if you modify the design and see placement errors, confirm the PCF pin numbers match the actual board schematic.

---

## Summary

You now have a working iCE40 development environment and have completed the full toolchain loop: write Verilog → simulate → synthesize → place and route → flash.

The key ideas from this chapter:

- `` `default_nettype none `` catches undeclared-wire bugs at compile time.
- A reduction AND (`&counter`) cleanly detects the all-ones state without a comparator.
- The three-step build is: Yosys (synthesis) → nextpnr (P&R) → icepack (bitstream).
- Simulate with Icarus Verilog and inspect waveforms in GTKWave before going near hardware.
- hiprog streams the bitstream to the iCE40 through the RP2040 over USB — no extra probe needed.

In the next chapter we step back from the toolchain and take a proper tour of digital design with Verilog: gates, state machines, and the datapath-controller pattern.
