#priority 698
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Ender IO's dark steel upgrades: the blank upgrade and its forty-five variants.
//
// Two passes in one file, both of them the owner's rule that another mod's machine does not get to
// make this pack's things:
//
//   * the **blank** upgrade (`item_dark_steel_upgrade:0`) was made in Ender IO's own alloy smelter -
//     a recipe EIO ships as `<alloying>` in its darksteel_upgrades.xml. It is a GregTech assembler
//     recipe now (the three inputs are over the alloy smelter's two-input limit) and the Ender IO
//     recipe is switched off by name in config/enderio/recipes/user/user_recipes.xml.
//   * the **forty-five variants** were crafting-table recipes that take a blank upgrade plus one or
//     two parts and produce an upgrade carrying an NBT tag (`enderio:dsu`). An upgrade is a machine
//     component, so they are assembler work now. The NBT tag is written with `.withTag`, and the
//     tags themselves come out of EIO's own darksteel_upgrades*.xml - not invented.
//
// Materials are unchanged and no count is lowered. Ender IO's alloy ingots and nuggets in these grids
// are written as the GregTech ore names, because an assembler recipe is not a crafting-table recipe
// and so is not what MinespaceMaterialRepoint re-points.

// ---- the blank upgrade (was Ender IO's alloy smelter)
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_dark_iron_bars>, <ore:itemClay>, <minecraft:string> * 4)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

// ---- the forty-five variants, one assembler recipe each
// The four Solar upgrades are deliberately absent: each one is made from an Ender IO solar panel,
// and integration.zs removes those panels (they are RF generators and the pack does not keep a
// machine that makes its own power) and hides them from JEI. A recipe whose only input no longer
// exists is exactly the "why is this still here?" wart, and a progression probe walking the finished
// registries found all four as dead recipes - they are hidden with the panels instead, see
// integration.zs. Ender IO's own crafting recipes for them are removed by the `recipes.remove`
// calls below, which match the upgrade by item, not by NBT tag.

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <forestry:apiarist_helmet>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiointegrationforestry:apiarist_armor_head" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <forestry:apiarist_chest>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiointegrationforestry:apiarist_armor_chest" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <forestry:apiarist_legs>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiointegrationforestry:apiarist_armor_legs" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <forestry:apiarist_boots>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiointegrationforestry:apiarist_armor_feet" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <forestry:naturalist_helmet>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiointegrationforestry:naturalist_eye" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:carpet:32767>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:carpet" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:skull:4>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:depth" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetVibrantAlloy> * 4, <ore:ingotVibrantAlloy> * 3, <minecraft:ender_pearl>, <enderio:item_dark_steel_upgrade>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:direct" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:elytra>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:elytra" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_material:15>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:energyupgrade" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_basic_capacitor>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:energyupgrade1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_basic_capacitor:1>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:energyupgrade2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_basic_capacitor:2>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:energyupgrade3" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_material:43>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:energyupgrade4" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_material:7>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:glide" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:diamond_hoe>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:hoe" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <ore:chestWood>, <ore:gearWood>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:inv" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <ore:chestWood>, <enderio:item_material:12>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:inv1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <ore:chestWood>, <enderio:item_material:13>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:inv2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:piston>, <ore:gearWood>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:jumpboost1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:piston>, <enderio:item_material:12>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:jumpboost2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:piston>, <enderio:item_material:13>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:jumpboost3" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:potion>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:nightvision" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <ore:wool>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:padding" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:noteblock>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:sounddetector" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:potion>, <ore:gearWood>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:speedboost1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:potion>, <enderio:item_material:12>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:speedboost2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:potion>, <enderio:item_material:13>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:speedboost3" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:diamond_shovel>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:spoon" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:waterlily>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:swim" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:tnt>, <ore:gearWood>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:tnt" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:tnt>, <enderio:item_material:10>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:tnt1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:tnt>, <enderio:item_material:11>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:tnt2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:tnt>, <enderio:item_material:12>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:tnt3" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <minecraft:tnt>, <enderio:item_material:13>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:tnt4" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <theoneprobe:probe>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:top" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_dark_steel_upgrade>, <enderio:item_material:16>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:travel" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetDarkSteel> * 2, <minecraft:stick> * 2, <enderio:item_dark_steel_upgrade:0>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:anvil" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotDarkSteel> * 2, <minecraft:stick> * 2, <enderio:item_dark_steel_upgrade:0>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:anvil1" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:blockDarkSteel>, <enderio:block_dark_steel_anvil>, <enderio:item_dark_steel_upgrade:0>, <minecraft:stick> * 2)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:anvil2" }))
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_dark_steel_upgrade:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:brick> * 5, <enderio:item_dark_steel_upgrade:0>)
    .circuit(1)
    .outputs(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderio:step_assist" }))
    .duration(400).EUt(120)
    .buildAndRegister();

