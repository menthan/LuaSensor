local module = {}

module.SSID = {}  
module.SSID["name"] = "password"

module.OW_PIN = 5

module.HOST = "x.x.x.x"  
module.PORT = port
module.ID = node.chipid()

module.TOPIC = module.ID .. "/"

return module  
