---
layout: book
title: "The Humble iCE Cookbook"
description: "A hands-on beginner's guide to Digital Design with FPGAs."
featured_image: /images/humble-ice.jpg
---

<div class="book-home__cover">
  <img src="/images/fpga-beginners-cover-small.jpg" alt="The Humble iCE Cookbook cover">
</div>

<div class="book-home__intro">
  <p>
    <strong>The Humble iCE Cookbook</strong> is a collection of practical FPGA projects built around 
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

<h2 class="book-home__chapters-heading">Chapters</h2>

<ol class="book-home__chapter-list">

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch01-introduction/">Getting Started with Humble iCE</a></strong><br>
    Install the open-source iCE40 toolchain on Windows, macOS, or Linux, then build, simulate, and flash your first Verilog design — a blinking LED.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch02-digital-design-with-verilog/">Digital Design with Verilog HDL</a></strong><br>
    Gates, behavioral design, building blocks (MUX, encoder, shift register, counter), ASM/ASMD state machines, and a complete datapath+controller example — all with testbenches and synthesis.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Digital Logic Basics</strong><br>
    Logic gates, Boolean algebra, truth tables, and the combinational circuits that form an FPGA's building blocks.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>FPGA Architecture</strong><br>
    Inside an FPGA: Look-Up Tables, flip-flops, configurable logic blocks, I/O pins, and the routing fabric.</div>
  </li>

  <li class="book-home__chapter-item">
    <div><strong><a href="/begin-fpga/ch05-uart-tx/">UART Transmitter</a></strong><br>
    Build a UART TX in Verilog — baud rate generation with a fractional accumulator, a partitioned controller-datapath state machine, simulation with GTKWave, and synthesis onto the iCE40.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Introduction to HDL</strong><br>
    Hardware Description Languages — Verilog and VHDL — and how hardware design differs from software programming.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Verilog Basics</strong><br>
    Modules, ports, wire vs reg, always blocks, and your first Verilog design.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Simulation and Testbenches</strong><br>
    Writing testbenches, running simulations with Icarus Verilog, and viewing waveforms in GTKWave.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Synthesis and Implementation</strong><br>
    Turning HDL into a bitstream: synthesis, place-and-route, timing analysis, and programming the FPGA.</div>
  </li>

  <li class="book-home__chapter-item book-home__chapter-item--soon">
    <div><strong>Your First FPGA Project</strong><br>
    A complete worked example: blinking LEDs, a 7-segment display driver, and a simple state machine.</div>
  </li>

</ol>
