---
layout: post
title: A Simple IoT Project with the ESP8266 WiFi module
excerpt: "Plotting LM35 temperature data on ThingSpeak with an Arduino and ESP8266 WiFi module."
tags: [ESP8266, WiFi, IoT, Internet Of Things, Arduino, LM35, ThingSpeak]
categories: [Arduino, Circuits]
comments: true
modified: 2016-09-02
thumbnail: images/2014/12/esp8266-arduino-hookup.jpg
images: images/2014/12/esp8266-arduino-hookup.jpg
---

![ESP8266 v01](/images/2014/12/esp8266-v01.jpg "ESP8266 V01 WiFi Module")
<br />
<br />

<hr/>
<hr/>
## Note

This is one of my older ESP8266 articles. Please check out my more recent
ESP8266 projects below:

- [A Desk Drawer Protector Using ESP8266][8]
- [An ESP8266 IoT Temperature Monitor for my Balcony Garden][9]
<hr/>
<hr/>

### The ESP8266 WiFi Module

The ESP8266 is a WiFi module that costs less than 5 USD. This makes
putting your sensors on the net actually feasible. (Hooking up the $75
Arduino Yun to each of your sensors - not no feasible.) There's a lot
of excitement about this sensor on the Internet currently, and people
have done an amazing job deciphering the obscure command structure of
this device that comes from China. There seems to be three ways of
using this module, in order of increasing complexity:

1. Sending it *AT* commands from a computer via an USB to serial
adapter. This is mostly useful for testing and setup.
2. Interfacing with an Arduino or any other microcontoller and using
this board as a peripheral.
3. Programming the module directly and use its GPIO pins to talk to
your sensors, eliminating the need for a second controller.

I've explored options #1 and #2 above, and that's what I'll be talking
about here. If you are new to this whole thing, I recommend that you
watch [this video from Great Scott Labs][2] first.

### Setting up the ESP8266

The first thing you want to do with ESP8266 (as with any aliens) is to
establish communication. For this, you hook up a USB to TTL adapter to
the module, and talk to it using a serial port terminal application
like [CoolTerm][7]. One thing to be careful about when you hook up this
module is to remember that this module operates at 3.3 V - even the
serial lines should not exceed this voltage. So here is how I hooked
up my ESP8266:

<br />
<br />
![ESP8266 circuit](/images/2014/12/esp8266-circuit.jpg)
<br />
<br />

In the above circuit, you can see that I used a 3.3 V regulator to
power the board, and a resistor dividor on the RX line to keep the
voltages on spec. The sessions below use *CoolTerm*. My board worked
with a baud rate of 9600, since its firmware was already upgraded to
0.9.2.2. You may need to try other baud rates - 115200, for instance.

{% highlight HTML %}
{% raw %}
þ<..þ...,.(.....û..ÿ
[System Ready, Vendor:www.ai-thinker.com]
{% endraw %}
{% endhighlight %}

Now, you can send it *AT* commands. You can see the full command
reference [here][3]. First let's send "AT":

{% highlight HTML %}
{% raw %}
AT


OK
{% endraw %}
{% endhighlight %}

Now let's get the firmware version:

{% highlight HTML %}
{% raw %}
AT+GMR

0018000902

OK
{% endraw %}
{% endhighlight %}

Now, let's get the operation mode.

{% highlight HTML %}
{% raw %}
AT+CWMODE?

+CWMODE:3

OK
{% endraw %}
{% endhighlight %}

*3* implies that we are in Standalone + Access Point mode. That's
 fine. Now, let's do something fun. Let's list all the available WiFi
 access points.

{% highlight HTML %}
{% raw %}
AT+CWLAP

+CWLAP:(0,"Cisco15010-guest",-84,"ce:d7:19:0b:80:19",1)
+CWLAP:(4,"TRENDnet",-86,"c8:d7:19:0b:80:19",1)
+CWLAP:(2,"ASingh",-87,"00:25:5e:c5:d1:88",1)
+CWLAP:(4,"HMMA",-66,"80:ea:96:f1:27:7a",11)
+CWLAP:(4,"dlink-30B8",-91,"c8:d3:a3:6e:30:b8",6)
+CWLAP:(4,"Deepak Mullick",-93,"80:a1:d7:77:a1:e4",6)
+CWLAP:(1,"MGMNT",-91,"80:a1:d7:77:a1:e5",6)
+CWLAP:(3,"rajat_linksys",-67,"20:aa:4b:31:43:9d",6)
+CWLAP:(2,"smk385",-89,"00:1f:33:bc:02:f6",6)
+CWLAP:(4,"Apoorv",-91,"ec:1a:59:17:53:93",7)
+CWLAP:(3,"AkhIshir",-88,"08:60:6e:cb:63:b0",11)
+CWLAP:(2,"sunil",-77,"94:d7:23:f5:fc:34",9)
+CWLAP:(1,"MGMNT",-77,"94:d7:23:f5:fc:35",9)
+CWLAP:(1,"Tanu",-92,"00:1d:7e:1e:68:4e",11)

OK
{% endraw %}
{% endhighlight %}

Now let's connect to my WiFi network.

{% highlight HTML %}
{% raw %}
AT+CWJAP="HMMA","NOTTELLINGMYPASSWD"


OK
{% endraw %}
{% endhighlight %}

Now, let's check if we actually got an IP address:

{% highlight HTML %}
{% raw %}
AT+CIFSR

192.168.4.1
192.168.4.10

OK
{% endraw %}
{% endhighlight %}

Whoohoo! We are on the network. We'll actually make use of the
Internet in the next section. Also, the above settings are now
actually stored in the module. Even if you power it on and off, it
will connect automatically to this network.

At this point, you can upgrade the firmware if you want. I used [this
Python script][5]. You can read about the process at the
[electrodragon][3] web page.

### LM35 Temperature Plot using an Arduino

Now that we have put the module on the network, let's make use of it
by creating a small IoT (Internet of Things) device. I had written [a
previous post][6] on plotting sensor data on ThingSpeak. This time,
I'll use an LM35 temperature sensor. I'll talk to the ESP8266 using an
Arduino Mini Pro clone. Here's what the LM35 looks like:

<br />
<br />
![LM35](/images/2014/12/LM35.jpg)
<br />
<br />

In the code below, I use the *SoftwareSerial* library to talk to the
ESP8266. I use the hardware *Serial* for debugging. (You could try the
opposite.) I also assume that the ESP8266 is already setup to connect
to the WiFi network.

{% highlight C++ %}
{% raw %}

// esp8266_test.ino
//
// Plot LM35 data on thingspeak.com using an Arduino and an ESP8266 WiFi
// module.
//
// Author: Mahesh Venkitachalam
// Website: electronut.in

#include <SoftwareSerial.h>
#include <stdlib.h>

// LED
int ledPin = 13;
// LM35 analog input
int lm35Pin = 0;

// replace with your channel's thingspeak API key
String apiKey = "T2RJXWQAVXG4ZV39";

// connect 10 to TX of Serial USB
// connect 11 to RX of serial USB
SoftwareSerial ser(10, 11); // RX, TX

// this runs once
void setup() {                
  // initialize the digital pin as an output.
  pinMode(ledPin, OUTPUT);    

  // enable debug serial
  Serial.begin(9600);
  // enable software serial
  ser.begin(9600);

  // reset ESP8266
  ser.println("AT+RST");
}


// the loop
void loop() {

  // blink LED on board
  digitalWrite(ledPin, HIGH);   
  delay(200);               
  digitalWrite(ledPin, LOW);

  // read the value from LM35.
  // read 10 values for averaging.
  int val = 0;
  for(int i = 0; i < 10; i++) {
      val += analogRead(lm35Pin);   
      delay(500);
  }

  // convert to temp:
  // temp value is in 0-1023 range
  // LM35 outputs 10mV/degree C. ie, 1 Volt => 100 degrees C
  // So Temp = (avg_val/1023)*5 Volts * 100 degrees/Volt
  float temp = val*50.0f/1023.0f;

  // convert to string
  char buf[16];
  String strTemp = dtostrf(temp, 4, 1, buf);

  Serial.println(strTemp);

  // TCP connection
  String cmd = "AT+CIPSTART=\"TCP\",\"";
  cmd += "184.106.153.149"; // api.thingspeak.com
  cmd += "\",80";
  ser.println(cmd);

  if(ser.find("Error")){
    Serial.println("AT+CIPSTART error");
    return;
  }

  // prepare GET string
  String getStr = "GET /update?api_key=";
  getStr += apiKey;
  getStr +="&field1=";
  getStr += String(strTemp);
  getStr += "\r\n\r\n";

  // send data length
  cmd = "AT+CIPSEND=";
  cmd += String(getStr.length());
  ser.println(cmd);

  if(ser.find(">")){
    ser.print(getStr);
  }
  else{
    ser.println("AT+CIPCLOSE");
    // alert user
    Serial.println("AT+CIPCLOSE");
  }

  // thingspeak needs 15 sec delay between updates
  delay(16000);  
}

{% endraw %}
{% endhighlight %}

In the code above, I read the analog pin, compute the temperature,
and send that information to a ThingSpeak channel via a *GET* request.

Here is how the circuit is hooked up. I am using a cheap Arduino Pro
Mini clone for this experiment, and the battery is a rechargeable one
meant for charging cell phones.

<br />
<br />
![ESP8266 Arduino LM35](/images/2014/12/esp8266-arduino-hookup.jpg)
<br />
<br />

<br />
And here is the plot at [thingspeak.com][4]:

<br />
<br />
![LM35 ThingSpeak Plot](/images/2014/12/LM35-plot.jpg "LM35 ThingSpeak Plot")
<br />
<br />


### Conclusion

I think this module is great value for the money. A very practical way
of putting your sensors on the Internet. Although this module can be
programmed directly, I'll probably just use it as a peripheral due to
the ease of using it that way.

### References

1. A [nice introductory video][2] from Great Scott Labs about the ESP8266.
2. [Seeed Studio article][1] on Getting Started with ESP8266.
3. [electrodragon's web page][3] on the ESP8266.
4. [ThingSpeak][4] website.
5. My small project on [using ThingsSpeak][6] to plot sensor data.
6. *esptool.py* - [a Python script][5] to update firmware.
7. [CoolTerm][7] - nice serial terminal software.

[1]: http://www.seeedstudio.com/blog/2014/09/11/getting-started-with-esp8266/
[2]: https://www.youtube.com/watch?v=9QZkCQSHnko&app=desktop
[3]: http://www.electrodragon.com/w/Wi07c
[4]: https://thingspeak.com
[5]: https://github.com/themadinventor/esptool/
[6]: http://electronut.in/dht11-rpi-cloud-plot/
[7]: http://freeware.the-meiers.org/
[8]: http://electronut.in/esp8266-desk-draw-protector/
[9]: http://electronut.in/IoT-temp-sensor/
