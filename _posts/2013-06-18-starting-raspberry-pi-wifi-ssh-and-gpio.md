---
layout: post
title: 'Starting Raspberry Pi: WiFi, ssh and GPIO'
excerpt: 'Starting Raspberry Pi: WiFi, ssh and GPIO'
date: 2013-06-18 13:57:18.000000000 +05:30
categories:
- Raspberry Pi
tags:
- GPIO
- Python
- Raspberry Pi
- WiFi
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
  _cc_page_template_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_slider_on: '0'
  _cc_page_slider_cat: a:0:{}
  _thumbnail_id: '439'
  _wpas_done_all: '1'

modified: 2013-06-18

thumbnail: images/2013/06/IMG_1534-tn.jpg
---
<p>This is a short post on setting up the Raspberry Pi (RPi) for development for the first time.</p>
<p>Being that the RPi is a full-fledged mini computer, it seems prudent to get a case rather than sticking wires all over it. Here's a case that I picked up from ebay:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1534.jpg" />
</p>
<p>It's also very helpful to get a power adapter. This one's from Samsung (5V, 700 mA) and connects to the micro USB port:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1564.jpg"/>
</p>
<p>Next, you need to install an Operating System for your RPi. What you do is to download the latest "Wheezy" from the RPi official site, and write that image on to an SD card. Here is a nice video that will help you with this part:</p>
<p><iframe width="560" height="315" src="http://www.youtube.com/embed/lG7BeR19YHc" frameborder="0" allowfullscreen></iframe></p>
<p>For the first-time setup, it is nice to have a keyboard and mouse. I got this wireless keyboard with built-in trackpad for this purpose, and it was plug & play installation with Wheezy.</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1562.jpg" />
</p>
<p>Internet is the next priority, and this USB WiFi adapter works great:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1563.jpg"/>
</p>
<p>You can use your TV as the RPi monitor, as long as it has an HDMI cable. Here's the my RPi connected to the TV:</p>
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/06/IMG_1553.jpg"/>
</p>
<p>The first thing I need for RPi development is to have remote access to it. I don't want to sit in front of my TV and use a miniature keyboard to do coding. So the next thing is to set up <strong>ssh</strong> on the Pi so I can remote login. For this, we need to get a static IP setup for the Pi. You can read more about this here:</p>
<p><a href="http://elinux.org/RPi_Remote_Access">http://elinux.org/RPi_Remote_Access<br />
</a></p>
<p>Here is what my network configuration file looks like:</p>
<p><code><br />
pi@raspberrypi /etc/network $ cat interfaces<br />
auto lo</p>
<p>iface lo inet loopback<br />
iface eth0 inet dhcp</p>
<p>allow-hotplug wlan0<br />
iface wlan0 inet manual<br />
wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf<br />
iface default inet static<br />
	address 192.168.4.31<br />
    	netmask 255.255.255.0<br />
    	gateway 192.168.4.1<br />
</code></p>
<p>Now, you can login from your machine (in my case, a Mac) as follows:</p>
<p><code>$ ssh pi@192.168.4.31<br />
</code></p>
<p>Note that the default password for the user "pi" is "raspberry".</p>
<p>You can also display GUI from the RPi on to your machine as long as you have an X-server running. Start the session with:</p>
<p><code>$ ssh -X pi@192.168.4.31<br />
</code></p>
<p>Now, if you type:</p>
<p><code>$midori<br />
</code></p>
<p>The RPi browser window will popup on your remote machine, if you have the X-server setup correctly. But this is painfully slow, which is why I stick to ssh and the command line.</p>
<p>Python comes pre-installed with the RPi, which is great. But to use the GPIO pins with Python, you still need to get the appropriate library. Here is how you can do it:</p>
<p><code>$sudo apt-get update<br />
$sudo apt-get install python-dev</code></p>
<p>Now download the Python GPIO library from:</p>
<p><a href="http://code.google.com/p/raspberry-gpio-python">http://code.google.com/p/raspberry-gpio-python<br />
</a></p>
<p>Download, unzip, untar, cd into the directory and do:</p>
<p><code>$sudo python setup.py install<br />
</code></p>
<p>Now you are all set to talk to external hardware with Python!</p>
<p>As a simple test of the GPIO, I am hooking up an LED to pin 18 (GPIO5) of the RPi.</p>
<p><a href="http://electronut.in/wp-content/uploads/2013/06/IMG_1560.jpg"><img src="assets/IMG_1560.jpg" alt="RPi GPIO" width="800" height="520" class="alignnone size-full wp-image-439" /></a></p>
<p>Here is the code to make this LED blink:</p>
<p><script src="https://gist.github.com/electronut/5803155.js"></script></p>
<p>Your RPi is all set. Just power it on, and since the WiFi adapter puts it on your network, you can remote login any time from your machine and work on your project.</p>
<p><strong>Checking your Raspberry Pi Hardware Version</strong></p>
<p>There are several flavors of Pi. ;-)</p>
<p>Here is how you can check your version.</p>
<p><code>pi@raspberrypi ~ $ cat /proc/cpuinfo<br />
processor	: 0<br />
model name	: ARMv6-compatible processor rev 7 (v6l)<br />
BogoMIPS	: 2.00<br />
Features	: swp half thumb fastmult vfp edsp java tls<br />
CPU implementer	: 0x41<br />
CPU architecture: 7<br />
CPU variant	: 0x0<br />
CPU part	: 0xb76<br />
CPU revision	: 7</p>
<p>Hardware	: BCM2708<br />
Revision	: 000f<br />
Serial		: 00000000364a6f1c</code></p>
<p>To understand the revision number, refer to the hardware revision history table at <a href="http://elinux.org/RPi_HardwareHistory">this link</a>. In my case, I have the Model B, with PCB Rev 2.0, made in Q4 2012.</p>
<p><strong>Plugging in an HDMI cable</strong></p>
<p>Edit <code>config.txt</code> in the SD Card as follows, to ensure that your Pi recognizes the HDMI cable of your monitor.</p>
<p><code>hdmi_force_hotplug=1</code></p>
