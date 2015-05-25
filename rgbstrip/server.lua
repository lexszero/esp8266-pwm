if mqtt_clientid == nil then
	mqtt_clientid='esp8266_' .. wifi.sta.getmac()
end
if mqtt_topic == nil then
	mqtt_topic='/'..mqtt_clientid
end

function rgb(r, g, b)
	pca9685.set_chan_byte(pwm_channels[1], r)
	pca9685.set_chan_byte(pwm_channels[2], g)
	pca9685.set_chan_byte(pwm_channels[3], b)
end

function rgb1(val)
	rgb(bit.band(bit.rshift(val, 16), 0xFF),
		bit.band(bit.rshift(val, 8), 0xFF),
		bit.band(val, 0xFF))
end

function hsv(h, s, v)
	rgb(hsv2rgb(h, s, v))
end

m = mqtt.Client(mqtt_clientid, 120, mqtt_user, mqtt_password)

mqtt_online = false

function mqtt_connect()
	print('mqtt: connecting')
	m:connect(mqtt_host, mqtt_port, mqtt_secure, function(conn)
		print('mqtt: connected')
		mqtt_online = true
		m:subscribe(mqtt_topic..'/rgb', 0, function(conn)
			print('mqtt: subscribed')
		end)
	end)
end

m:on('connect', function(conn)
	mqtt_online = true
	print('mqtt: conected')
end)
m:on('offline', function(conn)
	mqtt_online = false
	print('mqtt: offline')
end)
m:on('message', function(conn, topic, data)
	print(topic .. ":" )
	if data ~= nil then
		print(data)
	else
		return
	end

	if t == mqtt_topic..'/rgb' then
		rgb1(tonumber(data, 16))
	end
end)

tmr.alarm(0, 1000, 1, function()
	if wifi.sta.getip() == nil then
		print('wifi: connecting')
	else
		if mqtt_online == false then
			mqtt_connect()
		end
	end
end)


