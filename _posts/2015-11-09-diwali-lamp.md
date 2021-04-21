---
layout: post
title: Hacking a Cheap LED Lamp with nRF51822
excerpt: "Hacking a Cheap Diwali LED Lamp with Nordic nRF51822 BLE SoC and controlling it via a phone."
tags: [BLE, nRF51822, LED, Diwali]
categories: [Electronics]
comments: true
modified: 2015-11-09
thumbnail: images/2015/11/ble-lamp-final.jpg
images: images/2015/11/ble-lamp-final.jpg
---

![Diwali-BLE-lamp](/images/2015/11/ble-lamp-final.jpg "Diwali BLE Lamp")

## Introduction

Diwali (or *deepavali*, the Indian festival of lights) is just around
the corner, and in addition to stuffing myself with unhealthy snacks
and scaring my kids with firecrackers, it's also the time to receive
cheap LED lamps as gifts. ;-) So I decided to take one apart and make
it controllable via a phone - using my favorite Nordic nRF51822 BLE
SoC.

## Background

Before you read further, you might want to look through some of my
previous articles on nRF51822 programming, since we're going to use
similar concepts and development setup here.

* [nRF51822 Begins - nRF-DK, GCC, ADC, UART/BLE][1]
* [External nRF51822 SWD Programming using the nRF51-DK][2]
* [nRF51-DK PWM & GPIOTE test with S110 SoftDevice][3]
* [Talking to Ultrasonic Distance Sensor HC-SR04 using nRF51822][4]
* [Controlling an RGB LED with Nordic nRF51-DK (nRF51822/nRF51422)][5]
* [Motor Control over BLE with nRF51822 and TB6612FNG][6]
* [BLEBot - nRF51822 based BLE Robot][7]

## Hardware & Connections

This project uses one of the Chinese nRF51822 modules that are
available from *aliexpress* for about 5 USD. In my case, I actually
fried the chip in mine, and my friends at [ExploreEmbedded][8]
helped me replace it with one of the free nRF51422 samples I got with
my nRF51-DK board. My previous articles (above) cover programming this
board, so I will not repeat the information here.

Here's what the inside of the lamp looks like:

![Diwali-BLE-lamp](/images/2015/11/ble-lamp-start.jpg "Diwali BLE Lamp")

It's just 3 x 1.5 V coin cells connected to an LED and a switch under
the lamp. The first thing we need to do is reduce the voltage to 3 V
by taking out one battery. I used a mutilated Lego piece and some hot
glue to reposition the battery contact. The next thing to do is to
create some space for the nRF51822 board, for which I had to flip the
lid of the lamp.

The nRF51822 is connected as follows:

|**nRF51822**|**LED Lamp**|
|:--------:|:--------:|
| VDD | + 3V |
| GND | GND |
| P0.28 | Cathode of LED |

The anode of the LED is connected to +3V - so here, we are using the LED
in *active low* mode just the nRF51-DK. You need to set *P0.28* to LOW
to light the LED. For the connections, we have to solder wires to the
annoying 2x9 headers:

![Diwali-BLE-lamp](/images/2015/11/ble-lamp-solder.jpg "Diwali BLE Lamp")

Here's what it looks like all hooked up:

![Diwali-BLE-lamp](/images/2015/11/ble-lamp-inside.jpg "Diwali BLE Lamp")

Now, we need to program it.

### The Program

The program starts with the usual boilerplate to set up BLE, and then
goes on to set up a PWM channel as follows:

{% highlight C %}
{% raw %}
  // set up LED
  uint32_t pinLED = 28;

  // 2-channel PWM
  app_pwm_config_t pwm1_cfg =
      APP_PWM_DEFAULT_CONFIG_1CH(5000L, pinLED);

  pwm1_cfg.pin_polarity[0] = APP_PWM_POLARITY_ACTIVE_LOW;

  /* Initialize and enable PWM. */
  err_code = app_pwm_init(&PWM1,&pwm1_cfg,pwm_ready_callback);
  APP_ERROR_CHECK(err_code);
{% endraw %}
{% endhighlight %}

In the above code, pin 28 is setup with an *active low* PWM signal
with a period of 5000 us (200 Hz). Now here is the main loop:

{% highlight C %}
{% raw %}
int dir = 1;
int val = 0;
appEvent.pending = false;

  while(1) {

      // PWM stop/start requires some tricks
      // because app_pwm_disable() has a bug.
      // See:
      // https://devzone.nordicsemi.com/question/41179/how-to-stop-pwm-and-set-pin-to-clear/

      // is event flag set?
      if (appEvent.pending) {
          switch(appEvent.event) {

              case eAppEvent_Start:
              {
                  nrf_drv_gpiote_out_task_enable(pinLED);
                  app_pwm_enable(&PWM1);
              }
              break;

              case eAppEvent_Stop:
              {
                  app_pwm_disable(&PWM1);
                  nrf_drv_gpiote_out_task_disable(pinLED);
                  nrf_gpio_cfg_output(pinLED);
                  nrf_gpio_pin_set(pinLED);
              }
              break;

              case eAppEvent_Faster:
              {
                  if (delay > 5) {
                      delay -= 5;
                  }
              }
              break;

              case eAppEvent_Slower:
              {
                  if( delay < 80) {
                      delay += 5;
                  }
              }
              break;
          }

          // reset flag
          appEvent.pending = false;
      }

      while (app_pwm_channel_duty_set(&PWM1, 0, val) == NRF_ERROR_BUSY);

      // change direction at edges
      if(val > 99) {
          dir = -1;
      }
      else if (val < 1){
          dir = 1;
      }
      // increment/decrement
      val += dir*2;

      // delay
      nrf_delay_ms(delay);
  }
{% endraw %}
{% endhighlight %}

In the above loop, the PWM duty cycle is changed every step to make the LED
"breathe", and by changing the delay, we can control the rate of breathing.

We use the Nordic UART Service (NUS) to send commands to the chip via
BLE. Here, you can see the data structure used for events, and how
it's handled.

{% highlight C %}
{% raw %}
// These are based on default values sent by Nordic nRFToolbox app
// Modify as neeeded
#define FORWARD "FastForward"
#define REWIND "Rewind"
#define STOP "Stop"
#define PAUSE "Pause"
#define PLAY "Play"
#define START "Start"
#define END "End"
#define RECORD "Rec"
#define SHUFFLE "Shuffle"


// events
typedef enum _AppEventType {
    eAppEvent_Start,
    eAppEvent_Stop,
    eAppEvent_Slower,
    eAppEvent_Faster
} AppEventType;


// structure handle pending events
typedef struct _AppEvent
{
    bool pending;
    AppEventType event;
    int data;
} AppEvent;

AppEvent appEvent;

uint32_t delay = 20;


// Function for handling the data from the Nordic UART Service.
static void nus_data_handler(ble_nus_t * p_nus, uint8_t * p_data,
                             uint16_t length)
{
    if (strstr((char*)(p_data), REWIND)) {
        appEvent.event = eAppEvent_Slower;
        appEvent.pending = true;
    }
    else if (strstr((char*)(p_data), FORWARD)) {
        appEvent.event = eAppEvent_Faster;
        appEvent.pending = true;
    }
    else if (strstr((char*)(p_data), STOP)) {
        appEvent.event = eAppEvent_Stop;
        appEvent.pending = true;
    }
    else if (strstr((char*)(p_data), PLAY)) {
        appEvent.event = eAppEvent_Start;
        appEvent.pending = true;
    }
}
{% endraw %}
{% endhighlight %}

The NUS commands are sent using the [Nordic nRFToolBox app][10].

## In Action

Here's the hacked LED Lamp in action:

<p>
<iframe width="560" height="315" src="https://www.youtube.com/embed/eMsqE3HZWcU" frameborder="0" allowfullscreen></iframe>
</p>

## Downloads

You can get the complete source code for this project here:

[https://github.com/electronut/nRF51-diwali-lamp][9]


[1]: http://electronut.in/nrf51-adc-test/
[2]: http://electronut.in/nrf51-dk-external-programming/
[3]: http://electronut.in/nrf51-pwm-test/
[4]: http://electronut.in/nrf51-hcsr04/
[5]: http://electronut.in/nrf51-rgb-led-test/
[6]: http://electronut.in/nrf51-TB6612FNG-test/
[7]: http://electronut.in/blebot/
[8]: http://exploreembedded.com/
[9]: https://github.com/electronut/nRF51-diwali-lamp
[10]: https://www.nordicsemi.com/eng/Products/nRFready-Demo-Apps/nRF-Toolbox-App
