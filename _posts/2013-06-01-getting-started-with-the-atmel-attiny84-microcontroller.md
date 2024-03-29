---
layout: post
title: Getting Started with the Atmel ATtiny84 Microcontroller
excerpt: Getting Started with the Atmel ATtiny84 Microcontroller
date: 2013-06-01 09:20:51.000000000 +05:30
categories:
- AVR Programming
tags:
- ATtiny
- ATtiny84
- AVR
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
image:
  feature: header.jpg

modified: 2013-06-01

thumbnail: images/2013/05/IMG_1478-tn.jpg
---
<p style="padding: 20px;"
<img src="{{ site.baseurl }}/images/2013/05/IMG_1478.jpg"/>
</p>
<p>Like many folks, I got introduced to microcontrollers through the Arduino platform. The ease of setup, simple language syntax and the availability of a huge number libraries makes Arduino a very attractive choice to prototype your hardware projects. But after you get a grip on your project, sometimes it's worth asking if you really need the power and the prototyping ergonomics of an Arduino, especially if all you are doing is reading a few sensors and turning on a few LEDs. </p>
<p>Atmel has a line of microcontrollers called <a href="http://www.atmel.in/products/microcontrollers/avr/tinyavr.aspx">tinyAVR</a> which are little microcontrollers which can do a lot of the work that an Arduino does in a much more compact form. Take a look at <a href="http://en.wikipedia.org/wiki/Atmel_AVR_ATtiny_comparison_chart">the wikipedia page that compares the capabilities of the tinyAVRs</a>.</p>
<p><!--more--></p>
<p>In this post, I'll be setting up to program an Atmel ATtiny84, a chip that I will be using for most of my ATtiny projects. I picked this 14-pin chip rather than the very popular 8-pin ATtiny85 because the former has a few more I/O pins which could come in handy for many projects. Here is a pin comparison between these 2 chips.</p>
<br/>
<p>[From Atmel datasheets, for illustrative purpose.]<br />
<img src ="{{ site.baseurl }}/images/2013/05/84-85-comparison.png"/></p>

<p>I will be programming the ATtiny85 in C, using the free AVR-GCC and AVRDUDE tools. Windows users please read the <a href="http://www.ladyada.net/learn/avr/setup-win.html">Adafruit guide to set up the AVR tools</a>. Mac users (like me, for instance) can use the free <a href="http://www.obdev.at/products/crosspack/index.html">CrossPack suite</a> for AVR programming.</p>
<p>Next, you need a programmer. I recommend the <a href="https://www.sparkfun.com/products/9825">Sparkfun Pocket AVR programmer</a>, which I use. </p>
<p>The setup is really simple - just connect the VCC, MISO, MOSI, SCK, RESET, and GND pins from the chip to the same pins on the programmer. The ugly looking small PCB you see below is my homemade version of the <a href="https://www.sparkfun.com/products/8508">Sparkfun AVR programming adapter</a> - not a requirement, it just makes it convenient to connect the 6-pin plug easily to a breadboard.</p>
<p>Note that you need not connect the VCC pin to the programmer, if you are powering the circuit yourself. There is a small switch on the programmer in case you decide to go that route. </p>
<p>Here is my programming setup:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1477.jpg"/></p>
<p>Once you program the chip, you don't need the programmer, and here you can see the chip working directly from the 3V battery:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1478.jpg"/></p>
<p>Here is the source code - very simple:</p>
<p><script src="https://gist.github.com/electronut/5689130.js"></script></p>
<p>Here is the Makefile:</p>
<p><script src="https://gist.github.com/electronut/5689137.js"></script></p>
<p>To upload the program to your chip, connect the programmer to the USB port of your computer, and run 'make install' in a shell in the relevant project directory. If all goes well, you will see a happy blinking LED. </p>
<p>So now you know how to program an ATtiny84. But to really understand the chip, you have to read the Atmel datasheet (just search for 'ATtiny84 datasheet' on the net) - there is no way around it. It's complex and can seem incomprehensible in the beginning, but do persist, and in the end, I assure you that it will be much more rewarding than blindly using libraries that someone else wrote.</p>
<p>Good luck to you in starting out with the tinyAVRs, and watch <a href="http://electronut.in/">electronut.in</a> for upcoming projects that use these chips.</p>
