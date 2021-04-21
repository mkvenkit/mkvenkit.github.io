---
layout: post
title: An IoT Triad Demo, Part I - Device (nRF8001 + Arduino)
excerpt: "Using nRF8001 and Arduino to create a BLE IoT device that puts out temperature and battery levels."  
tags: [nRF8001, Arduino, BLE, IoT]
categories: [Electronics]
comments: true
modified: 2015-05-28
thumbnail: images/2015/05/iott-device.jpg 
images: images/2015/05/iott-device.jpg 
---

<br />
<br />
![IoT Device](/images/2015/05/iott-device.jpg "nRF8001 Arduino BLE IoT")
<br />
<br />

## Introduction

Internet Of Things (IoT) implementations usually consist of three
parts - the device itself, software that interacts with the device
(which usually runs on a mobile platform), and a cloud part that can
serve as an intermediary, which may host web apps for controlling the
device or dashboards for device data. In this three-part article, I
demonstrate an "IoT triad" by developing a simple Bluetooth Low
Energy (BLE) device, a cross platform mobile application, and data
visualization on the cloud.  In this first installment of the project,
I will focus on the device part.

## The Device

Our IoT device consists of an [Adafruit nRF8001 breakout board][1]
controlled by an Arduino Pro Mini (clone). It measures the ambient
temperature from an [LM35 sensor][2] connected to analog pin of the
Arduino, and sends out this information to connected BLE peers. In
addition, it also broadcasts a (fake) battery level to listeners. Here
is how we hook up the device:

<br />
<br />
![IoT Device Schematic](/images/2015/05/iott-schematic.jpg "nRF8001 Arduino BLE IoT Schematic")
<br />
<br />

The connections above are same as that in the [Adafruit nRF8001
article][3].  (Note that we're using a 5V Arduino.) REQ connects to
the SPI Chip Select pin, which is set as Digital 10 here. RDY is the
interrupt out from the nRF8001, which is connected to Digital 2 (It
needs to be connected to an interrupt capable pin). RST connects to
Digital 9, and is used to restart the nRF8001 board when the Arduino
starts up.

## Firmware

Now, we need to develop the firmware for our IoT device. The BLE magic
happens in the nRF8001, and the Arduino acts as a controller for this
chip. The communication between the nRF8001 and the Arduino happens
via something called the Application Controller Interface (ACI). This
scheme is shown below.

<br />
<br />
![nRF8001 ACI](/images/2015/05/iott-aci.png "nRF8001 ACI")
<br />
<br />

Note that there is one extra connection above than the usual SPI
scheme. (This is because the nRF8001 doesn't act as a pure SPI slave
device.) The controller and the nRF8001 communicate in a bidirectional
scheme. Information going from the controller to the nRF8001 are in
the form of *system commands* and *data commands*. Information going
the other way is in the form of *system events* and *data events*. For
the gory details, you can (and you must!) read the 161 page [nRF8001
data sheet][7]. Luckily, we don't have to code everything up from the
data sheet ourselves. Nordic has provided an [excellent SDK for the
Arduino][6] with great examples which we can build upon.

### nRF8001 Configuration

Before we can use the nRF8001, we need to configure it. Nordic
provides a Windows-only (why Oh why?!) [nRFGo utility][8] that can be
used to generate the files needed to configure the GATT and GAP
settings as well as other hardware settings for the nRF8001. If you
are unfamiliar with these BLE concepts, I recommend that you start
reading *Getting Started with Bluetooth Low Energy* by Kevin Townsend
et al. (BLE has a tonne of acronymns and concepts, and if you're like
me, it will take multiple readings for the dust to settle.)

To get started, we have to first decide what kind of services our BLE
device is going to provide. In our case, we want to send out
temperature out (measured by the Arduino using the LM35), as well as a
fake battery level. The BLE specification describes a number of
[standard Services][9], and we're going to make use of a couple of
them. For sending out the temperature, we will make use of the [Health
Thermometer Profile][10]. This service specifies a number of
characteristics, but we'll make use of only one that we're interested
in - *Temperature Measurement*. For battery level, we'll make use of
the [Battery Service profile][11], and the characteristic of interest
in this case is *Battery Level*.

Nordic uses the concept of *Service Pipes* for the nRF8001 ACI. Each
service pipe points a unique charactacteristic - for example, the
*Battery Level* as in our case. The pipe also defines the direction of
data transfer, and a bunch of other properties. When we configure the
nRF8001 using nRFGo, it will create the definitions required to create
these pipes in *services.h*.

<br />

The way we use nRFGo is as follows:

1. Select File->New->nRF8001.
2. Add GATT services to device by dragging and dropping from "Service Templates" tab onto the tab on the left.
3. Modify GAP settings.
4. Go to nRFSetup menu, generate source files and choose the option to generate just the *.h* file.
5. Copy the generated *services.h* file to our Arduino project directory.

Here is what the GATT settings looks like:

<br />
<br />
![nRFGo GATT](/images/2015/05/nRFgo-gatt.png "nRFGo GATT settings")
<br />
<br />

For the *Health Thermometer* profile, we have only included the
*Temperature Measurement* characteristic. In its properties, we have
checked the *Indicate* option, which means the following (from nRF8001
data sheet):

1. Update Server and send an indication of the update to the Client (Peer device).
2. Peer device acknowledges a successful reception of the indication.
3. nRF8001 generates DataAckEvent

We also have checked the "Use characteristic presentation format"
option, and set the value to be a 4 byte *FLOAT* with an initial value
of *22*. For the *Battery Service* profile, we have enabled
"broadcast" and "set pipe" for the *Battery Level*
characteristic. We've also set the characteristic format at an
unsigned 8 bit integer with an initial value of *11*.

<br />
Now let's look at the GAP settings:

<br />
<br />
![nRFGo GAP](/images/2015/05/nRFgo-gap.png "nRFGo GAP settings")
<br />
<br />

In the GAP Settings tab, I have set the device name as *IoT
electronut*. I've also set values in the ACI connect/bond/broadcast
tabs. This is something you can play with - I am yet to get too deep
into these. To see and modify the settings I used above, simply load the
*arduino_nrf8001_iot.xml* file into nRFGo from my [github link][4] for
the project.

At the end of the above process, we end up with a *services.h* file
that we will use in our project. (nRFGo also generates a
*services_lock.h*, which is to be only used for production, since that
will write the settings permanently into the non-volatile RAM of the
nRF8001.) If you look inside the *services.h* file, you will see stuff like:

{% highlight C++ %}
{% raw %}

/* Service: Battery - Characteristic: Battery Level - Pipe: BROADCAST */
#define PIPE_BATTERY_BATTERY_LEVEL_BROADCAST          1
#define PIPE_BATTERY_BATTERY_LEVEL_BROADCAST_MAX_SIZE 1

/* Service: Battery - Characteristic: Battery Level - Pipe: SET */
#define PIPE_BATTERY_BATTERY_LEVEL_SET          2
#define PIPE_BATTERY_BATTERY_LEVEL_SET_MAX_SIZE 1

/* Service: Health Thermometer - Characteristic: Temperature Measurement - Pipe: TX_ACK */
#define PIPE_HEALTH_THERMOMETER_TEMPERATURE_MEASUREMENT_TX_ACK          3
#define PIPE_HEALTH_THERMOMETER_TEMPERATURE_MEASUREMENT_TX_ACK_MAX_SIZE 4

{% endraw %}
{% endhighlight %}

The above three pipes match our settings in the GATT tab in
nRFGo. These pipe handles will be used in our code. The *services.h*
file also contains the initialization code containing all our
settings. This looks something like:

{% highlight C++ %}
{% raw %}

#define SETUP_MESSAGES_CONTENT {\
    {0x00,\
        {\
            0x07,0x06,0x00,0x00,0x03,0x02,0x42,0x07,\
        },\
    },\
    {0x00,\
        {\
            0x1f,0x06,0x10,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x00,0x03,0x01,0x01,0x00,0x00,0x06,0x00,0x00,\
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,\
        },\
    },\
...
{% endraw %}
{% endhighlight %}

To be clear, you don't absolutely *require* nRFGo to make all this
work. As long as you are able to send the correct initialization
commands to nRF8001 via SPI, it will work. But as you can imagine,
coding this up manually would be horribly painful.

Here is the Arduino code that uses the information in *services.h*
to setup the nRF8001:

{% highlight C++ %}
{% raw %}
   //  Point ACI data structures to the the setup data that
   // the nRFgo studio generated for the nRF8001
    aci_state.aci_setup_info.services_pipe_type_mapping =
                    &services_pipe_type_mapping[0];
    aci_state.aci_setup_info.number_of_pipes    = NUMBER_OF_PIPES;
    aci_state.aci_setup_info.setup_msgs         = (hal_aci_data_t*) setup_msgs;
    aci_state.aci_setup_info.num_setup_msgs     = NB_SETUP_MESSAGES;

    // set uC connections
    aci_state.aci_pins.board_name = BOARD_DEFAULT;
    aci_state.aci_pins.reqn_pin   = 10;
    aci_state.aci_pins.rdyn_pin   = 2;
    aci_state.aci_pins.mosi_pin   = MOSI;
    aci_state.aci_pins.miso_pin   = MISO;
    aci_state.aci_pins.sck_pin    = SCK;
    aci_state.aci_pins.spi_clock_divider      = SPI_CLOCK_DIV8;  
    aci_state.aci_pins.reset_pin              = 9;
    aci_state.aci_pins.active_pin             = UNUSED;
    aci_state.aci_pins.optional_chip_sel_pin  = UNUSED;
    aci_state.aci_pins.interface_is_interrupt = false;
    aci_state.aci_pins.interrupt_number       = 1;

    // this call inititualizes the nRF8001 with our settings
    lib_aci_init(&aci_state, false);

{% endraw %}
{% endhighlight %}

In the code above, we can see how the Nordic ACI library data
structures are set up according to the configuration we created in the
*services.h* file. The code also sets the microcontroller pins used to
communicate with the nRF8001, and finally calls *lib_aci_init()* to
initialize it.

### nRF8001 Flow Control

The nRF8001 is state machine with the following four modes of
operation: *Sleep*, *Setup*, *Active*, and *Test*. The following graphic
illustrates how it switches between these modes.

<br />
<br />
![nRF8001 SM](/images/2015/05/iott-nrf8001-state-machine.png "nRF8001 state machine")
<br />
<br />

Here is the boilerplate code from the Nordic BLE SDK, which manages
the event loop in the nRF8001:

{% highlight C++ %}
{% raw %}

void aci_loop()
{
    static bool setup_required = false;

    // We enter the if statement only when there is a ACI event
    // available to be processed
    if (lib_aci_event_get(&aci_state, &aci_data))
    {
        aci_evt_t * aci_evt;
        aci_evt = &aci_data.evt;

        switch(aci_evt->evt_opcode) {
        case ACI_EVT_DEVICE_STARTED:
            {
                aci_state.data_credit_available =
                    aci_evt->params.device_started.credit_available;

                switch(aci_evt->params.device_started.device_mode)
                {
                case ACI_DEVICE_SETUP:
                    {
                        Serial.println(F("Evt Device Started: Setup"));
                        aci_state.device_state = ACI_DEVICE_SETUP;
                        setup_required = true;
                    }                    
                    break;

                case ACI_DEVICE_STANDBY:
                    {
                        aci_state.device_state = ACI_DEVICE_STANDBY;

                        // sleep_to_wakeup_timeout = 30;
                        Serial.println(F("Evt Device Started: Standby"));
                        if (aci_evt->params.device_started.hw_error) {
                            //Magic number used to make sure the HW error
                            //event is handled correctly.
                            delay(20);
                        }
                        else
                        {
                            lib_aci_connect(30/* in seconds */,
                                            0x0100 /* advertising interval 100ms*/);
                            Serial.println(F("Advertising started"));
                        }
                    }
                    break;
                }
            }
            break; // case ACI_EVT_DEVICE_STARTED:

        case ACI_EVT_CMD_RSP:
            {
                //If an ACI command response event comes with an error -> stop
                if (ACI_STATUS_SUCCESS != aci_evt->params.cmd_rsp.cmd_status ) {
                    // ACI ReadDynamicData and ACI WriteDynamicData
                    // will have status codes of
                    // TRANSACTION_CONTINUE and TRANSACTION_COMPLETE
                    // all other ACI commands will have status code of
                    // ACI_STATUS_SCUCCESS for a successful command
                    Serial.print(F("ACI Status of ACI Evt Cmd Rsp 0x"));
                    Serial.println(aci_evt->params.cmd_rsp.cmd_status, HEX);
                    Serial.print(F("ACI Command 0x"));
                    Serial.println(aci_evt->params.cmd_rsp.cmd_opcode, HEX);
                    Serial.println(F("Evt Cmd respone: Error. "
                                     "Arduino is in an while(1); loop"));
                    while (1);
                }
                else
                {
                    // print command
                    Serial.print(F("ACI Command 0x"));
                    Serial.println(aci_evt->params.cmd_rsp.cmd_opcode, HEX);
                }
            }
            break;

        case ACI_EVT_CONNECTED:
            {                
                // The nRF8001 is now connected to the peer device.
                Serial.println(F("Evt Connected"));
            }            
            break;

        case ACI_EVT_DATA_CREDIT:
            {

                Serial.println(F("Evt Credit: Peer Radio acked our send"));

                /** Bluetooth Radio ack received from the peer radio for
                    the data packet sent.  This also signals that the
                    buffer used by the nRF8001 for the data packet is
                    available again.  We need to wait for the Confirmation
                    from the peer GATT client for the data packet sent.
                    The confirmation is the ack from the peer GATT client
                    is sent as a ACI_EVT_DATA_ACK.  */
            }
            break;

        case ACI_EVT_DISCONNECTED:
            {                
                // Advertise again if the advertising timed out.
                if(ACI_STATUS_ERROR_ADVT_TIMEOUT ==
                   aci_evt->params.disconnected.aci_status) {
                    Serial.println(F("Evt Disconnected -> Advertising timed out"));
                    Serial.println(F("nRF8001 going to sleep"));
                    lib_aci_sleep();
                    aci_state.device_state = ACI_DEVICE_SLEEP;
                }

                else
                {
                    Serial.println(F("Evt Disconnected -> Link lost."));
                    lib_aci_connect(30/* in seconds */,
                                    0x0050 /* advertising interval 50ms*/);
                    Serial.println(F("Advertising started"));
                }
            }                
            break;

        case ACI_EVT_PIPE_STATUS:
            {
                Serial.println(F("Evt Pipe Status"));
                // check if the peer has subscribed to the
            }
            break;    

        case ACI_EVT_PIPE_ERROR:
            {
                // See the appendix in the nRF8001
                // Product Specication for details on the error codes
                Serial.print(F("ACI Evt Pipe Error: Pipe #:"));
                Serial.print(aci_evt->params.pipe_error.pipe_number, DEC);
                Serial.print(F("  Pipe Error Code: 0x"));
                Serial.println(aci_evt->params.pipe_error.error_code, HEX);

                // Increment the credit available as the data packet was not sent.
                // The pipe error also represents the Attribute protocol
                // Error Response sent from the peer and that should not be counted
                //for the credit.
                if (ACI_STATUS_ERROR_PEER_ATT_ERROR !=
                    aci_evt->params.pipe_error.error_code) {
                    aci_state.data_credit_available++;
                }
            }
            break;

        case ACI_EVT_DATA_ACK:
            {
                Serial.println(F("Attribute protocol ACK for"));
            }
            break;

        case ACI_EVT_HW_ERROR:
            {                
                Serial.println(F("HW error: "));
                Serial.println(aci_evt->params.hw_error.line_num, DEC);

                for(uint8_t counter = 0; counter <= (aci_evt->len - 3); counter++)
                {
                    Serial.write(aci_evt->params.hw_error.file_name[counter]);
                }
                Serial.println();
                lib_aci_connect(30/* in seconds */,
                                0x0100 /* advertising interval 100ms*/);
                Serial.println(F("Advertising started"));
            }            
            break;

        default:
            {                
                Serial.print(F("Evt Opcode 0x"));
                Serial.print(aci_evt->evt_opcode, HEX);
                Serial.println(F(" unhandled"));
            }            
            break;
        }
    }
    else
    {
        //  No event in the ACI Event queue
    }

    /* setup_required is set to true when the device starts up and
       enters setup mode.  
       *  It indicates that do_aci_setup() should be
       called. The flag should be cleared if
       *  do_aci_setup() returns ACI_STATUS_TRANSACTION_COMPLETE.  */

    if(setup_required)
    {
        if (SETUP_SUCCESS == do_aci_setup(&aci_state))
        {
            setup_required = false;
        }
    }
}

{% endraw %}
{% endhighlight %}

So the *aci_loop()* method above handles the event loop in the
nRF8001, and we need to add our code to specific event handling
sections within this code. This is how we integrate *aci_loop()* into
our Arduino code:

{% highlight C++ %}
{% raw %}

void loop()
{
    aci_loop();

    // every 5 seconds
    if(millis() - lastUpdate > 5000) {

        // do something!

        // update time stamp
        lastUpdate = millis();
    }
}

{% endraw %}
{% endhighlight %}


### Measuring & Sending Temperature

We measure temperature using the LM35 sensor, which is connected to
the *Analog 0* pin of the Arduino. Here is code that calculates
temperature from this sensor:

{% highlight C++ %}
{% raw %}

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

{% endraw %}
{% endhighlight %}

Now let's look at how the data is sent to BLE peers.

{% highlight C++ %}
{% raw %}

  lib_aci_send_data(PIPE_HEALTH_THERMOMETER_TEMPERATURE_MEASUREMENT_TX_ACK,
                (uint8_t*)&temp, 4);

{% endraw %}
{% endhighlight %}

Before we send the data, we need to make sure that a peer has notifications turned on. This is done in the ACI loop:

{% highlight C++ %}
{% raw %}
case ACI_EVT_PIPE_STATUS:
    {
        Serial.println(F("Evt Pipe Status"));
        // check if the peer has subscribed to the
        // Temperature Characteristic
        if (lib_aci_is_pipe_available(&aci_state,
               PIPE_HEALTH_THERMOMETER_TEMPERATURE_MEASUREMENT_TX_ACK))
        {
            notifyTemp = true;
        }
        else {
            notifyTemp = false;
        }
    }
    break;    
{% endraw %}
{% endhighlight %}

### Broadcasting Battery Level

In addition to temperature, we're also going to send a fake battery
level - just to demonstrate the concept of broadcasting. The broadcasting
is set up in the event loop as follows:


{% highlight C++ %}
{% raw %}
case ACI_DEVICE_STANDBY:
    {
        aci_state.device_state = ACI_DEVICE_STANDBY;

        if (!broadcastSet) {
            lib_aci_open_adv_pipe(PIPE_BATTERY_BATTERY_LEVEL_BROADCAST);
            Serial.println(F("Broadcasting started"));
            broadcastSet = true;
        }

        // sleep_to_wakeup_timeout = 30;
        Serial.println(F("Evt Device Started: Standby"));
        if (aci_evt->params.device_started.hw_error) {
            //Magic number used to make sure the HW error
            //event is handled correctly.
            delay(20);
        }
        else
        {
            lib_aci_connect(30/* in seconds */,
            0x0100 /* advertising interval 100ms*/);
            Serial.println(F("Advertising started"));
        }
    }
    break;
{% endraw %}
{% endhighlight %}

Here is where the actual broadcasting is done - in *loop()*:

{% highlight C++ %}
{% raw %}
if (broadcastSet) {
    Serial.println(F("Setting batt level"));
    uint8_t val = batt[index++ % 3];
    lib_aci_set_local_data(&aci_state, PIPE_BATTERY_BATTERY_LEVEL_BROADCAST, (uint8_t*)&val, 1);
}
{% endraw %}
{% endhighlight %}

The battery level just cycles through an array that has values *{25, 50, 75}*.

## Testing BLE

For testing our BLE device, I used [the excellent LightBlue app][5] on
my iPhone 5. There are plenty of BLE scanner apps vailable for other
platforms - make sure you pick one that can listen to BLE
notifications and read advertisement data. The images below show the
interaction of our device with the app.

<br />
<br />
![BLE LightBlue App](/images/2015/05/iott-lightblue.png "BLE LightBlue App")
<br />
<br />

When the app starts, we will see our BLE device listed on it, and we
can see the services supported, as well as start listening for
notifications.

#### Important Note for Debugging

When playing around with BLE, if you find that your old GATT settings
are not going away in your mobile app, restart bluetooth on the
phone. (This happens due to GATT caching, as I learned painfully.)

## Getting the Code

All source files for this project can be found [at my github page][4].

## Conclusion

By constructing a BLE IoT contraption that transmits temperature and
battery levels, we have touched on the *Device* part of the IoT
triad. In the next part, we will look at the *Mobile* part - creating a
cross platform mobile application that will speak to our Device.

## References

1. Nordic Semiconductor nRF8001 data sheet.
2. *Getting Started with Bluetooth Low Energy* by
   Kevin Townsend, Carles Cufí, Akiba, & Robert Davidson.
   (O'Reilly Media, ISBN-13: 978-1491949511)
3. Nordic nRF8001 BLE SDK.

[1]: http://www.adafruit.com/products/1697
[2]: http://www.ti.com/product/lm35
[3]: https://learn.adafruit.com/getting-started-with-the-nrf8001-bluefruit-le-breakout/introduction
[4]: https://github.com/electronut/IoT-Triad
[5]: https://itunes.apple.com/in/app/lightblue-bluetooth-low-energy/id557428110
[6]: https://github.com/NordicSemiconductor/ble-sdk-arduino
[7]: https://www.nordicsemi.com/eng/Products/Bluetooth-Smart-Bluetooth-low-energy/nRF8001
[8]: https://www.nordicsemi.com/chi/node_176/2.4GHz-RF/nRFgo-Studio
[9]: https://developer.bluetooth.org/gatt/services/Pages/ServicesHome.aspx
[10]: https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.health_thermometer.xml
[11]: https://developer.bluetooth.org/gatt/services/Pages/ServiceViewer.aspx?u=org.bluetooth.service.battery_service.xml
