#priority 845
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Ported from the GTCEu-era script of the same name (see TJ-MIGRATION-PLAN.md, section 6d).
// The recipe map accessor is GTCE-TJ's:
//     <recipemap:assembler>.recipeBuilder()                                   [GTCEu]
//  -> mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()    [GTCE-TJ]
// Everything else - inputs/outputs/duration/EUt/property/circuit/fluidInputs/
// buildAndRegister, the ore dictionary names, the Galacticraft item ids and the JEI calls -
// is unchanged, because those APIs are the same in both forks.
// Recipes for this mod's own GregTech machines, and the Galacticraft machines they replace.
//
// The machines live in the addon (see MinespaceGregMachines / MetaTileEntityOxygenCompressor),
// not in a script, because Galacticraft's oxygen and fuel chains cannot be expressed as
// GregTech recipes: their tanks store what they hold in the stack's damage value, so a machine
// has to move that value around. The item form of a GregTech machine is GregTech's own machine
// item with the registry id as its metadata:
//
//   minespace:oxygen_compressor  ->  gregtech:machine:32000
//   minespace:rocket_fuel_loader  ->  gregtech:machine:32001

// ------------------------------------------------------- Oxygen Compressor (LV)
// Built in GregTech's assembler out of steel and aluminium plate plus an LV circuit, which is
// what Galacticraft's own compressor used to cost in compressed plates.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSteel> * 4, <ore:plateAluminium> * 2, <ore:circuitBasic>)
    .outputs(<gregtech:machine:32000>)
    .duration(400).EUt(30)
    .buildAndRegister();

// Galacticraft's own oxygen compressor (meta 0) and its decompressor (meta 1) are gone; the
// compressor's job is the machine above, and nothing needs to empty a tank any more.
recipes.remove(<galacticraftcore:oxygen_compressor:*>);

// ------------------------------------------------------- Rocket Fuel Loader (LV)
// Fills the rocket standing on the landing pad next to it. Steel and bronze plate plus an LV
// circuit; it accepts Galacticraft's rocket fuel by pipe, or Galacticraft's own fuel canisters
// in its slot.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSteel> * 4, <ore:plateBronze> * 2, <ore:circuitBasic>)
    .outputs(<gregtech:machine:32001>)
    .duration(400).EUt(30)
    .buildAndRegister();

// Galacticraft's own fuel loader is gone; the machine above does its job.
recipes.remove(<galacticraftcore:fuel_loader>);
