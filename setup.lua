local module = {}

local function wifi_wait_ip()  
  if wifi.sta.getip() then
    tmr.stop(1)
    print("IP is "..wifi.sta.getip())
    m.connect(soc.sense)
  end
end

function module.start()  
  print("ID: " .. config.ID)

  wifi.setmode(wifi.NULLMODE); --workaround for firmware bug#1639
  wifi.setmode(wifi.STATION);
  
  wifi.sta.config(config.SSID,config.PASS)
  wifi.sta.connect()
  print("Connecting to " .. config.SSID .. " ...")
  tmr.alarm(1, 2500, 1, wifi_wait_ip)
end

return module 
