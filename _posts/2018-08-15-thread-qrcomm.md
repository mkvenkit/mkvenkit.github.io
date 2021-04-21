---
layout: post
title: "Nordic nRF52840 QR Code based Thread Commissioning"
excerpt: "Nordic nRF52840 QR Code based Thread Commissioning on the Raspberry Pi Border Router using camera on the Pi."
tags: [Thread, OpenThread, nRF52840, Nordic, QR code, commissioning]
categories: [Electronics, programming]
comments: false
modified: 2018-08-16
thumbnail: /images/2018/thread-qrcomm/thread-qrcomm.jpg
images: /images/2018/thread-qrcomm/thread-qrcomm.jpg
---

## Introduction

I recently wrote about using [Thread and MQTT-SN on the Nordic nRF52840][2] 
multiprotocol SoC. One thing I did not cover in detail is *Thread 
Commisioning* - a secure process by which a device joins a Thread network. I 
side-stepped the process by passing the network credentials directly to the 
device using the [Thread CLI][3].

There are different types of commissioning, and Thread has a Mesh 
Commisioning Protocol (MeshCop) to facilitate this process. In [On-mesh commissioning][4], 
a node which is part of the network, which has the 
required credientials, adds the *joiner* to the network. [External commissioning][5], on the 
other hand, uses a device outside the Thread network, like a mobile phone, to add new nodes to the network.

The [Thread Group][6] provides a mobile app for external commissioning. Unfortunately 
we found it to be very unstable (crashed on three different Android phones), and it's 
for Android only in any case. I wish the Thread Group would either release the source 
code for this app or build a stable cross-platform solution. But since we don't want to wait 
around for that to happen, I thought - Why not use a camera on the Raspberry Pi itself 
to do the commissioning?

But before we get to the Pi, let's talk about how to generate QR codes for 
Thread commissioning.

## Preparing QR Codes for Thread Commissioning

The QR code commissioning works by encoding the *Joining Device Credential* and the 
*EUI-64* of the device into an image. The scanning device parses this information 
and passes it to the external commissioner. The *Joiner Device Credential* from the 
Thread specification, is:

*a device-specific string of all uppercase alphanumeric characters 
(0-9 and A-Y, excluding I, O, Q and Z for readability), with a length between 
6 and 32 characters*

The *EUI-64* is a 64 bit unique identifier for the device. For nRF52840, it's the 
MAC ID (which is actually 48 bits).

The QR code is generated using a string of the following form:

<pre>
v=1&&eui=2b749b2cc8427dd7&&cc=ENUT02
</pre>
<br>

You can use an [online tool][7] to generate the QR code - just use the above 
string in the *URL* field. Print it out, and you have your commissioning weapon ready.

By the way, you can get the *EUI-64* of your device very conveniently by 
opening up a serial terminal and using the Thread CLI.

<pre>
> eui64
2b749b2cc8427dd7
Done
</pre>
<br>

## Reading QR Code on the Raspberry Pi

Now that you have the QR code, how do you read it on the Pi? The goodwill 
of open source developers come to the rescue again, in the form of [ZBar][8].

Here's how you install it:

<pre>
sudo apt-get install zbar-tools
</pre>
<br>

Now in order for the above to work (it looks for *dev/video0*), you need enable 
a module on the Pi.

<pre>
sudo rpi-update
sudo modprobe bcm2835-v4l2
</pre>
<br>

To ensue that this is done every time the Pi boots, you can add *bcm2835-v4l2* to 
*/etc/modules*.

<hr>
**Note**

The Nordic Raspberry Pi border image does not come with any GUI. (An 
unnecessary omission, making it difficult to use). So in order to understand *zbar-tools*, 
I ended up testing it with a Pi installation with proper GUI. But you don't have to 
go through that necessarily.
<hr>

No test out *zbar-tools* on the Pi as follows:

<pre>
zbarcam --prescale=640x480
</pre>
<br>

This is what you will see:

![zbarcam](/images/2018/thread-qrcomm/zbarcam.jpg)

The program will continuously try to detect and print out the decoded strings from 
QR codes in the camera stream. The *prescale* option is needed because without it, 
the detection is too slow to be useful.

## QR Code Commissioning 

So now we know how to parse the QR codes. Now let's write a Python program to 
use this information for commissioning.

<pre>
def main():
  # start zbarcam process
  proc = subprocess.Popen(['zbarcam','--nodisplay', '--prescale=640x480'],
	  stdout=subprocess.PIPE)
  try:
    while True:
      line = proc.stdout.readline()
      if line != '':
        # data is of the form:
        # QR-Code:v=1&&eui=2b749b2cc8427dd7&&cc=ENUT02
        data = line.strip()
        #print(data)
        # parse
        i1 = data.find("eui=")
        eui = data[i1+1+3:i1+4+16]
        i2 = data.find("cc=")
        cc = data[i2+3:]
        print("Found device: (%s, %s)" % (eui, cc))
        commission_enable()
        commission_joiner(eui, cc)
        print("done.")
      break
  except Exception as ex:
    print(ex)
  # kill process
  subprocess.call(['sudo', 'kill', str(proc.pid), '-s', 'SIGINT'])
  exit(0)
</pre>
<br>

The above code runs *zbarcam* and reads its output. Note the *nodisplay* option - we 
need this on Nordic's Pi image since it has no GUI. (In any case we don't need 
to display the video on screen.)

The EUI-64 and joiner credential are extracted from the string and passed on to 
methods that *enable commissioning* on the border router, and then *join* the node. 
We use *wpanctl* for these actions.

<pre>
# enable commissioning
def commission_enable():
  proc = subprocess.Popen(['wpanctl','commissioner', '-e'],
    stdout=subprocess.PIPE)  
  while True:
    line = proc.stdout.readline()
    if line != '':
      print(line)
    else:
      break

# perform commissioning
def commission_joiner(eui, cc):
  proc = subprocess.Popen(['wpanctl','commissioner', '--joiner-add',
    cc, eui],stdout=subprocess.PIPE)  
  while True:
    line = proc.stdout.readline()
    if line != '':
      print(line)
    else:
      break
</pre>
<br>

Actually the *wpanctl commission -e* command needs to be run only once, and will 
ouput a warning on subsequent calls. (But since I am lazy, we'll ignore that warning 
rather than handle it.) *wpanctl commissioner --joiner-add cc eui64* will do the actual joining.

Here's a typical output:

<pre>
$ python qrcomm.py 
Found device: (2b749b2cc8427dd7, ENUT02)
Commissioner command applied.
Joiner added.
done.
</pre>
<br>

Now we've added the joiner from the border router. Let's now look at how to 
join the nework from the device.

## Code on The Joiner

Our *Joiner* is an nRF52840-DK, and the code we're using is adapted from 
the Nordic NFC MeshCoP example. Our code works as follows:

On pressing button 3 (label) on the board, we start a single-short timer that 
calls *otJoinerStart* with the joiner credential (*ENUT02* in our case). This 
method has a callback as shown below:

<pre>
static void joiner_callback(otError error, void * p_context)
{
	uint32_t err_code;

    if (error == OT_ERROR_NONE)
    {
        err_code = bsp_thread_commissioning_indication_set(BSP_INDICATE_COMMISSIONING_SUCCESS);
        APP_ERROR_CHECK(err_code);

        error = otThreadSetEnabled(thread_ot_instance_get(), true);
        ASSERT(error == OT_ERROR_NONE);
    }
    else
    {
        if (m_app.joiner_retry_count < MAX_JOINER_RETRY_COUNT)
        {
            m_app.joiner_retry_count++;

            err_code = app_timer_start(m_joiner_timer, 
                APP_TIMER_TICKS(JOINER_DELAY), thread_ot_instance_get());
            APP_ERROR_CHECK(err_code);
        }
        else
        {
            m_app.joiner_retry_count = 0;
            m_app.commissioning_in_progress = false;

            err_code = bsp_thread_commissioning_indication_set(
                BSP_INDICATE_COMMISSIONING_NOT_COMMISSIONED);
            APP_ERROR_CHECK(err_code);
        }
    }
}
</pre>
<br>

If the joining was successful, the above code calls *otThreadSetEnabled()* which 
starts Thread on the node. On faliure, it keeps retrying a few times.

Once the node joins successfully, the LEDs on the board will be stable and LED 2 (label) 
will light up.

If you really want to be sure that commissioning worked, you can 
open up a serial terminal and use the *Thread CLI* to verify that 
*masterkey* is same as the one you used to setup *wpantund* on the Pi 
border router.

In the code, button 4 (label) is hooked up to call *otInstanceFactoryReset()* - 
great for testing.

## In Action

You can see the QR code Thread commissioning in action below.

<iframe width="560" height="315" src="https://www.youtube.com/embed/ISOybwpeJtw" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

## Conclusion

And that's how you can use a camera on the Raspberry Pi Border Router to 
commission your Thread device. Although this method may look like *external commissioning*, 
since we're actually using a separate program to parse the information and 
run *wpanctl* to manually add the joiner, this looks more like a variation of 
*on-mesh commissioning* to me. Who knows? Maybe the Thread experts will tell us. 
In any case, it works.

## Downloads 

You can download code for this project here:

[https://gitlab.com/electronut/nRF52840_qrcomm][1]


## About this Article

**Title**: Nordic nRF52840 QR Code based Thread Commissioning 

**Author**: Mahesh Venkitachalam

**Website**: electronut.in

**First Published**: 16 Aug 2018

**Revisions**


[1]: https://gitlab.com/electronut/nRF52840_qrcomm
[2]: https://electronut.in/nrf52840-thread/
[3]: https://github.com/openthread/openthread/blob/master/src/cli/README.md
[4]: https://openthread.io/guides/build/commissioning
[5]: https://openthread.io/guides/border-router/external-commissioning
[6]: https://play.google.com/store/apps/details?id=org.threadgroup.commissioner&hl=en_IN
[7]: https://www.qr-code-generator.com/
[8]: http://zbar.sourceforge.net/
