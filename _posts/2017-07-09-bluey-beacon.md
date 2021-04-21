---
layout: post
title: Bluey Beacon - Building a Nordic nRF52832 BLE IoT Sensor Beacon
excerpt: "Sending sensor data in Advertisement Packets using Nordic nRF52832."
tags: [nRF52832, Nordic, BLE, beacon, sensor, python, GCC, Embedded]
categories: [Electronics]
comments: false
modified: 2017-07-09
thumbnail: images/2017/06/bluey-beacon.png
images: images/2017/06/bluey-beacon.png
---

![STM32](/images/2017/06/bluey-beacon.png)

## A BLE Beacon

In this project, we're going to build a BLE Beacon that transmits temperature,
humidity and ambient light levels to a dashboard on the internet.

Bluetooth Low Energy (BLE) is a technology that was designed from the ground up
to reduce power consumption. It's common for BLE devices to keep going and going
(like our pink furry friend) for months on a coin cell battery. A **beacon** is a
typical example of such a device. All it does is wake up periodically, send
data, and go back to sleep. There are different methods of connecting to a BLE device.
In the case of the beacon, typically a **non-connectable** mode is used, either
as **ADV_NONCONN_IND** or **ADV_SCAN_IND**. For our beacon, we will be using the
first of these methods. The two methods are compared in the graphic below:

![BLE adv](/images/2017/06/ble-adv.png)

So we'll be sending sensor data in the advertisement packets, and there will
be no scan response from the device.

So how we get this sensor data on to the internet? For that we'll use a Raspberry
Pi 3 as a gateway. As you will see below, a Python script will grab the advertisement
packets, parse the sensor data and use a combination of **dweet.io** and **freeboard.io**
to post this data on the web.

Now, let's look at the hardware.

## Hardware

We'll be building the beacon using the [Bluey][1] nRF52832 development board,
which comes built-in with accelerometer/gyroscope, temperature/humidity, and
ambient light sensors. Although the code here is specific to this board, you
can easily replicate this project using any nRF52 board with similar sensors - just
change the code that gets data from your specific sensors. If you want to use
Bluey though, it's available for purchase on [our Tindie store][3].

## Firmware

We'll be using the Nordic nRF 5 SDK (version 12.2.0) to develop the firmware on
nRF52832. I won't cover SDK, toolchain and code upload here. But please [check out
the other articles][4] I have written on Nordic nRF BLE development for details.

Nordic has a bunch of great examples in their SDK, and a good place to start for
our beacon project is the **ble_app_beacon** project in the **examples/ble_peripheral**
directory.

Here's our main loop:

<script src="https://gist.github.com/electronut/89177095e6ae404a70a103ff25ac6051.js"></script>

The above code goes through initializing the BLE stack, advertising, and timers. Next,
it initializes TWI (I2C) for communicating with the sensors, and calls the initialization
code for the temperature/humidity and ambient light sensors.

In the main loop, all the code does is the following: if a flag is true, set the advertising
data, reset the flag, and go to sleep.

The **g_setAdvData** flag is set up as follows:

<script src="https://gist.github.com/electronut/9e9fa0021d6ad9842604de7782276d0a.js"></script>

In a timer, we periodically set this flag, which is then checked in the main loop and
the advertisement packet sent. Before we look at how the data is sent, let's look at
how advertisement is setup.

Here's the definition for **advertising_init()**:

<script src="https://gist.github.com/electronut/72410bcc0cea24ae65e85c8757f4c08a.js"></script>

As you can see above, we are using the **BLE_GAP_ADV_TYPE_ADV_NONCONN_IN** mode for
this project. Non-connectable indication only (no scanning) advertisement.

All action happens in **set_adv_data()**:

<script src="https://gist.github.com/electronut/4a2343858c7cf7159bc7a6330ece0f41.js"></script>

The **init** flag above is used so that we don't try to read sensors before they are initialized.
The main thing to understand above is that we are packing off custom sensor data in the
**manuf_data.data.p_data** field. At the receiving end, we have to unpack and put the data together
in the same order, as we will see.

So at this point our firmware is ready, the beacon is sending advertising packets containing
sensor data periodically. Now we need to pick up this data.

## Software

On the receiving side, we're going to use a Raspberry Pi 3. Assuming you have [set up your Pi][5],
the next (required) step is to install the [BlueZ][6] - the official Linux bluetooth stack.

### Crash Course on BlueZ BLE

BlueZ is a complex, powerful set of tools and delving into it is beyond the scope of this post. Unfortunately, even the official page seems to have no proper documentation. My own (shaky) understanding came from bits and pieces I put together from various websites.

Here's a taste of how BlueZ BLE tools work on the Pi - we're running the tools
to scan BLE data from our beacon, and all this is on a Raspberry Pi 3 which has
built-in WiFi and Bluetooth/BLE.

First, we run **hcidump** to listen in on incoming raw BLE data:

<p>
<pre>
pi@raspberrypi:~ $ sudo hcidump --raw
HCI sniffer - Bluetooth packet analyzer ver 5.43
device: hci0 snap_len: 1500 filter: 0xffffffff
</pre>
</p>

Then, we run **hcitool** to scan for BLE devices. Run this in a separate xterm.

<p>
<pre>
pi@raspberrypi:~ $ sudo hcitool lescan
LE Scan ...
E2:91:9F:03:C5:0D bluey
</pre>
</p>

You can see that **hcitool** is seeing our beacon. At the same time, you'll
see a stream of new data in the **hcidump** window:

<p>
<pre>
< 01 0B 20 07 01 10 00 10 00 00 00
> 04 0E 04 01 0B 20 00
< 01 0C 20 02 01 01
> 04 0E 04 01 0C 20 00
> 04 3E 2B 02 01 03 01 0D C5 03 9F 91 E2 1F 03 19 00 00 02 01
  04 10 FF FF FF 66 60 D2 7C 02 E3 00 AE A9 B1 B2 B3 B4 06 08
  62 6C 75 65 79 CF

</pre>
</p>

The last three lines of data are what we are concerned about. **62 6C 75 65 79**
above - looks familiar? Those are the ASCII hex codes for 'b', 'l', 'u', 'e', 'y' -
"bluey" - the device name we used in **set_adv_data()** above.

The sensor data is in the following bytes:

<p>
<pre>
1F 03 19 00 00 02 01 04 10 FF FF FF 66 60 D2 7C 02 E3 00 AE A9 B1 B2 B3 B4
</pre>
</p>

All we need to do is parse this data. So, instead of doing all this manually,
we're going to write a Python script that will run the BlueZ tools and grab this
data for us.

### Scanning the beacon data and Posting it

Now, lets look at the Python code that sets up the BlueZ tools:

<script src="https://gist.github.com/electronut/180b2b75fc047bd6d330a03786bb1ef4.js"></script>

In the above code, we create a class that will help us create two processes - **hcidump**
and **hcitool**, and parse the data from the **hcidump** output.

Here's the main loop in the code:

<script src="https://gist.github.com/electronut/7b1132d121520555e631dff40e4e3d79.js"></script>

In the above code, we're first filtering against a MAC address and also checking for
the "bluey" string in the advertisement data. If that matches, then we parse the sensor data.

OK, now have the sensor data, how do we get this on to the web? In this project,
we're going to use a combination of **dweet.io** and **freeboard.io** to achieve
this.

To be honest, this New Age, Webby way of doing things seems overcomplicated to
me. Many of these IoT dashboard services which started off as free have now started
charging (naturally) and many of the free ones look awful, or have inconvenient restrictions.
But the good news is that you have the sensor data on a Pi and you can send it wherever you want -
display it on the Pi, or build your own dashboard - if you have the time and
the inclination.

Anyway, the idea here is that you make a web request to a unique **dweet** URL,
and set that as the datasource in **freeboard**. Thus your sensor data ends up
in the dashboard. If you want a graph of historic data, you need to use their paid
services. So we are just displaying real-time data here.

Here's the code for parsing the sensor data:

<script src="https://gist.github.com/electronut/4e8f04ee20116d6c25cb701ece7a9f1a.js"></script>

We're just unpacking the data in the same format as was set in the **set_adv_data()** call
in the firmware.

Here's what the dashboard looks like:

![dashboard](/images/2017/06/beacon-dashboard.png)

## Enclosure

Since we want to hand the beacon on a wall some place, we'll also design a simple enclosure
for it, which can be laser cut. Here's what the design looks like - it was designed using **Inkscape**.

<img alt="enclosure design" src="/images/2017/06/beacon-enclosure.png" style="width:400px;"/>

The above design is for 3 mm thick acrylic.

Here's what the final enclosure looks like:

<img alt="enclosure" src="/images/2017/06/beacon-enclosure2.jpg" />

Although you see a coin cell above, I recommend using a 3.7 V LiPo battery instead - that will last
much longer.

## Downloads

All code and design files for this project can be found at the github repository
below. Navigate to the **code/bluey-beacon** directory. The firmware is in the **bluey-beacon-nrf52**
directory. Note that the the beacon code
depends on code in the **code/bluey-common** directory - so follow installation instructions in
**code/README.md**.

[https://github.com/electronut/electronutlabs-bluey][2]

[1]: http://electronut.in/bluey/
[2]: https://github.com/electronut/electronutlabs-bluey
[3]: https://www.tindie.com/products/ElectronutLabs/bluey-nrf52832-ble-development-board/
[4]: https://www.google.co.in/search?q=nrf+site:http://electronut.in
[5]: https://www.raspberrypi.org/documentation/
[6]: http://www.bluez.org/
