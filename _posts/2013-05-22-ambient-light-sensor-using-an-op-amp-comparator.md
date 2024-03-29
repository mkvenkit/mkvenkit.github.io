---
layout: post
title: Ambient Light sensor using an Op-Amp Comparator
excerpt: Ambient Light sensor using an Op-Amp Comparator
date: 2013-05-22 08:45:09.000000000 +05:30
categories:
- Circuits
tags:
- comparator
- LDR
- LM358
- op-amp
status: publish
type: post
published: true
comments: true
meta:
  _cc_page_slider_cat: a:0:{}
  _cc_page_slider_on: '0'
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
  _thumbnail_id: '190'
  _wpas_done_all: '1'

modified: 2013-05-22

thumbnail: images/2013/05/IMG_1416-tn.jpg
---
<p>Say you have a microcontroller circuit that does something when it goes dark. To save power, you want to put the chip to sleep when the ambient light drops below a certain level. One way to do this is using an <a href="http://en.wikipedia.org/wiki/Photoresistor">LDR </a>and an op-amp <a href="http://en.wikipedia.org/wiki/Comparator">comparator</a>. </p>
<p>Here is the schematic:</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1415.jpg"/></p>
<p>In the above circuit, the reference voltage at the non-inverting terminal of the op-amp is VCC/2. When it's dark, the LDR has a high resistance (over 20K), and the voltage at the inverting terminal (pin 3) is going to be less than VCC/2. Hence, the output of the op-amp will go to high when it is dark. When sufficient light falls on the LDR, its resistance falls, and the voltage at the inverting terminal (pin 2) exceeds VCC/2. At this point, the op-amp output goes low. We can control the threshold at which it goes from low to high by adjusting the potentiometer R1.</p>
<p>Here is what the circuit looks like on a breadboard. The supply is 5V regulated.</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1416.jpg"/></p>
<p>In this case, I am using the LM358 - a very popular general-purpose <a href="http://en.wikipedia.org/wiki/Operational_amplifier">Op-Amp</a> IC. This works fine for our purpose, but do note that there are dedicated comparator ICs with better switching characteristics for critical applications.</p>
<p>In my next post, I will describe how to hook this up to an ATmega168 and wake it up from power-save mode.</p>
