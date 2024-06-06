--default variables
curHunger = 100
curThirst = 100

--decreases hunger and thirst over time
local used_time = CurTime()
local function UpdateHungerAndThirst()
    if curHunger > 100 then
        curHunger = 100
    elseif curHunger < 0 then
        curHunger = 0
        net.Start("PlyNoFood")
        net.SendToServer()
        return  
    end
        
    if curThirst > 100 then
        curThirst = 100
    elseif curThirst < 0 then
        curThirst = 0
        net.Start("PlyNoThirst")
        net.SendToServer()
        return 
    end

    if CurTime() > used_time + 2.5 then
        used_time = CurTime()
        curHunger = curHunger - 0.1
        curThirst = curThirst - 0.2
    end 
end

function draw.Circle( x, y, radius, seg )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is needed for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end

hook.Add("HUDPaint", "PolygonCircleTest", function()
	
	surface.SetDrawColor( 0, 0, 0, 200)
	draw.NoTexture()
	draw.Circle( ScrW() / 5.207, ScrH() / 1.0735, 18, 50 )
    draw.Circle( ScrW() / 5.207, ScrH() / 1.029, 18, 50 )

	--Usage:
	--draw.Circle( x, y, radius, segments )

end )

hook.Add("Tick", "HungerThirst", function()
    UpdateHungerAndThirst()
end)

hook.Add("Tick", "SprintManage", function()
    local ply = LocalPlayer()
    if IsValid(ply) then
        if ply:GetVelocity():Length() > 200 then
            curHunger = curHunger - 0.0008
            curThirst = curThirst - 0.002
        end
    end
end)

surface.CreateFont( "Stats", {
    font = "Arial", 
    extended = false,
    size = 20,
    weight = 700,
    blursize = 0,
    scanlines = 0,
    antialias = true,
} )

local wave = Material( "materials/icons/thirst.png", "noclamp smooth" )


--[[ hook.Add( "HUDPaint", "HUDPaint_DrawATexturedBox", function()
	surface.SetMaterial( wave )
	surface.SetDrawColor( 255, 255, 255, 255 )
	surface.DrawTexturedRect( 50, 50, 128, 128 )
    surface.SetTextPos(ScrW() / 5.41, ScrH() / 1.089)
end ) ]]

hook.Add("OnEntityCreated", "Images", function ()
    -- Blurred out screenshot of Construct
    local img_hunger = vgui.Create("DImage")
    img_hunger:SetPos(ScrW() / 5.41, ScrH() / 1.089)
    img_hunger:SetSize(30,30)		
    img_hunger:SetImage("icons/hunger.png")

    local img_thirst = vgui.Create("DImage")
    img_thirst:SetPos(ScrW() / 5.41, ScrH() / 1.044)
    img_thirst:SetSize(30,30)		
    img_thirst:SetMaterial(wave)
end)

hook.Add("HUDPaint", "Stats", function()
    //draw.Circle( 50, 50, 5, 0 )
    currHunger = " " .. string.format("%.0f", curHunger)
    currThirst = " " .. string.format("%.0f", curThirst)

    draw.SimpleText(currHunger, "Stats", ScrW() / 4.7, ScrH() / 1.075, Color(255, 255, 255), 1, 1)        
    draw.SimpleText(currThirst, "Stats", ScrW() / 4.7, ScrH() / 1.03, Color(255, 255, 255), 1, 1) 
end)

soundOn = true
net.Receive("PlyUseBottle", function(len, ply)
    if soundOn == true then
        sound.Play("entities/drinkable/sippin.mp3", LocalPlayer():GetPos())
    end
    local waterValue = 25
    curHunger = curHunger - 5
    curThirst = curThirst + waterValue
end)

net.Receive("PlyUseFood", function(len, ply)
    if soundOn == true then
        sound.Play("entities/eatable/yummy.mp3", LocalPlayer():GetPos())
    end
    local foodValue = 15
    curHunger = curHunger + foodValue
    curThirst = curThirst - 10
end)

net.Receive("PlayerSpawn", function(len, ply)
    curHunger = 100
    curThirst = 100
end)