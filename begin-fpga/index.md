---
layout: book
title: "The Humble iCE Cookbook"
description: "A hands-on beginner's guide to Digital Design with FPGAs."
featured_image: /images/humble-ice.jpg
---

<p style="font-size:0.75rem; color: #888; margin-bottom: 0.5rem;">Last Updated: June 28, 2026 &nbsp;·&nbsp; <a href="/begin-fpga/changelog/">Changelog</a></p>

<div class="book-home__cover">
  <img src="/images/fpga-beginners-cover-small.jpg" alt="The Humble iCE Cookbook cover">
</div>

<div class="book-home__intro">
  <p>
    In March 2026, the IEEE dedicated a Milestone plaque to the field-programmable gate array, honouring
    Ross Freeman's 1984 invention and the Xilinx XC2064 that shipped a year later with an 8-by-8 grid of
    64 programmable logic blocks. Freeman's bet was that as transistors got cheap, flexibility would matter
    more than squeezing out every last one. Four decades on, that bet has paid off: FPGAs sit inside routers,
    base stations, MRI scanners, and AI accelerators, and the workflow he started - describe the hardware,
    compile it, load the bitstream - is still exactly what you will do in this book, except now on a board
    that costs less than a good dinner and with a toolchain that is entirely open source. That is what I set
    out to build: an affordable FPGA board, and a kit of genuinely useful PMODs to plug into it.
  </p>
  <p>
    <strong>The Humble iCE Cookbook</strong> is the third piece - a collection of practical FPGA projects built around 
    Humble iCE - a Lattice Semiconductor iCE40UP5K FPGA based development board with a built-in USB programmer.
    Each chapter takes a real project from idea to working hardware. You write the Verilog code,
    simulate it, synthesize a bitstream, and finally flash it on to the board.
  </p>
  <p>
    Along the way you will pick up the <m>digital design</m> fundamentals you need: logic, state machines,
    timing, and the Verilog HDL. You need only a basic knowledge of programming and electronics to 
    follow along. 
  </p>
  <p>
    Happy hacking with FPGAs!
  </p>
</div>

<h2 class="book-home__chapters-heading">Table of Contents</h2>

<ol class="book-home__chapter-list">
  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch01-specifications/">Humble iCE Specifications</a></strong><br>
    Board overview, iCE40UP5K resources, RP2040 programmer, PMOD connectors, power supply, and schematic walkthrough.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch02-getting-started/">Getting Started with Humble iCE</a></strong><br>
    Install the open-source iCE40 toolchain on Windows, macOS, or Linux, then build, simulate, and flash your first Verilog designs — a blinking LED and an RGB blinky.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch03-digital-design-with-verilog/">A Crash Course in Digital Design with Verilog HDL</a></strong><br>
    Gates, behavioral design, building blocks (MUX, encoder, shift register, counter), ASM/ASMD state machines, and a complete datapath+controller example — all with testbenches and synthesis.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch04-fpga-architecture/">FPGA Architecture</a></strong><br>
    Inside the iCE40UP5K: Look-Up Tables, flip-flops, BRAM, SPRAM, DSP blocks, PLLs, I/O pins, and the programmable routing fabric.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch05-uart-tx/">Project: UART Transmitter</a></strong><br>
    Build a UART TX in Verilog — baud rate generation with a fractional accumulator, a partitioned controller-datapath state machine, simulation with GTKWave, and synthesis onto the iCE40.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch06-7seg-pmod/">Project: 4×7-Segment PMOD</a></strong><br>
    Drive a 4-digit 7-segment display PMOD — multiplexed scanning, BCD decoding, and a counter demo.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch07-vga-pmod/">Project: VGA PMOD</a></strong><br>
    Generate a VGA signal using our VGA PMOD — sync timing, pixel clock via PLL, and a colour test pattern.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch08-i2s-mic/">Project: I2S Microphone PMOD</a></strong><br>
    Capture audio from an I2S MEMS microphone using our PMOD and stream samples over UART.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch09-pdm-mic/">Project: PDM Microphone PMOD</a></strong><br>
    Capture audio from a PDM MEMS microphone using our PMOD, implement a CIC decimation filter, and stream PCM samples over UART.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch10-hm01b0-camera/">Project: HM01B0 Camera PMOD</a></strong><br>
    Capture QVGA grayscale images from an HM01B0 camera using our PMOD and stream frames to a host PC.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch11-usb-audio/">Project: 2-Channel USB Audio Out</a></strong><br>
    Combine I2S and PDM microphone PMODs with a USB-C PMOD to stream 2-channel audio to a host PC using soft IP.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch12-sn76489/">Project: Replicating the SN76489 Sound Generator</a></strong><br>
    Replicate the classic TI SN76489 PSG in Verilog — three square-wave tone channels, a 15-bit noise LFSR, a DAC attenuation ROM, and signed PCM output streamed to a GY-PCM5102 I2S DAC.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch13-systolic-array/">Project: Systolic Array Matrix Multiplier</a></strong><br>
    Build a 4×4 systolic array in Verilog that computes C = A × B for 8-bit integer matrices — the same dataflow used in Google's TPU — and verify it completes in 10 clock cycles on the iCE40UP5K.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/changelog/">Changelog</a></strong><br>
    A running log of additions, corrections, and updates to the book.</div>
  </li>

</ol>
