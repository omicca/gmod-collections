if SERVER then 
    include("init.lua")
    AddCSLuaFile()
else
    include("cl_init.lua")
end