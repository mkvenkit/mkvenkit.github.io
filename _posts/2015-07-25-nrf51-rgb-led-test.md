---
layout: post
title: Controlling an RGB LED with Nordic nRF51-DK (nRF51822/nRF51422)
excerpt: "Using PWM and Nordic UART Service on nRF51-DK (nRF51822/nRF52422) to control an RGB LED over BLE."
tags: [nRF51822, nRF-DK, BLE, softdevice, S110, RGB, LED, PWM]
categories: [Electronics]
comments: true
modified: 2015-07-25
thumbnail: images/2015/07/nrf51-rgb-led.jpg
images: images/2015/07/nrf51-rgb-led.jpg
---

![nRF51-RGB-LED](/images/2015/07/nrf51-rgb-led.jpg "nRF51 RGB LED")

## Introduction

In this project, we will control an RGB LED using the Nordic
nRF51-DK over BLE. We will make use of PWM (Pulse Width Modulation) and
NUS (Nordic UART Service) for this.

## Background

Before you read further, you might want to look at my previous articles on
nRF51822 programming, since we're going to use the same development setup here.

* [External nRF51822 SWD Programming using the nRF51-DK][1]
* [nRF51-DK PWM & GPIOTE test with S110 SoftDevice][2]
* [Talking to Ultrasonic Distance Sensor HC-SR04 using nRF51822][3]

## RGB LED

In this project, we will be using a *Common Cathode* RGB LED. An RGB
LED combines three LEDs - Red, Green and Blue, and by toggling each of
these on in different proportions, you can get a huge variety of
colors. This is done by varying the *duty cycle* of the PWM pulses to
each of the R, G, B pins. (For example, 0% means the pin is off,
100% means it's on all the time, and 50% means it's on half the time.)

Here is how we hook up the RGB LED to the nRF-DK:

![nRF51-RGB-LED-CIRCUIT](/images/2015/07/nrf51-rgb-led-circuit.png "nRF51 RGB LED Circuit")

Note that I used 100 &Omega; resistors above. I have [written about
nRF51 PWM control][2] before. This project uses the same methods to
set PWM duty cycle to the each of the R, G and B pins.

## BLE Control

To control the RGB LED over BLE, we use the Nordic [nRFToolbox
App][4]. The app has a configurable keypad which send strings to the
nRF51-DK over the Nordic UART Service when the buttons are pressed. We
check for these strings and take appropriate action in the code as
follows:

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

// delay in milliseconds between PWM updates
uint32_t delay = 10;
// min/max delay,increment in milliseconds
const uint32_t delayMin = 10;
const uint32_t delayMax = 250;
const uint32_t delayInc = 25;

bool enablePWM = true;
bool pausePWM = false;

// Function for handling the data from the Nordic UART Service.
static void nus_data_handler(ble_nus_t * p_nus, uint8_t * p_data,
                             uint16_t length)
{
  if (strstr((char*)(p_data), FORWARD)) {
    if((delay + delayInc) < delayMax) {
      delay += delayInc;
    }
  }
  else if (strstr((char*)(p_data), REWIND)) {
    if((delay - delayInc) > delayMin) {
      delay -= delayInc;
    }
  }
  else if (strstr((char*)(p_data), START)) {
    delay = delayMin;
  }
  else if (strstr((char*)(p_data), END)) {
    delay = delayMax;
  }
  else if (strstr((char*)(p_data), STOP)) {
    enablePWM = false;
  }
  else if (strstr((char*)(p_data), PLAY)) {
    enablePWM = true;
  }
  else if (strstr((char*)(p_data), PAUSE)) {
    pausePWM = !pausePWM;
  }
}
{% endraw %}
{% endhighlight %}


In the code above, *nus_data_handler()* is called every time data
arrives to the chip via the Nordic UART Service over BLE. (You can see
how this is set up in the full source code.)

## The Main Loop

The main loop for the code just sits around varying the RGB LED
colors by modifying the PWM duty cycle. As the buttons are pressed, it
starts/stops PWM, and makes the color changes faster or slower as
needed.

{% highlight C %}
{% raw %}
// Enter main loop.
    int dir = 1;
    int val = 0;

    // main loop:
    bool pwmEnabled = true;

    while(1) {

      // only if not paused
      if (!pausePWM) {

        // enable disable as needed
        if(!enablePWM) {
          if(pwmEnabled) {
            app_pwm_disable(&PWM1);
            app_pwm_disable(&PWM2);

            // This is required becauase app_pwm_disable()
            // has a bug.
            // See:
            // https://devzone.nordicsemi.com/question/41179/how-to-stop-pwm-and-set-pin-to-clear/
            nrf_drv_gpiote_out_task_disable(pinR);
            nrf_gpio_cfg_output(pinR);
            nrf_gpio_pin_clear(pinR);
            nrf_drv_gpiote_out_task_disable(pinG);
            nrf_gpio_cfg_output(pinG);
            nrf_gpio_pin_clear(pinG);
            nrf_drv_gpiote_out_task_disable(pinB);
            nrf_gpio_cfg_output(pinB);
            nrf_gpio_pin_clear(pinB);

            pwmEnabled = false;
          }
        }
        else {
          if(!pwmEnabled) {

            // enable PWM

            nrf_drv_gpiote_out_task_enable(pinR);
            nrf_drv_gpiote_out_task_enable(pinG);
            nrf_drv_gpiote_out_task_enable(pinB);

            app_pwm_enable(&PWM1);
            app_pwm_enable(&PWM2);
            pwmEnabled = true;
          }
        }

        if(pwmEnabled) {
          // Set the duty cycle - keep trying until PWM is ready
          while (app_pwm_channel_duty_set(&PWM1, 0, val) == NRF_ERROR_BUSY);
          while (app_pwm_channel_duty_set(&PWM1, 1, val) == NRF_ERROR_BUSY);
          while (app_pwm_channel_duty_set(&PWM2, 0, val) == NRF_ERROR_BUSY);
        }

        // change direction at edges
        if(val > 99) {
          dir = -1;
        }
        else if (val < 1){
          dir = 1;
        }
        // increment/decrement
        val += dir*5;
      }      
      // delay
      nrf_delay_ms(delay);
    }
{% endraw %}
{% endhighlight %}

You can see above that we're jumping through some hoops to stop
and start the PWM. This is due to a known bug in the Nordic nRF51 SDK
(as of version 9.0.0) which does not correctly set the pins to low
when *app_pwm_disable()* is called. This issue has been discussed on
the [Nordic Developer Zone][6].

## In Action

Once it's all hooked up, you can see how it should work here:

<iframe width="560" height="315" src="https://www.youtube.com/embed/69K_P8o4c6Q" frameborder="0" allowfullscreen></iframe>

## Downloads

You can get the complete source code for this project here:

[https://github.com/electronut/nRF51-RGB-LED-test][5]


## References

1. nRF51 Series Reference Manual Version 3.0.

[1]: http://electronut.in/nrf51-dk-external-programming/
[2]: http://electronut.in/nrf51-pwm-test/
[3]: http://electronut.in/nrf51-hcsr04/
[4]: https://www.nordicsemi.com/eng/Products/nRFready-Demo-Apps/nRF-Toolbox-App
[5]: https://github.com/electronut/nRF51-RGB-LED-test
[6]: https://devzone.nordicsemi.com/question/41179/how-to-stop-pwm-and-set-pin-to-clear/
