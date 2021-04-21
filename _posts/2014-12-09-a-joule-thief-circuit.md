---
layout: post
title: A Joule Thief Circuit
excerpt: "I was looking for a simple voltage boost circuit when I found the Joule Thief."
tags: [joule thief, ferrite toroid, boost, circuit]
comments: false
#modified: 2014-12-09
thumbnail: images/2014/12/joule-thief-breadboard.jpg
images: images/2014/12/joule-thief-breadboard.jpg
---

![ferrite toroid](/images/2014/12/ferrite-toroids.jpg "Ferrite Toroids")

### The Joule Thief

I was looking for a simple voltage boost circuit for one of my
projects, when I came across a circuit called the *Joule Thief*. This
cool sounding circuit is astonishingly simple - just a coil which you
could wind yourself, a resistor, and a transistor. There seems to be
several variations of this nifty little circuit on the net. I had to
give this a shot! This is the circuit that I used:

<br />
![joule-thief](/images/2014/12/joule-thief-circuit.jpg "The Joule Thief Circuit")
<br /><br />


Now let's look at building the circuit.

### Building the Circuit

The tough thing was getting the ferrite toroid. I looked online and
couldn't find any cheap options. My friend Ravi and I wandered around
S.P. Road (Bangalore), looking for it, and finally had success at a
wholesaler called Jinanica. He reluctantly sold us 10 toroids - darn
cheap at Rs.6 per piece.

To make the coil, I wound 10 turns of 26 gauge insulated (yellow) wire
and then wound 7 turns of a second (red) wire on it. It matters how
you connect the coil to the circuit. For instance, you don't want to
join up the red and yellow wires at the starting point. The way you
connect it changes the way the coils are electromagnetically coupled,
changing the output. Here is the circuit, assembled on a breadboard:

<br />
![joule-thief-bb](/images/2014/12/joule-thief-breadboard.jpg "Building the Joule Thief Circuit")
<br /><br />

I hooked up the circuit to a 1.5 V AA battery, and the output to my
oscilloscope, and I was shocked to see pulses of 52 V (max) coming
out. The pulses were about 2 us in width and 20 us apart, giving an
output of about 5.5 V RMS. Wow man, electromagnetism rocks!

<br />
![joule-thief-osc](/images/2014/12/joule-thief-osc.jpg "Oscilloscope output from the Joule Thief Circuit")
<br /><br />


### Conclusion

The circuit works really well. I need to experiment with smoothing the
output a bit. I plan to use it soon for a project of mine, and will
post results.

### References

1. [Weekend Projects with Bre Pettis: Make a Joule Thief][1]
2. [Wikipedia entry on Joule Thief][2]

[1]:http://www.evilmadscientist.com/2007/weekend-projects-with-bre-pettis-make-a-joule-thief/
[2]:http://en.wikipedia.org/wiki/Joule_thief
