-- 
--Load player inventory (on player spawn)
--
function LoadInventory(player)
    local playerID = player:SteamID()
    local data = sql.Query("SELECT item, slot_index FROM ei_players WHERE player_id = " .. sql.SQLStr(playerID))

    player.Inventory = {}

    if data then
        for _, row in ipairs(data) do
            table.insert(player.Inventory, {item = row.item, slotIndex = tonumber(row.slot_index)})
        end
    end

    print("Inventory loaded.")
end


--
-- Retrieve player inventory data
--
function RetrieveInventoryData(playerSteamID)
    local query = "SELECT id, item FROM ei_players WHERE player_id = " .. sql.SQLStr(playerSteamID)
    local result = sql.Query(query)

    if result then
        local inventoryData = {}
        for _, row in pairs(result) do
            table.insert(inventoryData, {id = tonumber(row.id), item = row.item})
        end
        return inventoryData
    else
        return {}
    end
end


--
-- Check if list contains item (ei_config)
--
function contains_item(items, name)
    for _, item in ipairs(items) do
        if item.name == name then
            return true, item.type 
        end
    end
    return false, nil
end


--
-- Function to get the item type based on the entity name
--
function getItemType(entName)
    for _, item in ipairs(allowedItems) do
        if item.name == entName then
            return item.type
        end
    end
    return nil
end


--
-- Function to save the picked up item to the database
--
function SavePickedUpItem(ply, modelPath, itemType, entName)
    local playerSteamID = ply:SteamID()
    
    local maxSlots = 37
    local reservedSlots = 2 
    local occupiedSlotsData = sql.Query("SELECT slot_index FROM ei_players WHERE player_id = " .. sql.SQLStr(playerSteamID))
    
    local occupiedSlots = {}
    if occupiedSlotsData then
        for _, row in ipairs(occupiedSlotsData) do
            local slotIndex = tonumber(row["slot_index"])
            occupiedSlots[slotIndex] = true
        end
    end

    local slotIndex = nil
    for i = reservedSlots + 1, maxSlots do
        if not occupiedSlots[i] then
            slotIndex = i
            break
        end
    end

    if not slotIndex then
        ply:ChatPrint("Your inventory is full. You cannot pick up more items.")
        return
    end

    if not itemType then
        print("Invalid item type")
        return
    end

    sql.Query("INSERT INTO ei_players (player_id, item, slot_index, slot_type) VALUES (" .. sql.SQLStr(playerSteamID) .. ", " .. sql.SQLStr(modelPath) .. ", " .. tonumber(slotIndex) .. ", " .. tonumber(itemType) .. ")")
end


--
-- Drops an item
--
function DropItem(ply, modelPath, slot_index)
    local playerSteamID = ply:SteamID()

    -- Select query to debug and ensure the row exists
    local selectQuery = [[
        SELECT id 
        FROM ei_players 
        WHERE player_id = ]] .. sql.SQLStr(playerSteamID) .. [[ 
        AND item = ]] .. sql.SQLStr(modelPath) .. [[
        AND slot_index = ]] .. sql.SQLStr(slot_index) .. [[
        LIMIT 1;
    ]]
    local selectResult = sql.Query(selectQuery)

    if selectResult and #selectResult > 0 then
        local rowID = selectResult[1].id
        local deleteResult = sql.Query("DELETE FROM ei_players WHERE id = " .. rowID .. "")

        if rowID then
            local entityClass = itemModelToEntityClass[modelPath]
            local droppedItem = ents.Create(entityClass)
            if not IsValid(droppedItem) then return end
            droppedItem:SetModel(modelPath)
            droppedItem:SetPos(ply:GetPos() + ply:GetForward() * 30 + Vector(0, 0, 20))
            droppedItem:Spawn()

            -- Ensure the item is solid and has physics
            droppedItem:SetSolid(SOLID_VPHYSICS)
            droppedItem:PhysWake()

            -- Check if the item is ammo and set the appropriate type and amount
            if ammoData[modelPath] then
                droppedItem.ammoType = ammoData[modelPath].type
                droppedItem.ammoAmount = ammoData[modelPath].amount
            end

            function droppedItem:StartTouch(ent)
                if ent:IsPlayer() then
                    return
                end
            end

            -- Override the Use function to allow manual pickup
            function droppedItem:Use(activator, caller)
                if not activator:IsPlayer() then return end
                
                if ammoData[modelPath] then
                    if not self.ammoType or not self.ammoAmount then
                        print("Error: Ammo type or amount is nil")
                        return
                    end
                    activator:GiveAmmo(self.ammoAmount, self.ammoType, true)

                    DarkRP.notify(activator, 0, 4, "You picked up " .. self.ammoAmount .. " rounds of " .. self.ammoType .. " ammo.")
                else
                    -- Implement your logic for picking up other item types
                end

                self:Remove()
            end

            -- Make the item usable
            droppedItem:SetUseType(SIMPLE_USE)
        else
            print("SQL Error during delete:", sql.LastError()) 
        end
    else
        print("SQL Error or no row found during select:", sql.LastError()) 
    end
end



--
-- Find substring in model path
--
function stringContains(str, substring)
    return string.find(str, substring) ~= nil
end