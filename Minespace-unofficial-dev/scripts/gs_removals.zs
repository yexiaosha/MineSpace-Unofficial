#priority 846
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
// Galaxy Space gets the same treatment Galacticraft got: its own power generation and the
// machines that duplicate a GregTech machine stop being craftable, and GregTech machines take
// over the job.
//
// Every registry name below came from a live server run (CraftTweaker's
// itemUtils.getItemsByRegexRegistryName over the machine/power keywords), not from guessing:
// Galaxy Space names its blocks in its own style and one of them (the gas extractor) even uses
// metadata 100 rather than 0, which is why the metas are written out explicitly.
//
// What is deliberately *not* here:
//   * Galaxy Space's rocket assembler and the NASA workbench categories. Tier 1-3 and the GS
//     tiers are built with those for now; higher tiers become GregTech multiblocks later.
//   * Galaxy Space's utility machinery (modification table, gravity module, magnetic field
//     generator, planetary shield, hydroponic base, oxygen storage cluster, oxygen tanks 4-6).
//     Those are content, not industry GregTech duplicates.
//   * Batteries (advanced/extra/modern/ultimate), same as Galacticraft's batteries: they are
//     storage items for its own tools, not generators.

// ------------------------------------------------------------------ power generation
// GT generators replace all of these; the removed Galacticraft generators sit in
// gc_gregify_removals.zs.
recipes.remove(<galaxyspace:fuel_generator:*>);      // Fuel Generator
recipes.remove(<galaxyspace:gas_generator:*>);       // Gas Generator
recipes.remove(<galaxyspace:gas_burner:*>);          // Gas Burner
recipes.remove(<galaxyspace:modern_solarpanel:*>);   // Hybrid Solar Panel
recipes.remove(<galaxyspace:single_solarpanel:*>);   // Solar Mini-Panel
recipes.remove(<galaxyspace:modern_single_solarpanel:*>); // Modern Solar Mini-Panel
recipes.remove(<galaxyspace:panel_controller:*>);    // Mini-Panels Controller
recipes.remove(<galaxyspace:solarwind_panel:*>);     // Solar Wind Panel
recipes.remove(<galaxyspace:wind_generator:*>);      // Wind Turbine
recipes.remove(<galaxyspace:adv_wind_generator:*>);  // Advanced Wind Turbine

// Galaxy Space's own energy cluster - the upgrade of Galacticraft's Energy Storage Cluster,
// which is removed as well. Buffering is GregTech's job now.
recipes.remove(<galaxyspace:modern_storage_module:*>); // Modern Energy Cluster

// ------------------------------------------------- machines that duplicate a GregTech one
recipes.remove(<galaxyspace:assembly_machine:*>);         // -> GT assembler (GS calls it "modified compressor")
recipes.remove(<galaxyspace:adv_circuit_fabricator:*>);   // -> GT circuit production
recipes.remove(<galaxyspace:gas_collector:*>);            // -> GT gas collector
recipes.remove(<galaxyspace:gas_extractor:*>);            // -> GT fluid drilling rig
recipes.remove(<galaxyspace:liquid_separator:*>);         // -> GT distillery / centrifuge
recipes.remove(<galaxyspace:universal_recycler:*>);       // -> GT arc furnace / macerator

// ------------------------------------------------- Galaxy Space's own copy of GregTech's metals
// Galaxy Space ships cobalt, magnesium and nickel as a full ingot / block / nugget set, and its
// ingot is registered *first* under ingotCobalt / ingotMagnesium / ingotNickel (GregTech's is the
// second entry), so every recipe written against those names would hand out Galaxy Space's ingot.
// Same treatment as Galacticraft's duplicate metals in gc_gregify_removals.zs: the mod's own copies
// stop being craftable and the ore dictionary entries keep resolving to GregTech's items.
//
// Note that Galaxy Space's *plates* (galaxyspace:compressed_plates:0/1/2/3 - coal, cobalt,
// magnesium, nickel) are deliberately left alone: coal and magnesium have no GregTech plate at all,
// and the cobalt / nickel ones are only ever produced by GregTech's own hammer and flatten recipes,
// which is what Galaxy Space's own machines want.
recipes.remove(<galaxyspace:ingots:*>);
recipes.remove(<galaxyspace:blocksmetals:*>);
recipes.remove(<galaxyspace:nuggets:*>);

// The recipe pages of those machines. Galacticraft's equivalents are hidden in
// gc_gregify_removals.zs; Galaxy Space's JEI category ids were read from its own
// *RecipeCategory classes with javap (getUid), because guessing them throws
// "Unknown recipe category".
mods.jei.JEI.hideCategory("galaxyspace.assembler");
mods.jei.JEI.hideCategory("galaxyspace.universal_recycler");

// ...and the machine items themselves, each at the metadata the probe reported.
mods.jei.JEI.hide(<galaxyspace:fuel_generator:0>);
mods.jei.JEI.hide(<galaxyspace:gas_generator:0>);
mods.jei.JEI.hide(<galaxyspace:gas_burner:0>);
mods.jei.JEI.hide(<galaxyspace:modern_solarpanel:0>);
mods.jei.JEI.hide(<galaxyspace:single_solarpanel:0>);
mods.jei.JEI.hide(<galaxyspace:modern_single_solarpanel:0>);
mods.jei.JEI.hide(<galaxyspace:panel_controller:0>);
mods.jei.JEI.hide(<galaxyspace:solarwind_panel:0>);
mods.jei.JEI.hide(<galaxyspace:wind_generator:0>);
mods.jei.JEI.hide(<galaxyspace:adv_wind_generator:0>);
mods.jei.JEI.hide(<galaxyspace:modern_storage_module:0>);
mods.jei.JEI.hide(<galaxyspace:assembly_machine:0>);
mods.jei.JEI.hide(<galaxyspace:adv_circuit_fabricator:0>);
mods.jei.JEI.hide(<galaxyspace:gas_collector:0>);
mods.jei.JEI.hide(<galaxyspace:gas_extractor:100>);
mods.jei.JEI.hide(<galaxyspace:liquid_separator:0>);
mods.jei.JEI.hide(<galaxyspace:universal_recycler:0>);

// Interstellar: Exoplanets used to be covered here too. It has since been removed from the
// pack - its ores register their own furnace recipes, which collide with GTCEu's and fill the
// log with "Tried to register duplicate Furnace Recipe" - so nothing here targets it any more.

// ------------------------------------- Galaxy Space machines that must keep the compressed plates
// aa_minespace_oredict.zs takes Galacticraft's compressed plates and Galaxy Space's cobalt / nickel
// plates out of the shared plateX ore dictionary names, so plateCopper etc. now mean GregTech's
// plain plate and nothing else. That is the right fix for the ambiguity - but it must not hand
// Galaxy Space's machines a *cheaper* recipe than they had. These are exactly the recipes whose own
// grid asked for a plate from that shared name, and in Galaxy Space's design that plate was the
// Galacticraft compressed plate (two GregTech plates plus TNT) or Galaxy Space's own cobalt / nickel
// plate, so every one of them is rebuilt here against the compressed item it always meant:
//
//     <ore:plateSteel>    -> <ore:compressedSteel>              (Galacticraft compressed)
//     <ore:plateTin/Copper/Iron/Bronze/Titanium/Desh/Aluminum> -> <ore:compressedX>
//     <ore:plateCobalt>   -> <galaxyspace:compressed_plates:1>  (Galaxy Space, no compressedX name)
//     <ore:plateNickel>   -> <galaxyspace:compressed_plates:3>
//
// Everything else in each grid - wafers, aluminium wire, machine frames, canisters, batteries - is
// the mod's own item, unchanged, as are the output counts. The grids come from a live dump of the
// recipes before the ore dictionary was corrected.
recipes.remove(<galaxyspace:decoblocks:0>);
recipes.addShaped(<galaxyspace:decoblocks:0> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, <galaxyspace:compressed_plates:1>],
    [null, null, null]
]);

recipes.remove(<galaxyspace:decoblocks:2>);
recipes.addShaped(<galaxyspace:decoblocks:2> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, <galaxyspace:compressed_plates:3>],
    [null, null, null]
]);

recipes.remove(<galaxyspace:decoblocks:3>);
recipes.addShaped(<galaxyspace:decoblocks:3> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, <ore:compressedCopper>],
    [null, null, null]
]);

// The magnesium pair of the same family, added 2026-10-14 together with the `plateMagnesium`
// cleanup in `oredict.zs`: these two grids were the only recipes reading that name, so they are
// rebuilt against the item they always meant - Galaxy Space's compressed magnesium plate. The
// grids and the output counts are the mod's own, read out of a live dump before the ore dictionary
// was touched, and they are the same two shapes the cobalt / nickel / copper siblings above use.
recipes.remove(<galaxyspace:decoblocks:1>);
recipes.addShaped(<galaxyspace:decoblocks:1> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, <galaxyspace:compressed_plates:2>],
    [null, null, null]
]);

recipes.remove(<galaxyspace:decoblocks:5>);
recipes.addShaped(<galaxyspace:decoblocks:5> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [null, <galaxyspace:compressed_plates:2>, null]
]);

recipes.remove(<galaxyspace:decoblocks:4>);
recipes.addShaped(<galaxyspace:decoblocks:4> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [null, <galaxyspace:compressed_plates:1>, null]
]);

recipes.remove(<galaxyspace:decoblocks:6>);
recipes.addShaped(<galaxyspace:decoblocks:6> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [null, <galaxyspace:compressed_plates:3>, null]
]);

recipes.remove(<galaxyspace:decoblocks:7>);
recipes.addShaped(<galaxyspace:decoblocks:7> * 4, [
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [<ore:stoneSmooth>, <ore:stoneSmooth>, null],
    [null, <ore:compressedCopper>, null]
]);

recipes.remove(<galaxyspace:machineframes:0>);
recipes.addShaped(<galaxyspace:machineframes:0>, [
    [<ore:compressedSteel>, <ore:waferBasic>, <ore:compressedSteel>],
    [<galacticraftcore:aluminum_wire:0>, <ore:blockRedstone>, <galacticraftcore:aluminum_wire:0>],
    [<ore:compressedSteel>, <ore:waferBasic>, <ore:compressedSteel>]
]);

recipes.remove(<galaxyspace:machineframes:1>);
recipes.addShaped(<galaxyspace:machineframes:1>, [
    [<ore:compressedTitanium>, <ore:waferAdvanced>, <ore:compressedTitanium>],
    [<galacticraftcore:aluminum_wire:1>, <galaxyspace:machineframes:0>, <galacticraftcore:aluminum_wire:1>],
    [<ore:compressedTitanium>, <ore:waferAdvanced>, <ore:compressedTitanium>]
]);

recipes.remove(<galaxyspace:liquid_extractor:0>);
recipes.addShaped(<galaxyspace:liquid_extractor:0>, [
    [<ore:compressedSteel>, <galacticraftcore:fluid_tank:0>, <ore:compressedSteel>],
    [<galacticraftcore:aluminum_wire:1>, <galaxyspace:machineframes:0>, <galacticraftcore:aluminum_wire:1>],
    [<ore:waferAdvanced>, <galacticraftcore:fluid_pipe:0>, <ore:waferAdvanced>]
]);

recipes.remove(<galaxyspace:hydroponic_base:0>);
recipes.addShaped(<galaxyspace:hydroponic_base:0>, [
    [<galacticraftcore:basic_item:20>, <galacticraftcore:fluid_tank:0>, <galacticraftcore:oxygen_concentrator:0>],
    [<ore:compressedSteel>, <galaxyspace:machineframes:0>, <ore:compressedSteel>],
    [<ore:compressedSteel>, <galacticraftcore:aluminum_wire:1>, <ore:compressedSteel>]
]);

recipes.remove(<galaxyspace:modification_table:0>);
recipes.addShaped(<galaxyspace:modification_table:0>, [
    [<ore:waferAdvanced>, <galaxyspace:compressed_plates:1>, <ore:waferAdvanced>],
    [<ore:dustRedstone>, <galaxyspace:machineframes:0>, <ore:dustRedstone>],
    [<ore:compressedBronze>, <ore:waferModern>, <ore:compressedBronze>]
]);

recipes.remove(<galaxyspace:gs_basic:9>);
recipes.addShaped(<galaxyspace:gs_basic:9> * 3, [
    [<ore:compressedIron>, <ore:compressedIron>, <ore:compressedIron>],
    [<galacticraftcore:canister:0>, <minecraft:milk_bucket:0>, <galacticraftcore:canister:0>],
    [<ore:compressedIron>, <ore:compressedIron>, <ore:compressedIron>]
]);

recipes.remove(<galaxyspace:jetpack:200>);
recipes.addShaped(<galaxyspace:jetpack:200>, [
    [<galacticraftcore:fluid_pipe:0>, <galacticraftcore:battery:100>, <galacticraftcore:fluid_pipe:0>],
    [<ore:compressedSteel>, <galacticraftcore:steel_chestplate:0>, <ore:compressedSteel>],
    [<galacticraftcore:fuel_canister_partial:1>, <galacticraftcore:aluminum_wire:1>, <galacticraftcore:fuel_canister_partial:1>]
]);

recipes.remove(<galaxyspace:space_suit_light_chest:0>);
recipes.addShaped(<galaxyspace:space_suit_light_chest:0>, [
    [<ore:compressedAluminum>, <galaxyspace:advanced_battery:100>, <ore:compressedAluminum>],
    [<galacticraftcore:canvas:0>, <galaxyspace:cobalt_chest:0>, <galacticraftcore:canvas:0>],
    [<ore:compressedAluminum>, <galaxyspace:compressed_plates:3>, <ore:compressedAluminum>]
]);

recipes.remove(<galaxyspace:space_suit_light_legs:0>);
recipes.addShaped(<galaxyspace:space_suit_light_legs:0>, [
    [<ore:compressedAluminum>, <galaxyspace:advanced_battery:100>, <ore:compressedAluminum>],
    [<galacticraftcore:canvas:0>, <galaxyspace:cobalt_legs:0>, <galacticraftcore:canvas:0>],
    [<ore:compressedAluminum>, <galaxyspace:compressed_plates:3>, <ore:compressedAluminum>]
]);

recipes.remove(<galaxyspace:space_suit_light_feet:0>);
recipes.addShaped(<galaxyspace:space_suit_light_feet:0>, [
    [<galaxyspace:compressed_plates:3>, <galaxyspace:advanced_battery:100>, <galaxyspace:compressed_plates:3>],
    [<ore:compressedAluminum>, <galaxyspace:cobalt_boots:0>, <ore:compressedAluminum>],
    [<galacticraftcore:canvas:0>, null, <galacticraftcore:canvas:0>]
]);

recipes.remove(<galaxyspace:advanced_battery:100>);
recipes.addShaped(<galaxyspace:advanced_battery:100>, [
    [null, <galaxyspace:compressed_plates:3>, null],
    [<galaxyspace:compressed_plates:3>, <galacticraftcore:battery:100>, <galaxyspace:compressed_plates:3>],
    [<galaxyspace:compressed_plates:3>, <ore:dustRedstone>, <galaxyspace:compressed_plates:3>]
]);

recipes.remove(<galaxyspace:modern_battery:100>);
recipes.addShaped(<galaxyspace:modern_battery:100>, [
    [<galaxyspace:advanced_battery:100>, <ore:compressedTitanium>, <galaxyspace:advanced_battery:100>],
    [<ore:compressedTitanium>, <ore:dustSulfur>, <ore:compressedTitanium>],
    [<ore:compressedTitanium>, <ore:dustRedstone>, <ore:compressedTitanium>]
]);

recipes.remove(<galaxyspace:gs_basic:1>);
recipes.addShaped(<galaxyspace:gs_basic:1>, [
    [<galacticraftcore:steel_pole:0>, null, null],
    [<ore:compressedSteel>, <galacticraftcore:steel_pole:0>, null],
    [<galacticraftcore:basic_item:0>, <ore:compressedIron>, <galacticraftcore:steel_pole:0>]
]);

recipes.remove(<galaxyspace:rocket_modules:2>);
recipes.addShaped(<galaxyspace:rocket_modules:2>, [
    [<ore:compressedSteel>, <ore:chestWood>, <ore:compressedSteel>],
    [<galacticraftcore:steel_pole:0>, <galacticraftcore:buggymat:1>, <galacticraftcore:steel_pole:0>],
    [<ore:compressedSteel>, <ore:compressedSteel>, <ore:compressedSteel>]
]);

recipes.remove(<galaxyspace:gs_basic:11>);
recipes.addShaped(<galaxyspace:gs_basic:11>, [
    [<ore:compressedTin>, <ore:ingotGold>, <ore:compressedTin>],
    [<ore:dustRedstone>, <galaxyspace:compressed_plates:1>, <ore:dustRedstone>],
    [<ore:compressedTin>, <ore:waferBasic>, <ore:compressedTin>]
]);

recipes.remove(<galaxyspace:gs_basic:32>);
recipes.addShaped(<galaxyspace:gs_basic:32>, [
    [<ore:compressedSteel>, <ore:compressedSteel>, <ore:compressedSteel>],
    [<galacticraftcore:grating:0>, <minecraft:carpet:0>, <ore:compressedSteel>],
    [<ore:compressedSteel>, <ore:compressedSteel>, <ore:compressedSteel>]
]);

recipes.remove(<galaxyspace:gs_basic:33>);
recipes.addShaped(<galaxyspace:gs_basic:33>, [
    [<ore:compressedIron>, <ore:dustRedstone>, <ore:compressedIron>],
    [<ore:dustRedstone>, <ore:waferBasic>, <ore:dustRedstone>],
    [<ore:compressedIron>, <ore:dustRedstone>, <ore:compressedIron>]
]);

// ============================== Galaxy Space's own plates: the machines that made them are gone
//
// Galaxy Space makes its plate family in two of its own machines, and this pack removed both of them
// in the removals above, because GregTech already has equivalents:
//
//   * its compressed plates came out of **Galacticraft's Compressor** (GS calls the same block its
//     "modified compressor" when it registers `galaxyspace:assembly_machine`, which the removals take
//     away as "-> GT assembler");
//   * the SDHC-120 alloy and the Heavy Duty Plates came out of **GS's Assembly Machine**
//     (`galaxyspace:assembly_machine`, "-> GT assembler").
//
// The machine pass rebuilt GS's *blocks* against GregTech, but never rebuilt these *parts*, so four of
// them ended up with no producer at all - a probe over every recipe registry and every GregTech recipe
// map found: compressed coal 0 recipes, compressed magnesium 0, the SDHC-120 alloy plate 0, and all
// eight Heavy Duty Plates 0. (Cobalt and nickel survived only because Gregicality generated
// "material form" recipes for them, which is a separate story - see TJ-MIGRATION-PLAN.md 6o.)
//
// The recipes below are Galaxy Space's own, read out of its source
// (`BlesseNtumble/GalaxySpace`, `.../overworld/recipes/CraftingRecipesOverworld.java`), with GregTech's
// **compressor** standing in for Galacticraft's and GregTech's **assembler** for GS's:
//
//     CompressorRecipes  :0 <- 9 coal        (or 1 coal block)
//     CompressorRecipes  :1 <- 2 cobalt ingots
//     CompressorRecipes  :2 <- 2 magnesium ingots
//     CompressorRecipes  :3 <- 2 nickel ingots
//     AssemblyRecipes    :4 <- bronze plate + "plateCoal" + aluminium plate
//
// The "plateCoal" there is GS's own compressed coal plate, which is why :0 has to exist for the alloy
// plate to be buildable at all. Costs are GS's own; only the machine changed. The Heavy Duty Plates are
// a separate decision, see the note at the bottom of this file.

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<minecraft:coal:0> * 9)
    .outputs(<galaxyspace:compressed_plates:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<minecraft:coal_block:0>)
    .outputs(<galaxyspace:compressed_plates:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:ingotCobalt> * 2)
    .outputs(<galaxyspace:compressed_plates:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:ingotMagnesium> * 2)
    .outputs(<galaxyspace:compressed_plates:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:ingotNickel> * 2)
    .outputs(<galaxyspace:compressed_plates:3>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:compressedBronze>, <galaxyspace:compressed_plates:0>, <ore:compressedAluminum>)
    .circuit(1)
    .outputs(<galaxyspace:compressed_plates:4>)
    .duration(400).EUt(30)
    .buildAndRegister();

// ------------------------------------------------- Heavy Duty Plates: the mod machinery goes, GT comes in
//
// These are the items that "needed another mod's machine", which by the owner's rule have to be made
// in a GregTech machine instead. Galaxy Space's Heavy Duty Plates and Galacticraft's own Heavy-Duty
// Plate were all made inside machines this pack deleted - Galacticraft's Compressor and GS's Assembly
// Machine - and a probe found **no producer anywhere** for Galacticraft's `item_basic_asteroids:5` or
// for any of GS's `hdp:0..7`, which left GS's rocket parts (built from `HDP:i` per tier) unbuildable.
//
// The chains below are Galaxy Space's own, read out of its source
// (BlesseNtumble/GalaxySpace, .../overworld/recipes/AssemblyRecipes.java), with GregTech's compressor
// and assembler standing in for the two removed machines:
//
//     Galacticraft Heavy-Duty Plate <- 2 titanium ingots                      (compressor)
//     hdp:0  <- GS magnesium plate + SDHC-120 alloy + Galacticraft HD plate   (assembler)
//     hdp:1  <- GS cobalt plate + hdp:0 + GS nickel plate + dolomite          (assembler)
//     hdp:2  <- SDHC-120 alloy + hdp:1 + volcanic rock                        (assembler)
//
// Two ingredients needed substituting, and this is the one place the pack had to choose rather than
// transliterate: GS's source names a "dolomite meal" and a "volcanic stone" that do not exist as items
// in the GS 2.2.0 jar this pack runs (a scan of every item's display name finds neither). The closest
// real materials are GregTech's dolomite dust and Galacticraft's Venus Volcanic Rock
// (`galacticraftplanets:venus:2`), which is what is used here.
//
// ------------------------------- `hdp:3..7`: one real gap and four that are only cosmetic
// Galaxy Space ships eight damage values for this item, and its own recipes reach exactly four of them.
// Disassembling the 2.2.0 jar settles it: all five NASA-workbench part recipes
// (`Schematic{Body,Booster,Cone,Engine,Fins}Recipe.registerRecipeWorkBench()`) run
// `for (int i = 0; i <= 3; i++)` and build their part out of `new ItemStack(HDP, 1, i)`, and the
// deconstructor's salvage list stops at `HDP:2`. Nothing anywhere in the jar asks for 4, 5, 6 or 7.
//
// So **hdp:3 is a real gap**: without it the fourth rocket's body, booster, cone, engine and fins
// cannot be assembled at the workbench at all. It is built here by continuing the mod's own pattern -
// previous tier, a plate of the next rocket metal, and the dolomite the tiers above already use.
//
// `hdp:4..7` are **this pack's invention, not a port** - there is no Galaxy Space recipe to restore,
// because there never was one. They are filled in anyway: an item that ships with eight tiers and can
// only ever make four of them is worse than one that is explicit about it. Each step is a strictly
// dearer version of the one below it (previous tier + two more plates + a mineral, at the next
// voltage), so they can be deleted again without breaking a single mod recipe if the owner would
// rather have the family stop at four.

mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:ingotTitanium> * 2)
    .outputs(<galacticraftplanets:item_basic_asteroids:5>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:compressed_plates:2>, <galaxyspace:compressed_plates:4>,
            <galacticraftplanets:item_basic_asteroids:5>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:compressed_plates:1>, <galaxyspace:hdp:0>,
            <galaxyspace:compressed_plates:3>, <ore:dustDolomite>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:1>)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:compressed_plates:4>, <galaxyspace:hdp:1>,
            <galacticraftplanets:venus:2>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:2>)
    .duration(400).EUt(30)
    .buildAndRegister();

// hdp:3 - the fourth tier, and the only one of 3..7 that Galaxy Space itself asks for.
// Desh is Mars' metal, stainless steel is the first plate that needs a GregTech blast furnace, and the
// dolomite is the same mineral tier 1 already uses.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:hdp:2>, <ore:plateDesh>, <ore:plateStainlessSteel>, <ore:dustDolomite>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:3>)
    .duration(600).EUt(120)
    .buildAndRegister();

// hdp:4..7 - the four tiers Galaxy Space never defined. Same shape, one voltage up each time:
// the previous plate, the next two metals in the rocket ladder, and one mineral or machine part
// that belongs to the world that tier is aimed at.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:hdp:3>, <ore:plateTitanium>, <ore:plateTungsten>,
            <galacticraftplanets:item_basic_asteroids:5>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:4>)
    .duration(800).EUt(480)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:hdp:4>, <ore:plateTungstenSteel>, <ore:plateTitanium>,
            <galacticraftplanets:venus:2>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:5>)
    .duration(1000).EUt(1920)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:hdp:5>, <ore:plateHssg>, <ore:plateUltimet>, <ore:dustDolomite>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:6>)
    .duration(1200).EUt(7680)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:hdp:6>, <ore:plateHsse>, <ore:plateTungstenCarbide>, <ore:plateOsmiridium>)
    .circuit(1)
    .outputs(<galaxyspace:hdp:7>)
    .duration(1600).EUt(30720)
    .buildAndRegister();

