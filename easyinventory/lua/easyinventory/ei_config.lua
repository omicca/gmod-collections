------------------------------------------------------------
--                     Configurations                     --
------------------------------------------------------------

--
-- Enter class name for item
-- Type: 0 = Common
-- Type: 1 = Ammo
-- Type: 2 = Weapons
--
allowedItems = {
    {name = "some_food", type = 0},
    {name = "some_drink", type = 0},
    {name = "spawned_ammo", type = 1},
    {name = "spawned_weapon", type = 2}
}

--
-- Existing mappings
-- Enter model path followed by class name
--
itemModelToEntityClass = {
    ["models/food/burger.mdl"] = "some_food",
    ["models/props_junk/garbage_plasticbottle003a.mdl"] = "some_drink",
    ["models/items/boxmrounds.mdl"] = "spawned_ammo",
    ["models/items/boxsrounds.mdl"] = "spawned_ammo",
    ["models/items/boxbuckshot.mdl"] = "spawned_ammo",
    ["models/weapons/w_rif_ak47.mdl"] = "spawned_weapon"
}

modelToWeaponClass = {
    ["models/weapons/w_pist_fiveseven.mdl"] = "weapon_fiveseven2",
    ["models/weapons/w_rif_ak47.mdl"] = "weapon_ak472",
}


-- Define ammo data mapping
ammoData = {
    ["models/items/boxmrounds.mdl"] = {type = "SMG1", amount = 30},
    ["models/items/boxsrounds.mdl"] = {type = "Pistol", amount = 20},
    ["models/items/boxbuckshot.mdl"] = {type = "Buckshot", amount = 10},
}