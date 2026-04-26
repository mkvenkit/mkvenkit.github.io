---
title: Making the Raspberry Pi Speak
date: 2013-07-05 16:31:20.000000000 +05:30
description: Making the Raspberry Pi Speak
featured_image: "/images/2013/07/photo.jpg"
tags:
- audio
- Python
- pyttsx
- Raspberry Pi
- speech
categories:
- Raspberry Pi
---
<p style="padding: 20px;">
<img src="{{ site.baseurl }}/images/2013/07/photo.jpg"/>
</p>
<p>This is a short post on getting audio setup on my Raspberry Pi and then making it speak. </p>
<p><!--more--></p>
<p>For the audio setup, I followed instructions on this website:</p>
<p><a href="http://cagewebdev.com/index.php/raspberry-pi-getting-audio-working/">http://cagewebdev.com/index.php/raspberry-pi-getting-audio-working/</a></p>
<p>After the above steps, the first time I plugged in a pair of powered speakers to the Pi, I got a whole bunch of "journal" errors from the kernel. Luckily, they went away after a reboot. I have to live with the fact that installing stuff on Linux will always be a "transcendental" experience for me. ;-)</p>
<p>To test audio, you can try:</p>
<p><code>aplay /usr/share/sounds/alsa/*<br />
</code></p>
<p>Once you are happy with this, the next step is to install <strong>pyttsx</strong>, which is a Python text-to-speech library. You can install it as follows:</p>
<p><code>wget https://pypi.python.org/packages/source/p/pyttsx/pyttsx-1.1.tar.gz<br />
gunzip pyttsx-1.1.tar.gz<br />
tar -xf pyttsx-1.1.tar<br />
cd pyttsx-1.1/<br />
sudo python setup.py install</code></p>
<p>In addition to the above, I also needed to install <strong>espeak</strong>, which I did as follows:<br />
<code><br />
sudo apt-get install espeak</code></p>
<p>Now, to get some quality speech out of our Pi. Try the Python code below:</p>
<p><script src="https://gist.github.com/electronut/5933641.js"></script></p>
