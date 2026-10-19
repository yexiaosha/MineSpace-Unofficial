#priority 791
// Quantum Minecraft Dynamics - GT integration
//
// QMD's default controller recipes consume NCO's general-purpose processors
// (chemical reactor, rock crusher, supercooler). Those processors are no longer
// the pack's processing path, so the three affected controllers are rebuilt from
// GT materials instead.
//
// QMD's own multiblocks remain unchanged. This file only replaces the three
// crafting-table controller recipes that referenced NCO processors.

// Ore Leacher: replace NCO chemical reactor + rock crusher with GT circuits and
// tungsten-steel structural parts. Assembled at EV.
recipes.remove(<qmd:ore_leacher>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateTungstenSteel> * 4, <ore:plateStainlessSteel> * 4,
            <ore:plateTitanium> * 2, <ore:circuitElite> * 2)
    .outputs(<qmd:ore_leacher>)
    .duration(600).EUt(1920)
    .buildAndRegister();

// Decay Chamber: replace the NCO decay hastener with a GT elite circuit and
// stainless/tungsten-steel parts. Assembled at IV.
recipes.remove(<qmd:decay_chamber_controller>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateTungstenSteel> * 4, <ore:plateStainlessSteel> * 2,
            <ore:plateTitanium> * 2, <ore:circuitMaster> * 2)
    .outputs(<qmd:decay_chamber_controller>)
    .duration(800).EUt(7680)
    .buildAndRegister();

// Liquefier: replace the NCO supercooler with a GT elite circuit and titanium
// thermal parts. Assembled at EV.
recipes.remove(<qmd:liquefier_controller>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateStainlessSteel> * 4, <ore:plateTitanium> * 4,
            <ore:circuitElite> * 2)
    .outputs(<qmd:liquefier_controller>)
    .duration(600).EUt(1920)
    .buildAndRegister();
