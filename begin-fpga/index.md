---
layout: book
title: "FPGA for Beginners"
description: "A hands-on introduction to Field-Programmable Gate Arrays — from digital logic fundamentals to writing your first Verilog design."
featured_image: /images/humble-ice.jpg
---

<style>
.book-index-intro {
  font-size: 16px;
  line-height: 1.8;
  color: #6C7A89;
  margin-bottom: 40px;
}

.book-index-grid {
  display: grid;
  gap: 16px;
  margin-top: 8px;
}

@media (min-width: 640px) {
  .book-index-grid {
    grid-template-columns: 1fr 1fr;
  }
}

.book-index-card {
  display: block;
  padding: 20px 22px;
  border: 1px solid #dddddd;
  border-radius: 6px;
  text-decoration: none;
  background: #ffffff;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
}

.book-index-card:hover {
  border-color: #3498db;
  box-shadow: 0 4px 16px rgba(52,152,219,0.10);
}

.book-index-card--soon {
  opacity: 0.5;
  pointer-events: none;
  cursor: default;
}

.book-index-card__num {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #3498db;
  margin-bottom: 6px;
}

.book-index-card--soon .book-index-card__num {
  color: #ABB7B7;
}

.book-index-card__title {
  font-size: 15px;
  font-weight: 700;
  color: #2A2F36;
  margin-bottom: 6px;
  line-height: 1.3;
}

.book-index-card__desc {
  font-size: 13px;
  color: #6C7A89;
  line-height: 1.5;
  margin: 0;
}

.book-index-card__badge {
  display: inline-block;
  margin-top: 10px;
  padding: 2px 7px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  background: #f4f5f6;
  color: #ABB7B7;
  border-radius: 3px;
}
</style>

<p class="book-index-intro">
  <strong>FPGA for Beginners</strong> takes you from zero to writing and synthesizing your first hardware design. 
  No prior hardware experience required — just curiosity and a willingness to think differently about how computation works.
  Each chapter builds on the last, mixing concepts with practical exercises you can run on a real FPGA board or a free simulator.
</p>

<div class="book-index-grid">

  <a href="/begin-fpga/ch01-introduction/" class="book-index-card">
    <p class="book-index-card__num">Chapter 1</p>
    <p class="book-index-card__title">Introduction to FPGAs</p>
    <p class="book-index-card__desc">What is an FPGA, how it compares to CPUs and microcontrollers, and why you'd choose one.</p>
  </a>

  <a href="/begin-fpga/ch02-digital-logic-basics/" class="book-index-card">
    <p class="book-index-card__num">Chapter 2</p>
    <p class="book-index-card__title">Digital Logic Basics</p>
    <p class="book-index-card__desc">Logic gates, Boolean algebra, truth tables, and the combinational circuits that form an FPGA's building blocks.</p>
  </a>

  <a href="/begin-fpga/ch03-fpga-architecture/" class="book-index-card">
    <p class="book-index-card__num">Chapter 3</p>
    <p class="book-index-card__title">FPGA Architecture</p>
    <p class="book-index-card__desc">Inside an FPGA: Look-Up Tables, flip-flops, configurable logic blocks, I/O pins, and the routing fabric.</p>
  </a>

  <span class="book-index-card book-index-card--soon">
    <p class="book-index-card__num">Chapter 4</p>
    <p class="book-index-card__title">Introduction to HDL</p>
    <p class="book-index-card__desc">Hardware Description Languages — Verilog and VHDL — and how hardware design differs from software programming.</p>
    <span class="book-index-card__badge">Coming Soon</span>
  </span>

  <span class="book-index-card book-index-card--soon">
    <p class="book-index-card__num">Chapter 5</p>
    <p class="book-index-card__title">Verilog Basics</p>
    <p class="book-index-card__desc">Modules, ports, wire vs reg, always blocks, and your first Verilog design.</p>
    <span class="book-index-card__badge">Coming Soon</span>
  </span>

  <span class="book-index-card book-index-card--soon">
    <p class="book-index-card__num">Chapter 6</p>
    <p class="book-index-card__title">Simulation and Testbenches</p>
    <p class="book-index-card__desc">Writing testbenches, running simulations with Icarus Verilog, and viewing waveforms in GTKWave.</p>
    <span class="book-index-card__badge">Coming Soon</span>
  </span>

  <span class="book-index-card book-index-card--soon">
    <p class="book-index-card__num">Chapter 7</p>
    <p class="book-index-card__title">Synthesis and Implementation</p>
    <p class="book-index-card__desc">Turning HDL into a bitstream: synthesis, place-and-route, timing analysis, and programming the FPGA.</p>
    <span class="book-index-card__badge">Coming Soon</span>
  </span>

  <span class="book-index-card book-index-card--soon">
    <p class="book-index-card__num">Chapter 8</p>
    <p class="book-index-card__title">Your First FPGA Project</p>
    <p class="book-index-card__desc">A complete worked example: blinking LEDs, a 7-segment display driver, and a simple state machine.</p>
    <span class="book-index-card__badge">Coming Soon</span>
  </span>

</div>
