local module = {}  

OW_PIN = 5
hold = false

function publish(topic, message)
  m:publish(topic, message, 1, 0)
  print(topic.. message)
end

function debounced_trigger(pin, onchange_function, dwell)
  local function trigger_cb(pin_state)
    tmr.stop(6)
    tmr.alarm(5, dwell, 0, function()
      onchange_function(pin)
    end)
  end
  gpio.trig(pin, 'both', trigger_cb)
end

function onChange (pin)
  local released = gpio.read(pin) == 1
  if released and hold then
    publish(config.TOPIC .. "D"..pin, "release")
  elseif released and not hold then
    publish(config.TOPIC .. "D"..pin, "press")
  end
  hold = false
  local function late_cb(pin)
    if not released then
      hold = true
      publish(config.TOPIC .. "D"..pin, "hold")
    end
  end
  tmr.alarm(6, 1000, tmr.ALARM_SINGLE, function() late_cb(pin) end)
end

local function watch_di()
  for i=1,8 do
    gpio.mode(i, gpio.INT, gpio.PULLUP)
    debounced_trigger(i, onChange, 500)
  end
end

-- Onewire functions 
local function setup_ow()
    local count = 0
    repeat
      count = count + 1
        ow.setup(OW_PIN)
        addr = ow.reset_search(OW_PIN)
        addr = ow.search(OW_PIN)
      tmr.wdclr()
    until (addr ~= nil) or (count > 100)
    if addr == nil then
      publish(config.TOPIC .. "temp", "not connected")
    end
end

local function temperature()
   ow.reset(OW_PIN)
   ow.select(OW_PIN, addr)
   ow.write(OW_PIN,0xBE,1)
   local data = ""
   for i = 1, 9 do
     data = data .. string.char(ow.read(OW_PIN))
   end
  -- print(data:byte(1,9))
   local crc = ow.crc8(string.sub(data,1,8))
   --print("CRC="..crc)
   if crc == data:byte(9) then
     local t = (data:byte(1) + data:byte(2) * 256) * 625 / 100
     print("Temperature="..t.."Centigrade")
     publish(config.TOPIC .. "temp", t)
   end
   -- reset bus
   ow.reset(OW_PIN)
   ow.select(OW_PIN, addr)
   ow.write(OW_PIN, 0x44, 1)
end
  
function module.start()
  m = mqtt.Client(config.ID, 120)
  m:connect(config.HOST, config.PORT, 0, 1, 
    function(con) 
      watch_di()
      setup_ow()
      if addr then 
        -- publish temperature
        tmr.stop(4)
        tmr.alarm(4, 5*60000, 1, temperature)
      end
    end
  ) 
end

return module  
