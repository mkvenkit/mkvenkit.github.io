---
layout: post
title: "nRF52840 based GPS Logging device"
excerpt: "GPS TRACKING DEVICE WITH NRF52840 BLIP"
tags: [nRF52840, blip, GPS, U-blox]
categories: [Electronics, programming]
comments: false
modified: 2018-12-14
thumbnail: images/2018/nrf52840_gps/medow2.jpg
images: images/2018/nrf52840_gps/medow2.jpg
---

**Author: [Vaishali Pathak](https://github.com/Pathak94)**

**Editor: Mahesh Venkitachalam**


Last weekend, my colleagues and I decided to go on a trek to [Kudremukh peak](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=40&cad=rja&uact=8&ved=2ahUKEwjd6pq4p5_fAhUJ3o8KHUA2B_sQwaICMCd6BAgDEA4&url=https%3A%2F%2Fwww.karnataka.com%2Fkudremukh%2Fkudremukh-trek%2F&usg=AOvVaw3DVIuRjED7lqVBHDBc92T1) in the Western Ghats. We thought, how about recording the GPS data throughout the trek. We quickly assembled a GPS module with our upcoming board **blip**, which is a development board based on Nordic's [nRF52840](https://openthread.io/platforms/nrf52840) chip. Blip has onboard SD card slot which made our job easier, to collect and store data.

![c_cpp_Set1](/images/2018/nrf52840_gps/bli_gps_connection.jpg)

## Hardware used
* [blip](https://docs.electronut.in/ElectronutLabs-blip/)
* [U-Blox GPS module](https://robu.in/product/ublox-neo-6m-gps-module/)
* A plastic box

![c_cpp_Set1](/images/2018/nrf52840_gps/blip_gps.jpg)


Later, we planned to upload GPS data to the [Google Earth](https://www.google.com/intl/en_in/earth/) to plot the trail. We used a normal power bank to power the blip and GPS module. We kept it in the outside pocket of the backpack.

![c_cpp_Set1](/images/2018/nrf52840_gps/backpack.jpg)

The trek started. We covered more than 20 km both ways, the view was breathtaking. It was definitely an exhilarating experience. 

![c_cpp_Set1](/images/2018/nrf52840_gps/medow2.jpg)

After returning we were excited to upload the collected GPS data to google earth. After connecting the SD card and scanning the data for while, we realized that we have missed several hours of data, this what happens when you code in haste :P. But that's okay at least we were able to plot some data points. We converted the GPS data in KML format and plotted to Google Earth. We were happy to see our somewhat successful attempt and that was enough for us.

![c_cpp_Set1](/images/2018/nrf52840_gps/google_earth_path.jpg)

Top view

![c_cpp_Set1](/images/2018/nrf52840_gps/google_e_top.jpg)

If you wish to see the firmware and scripts for the code, you can find the link below. At last, I want to thank all my colleagues at [Electronut Labs](https://electronut.in/) especially [Ajay](https://github.com/intajay) for helping me complete the project. 

## Firmware and scripts 

[blip-gps-logger](https://github.com/electronut/blip-gps-logger)


Happy Trekking and Happy Coding! :)
![c_cpp_Set1](/images/2018/nrf52840_gps/trek_shoes.jpg)