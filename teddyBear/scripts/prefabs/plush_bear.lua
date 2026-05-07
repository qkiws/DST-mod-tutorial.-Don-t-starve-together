local Assets = { 
    -- anim file
    Asset("ANIM", "anim/plush_bear.zip"),
	-- Inventory image and atlas file used for the item.
    Asset("ATLAS", "images/inventoryimages/plush_bear.xml"),
    Asset("IMAGE", "images/inventoryimages/plush_bear.tex"),
}

local function DoHeal(inst, owner)
    -- simple function to heal player 3 
    if owner and owner.components.health and not owner.components.health:IsDead() then
    owner.components.health:DoDelta(3, false, 'plush_bear')
    end
end


local function UpdateState(inst)
    local isNight = TheWorld.state.isnight
    local owner = inst.components.inventoryitem.owner

    local isEquipped = inst.components.equippable:IsEquipped()

    local shouldFire = isNight and (owner == nil or isEquipped)
    inst.Light:Enable(shouldFire)

    -- editting breaking age, in night breaks faster
    if isEquipped then
        if isNight then
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
    inst.heal_task = inst:DoPeriodicTask(5, DoHeal, nil, owner)
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    inst.components.fueled:StopConsuming()
    
    UpdateState(inst)

    if inst.heal_task ~= nil then
        inst.heal_task:Cancel()
        inst.heal_task = nil
    end
end

local function MainFunction()

    local inst = CreateEntity()

    -- Базовые компоненты движка
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    local minimap = inst.entity:AddMiniMapEntity()
    minimap:SetIcon("plush_bear.tex")


    inst.AnimState:SetBank("plush_bear")
    inst.AnimState:SetBuild("plush_bear")
    inst.AnimState:PlayAnimation("idle")

    -- You can setup your own light
    inst.entity:AddLight()
    inst.Light:SetFalloff(0.5)
    inst.Light:SetIntensity(0.7)
    inst.Light:SetRadius(3.3) 
    inst.Light:SetColour(255/255, 195/255, 130/255)
    inst.Light:Enable(false)

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

    inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE 
    inst.components.fueled:InitializeFuelLevel(672) 
    inst.components.fueled:SetDepletedFn(inst.Remove)
    
    inst:WatchWorldState("isday", UpdateState)
    inst:WatchWorldState("isdusk", UpdateState)
    inst:WatchWorldState("isnight", UpdateState)

    inst:ListenForEvent("ondropped", UpdateState)
    inst:ListenForEvent("onputininventory", UpdateState)

    return inst
end

-- returning ready prefab to server
return Prefab("plush_bear", MainFunction, Assets)