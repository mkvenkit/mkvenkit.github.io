---
title: Humble iCE
subtitle: FPGA Development Board by Electronut Labs
description: Humble iCE is a cost-optimized FPGA development board based on the Lattice iCE40UP5k chip, designed to make FPGA education more accessible.
featured_image: /images/embedded/hi1.jpg
permalink: /fpga
---

<style>
  .humble-ice-page {
    max-width: 860px;
    margin: 0 auto;
  }

  .humble-ice-hero-img {
    width: 100%;
    height: auto;
    display: block;
    margin-bottom: 32px;
    border-radius: 4px;
    box-shadow: 0 10px 24px rgba(0,0,0,0.08);
  }

  .humble-ice-specs {
    display: grid;
    gap: 12px;
    margin: 32px 0;
    padding: 24px;
    background: #f9f9f9;
    border-left: 4px solid #e8e8e8;
  }

  .humble-ice-specs h3 {
    margin: 0 0 8px;
    font-size: 1em;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #6C7A89;
  }

  .humble-ice-specs ul {
    margin: 0;
    padding-left: 20px;
  }

  .humble-ice-specs ul li {
    margin-bottom: 6px;
  }

  .humble-ice-cta {
    margin-top: 40px;
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
  }

  .status-badge {
    display: inline-block;
    padding: 4px 12px;
    background: #fff3cd;
    border: 1px solid #ffc107;
    border-radius: 3px;
    font-size: 0.85em;
    color: #856404;
    margin-bottom: 24px;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }
</style>

<div class="humble-ice-page">

  <img src="/images/embedded/hi1.jpg" alt="Humble iCE FPGA board" class="humble-ice-hero-img">

  <span class="status-badge">Coming Soon</span>

  <p>
    <strong>Humble iCE</strong> is a cost-optimized FPGA development board based on the <strong>Lattice iCE40UP5k</strong> chip, designed to make FPGA education more accessible. It pairs the FPGA with an <strong>RP2040</strong> microcontroller for programming and USB communication, so you don't need a separate programmer.
  </p>

  <p>
    The board is designed with beginners in mind: simple toolchain, open source bitstream support via <a href="https://github.com/YosysHQ/yosys" target="_blank" rel="noopener">Yosys</a> / <a href="https://github.com/YosysHQ/nextpnr" target="_blank" rel="noopener">nextpnr</a> / <a href="https://github.com/YosysHQ/icestorm" target="_blank" rel="noopener">IceStorm</a>, and enough I/O to learn real digital design.
  </p>

  <div class="humble-ice-specs">
    <h3>Key Features</h3>
    <ul>
      <li>Lattice iCE40UP5k FPGA — 5280 LUTs, 30 DSPs, 1Mb SPRAM</li>
      <li>Raspberry Pi RP2040 for USB programming and UART bridge</li>
      <li>USB-C connector</li>
      <li>Open source toolchain compatible (Yosys / nextpnr / IceStorm)</li>
      <li>Compact, breadboard-friendly form factor</li>
      <li>Designed for FPGA education and experimentation</li>
    </ul>
  </div>

  <p>
    This page will be updated with full documentation, pinouts, examples, and purchase links as the board approaches release. Follow <a href="https://twitter.com/mkvenkit" target="_blank" rel="noopener">@mkvenkit</a> for updates.
  </p>

  <div class="humble-ice-cta">
    <a href="https://twitter.com/mkvenkit" class="button button--large" target="_blank" rel="noopener noreferrer">Follow for Updates</a>
    <a href="/products/" class="button button--large">All Products</a>
  </div>

</div>
