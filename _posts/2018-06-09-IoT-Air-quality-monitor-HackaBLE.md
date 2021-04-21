---
layout: post
title: "An IoT Air Quality Monitor based on the nRF52832 BLE SoC"
excerpt: "Air quality monitor project with hackable board and adafruit dashboard"
tags: [Air Quality Monitor, nRF52832, hackaBLE, IOT, Adafruit dashboard, DHT11, ZH03a dust sensor]
categories: [Electronics]
comments: false
modified: 2018-06-09
thumbnail: /images/2018/06/Air-quality-monitor.jpg
images: /images/2018/06/Air-quality-monitor.jpg
---

**Author: Vaishali Pathak**

**Editor: Mahesh Venkitachalam**

<h2>Introduction</h2>

Do you sometimes wonder how polluted the air inside your house is? 

Our surroundings are constantly degrading, and there are innumerable disease that can be caused by living in unhealthy, impure and polluted surroundings. I know there are a number of devices in the market that will measure the concentration of harmful pollutants in your house. But, I decided to build one so, I get to choose the functionality I want. In this article, I will show you how to build your own air quality monitor, which will measure the concentration of standard pollutant particles(PM1.0, PM2.5, PM10) in your house, as well as the temperature and humidity. We will make it super convenient by sending the obtained data to Adafruit cloud server, so that, you can access it whenever and from where ever you want through the dashboard. 

<h2> Objective </h2>

We are going to build an Air Quality monitor with temperature and humidity sensor using [Electronut Lab's](http://electronut.in/) nRF52382 based [hackaBLE](http://electronut.in/portfolio/hackaBLE/) board. We will also be able to access current measured values of the monitor from anywhere via the internet on [adafruit.io](https://io.adafruit.com/Vaishali94/dashboards/aqm) dashboard.

The Air quality monitor will measure and output the following values:

  * Particle concentration values of particle sizes.
     * 1.0 um (PM1.0)
     * 2.5 um (PM2.5)
     * 10 um (PM10)
  * Ambient temperature in degree C.
  * Relative humidity in %.
 
 <h2> Components </h2>
 
**ZH03a Laser Dust Sensor Module**
  
![dust sensor](/images/2018/06/dust-sensor.jpg)

ZH03a uses light scattering principle to detect dust particles.

 **DHT11 temperature and humidity sensor**
 
 ![dht11](/images/2018/06/dht11.jpg)
 
  [**HackaBLE Board**] (http://electronut.in/portfolio/hackaBLE/)
  
 ![hackable](/images/2018/06/hackable.jpg)
  

<h2> Directions: </h2>

This project is divided into 4 phases:

  1. **HackaBLE beacon**: We will write code to transmit data measured by dust sensor and DHT11 temperaure/humidity sensor in advertisement packets, as a result hackable will act like a bluetooth beacon. 
  2. **Raspberry Pi as a gateway**: We will write a python script on Raspberry Pi to read and interpret advertisement packets, also talk to the internet to display the extracted data values on adafruit dashboard.
  3. **Adafruit dashboard display**: We will create feeds which will publish data sent by raspberry pi on the dashboard. 
  4. **Design Enclosure for our hardware**: We will design a box structure which will enclose all the hardware using Inkscape design software.
  
  
 <h2> HackaBLE beacon </h2>
  
  **What is a BLE beacon?**
  
  Bluetooth beacons are hardware transmitters - a class of Bluetooth low energy (LE) devices that broadcast their identifier to nearby portable electronic devices. The technology enables smartphones, tablets, and other devices to perform actions when in close proximity to a BLE beacon.
  
  As mentioned earlier we will develop code for nRF52832 based hackable which will transmit sensor's data through advertisement packets. You can find the code in this repository as *air_quality_monitor*. 

 Few important things to study before jumping towards writing code are given below. Refer to the hyperlinks to know more:
 
  * [How to talk to dust sensor](http://www.winsen-sensor.com/d/files/PDF/Gas%20Sensor%20Module/PM2.5%20Detection%20Module/ZH03A%20Laser%20Dust%20Module%20V1.8.pdf)
  * [How to initiate DHT11 sensor and read values from it.](https://akizukidenshi.com/download/ds/aosong/DHT11.pdf)
  * [How to implement beacon on nrf52832.](http://electronut.in/bluey-beacon/)
  
 
 <h2> Interfacing DHT11 sensor module </h2>
 
 We need to connect the sensor in the following way to obtain the output.
 
 ![dht11](/images/2018/06/Dht11-MCU.PNG)
                                                                               
    [Image Source : DHT11 Datasheet]
 
 Now to obtain temperature and humidity data from the DHT11 value you need to initiate the sensor in following way.
 
![dht11](/images/2018/06/DHT11-comm-protocol.PNG)
                                                                      
    [Image Source : DHT11 Datasheet]
                                                                               
Now, our code is going to be the C program of the above signal diagram. DHT11 outputs 5 bytes of data containing 2 bytes for temperature, 2 bytes for relative humidity and 5th checksum byte to test with the data packet is correct or not, like the following.

![dht11](/images/2018/06/Dht11-data-format.PNG)
                                                                              
    [Image Source : DHT11 Datasheet]
    
<h2> Interfacing ZH03a Dust Sensor </h2>

Connect the pins of dust sensor in the following manner:

![dust sensor connection](/images/2018/06/Dust-sensor-connection.jpg)

    [Image Source : ZH03a Datasheet]
    
Unlike DHT11 ZH03a follows Byte-by-Byte protocol(UART), so we need to configure UART setting in our code according to below directions for ZH03a.


![dht11 pin up](/images/2018/06/dht11-pin-connection.jpg)
                                                                              
    [Image Source : ZH03a Datasheet]
                                                                      
After setting up UART for communication with the dust sensor, we need to write code to interpret sensor data. When initiated connection with sensor it uploads 22 bytes of data, as shown below.

![data_format](/images/2018/06/dust-sensor-data-format.PNG)
                                                                               
     [Image Source : ZH03a Datasheet]
     
Depending on the set pin of ZH03A dust sensor works in two modes:

   * Continous sampling mode. (SET = 1, set pin not connected)
   * Low power mode. (SET = 0)
 
 Here, we will use dust sensor in continuous sampling mode.
 
 After receiving the sensor data we need to write the checksum code to verify if the received data is correct, just like we did for DHT11. You can check out the code for implementation of both the sensors in this repository.
 
To implement the code for the beacon, refer to the example code in the NRF SDK you are using. In the code given in this repository, you will notice that I have created a *set_adv_data* function which sets up the advertisement packet needed to be sent by the nRF52. Also, I have also created a timer for setting the difference between each beacon interval. You have to be little familiar with bluetooth low energy and nRF sdk to be able to code. Anyways, BLE is fun and you should definitely look into it.Refer to the code here.
```
void set_adv_data(bool init)
{
  uint32_t      err_code;

  ble_advdata_t advdata;
  uint8_t       flags = BLE_GAP_ADV_FLAG_BR_EDR_NOT_SUPPORTED;

  ble_advdata_manuf_data_t        manuf_data; // Variable to hold manufacturer specific data
  // Initialize with easily identifiable data
  uint8_t data[]                      = {
    0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8};

  // get sensor data
  if (!init)
  {
      DHT11_read();
    data[0] = pm0_1>>8;
    data[1] = pm0_1;
    data[2] = pm2_5>> 8;
    data[3] = pm2_5;
    data[4] = pm10 >> 8;
    data[5] = pm10;
    data[6] = temperature;
    data[7] = humidity;
    
}

manuf_data.company_identifier       = 0xFFFF;
  manuf_data.data.p_data              = data;
  manuf_data.data.size                = sizeof(data);

  // Build advertising data struct to pass into @ref ble_advertising_init.
  memset(&advdata, 0, sizeof(advdata));

  advdata.name_type               = BLE_ADVDATA_SHORT_NAME;
  advdata.short_name_len          = 5;
  advdata.flags                   = flags; //BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE;
  advdata.p_manuf_specific_data   = &manuf_data;
  // if you don't set tx power, you get 3 extra bytes for manuf data
  //int8_t tx_power                 = -4;
  //advdata.p_tx_power_level        = &tx_power;
  advdata.include_appearance      = true;

  err_code = ble_advdata_set(&advdata, 0);
  APP_ERROR_CHECK(err_code);
}
```
So, we will call this function from the main() with a boolean flag variable *g_setAdvData* to this function. We will set it's value *false* inside the main(), but the timer handler will set it *true*. So that, this function is called according to assigned time interval value. Refer to the code in the repository (link in downloads section below) to understand better. 

Now you will be able to see your device advertising through [nRF connect](https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp&hl=en_IN) App. You will also be able to see the data of the sensors present under manufacture data. Every bluetooth device has their unique mac id. Note that id for your device, you will need that later. 

<h2> Raspberry Pi as gateway </h2>

As we have created a bluetooth beacon that transmits sensor data in every 2 sec interval. Now, we will write a python program to catch our advertisements packets and decode the data from it. Refer this "Script_Rpi_readPackets" directory for python script for the complete code. 

To communicate to adafruit we have used an MQTT client library in python, which will establish a connection between Rpi and adafruit via the internet to facilitate communication so that we can publish the received data from the sensor to the adafruit cloud. Here are the steps to write your code.
1. Import MQTT library.
2. Create your adafruit account, then pass your credential in your code to establish connection.
3. Write function to connect to adafruit, publish data and close the connection.

Refer to the code below.

```
# Import Adafruit IO MQTT client.
from Adafruit_IO import MQTTClient


# Set to your Adafruit IO key & username below.
ADAFRUIT_IO_KEY      = 'add_your_adafruit_io_key'
ADAFRUIT_IO_USERNAME = 'adafruit_user_name'  # See https://accounts.adafruit.com
                                                    # to find your username.


# Define callback functions which will be called when certain events happen.
def connected(client):
    print('Connected to Adafruit IO!  Listening for Dust_sensor changes...')
    # Subscribe to changes on a feed named DemoFeed.
    # client.subscribe('Dust_sensor')

def disconnected(client):
    # Disconnected function will be called when the client disconnects.
    print('Disconnected from Adafruit IO!')
    sys.exit(1)

def message(client, feed_id, payload):
    print('Feed {0} received new value: {1}'.format(feed_id, payload))

# Create an MQTT client instance.
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)


# Setup the callback functions defined above.
client.on_connect    = connected
client.on_disconnect = disconnected
client.on_message    = message

# Connect to the Adafruit IO server.
```
After implementing this code you need to use these function to publish your collected data using hci tools present in BLUEZ BLE tools. [Refer Here](http://electronut.in/bluey-beacon/) to install and learn about BLUEZ.

After installing BLUEZ in your Raspberry Pi, you will be able to use bluetooth scan tools like hcilescan and hcidump. Here's my python code which will read all the bluetooth packets available in the vicinity. 

```
"""
This class uses hctool and hcidump to parse BLE adv data.
"""
class BLEScanner:

    hcitool = None
    hcidump = None

    def start(self):
        print('Start receiving broadcasts')
        DEVNULL = subprocess.DEVNULL
        if sys.version_info > (3, 0) else open(os.devnull, 'wb')

        subprocess.call('sudo hciconfig hci0 reset', shell = True, 
        stdout = DEVNULL)
        self.hcitool = subprocess.Popen(['sudo', '-n', 'hcitool', 'lescan', 
        '--duplicates'], stdout = DEVNULL)
        self.hcidump = subprocess.Popen(['sudo', '-n', 'hcidump', '--raw'],
        stdout=subprocess.PIPE)

    def stop(self):
        print('Stop receiving broadcasts')
        subprocess.call(['sudo', 'kill', str(self.hcidump.pid), '-s', 'SIGINT'])
        subprocess.call(['sudo', '-n', 'kill', str(self.hcitool.pid), '-s', "SIGINT"])

    def get_lines(self):
        data = None
        try:
            print("reading hcidump...\n")
            #for line in hcidump.stdout:
            while True:
                line = self.hcidump.stdout.readline()
                #print (line)
                line = line.decode()
                if line.startswith('> '):
                    yield data
                    data = line[2:].strip().replace(' ', '')
                elif line.startswith('< '):
                    data = None
                else:
                    if data:
                        data += line.strip().replace(' ', '')
        except KeyboardInterrupt as ex:
            print("kbi")
            return
        except Exception as ex:
            print(ex)
return
```
This will help you scan and get data in the bluetooth advertisement packets. Every advertisement packets have their mac IDs. As we have already asked you to remember the mac ID for our device beacuse we will need it here. On the basis of the ID we will search for our advertisement packet to extract the sensor data.  
Here's the complete [python script](https://github.com/electronut/ElectronutLabs-hackaBLE/tree/master/code/air_quality_monitor/Python_script) for your better understanding.

**how to run this python script?**

Open a terminal in your Raspberry Pi. Run this command.

```
~> Python adafruit_dashboard.py *your_mac_id*
```

Now you will be able to see data getting published to the adafruit dashboard. 

<h2> Setting up Adafruit Display </h2>

To set up your adafruit dashboard:

  * Create an account on io.adafruit.
  * Create a new dashboard.
  * Add feeds to your dashboard.
  
You need to add a feed to every individual data you are receiving. In our case, we will add 5 feeds for temperature, humidity, and 3 particle concentration values. Like this.

![feeds](/images/2018/06/adafruit_feeds.PNG)

After this choose any kind of object on which you want to display the data. My dashboard looks like this.

![dashboard](/images/2018/06/adafruit_dashboard.PNG)

<h2> Designing the enclosure </h2>

We are going design an enclosure for our hardware. I used [Inkscape](https://inkscape.org/en/) to create my design. The Design is very simple, you can hang it on your wall or keep it on your table. So, here's the final arch shaped design of the enclosure.

![enclosure](/images/2018/06/inkspace_enclosure_design.PNG)

After soldering the circuit this is how the  hardware looks. You can power the circuit using DC adapter. 

![design](/images/2018/06/Air-quality-monitor.jpg)

so, this is a bluetooth beacon which transmits the sensor data which it reads in every 2sec interval. The python script running on raspberry pi will read the beacon data and through MQTT client server it will send the decoded data to adafruit dashboard's feed. This how the current feed looks after collecting data for an hour.

![DASHBOARD](/images/2018/06/adafruit_final_dashboard.PNG)

My adafruit dashboard is continuously publishing data, you can also see my live dashboard on adafruit.io [here](https://io.adafruit.com/Vaishali94/dashboards/aqm). 

<h2>Conclusion</h2>

I think this is an interesting project to build. It provides wide learning opportunities for a beginner in embedded systems development - especially BLE and IoT.

<h2>Downloads</h2>
[https://github.com/electronut/ElectronutLabs-hackaBLE/tree/master/code/air_quality_monitor](https://github.com/electronut/ElectronutLabs-hackaBLE/tree/master/code/air_quality_monitor)

<h2>Acknowledgement</h2>

I want to thank my all collegues at [Electronut Labs](http://electronut.in/about/) for their encouragement in the projects and providing their invaluable insights.  
