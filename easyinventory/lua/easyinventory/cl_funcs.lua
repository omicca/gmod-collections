------------------------------------------------------------
--                      HUD Settings                      --
------------------------------------------------------------

//ply model
local playerModelPanel
function ShowPlayerModelPanel()
    if not playerModelPanel then
        playerModelPanel = vgui.Create("DModelPanel")
        playerModelPanel:SetSize(1000, 1000) 
        playerModelPanel:SetPos(1100, 10) 
        playerModelPanel:SetModel(LocalPlayer():GetModel())
        playerModelPanel:SetCamPos(Vector(50, 50, 50)) 
        playerModelPanel:SetLookAt(Vector(0, 0, 40)) 

        function playerModelPanel:LayoutEntity(ent)
            ent:SetAngles(Angle(0, 20, 0)) 
        end

        playerModelPanel.Think = function(self)
            local modelPath = LocalPlayer():GetModel()
            if self:GetModel() ~= modelPath then
                self:SetModel(modelPath)
            end
        end
    end
    playerModelPanel:SetVisible(true)
end

function HidePlayerModelPanel()
    if playerModelPanel then
        playerModelPanel:SetVisible(false)
    end
end

//dark overlay in inventory
local darkOverlayPanel
function CreateDarkOverlayPanel()
    darkOverlayPanel = vgui.Create("DPanel")
    darkOverlayPanel:SetSize(ScrW(), ScrH())
    darkOverlayPanel:SetPos(0, 0)
    darkOverlayPanel:SetBackgroundColor(Color(0, 0, 0, 206))
    darkOverlayPanel:SetMouseInputEnabled(false)
    darkOverlayPanel:SetKeyboardInputEnabled(false)
end

function ShowDarkOverlayPanel()
    if not darkOverlayPanel then
        CreateDarkOverlayPanel()
    end
    darkOverlayPanel:SetVisible(true)
end

function HideDarkOverlayPanel()
    if darkOverlayPanel then
        darkOverlayPanel:SetVisible(false)
    end
end

//Helper func to drop weapon/item
function DropItem(itemModel, slot_index, item)
    net.Start("DropInvItem") 
    net.WriteString(itemModel)
    net.WriteInt(slot_index, 32)
    net.SendToServer()
    item:Remove()
end