include("easyinventory/cl_funcs.lua")
include("easyinventory/ei_config.lua")

inventoryOpen = false
net.Receive("SendInventoryData", function()
    local inventoryData = net.ReadTable()
    if (inventoryOpen == false) then
        inventoryOpen = true;
        DisplayInventoryData(inventoryData)
    end
end)

//delay for inventory
local coolDowm = 0.5
local lastInventoryAction = 0
hook.Add("PlayerButtonDown", "HandleInventory", function(ply, button)
    if button == KEY_G then
        local currentTime = CurTime()
        if currentTime - lastInventoryAction >= coolDowm then
            if !inventoryOpen then
                net.Start("RequestInventoryData")
                net.SendToServer()
            end
            lastInventoryAction = currentTime  
        end
    end
end)

//delay for pickup
local lastPickupTime = 0
local pickupDistance = 100
local maxDistance = 50
hook.Add("KeyPress", "HandleItemPickup", function(ply, key)
    if input.IsKeyDown(KEY_LALT) and input.IsKeyDown(KEY_R) then
        local currentTime = CurTime()
        if currentTime - lastPickupTime >= coolDowm then
            local trace = ply:GetEyeTrace()
            if IsValid(trace.Entity) then
                local modelPath = trace.Entity:GetModel()
                local entityIndex = trace.Entity:EntIndex()
                print(trace.Entity:GetClass())
                print(modelPath)
                local distance = ply:GetPos():Distance(trace.Entity:GetPos())  
                if distance <= maxDistance then
                    if modelPath then
                        net.Start("PickupItem")
                        net.WriteString(modelPath)
                        net.WriteInt(entityIndex, 32)
                        net.SendToServer()
                    end
                end
            end
            lastPickupTime = currentTime  
        end
    end
end)


local inventorySlots = {}
local inventoryPanel
local function HandleDrop(targetSlot, item, uniqueId)
    local oldParent = item:GetParent()
    local oldSlotIndex = table.KeyFromValue(inventorySlots, oldParent)
    local newSlotIndex = table.KeyFromValue(inventorySlots, targetSlot)
    
    if oldParent ~= targetSlot then
        item:SetParent(targetSlot)
        item:SetPos(8, 8)
        item:Center()
        oldParent:InvalidateLayout(true)
        targetSlot:InvalidateLayout(true)
        
        local modelPath = item:GetModel()
        local weaponClass = modelToWeaponClass[modelPath] 

        if oldSlotIndex <= 2 and (newSlotIndex > 2 or newSlotIndex == nil) then
            net.Start("StripPlyWeapon")
            net.WriteInt(oldSlotIndex, 32)
            net.WriteString(weaponClass)
            net.SendToServer()
        end

        if newSlotIndex <= 2 then
            net.Start("GivePlyWeapon")
            net.WriteInt(newSlotIndex, 32)
            net.WriteString(weaponClass) 
            net.SendToServer()
        end

        if newSlotIndex and modelPath then
            net.Start("UpdateSlot")
            net.WriteInt(newSlotIndex, 32)
            net.WriteString(modelPath)
            net.WriteInt(uniqueId, 32)
            net.SendToServer()
        else
            print("Error: Slot index or model path is nil")
        end
    end
end

local SLOT_TYPE_REGULAR = 0
local SLOT_TYPE_RIFLE = 2
local SLOT_TYPE_PISTOL = 1
-- Function to display inventory data
function DisplayInventoryData(inventoryData)
    -- Close existing inventory panel if it exists
    if IsValid(inventoryPanel) then
        inventoryPanel:Close()
    end

    -- Show overlay panel and player model
    ShowDarkOverlayPanel()
    ShowPlayerModelPanel()

    -- Create new inventory panel
    inventoryPanel = vgui.Create("DFrame")
    inventoryPanel:SetSize(630, 700)
    inventoryPanel:SetTitle("")
    inventoryPanel:MakePopup()
    inventoryPanel:Center()
    inventoryPanel:ShowCloseButton(false)
    inventoryPanel:SetDraggable(false)
    inventoryPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 200))
    end

    -- Clear existing inventory slots
    for _, slot in ipairs(inventorySlots) do
        slot:Remove()
    end
    inventorySlots = {} -- Clear the inventorySlots table

    -- Create inventory slots
    CreateInventorySlots(inventoryPanel)

    -- Request inventory data from the server
    net.Start("RequestItemIndex")
    net.SendToServer()
    net.Receive("SendItemIndex", function()
        local sqlResult = net.ReadTable()

        for _, row in ipairs(sqlResult) do
            local slotIndex = tonumber(row.slot_index)
            local slot = inventorySlots[slotIndex]
            local item = row.item
            local id = row.id
            local slot_type = row.slot_type
            if slot then
                DraggableInvItem(slot, item, id, slot_type, slotIndex)
            end
        end
    end)

    -- Close inventory panel when the 'G' key is pressed
    function inventoryPanel:OnKeyCodePressed(keyCode)
        if keyCode == 17 then -- 'G' key code
            if IsValid(inventoryPanel) then
                inventoryPanel:Close()
                HidePlayerModelPanel()
                HideDarkOverlayPanel()
                inventoryOpen = false
                lastInventoryAction = CurTime()
            end
        end
    end
end


-- Function to create inventory slots
function CreateInventorySlots(parent)
    local iconLayout = vgui.Create("DIconLayout", parent)
    iconLayout:Dock(BOTTOM)
    iconLayout:SetSpaceY(10)
    iconLayout:SetSpaceX(10)

    -- Create slot for equipping rifles
    local rifleSlot = iconLayout:Add("DPanel")
    rifleSlot:SetSize(305, 85)
    rifleSlot.slotType = SLOT_TYPE_RIFLE
    rifleSlot.Paint = function(self, w, h)
        -- Draw the main background
        draw.RoundedBox(5, 0, 0, w, h, Color(50, 50, 50, 200))
        
        -- Draw the glassy dark border
        local borderWidth = 2
        draw.RoundedBox(5, 0, 0, w, borderWidth, Color(0, 0, 0, 150)) -- Top border
        draw.RoundedBox(5, 0, h - borderWidth, w, borderWidth, Color(0, 0, 0, 150)) -- Bottom border
        draw.RoundedBox(5, 0, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Left border
        draw.RoundedBox(5, w - borderWidth, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Right border
    end
    rifleSlot:Receiver("InventoryItem", function(receiver, droppedItems, isDropped, menuIndex, mouseX, mouseY)
        if isDropped then
            local droppedItem = droppedItems[1]
            if droppedItem then
                local itemType = tonumber(droppedItem.itemType)
                if (itemType == rifleSlot.slotType) then
                    droppedItem:OnDrop(rifleSlot)
                else
                    print("Only rifles can be placed in this slot.")
                end
            end
        end
    end)
    table.insert(inventorySlots, rifleSlot)

    -- Create slot for equipping pistols
    local pistolSlot = iconLayout:Add("DPanel")
    pistolSlot:SetSize(305, 85)
    pistolSlot.slotType = SLOT_TYPE_PISTOL
    pistolSlot.Paint = function(self, w, h)
        -- Draw the main background
        draw.RoundedBox(5, 0, 0, w, h, Color(50, 50, 50, 200))
        
        -- Draw the glassy dark border
        local borderWidth = 2
        draw.RoundedBox(5, 0, 0, w, borderWidth, Color(0, 0, 0, 150)) -- Top border
        draw.RoundedBox(5, 0, h - borderWidth, w, borderWidth, Color(0, 0, 0, 150)) -- Bottom border
        draw.RoundedBox(5, 0, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Left border
        draw.RoundedBox(5, w - borderWidth, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Right border
    end
    pistolSlot:Receiver("InventoryItem", function(receiver, droppedItems, isDropped, menuIndex, mouseX, mouseY)
        if isDropped then
            local droppedItem = droppedItems[1]
            if droppedItem then
                local itemType = tonumber(droppedItem.itemType)
                if (itemType == pistolSlot.slotType) then
                    droppedItem:OnDrop(pistolSlot)
                else
                    print("Only pistols can be placed in this slot.")
                end
            end
        end
    end)
    table.insert(inventorySlots, pistolSlot)

    -- Create regular inventory slots
    for i = 1, 35 do
        local slot = iconLayout:Add("DPanel")
        slot:SetSize(80, 80)
        slot.slotType = SLOT_TYPE_REGULAR
        slot.Paint = function(self, w, h)
            -- Draw the main background
            draw.RoundedBox(5, 0, 0, w, h, Color(50, 50, 50, 200))
            
            -- Draw the glassy dark border
            local borderWidth = 2
            draw.RoundedBox(5, 0, 0, w, borderWidth, Color(0, 0, 0, 150)) -- Top border
            draw.RoundedBox(5, 0, h - borderWidth, w, borderWidth, Color(0, 0, 0, 150)) -- Bottom border
            draw.RoundedBox(5, 0, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Left border
            draw.RoundedBox(5, w - borderWidth, 0, borderWidth, h, Color(0, 0, 0, 150)) -- Right border
        end
        
        -- Set up the slot to receive draggable items
        slot:Receiver("InventoryItem", function(receiver, droppedItems, isDropped, menuIndex, mouseX, mouseY)
            if isDropped then
                local droppedItem = droppedItems[1]
                if droppedItem then
                    droppedItem:OnDrop(slot)
                end
            end
        end)
        
        table.insert(inventorySlots, slot)
    end
end

-- Function to create draggable items
function DraggableInvItem(slot, itemModelPath, uniqueId, itemType, slotIndex)
    local item = vgui.Create("DModelPanel", slot)
    item:SetSize(64, 64)
    item:SetModel(itemModelPath)
    item:Droppable("InventoryItem")
    item:Center()
    item.uniqueId = uniqueId 
    item.itemType = tostring(itemType) 
    item.slotIndex = slotIndex

    function item:OnMousePressed(keyCode)
        if keyCode == MOUSE_RIGHT then
            local menu = DermaMenu()
            if tonumber(slotIndex) > 2 then
                menu:AddOption("Drop", function() DropItem(itemModelPath,slotIndex, item) end)
            end
            menu:AddOption("Consume", function() print("Action 3 selected") end)
            menu:Open()
        elseif keyCode == MOUSE_LEFT then
            self:MouseCapture(true)
            self:DragMousePress(keyCode)
        end
    end

    function item:OnMouseReleased(keyCode)
        if keyCode == MOUSE_LEFT then
            self:MouseCapture(false)
            self:DragMouseRelease(keyCode)
        end
    end

    function item:OnDrop(targetSlot)
        local targetSlotType = targetSlot.slotType or "nil"

        if targetSlot:GetChildren()[1] then
            local targetItem = targetSlot:GetChildren()[1]
            local sourceSlot = self:GetParent()
            local targetItemID = targetItem.uniqueId
            local sourceItemID = self.uniqueId
            local sourceItemType = self.itemType
            local targetItemType = targetItem.itemType

            -- Ensure the target slot type matches the source item type
            if targetSlot.slotType == 0 or sourceItemType == targetSlot.slotType then
                targetItem:SetParent(sourceSlot)
                targetItem:Center()
                self:SetParent(targetSlot)
                self:SetPos(8, 8)
                sourceSlot:InvalidateLayout(true)
                targetSlot:InvalidateLayout(true)

                -- Update database for target item
                net.Start("UpdateSlot")
                net.WriteInt(table.KeyFromValue(inventorySlots, sourceSlot), 32)
                net.WriteString(targetItem:GetModel())
                net.WriteInt(targetItemID, 32)
                net.SendToServer()

                -- Update database for source item
                net.Start("UpdateSlot")
                net.WriteInt(table.KeyFromValue(inventorySlots, targetSlot), 32)
                net.WriteString(self:GetModel())
                net.WriteInt(sourceItemID, 32)
                net.SendToServer()
            else
                print("Invalid item type for this slot.")
            end
        else
            HandleDrop(targetSlot, self, uniqueId)
        end
    end

    -- Set up the default layout for the item
    item.LayoutEntity = function(ent) return end

    local mn, mx = item.Entity:GetRenderBounds()
    local size = math.max(math.abs(mn.x) + math.abs(mx.x), math.abs(mn.y) + math.abs(mx.y), math.abs(mn.z) + math.abs(mx.z))
    item:SetFOV(30)
    item:SetCamPos(Vector(size, size, size))
    item:SetLookAt((mn + mx) * 0.5)
end
