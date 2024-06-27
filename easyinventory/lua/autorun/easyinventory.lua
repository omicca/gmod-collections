if SERVER then
    include("easyinventory/ei_server.lua")
    AddCSLuaFile("easyinventory/ei_config.lua")
else 
    include("easyinventory/ei_client.lua")
    include("easyinventory/cl_funcs.lua")
end