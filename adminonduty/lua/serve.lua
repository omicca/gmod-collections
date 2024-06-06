AddCSLuaFile("client_serve.lua")

-- store ranks
local originalRanks = {}
local customUsergroup = "AOD"

local function SwitchToCustomRank(ply)
    if not originalRanks[ply:SteamID()] then
        originalRanks[ply:SteamID()] = ply:GetUserGroup()
        ply:SetUserGroup(customUsergroup)
        ply:GodEnable()
        ply:ChatPrint("Switched to Admin on Duty (" .. customUsergroup .. ")")
    else
        ply:ChatPrint("You are already in the custom rank.")
    end
end

local function RevertToOriginalRank(ply)
    local originalRank = originalRanks[ply:SteamID()]
    if originalRank then
        ply:SetUserGroup(originalRank)
        originalRanks[ply:SteamID()] = nil
        ply:GodDisable()
        ply:ChatPrint("You have been reverted to your original rank: " .. originalRank)
    else
        ply:ChatPrint("No original rank found for you.")
    end
end

concommand.Add("onduty", function(ply, cmd, args)
    if ply:IsAdmin() then
        SwitchToCustomRank(ply)
    else
        ply:ChatPrint("You do not have permission to use this command.")
    end
end)


concommand.Add("offduty", function(ply, cmd, args)
    if ply:IsAdmin() then
        RevertToOriginalRank(ply)
    else
        ply:ChatPrint("You do not have permission to use this command.")
    end
end)


hook.Add("PlayerNoClip", "RestrictNoclipInvisibilityByRank", function(ply, desiredNoclipState)
    if ULib.ucl.query(ply, "ulx noclip") then
        if ply:GetUserGroup() == customUsergroup then
            if desiredNoclipState then
                ULib.invisible(ply, true)
            else
                ULib.invisible(ply, false)
            end
        end
        return true
    else
        ply:ChatPrint("You do not have permission to use noclip.")
        return false
    end
end)
