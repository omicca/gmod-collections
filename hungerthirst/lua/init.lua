util.AddNetworkString("PlyNoFood")
util.AddNetworkString("PlyNoThirst")

util.AddNetworkString("PlyUseBottle")
util.AddNetworkString("PlyUseFood")

util.AddNetworkString("PlayerSpawn")

AddCSLuaFile("cl_init.lua")

local respawnTimerActive = {}

local function createSpawnTimer(ply)
    respawnTimerActive[ply] = true 
    timer.Simple(5, function()
        if IsValid(ply) then
            ply:Spawn()
            respawnTimerActive[ply] = false 
            timer.Simple(0, function()
                ply:Freeze(false)
            end)
        end
    end)
end

hook.Add("PlayerSay", "HungerCommand", function(ply, text, public)
    if (string.lower(text) == "/nohunger") then
        if not respawnTimerActive[ply] then 
            ply:Kill()
            respawnTimerActive[ply] = true 
            ply:Freeze(true)
            createSpawnTimer(ply)
        end
        return ""
    end
end)

hook.Add("PlayerDeath", "CancelRespawnOnDeath", function(ply)
    respawnTimerActive[ply] = false 
    ply:Freeze(false) 
end)

net.Receive("PlyNoFood", function(len, ply)
    ply:Say("/respawn")
end)

net.Receive("PlyNoThirst", function(len, ply)
    ply:Say("/nohunger")
end)

hook.Add("PlayerUse", "PlyUse", function(ply, ent)
    if ent:GetClass() == "some_drink" then
        ent:Remove()
        net.Start("PlyUseBottle")
        net.Send(ply)
    end

    if ent:GetClass() == "some_food" then
        ent:Remove()
        net.Start("PlyUseFood")
        net.Send(ply)
    end
end)

hook.Add("PlayerSpawn", "PlySpawn", function(ply)
    net.Start("PlayerSpawn")
    net.Send(ply)
end)
