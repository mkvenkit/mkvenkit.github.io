---
layout: post
title: Plotting DHT11 sensor data at ThingSpeak.com using Raspberry Pi Model A+
excerpt: "A small Internet Of Things experiment in which I plot sensor data from a Raspberry Pi on ThingSpeak."
tags: [DHT11, temperature, humidity, sensor, plot, cloud, IOT, Internet Of Things, Raspberry Pi, thingspeak.com, python]
categories: [Raspberry Pi]
comments: true
modified: 2014-12-14
thumbnail: images/2014/12/thingspeak-stream.jpg
images: images/2014/12/thingspeak-stream.jpg
---

![sensor data](/images/2014/12/thingspeak-stream.jpg "ThingsSpeak.com Plot")

### Internet Of Things

Feeling left behind, I too want to get on board the *Internet Of
Things* bandwagon by putting a sensor on the net. For this experiment,
I decided to attach a DHT11 Temperature/Humidity sensor to a Raspberry
Pi Model B+ and use [thingspeak.com][2] to plot the data.  I also
looked at *data.sparkfun.com* which offers a similar service, but it
doesn't actually plot your data.

### ThingSpeak

ThingSpeak is an "open data platform for the Internet Of Things". To
get started, you need to create a *channel* that specifies what you
are plotting - title, range, number of fields, etc. You then update
data in your channel with an HTTP request of the form:

{% highlight html %}
{% raw %}
https://api.thingspeak.com/update?api_key=YOUR_CHANNEL_API_KEY&field1=99
{% endraw %}
{% endhighlight %}

The data stream itself can be viewed at the following URL:

{% highlight html %}
{% raw %}
https://api.thingspeak.com/channels/YOUR_CHANNEL_ID
{% endraw %}
{% endhighlight %}

ThingSpeak provides a lot of options for displaying your channel's
data - make it public/private, changing extents, layouts, etc. The
only limitation is the rate of data updates - it has to be no more
frequent than *15 seconds*. But the whole software is Open Source,
which means you could host it on your own if you need faster updates.

### Raspberry Pi and DHT11

I've written before about the DHT11 sensor [here][1]. Here is how I
connected it to Raspberry Pi:

<br/>
<br/>
![sensor data](/images/2014/12/dht11-rpi-circuit.jpg "RPi DHT-11 Circuit")
<br/>
<br/>

Here is how it looks on a breadboard:

<br/>
<br/>
![sensor data](/images/2014/12/rpi-dht11-hookup.jpg "RPi DHT-11 Breadboard")
<br/>
<br/>

Now we need to connect this to the internet.

### The Code

I used Python to communicate with the DHT11 sensor and put the data on
ThingSpeak. To talk to the sensor, I used the [Adafruit DHT
Library][3]. Here is the code, and the output from ThingSpeak is what
you saw at the beginning of this article.

{% highlight python %}
{% raw %}
"""
dht11_thingspeak.py

Temperature/Humidity monitor using Raspberry Pi and DHT11.
Data is displayed at thingspeak.com

Author: Mahesh Venkitachalam
Website: electronut.in

"""

import sys
import RPi.GPIO as GPIO
from time import sleep  
import Adafruit_DHT
import urllib2

def getSensorData():
    RH, T = Adafruit_DHT.read_retry(Adafruit_DHT.DHT11, 23)
    # return dict
    return (str(RH), str(T))

# main() function
def main():
    # use sys.argv if needed
    if len(sys.argv) < 2:
        print('Usage: python tstest.py PRIVATE_KEY')
        exit(0)
    print 'starting...'

    baseURL = 'https://api.thingspeak.com/update?api_key=%s' % sys.argv[1]

    while True:
        try:
            RH, T = getSensorData()
            f = urllib2.urlopen(baseURL +
                                "&field1=%s&field2=%s" % (RH, T))
            print f.read()
            f.close()
            sleep(15)
        except:
            print 'exiting.'
            break

# call main
if __name__ == '__main__':
    main()

{% endraw %}
{% endhighlight %}

You run it by uploading it to your Pi and doing:

{% highlight sh %}
{% raw %}
sudo python dht11_thingspeak.py YOURWRITEAPIKEY
{% endraw %}
{% endhighlight %}

### Conclusion

I was looking for a quick way to put sensor data on the Internet, and
ThingSpeak fits the bill. And now I can claim to be part of the IOT
buzz. ;-)

[1]: http://electronut.in/talking-to-dht11-humidity-temperature-sensor/
[2]: https://thingspeak.com/docs
[3]: https://github.com/adafruit/Adafruit_Python_DHT
