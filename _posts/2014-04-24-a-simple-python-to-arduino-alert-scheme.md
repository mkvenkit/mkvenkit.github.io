---
layout: post
title: A Simple Python to Arduino Alert Scheme
excerpt: A Simple Python to Arduino Alert Scheme
date: 2014-04-24 21:54:13.000000000 +05:30
categories:
- Arduino
- Python
tags:
- arduino
- Python
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'
image:
  feature: header.jpg

modified: 2014-04-24

thumbnail: images/2014/04/IMG_3598-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/04/IMG_3598.jpg"/>
</p>
<p>My friend asked me the following yesterday:</p>
<p>"Is it possible to make the build script at my company flash some lights when it fails?"</p>
<p>I gave her some suggestions which involved the usual suspects - Python and Arduino. Now it's all up to you, I said. But soon, I started fidgeting, and I can't help it. I need to try this myself. ;-)</p>
<p><!--more--></p>
<p>This is what I came up with:</p>
<ol>
<li>
Run a Python program that communicates with an Arduino via serial port.
</li>
<li>
Arduino is connected to some lights. (LEDs, for proof of concept.)
</li>
<li>
When build script fails, it communicates with the Python program, and it sends some data via<br />
serial port, which the Arduino reads, and flashes some lights.</li>
</ol>
<p>The only challenge here is the mechanism for a script on the build machine to communicate with our Python program. I am sure there are many sophisticated ways of doing this, but being a simpleton, I chose a very simple way - use a status file.</p>
<p>The build script writes 'OK' or 'BAD' (or whatever) to a file called <code>status.txt</code>, and the python code checks this file and sends some data to Arduino, which takes appropriate action.</p>
<p>The Python code sits in a loop, and every 2 seconds, reads the status file. If it reads 'OK', it sends a '1' via serial port. If it reads anything else, it sends a '0'. When it quits, it sends a '2', and this is used by the Arduino to cleanup.</p>
<p>Here is the Python code:</p>
<p><script src="https://gist.github.com/electronut/11259140.js"></script></p>
<p>At the Arduno end, it turns a Green LED on if it reads a '1' via serial, and a Red LED when it reads a '0'. If it reads anything else, it turns both LEDs off. (This is important for cleanup - when the python script exits, we turn the LEDs off.)</p>
<p>Here is the code at the Arduino end:</p>
<p><script src="https://gist.github.com/electronut/11259325.js"></script></p>
<p>Here is how I run it:</p>
<p><code>$ python ardu_alert.py --port /dev/tty.usbmodem411<br />
</code></p>
<p>To change the status I do:</p>

{% raw %}
$echo OK > status.txt
$echo BAD > status.txt
{% endraw %}

<p>It works quite well, as you can see below.</p>
<p><iframe src="//player.vimeo.com/video/92845497" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> </p>
<p>Instead of LEDs, you can hook up anything at the other end, provided you do some extra work. For example, use a MOSFET/transistor and a Relay to control lights, or maybe even hack a toy to do something silly. </p>
<p>That was fun. :D</p>
