local module = {}  

function publish(topic, message)
  m:publish(topic, message, 1, 0)
  print(topic.. message)
end

function debounced_trigger(pin, onchange_function)
  local function trigger_cb(pin_state)
    tmr.stop(6) -- reset late_cb timer
    tmr.alarm(5, 500, 0, function() onchange_function(pin) end)
  end
  gpio.trig(pin, 'both', trigger_cb)
end

function onChange (pin)
  local high = gpio.read(pin) == 1
  if high and stable then
    publish(config.TOPIC .. "D"..pin, "high")
  elseif high and not stable then
    publish(config.TOPIC .. "D"..pin, "pulse")
  end
  stable = false
  local function late_cb(pin)
    if not high then
      stable = true
      publish(config.TOPIC .. "D"..pin, "low")
    end
  end
  tmr.alarm(6, 1000, tmr.ALARM_SINGLE, function() late_cb(pin) end)
end

local function watch_di()
  for i=1,8 do
    gpio.mode(i, gpio.INT, gpio.PULLUP)
    debounced_trigger(i, onChange)
  end
end

-- Onewire functions 
local function setup_ow()
    local count = 0
    repeat
      count = count + 1
        ow.setup(config.OW_PIN)
        addr = ow.reset_search(config.OW_PIN)
        addr = ow.search(config.OW_PIN)
      tmr.wdclr()
    until (addr ~= nil) or (count > 100)
    if addr == nil then
      publish(config.TOPIC .. "temp", "not connected")
    end
end

local function temperature()
   ow.reset(config.OW_PIN)
   ow.select(config.OW_PIN, addr)
   ow.write(config.OW_PIN,0xBE,1)
   local data = ""
   for i = 1, 9 do
     data = data .. string.char(ow.read(config.OW_PIN))
   end
   local crc = ow.crc8(string.sub(data,1,8))
   --print("CRC="..crc)
   if crc == data:byte(9) then
     local t = (data:byte(1) + data:byte(2) * 256) * 625 / 100
     publish(config.TOPIC .. "temp", t)
   end
   -- reset bus
   ow.reset(config.OW_PIN)
   ow.select(config.OW_PIN, addr)
   ow.write(config.OW_PIN, 0x44, 1)
end
  
function module.start()
  m = mqtt.Client(config.ID, 120)
  m:connect(config.HOST, config.PORT, 0, 1, 
    function(con) 
      watch_di()
      setup_ow()
      if addr then 
        -- update temperature every 5 minutes
        tmr.stop(4)
        tmr.alarm(4, 5*60000, 1, temperature)
      end
    end
  ) 
end

return module  
