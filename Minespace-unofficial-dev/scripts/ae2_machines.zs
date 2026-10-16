#priority 600
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// AE2's machines, rebuilt the GregTech way instead of carried over.
//
// The export of the finished recipes made the problem plain: almost every AE2 machine was "a pile of
// GregTech iron plates plus whatever AE2's own grid used" - the ME Drive was four iron plates, two
// engineering processors and two cables; the Inscriber was five iron plates and two pistons; the
// Vibration Chamber was seven iron plates, an energy acceptor and a furnace. GregTech builds machines
// out of four things, and this file does the same:
//
//   the body       -> the machine casing of its tier (MV casing, HV casing, ...)
//   the function   -> the GregTech part that *does* the job: a motor turns, a piston presses, a
//                     conveyor moves items, a robot arm inserts them, an emitter projects, a sensor reads
//   the control    -> GregTech circuits of the tier (basic -> good -> advanced)
//   the signature  -> the AE2 part that makes the machine recognisable (quartz glass, fluix, a ME cable,
//                     an engineering processor, smooth sky stone)
//
// So the Inscriber is a casing with two pistons in it (it presses), the Security Station carries a
// sensor (it reads you), the Spatial IO Port carries an emitter (it projects the field), the Drive has
// two motors and two ME cables (two bays), and the Energy Acceptor is a casing with four copper wires
// running in. Nothing is cheaper than the recipe it replaces, every part already has a route in this
// pack, and the tier can be read off the recipe.

// ------------------------------------------------------------------ MV machines
recipes.remove(<appliedenergistics2:drive:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32601> * 2, <ore:circuitGood> * 2, <appliedenergistics2:part:16> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:drive:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:chest:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32631>, <ore:circuitGood>, <appliedenergistics2:part:16>, <appliedenergistics2:quartz_glass:0>, <ore:plateAluminium>)
    .circuit(1)
    .outputs(<appliedenergistics2:chest:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:crafting_unit:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32651>, <ore:circuitGood>, <appliedenergistics2:material:24>, <appliedenergistics2:part:16>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_unit:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32601>, <ore:circuitBasic> * 2, <appliedenergistics2:material:7>, <ore:wireFineCopper> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:charger:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:energy_acceptor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <ore:circuitBasic> * 2, <appliedenergistics2:material:7>, <ore:wireFineCopper> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:energy_acceptor:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:inscriber:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32641> * 2, <ore:circuitGood>, <ore:crystalCertusQuartz> * 2, <ore:plateAluminium>)
    .circuit(1)
    .outputs(<appliedenergistics2:inscriber:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:condenser:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32631>, <ore:circuitBasic>, <appliedenergistics2:material:8> * 2, <ore:pipeTinySteel> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:condenser:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:interface:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32651>, <ore:circuitGood>, <appliedenergistics2:part:16>, <ore:plateAluminium> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:interface:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluid_interface:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <ore:circuitGood>, <appliedenergistics2:part:16>, <ore:pipeTinySteel> * 2, <ore:plateAluminium> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:fluid_interface:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:io_port:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32631> * 2, <ore:circuitGood>, <appliedenergistics2:part:16> * 2, <ore:plateAluminium>)
    .circuit(1)
    .outputs(<appliedenergistics2:io_port:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:security_station:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32691>, <ore:circuitGood>, <appliedenergistics2:material:24>, <ore:plateAluminium> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:security_station:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:vibration_chamber:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32601>, <ore:circuitBasic>, <ore:plateSteel> * 2, <appliedenergistics2:material:7>, <ore:wireFineCopper> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:vibration_chamber:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:cell_workbench:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32651> * 2, <ore:circuitBasic>, <ore:plateAluminium> * 2, <ore:screwSteel> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:cell_workbench:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:quartz_growth_accelerator:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32631>, <ore:circuitBasic>, <appliedenergistics2:material:7> * 2, <appliedenergistics2:quartz_glass:0> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:quartz_growth_accelerator:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:controller:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <ore:circuitGood> * 2, <appliedenergistics2:material:24>, <appliedenergistics2:part:16> * 2, <appliedenergistics2:smooth_sky_stone_block:0> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:controller:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:spatial_pylon:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32680> * 2, <ore:circuitGood>, <appliedenergistics2:material:8>, <appliedenergistics2:quartz_glass:0> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:spatial_pylon:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:molecular_assembler:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32651> * 2, <ore:circuitGood>, <appliedenergistics2:material:43>, <appliedenergistics2:material:44>, <appliedenergistics2:quartz_glass:0>)
    .circuit(1)
    .outputs(<appliedenergistics2:molecular_assembler:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:energy_cell:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <ore:circuitBasic> * 2, <appliedenergistics2:material:1> * 2, <appliedenergistics2:material:8> * 2, <appliedenergistics2:quartz_glass:0> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:energy_cell:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:view_cell:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <appliedenergistics2:part:16>, <ore:circuitBasic>, <appliedenergistics2:quartz_glass:0> * 2, <ore:plateAluminium> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:view_cell:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:matter_cannon:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32641>, <ore:circuitGood>, <appliedenergistics2:energy_cell:0>, <ore:plateSteel> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:matter_cannon:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:color_applicator:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32641>, <ore:circuitGood>, <appliedenergistics2:energy_cell:0>, <ore:platePlastic> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:color_applicator:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:entropy_manipulator:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:2>, <gregtech:meta_item_1:32641>, <ore:circuitGood>, <appliedenergistics2:energy_cell:0>, <appliedenergistics2:material:7> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:entropy_manipulator:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ hand tools: a rod, a body, the chip that makes it work
recipes.remove(<appliedenergistics2:charged_staff:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:stickSteel> * 2, <ore:plateSteel> * 2, <appliedenergistics2:material:1>, <ore:circuitBasic>)
    .circuit(1)
    .outputs(<appliedenergistics2:charged_staff:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:sky_compass:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:32690>, <appliedenergistics2:material:1>, <ore:circuitBasic>, <ore:plateSteel> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:sky_compass:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:memory_card:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:platePlastic>, <ore:foilGold>, <ore:circuitBasic>, <ore:wireFineRedAlloy> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:memory_card:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:biometric_card:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:platePlastic>, <ore:foilGold>, <ore:circuitBasic>, <gregtech:meta_item_1:32690>)
    .circuit(1)
    .outputs(<appliedenergistics2:biometric_card:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ HV tier
recipes.remove(<appliedenergistics2:spatial_io_port:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:3>, <gregtech:meta_item_1:32632> * 2, <ore:circuitAdvanced>, <appliedenergistics2:part:16> * 2, <appliedenergistics2:material:9>)
    .circuit(1)
    .outputs(<appliedenergistics2:spatial_io_port:0>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:quantum_ring:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:3>, <gregtech:meta_item_1:32681> * 2, <ore:circuitAdvanced>, <appliedenergistics2:material:9> * 2, <appliedenergistics2:energy_cell:0>)
    .circuit(1)
    .outputs(<appliedenergistics2:quantum_ring:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:dense_energy_cell:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:machine_casing:3>, <appliedenergistics2:energy_cell:0> * 4, <ore:circuitGood>, <appliedenergistics2:material:8> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:dense_energy_cell:0>)
    .duration(400).EUt(480)
    .buildAndRegister();
