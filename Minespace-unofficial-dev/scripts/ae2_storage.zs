#priority 598
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// AE2's storage electronics, redesigned instead of copied.
//
// The first pass simply flattened AE2's own crafting grids into the assembler (three quartz glass, three
// redstone, one component, three plates - the mod's shape, moved). That is not a GregTech recipe, it is
// the old one wearing a machine's clothes, and the owner said so: "you are almost copying the original
// recipes, there is no invention in it". This file is the answer for the storage family, and the shape
// of every recipe now *says* what the item is:
//
//   a component is a chip      -> GT circuit + certus quartz + fine wire (fluid ones take a tiny pipe)
//   a housing is a card cage   -> aluminium plates + a quartz glass window + steel screws + a circuit
//   a cell is a card in a cage -> housing + component + screws + a circuit
//   a blank pattern is a card  -> a plastic plate, an aluminium foil data layer, a circuit
//
// The tier is legible from the recipe rather than from a number: basic -> good -> advanced circuit as
// the capacity grows, and tin -> copper -> silver -> electrum (or steel -> stainless -> titanium for the
// pipes) as the voltage rises. Nothing is cheaper than what it replaces - every recipe carries real
// GregTech parts the mod's own grid never asked for - and every material already has a route in this
// pack, so no new bottleneck is created.

// ------------------------------------------------------------------ the components (chips)
recipes.remove(<appliedenergistics2:material:35>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitBasic>, <ore:crystalCertusQuartz> * 2, <ore:wireFineTin> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:material:35>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:36>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitGood>, <appliedenergistics2:material:35> * 2, <ore:wireFineCopper> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:material:36>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:37>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced>, <appliedenergistics2:material:36> * 2, <ore:wireFineSilver> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:material:37>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:38>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced> * 2, <appliedenergistics2:material:37> * 2, <ore:wireFineElectrum> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:material:38>)
    .duration(600).EUt(1920)
    .buildAndRegister();

// The fluid ones are the same chip with a pipe instead of a wire - that is the whole difference between
// a stack of items and a tank of fluid.
recipes.remove(<appliedenergistics2:material:54>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitBasic>, <ore:crystalCertusQuartz> * 2, <ore:pipeTinySteel> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:material:54>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:55>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitGood>, <appliedenergistics2:material:54> * 2, <ore:pipeTinySteel> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:material:55>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:56>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced>, <appliedenergistics2:material:55> * 2, <ore:pipeTinyStainlessSteel> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:material:56>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:57>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced> * 2, <appliedenergistics2:material:56> * 2, <ore:pipeTinyTitanium> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:material:57>)
    .duration(600).EUt(1920)
    .buildAndRegister();

// The spatial ones store geometry rather than matter, so they are built on a fluix pearl and gold wire.
recipes.remove(<appliedenergistics2:material:32>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitGood>, <appliedenergistics2:material:9> * 2, <ore:wireFineGold> * 4)
    .circuit(3)
    .outputs(<appliedenergistics2:material:32>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:33>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced>, <appliedenergistics2:material:32> * 2, <ore:wireFineGold> * 4)
    .circuit(3)
    .outputs(<appliedenergistics2:material:33>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:34>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:circuitAdvanced> * 2, <appliedenergistics2:material:33> * 2, <ore:wireFineElectrum> * 4)
    .circuit(3)
    .outputs(<appliedenergistics2:material:34>)
    .duration(600).EUt(1920)
    .buildAndRegister();

// ------------------------------------------------------------------ the card cage and the blank card
recipes.remove(<appliedenergistics2:material:39>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 4, <appliedenergistics2:quartz_glass:0> * 2, <ore:screwSteel> * 3, <ore:circuitBasic>)
    .circuit(4)
    .outputs(<appliedenergistics2:material:39>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:52>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:platePlastic>, <ore:foilAluminium>, <ore:circuitBasic>)
    .circuit(4)
    .outputs(<appliedenergistics2:material:52>)
    .duration(200).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ the cells: a card in the cage
recipes.remove(<appliedenergistics2:storage_cell_1k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:35>, <ore:screwSteel> * 2, <ore:circuitBasic>)
    .circuit(5)
    .outputs(<appliedenergistics2:storage_cell_1k:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:storage_cell_4k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:36>, <ore:screwSteel> * 2, <ore:circuitGood>)
    .circuit(5)
    .outputs(<appliedenergistics2:storage_cell_4k:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:storage_cell_16k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:37>, <ore:screwAluminium> * 2, <ore:circuitAdvanced>)
    .circuit(5)
    .outputs(<appliedenergistics2:storage_cell_16k:0>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:storage_cell_64k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:38>, <ore:screwStainlessSteel> * 2, <ore:circuitAdvanced> * 2)
    .circuit(5)
    .outputs(<appliedenergistics2:storage_cell_64k:0>)
    .duration(600).EUt(1920)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluid_storage_cell_1k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:54>, <ore:screwSteel> * 2, <ore:circuitBasic>)
    .circuit(6)
    .outputs(<appliedenergistics2:fluid_storage_cell_1k:0>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluid_storage_cell_4k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:55>, <ore:screwSteel> * 2, <ore:circuitGood>)
    .circuit(6)
    .outputs(<appliedenergistics2:fluid_storage_cell_4k:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluid_storage_cell_16k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:56>, <ore:screwAluminium> * 2, <ore:circuitAdvanced>)
    .circuit(6)
    .outputs(<appliedenergistics2:fluid_storage_cell_16k:0>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluid_storage_cell_64k:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:57>, <ore:screwStainlessSteel> * 2, <ore:circuitAdvanced> * 2)
    .circuit(6)
    .outputs(<appliedenergistics2:fluid_storage_cell_64k:0>)
    .duration(600).EUt(1920)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:spatial_storage_cell_2_cubed:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:32>, <ore:screwSteel> * 2, <ore:circuitGood>)
    .circuit(7)
    .outputs(<appliedenergistics2:spatial_storage_cell_2_cubed:0>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:spatial_storage_cell_16_cubed:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:33>, <ore:screwAluminium> * 2, <ore:circuitAdvanced>)
    .circuit(7)
    .outputs(<appliedenergistics2:spatial_storage_cell_16_cubed:0>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:spatial_storage_cell_128_cubed:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:39>, <appliedenergistics2:material:34>, <ore:screwStainlessSteel> * 2, <ore:circuitAdvanced> * 2)
    .circuit(7)
    .outputs(<appliedenergistics2:spatial_storage_cell_128_cubed:0>)
    .duration(600).EUt(1920)
    .buildAndRegister();

// ------------------------------------------------------------------ the crafting CPU's accelerating card
recipes.remove(<appliedenergistics2:crafting_accelerator:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <ore:circuitGood>, <ore:screwSteel> * 2, <ore:wireFineRedAlloy> * 4)
    .circuit(8)
    .outputs(<appliedenergistics2:crafting_accelerator:0>)
    .duration(300).EUt(120)
    .buildAndRegister();
