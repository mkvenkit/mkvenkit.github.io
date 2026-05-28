---
title: "Introduction to FPGAs"
description: "What is an FPGA, how it compares to CPUs and microcontrollers, and why you'd choose one for your next project."
chapter_num: 1
prev_url: /begin-fpga/
prev_title: "Overview"
next_url: /begin-fpga/ch02-digital-logic-basics/
next_title: "Digital Logic Basics"
---

## What's the deal with FPGAs?

IEEE article

https://spectrum.ieee.org/fpga-chip-ieee-milestone

A **Field-Programmable Gate Array** (FPGA) is an integrated circuit that can be reconfigured after manufacturing to implement virtually any digital circuit you can describe. Unlike a fixed processor that executes instructions one after another, an FPGA is a blank slate of programmable logic fabric — you wire it up in hardware.

The "field-programmable" part means a customer, developer, or hobbyist can configure it in the field, rather than the chip manufacturer hardwiring its logic during fabrication. The "gate array" part describes what's actually inside: an array of logic gates and flip-flops interconnected by a programmable routing network.

When you program an FPGA, you aren't uploading code that runs on a processor. You are describing a *circuit* — specifying which logic cells do what, and how they connect to each other and to the I/O pins. The result is hardware that behaves exactly like a custom chip you designed yourself.

## How FPGAs Differ from CPUs and Microcontrollers

To appreciate why FPGAs are useful, it helps to contrast them with the devices you might already know.

### CPUs and Microcontrollers

A CPU or microcontroller executes a program: it fetches an instruction, decodes it, executes it, and moves to the next one. This sequential cycle is typically measured in nanoseconds, but it means operations happen one at a time (or a small number at a time on superscalar cores). A microcontroller like the Arduino's ATmega328 has fixed peripherals — UART, SPI, I2C — etched permanently into silicon.

### FPGAs

An FPGA has no "instructions" in the traditional sense. Everything happens in parallel, simultaneously, every clock cycle. If you design a circuit with 100 adders, all 100 adders add their inputs at the same instant. There is no loop, no fetch-decode-execute — just logic propagating through combinational paths and state captured in flip-flops on each clock edge.

| Property | Microcontroller | CPU | FPGA |
|---|---|---|---|
| Execution model | Sequential | Sequential (pipelined) | Parallel / concurrent |
| Programmability | Software | Software | Hardware description |
| Fixed peripherals | Yes | Yes | No — you build them |
| Reconfigurable | No | No | Yes |
| Power efficiency | Medium | Lower | Can be very high |
| Performance ceiling | Fixed | Fixed | Scales with silicon area |

## Where Are FPGAs Used?

FPGAs appear wherever a problem needs high throughput, low and predictable latency, or custom I/O that no off-the-shelf processor provides.

### Telecommunications

Base stations and network switches use FPGAs to process data at line rate — handling frames arriving at 100 Gbps or more with deterministic, nanosecond-level timing that a general-purpose CPU cannot guarantee.

### High-Frequency Trading

Financial firms run trading algorithms on FPGAs because market data can be processed and orders submitted in under a microsecond, orders of magnitude faster than a software stack on a server.

### Video and Image Processing

Frame buffers, scalers, HDMI/SDI transceivers, and real-time filters all benefit from the parallel nature of FPGAs. A single FPGA can process full 4K video streams without breaking a sweat.

### Prototyping and ASIC Emulation

Before committing to a multi-million-dollar ASIC tape-out, chip designers prototype their designs on FPGAs. The logic is the same; the FPGA just runs slower and costs less.

### Embedded Systems and Maker Projects

Inexpensive boards like the Lattice iCE40 (found on the iCEBreaker) or Xilinx Artix-7 (found on the Arty A7) make FPGAs accessible to hobbyists and students. You can build custom CPU cores, retro game consoles, LED controllers, and audio synthesizers — all on affordable hardware.

## How an FPGA Gets Configured

Configuring an FPGA involves a toolchain, not a compiler in the traditional sense. The high-level steps are:

1. **Write HDL** — Describe your circuit in Verilog or VHDL (Hardware Description Language).
2. **Synthesize** — The synthesis tool converts your HDL into a netlist of logical primitives (AND gates, flip-flops, etc.).
3. **Place and Route** — The P&R tool maps those primitives onto the FPGA's actual logic cells and routes the connections through the programmable interconnect.
4. **Generate Bitstream** — The output is a bitstream file: a binary blob that, when loaded into the FPGA, configures every cell, every connection, every I/O standard.
5. **Program the FPGA** — The bitstream is sent to the chip over JTAG or SPI. Most FPGAs are volatile (SRAM-based), so they need to be programmed each power-on unless paired with a configuration flash chip.

## Choosing Your First FPGA Board

For learning, you want a board with:

- **A small FPGA** — fewer resources means faster compile times and a less overwhelming toolchain
- **Open-source or free tools** — Lattice iCE40 works with the fully open-source Yosys/nextpnr toolchain; Xilinx offers free Vivado WebPACK for smaller devices
- **Good community support** — tutorials, example projects, and forums

Two excellent starting points are the **iCEBreaker** (Lattice iCE40UP5K, $50–$60) for a fully open-source experience, and the **Arty A7-35T** (Xilinx Artix-7, ~$130) if you want access to Xilinx's mature toolchain and IP ecosystem.

## Summary

An FPGA is a reconfigurable hardware fabric you describe in a Hardware Description Language. Unlike a CPU, it executes logic in parallel rather than running sequential instructions, which makes it uniquely suited to high-throughput, low-latency, and custom-I/O problems. Configuring an FPGA means synthesizing HDL into a bitstream and loading it onto the chip.

In the next chapter we'll build the digital logic foundation you'll need before writing a single line of HDL.
