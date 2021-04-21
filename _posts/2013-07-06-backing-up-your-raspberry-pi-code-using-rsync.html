---
layout: post
title: Backing up your Raspberry Pi code using rsync
excerpt: Making the Raspberry Pi Speak
date: 2013-07-06 08:43:37.000000000 +05:30
categories:
- Raspberry Pi
tags:
- backup
- code
- emacs
- Raspberry Pi
- rsync
- ssh
status: publish
type: post
published: true
comments: true
meta:
  _cc_page_slider_on: '0'
  _cc_page_slider_cat: a:0:{}
  _cc_page_template_on: '0'
  _cc_page_template_cat: a:0:{}
  _cc_page_slider_caption: '0'
  _cc_post_template_on: '0'
  _cc_post_template_avatar: '0'
  _cc_post_template_date: '0'
  _cc_post_template_tags: '0'
  _cc_post_template_comments_info: '0'
  _edit_last: '5'
  _cc_post_template_type: img-left-content-right
  _wpas_done_all: '1'
---
<p>This is how I develop code on my Raspberry Pi:</p>
<p><a href="http://electronut.in/starting-raspberry-pi-wifi-ssh-and-gpio/" title="Starting Raspberry Pi: WiFi, ssh and GPIO">ssh into the Pi</a> from my Macbook Pro from 2 Terminals, and use <strong>emacs</strong> on one to edit the code, while I run the code from the other. This way I don't need to use the annoyingly slow X-server or VNC solutions to display UI from the PI for editing. </p>
<p><!--more--></p>
<p>Installing emacs on the Pi is exceedingly simple, by the way:</p>
<p><code>sudo apt-get install emacs</code></p>
<p>There are other editors, but really nothing beats <strong>emacs</strong> or <strong>vi</strong> when it comes to editing code on Linux, and I highly recommend that you spend some time learning one of these editors.</p>
<p>Since I develop code on the Pi directly, I need a backup plan, and the plan is <strong>rsync</strong>.</p>
<p><a href="http://en.wikipedia.org/wiki/Rsync">rsync</a> is a Unix utility that can synchronyze your files between directories and other machines (via ssh).</p>
<p>rsync is very powerful, and not to be meddled with unless you are paying attention. If you are mucking around it with it, (a) back up your test files and (b) use the -n or "dry run" flag so it only <em>tells</em> you what will be done and not actually do it, till you are satisfied.</p>
<p>Here is my script to back up my code directory (recursively) from the Raspberry Pi on to my Macbook:</p>
<p><script src="https://gist.github.com/electronut/5938436.js"></script></p>
<p>Here is a typical run:</p>
<p><code>$./bkup-pi.sh<br />
Backing up RPi #1...<br />
pi@192.168.4.31's password:<br />
receiving file list ... done<br />
python/hello.py<br />
python/hello.py~<br />
python/cat9532/<br />
python/cat9532/pi-cat9532.py~<br />
python/cat9532/rpi-cat9532.py<br />
python/cat9532/rpi-cat9532.py~<br />
python/gpiotest/<br />
python/gpiotest/testGPIO.py<br />
python/i2ctest/<br />
python/i2ctest/i2ctest.py<br />
python/i2ctest/i2ctest.py~<br />
python/mma7660/<br />
python/mma7660/mma7455.c<br />
python/mma7660/rpi-mma7660.c<br />
python/mma7660/rpi-mma7660.py<br />
python/mma7660/rpi-mma7660.py~<br />
python/opencv/<br />
python/opencv/ocvtest.py<br />
python/servo-test/<br />
python/servo-test/servo-test.py<br />
python/servo-test/servo-test.py~<br />
python/speech/<br />
python/speech/hello.py~<br />
python/speech/speech-test.py<br />
python/speech/speech-test.py~<br />
python/speech/test.py<br />
python/speech/test.py~</p>
<p>sent 502 bytes  received 24631 bytes  4569.64 bytes/sec<br />
total size is 23024  speedup is 0.92<br />
...<br />
done.</p>
<p></code></p>
