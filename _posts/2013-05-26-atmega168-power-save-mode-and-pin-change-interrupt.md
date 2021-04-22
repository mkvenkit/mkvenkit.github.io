---
layout: post
title: ATmega168 Power Save Mode and Pin Change Interrupt
excerpt: ATmega168 Power Save Mode and Pin Change Interrupt
date: 2013-05-26 08:53:11.000000000 +05:30
categories:
- AVR Programming
tags:
- 16-bit timer
- ATmega168
- Atmel
- AVR
- comparator
- LM358
- op-amp
- pin change interrupt
- power-save
- sleep mode
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
  _thumbnail_id: '271'
  _wpas_done_all: '1'
image:
  feature: header.jpg
---
<p>Most times your microcontroller is running in a loop, waiting for something to happen - like a button press. All this while it is consuming power, and this could be an issue, especially if you are running the circuit from a battery. To counter this problem, there are ways of reducing the power consumption of your chip. Here are the various "sleep modes" supported by the ATmega168. </p>
<p>[Table reproduced from Atmel ATmega168 datasheet for illustrative purpose]</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/ATmega168-sleep-modes.png"/></p>
<p>In a previous post about an <a href="http://electronut.in/ambient-light-sensor-using-an-op-amp-comparator/">Ambient Light sensor using an Op-Amp Comparator</a>, I mentioned that we would be using the op-amp output to "wake up" an ATmega168. So here, we will be using the "power-save" mode from the above table, and use a pin-change interrupt to wake up from this sleep mode.</p>
<p>The setup used is shown below in the 2 schematics I had posted before. The output Vo from the op-amp should be connected to the pin 14 of the ATmega168 (PCINT0/PB0). Also, in this case, we are not using serial output, so you can remove the connections to the FTDI adapter. </p>
<p><!-- insert table here--></p>
<img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1415.jpg"/>
<br/>
<img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1412.jpg"/>
<br/>
<p><!-- end table here--></p>
<p>Here is what the circuit looks like, hooked up on a breadboard:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1451.jpg"/></p>
<p>This is the how the program works:</p>
<p><!-- begin list --></p>
<ul>
<li>
When the program starts, start the 16-bit timer, set to fire an interrupt every 3 seconds. Start the timer only if pin 14 is low. (This means that the light level is high in our sensor circuit.).
</li>
<li>
When the chip is not sleeping, it will be flashing an LED attached to pin 6.
</li>
<li>
When the 16-bit timer interrupt happens, set a flag (a <a href="http://en.wikipedia.org/wiki/Volatile_variable">volatile variable</a>) so that the main loop reads this flag and puts the chip to sleep mode. It will also turn the LED off at this point.
</li>
<li>
Set up a pin change interrupt on PCINT0 for any logical change in input. When the interrupt fires, if it was caused by a rising edge (ie., light to dark), wake up the chip, and stop the 16-bit timer. If the interrupt was caused by a falling edge (ie., dark to light), re-start the 16-bit timer.
</li>
</ul>
<p><!-- end list --></p>
<p>You can read about pin-change interrupts and the 16-bit timer in the Atmel ATmega168 datasheet.</p>
<p>The complete code listing is below. The opening comments in the code also have all the required build commands.</p>
<p><script src="https://gist.github.com/electronut/5648690.js"></script></p>
