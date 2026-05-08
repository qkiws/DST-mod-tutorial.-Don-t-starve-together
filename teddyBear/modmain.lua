PrefabFiles = {
    "plush_bear",
}

-- shows the game what needs to be loaded by running the server
Assets = {
    Asset("ATLAS", "images/inventoryimages/plush_bear.xml"),
    Asset("IMAGE", "images/inventoryimages/plush_bear.tex")
}

-- Adding icon to minimap
AddMinimapAtlas("images/inventoryimages/plush_bear.xml")

-- Addinting text to RECIPE part
GLOBAL.STRINGS.NAMES.PLUSH_BEAR = "Lovely Teddy BEAR"
GLOBAL.STRINGS.RECIPE_DESC.PLUSH_BEAR = "Craft your TEDDY!"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.PLUSH_BEAR = "Mind and heart blowing bear"

-- Adding a recipe to RECIPES
AddRecipe2(
    'plush_bear',
    {
        GLOBAL.Ingredient("beefalowool", 10) -- ingridients that will be used
    },
    GLOBAL.TECH.NONE, 
    {atlas = "images/inventoryimages/plush_bear.xml", image = "plush_bear.tex"},
    {"SURVIVAL"} -- what part of RECIPES 
)

local function MakeSewing(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return inst
    end

    if not inst.components.sewing then
        inst:AddComponent('sewing')
    end

    inst.components.sewing.repair_value = 120
end

AddPrefabPostInit("beefalowool", MakeSewing)
RegisterInventoryItemAtlas("images/inventoryimages/plush_bear.xml", "plush_bear.tex")
