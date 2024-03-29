---
layout: post
title: Serial Communications with the ATtiny84
excerpt: Serial Communications with the ATtiny84
date: 2013-06-04 07:54:16.000000000 +05:30
categories:
- AVR Programming
tags:
- ATtiny84
- AVR
- Serial Communications
- tinyAVR
status: publish
type: post
published: true
comments: true
meta:
  _cc_post_template_date: '0'
  _cc_post_template_avatar: '0'
  _cc_post_template_on: '0'
  _cc_page_slider_caption: '0'
  _cc_page_template_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_slider_cat: a:0:{}
  _cc_page_slider_on: '0'
  _cc_post_template_tags: '0'
  _cc_post_template_comments_info: '0'
  _edit_last: '5'
  _cc_post_template_type: img-left-content-right
  _wpas_done_all: '1'

modified: 2013-06-04

thumbnail: images/2013/06/IMG_1499-tn.jpg
---
<p style="padding: 20px;">
<a href="{{site.baseurl }}/images/2013/06/IMG_1496.jpg"/>
</p>
<p>In a previous post, I talked about <a href="http://electronut.in/serial-communications-with-the-atmega168/" title="Serial Communications with the ATmega168">serial communications with an ATmega168</a>. But that chip has USART - hardware support for serial communications. But what about the tinyAVRs? As continuation of <a href="http://electronut.in/getting-started-with-the-atmel-attiny84-microcontroller/" title="Getting Started with the Atmel ATtiny84 Microcontroller">my last post on setting up the ATtiny84 for programming</a>, this time, I will talk about sending data from an ATtiny84 to a computer using serial communications. </p>
<p><!--more--></p>
<p>First, I recommend that you watch this fun and informative video on serial communications by Pete from Sparkfun, USA:</p>
<p><iframe width="560" height="315" src="http://www.youtube.com/embed/JJZOTtwpAjA?rel=0" frameborder="0" allowfullscreen></iframe></p>
<p>So, now that we have some idea about serial communications, let's talk about implementing a transmit only (TX) for the ATtiny84. Here is our scheme:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1499.jpg"/></p>
<p>The above image shows the transmission of a byte (with value 0x95). The value is sent one bit at a time, starting with the least significant bit (LSB), every 1/9600 seconds, thus giving us a baud rate of 9600. The data format for a packet for the 9600 baud <a href="http://en.wikipedia.org/wiki/8-N-1">8-N-1 serial connection</a> is as follows:</p>
<p><code>start(low)-[0]-[1]-[2]-[3]-[4]-[5]-[6]-[7]-stop(high)-idle(high)-idle(high)</code></p>
<p>(In the above, the 2 idle bits at the end are not strictly necessary.)</p>
<p>So how do we implement sending a bit every 1/9600 seconds? For this, we use the 16-bit timer (Timer1) of the Attiny84 in CTC mode. The value for the top of the counter is calculated as shown in the image above. </p>
<p>In the <a href="http://en.wikipedia.org/wiki/Interrupt_handler">ISR</a> for the timer, we keep track of the current data byte and the current bit being sent, and keep setting the output pin high/low as appropriate.</p>
<p>Here is the code that implements the above ideas.</p>
<p><script src="https://gist.github.com/electronut/5697636.js"></script></p>
<p>The Makefile is the same as we used in the <a href="http://electronut.in/getting-started-with-the-atmel-attiny84-microcontroller/" title="Getting Started with the Atmel ATtiny84 Microcontroller">ATtiny84 introduction</a> post:</p>
<p><a href="https://gist.github.com/electronut/5689137">https://gist.github.com/electronut/5689137</a></p>
<p>This is the schematic for wiring it up:</p>

<p style="padding: 20px;">
<img src="{{ site.baseurl}}/images/2013/06/IMG_1499-2.jpg"/></p>
<p>Here is what the breadboard setup looks like:</p>

<p style="padding: 20px;">
<img src="{{ site.baseurl}}/images/2013/06/IMG_1496.jpg"/></p>
<p>And here is the output from CoolTerm. It was surprisingly easy to get this working. ;-)</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/attiny84-coolterm.png"/>
</p>
<p><strong>Note:</strong></p>
<p>On OS X, you can use the <strong>screen</strong> command to see the serial output. For example:</p>
<p><code>$ screen /dev/tty.usbserial-A7006Yqh 9600<br />
</code></p>
