---
layout: post
title: A Silly Birthday Greeting Box
excerpt: "Hacking a cheap toy and using a MOSFET and a reed switch to create a silly birthday greeting box."  
tags: [reed switch, MOSFET]
categories: [Electronics]
comments: true
modified: 2015-05-22
thumbnail: images/2015/05/box-final.jpg
images: images/2015/05/box-final.jpg
---

<iframe width="420" height="315" src="https://www.youtube.com/embed/xy1e3aNny9s" frameborder="0" allowfullscreen></iframe>

<br />
<br />
There seems to be a deluge of cheap toys in my house, thanks to the
kids. But on the upside, many of these have interesting electronics
that are perfect for little hacks. I wanted to make a quick birthday
gift for my wife, and I remembered that I had stashed away this
particularly annoying toy (a cycle bell?) that sang "Happy Birthday"
continuously in an ear-shattering tone. So I decided to make a
birthday greeting box out of it. Here's what the ear-shatterer looks
like, outside and inside.

<br />
<br />
![Toy](/images/2015/05/box-toy.jpg "The Ear-Shatterer")
<br />
<br />


So it consists of a "black box" IC, which is connected to a push
button and a 3V battery box, and has outputs for a speaker and an LED.
After making a little sketch of the connection, I desoldered all the
wires, and cut off the hot glue to extract the speaker. The wires were
really flimsy and the soldering, connections etc. were clearly done by
an "I hate my job and want to shoot my boss" kind of employee.

For the box, I used the unused case for my wrist watch (also
unused). I wanted the music to be triggered when the box is opened. I've
done something similar before that earned me my "5 minutes of fame" on
[hackaday][1] and [lifehacker][2]. So I decide to take the same approach here -
use a MOSFET and a reed switch. The scheme is shown below.

<br />
<br />
![Circuit](/images/2015/05/box-circuit.jpg "The MOSFET circuit")
<br />
<br />

The high resistence (1 Mega Ohm) ensures that the current drain when
the box is closed in really small - which means more battery
life. When the box is closed, the reed switch is closed, the *gate* of
the MOSFET is grounded, and it doesn't supply power to the circuit.
When the box is opened, the reed switch opens, and the MOSFET turns
on, supplying power to the screamer. By design, the push button
triggers the music on for each press. But since I want an on/off type
of system, I just shorted the push-button connection, and connected
the circuit's power supply across VCC and the *drain* of the
MOSFET. The magnet, fixed to the top flap of the box, was stolen from
the kitchen refrigerator. (I can't resist magnets, so I keep buying
this junk at every international airport I pass through.) I also
replaced the red LED with a cooler blue LED.

<br />
<br />
![Box](/images/2015/05/box-build.jpg "The Box")
<br />
<br />


Now for some personality. My son helped me find three LEGO figures to
represent our team - construction worker, pirate (?) and
Obi-Wan. Pirate is holding the blue LED, which flickers in sync with
the screeching. And the box had the perfect slot for a Greeting
card. Here is the completed masterpiece (you can see it in action at
the YouTube link on top of the page):

<br />
<br />
![Box Final](/images/2015/05/box-final.jpg "The Masterpiece")
<br />
<br />

I am never throwing broken toys away. ;-)


[1]: http://hackaday.com/2012/12/21/adding-task-lighting-inside-a-desk/
[2]: http://lifehacker.com/5973589/add-automatic-led-lights-for-desk-drawers
