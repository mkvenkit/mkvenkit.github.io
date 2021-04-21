---
layout: post
title: "Using Visual Studio Code for Nordic nRF5 BLE Debugging"
excerpt: "Using Cortex Debug for Nordic nRF5x on Visual Studio Code and bumpy"
tags: [cortex, debug, nRF52832, hackaBLE, bumpy, visual studio code, vscode]
categories: [Electronics, programming]
comments: false
modified: 2018-07-17
thumbnail: images/2018/07/cortex_debug.png
images: images/2018/07/cortex_debug.png
---

**Author: Vaishali Pathak**

**Editor: Mahesh Venkitachalam**

Here at Electronut Labs, we work extensively on Bluetooth Low Energy technology, and we have chosen Nordic Semiconductors nRF5x series boards for developing our products. 

(We have our own range of breakout boards based on nRF5x series microcontrolers. You can visit out [website](https://electronut.in/portfolio/) or [tindie](https://www.tindie.com/stores/ElectronutLabs/) to purchase our boards.)

We really like Visual Studio Code editor for development. Their UI is very modern and slick, and they provide nice extensions which will make your coding tasks easier. I am going to talk about one useful extension for debugging here - *Cortex Debug* - which adds debugging support for ARM Cortex-M Microcontrollers.

**Cortex Debug** on Visual Studio Code is very fast and efficient. I will show you how to set it up, and this setup is going to work with any nRF5x development boards. Later, I am going to show you how to debug on our nRF5x breakout board [hackaBLE](https://electronut.in/portfolio/hackaBLE/) and program it using [Bumpy](https://electronut.in/portfolio/bumpy/), our SWD programmer.

Before talking about debugging, we will set c/c++ configuration settings which will make coding and debugging very convinient. After adding c/c++ configuration settings you can directly go to a function definition by just clicking on it. Click on *view* from the menu and select c/cpp edit configurations and it will open c_cpp_properties.json file then write this congiguration settings as shown below(note: I've only added path for linux machine, you can add your own paths depending on your machine).

<script src="https://gist.github.com/Pathak94/fa64817a8060e086d62cce150dc53e7e.js"></script>

For example, if you right click on *ble_stack_init()* and select go to definition

![c_cpp_Set1](/images/2018/07/c_cpp_Set1.png)

You will directly go to the function definition.

![c_cpp_Set2](/images/2018/07/c_cpp_set2.png)

This configuration settings will reduce your time as well as effort while you are debugging.

### Setting up Cortex Debug configuration in VSCode

![Cortex Debug screen](/images/2018/07/cortex_debug.png)

Debugging ble_app_hrs example from nRF5 SDK. 

Before setting up Cortex Debug you need to install the following:

1. [ARM GCC Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads) provides arm-none-eabi-gdb related tools.
2. [J-Link Software tools](https://www.segger.com/downloads/jlink) provides J-Link GDB server for J-Link based debggers.
3. Then you will need the following extensions.

    1. Install C/C++ Extension.
    2. Install Intellisense.
    3. Install Cortex Debug

The installation screens are shown below.

![c/c++ extension](/images/2018/07/cextension.png)    

![intellisense](/images/2018/07/intellisense.png)

![cortex_debug](/images/2018/07/cortex_Debug.png)


After this last step is to set configuration properties in launch settings. Go to debug menu and click add configurations. Now you can see launch.json file. Now edit this file and add the following. 

<script src="https://gist.github.com/Pathak94/15fe63c3e3efa6d0845fe84e284aaf82.js"></script>


Your launch.json file should look like this.

![nrf_launch](/images/2018/07/nrf_launch.PNG)


Now, you are all set to debug your project. Go to Debug menu in Visual Studio code and select start debugging. you will see a small tab menu will appear, like this.

![debug_tab_menu](/images/2018/07/tab_debug_menu.png)

If you hover over the menu you will see it will allow you to step through, step into, step out, restart and stop the debugging. You also see three windows in the left for variable, stack and watch, this will keep track of all the variables currently present in the scope, the program stack.

![variable_stack](/images/2018/07/stack_variable.png)

As you can see it is very fast and easy to use.

## Debugging hackaBLE using Bumpy

I would like to briefly introduce our products hackaBLE and Bumpy before proceding further. 

[**hackaBLE**](https://electronut.in/portfolio/hackaBLE/) 

hackaBLE is a tiny (~ 18 mm x 28 mm) Open Source Nordic nRF52832 based BLE development board you can embed in your BLE projects.

[**Bumpy**](https://electronut.in/portfolio/bumpy/)

Bumpy is an inexpensive Open Source blackmagic probe compatible SWD debugger designed to be used with ARM GDB. It supports many platforms, but was primarily designed for use with our Nordic Semiconductor nRF BLE boards. 

![hackable_bumpy](/images/2018/07/hackaBLE-prog1.jpg)

[Here](https://github.com/electronut/ElectronutLabs-hackaBLE) is the full documentation about how to use hackaBLE and program it using [Bumpy](https://github.com/electronut/ElectronutLabs-Bumpy). 

**Setting up Cortex Debug configurations for Bumpy**

![hackable_bumpy_debug](/images/2018/07/hackaBLE-prog_debugging.jpg)

Since Bumpy is blackmagic probe based SWD debugger you need to set its specific launch settings. Here's what you need to write in launch.json file for configuring debugging in VS Code.

<script src="https://gist.github.com/Pathak94/d4801dea5dd5f883551c39a58be3da3d.js"></script>

![Bumpy_settings](/images/2018/07/bmp_settings.png)

As you can see most of the configuration properties are same as before, except the ones specific for blackmagic probe debugger. And, now you use Bumpy to debug on your project.

### CONCLUSION 

In this article we saw how you can easily set up and configure Cortex Debug Extention in Visual Studio Code. We also showed you how to debug using Bumpy, our blackmagic SWD programmer. Hope you find this article helpful.

### ACKNOWLEDGEMENTS

I want to thank Tavish from [Electronut Labs](https://electronut.in/) for suggesting us to use Cortex Debug.

### References

1. [Cortex Debug Project](https://marcelball.ca/projects/cortex-debug/) by marcelball.























