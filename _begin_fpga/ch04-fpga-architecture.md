---
title: "FPGA Architecture"
description: "Inside an FPGA: Look-Up Tables, flip-flops, configurable logic blocks, I/O pins, and the programmable routing fabric."
chapter_num: 4
prev_url: /begin-fpga/ch03-digital-logic-basics/
prev_title: "Digital Logic Basics"
next_url: /begin-fpga/
next_title: "Overview"
published: false
---

## The Programmable Logic Fabric

An FPGA is a large array of programmable resources connected by a programmable routing network. At power-on the chip is blank; when you load a bitstream, every programmable element — every logic cell, every routing switch, every I/O standard — is configured to implement your specific design.

The three main resources on a modern FPGA are:

1. **Configurable Logic Blocks (CLBs)** — the cells that implement logic and hold state
2. **Programmable Interconnect** — the routing fabric that wires CLBs together
3. **I/O Blocks (IOBs)** — the cells that connect internal logic to chip pins

Most FPGAs also include hard IP blocks — pre-built, non-programmable circuits embedded in silicon — such as block RAMs, DSP slices, PLLs, and sometimes even hard CPU cores.

## Look-Up Tables (LUTs)

The heart of every CLB is a **Look-Up Table**. A LUT is essentially a tiny, configurable truth table stored in SRAM cells.

A *k*-input LUT (written *k*-LUT) can implement *any* Boolean function of *k* inputs. It works like this:

- The LUT has 2^*k* SRAM configuration bits.
- The *k* input signals act as an address into that SRAM.
- The SRAM outputs the stored bit at that address — which is exactly the desired output for that input combination.

A 4-LUT has 2⁴ = 16 configuration bits, covering all 65,536 possible 4-input Boolean functions. Modern FPGAs (Xilinx 7-series, Lattice ECP5, Intel Cyclone) typically use 6-LUTs for more logic per cell, but the principle is the same.

### LUT Example

Suppose you want to implement `Y = (A AND B) OR (NOT C)`. With a 3-LUT, you build the truth table for all 8 input combinations of A, B, C, and store those 8 output values in the LUT's SRAM. At runtime, the LUT reads the stored value in one clock cycle — regardless of how complex the original Boolean expression was.

This is why FPGAs can implement arbitrary combinational logic so efficiently: the complexity of the function doesn't matter, only the number of inputs.

## Flip-Flops and Registers

Each LUT in a CLB is paired with one or more **D flip-flops** (DFFs). A flip-flop captures the value on its data input (D) at the rising edge of a clock and holds it until the next rising edge.

```
         ______
 D ------| DFF |------ Q
         |     |
 CLK ----|     |
         |_____|
```

Flip-flops are the memory elements of sequential logic. In a pipeline, every stage's combinational output is registered (captured in a flip-flop) before passing to the next stage. This breaks long combinational paths into shorter segments, allowing higher clock frequencies.

Most FPGAs allow each DFF to be used in two modes:

- **Registered output** — the LUT output feeds the flip-flop, and the flip-flop's Q feeds the next stage.
- **Pass-through** — the DFF is bypassed, and the LUT output drives the routing directly as pure combinational logic.

## Configurable Logic Blocks

A CLB (Xilinx terminology; Lattice calls it a PFU) groups several LUTs and flip-flops together with additional logic:

- **Carry chain logic** — dedicated fast-carry propagation paths for arithmetic (adders, counters). Using carry chains for addition is far faster and more area-efficient than building adders from LUTs alone.
- **Wide function multiplexers** — combine multiple LUTs to implement functions wider than a single LUT's input count.
- **Shift register mode** — some LUTs can be reconfigured as small shift registers, saving flip-flop resources for FIFO and delay lines.

On a Xilinx 7-series FPGA, a CLB contains two "slices," each with four 6-LUTs and eight flip-flops. A mid-range Artix-7 (XC7A35T) has about 5,200 slices — over 20,000 LUTs and 40,000 flip-flops.

## Programmable Interconnect

Logic cells are only useful if you can connect them. The **programmable routing fabric** consists of metal wire segments and programmable switches (pass transistors or transmission gates) that can connect any wire segment to any adjacent segment.

The routing fabric has a hierarchical structure:

- **Local routing** — short connections within a CLB or between adjacent CLBs, with minimal delay.
- **General routing** — medium-length segments that span several CLBs.
- **Global routing** — long, low-skew lines that span the entire chip, used for clocks and global control signals.

Place-and-route tools (Vivado, Quartus, nextpnr) choose which routing segments and switches to activate for each net in your design. Routing is why place-and-route takes longer than synthesis: the search space for a large design is enormous.

### Routing Delay

A significant fraction of a signal's propagation delay comes not from the logic cells themselves but from the routing. Two identical logic paths that use different routing resources can have very different delays. This is why timing-critical designs need careful attention to placement constraints.

## I/O Blocks

I/O Blocks connect the internal logic fabric to the chip's physical pins. Each IOB is highly configurable:

- **Voltage standard** — LVCMOS 3.3 V, LVCMOS 1.8 V, LVDS differential, SSTL for DDR memory, and many others.
- **Drive strength** — how much current the output can source or sink.
- **Slew rate** — controls the rise/fall speed of output transitions (faster = more EMI; slower = cleaner).
- **Input registers** — flip-flops inside the IOB capture input data with minimal routing delay, important for high-speed interfaces.
- **Pull-up / pull-down** — configurable weak pull resistors.

Getting IOB configuration right is essential when interfacing with external chips. A mismatch in voltage standard can permanently damage an FPGA or the device it's talking to.

## Hard IP Blocks

Most FPGAs embed fixed-function blocks in silicon that complement the programmable fabric:

| Block | Purpose |
|---|---|
| **Block RAM (BRAM)** | Dual-port synchronous RAM, typically 18 Kb or 36 Kb per block. Used for FIFOs, LUTs, frame buffers. |
| **DSP Slice** | Multiplier-accumulator (MAC) unit. Essential for signal processing, filters, and neural network inference. |
| **PLL / MMCM** | Phase-Locked Loop for clock synthesis — generate precise, phase-aligned clocks from a reference input. |
| **SerDes / SERDES** | High-speed serial transceivers for PCIe, SATA, Ethernet, etc. |
| **Hard CPU** | Zynq-7000 and Zynq UltraScale+ include ARM Cortex-A cores alongside the FPGA fabric. |

Hard IP runs faster and uses less power than equivalent soft (LUT-based) implementations. Learning when to use hard IP versus building your own in LUTs is a key skill in FPGA design.

## A Bird's Eye View of the Chip

Zoom out, and a typical mid-range FPGA die looks something like this:

```
+----------------------------------------------------------+
|  IOBs along all edges                                    |
|  +---------+  CLB array  +---------+  CLB array          |
|  | PLLs /  |             | PLLs /  |                     |
|  | MMCMs   |  BRAM cols  | MMCMs   |  BRAM cols          |
|  +---------+             +---------+                     |
|  CLB array    DSP cols   CLB array    DSP cols            |
|  ...                                                     |
+----------------------------------------------------------+
```

The CLB fabric fills most of the die. BRAM and DSP columns are interspersed at regular intervals. PLLs sit near the edges. IOBs form a ring around the perimeter.

## Summary

FPGAs implement logic using Look-Up Tables — tiny configurable truth tables stored in SRAM. Each LUT pairs with a flip-flop to support both combinational and sequential logic. CLBs group LUTs, flip-flops, carry chains, and local multiplexers into efficient slices. A programmable routing fabric connects CLBs to each other and to I/O Blocks. Hard IP blocks (BRAM, DSP, PLL) complement the soft fabric.

With this architecture in mind, you're ready to start describing circuits in hardware. Chapter 4 introduces Hardware Description Languages and explains how writing HDL differs from writing software.
