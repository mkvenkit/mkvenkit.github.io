---
layout: post
title: Talking to a Raspberry Pi from your Phone using Bottle (Python)
excerpt: Talking to a Raspberry Pi from your Phone using Bottle (Python)
date: 2014-03-22 17:06:00.000000000 +05:30
categories:
- Python
- Raspberry Pi
tags:
- Bottle
- LED
- Python
- Raspberry Pi
status: publish
type: post
published: true
comments: true
meta:
  _cc_post_template_type: img-left-content-right
  _edit_last: '5'
  _cc_post_template_comments_info: '0'
  _cc_post_template_tags: '0'
  _cc_post_template_date: '0'
  _cc_post_template_avatar: '0'
  _cc_post_template_on: '0'
  _cc_page_slider_caption: '0'
  _cc_page_slider_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_slider_on: '0'
  _cc_page_template_cat: a:0:{}

modified: 2014-03-22

thumbnail: images/2014/03/ledctrl-pi-tn.jpg
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/03/ledctrl-pi.jpg"/>
</p>
<p>Here's a short post on communicating with the raspberry from your phone's browser.</p>
<p>Our goal is to turn an LED connected to the Pi on and off, by accessing a web page on the phone's browser. Both the phone and the Pi are on the local WiFi network.</p>
<p><!--more--></p>
<p>Here's how we do it:</p>
<p>Start a web server on the Pi. For this, we will use the simple and elegant <a href="http://bottlepy.org/docs/dev/index.html#">Bottle web framework</a>, which consists of a single source file. Accessing the LED control web page displays a button, and clicking on it uses <a href="https://api.jquery.com/jQuery.ajax/">jQuery AJAX</a> to send a request to the web server, which in turn changes the GPIO pin state to turn the LED on.</p>
<p>Here's the code:</p>
<p><script src="https://gist.github.com/electronut/9705471.js"></script></p>
<p>To start it, first run the server on your Pi. (You can <a href="http://electronut.in/starting-raspberry-pi-wifi-ssh-and-gpio/" title="Starting Raspberry Pi: WiFi, ssh and GPIO">ssh into your pi</a> for this.)</p>
<p><code>pi@raspberrypi ~/code/python/bottle $ sudo python ledctrl.py<br />
</code></p>
<p>Then, access the web page from your phone's browser. In my case, the address is:</p>
<p><code>http://192.168.4.31:8080/led<br />
</code></p>
<p>You can control the LED from anywhere as long as you are in the local network. This can also work, from outside provided you do <a href="http://www.wikihow.com/Set-Up-Port-Forwarding-on-a-Router">port forwarding</a> on your router. I plan to explore this myself.</p>
<p>This is the starting point for me for a Raspberry Pi based home monitor robot. Watch this site for updates on this topic!</p>
