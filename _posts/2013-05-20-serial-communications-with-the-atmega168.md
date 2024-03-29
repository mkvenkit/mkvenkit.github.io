---
layout: post
title: Serial Communications with the ATmega168
excerpt: Serial Communications with the ATmega168
date: 2013-05-20 10:33:28.000000000 +05:30
categories:
- Circuits
tags:
- ATmega168
- debugging
- Serial Communication
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
  _thumbnail_id: '131'
  _cc_post_template_type: img-left-content-right

modified: 2013-05-20

thumbnail: images/2013/05/IMG_1412-tn.jpg
---
<p>The first thing you do when you learn a new programming language or platform is to write a "hello world" application. This requires something like a "printf" function. That's not so straightforward when it comes to microcontrollers - where will the output of the "printf" go? That's where serial communications come in. Arduino users have it easy - they just need to use Serial.print(). But the situation is not so bad if you are using a standalone microcontroller - just choose a chip like ATmega168 which has <a href="http://en.wikipedia.org/wiki/Universal_asynchronous_receiver/transmitter">USART </a>- hardware support for serial communications.</p>
<p>The code needed to transmit serial data is very simple, and the datasheet has most of what you need:</p>
<p><script src="https://gist.github.com/electronut/5610483.js"></script></p>
<p>Here is the schematic of a simple setup that will let you send debug data (strings) from an ATmega168 to your computer. If you are completely new to AVR programming, I recommend that you read <a href="http://hackaday.com/2010/10/23/avr-programming-introduction/">Hackaday's tutorial</a> on the subject. Note how the TX/RX lines are flipped when you connect it from the ATmega168 to the FTDI adapter.</p>
<p>A few things to remember in order to for this to work correctly (the Makefile in the GitHub link below takes care of all this):</p>
<ul>
<li>For getting a 9600 baud rate, the chip needs to run at 8 MHz, and for this, you need to unset the  CKDIV8 fuse.</li>
<li>For full sprintf formatting support, some additional flags are needed in the linker.</li>
</ul>
<p>&nbsp;</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1412.jpg"/></p>
<div title="Page 199">
<div>
<div>
<p>&nbsp;</p>
<p>Here is a photo of the setup that I used:</p>
<p>&nbsp;</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1411.jpg"/></p>
</div>
</div>
</div>
<p>&nbsp;</p>
<p>Here is what the output looks like on CoolTerm, a serial monitor that I use on my Mac:</p>
<p>&nbsp;</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/coolterm.png"/></p>
<p>&nbsp;</p>
<p>Having a "printf" function is very handy for debugging your projects - so choose a chip that will let you support this functionality without too much pain.</p>
<h2>Downloads</h2>
<p>Here is all the code used in this project - do pay attention to the flags in the Makefile.</p>
<p><a href="https://github.com/electronut/atmega168-serial-hello">https://github.com/electronut/atmega168-serial-hello</a></p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
