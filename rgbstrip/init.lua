-- Configure UART to 115200 8N1
uart.setup(0, 115200, 8, 0, 1, 1)

-- Initialize I2C bus with SDA on GPIO0, SCL on GPIO2
-- https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en#new_gpio_map
i2c.setup(0, 3, 4, i2c.SLOW)

-- Initialize PCA9685 PWM controller
-- Args:
--	i2c bus id (should be 0)
--	i2c address (see pca9685 datasheet)
--	mode - 16-bit value, low byte is MODE1, high is MODE2 (see datasheet)
require('pca9685')
pca9685.init(0, 0x40, 0)

-- PWM channels used for R, G, B colors. 
pwm_channels={0, 1, 2}

-- Setup Wi-Fi connection
wifi.setmode(wifi.STATION)
wifi.sta.config('HomeNetwork', 'VerySecretPassword')

-- MQTT parameters
-- Will subscribe to messages on topic <mqtt_topic>/rgb
-- Publish a message with hex color value (e.g. "ff00ff" - purple)
mqtt_host='192.168.0.1'
mqtt_port='1883'
mqtt_user='test'
mqtt_password='test'
mqtt_secure=0
mqtt_clientid='room-rgbstrip'	-- Default: "esp8266_<MACADDR>"
mqtt_topic='/room/rgbstrip'		-- Default: "/<clientid>"

dofile('server.lc')
