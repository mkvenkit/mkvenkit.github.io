---
layout: post
title: Installing Arduino Bootloader on an ATmega32u4
excerpt: "Soldering the ATmega32u4 chip and installing Arduino Bootloader on it."  
tags: [AVR, Arduino, ATmega32u4, bootloader]
categories: [Electronics]
comments: true
modified: 2015-06-07
thumbnail: images/2015/06/atmega32u4-solder1.jpg
images: images/2015/06/atmega32u4-solder1.jpg
---

The Atmel ATmega32u4 gained popularity with its use in the Arduino
Leonardo, due to the built-in USB support, which made an additional
chip unnessary for that purpose. I've had a couple of ATmega32u4s in
storage for a while, so I decided to try and solder the chip and make
an Arduino Leonardo compatible board out of it. Both [Adafruit][1] and
[Sparkfun][2] have ATmega32u4 breakout boards that they sell, and I
have used their designs as a reference. Why bother? Because if you are
developing an AVR based board with USB, this chip is worth looking at,
especially since you can use the existing Leonardo bootloader.


##Soldering

The first step of course, is to solder the darn chip. I used a *QFP 44*
breadboard adapter, and started by tinning the pads.

<br />
<br />
![ATmega32u4](/images/2015/06/atmega32u4-solder1.jpg "Soldering the ATmega32u4")
<br />
<br />

<br />
Next, I soldered the chip. Diagonal corner pins first, to fix the chip
on the board. Used plenty of flux, and a magnifier loupe (getting
old!).

<br />
<br />
![ATmega32u4](/images/2015/06/atmega32u4-solder2.jpg "Soldering the ATmega32u4")
<br />
<br />

After a close inspection, checking for shorts, etc., I assembled the
circuit on a breadboard. The schematic can be found [here][3].

<br />
<br />
![ATmega32u4](/images/2015/06/atmega32u4-breadboard.jpg "ATmega32u4 circuit")
<br />
<br />

<br />
For the USB connection, I cut an old USB cable. The color scheme for
the wires is shown below. But I (painfully) discovered that *D+* and *D-*
are switched some times.

<br />
<br />
![USB](/images/2015/06/usb-cable.jpg "USB cable wire colors")
<br />
<br />

##Bootloader

After setting up the breadboard, I used an ISP programmer (Sparkfun, based on usbtiny) and *avrdude* to first check the fuses on the chip - to see if the connections are alive, basically:

{% highlight sh %}
{% raw %}
$ avrdude -c usbtiny -p m32u4 -U lfuse:r:low_fuse_val.hex:h -U hfuse:r:high_fuse_val.hex:h

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.01s

avrdude: Device signature = 0x1e9587
avrdude: reading lfuse memory:

Reading | ################################################## | 100% 0.00s

avrdude: writing output file "low_fuse_val.hex"
avrdude: reading hfuse memory:

Reading | ################################################## | 100% 0.00s

avrdude: writing output file "high_fuse_val.hex"

avrdude: safemode: Fuses OK (H:F3, E:99, L:5E)

avrdude done.  Thank you.
{% endraw %}
{% endhighlight %}

<br />
Next, I got the [Sparkfun bootloader][4] and downloaded it to the chip as follows:

{% highlight sh %}
{% raw %}
$ avrdude -c usbtiny -p m32u4 -U flash:w:Caterina-promicro16.hex

avrdude: AVR device initialized and ready to accept instructions

Reading | ################################################## | 100% 0.00s

avrdude: Device signature = 0x1e9587
avrdude: NOTE: "flash" memory has been specified, an erase cycle will be performed
         To disable this feature, specify the -D option.
avrdude: erasing chip
avrdude: reading input file "Caterina-promicro16.hex"
avrdude: input file Caterina-promicro16.hex auto detected as Intel Hex
avrdude: writing flash (32762 bytes):

Writing | ################################################## | 100% 0.00s

avrdude: 32762 bytes of flash written
avrdude: verifying flash memory against Caterina-promicro16.hex:
avrdude: load data flash data from input file Caterina-promicro16.hex:
avrdude: input file Caterina-promicro16.hex auto detected as Intel Hex
avrdude: input file Caterina-promicro16.hex contains 32762 bytes
avrdude: reading on-chip flash data:

Reading | ################################################## | 100% 0.00s

avrdude: verifying ...
avrdude: 32762 bytes of flash verified

avrdude: safemode: Fuses OK (H:F3, E:99, L:5E)

avrdude done.  Thank you.
{% endraw %}
{% endhighlight %}

<br />
Now, after unhooking the ISP programmer and connecting the USB cable
to my computer (running OS X), I got:

{% highlight sh %}
{% raw %}
# before plugging in USB
$ ls /dev/tty.*
/dev/tty.Bluetooth-Incoming-Port        /dev/tty.MaheshsJawbone-SPPDev
/dev/tty.Bluetooth-Modem

# after plugging in USB
$ ls /dev/tty.*
/dev/tty.Bluetooth-Incoming-Port        /dev/tty.MaheshsJawbone-SPPDev
/dev/tty.Bluetooth-Modem                        /dev/tty.usbmodem1411
{% endraw %}
{% endhighlight %}

<br />
Yay - it's alive! Now I opened up the Arduino IDE, selected *Arduino
Leonardo* as the board and the above serial port. I put an LED on *D2*
and wrote a blink sketch which also printed debug statements on
*Serial*. To upload the code to the board, I had to hit *upload*, and
then set *RESET* of the chip to *GND* momentarily. And it just worked.

##Acknowledgements

Thanks to **Ayush Sagar** for pointing out to me that the D+/D- wire colors in USB are unreliable!

##References

1. Atmel ATmega32u4 data sheet.
2. Adafruit ATmega32u4 breakout board documentation.
3. Sparkfun ATmega32u4 breakout board documentation.

[1]: https://www.adafruit.com/products/296
[2]: https://www.sparkfun.com/products/11117
[3]: https://github.com/adafruit/Atmega32u4-Breakout-Board
[4]: https://github.com/sparkfun/SF32u4_boards
