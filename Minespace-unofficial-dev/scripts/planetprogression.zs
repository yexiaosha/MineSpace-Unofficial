#priority 596
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// PlanetProgression, rebuilt the same way as AE2 (sections 6av / 6au / 6aw).
//
// The export showed the mod's seven craftable items sitting in the assembler as their own crafting
// grids, flattened - a telescope out of compressed tin, diamond blocks and a glass pane, a keycard out
// of compressed iron, dish bases and iron blocks. GregTech would say: give each one a body, the part
// that does its job, circuits by tier and the mod's signature parts, and let the recipe say what the
// item is.
//
//   telescope            an aluminium frame and tube, quartz glass lenses, one diamond block as the
//                        mirror, motors for the tracking drive and a sensor behind the eyepiece
//   satellite builder    a casing with two robot arms and the bronze frame it works in
//   satellite launcher   a casing with two pistons - it is what throws the rocket upwards
//   satellite controller a computer: plates, wafers, a quartz glass screen and a sensor that listens
//   launch pad            the same reinforced pad as before, plus the circuit that makes it a launcher
//   satellite module     a plate body carrying its wiring, wafers and the bronze housing
//   dish keycard         a plastic card with a gold foil layer and the dish link - the same card
//                        language the AE2 cards use, instead of three iron blocks

recipes.remove(<planetprogression:telescope:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:frameGtAluminium>, <gregtech:meta_item_1:32601> * 2, <appliedenergistics2:quartz_glass:0> * 2, <minecraft:diamond_block>, <ore:plateAluminium> * 4, <gregtech:meta_item_1:32691>)
    .circuit(1)
    .outputs(<planetprogression:telescope:0>)
    .duration(600).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:satellite_builder:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32651> * 2, <galacticraftcore:basic_item:10> * 2, <galacticraftcore:basic_item:14> * 2)
    .circuit(2)
    .outputs(<planetprogression:satellite_builder:0>)
    .duration(600).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:satellite_launcher:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32641> * 2, <galacticraftcore:basic_item:9> * 4, <galacticraftcore:basic_item:14>)
    .circuit(3)
    .outputs(<planetprogression:satellite_launcher:0>)
    .duration(600).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:satellite_controller:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <ore:plateAluminium> * 2, <galacticraftcore:basic_item:14> * 2, <appliedenergistics2:quartz_glass:0>, <gregtech:meta_item_1:32691>)
    .circuit(4)
    .outputs(<planetprogression:satellite_controller:0>)
    .duration(600).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:satellite_module_basic:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <galacticraftcore:aluminum_wire:1> * 4, <galacticraftcore:basic_item:14> * 2, <galacticraftcore:basic_item:10> * 2, <minecraft:dye:2>)
    .circuit(5)
    .outputs(<planetprogression:satellite_module_basic:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:advanced_launch_pad:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:11> * 6, <minecraft:iron_block> * 3, <ore:circuitBasic>)
    .outputs(<planetprogression:advanced_launch_pad:0> * 9)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<planetprogression:dish_keycard:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:11> * 2, <galacticraftcore:dishbase> * 2, <ore:platePlastic>, <ore:foilGold>, <ore:circuitBasic>)
    .circuit(6)
    .outputs(<planetprogression:dish_keycard:0>)
    .duration(300).EUt(120)
    .buildAndRegister();
