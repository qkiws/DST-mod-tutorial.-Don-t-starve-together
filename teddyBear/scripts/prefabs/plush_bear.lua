local Assets = { 
    Asset("ANIM", "anim/plush_bear.zip"),
    Asset("ATLAS", "images/inventoryimages/plush_bear.xml"),
    Asset("IMAGE", "images/inventoryimages/plush_bear.tex"),
}

-- creating an invisible point for server, otherwise will not work ===
local function LightFn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX") -- Говорим игре, что это просто спецэффект

    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.85)
    inst.Light:SetRadius(4) 
    inst.Light:SetColour(255/255, 195/255, 130/255)
    inst.Light:Enable(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false -- do not save at exit
    return inst
end
-- ========================================================

local function DoHeal(inst, owner)
    if owner and owner.components.health and not owner.components.health:IsDead() then
        owner.components.health:DoDelta(1, false, 'plush_bear')
    end
end

local function UpdateState(inst)
    local isNight = TheWorld.state.isnight
    local inCave = TheWorld:HasTag("cave")
    local isDark = isNight or inCave 
    local owner = inst.components.inventoryitem.owner
    local isEquipped = inst.components.equippable:IsEquipped()

    local shouldFire = isDark and (owner == nil or isEquipped)
    
    -- light logit
    if shouldFire then
        if isEquipped then
            -- if the bear in arms we should create a point and hardly set in to our owner.CFrame
            if inst.light_fx == nil then
                inst.light_fx = SpawnPrefab("plush_bear_light")
                inst.light_fx.entity:SetParent(owner.entity)
            end
            inst.Light:Enable(false) -- disable the light
        else
            -- if on ground delete
            if inst.light_fx ~= nil then
                inst.light_fx:Remove()
                inst.light_fx = nil
            end
            inst.Light:Enable(true)
        end
    else
        -- turning off
        if inst.light_fx ~= nil then
            inst.light_fx:Remove()
            inst.light_fx = nil
        end
        inst.Light:Enable(false)
    end

    -- same fuel logic
    if isEquipped then
        if inCave then
            inst.components.fueled.rate = 0
        elseif isNight then
            inst.components.fueled.rate = 1.5
        else
            inst.components.fueled.rate = 0.7
        end
    end    
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "plush_bear", "plush_bear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.components.fueled:StartConsuming()
    UpdateState(inst)

    if inst.heal_task ~= nil then
        inst.heal_task:Cancel()
    end
    inst.heal_task = inst:DoPeriodicTask(7, DoHeal, nil, owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.components.fueled:StopConsuming()
    
    -- should delete light 
    if inst.light_fx ~= nil then
        inst.light_fx:Remove()
        inst.light_fx = nil
    end
    
    UpdateState(inst)

    if inst.heal_task ~= nil then
        inst.heal_task:Cancel()
        inst.heal_task = nil
    end
end

-- wen the fuel is 0 delete all items
local function OnRemove(inst)
    if inst.light_fx ~= nil then
        inst.light_fx:Remove()
        inst.light_fx = nil
    end
end

local function MainFunction()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("plush_bear.tex")

    inst.AnimState:SetBank("plush_bear")
    inst.AnimState:SetBuild("plush_bear")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:AddLight()
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.85)
    inst.Light:SetRadius(4) 
    inst.Light:SetColour(255/255, 195/255, 130/255)
    inst.Light:Enable(false)

    inst:AddTag("light")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "plush_bear"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/plush_bear.xml"

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)

    inst.components.equippable.dapperness = TUNING.DAPPERNESS_HUGE

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE 
    inst.components.fueled:InitializeFuelLevel(672) 
    inst.components.fueled:SetDepletedFn(inst.Remove)
    
    inst:WatchWorldState("isday", UpdateState)
    inst:WatchWorldState("isdusk", UpdateState)
    inst:WatchWorldState("isnight", UpdateState)

    inst:ListenForEvent("ondropped", UpdateState)
    inst:ListenForEvent("onputininventory", UpdateState)
    inst:ListenForEvent("onremove", OnRemove) -- need new event

    return inst
end

return Prefab("plush_bear", MainFunction, Assets),
       Prefab("plush_bear_light", LightFn)
