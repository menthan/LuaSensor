local module = {}

module.SSID = {}  
module.SSID["name"] = "password"

module.HOST = "x.x.x.x"  
module.PORT = port
module.ID = node.chipid()

module.TOPIC = module.ID .. "/"

return module  
