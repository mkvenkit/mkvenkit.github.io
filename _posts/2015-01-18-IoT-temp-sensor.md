---
layout: post
title: An ESP8266 IoT Temperature Monitor for my Balcony Garden
excerpt: "An Internet of Things (IoT) device that plots temperature data on thingspeak.com using an ESP8266 WiFi module, an Ardunino Pro Mini clone, and an LM35 sensor.."
tags: [LM35, ESP8266, Arduino, IoT, temperature, sensor, WiFi]
categories: [Circuits]
comments: true
modified: 2016-09-02
thumbnail: images/2015/01/iot-device.jpg
images: images/2015/01/iot-device.jpg
---

![IoT sensor](/images/2015/01/iot-device.jpg "IoT Temperature Sensor")
<br />
<br />

I had previously written about using the ESP8266 WiFi module to make
an Internet Of Things [(IoT) device that plots temperature data][1] on
the web, at *thingspeak.com*. That was a mess of wires on a
breadboard. I have now refined this project - simplified some
components, put them on a PCB, given some thought to saving battery
life, as well as built a laser-cut enclosure for the device, which is
now installed in my balcony garden.

The schematic for the device is below. I am using the "01" version of
the ESP8266 WiFi module here. I am also using a 3.3 V version of the
Arduino Pro Mini (or a clone in my case) to talk to the ESP8266, since
the latter works at this voltage and I don't need to worry about
shifting voltage levels from 5V to 3.3V. As before, I am using an LM35
temperature sensor, and I use an Arduino analog pin (ADC) to read
it. The whole thing is powered by a 9V battery. An LD33 3.3V
regulator takes care of the supply to the ESP8266, and since the
Arduino has a built in regulator, I can directly connect 9V to the
*RAW* pin. For conserving battery life, I do the following:

1. Take a temperature reading every 10 minutes.
2. Plot it on thingspeak.com.
3. Put the Arduino to deep sleep using a watchdog timer. (I use the [Narcoleptic library][4] for this purpose.)
4. Use the *CH_PD* pin of the ESP8266 for disabling the chip when not needed, using a *digitalWrite* on the Arduino.

I also use the *SoftwareSerial* library on the Arduino to communicate
with the ESP8266. That way I can keep the hardware serial pins
connected to the USB to TTL adapter and use it for debugging. But you
could do the opposite.

I also assume here that the ESP8266 module has been setup to connect
to your WiFi network. I've covered this part in my [previous
post][1]. The *SSID* and password are stored on the ESP8266 once you
set it up, and you don't have to keep sending that information in your
Arduino code.

<br />
<br />
![LM35 IoT Circuit](/images/2015/01/LM35-IoT-circuit.png "LM35 IoT Circuit")
<br />
<br />

Here is the Arduino code.

{% highlight C++ %}
{% raw %}

// lm35_iot.ino
//
// Plot LM35 data on thingspeak.com using an Arduino Pro Mini
// and an ESP8266 WiFi module.
//
// Author: Mahesh Venkitachalam
// Website: electronut.in

#include <SoftwareSerial.h>
#include <stdlib.h>
#include <Narcoleptic.h>

// LED
int ledPin = 13;
// LM35 analog input
int lm35Pin = 0;
// ESP8266 chip enable
int chipEnablePin = 2;

// replace with your channel's thingspeak API key
String apiKey = "T2RJXWQAVXG4ZV39";

// connect 10 to TX of ESP8266
// connect 11 to RX of ESP8266
SoftwareSerial ser(10, 11); // RX, TX

// this runs once
void setup() {                
  // set outputs
  pinMode(ledPin, OUTPUT);    
  pinMode(chipEnablePin, OUTPUT);    

  // enable debug serial
  Serial.begin(9600);
  // enable software serial
  ser.begin(9600);

  // reset ESP8266
  ser.println("AT+RST");
}

// the loop
void loop() {

  // enable ESP8266
  digitalWrite(chipEnablePin, HIGH);   

  // reset ESP8266
  ser.println("AT+RST");

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
  // So Temp = (avg_val/1023)*3.3 Volts * 100 degrees/Volt
  float temp = val*33.0f/1023.0f;

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

  // this delay is required before disabling the ESP8266 chip
  delay(1000);

  // disable ESP8266
  digitalWrite(chipEnablePin, LOW);   

  // deep sleep
  nsleep(10);
}

// utility method for deep sleep:
// Narcoleptic.delay deosn't seem to work for large values
void nsleep(int nMinutes) {
  for (int i = 0; i < 3*nMinutes; i++) {
    Narcoleptic.delay(20000);
  }
}

{% endraw %}
{% endhighlight %}

For enclosure, I designed a T-slot based acrylic box using the
[Inkscape T-Slot Boxmaker plugin][3]. It uses *M2x10* hex screws and
has slots for the LM35, PCB spacer, as well as one for hanging the box on a
nail. The acrylic thickness is 3 mm. Here's what it looks like:

<br />
<br />
![IoT Enclosure](/images/2015/01/temp-monitor-enclosure.png "Enclosure Design")
<br />
<br />

I built the circuit on a general purpose PCB. Here's what it looks
like in the process of assembly. (Thanks to my pal Ravi for getting
the enclosure laser cut quickly!)


<br />
<br />
![IoT Assembly](/images/2015/01/laser-cut-enclosure.jpg "IoT Device Assembly")
<br />
<br />

Here is what the device looks, hanging out on my balcony:

<br />
<br />
![IoT balcony](/images/2015/01/balcony.jpg "IoT in the Balcony")
<br />
<br />

This is what the plot looks like after a night of data collection:

<br />
<br />
![IoT thingspeak](/images/2015/01/iot-thingspeak.png "thingspeak.com plot")
<br />
<br />


[Click here][5] for a live feed of temperature data from my balcony garden.

<br />

You can find all the necessary files for this project at my [github link here][2].

[1]: http://electronut.in/an-iot-project-with-esp8266/
[2]: https://github.com/electronut/LM35-ESP8266-IoT
[3]: http://wyolum.com/t-slot-boxmaker/
[4]: https://code.google.com/p/narcoleptic/
[5]: https://thingspeak.com/channels/21281
