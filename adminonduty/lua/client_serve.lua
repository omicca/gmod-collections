
local desiredRole = "AOD"


local function PrintText()
    local msg = "Just a test"
    local color = Color(255, 100, 255, 255) -- Adjusted alpha value to ensure visibility
    local duration = 5
    local fade = 0.5


    ULib.csayDraw(msg, color, duration, fade)
end

local function DrawESP()
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:GetUserGroup() ~= desiredRole or ply:GetMoveType() ~= MOVETYPE_NOCLIP then
        return
    end


    for _, target in ipairs(player.GetAll()) do
        if target ~= ply and target:Alive() then
            local targetPos = target:GetPos()
            local targetScreenPos = targetPos:ToScreen()
            
            draw.DrawText(target:Nick(), "Default", targetScreenPos.x, targetScreenPos.y, Color(0, 255, 13), TEXT_ALIGN_CENTER)
            
        end
    end
end

hook.Add("HUDPaint", "ESPDraw", DrawESP)

