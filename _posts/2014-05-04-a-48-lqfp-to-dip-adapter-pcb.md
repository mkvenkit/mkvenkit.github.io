---
layout: post
title: A 48 LQFP to DIP adapter PCB
excerpt: A 48 LQFP to DIP adapter PCB
date: 2014-05-04 22:12:29.000000000 +05:30
categories:
- Open Source Hardware
tags:
- adapter
- DIP
- EAGLE
- gerber
- LQFP
- Open Source Hardware
- OSH
- PCB
status: publish
type: post
published: true
comments: true
meta:
  _edit_last: '5'
  _oembed_d43707f278918764a45e6417ece83141: '{{unknown}}'
image:
  feature: header.jpg

modified: 2014-05-04

thumbnail: images/2014/05/adapter-tn.png
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2014/05/Screen-Shot-2014-05-04-at-5.25.14-pm.png"/>
</p>
<p>I have been looking at prototyping with some ARM Cortex M4 chips, and many of them use a 48 pin LQFP packaging. Sadly, I haven't been able to find a decent 48 LQFP to DIP adapter PCB in India. The only one I saw was expensive and designed in a crazy way (4 sets of orthogonal pins) which made it useless for breadboard prototyping. So I decide to create one of my own.</p>
<p><!--more--></p>
<p>Here are the EAGLE design files:</p>

<p><a href="https://github.com/electronut/pcbs/tree/master/48LQFP-to-DIP">https://github.com/electronut/pcbs/tree/master/48LQFP-to-DIP<br />
</a></p>
<p>I have also uploaded the Gerbers to OSHPark so you can order it directly from them:

<a href=" https://oshpark.com/shared_projects/E5GrRBgq">
https://oshpark.com/shared_projects/E5GrRBgq</a></p>

<p>I plan to place an order myself from OSHPark and will update this post with my results.</p>
<p>Hope someone finds this useful. :-)</p>
<p>(The rendering of the board is from the <a href="http://mayhewlabs.com/webGerber/">fabulous online gerber viewer</a> from mayhewlabs.)</p>
