---
layout: post
title: Soldering Accelerometer MMA7660 in DFN-10 package using a Hot Air Rework Station
excerpt: Soldering Accelerometer MMA7660 in DFN-10 package using a Hot Air Rework Station
date: 2013-05-30 13:51:34.000000000 +05:30
categories:
- Circuits
tags:
- Accelerometer
- DFN-10
- MMA7660
- SMD
- soldering
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
  _thumbnail_id: '312'
  _wpas_done_all: '1'

modified: 2013-05-30

thumbnail: images/2013/05/chips-tn.png
---
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1474.jpg"/></p>
<p>Freescale makes some nifty accelerometer chips, like the popular MMA8452, for which Sparkfun, USA sells a breakout board. But unfortunately (for hobbyists) they all come in hard-to-solder tiny little packages, like the 16 pin QFN which is just 3 mm x 3mm across. </p>
<p>After a few unsuccessful attempts to solder the MMA8452 chip at home, I found a better candidate - the MMA7660 which has a DFN-10 package. As you can see from the schematic below, the latter has only 10 pins, and the pins extend to the sides, which makes it easier to solder.</p>
<p><img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/chips.png"/><br />
[From Freescale MMA8452/MMA7660 datasheets, for illustrative purpose.]</p>
<p>I was able to successfully solder the MMA7660 on to <a href=" http://www.proto-advantage.com/store/product_info.php?products_id=3100077">DFN-10 prototype board</a> using a hot air rework station. </p>
<p>I basically followed the technique shown in the video below:</p>
<p><!-- start list--></p>
<ol>
<li>
Apply flux and tin the pads.
</li>
<li>
Place chip on tinned pads - align correctly, apply flux.
</li>
<li>
Heat the chip with the hot air gun.
</li>
<li>
Solder exposed pins on the sides.
</li>
<li>
Reheat the chip with hot air gun to reflow the solder.
</li>
<li>
At each stage, inspect pads with magnifier for shorts, and use flux generously.
</li>
</ol>
<p><!-- end list--></p>
<p>Sjaak solders a QFN chip, attempts a BGA chip:</p>
<p><iframe width="560" height="315" src="http://www.youtube.com/embed/-tWLlkBD9DA?rel=0" frameborder="0" allowfullscreen></iframe></p>
<p>A couple of photos of the chip after soldering:</p>
<p>
<img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1353.jpg"/>
</p>
<p>
<img style="padding: 20px;" src="{{ site.baseurl }}/images/2013/05/IMG_1456.jpg"/>
</p>
<p><!-- end table --></p>
<p>So why torture yourself soldering these microscopic chips when you can buy breakout boards?</p>
<p>A few reasons to consider, especially if you are trying to make a product that you might sell:</p>
<p><!-- start list--></p>
<ul>
<li>
<strong>Cost</strong>: The breakout board is usually 4-5 times more expensive than buying the chip.
</li>
<li>
<strong>Size</strong>: If you are designing a PCB yourself, it's going to be much more compact if you just use the chip and not the whole breakout board.
</li>
<li>
<strong>Bragging Rights</strong>: When you walk into a bar and announce that you hand soldered a DFN-10 chip, that will surely make you popular. Right? Right? ;-)
</li>
</ul>
<p><!-- end list--></p>
