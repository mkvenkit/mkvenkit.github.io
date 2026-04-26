---
title: Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE
description: "...when it comes to resource constrained low power systems, Linux is
  just too heavy. Enter Zephyr – an RTOS (Real Time Operating System) that is very
  much influenced by Linux, but designed specifically with the above constraints in
  mind."
featured_image: "/images/2019/02/app_kernel_conf_1-1.png"
tags:
- Zephyr
- RTOS
- nRF52832
- Nordic
- BLE
categories:
- Electronics
- programming
---
## Introduction

I worked for almost two decades in the software industry. In the early 2000s, I was developing applications on Windows, Linux, and various flavours of Unix. On the Windows side, we had Microsoft Visual Studio, MFC, NMake, and CL. On the Linux/Unix side, we had GCC, POSIX and various types of windowing toolkits (X-Window + Motif, anyone?). Cross platform development was a challenge, but even before the advent of fancy tools like Qt and wxWindows, we were able to structure the code so that large parts of it was compatible across the different operating systems.

Compared to that, cross-platform development in the embedded world today is far more difficult. First of all, there are many chip architectures – AVR, ARM, Xtensa, RISC-V, etc., and these chips vary hugely in their capabilities and supported peripherals. Then there are different sorts of toolchains, libraries, and development environments. Not all them can run an OS (or an RTOS) and in many cases, people don’t prefer to. Overall, good luck trying to port your code from once device to another! Although efforts like _mbed_ try to address the cross-platform issue, they are restricted to certain chip families.

Why not just use embedded Linux then? You certainly can in many cases, as the huge success of Raspberry Pi shows. But when it comes to resource constrained low power systems, Linux is just too heavy. Enter **Zephyr** – an RTOS (Real Time Operating System) that is very much influenced by Linux, but designed specifically with the above constraints in mind.

## Objective

In this project, we will build a BLE (Bluetooth Low Energy) device that broadcasts data from a BME280 temperature/humidity sensor. For this, we will use the Zephyr RTOS on the Electronut Labs **hackaBLE** board based on the Nordic nRF52832 SoC. For programming hackaBLE, we will use the Electronut Labs **Bumpy** SWD debugger based on the _blackmagicprobe_ project.

## Getting Started

The first thing to do of course, is to install Zephyr. For this task and for all tasks ahead, the [official documentation page](https://docs.zephyrproject.org/latest/getting_started/index.html) is your best reference. You can install Zephyr on Linux, Mac, or Windows. But I did it on Linux, and hence this article will reflect that experience. As you go through the official installation procedure, I recommend that you install the _Zephyr SDK_ as well, since it has the required toolchain. Makes it easy to get started.

Now, before we proceed to build our “hello world” application with Zephyr, let’s look at a few concepts that are central to working with this RTOS.

### CMake

If you have worked with embedded systems for any considerable time, you’re probably familiar with _Makefiles_. Well, _CMake_ is a system that makes Makefiles. CMake is a cross-platform tool that uses configuration files to create build files specific to your system. Zephyr uses CMake, and building a project goes something like this:

```
$cd hello_world 
$mkdir build && cd build
$cmake -GNinja -DBOARD=my_board ..
# impressively voluminous cmake output... 
# now you're ready to build
$ninja
# super-fast build with more output... 
# upload to the board
$ninja flash
```

_Ninja_ is a build system designed to use with CMake. Apparently it’s faster – as ninjas tend to be. In addition to CMake/Ninja, Zephyr is also working on a “meta-tool” called [**west**](https://docs.zephyrproject.org/latest/guides/west/index.html#west) which will replace the above eventually. But for now you can still use our masked friend.

### Device Trees

Your embedded device has a complex hierarchy of components, starting from higher level elements like LEDs and Buttons, down to SoC peripherals like I2C and ADC. In Linux, and in Zephyr, this hierarchy is represented as a _device tree_. The device tree resides in DTS (Device Tree Source) files – these are human readable text files. In Linux, these are compiled into binary DTB (Device Tree Blob) files using a DTC (Device Tree Compiler). In Zephyr, to reduce overhead, the DTS information is just used during compile time. The DTS files are naturally hierarchical. For example the _nrf52840\_pca10056.dts_ includes _nrf52840\_qiaa.dtsi_, which in turn includes _nrf52840.dtsi_ – going from board to chip variant to the core SoC.

If you are not familiar with device trees, the whole thing might seem a bit odd. But consider this: how does the Linux kernel support such a huge variety of third party devices without having to recompile the code every time? Because the device information can be passed into the kernel as a binary “blob” – the DTB.

So how do you get Zephyr to talk to your particular device? Chances are that a variant of this device is already supported by the kernel. So you take the relevant DTS and either make a modified copy of it, or write an _overlay_ for it – something that adds or modifies the existing device so it matches yours. The DTS file along with some other configuration files constitute the “board files” for your device. We’ll be creating these files for **hackaBLE** in this project, so things will become clearer further ahead.

### Config Files

Device Trees help you describe the hardware. There is another level of application-specific customisation required, which will let you enable only those features you really need. In Zephyr, this is done via the _Kconfig_ configuration system. The “board files” we talked about earlier contain some default configurations, which can be further refined using application specific configurations. For example, if you want to enable the Bluetooth subsystem, you would have this in your project’s _prj.conf_ file:

```
CONFIG_BT=y
```

Enabling only what you need is critical for embedded systems, since it has a direct impact on things like power consumption, memory, and performance.

Kconfig also provides an interactive UI for setting all the configuration options. Doing a `ninja menuconfig` in the _build_ directory with bring up this UI:

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 1](/images/2019/02/app_kernel_conf_1-1.png)

\[Image source: https://docs.zephyrproject.org/latest/application/index.html\]

_menuconfig_ gives you the entire configuration tree. You can search and navigate through this tree to set your relevant options. It’s a clunky interface, but it’s lightweight, and works across platforms. Once you set your options, save, and quit, you can rebuild your application with the new options. But here’s the catch – these options are saved inside your _build_ directory, and will be blown away if you delete this directory. So to save these options for the future, you need copy these to your _prj.conf_ file. (Here’s a menuconfig tip – while you are on a configuration option, press _Shift-?_, and you will get a help file that gives you the exact name of that option.)

Now let’s put this above knowledge to some use by building a couple of Zephyr applications on hackaBLE.

## Required Hardware

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 2](/images/2019/02/IMG_7765-e1550748770908-1.jpg)

You need the following hardware to build this project.

1.  Electronut Labs [hackaBLE](https://docs.electronut.in/hackaBLE/)
2.  Electronut Labs [Bumpy](https://docs.electronut.in/bumpy/) SWD programmer
3.  BME280 breakout board
4.  Breadboard, connecting wires

## Hello World on hackaBLE

The hackaBLE board is not directly supported by Zephyr, so the first thing we want to do is create the required board files. hackaBLE uses the Nordic nRF52832 SoC, so we’ll just modify the board files for the Nordic nRF52832-DK board which is already supported by Zephyr, and listed under _nrf52\_pca10040_.

### Adding hackaBLE to Zephyr

First, we need to copy _boards/arm/nrf52\_pca10040/_ to a new directory _boards/arm/nrf52\_hackable/_. Then we rename the files as follows:

```
board.cmake
Kconfig
Kconfig.board
Kconfig.defconfig
nrf52_hackable_defconfig
nrf52_hackable.dts
nrf52_hackable.yaml
```

The next step is to replace the occurrences of _pca10040_ inside the above files with _hackable_. The next important edit is for board.cmake which will contain just:

```
include(${ZEPHYR_BASE}/boards/common/blackmagicprobe.board.cmake)
```

This is required for us to program hackaBLE using the Bumpy SWD debugger, which is based on [blackmagicprobe](https://github.com/blacksphere/blackmagic/wiki). Next, we’ll edit the DTS file to map the correct pins to the peripherals we will be using.

```
&uart0 {
    status = "ok";
    compatible = "nordic,nrf-uart";
    current-speed = <115200>;
    tx-pin = <27>;
    rx-pin = <25>;
};

&i2c0 {
    status = "ok";
    sda-pin = <04>;
    scl-pin = <03>;
};
```

We need to use I2C and UART in this project, so we’ve correspondingly mapped the nRF52832 SoC peripherals to convenient pin numbers on hackaBLE.

### Code Setup

The Zephyr build system allows you to easily build your project outside the installation folder. It’s usually easiest to just copy a sample project over and then modify the configuration. In our case, the folder looks like this:

```
$ tree -L 2 hackable_zephyr_hello/
hackable_zephyr_hello/
___ build
___ CMakeLists.txt
___ prj.conf
___ README.rst
___ sample.yaml
___ src
    ___ main.c
```

Here’s what our prj.conf looks like:

```
CONFIG_GPIO=y
CONFIG_UART_CONSOLE=y
```

Remember our discussion on Kconfig? The above file tells CMake that we want to enable GPIOs and the UART console.

Our _main.c_ is very simple:

```
#include <zephyr.h>
#include <misc/printk.h>
#include <device.h>
#include <gpio.h>


void main(void)
{
    struct device* port0 = device_get_binding("GPIO_0");

    /* Set LED pin as output */
    gpio_pin_configure(port0, 17, GPIO_DIR_OUT);

    while (1) {
        // flash  LED
        gpio_pin_write(port0, 17, 0);
        k_sleep(500);
        gpio_pin_write(port0, 17, 1);
        k_sleep(500);

        printk("Hello World! %s\r\n", CONFIG_BOARD);

        k_sleep(2000);
    }
}
```

Let’s go through the above code quickly. The first thing it does is to get the _GPIO\_0_ device binding – again, this come from the DTS file, and nRF52832 has only one GPIO port – P0. We then configure P0.17 – the LED red channel – as an output. In the main loop, all we do is flash the LED and print “hello world”, with delays in between. The _printk_ outputs to the serial port, as per our config file which has enabled UART console – _CONFIG\_UART\_CONSOLE=y_.

Now we go into the _build_ directory and build our project as follows:

```
cmake -GNinja -DBOARD=nrf52_hackable ..
```

Before we upload the code, let’s take a look at the hardware hookup.

### Hardware Connections

For this project, hook up the hardware as follows so it matches up with our DTS and config files.

|**hackaBLE** | **Bumpy** | **BME280**|
|--|--|--|
| P0.27	| Rx | |
| P0.25	| Tx | |  	
| P0.03 | 	 | SCL |
| P0.04 |    | SDA |
| GND | GND	 | GND |
| VDD | 3V3	| VDD|

### Upload and Test

The last step is to flash the code:

```
$ ninja flash
[1/142] Preparing syscall dependency handling

[136/142] Linking C executable zephyr/zephyr_prebuilt.elf
Memory region         Used Size  Region Size  %age Used
           FLASH:       37220 B       512 KB      7.10%
            SRAM:       10924 B        64 KB     16.67%
        IDT_LIST:         120 B         2 KB      5.86%
[141/142] Flashing nrf52_hackable
Using runner: blackmagicprobe
Remote debugging using /dev/ttyACM0
Target voltage: unknown
Available Targets:
No. Att Driver
 1      Nordic nRF52
 2      Nordic nRF52 Access Port
Attaching to Remote target
0x0000556c in ?? ()
Loading section text, size 0xdc lma 0x0
Loading section _TEXT_SECTION_NAME_2, size 0x859a lma 0xe0
Loading section .ARM.exidx, size 0x8 lma 0x867c
Loading section sw_isr_table, size 0x138 lma 0x8684
Loading section devconfig, size 0x90 lma 0x87bc
Loading section rodata, size 0x62c lma 0x884c
Loading section datas, size 0x1e0 lma 0x8e78
Loading section initlevel, size 0x90 lma 0x9058
Loading section _k_sem_area, size 0x18 lma 0x90e8
Loading section _k_mutex_area, size 0x14 lma 0x9100
Loading section _k_queue_area, size 0x10 lma 0x9114
Loading section _net_buf_pool_area, size 0x40 lma 0x9124
Start address 0x1ae8, load size 37214
Transfer rate: 29 KB/sec, 775 bytes/write.
```

To test the output, we open a serial terminal using _picocom_:

```
picocom -e b -b 115200 /dev/ttyACM1
```

In the attached screenshot below, you can see the output:

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 3](/images/2019/02/Screenshot-from-2019-02-21-11-54-48-1024x576.png)

From the above, you also get an idea of my workflow. I use the _byobu_ terminal multiplexer, and the four screens from top left, going anti-clockwise are – zephyr build, USB monitoring using `dmesg -w`, picocom output, and a Python shell for calculations.

Now that we’ve got “hello” going. let’s try something more interesting.

## Building a BLE Temperature/Humidity Monitor

In this project, we’re going to enable the Zephyr BLE stack, communicate with the BME280 sensor using I2C, and then send the temperature and humidity data in two ways – via BLE advertisement packets, as well as via GATT characteristics – once a connection is made by a BLE central device like a mobile phone.

### Configuring BLE and BME280

To enable BLE, you need the following in your _prj.conf_:

```
##########
# for BLE
##########

# Incresed stack due to settings API usage
CONFIG_SYSTEM_WORKQUEUE_STACK_SIZE=2048

CONFIG_BT=y
CONFIG_BT_DEBUG_LOG=y
CONFIG_BT_SMP=y
CONFIG_BT_SIGNING=y
CONFIG_BT_PERIPHERAL=y
CONFIG_BT_GATT_DIS=y
CONFIG_BT_ATT_PREPARE_COUNT=2
CONFIG_BT_PRIVACY=y
CONFIG_BT_DEVICE_NAME="hackaBLE"
CONFIG_BT_DEVICE_APPEARANCE=833
CONFIG_BT_DEVICE_NAME_DYNAMIC=y
CONFIG_BT_DEVICE_NAME_MAX=65

CONFIG_BT_SETTINGS=y
CONFIG_FLASH=y
CONFIG_FLASH_PAGE_LAYOUT=y
CONFIG_FLASH_MAP=y
CONFIG_FCB=y
CONFIG_SETTINGS=y
CONFIG_SETTINGS_FCB=y
```

Oh, I didn’t come up with all the above stuff by myself. Zephy has fine BLE examples that I pilfered from. The above enables BLE and sets up various parameters – for example, _CONFIG\_BT\_PERIPHERAL=y_ says that our device is a _peripheral_, not a _central_, and _CONFIG\_BT\_DEVICE\_NAME=”hackaBLE”_ sets the name we advertise by.

Next we need to configure the BME280 sensor, which, luckily is already supported by Zephyr:

```
##########
# for I2C
##########
CONFIG_I2C=y
CONFIG_I2C_NRFX=y
CONFIG_I2C_0_NRF_TWIM=y
CONFIG_I2C_INIT_PRIORITY=60
CONFIG_I2C_0=y
CONFIG_BME280_I2C_MASTER_DEV_NAME="I2C_0"

##########
# for BME280
##########
CONFIG_SENSOR=y
CONFIG_BME280=y
```

Above, we first configure I2C, and there are some special settings for NRF which you can see above. Once I2C is enabled, we then enable the _sensor_ subsystem on Zephyr, and more specifically, the _BME280_ sensor.

### The Code

I won’t go through the whole code here, but here are the highlights.

We start by defining the main BLE service and the two characteristics we will be using – Temperature and Humidity:

```
static struct bt_uuid_128 vnd_uuid = BT_UUID_INIT_128(
    0xf0, 0xde, 0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12,
    0x78, 0x56, 0x34, 0x12, 0x78, 0x56, 0x34, 0x12);


static const struct bt_uuid_128 T_uuid = BT_UUID_INIT_128(
    0xf1, 0xde, 0xbc, 0x9a, 0x78, 0x56, 0x34, 0x13,
    0x78, 0x56, 0x34, 0x12, 0x78, 0x56, 0x34, 0x13);


static const struct bt_uuid_128 H_uuid = BT_UUID_INIT_128(
    0xf2, 0xde, 0xbc, 0x9a, 0x78, 0x56, 0x34, 0x13,
    0x78, 0x56, 0x34, 0x12, 0x78, 0x56, 0x34, 0x13);
```

These are added to the BLE subsystem as follows:

```
static struct bt_gatt_attr vnd_attrs[] = {
    /* Vendor Primary Service Declaration */
    BT_GATT_PRIMARY_SERVICE(&vnd_uuid),
    BT_GATT_CHARACTERISTIC(&T_uuid.uuid, 
                    BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                    BT_GATT_PERM_READ,
                    read_T, NULL, T_vals),
    BT_GATT_CCC(T_ccc_cfg, T_ccc_cfg_changed),
    BT_GATT_CHARACTERISTIC(&H_uuid.uuid, 
                    BT_GATT_CHRC_READ | BT_GATT_CHRC_NOTIFY,
                    BT_GATT_PERM_READ,
                    read_H, NULL, H_vals),
    BT_GATT_CCC(H_ccc_cfg, H_ccc_cfg_changed)
};
```

In the code above, you can see read/write functions assigned to each characteristic, as well as permissions, and the Client Characteristic Configuration Descriptor (CCCD) which lets the client (the central) enable notifications.

Here’s how we set up the BLE advertisement packet.

```
static volatile u8_t mfg_data[] = { 0x00, 0x00, 0xaa, 0xbb };

static const struct bt_data ad[] = {
    BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
    BT_DATA(BT_DATA_MANUFACTURER_DATA, mfg_data, 4),

    BT_DATA_BYTES(BT_DATA_UUID128_ALL,
              0xf0, 0xde, 0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12,
              0x78, 0x56, 0x34, 0x12, 0x78, 0x56, 0x34, 0x12),
};
```

Above, we’ll use the third and fourth bytes in _mfg\_data_ to send the most significant digits of temperature and humidity respectively.

We access the sensor in a manner similar to what we did with GPIO before:

```
dev_bme280 = device_get_binding("BME280");
```

Here’s how you get the BME280 data:

```
void update_sensor_data()
{

    // get sensor data
    struct sensor_value temp, press, humidity;

    sensor_sample_fetch(dev_bme280);
    sensor_channel_get(dev_bme280, SENSOR_CHAN_AMBIENT_TEMP, &temp);    
    sensor_channel_get(dev_bme280, SENSOR_CHAN_PRESS, &press);
    sensor_channel_get(dev_bme280, SENSOR_CHAN_HUMIDITY, &humidity);

    char strData[64];
    sprintf(strData, "T: %d H: %d",
            temp.val1, 
            humidity.val1);
    printk("temp: %d.%06d; press: %d.%06d; humidity: %d.%06d\n",
            temp.val1, temp.val2, press.val1, press.val2,
            humidity.val1, humidity.val2);

    mfg_data[2] = (uint8_t)temp.val1;
    mfg_data[3] = (uint8_t)humidity.val1;

    T_vals[0] = temp.val1;
    T_vals[1] = temp.val2;
    H_vals[0] = humidity.val1;
    H_vals[1] = humidity.val2;
}
```

In Zephyr, sensor data is stored in a struct as follows:

```
/**
 * @brief Representation of a sensor readout value.
 *
 * The value is represented as having an integer and a fractional part,
 * and can be obtained using the formula val1 + val2 * 10^(-6). Negative
 * values also adhere to the above formula, but may need special attention.
 * Here are some examples of the value representation:
 *
 *      0.5: val1 =  0, val2 =  500000
 *     -0.5: val1 =  0, val2 = -500000
 *     -1.0: val1 = -1, val2 =  0
 *     -1.5: val1 = -1, val2 = -500000
 */
struct sensor_value {
    /** Integer part of the value. */
    s32_t val1;
    /** Fractional part of the value (in one-millionth parts). */
    s32_t val2;
};
```

So in our code, we retrieve the temperature and humidity, and store them both for advertisement packets and for the characteristics.

Here’s our main loop:

```
while (1) {
    k_sleep(2*MSEC_PER_SEC);

    // update 
    update_sensor_data();

    // notify 
    bt_gatt_notify(NULL, &vnd_attrs[2], T_vals, sizeof(T_vals));
            bt_gatt_notify(NULL, &vnd_attrs[4], H_vals, sizeof(H_vals));

    // update adv data
    bt_le_adv_update_data(ad, ARRAY_SIZE(ad), NULL, 0);
}
```

What we’re doing above is notifying the connected device with the new sensor values as well as updating the advertising data.

### Build and Test

You can build and flash the code similar to the hello example. To test the device, we will be using the Nordic nRFConnect mobile app. Here’s what you see when you scan:

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 4](/images/2019/02/IMG_7761-e1550749119268-1.png)

In the above screenshot, you can see that the last two bytes of the advertisement packet manufacturer data is _0x1b21_ – 27 degree C with a humidity of 33%.

Now, let’s connect to it.

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 5](/images/2019/02/IMG_7762-e1550749105136-1.png)

You can see the UUID of the primary service we defined. If you click on it, you will see the characteristics:

![Getting Started with Zephyr RTOS on Nordic nRF52832 hackaBLE 6](/images/2019/02/IMG_7764-e1550749094953-1.png)

Taking some help from Python, we get:

```
>>> int(0x0000001b)
27
>>> int(0x000dbba0)
900000
>>> int(0x00000022)
34
>>> int(0x0002c959)
182617
```

Hence, T = 27.900000 deg C, H = 34.182617 %. If you enable notifications, you will see that these values update on the phone every two seconds, as per our code.

So here we are – a BLE device based on Nordic nRF52832 that transmits weather data, powered by the Zephyr RTOS!

___

### Programming hackaBLE without Bumpy

It’s perfectly possible to program hackaBLE without Bumpy. If you want to use the Nordic nRF52832-DK (PCA10040) for that purpose, you need to use the same _board.cmake_ as the PCA10040 in the board files. You’ll also need to match the Rx/Tx lines of hackaBLE and the DK in the DTS file to get the serial output.

___

## Conclusion

I learned a lot of programming on Linux. I always liked the “everything is a file” idea and standard programming concepts that worked across systems. Thinking in terms of processes, threads, inter-process communication mechanisms, sockets, etc. was natural, and these were concepts and programming conventions that were portable. But working with embedded systems today, vendor lock-in is a worrying trend, whether it be proprietary hardware programmers, expensive development tools, non portable APIs, or closed protocol stacks. There is a dire need for open, vendor-neutral frameworks like Zephyr, and the fact it follows the Linux model is a big plus in my view. We are definitely looking at Zephyr as the primary platform for our upcoming projects and products.

## Downloads

You can download the source code for this article at the link below:

[https://gitlab.com/electronutlabs-public/blog/hackable\_zephyr](https://gitlab.com/electronutlabs-public/blog/hackable_zephyr)

## Acknowledgements

I thank [Tavish Naruka](https://electronut.in/author/tavish/) for introducing me to Zephyr, as well as troubleshooting issues on various occasions.