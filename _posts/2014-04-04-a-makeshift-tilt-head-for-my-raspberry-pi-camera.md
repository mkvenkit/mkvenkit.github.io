---
layout: post
title: A Makeshift Tilt-Head for my Raspberry Pi Camera
excerpt: A Makeshift Tilt-Head for my Raspberry Pi Camera
date: 2014-04-04 22:30:32.000000000 +05:30
categories:
- Raspberry Pi
tags:
- arduino
- camera
- enclosure
- pan tilt
- Raspberry Pi
- sd card
- servo
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'
  _wpas_done_all: '1'
image:
  feature: header.jpg
  
modified: 2014-04-04

thumbnail: images/2014/04/IMG_3558-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/04/IMG_3558.jpg" />
</p>
<p>I want a pan/tilt scheme for the camera of my <a href="http://electronut.in/ultrasonic-sensor-hc-sr04-with-dagu-mini-driver-on-a-robot-chassis/" title="Ultrasonic sensor HC-SR04 with Dagu Mini Driver on a Robot Chassis">Raspberry Pi based home monitor robot</a>. But rather than use a pan/tilt bracket with two servos, I thought I could simplify things by using one servo for titling the camera and using the robot chassis swivel to pan the camera.</p>
<p><!--more--></p>
<p>So I wanted something to hold the Pi camera, as well as attach it to the servo. I found that some clever folks on the net were using SD card holders as enclosures for the tiny (but expensive!) Raspberry Pi cameras. I decided to try and put these ideas together.</p>
<p>The construction is shown below (click to enlarge). I first tried to cut the SD card holder using a blade, but the darn plastic was thicker than I though. So I attacked it with my Dremel next, and created a hole so that the rectangular camera module could poke through. I then dug into my son's Lego collection and found an unused brick that attached nicely to the servo shaft. I hot-glued that to one side of the SD card holder. The next step was to cover up all the ugly work I did by wrapping it under nice Gaffer's tape (my prized possession). </p>

<p style="padding:20px;">
<img src="{{ site.baseurl }}/images/2014/04/sd-tilt-head.jpg">
</p>
<p>To test the servo, I used an Arduino with the following simple code that sweeps the servo across its range:</p>
<p><a href="http://arduino.cc/en/Tutorial/Sweep">http://arduino.cc/en/Tutorial/Sweep</a></p>
<p>Here's the whole thing in action:</p>
<p><iframe src="//player.vimeo.com/video/90989038" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> </p>
<p>Hope that was somewhat entertaining. ;-)</p>
