---
layout: post
title: Designing an Op-Amp Circuit to Detect LDR Pulses
excerpt: Designing an Op-Amp Circuit to Detect LDR Pulses
date: 2013-07-11 21:11:35.000000000 +05:30
categories:
- Circuits
tags:
- comparator
- data slicer
- differentiator
- LDR
- op-amp
status: publish
type: post
published: true
comments: true
meta:
  _cc_page_slider_on: '0'
  _cc_page_slider_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_template_cat: a:0:{}
  _cc_page_slider_caption: '0'
  _cc_post_template_on: '0'
  _cc_post_template_avatar: '0'
  _cc_post_template_date: '0'
  _cc_post_template_tags: '0'
  _cc_post_template_comments_info: '0'
  _edit_last: '5'
  _cc_post_template_type: img-left-content-right
  _wpas_done_all: '1'

modified: 2014-07-11

thumbnail: images/2013/07/IMG_1651-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1651.jpg"/>
</p>
<h3>The Problem</h3>
<p>I wanted to design a circuit to generate a nice digital pulse (for input to a microcontroller or the Raspberry Pi) every time an LDR is quickly obscured from ambient light - like for instance, when you pass your hand over it. I didn't want to use the popular solution of reading the analog values, and processing it on the microcontroller (averaging, finding peaks, etc.), because this will take up valuable processing time, and I want to avoid lag as much as possible, by offloading this work to hardware.</p>
<p>So here are 3 attempts that I made, and the results.</p>
<p><!--more--></p>
<h3>Attempt #1: Use a Differentiator</h3>
<p>When you pass your hand over an LDR (connected in the form of a resistor divider circuit), you get a signal with a little dip in it. To convert this signal to a peak, you can use the derivative. So my first attempt was to use an op-amp differentiator from Scherz's book [1]. </p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1648.jpg"/>
</p>
<p>Here is what the output signals look like on an oscilloscope: </p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1645.jpg"/>
</p>
<p>So it works, we have a peak, but it's a low voltage signal, and in any case, it's not the clean digital signal I am looking for. Hence...</p>
<h3>Attempt #2: Use a Differentiator + Comparator</h3>
<p>If I feed the output of the circuit #1 to a comparator, it will swing to high when the differentiator outputs a peak.To avoid small noise triggering it, I am using a 1:100 resistor divider on the V- pin.</p>
<p>So here's the modified circuit:</p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1654.jpg" />
</p>

<p>Now here's what the signals look like on a scope:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1649.jpg"/>
</p>
<p>Now that's much better. This actually works very well - I am able to get this into the Raspberry Pi GPIO pins as a "rising" signal. (If you use it with the Pi, make sure you use a 3.3V supply and not a 5V supply to the op-amp - else you might damage your Pi.)</p>
<p>But apparently there is a better way of doing this...</p>
<h3>Attempt #3: A "Data Slicer"</h3>
<p>As expected, posting this on StackExchange [2] resulted in a more elegant solution which uses lesser number of components - a single op-amp, in fact. The idea is to use a "Data Slicer" op-amp circuit [3], in which the op-amp inputs are the signal (-) and the same signal with a low-pass filter (+), with a cut off around 1.6 Hz. The op-amp is wired as a comparator, which goes high whenever there is a difference in the inputs, which will happen when there is a dip in the LDR signal. The 1M pot is used to bias the default output to low when there is some noise.</p>
<p>Here is the circuit:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1655.jpg"/>
</p>
<p>And here is the output:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/IMG_1651.jpg" />
</p>
<p>Fantastic! I guess you (can) learn something new every day. ;-)</p>
<h3>References</h3>
<ol>
<li>
<em>Practical Electronics for Inventors, 4th Ed</em> by Paul Scherz & Simon Monk.
</li>
<li>
<a href="http://electronics.stackexchange.com/questions/75512/designing-an-op-amp-circuit-to-generate-a-digital-pulse-from-ldr">My post on this topic</a> at StackExchange/Electronics.
</li>
<li>
"Data Slicer" section in Microchip document titled "PIC® MCU Comparator Tips ‘n Tricks".
</li>
</ol>
