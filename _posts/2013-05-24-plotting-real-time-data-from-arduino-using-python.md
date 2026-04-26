---
title: Plotting real-time data from Arduino using Python
date: 2013-05-24 16:20:23.000000000 +05:30
description: Plotting real-time data from Arduino using Python
featured_image: "/images/2013/05/plot.png"
tags:
- analog
- arduino
- LDR
- matplotlib
- plot
- real-time
categories:
- Arduino
- Python
---
<p><iframe width="560" height="315" src="http://www.youtube.com/embed/LMr5UHJJPNk" frameborder="0" allowfullscreen></iframe></p>
<p><a href="http://www.arduino.cc/">Arduino </a> is fantastic as an intermediary between your computer and a raw electronic circuit. Using the serial interface, you can retrieve information from sensors attached to your Arduino. (You can also send information via the serial interface to actuate circuits and devices (LEDs, relays, servos, etc.) connected to your Arduino.) Once you have the data in your computer, you can do all sorts of things with it - analyze it, display it, or share it on the internet, for instance.</p>
<p>In this post, I will be reading and displaying analog data from a pair of LDRs connected to an Arduino. Here is the schematic:</p>
<p><!--more--></p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1443.jpg"/></p>
<p>Here is how you hook it up to the Arduino:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1439.jpg"/></p>
<p>The Arduino sketch is very simple - it just reads the values from analog pins A0 and A1 (in the range [0, 1023]) and prints it to the serial port. Here is the code:</p>
<p><script src="https://gist.github.com/electronut/5641938.js"></script></p>
<p>The serial port sends values in the format:</p>
<p><code>512 300<br />
513 280<br />
400 200<br />
...<br />
</code></p>
<p>On the computer side, I need to read these values, and plot them as a function of time. I am using Python and the <a href="http://matplotlib.sourceforge.net/">Matplotlib </a>library for this. I wanted to display this as a scrolling graph that moves to the right as data keeps coming in. For that, I am using the Python <code>deque</code> class to keep and update a fixed number of data points for each time frame. </p>
<p>You can see the full implementation here:</p>
<p><strong>UPDATE</strong>: I have upgraded the code below to use the matplotlib animation class. You can still get to the old code <a href="https://gist.github.com/electronut/5641933">here</a>.</p>
<p><script src="https://gist.github.com/electronut/d5e5f68c610821e311b0.js"></script></p>
<p>And here is what the plot looks like. It scrolls to the right as data keeps coming in.</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/plot.png"/></p>
