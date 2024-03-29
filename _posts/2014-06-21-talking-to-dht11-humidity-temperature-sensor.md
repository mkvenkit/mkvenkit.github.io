---
layout: post
title: Talking to DHT11 Humidity & Temperature Sensor
excerpt: Talking to DHT11 Humidity & Temperature Sensor
date: 2014-06-21 11:51:46.000000000 +05:30
categories:
- Circuits
tags:
- DHT11
- humidity
- sensor
- serial
- temperature
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'

modified: 2014-06-21

thumbnail: images/2014/06/dht11-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/06/Doc-15-06-14-6-34-pm.jpg"/>
</p>
<p>I am working on a "weather monitor" project that involves a Raspberry Pi taking to a DHT11 Humidity and Temperature sensor and serving up the collected data as a graph, over a web page. So, I wanted to first get an idea about how this sensor works.</p>
<p>The DHT11 is designed to work with a microcontroller, but we can coax it to send data with a simple circuit, as shown above. </p>
<p><!--more--></p>
<p>The DHT11 data sheet says that if we pull the input line LOW for 18 ms, pull the line HIGH and wait for 20-40 us, the DHT11 should start transmitting data. Pulling the line LOW can be done by just pressing the button. Here's the oscilloscope output right after I press the push button. </p>

<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/06/photo.jpg"/>
</p>

<p>Just like the data sheet said, 80 us LOW, 80 us HIGH, followed by 40 bits of data. The HIGH bits are 70 us long, and the LOW bits are 26-28 us long. Writing this bit stream out on a piece of paper, I got:</p>
<p><code>00110111 00000000 00011010 00000000 01010001<br />
</code></p>
<p>Let's decode this with a bit of Python:</p>
<p><code>>>> x = '00110111 00000000 00011010 00000000 01010001'.split()<br />
>>> x<br />
['00110111', '00000000', '00011010', '00000000', '01010001']<br />
>>> [int(i, 2) for i in x]<br />
[55, 0, 26, 0, 81]<br />
>>> </code></p>
<p>The first two numbers represent the Relative Humidity % (55.0), the next two the temperature n Centigrade (26.0), and the last number is a checksum (81 == 55 + 26). Looks good!</p>
<p>I tried to write some Python code to read the data, but unfortunately, my Python data loop does not seem fast enough to get the 40 bits without errors. Since I am on a deadline, I ended up using Adafruit's DHT driver below, which uses memory-mapped I/O. I need to study their code. ;-)</p>
<p><a href="https://github.com/adafruit/Adafruit_Python_DHT">https://github.com/adafruit/Adafruit_Python_DHT<br />
</a></p>
