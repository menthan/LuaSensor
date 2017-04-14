local module = {}

local function wifi_wait_ip()  
  if wifi.sta.getip()== nil then
    print("IP unavailable, Waiting...")
  else
    tmr.stop(1)
    print("IP is "..wifi.sta.getip())
    soc.start()
  end
end

function module.start()  
  print("ID: " .. config.ID)
  print("Configuring Wifi ...")
  wifi.setmode(wifi.NULLMODE); --workaround for firmware bug#1639
  wifi.setmode(wifi.STATION);
  for key,value in pairs(config.SSID) do
    wifi.sta.config(key,config.SSID[key])
    wifi.sta.connect()
    print("Connecting to " .. key .. " ...")
    tmr.alarm(1, 2500, 1, wifi_wait_ip)
  end
end

return module 
