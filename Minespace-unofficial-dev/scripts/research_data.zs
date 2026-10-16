#priority 846
// The six pieces of survey data the star map's tiers are gated on (see MinespaceResearchData and
// TJ-MIGRATION-PLAN.md 6ej). One tier per star layer:
//
//   I   -> layer 2, 近邻    (IV)        Proxima, Barnard, Tau Ceti
//   II  -> layer 3, 中距    (LuV~ZPM)   TRAPPIST-1 and the Gliese systems
//   III -> layer 4, 远距    (UV)        the Kepler field
//   IV  -> layer 5, 深空    (UHV)
//   V   -> layer 6, 超深空  (UHV+)
//   VI  -> layer 7, 未知    (UHV+)
//
// Each one is assembled out of the previous one plus a circuit and a plate of the tier it opens, so the chain is
// literally the voltage ladder: you cannot survey layer 6 before you have surveyed layer 5. The item form is
// `<minespace:research_data>` with the tier as its metadata.
//
// What this deliberately is NOT is a telescope. The plan's 4.3 wants the lanes opened by *observing*, and a survey
// that costs an assembler recipe is the placeholder until the observation step exists; the item and the gate in the
// star map do not change when it does, only the recipe does. Recorded so that nobody mistakes this for the design.

// ------------------------------------------------------- Tier I - the near systems
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSteel> * 4, <ore:circuitBasic>, <minecraft:paper> * 8)
    .outputs(<minespace:research_data:1>)
    .duration(400).EUt(30)
    .buildAndRegister();

// ------------------------------------------------------- Tier II - the mid systems
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateStainlessSteel> * 4, <ore:circuitGood>, <minespace:research_data:1>)
    .outputs(<minespace:research_data:2>)
    .duration(600).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------- Tier III - the far systems
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateTitanium> * 4, <ore:circuitAdvanced>, <minespace:research_data:2>)
    .outputs(<minespace:research_data:3>)
    .duration(800).EUt(480)
    .buildAndRegister();

// ------------------------------------------------------- Tier IV - deep space
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateTungstenSteel> * 4, <ore:circuitElite>, <minespace:research_data:3>)
    .outputs(<minespace:research_data:4>)
    .duration(1000).EUt(1920)
    .buildAndRegister();

// ------------------------------------------------------- Tier V - ultra-deep space
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateHssg> * 4, <ore:circuitMaster>, <minespace:research_data:4>)
    .outputs(<minespace:research_data:5>)
    .duration(1200).EUt(7680)
    .buildAndRegister();

// ------------------------------------------------------- Tier VI - the unknown
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateNeutronium> * 4, <ore:circuitUltimate>, <minespace:research_data:5>)
    .outputs(<minespace:research_data:6>)
    .duration(1600).EUt(30720)
    .buildAndRegister();
