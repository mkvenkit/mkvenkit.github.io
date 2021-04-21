---
layout: post
title: Getting Started with Atmel ATtiny10
excerpt: "Programming ATtiny10 using TPI and driving an RGB LED."
tags: [tinyAVR, ATtiny10, TPI, Atmel ICE, Atmel Studio]
categories: [Electronics]
comments: true
modified: 2016-03-17
thumbnail: images/2016/03/attiny10-finger.jpg
images: images/2016/03/attiny10-finger.jpg
---

![ATtiny10](/images/2016/03/attiny10-finger.jpg "ATtiny10")

## Introduction

I like Atmel tinyAVRs because they are tiny computers that I can
(almost) wrap my head around. The Atmel ATtiny4/5/9/10 are the
cheapest in the tinyAVR line, and they come in two packages - *SOT23*
pictured above, and an even more stupendously small 2mm x 2mm *USON*
package. This article will talk about programming these little
chips. Though they may be tiny, they are still quite capable, and the right
choice for many projects.

I've written about tinyAVRs before, and you can take a look at some
of the articles before to get a feel for them.

- [Talking to MMA7660 using I2C and ATtiny85][1]
- [Talking to Ultrasonic Distance Sensor HC-SR04 using an ATtiny84][2]
- [Serial Communications with the ATtiny84][3]

One fundamental difference in programming ATtiny10 versus the above is
that the former requires TPI (Tiny Programming Interface), which we will explore
below.

## The Circuit

To keep things interesting, we will program the ATtiny10 to drive a *common cathode* RGB LED. Here's the schematic:

![ATtiny10](/images/2016/03/attiny10-schematic.png "ATtiny10")

Above, you can see that the R, G and B leads of the LED are connected
to *PB0*, *PB1* and *PB2* pins of the ATtiny10. You can also see the
connections for the *Tiny Programming Interface*, which makes use of
three signals - *TPICLK*, *TPIDATA* and *RESET*. The traditional
*MOSI* in not connected. The pins are arranged in an indentical order
to the standard 2x3 ICSP header. Another thing to remember is that TPI
requires a 5V signal - 3.3V won't cut it. (But after programming, your
circuit can *run* at a lower voltage.)

Here's what it looks like, hooked up:

![ATtiny10](/images/2016/03/attiny10-hookup.jpg "ATtiny10")

I used an *SOT23* to *DIP* adapter above so I could use the chip on
a breadboard. To plugin the Atmel ICE 2x3 header on a breadboard easily,
I used a handy [AVR ISP adapter PCB][4] - an open source design
you can order from OSH Park.

## Programming with Atmel Studio 7 and Atmel ICE

I have [written before][1] on using Atmel Studio 7 and ICE for programming
tinyAVRs. The setup is similar here, except that we need to use TPI as the
programming interface. Once the project is setup and compiled, here's
what the *device programming* settings look like:

![ATtiny10-AS-ICE](/images/2016/03/attiny10-as-ice.png "ATtiny10-AS-ICE")

As you can see above, the interface is *TPI* and the target voltage
is read in as 5V, and the signature 0x1E9003 matches that of ATtiny10
from the datasheet. Use the *Program* option under *Memories* to
upload the code, and you're done.

I'll say it again: The combination of Atmel Studio 7 and ICE is a
fabulous toolset for programing Atmel microcontrollers. A long term Mac
user, I was so impressed by this combination that I bit the bullet,
took a pickaexe to my frozen wallet, and broke out the hard cash to
buy myself a license of Windows 10 (ugh) and Parallels (wow), so I
could use these tools from the comfort of my Macbook and OS X. I wish
that Atmel Studio was cross platform, but then I also wish that
the Aliens land soon. I ain't holding my breath for either.

### Note

The RGB LED connections interfere with TPI programming. So
you need to disconnect the LED (just pull the ground) during programming.

## Programming with USB ASP

I wanted to explore a cheaper option than Atmel ICE for programming
the ATtiny10. I found [some evidence][5] (How is your Polish?) on the
web that the cheap USB ASP programmer can be made to support TPI. But
so far, I haven't been able to make it work. I'll update this section
if I manage to do it.

In my view, it's better to buy an Atmel ICE if you are working with their
chips. They offer just the PCB for USD 35 if you are on a budget, and
are brave enough to make your own cables.

## The Code

The first thing you want to set is the clock speed. The ATtiny10 doesn't
have any fuses related to that, so you need to set that in the *CLKPS*
register. The default is a prescaler of 8 which puts it at 1 MHz,
but we want to run it at 8 MHz.

{% highlight C %}
{% raw %}
// Set CPU speed by setting clock prescalar:
// CCP register must first be written with the correct signature - 0xD8
CCP = 0xD8;
//  CLKPS[3:0] sets the clock division factor
CLKPSR = 0; // 0000 (1)
{% endraw %}
{% endhighlight %}

In the code, you want to ensure that *F_CPU* is set to 8 MHz so calls
like *_delay_ms()* work correctly.

{% highlight C %}
{% raw %}
// define CPU speed - actual speed is set using CLKPSR in main()
#define F_CPU 8000000UL
{% endraw %}
{% endhighlight %}

The way we're going to light up the RGB LED is to supply the correct
PWM frequency to each channel, based on the colors. I've chosen these
amazing colors for the LED, and they are stored in program memory as
follows:

{% highlight C %}
{% raw %}
// cyan, magenta, orange, purple, yellow
const unsigned char red[]   PROGMEM = {  0, 255,  255, 127, 255};
const unsigned char green[] PROGMEM = {255,   0,  127,   0, 255};
const unsigned char blue[]  PROGMEM = {255, 255,    0, 127,   0};
{% endraw %}
{% endhighlight %}

The PWM for each channel is set in an interrupt function (more on setup below),
which turns the channels on/off based on an 8-bit PWM counter variable:

{% highlight C %}
{% raw %}
// interrupt for Compare A
ISR(TIM0_COMPA_vect)
{
	// turn on/off according to PWM value
	if (pwmCount > rgb[0]) {
		PORTB &= ~(1 << PB0);
	}
	else {
		PORTB |= (1 << PB0);
	}
	if (pwmCount > rgb[1]) {
		PORTB &= ~(1 << PB1);
	}
	else {
		PORTB |= (1 << PB1);
	}
	if (pwmCount > rgb[2]) {
		PORTB &= ~(1 << PB2);
	}
	else {
		PORTB |= (1 << PB2);
	}
	// increment PWM count
	pwmCount++;

	// increment interval counter
	counter0++;
}
{% endraw %}
{% endhighlight %}

When the above function is called 256 times, we would have completed one cycle
of the PWM. The interrupt is setup as follows:

{% highlight C %}
{% raw %}
// set up Output Compare A
// WGM[3:0] is set to 0010
// prescaler is set to clk/8 (010)
TCCR0A = 0;
TCCR0B = (1 << 1) | (1 << WGM02);
// set Output Compare A value
OCR0A = 39;
// enable Output Compare A Match interrupt
TIMSK0 |= (1 << OCIE0A);
{% endraw %}
{% endhighlight %}

In the above code (Yes, you need to read the datasheet!) we setup
the 16-bit Timer0 of the ATtiny as follows:

1. Set timer prescaler to divide by 8.
2. Enable CTC mode for OCR0A.
3. Set OCR0A value for comparison.
4. Enable Output Compare A interrupt.

What the above does is to generate an interrupt every time the 16-bit
counter value matches OCR0A. For the values chosen above, that happens
every $$\frac{1}{8000000}*8*39$$ or 39 microseconds. So mutiply this
by 256 and you get your PWM cycle = 0.01 seconds, or 100 Hz, which is
fine to drive LEDs without flicker.

In the main code, the LED color is changed at regular intervals as follows:

{% highlight C %}
{% raw %}
// main loop
while (1)
{
  // change color every N cycles
  if(counter0 % colorInterval == 0) {
    colorIndex = (colorIndex + 1) % nColors;
	// set current RGB value
	rgb[0] = pgm_read_byte(&red[colorIndex]);
	rgb[1] = pgm_read_byte(&green[colorIndex]);
	rgb[2] = pgm_read_byte(&blue[colorIndex]);
  }
}
{% endraw %}
{% endhighlight %}

*colorInterval* is set to 32768, which gives an interval of 39 us *
 32768 = 1.27 seconds. You can also see above how the colors are read in
 from program memory.

## In Action

Here you can see the ATtiny10 in action, changing the colors of the
RGB LED every second or so. (I put a tape on the LED because I was
going blind staring at it all day.)

<iframe width="560" height="315" src="https://www.youtube.com/embed/t2HLAUw94Tw" frameborder="0" allowfullscreen></iframe>

## Downloads

You can get the complete source code for this project here:

[https://github.com/electronut/attiny10-rgb-hello][6]

[1]: http://electronut.in/attiny85-mma7660/
[2]: http://electronut.in/talking-to-ultrasonic-distance-sensor-hc-sr04-using-an-attiny84/
[3]: http://electronut.in/serial-communications-with-the-attiny84/
[4]: http://oshpark.com/shared_projects/JCbaKwcL
[5]: http://mirekk36.blogspot.in/2013/07/attiny10-tpi-usbasp-mkavrcalculator.html
[6]: https://github.com/electronut/attiny10-rgb-hello
