---
title: Preventing Raspberry Pi WiFi from going into Sleep Mode
date: 2013-06-27 15:53:54.000000000 +05:30
description: Preventing Raspberry Pi WiFi from going into Sleep Mode
tags:
- Raspberry Pi
- sleep mode
- WiFi
categories:
- Raspberry Pi
featured_image: /{"feature"=>"header.jpg"}
---
<p>I keep <a href="http://electronut.in/starting-raspberry-pi-wifi-ssh-and-gpio/" title="Starting Raspberry Pi: WiFi, ssh and GPIO">logged into my Raspberry Pi from my Mac</a>. The Pi is connected to my network using a USB WiFi adapter. But when I leave the login idle for a while, I find it to be (a) frozen and (b) I cannot login via a new ssh session - in fact, I can't even ping the Pi anymore. </p>
<p>I found the solution for problem (b) above <a href="http://raspberrypi.stackexchange.com/questions/1384/how-do-i-disable-suspend-mode/4518#4518">in a StackOverflow post</a>. </p>
<p>This is what you need to do:</p>
<p><!--more--></p>
<p><code>sudo nano /etc/modprobe.d/8192cu.conf</code></p>
<p>Add the following:</p>
<p><code># Disable power management<br />
options 8192cu rtw_power_mgnt=0</code></p>
<p>Thanks to user <strong>Herohtar</strong> at SO - I tried this, and it seems to work very well. I still need to figure out problem (a) - prevent a login session from freezing on long periods of inactivity.</p>
