#priority 599
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// AE2's parts and cards: the devices that hang on the network, built by function.
//
// Same idea as the machines (section 6av) and the storage family (6au), one level smaller. A part has no
// room for a machine casing, so its body is a plate and the GregTech part inside it is chosen by what
// the device *does*:
//
//   import / export bus   -> a robot arm (it takes items in and puts them out)
//   storage bus           -> a plate, a ME cable and a processor (it is a channel, not a mover)
//   planes                -> the annihilation / formation core sets it, a piston works it
//   level emitter         -> a GregTech emitter (that is what emits)
//   terminals / monitors  -> a quartz glass face plus a circuit (that is what shows something)
//   illuminated panel     -> a quartz glass face plus glowstone
//   P2P tunnel, toggle bus-> a ME cable plus a circuit
//   the cards             -> a plastic plate with a gold foil layer, exactly like the blank pattern

// ------------------------------------------------------------------ the cards
recipes.remove(<appliedenergistics2:material:25>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:platePlastic>, <ore:foilGold>, <ore:circuitBasic>, <minecraft:redstone>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:25> * 2)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:28>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:platePlastic>, <ore:foilGold>, <ore:circuitGood>, <minecraft:redstone>, <minecraft:diamond>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:28> * 2)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:41>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium>, <ore:circuitGood>, <appliedenergistics2:material:9>, <ore:wireFineGold> * 2)
    .circuit(1)
    .outputs(<appliedenergistics2:material:41>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:53>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:25>, <appliedenergistics2:material:52>, <ore:circuitBasic>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:53>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:58>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:28>, <appliedenergistics2:material:52> * 2, <ore:circuitGood>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:58>)
    .duration(400).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ the buses
// Storage bus: a channel onto the network - a plate, a ME cable and a processor.
recipes.remove(<appliedenergistics2:part:220>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:circuitBasic>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:220>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:221>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:pipeTinySteel> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:part:221>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:222>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:23>, <ore:circuitBasic>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:222>)
    .duration(200).EUt(120)
    .buildAndRegister();

// Import / export bus: the network's hands, so they carry a robot arm.
recipes.remove(<appliedenergistics2:part:240>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <gregtech:meta_item_1:32651>, <appliedenergistics2:part:16>, <ore:circuitGood>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:240>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:241>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <gregtech:meta_item_1:32651>, <appliedenergistics2:part:16>, <ore:circuitGood>, <ore:pipeTinySteel> * 2)
    .circuit(2)
    .outputs(<appliedenergistics2:part:241>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:260>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <gregtech:meta_item_1:32651>, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:circuitGood>)
    .circuit(3)
    .outputs(<appliedenergistics2:part:260>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:261>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <gregtech:meta_item_1:32651>, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:pipeTinySteel> * 2)
    .circuit(3)
    .outputs(<appliedenergistics2:part:261>)
    .duration(300).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ the planes and the emitter
recipes.remove(<appliedenergistics2:part:300>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:material:44>, <gregtech:meta_item_1:32640>, <ore:circuitGood>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:300>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:301>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:material:44>, <appliedenergistics2:material:7> * 2, <ore:circuitGood>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:301>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:320>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:material:43>, <gregtech:meta_item_1:32640>, <ore:circuitGood>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:320>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:280>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <gregtech:meta_item_1:32680>, <appliedenergistics2:part:16>, <ore:circuitBasic>)
    .circuit(2)
    .outputs(<appliedenergistics2:part:280>)
    .duration(200).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ the terminals and monitors: a face and a chip
recipes.remove(<appliedenergistics2:part:380>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <ore:circuitBasic>)
    .circuit(4)
    .outputs(<appliedenergistics2:part:380>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:520>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <ore:circuitBasic>, <ore:pipeTinySteel> * 2)
    .circuit(4)
    .outputs(<appliedenergistics2:part:520>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:340>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:circuitGood>)
    .circuit(4)
    .outputs(<appliedenergistics2:part:340>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:341>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:23>, <ore:circuitGood>)
    .circuit(4)
    .outputs(<appliedenergistics2:part:341>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:360>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:24>, <ore:circuitGood>)
    .circuit(4)
    .outputs(<appliedenergistics2:part:360>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:480>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:24>, <ore:circuitAdvanced>)
    .circuit(4)
    .outputs(<appliedenergistics2:part:480>)
    .duration(400).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:400>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <ore:circuitBasic>)
    .circuit(5)
    .outputs(<appliedenergistics2:part:400>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:420>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:quartz_glass:0> * 2, <appliedenergistics2:part:16>, <appliedenergistics2:material:22>, <ore:circuitGood>)
    .circuit(5)
    .outputs(<appliedenergistics2:part:420>)
    .duration(300).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ the interface parts, the tunnel, the panel and the toggle
recipes.remove(<appliedenergistics2:part:440>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16> * 2, <appliedenergistics2:material:24>, <ore:circuitGood>)
    .circuit(6)
    .outputs(<appliedenergistics2:part:440>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:441>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16> * 2, <appliedenergistics2:material:24>, <ore:circuitGood>, <ore:pipeTinySteel> * 2)
    .circuit(6)
    .outputs(<appliedenergistics2:part:441>)
    .duration(300).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:460>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16> * 2, <ore:circuitBasic>)
    .circuit(7)
    .outputs(<appliedenergistics2:part:460>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:80>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2, <appliedenergistics2:part:16>, <ore:circuitBasic>)
    .circuit(7)
    .outputs(<appliedenergistics2:part:80>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:180>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateAluminium>, <appliedenergistics2:quartz_glass:0>, <ore:dustGlowstone>, <ore:circuitBasic>)
    .circuit(8)
    .outputs(<appliedenergistics2:part:180>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:part:200>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSteel>, <appliedenergistics2:quartz_glass:0>, <ore:dustGlowstone>, <ore:circuitBasic>)
    .circuit(8)
    .outputs(<appliedenergistics2:part:200>)
    .duration(200).EUt(120)
    .buildAndRegister();
