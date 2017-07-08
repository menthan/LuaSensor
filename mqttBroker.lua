local module = {}  

local function handle_mqtt_error(client, reason) 
  tmr.create():alarm(10 * 1000, tmr.ALARM_SINGLE,  module.connect(function() end))
end

function module.connect(onConnect_function)
  client = mqtt.Client(config.ID, 120)
  client:lwt(config.TOPIC .. "status", "disconnected")
  client:connect(config.HOST, config.PORT, 
    function(c)
      module.publish("status", "connected")
      onConnect_function()
    end,
    handle_mqtt_error) 
end

function module.publish(subtopic, message)
  client:publish(config.TOPIC .. subtopic, message, 1, 0)
  print(config.TOPIC .. subtopic .. " " .. message)
end

return module
