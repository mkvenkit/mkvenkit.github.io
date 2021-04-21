---
layout: post
title: 555 Based Motion Sensing Night Lamp Kit
excerpt: "My attempt to create a 555 Based motion sensing Night Lamp Kit for kids."  
tags: [555, PIR, kit]
categories: [Electronics]
comments: true
modified: 2015-06-18
thumbnail: images/2015/06/nl-final.jpg 
images: images/2015/06/nl-final.jpg 
---


<br />
<br />
![Night Lamp](/images/2015/06/nl-final.jpg "Night Lamp Enclosure")
<br />
<br />

<br />
This is a short note on my attempt in 2013 to create an electronics
kit meant for kids - a DIY motion sensing night lamp based on the good
old 555. Although I gave up on the project before I got to the final
manufacturing stage, it was an educational experience for me.

### Design

The basic idea is as follows: A PIR sensor triggers the 555 IC which
lights up an LED for some time. So if something moves in the dark, the
light will automatically come on. Here is the schematic:

<br />
<br />
![Night Lamp](/images/2015/06/night-lamp-circuit.png "Night Lamp Schematic")
<br />
<br />

In the schematic above, the 555 is configured in a *monostable* mode -
a timer, that is. *T1* is used to invert the signal from the PIR
sensor, as the ones I used go from *LOW* to *HIGH* when the triggered
by motion. But *Pin 2* of the 555 needs to go *LOW* to be triggered -
hence the inversion. The values of *C1* and *R3* are chosen such that
the timer lasts about 15 seconds. The output of the 555 goes to a two
transistor *constant current LED driver*, and for the LED I chose a
really bright one (Part No. C503C-WAS-CBADA151, 20 mA If, 24 cd
brightness). Power supply is from a 9V battery.

### PCB

This was my first real forway into PCB manufacturing. I used *EAGLE*, and messed up the first PCB:

<br />
<br />
![Night Lamp](/images/2015/06/nl-error.jpg "Night Lamp PCB Error")
<br />
<br />

<br/>
The second time around, I did get it right.

<br />
<br />
![Night Lamp](/images/2015/06/nl-pcb.jpg "Night Lamp PCB")
<br />
<br />

### Enclosure

I used laser cut acrylic for the enclosure. I attempted a screw-less
cantilever design, and even had a slot for hanging the box on a
nail. I used *Inkscape* and *Sketchup* to design the box. I had to
make 7 iterations by the time I ironed out all the issues. Here's
lucky #7:

<br />
<br />
![Night Lamp](/images/2015/06/nl-assembly.jpg "Night Lamp PCB")
<br />
<br />

<br />
This was 2 years ago. Today, I dusted off the circuit, changed the
battery, and it still works.

<iframe width="420" height="315" src="https://www.youtube.com/embed/I-t0ynCbcPw" frameborder="0" allowfullscreen></iframe>

### Downloads

You can get all files for this project from my github link below:

<br/>
[https://github.com/electronut/night-lamp][1]

<br />
<br />
![Night Lamp](/images/2015/06/nl-oshpark.png "Night Lamp PCB")
<br />
<br />

<br />
You can also order the PCB from the OSH Park link below:

<br />
[https://oshpark.com/shared_projects/wEVw0g1x][2]


### Conclusion

Although the circuit worked well, I didn't have the drive to perfect
the enclosure and bring the kit to production. But it did get me started
on the path to becoming an indie hardware maker. Some things I learned
from this exercise:

1. The cantilever design for enclosure was a bad idea. It breaks very fast.
2. Be prepared to iterate over PCB and enclosure design.
3. Hardware is hard (duh!). Even a small kit like this takes time to perfect.
4. The last 5% takes forever.

### References

1. Practical Electronics for Inventors, Third Edition, by Paul Scherz and Simon Monk.

[1]: https://github.com/electronut/night-lamp
[2]: https://oshpark.com/shared_projects/wEVw0g1x
