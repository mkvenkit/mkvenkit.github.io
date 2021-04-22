---
layout: post
title: Ultrasonic sensor HC-SR04 with Dagu Mini Driver on a Robot Chassis
excerpt: Ultrasonic sensor HC-SR04 with Dagu Mini Driver on a Robot Chassis
date: 2014-03-29 13:41:01.000000000 +05:30
categories:
- Arduino
- Robotics
tags:
- arduino
- HC-SR04
- robot
- ultrasonic sensor
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'
  _wpas_done_all: '1'
image:
  feature: header.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/03/photo8.jpg" />
</p>

<p>I am working on a Raspberry Pi based robot, and recently acquired a <a href="https://www.dawnrobotics.co.uk/dagu-magician-2wd-robot-chassis/">Dagu chassis</a> and a <a href="http://www.dawnrobotics.co.uk/dagu-arduino-mini-driver-board/">Dagu Mini Driver</a> for this project. As soon as I had the mini driver hooked up and the wheels starts turning, I felt an irresistible urge ;-) to put an ultrasonic sensor on the chassis and have it roam around by itself. </p>
<p><!--more--></p>
<p>I've written about <a href="http://electronut.in/using-ultrasonic-distance-sensor-module-hc-sr04-with-an-arduino/" title="Using Ultrasonic Distance Sensor Module HC-SR04 with an Arduino">hooking up the inexpensive and fun Ultrasonic sensor HC-SR04</a> with an Arduino before. The wiring is the same - instead of a real Ardunio board, we're just using the Arduino compatible Dagu Mini driver here. You can see some details for this board at the link below. Unfortunately, they don't give you the full schematics.</p>
<p><a href="http://www.dagurobot.com/goods.php?id=142">http://www.dagurobot.com/goods.php?id=142<br />
</a></p>
<p>As far as construction goes, the Dagu chassis is very easy to put together. It can, and in fact it was put together by a 9 year old. :-)</p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/03/IMG_0597.jpg"/>
</p>

<p>Also as you can see, I've used very high tech Tie Wrap Technology to attach the sensor to the chassis. ;-)</p>
<p>The motors and the board are powered by a <a href="http://www.amazon.com/Astro-Mini-Ultra-Compact-Lipstick-Sized-Smartphones/dp/B005X1Y7I2/ref=sr_1_1?ie=UTF8&qid=1396081202&sr=8-1&keywords=Anker%C2%AE+Astro+Mini+3000mAh">3000 mAh 1A Anker rechargeable battery </a>- good stuff!</p>
<p>The programming part is quite simple. The main loop sends out a ping on the ultrasonic sensor. If it returns a distance less than a set threshold the wheels are made to stop and reverse. Then, the chassis is made to turn left by a bit, and this process repeats. This is a very simplistic algorithm, but you can modify it for more sophisticated behavior.</p>
<p>You can see the robot in action in the video below.</p>
<p><iframe src="//player.vimeo.com/video/90393983" width="500" height="331" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> </p>
<p>Here is the full source code:</p>
<p><script src="https://gist.github.com/electronut/9850220.js"></script></p>
<p>Not a complex project by a long shot. But it was a great fun detour for me, and I hope you find some useful information here.</p>
