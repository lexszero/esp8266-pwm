# **esp8266-pwm** #

## Summary
Code for ESP8266 WiFi module with [NodeMcu firmware](https://github.com/nodemcu/nodemcu-firmware) to control PCA9685 PWM controller. You can easily build WiFi-controlled smart home equipment or toys with this. Also contains a demo application: RGB LED strip with WiFi.

Licensed under [WTFPL](http://www.wtfpl.net/)

## Requirements
### Hardware
- Any ESP8266 module
- PCA9685 connected to ESP's GPIOs

My hardware (so mad skillz!):
![](http://dump.bitcheese.net/files/iwonase/IMG_20150312_084053.jpg)

_TODO: example schematics, photo/video of actual hardware_

### Software
- [NodeMCU](https://github.com/nodemcu/nodemcu-firmware)
- [esptool](https://github.com/themadinventor/esptool) for flashing NodeMCU
- [luatool](https://github.com/4refr0nt/luatool) for uploading Lua code

## PCA9685 driver Lua API
~~TODO: maybe write something useful here~~

Read the source

There are also some useful stuff in `utils.lua`

## rgbstrip: demo application
Directory `rgbstrip` contains an application to control a RGB LED strip over WiFi via [MQTT protocol](https://en.wikipedia.org/wiki/MQTT). RGB channels are usually driven with MOSFETs controlled by PWM.

### Installation
- Connect ESP8266 to PC (we assume that device is connected to `/dev/ttyUSB0`)
- Install `NodeMCU`, if you don't have one:
```
./esptool/esptool.py --port /dev/ttyUSB0 erase_flash
./esptool/esptool.py --port /dev/ttyUSB0 write_flash 0x0 nodemcu-firmware/pre_build/latest/nodemcu_latest.bin
```
- Edit `rgbstrip/init.lua` and change configuration as you wish
- Upload Lua files
```
for f in pca9685.lua rgbstrip/*.lua; do
    ./luatool/luatool.py -f "$f" -t "`basename $f`" -p /dev/ttyUSB0 || break
done
```
- Pre-compile `pca9685.lua` and `server.lua` on ESP8266. This is needed because `NodeMCU` sometimes runs out of RAM when loading Lua modules. Open your favorite serial terminal program (**warning**: `init.lua` configures UART to 115200 baud, `NodeMCU`'s default is 9600). Run following commands in `NodeMCU` REPL:
```
node.compile('pca9685.lua')
node.compile('server.lua')
```
- If there was a compilation error, you can reset device and try again. Shit happens.
- If compilation was succesfull, there will be created `pca9685.lc` and `server.lc` files in `NodeMCU` filesystem. Now original files can be removed:
```
file.remove('pca9685.lua')
file.remove('server.lua')
```

### MQTT interface
To control RGB strip, publish a MQTT message with topic `<mqtt_topic>/rgb` (where `<mqtt_topic>` is what you set in `init.lua`) and payload with desired color as hex string (e.g. `ff00ff` - purple).

### rgbstrip.sh: a simple control tool
It uses [mosquitto](http://mosquitto.org/) to publish MQTT messages and Xdialog for  simple GUI.
* Set your MQTT credentials in `mqtt_args` variable in the beggining of the script
* Run `rgbstrip.sh` with one of the following arguments
	* `w` or `white`: set total brightness (r=g=b)
	* `c` or `color`: set color with regular color choose dialog
	* `h` or `hsvcolor`: set color with Hue/Saturation/Value sliders
	* `m` or `midi`: read MIDI control events from ALSA and set color accordingly
	* any other value: set color with Red/Green/Blue sliders
