---
layout: post
title: Raspberry Pi I2C communications with CAT9532 16-bit Programmable LED Dimmer
excerpt: Raspberry Pi I2C communications with CAT9532 16-bit Programmable LED Dimmer
date: 2013-06-29 20:48:38.000000000 +05:30
categories:
- Python
- Raspberry Pi
tags:
- CAT9532
- I2C
- LED dimmer
- PWM
- Python
- Raspberry Pi
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

modified: 2013-06-29

thumbnail: images/2013/06/IMG_1613-tn.jpg
---
<p><iframe width="560" height="315" src="//www.youtube.com/embed/7vckzlMZZq4?rel=0" frameborder="0" allowfullscreen></iframe></p>
<p>I have a couple of servos on a pan/tilt bracket that I want to control from my Raspberry Pi. As I started looking at options, I read about the <a href="http://www.adafruit.com/products/815">Adafruit 16-channel servo driver</a>. This board is not available where I live, and I got curious about chips that generate PWM signals that could be configured via the I2C protocol. I found a cheap one (less than 2 USD) on element14 - the <a href="http://www.onsemi.com/PowerSolutions/product.do?id=CAT9532">CAT9532 16-bit Programmable LED Dimmer chip</a> from Catalyst Semiconductor.</p>
<p>This is a short post on communicating with the CAT9532 from a Raspberry Pi using Python and the <strong>smbus</strong> module. </p>
<p><!--more--></p>
<p>I won't go into I2C - this is a very popular protocol, and you can read this <a href="http://tronixstuff.wordpress.com/2010/10/20/tutorial-arduino-and-the-i2c-bus/">excellent introduction here</a>.</p>
<p><a href="http://en.wikipedia.org/wiki/System_Management_Bus">smbus</a> is the module used on Raspberry Pi to communicate with I2C devices. If you are used to sending I2C commands like START/STOP/RESTART etc., you will find smbus to be very frustrating (like I did). The commands are at a higher level, and <a href="https://www.kernel.org/doc/Documentation/i2c/smbus-protocol">a typical I2C sequence is "baked in"</a>, which may or may not suite you. One particular known problem with smbus on Raspberry Pi is that it cannot send a "REPEATED START" I2C command - what this means is that you cannot communicate with popular accelerometer chips like Freescale MMA8452 which require a REPEATED START to read back data from its registers. I burned my fingers on this, trying it with another accelerometer chip, the Freescale MMA7660. You can read more about this issue <a href="http://www.raspberrypi.org/phpBB3/viewtopic.php?t=17738&p=362569">here</a>, for instance. The suggested workaround is to use software I2C (bit-banging).</p>
<p>But luckily, the CAT9532 does not use a REPEATED START, which means we can use Python + smbus to communicate with it. </p>
<p>Looking at the datasheet, the CAT9532 has 10 registers, 2 read-only and 9 read/write, which can be used to set the frequency, duty cycle, and on/off state of 16 LED pins. The base address of the chip is 0x60, but you can use 3 more pins (3 more bits) to modify it.</p>
<p>This is what the chip looks like in its SOIC-24 package. I used a DIP adapter PCB so I could use it on a breadboard.</p>
<p style="padding: 10px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1600.jpg"/>
</p>
<p>My goals here are:</p>
<ol>
<li>
Make LED 8 (green) blink at 3 Hz, at 50% duty cycle.
</li>
<li>
Make LED 7 (blue) "pulse" - going from off to on and back to off slowly.
</li>
</ol>
<p>This is how I connected the hardware:</p>
<ol>
<li>
A0, A1 and A2 pins (configurable part of device I2C address) are all connected to GND, as is pin VSS.
</li>
<li>
Pull-up resistors of 4.7k for SDA, SCL and RESET pins of CAT9532 to +3.3V GPIO pin on Pi.
</li>
<li>
Connect SDA/SCL from Pi to that of CAT9532.
</li>
<li>
LED7 pin to 270 ohms to Blue LED(-), LED(+) to +5V on Pi.
</li>
<li>
LED8 pin to 270 ohms to Green LED(-), LED(+) to +5V on Pi.
</li>
</ol>
<p>This is what the full setup looks like:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1613.jpg"/>
</p>
<p>The full Python source is below. Run it from the Pi as:</p>
<p><code>sudo python rpi-cat9532.py<br />
</code></p>
<p><script src="https://gist.github.com/electronut/5890752.js"></script></p>
<p>Now that I understand how to set the PWM frequency and duty cycle via I2C, I'll need to figure out how to drive servos with this output - probably use some MOSFETs. But that's for another post.</p>
