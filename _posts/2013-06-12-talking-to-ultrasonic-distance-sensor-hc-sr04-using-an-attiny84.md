---
layout: post
title: Talking to Ultrasonic Distance Sensor HC-SR04 using an ATtiny84
excerpt: Talking to Ultrasonic Distance Sensor HC-SR04 using an ATtiny84
date: 2013-06-12 17:11:30.000000000 +05:30
categories:
- AVR Programming
- Python
tags:
- ATtiny84
- AVR
- HC-SR04
- sensor
- Serial Communications
- tinyAVR
- ultrasonic
status: publish
type: post
published: true
comments: true
meta:
  _cc_page_slider_on: '0'
  _cc_post_template_type: img-left-content-right
  _edit_last: '5'
  _cc_post_template_comments_info: '0'
  _cc_post_template_tags: '0'
  _cc_post_template_date: '0'
  _cc_post_template_avatar: '0'
  _cc_post_template_on: '0'
  _cc_page_slider_caption: '0'
  _cc_page_template_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_slider_cat: a:0:{}
  _wpas_done_all: '1'
image:
  feature: header.jpg

modified: 2013-06-12

thumbnail: /images/2013/06/IMG_1503-tn.jpg
---

<iframe width="560" height="315" src="https://www.youtube.com/embed/sDbGe3rc61Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

<p><!--more--></p>
<p>The HC-SR04 works as follows:</p>
<ul>
<li>
Send a 10us HIGH pulse on the Trigger pin.
</li>
<li>
The sensor sends out a “sonic burst” of 8 cycles.
</li>
<li>
Listen to the Echo pin, and the duration of the next HIGH signal will give you the time taken by the sound to go back and forth from sensor to target.
</li>
</ul>
<p>Here, the PB0 pin is used to send out the 10 us pulse. To measure the width of the echo pulse, we can use a pin-change interrupt and a timer. Here is the idea:</p>
<ul>
<li>
Setup pin change interrupt PCINT0 so that any logical change on pin will cause an interrupt.
</li>
<li>
Send a 10 us pulse to the trigger pin.
</li>
<li>
Loop till the PCINT0 interrupt sets a flag to indicate that measurement is done.
</li>
<li>
In the PCINT0 interrupt, start an 8-bit timer when you see a rising edge - ie., the echo pulse has gone from low to high. The 8-bit timer is setup to use the overflow interrupt.
</li>
<li>
The 8-bit counter overflows every time it reaches 255, and so when that interrupt fires, we add 255 to a running 32-bit counter value.
</li>
<li>
In the PCINT0 interrupt, stop 8-bit timer when you see a falling edge - ie., the echo pulse has gone from high to low. Update 32 bit count, and set flag to indicate that the measurement is done.
</li>
<li>
The measured pulse width is in terms of a counter value, and we can convert that into seconds, since we know the clock speed. This time value is then used to calculate the distance.
</li>
</ul>
<p>The distance is then sent using serial communications on pin PB1 - I've <a href="http://electronut.in/serial-communications-with-the-attiny84/" title="Serial Communications with the ATtiny84">covered this part</a> in a previous post. This is also the reason we cannot use the 16-bit timer to measure the pulse width - it's already being used for serial communications. Plus it's fun to learn how to use the 8-bit timer to count large values, right? ;-)</p>
<p>Here is the schematic:</p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/attiny84-hcsr04.png"/>
</p>
<p>And the breadboard looks like this:</p>
<p><a href="/images/2013/06/IMG_1503.jpg"><img src="assets/IMG_1503.jpg" alt="attiny84-hcsr04" width="800" height="618" class="alignnone size-full wp-image-409" /></a></p>
<p>The full C code is listed below:</p>
<p><script src="https://gist.github.com/electronut/5730184.js"></script></p>
<p>This is the Makefile that goes along with the above code. It is similar to the ones posted before - I've just added some extra linker flags to support full printf formatting.</p>
<p><a href="https://gist.github.com/electronut/5763929">https://gist.github.com/electronut/5763929<br />
</a></p>
<p>And here is the Python code used to plot the data:</p>
<p><a href="https://gist.github.com/electronut/5730160">https://gist.github.com/electronut/5730160<br />
</a></p>
<p>The Python code is a minor modification to <a href="http://electronut.in/plotting-real-time-data-from-arduino-using-python/" title="Plotting real-time data from Arduino using Python">what I posted before</a> on the subject.</p>
<p>You can get the ATtiny84 at <a href="http://in.element14.com/atmel">element14</a>.</p>
