---
layout: post
title: A Desk Drawer Protector Using ESP8266
excerpt: "LDR + Sparkfun ESP8266 Thing + IFTTT => protection from desk drawer marauders."
tags: [ESP8266, WiFi, IFTTT, LDR]
categories: [Electronics]
comments: true
modified: 2016-09-02
thumbnail: images/2016/09/ddp-open.jpg
images: images/2016/09/ddp-open.jpg
image:
  feature: header.jpg
---

![desk drawer contents](/images/2016/09/ddp-desk.jpg)

## Introduction

I am slightly (just a teeny bit, I assure you) obsessed with my desk drawer and
the arrangement of the contents therein. When I am in dire need of my
Kuru Toga pencil (sketch emergency) or my Alaskan knife (bear emergency), my
hand knows where to find it - even in the murky darkness of an all-too-common
Bengaluru power outage. Since my desk drawer remains the only place at
home where sightings of scotch tape, a pair of scissors, or a pen that actually
writes - is guaranteed, this sacred space is frequently violated. The marauders who purloin such
precious artifacts vary in ages 3 to 74. I've been threatening to do something
about it for a while, and now the time has come to unleash the power of ESP8266
and IFTTT on this situation.

The goal of the project is as follows:

*When my desk draw is opened, I want a buzzer to sound, and want to get an alert
on my mobile phone. I also want the circuit to consume minimal power.*

Since it's for home use, I decided to use ESP8266 for this project. I had a
*Sparkfun ESP8266 Thing Dev* board lying around, and this seemed like the
perfect excuse to try it out. For mobile alerts, I am using the IFTTT
(If This Then That) service. Let's look at the design.

## Design

The first thing we need is a way of detecting when the desk drawer is opened.
Since it's pitch dark inside a closed drawer, and there's some ambient light
when it opens, an LDR seemed like a decent idea. Since one of the design goals
is to reduce battery consumption, the ESP8266 needs to be in deep sleep most
of the time. I checked out the "light sleep" and gpio pin wakeup options for ESP8266,
but I finally went for the "deep sleep" option, but that requires a LOW pulse
to be sent to the RESET pin. The final circuit I have used is based on the nice
work by GitHub user [chaeplin][2].

![schematic](/images/2016/09/ddp-schematic.png)

Here's how the above circuit works. When the LDR is in the dark, Q1 is Off. As
it comes to light, LDR resistance drops, Q1 gets turns on, generating a HIGH
to LOW pulse at its collector output. This grounds C1, and as it charges via R6, it
generates a HIGH-LOW-HIGH pulse at RESET, causing the ESP8266 to reset and wake up. Q2
ensures that this reset happens only when ESP8266 is in deep sleep, at which
point GPIO16 is pulled HIGH, which turns Q2 ON and allows the reset to happen.

Here's a real test using my trusty Saleae logic analyzer.

![signals](/images/2016/09/ddp-signals.png)

The second signal is the output at the collector of Q1 and the first signal,
at the RESET line. You can see how a HIGH to LOW transition is converted
to a negative pulse.

Note that you will need to adjust the potentiometer to set the threshold
at which Q1 turns on. This will vary with the type of LDR and light levels
in your room.

In addition, we need to drive the buzzer for which I am using another BC548
transistor.

And here's a close-up of the power supply. It's a cheap LiPo charger I got from ebay,
and I am using it with a 600 mAh LiPo battery.

![power supply](/images/2016/09/ddp-batt.jpg)

The battery (also cheap) had the wrong connectors, and the charger had none,
so I had to do some soldering and hot gluing. But it worked, and
I can charge this battery periodically via USB. It even has charging indicator
LEDs.

Next, we need to setup IFTTT.

## IFTTT

To get mobile alerts, I decided to use IFTTT's [Maker channel service][3]. I
created a *recipe* which sends a "desk_drawer_open" notification. Look at
*How to Trigger Events* in the IFTTT website to understand how these events
are sent. To create recipes and receive notifications, you need to sign up
with IFTTT and download their **IF** [mobile app][4].

## Putting it Together

To keep life simple, I just bread-boarded my circuit, and put it in a transparent
plastic box.

![desk draw protector](/images/2016/09/ddp.jpg)

Now, on to the code.

## The Code

To start with, you need to create a file called **mysettings.h** and put it inside
your Arduino project directory. Here's what it should look like:

{% highlight C %}
{% raw %}
const char WiFiSSID[] = "xyz";
const char WiFiPSK[] = "abc";
char MakerIFTTT_Key[] = "kkkkkkkk";
{% endraw %}
{% endhighlight %}

(For the curious, this design is to avoid accidental check-ins that will announce
your WiFi and other credentials to the planet at large. Just put **mysettings.h**
in your .gitignore and you're set.)

Modify the above with your WiFi SSID, password, and your IFTTT Maker key.

Now, let's look at *initHardware()* which sets up the pins:

{% highlight C++ %}
{% raw %}
void initHardware()
{
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, HIGH);

  pinMode(BUZZER_PIN, OUTPUT);
}
{% endraw %}
{% endhighlight %}

Above, we set up output pins for the LED and the buzzer. Note that
for the Sparkfun ESP8266 Thing, the LED turns ON when you send GPIO5 a
LOW signal because of the way the LED is connected. You may need to switch
HIGH/LOW to match the ESP8266 board you are using.

Here's the code that connects the ESP8266 to your WiFi network. This is
mostly from the [Sparkfun tutorial for the ESP8266 Thing][1].

{% highlight C++ %}
{% raw %}
void connectWiFi()
{
  byte ledStatus = LOW;

  // Set WiFi mode to station (as opposed to AP or AP_STA)
  WiFi.mode(WIFI_STA);

  // WiFI.begin([ssid], [passkey]) initiates a WiFI connection
  // to the stated [ssid], using the [passkey] as a WPA, WPA2,
  // or WEP passphrase.
  WiFi.begin(WiFiSSID, WiFiPSK);

  // Use the WiFi.status() function to check if the ESP8266
  // is connected to a WiFi network.
  // make N attempts
  int NA = 10;
  int attempts = 0;
  while ((WiFi.status() != WL_CONNECTED) && attempts++ < NA)
  {
    // Blink the LED
    digitalWrite(LED_PIN, ledStatus); // Write LED high/low
    ledStatus = (ledStatus == HIGH) ? LOW : HIGH;

    yield();
    // Delays allow the ESP8266 to perform critical tasks
    // defined outside of the sketch. These tasks include
    // setting up, and maintaining, a WiFi connection.
    delay(100);
    // Potentially infinite loops are generally dangerous.
    // Add delays -- allowing the processor to perform other
    // tasks -- wherever possible.
  }

  // leave LED on
  digitalWrite(LED_PIN, LOW);
}
{% endraw %}
{% endhighlight %}

In the above code, we make 10 attempts to connect to WiFi before giving up.

Now let's look at the code that posts the alert to IFTTT.

The POST request is already prepared into a string in *setup()*:

{% highlight C++ %}
{% raw %}
// prepare POST request string
 postReqStr += "POST /trigger/";
 postReqStr += MakerIFTTT_Event;
 postReqStr += "/with/key/";
 postReqStr += MakerIFTTT_Key;
 postReqStr += " HTTP/1.1\r\n";
 postReqStr += "Host: maker.ifttt.com\r\n";
 postReqStr += "Content-Type: application/json\r\n";
 postReqStr += "Content-Length:  0";
 postReqStr += "\r\n";
 postReqStr += "\r\n";
}
{% endraw %}
{% endhighlight %}

And the POST happens here:

{% highlight C++ %}
{% raw %}
int postToIFTTT()
{
  // LED turns on when we enter, it'll go off when we
  // successfully post.
  digitalWrite(LED_PIN, HIGH);


  // Now connect to IFTTT
  WiFiClient client;
  if (!client.connect("maker.ifttt.com", 80))
  {
    // If we fail to connect, return 0.
    return 0;
  }

  // finally we are ready to send the POST to the server!
  client.print(postReqStr);
  client.stop();

  // Read all the lines of the reply from server and print them to Serial
  while(client.available()){
    String line = client.readStringUntil('\r');
  }

  // Before we exit, turn the LED off.
  digitalWrite(LED_PIN, LOW);

  return 1; // Return success
}
{% endraw %}
{% endhighlight %}

Above, we use the *WiFiClient* object to make a POST using the string we already
prepared. The result from the server is read back above, but that's only needed
for debugging.

Now, it's time to make some noise. Here's the code that sounds the buzzer.

{% highlight C %}
{% raw %}
// create some havoc with the buzzer
void makeNoise()
{
  analogWrite(BUZZER_PIN, 128);

  // play Jaws music
  for (int i = 0; i < 10; i++) {
    // E6
    analogWriteFreq(1318);
    delay(300);
    // F6
    analogWriteFreq(1397);
    delay(300);
  }
  analogWrite(BUZZER_PIN, 0);
}
{% endraw %}
{% endhighlight %}

Above, we use *analogWrite()* to send a PWM signal to the pin. The note sequence
E6/F6 might found familiar - it's the **minor second** interval used in
the thematic music for the *Jaws* movie. Note that the loudness of the buzzer
varies with the frequency. I did not have a datasheet for my cheap buzzer,
but you should try to look at the frequency response curves for yours.

And finally, here's *loop()* where the action happens:

{% highlight C++ %}
{% raw %}
void loop()
{
  // leave LED on
  digitalWrite(LED_PIN, LOW);
  delay(1000);
  // leave LED off
  digitalWrite(LED_PIN, HIGH);

  // awake here...

  // more annoying noises
  makeNoise();

  // connect to WiFi
  delay(200);
  connectWiFi();
  delay(200);

  // this yield is critical
  yield();

  // post to IFTTT
  postToIFTTT();

  // go to deep sleep
  ESP.deepSleep(0);
  yield();
}
{% endraw %}
{% endhighlight %}

As soon as we enter, we flash the LED once, make some noises, and post
an alert to IFTTT. And then we are off to deep sleep. Whenever the ESP8266 is
reset due to the LDR coming to light, this loop will be executed once, thus
sounding the buzzer and sending the mobile alert. The *yield()* calls above are
important, since they allow the ESP8266 to perform background tasks.

That's about it. Next time an unsuspecting invader opens my desk drawer, they
will be greeted with threatening music from *Jaws*, and I will get an alert
on my mobile phone. MUHUHUHUA!

## Downloads

You can get the complete source code for this project here:

[https://github.com/electronut/desk-draw-protector][5]

## In Action

Here's the desk draw protector in action:

<iframe width="560" height="315" src="https://www.youtube.com/embed/6fRtNdZ-VVY" frameborder="0" allowfullscreen></iframe>


[1]: https://learn.sparkfun.com/tutorials/esp8266-thing-hookup-guide/all
[2]: https://github.com/chaeplin/esp8266_and_arduino/tree/master/_48-door-alarm-deepsleep
[3]: https://ifttt.com/maker
[4]: https://ifttt.com/products
[5]: https://github.com/electronut/desk-draw-protector
