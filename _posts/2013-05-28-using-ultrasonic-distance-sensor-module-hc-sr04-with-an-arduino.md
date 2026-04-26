---
title: Using Ultrasonic Distance Sensor Module HC-SR04 with an Arduino
date: 2013-05-28 18:42:18.000000000 +05:30
description: Using Ultrasonic Distance Sensor Module HC-SR04 with an Arduino
featured_image: "/images/2013/05/IMG_1462.jpg"
tags:
- arduino
- distance measurement
- HC-SR04
- Python
- ultrasonic sensor
categories:
- Arduino
---
<p>I just got hold of an HC-SR04 Ultrasonic Sensor Module. This is a short post on hooking it up to an Arduino Uno and getting distance information from it.</p>
<p>The sensor has 4 pins - VCC (5V), GND, Trigger and Echo. Looking at the datasheet for HC-SR04, the way it work is:</p>
<p><!-- start list--></p>
<ul>
<li>
Send a 10us HIGH pulse on the Trigger pin.
</li>
<li>
The sensor sends out a "sonic burst" of 8 cycles.
</li>
<li>
Listen to the Echo pin, and the duration of the next HIGH signal will give you the time taken by the sound to go back and forth from sensor to target.
</li>
</ul>
<p><!-- end list --></p>
<p>This is what it looks like hooked to the Arduino:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1462.jpg"/></p>
<p>And here is the Arduino code:</p>
<p><script src="https://gist.github.com/electronut/5662576.js"></script></p>
<p>This is what the distance plot looks like as I walk to towards the sensor. This is done using Python and matplotlib - please take a look at <a href="http://electronut.in/plotting-real-time-data-from-arduino-using-python/" title="Plotting real-time data from Arduino using Python">my post on plotting real-time data with Python</a>.</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/distance-plot.png"/></p>
<p>The datasheet says that the sensor has a range of 2cm to 400 cm, and an accuracy of 3mm. The target needs to be 0.5 sq m, so it's not going to be very useful to scan for small objects. But it could be useful in many other situations. The sensor is cheap - about Rs. 250, and I could get it from ebay.in easily. </p>
