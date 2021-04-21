---
layout: post
title: Touch Activated Blinky Badge
excerpt: "A transistor based touch activated LED flasher badge to teach electronics and SMD soldering to kids and beginners."
tags: [LED, touch, badge, beginner, electronics, SMD, soldering, python]
categories: [Electronics]
comments: true
modified: 2015-09-26
thumbnail: images/2015/09/bb.png
images: images/2015/09/bb.png
---

![Touch Activated Blinky Badge](/images/2015/09/bb.png "Blinky Badge")

I wanted to create a simple project to teach soldering and electronics
to kids (10+ years) and beginners. I first thought of a simple two
transistor LED flasher, but then decided to make it interactive by
adding a touch sensitive element to it. The idea is that once made,
this PCB can be worn as a badge.

I had initially designed this using through-hole components. Here's a
photo of the breadboard prototype. I was using a couple on BC547 and
2N2222 transistors.

![BB Proto](/images/2015/09/bb-proto.jpg "Blinky Badge Prototype")

With SMD becoming more and more common, I decided to design the PCB
with. Plus I though SMD would have a much flatter profile - more suited to a
badge.

Here's the schematic for the Blinky Badge:

![BB Schematic](/images/2015/09/bb-schematic.png "Blinky Badge Schematic")

The touch plate consists of a few closely spaced copper tracks, and
when you put a finger across a track, it acts as a resistor, sending a
small current into the darlington pair *Q1 + Q2*, which amplifies the
current and switches on the bistable multivibrator circuit formed by
*Q3 + Q4*. The circuit is powered by a *CR2032* coin cell.

I designed this project using kicad, and the most interesting part was
creating the touch pad. Since all kicad project files are plain text
files, it was easy to figure out the structure and write a small
Python script to generate the pad. Here's a glimpse of the process:

![BB kicad](/images/2015/09/bb-kicad.png "Blinky Badge Touch Plate")

Soldering the badge was mostly very easy, except for the transistors, which
had very small pads. I have now changed the design to use larger pads. My
next goal is to teach my 10 year old to solder this board.

## Downloads

You can find all design files for this project, including the Bill Of
Materials (BOM) and gerbers, at my github link below:

[https://github.com/electronut/blinky-badge][1]

## Order From OSH Park

![BB OSHPark](/images/2015/09/bb-oshpark.png "BB OSHPark")

I've uploaded my gerbers to OSH Park. You can order PCBs from them
using the link below.

[https://oshpark.com/shared_projects/ETjUQUC9][2]


[1]: https://github.com/electronut/blinky-badge
[2]: https://oshpark.com/shared_projects/ETjUQUC9
