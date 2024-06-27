AddCSLuaFile("easyinventory/cl_funcs.lua")
AddCSLuaFile("easyinventory/ei_client.lua")
include("easyinventory/sv_funcs.lua")
include("easyinventory/ei_config.lua")

--
-- Network strings
--
util.AddNetworkString("LoadInventory")
util.AddNetworkString("SendInventory")
util.AddNetworkString("PickupItem")
util.AddNetworkString("RequestInventoryData")
util.AddNetworkString("SendInventoryData")
util.AddNetworkString("DropInvItem")
util.AddNetworkString("RequestItemIndex")
util.AddNetworkString("SendItemIndex")
util.AddNetworkString("UpdateSlot")
util.AddNetworkString("GivePlyWeapon")
util.AddNetworkString("StripPlyWeapon")


--
-- If no DB, initialize
--
if not sql.TableExists("ei_players") then
    sql.Query("CREATE TABLE ei_players (id INTEGER PRIMARY KEY AUTOINCREMENT, player_id TEXT NOT NULL, item TEXT NOT NULL, slot_index INTEGER, slot_type INTEGER)")
end


--
-- Load player inventory on initial spawn
--
hook.Add("PlayerInitialSpawn", "LoadPlayerInventory", function(player)
    LoadInventory(player)
end)


--
-- Handle inventory request from client
--
net.Receive("RequestInventoryData", function(len, ply)
    local playerSteamID = ply:SteamID()
    local inventoryData = RetrieveInventoryData(playerSteamID)

    net.Start("SendInventoryData")
    net.WriteTable(inventoryData)
    net.Send(ply)
end)

--
-- Fetch item index for draggable inventory item
--
net.Receive("RequestItemIndex", function(len, ply)
    local playerSteamID = ply:SteamID()
    local sqlResult = sql.Query("SELECT slot_index, item, id, slot_type FROM ei_players")

    if sqlResult then
        net.Start("SendItemIndex")
        net.WriteTable(sqlResult)
        net.Send(ply)
    else
        net.Start("SendItemIndex")
        net.WriteTable({})
        net.Send(ply)
    end
end)


--
-- Handle item pickup from client
--
net.Receive("PickupItem", function(len, ply)
    local modelPath = net.ReadString()
    local entityIndex = net.ReadInt(32)
    local entity = Entity(entityIndex)
    
    if not IsValid(entity) then
        print("Invalid entity received from client.")
        return
    end
    local entityName = entity:GetClass() 

    local allowed, itemType = contains_item(allowedItems, entityName)
    if allowed then
        if stringContains(modelPath, "rif") then
            itemType = 2
        else if stringContains(modelPath, "pist") then
            itemType = 1
        end
        end
        SavePickedUpItem(ply, modelPath, itemType, entityName)
        entity:Remove()
    else
        print("Invalid model path received from client.")
    end
end)


--
-- Receive drop request from client
--
net.Receive("DropInvItem", function(len, ply)
    local modelPath = net.ReadString()
    local slot_index = net.ReadInt(32)
    DropItem(ply, modelPath, slot_index)
end)


--
-- Update item position with slot index
--
net.Receive("UpdateSlot", function(len, ply)
    local slotIndex = net.ReadInt(32) -- Read the slotIndex as a signed 32-bit integer
    local modelPath = net.ReadString() -- Read the modelPath as a string
    local uniqueId = net.ReadInt(32) -- Read the itemID as a signed 32-bit integer

    if slotIndex and modelPath and uniqueId then
        sql.Query("UPDATE ei_players SET slot_index = " .. tonumber(slotIndex) .. " WHERE player_id = " .. sql.SQLStr(ply:SteamID()) .. " AND id = " .. tonumber(uniqueId))
    else
        print("Error: Slot index, slot type, model path, or item ID is nilll")
    end
end)


--
-- Give player weapon if dropped in slot 1 || 2
--
net.Receive("GivePlyWeapon", function(len, ply)
    local slotIndex = net.ReadInt(32)
    local swepClass = net.ReadString():Trim()

    if slotIndex == 1 then
        ply:Give(swepClass, false)
        ply:SelectWeapon(swepClass)
    elseif slotIndex == 2 then
        ply:Give(swepClass)
        ply:SelectWeapon(swepClass)
    end
end)

--
-- Strip weapon if removed from slot 1 || 2
--
net.Receive("StripPlyWeapon", function(len, ply)
    local slotIndex = net.ReadInt(32)
    local swepClass = net.ReadString():Trim()

    if slotIndex == 1 then
        if ply:HasWeapon(swepClass) then
            ply:StripWeapon(swepClass)
        end
    elseif slotIndex == 2 then
        if ply:HasWeapon(swepClass) then
            ply:StripWeapon(swepClass)
        end
    end
end)
