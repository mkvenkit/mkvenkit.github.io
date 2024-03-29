---
layout: post
title: Servo Control using Hardware PWM with Raspberry Pi Model A+
excerpt: Using hardware PWM on the Pi to drive servos.
date: 2014-11-24 21:45:13.000000000 +05:30
categories:
- Raspberry Pi
tags:
- PWM
- Raspberry Pi
- servo
status: trash
type: post
published: false
comments: true
meta:
  _edit_last: '5'
  _thumbnail_id: '911'
  _wp_trash_meta_status: publish
  _wp_trash_meta_time: '1416847605'
image:
  feature: header.jpg

modified: 2014-11-24

thumbnail: images/2014/11/two-servos-harware-pwm-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/11/two-servos-harware-pwm.jpg"/>
</p>
<p>Since getting my hands on the new Raspberry Pi Model A+, I have been trying to understand how to use use the two hardware PWM pins. I did a <a href="http://electronut.in/testing-hardware-pwm-with-the-raspberry-pi-model-a/" title="Testing Hardware PWM on the Raspberry Pi Model A+">quick test using the oscilloscope</a> in my previous post. <!--more--></p>
<p>I hooked up two servos to my Pi. The signal lines of the servos are connected to the Pi's hardware pins (GPIO18 and GPIO13), and the servos are powered separately. (My Anker rechargeable 5V battery has battery can barely power these. I'll need to set up a LiPo battery.)</p>
<p>Below is the Python code used to test these. I use wiringPi to set the PWM parameters, but I found the values to be a bit confusing. The base clock has a frequency of 19.2 MHz. Setting a divisor of 400 along with a "range" of 1024 gives us a PWM frequency of 19200000/400/1024 = 46.875 Hz, or a period of 21.3 milli seconds. Generally servos require a pulse of 1 to 2 milliseconds with a 20 millisecond separation. So the above should work, and it does.</p>
<p><script src="https://gist.github.com/electronut/646ec6157383cb7c43ad.js"></script></p>
<p>And here are the two servos in action!</p>
<p><iframe width="560" height="315" src="//www.youtube.com/embed/4F59xp2APvc" frameborder="0" allowfullscreen></iframe></p>
