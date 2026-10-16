#priority 849
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
// CraftTweaker port of the "Mods-Get-Gregged" Galacticraft *crafting table* recipes.
//
// These started life as a KubeJS script. KubeJS 1.12.2 turned out to be the wrong host for
// them: its crafting hook (dev.latvian.kubejs.crafting.KubeJSCraftingEventHandler) posts
// the events "recipes.crafting_table", "recipes.furnace" and "recipes.remove.output", and a
// listener registered on the plain id "recipes" -- which is what the project's own example
// scripts and docs use -- never receives anything. Every log this instance has produced was
// searched for the stock example script's own log line and none contains it, so the whole
// event was dead. CraftTweaker is the right host here anyway: the original pack is
// ZenScript, so these recipes are a transliteration rather than a rewrite.

// ---------------------------------------------------------------------------- removals
recipes.remove(<galacticraftcore:landing_pad>);
recipes.remove(<galacticraftcore:collector>);
recipes.remove(<galacticraftcore:oxygen_compressor>);
recipes.remove(<galacticraftcore:distributor>);
recipes.remove(<galacticraftcore:sealer>);
recipes.remove(<galacticraftcore:oxygen_detector>);
recipes.remove(<galacticraftcore:air_lock_frame>);

// The four canned foods move off the crafting grid and onto GregTech's canner; those
// recipes live in gc_gregify_machines.zs.
//
// Metadata note: these are 15..18, not 13..16. Galacticraft's basic_item metadata is the
// index into ItemBasic's `names` array, which was read out of Galacticraft-1.12.2-4.0.7
// with javap:
//
//   0 solar_module_0      5 ingot_aluminum       10 compressed_bronze     15 dehydrated_apple
//   1 solar_module_1      6 compressed_copper    11 compressed_iron      16 dehydrated_carrot
//   2 raw_silicon         7 compressed_tin       12 wafer_solar          17 dehydrated_melon
//   3 ingot_copper        8 compressed_aluminum  13 wafer_basic          18 dehydrated_potato
//   4 ingot_tin           9 compressed_steel     14 wafer_advanced       19 frequency_module
//
// (ItemBasic.getSubItems iterates 0..14 and 19..20 and getUnlocalizedName maps 15..18 onto
// ".canned_food", which is what pins the food down.) This also matches the GT5 source's own
// metadata values, so Galacticraft 3.x and 4.0.7 agree here and nothing needs shifting.
recipes.remove(<galacticraftcore:basic_item:15>);
recipes.remove(<galacticraftcore:basic_item:16>);
recipes.remove(<galacticraftcore:basic_item:17>);
recipes.remove(<galacticraftcore:basic_item:18>);

// ---------------------------------------------------------------------------- rocket pad
// Original: 3x launch pad = compressed iron x3 / advanced alloy plate x3 / iron block x3.
// The reference pack's "advanced alloy plate" is IC2's, and this pack has no IC2, so
// <ore:plateAlloyAdvanced> is registered but holds zero stacks - the whole middle row of the
// recipe was blank (JEI showed a launch pad that could not be made, and the pad is on the
// rocket critical path). GT's stainless-steel plate stands in: it is the same tier as the
// stainless screws the air lock frame below already asks for.
recipes.addShaped(<galacticraftcore:landing_pad> * 3, [
    [<ore:compressedIron>,      <ore:compressedIron>,      <ore:compressedIron>],
    [<ore:plateStainlessSteel>, <ore:plateStainlessSteel>, <ore:plateStainlessSteel>],
    [<minecraft:iron_block>,    <minecraft:iron_block>,    <minecraft:iron_block>]
]);

// ------------------------------------------------------------------------- oxygen chain
// The original recipes were built from Galacticraft's own machines plus GT circuits and
// cables; GC 4.0.7's compressed plates are "compressedAluminum" (its own US spelling).
//
// The circuit is <ore:circuitBasic> (GT5's name), NOT <ore:circuitLv>: GTCE-TJ kept GT5's
// circuit names (circuitPrimitive, circuitBasic, circuitGood, circuitAdvanced, ...) and the
// "tier" spellings circuitLv / circuitMv / circuitHv exist but are *empty* entries - the ore
// dictionary probe listed them as "circuitLv(0, first=empty)". A recipe written against one of
// them builds fine and lands in JEI with a blank circuit slot, which is an uncraftable recipe.
// circuitBasic(5 stacks), circuitGood(7) and circuitAdvanced(5) are the real ones.
// Superseded by GregTech: this machine is removed by gc_gregify_removals.zs,
// which loads after this file. See the note in tools\port-crafttweaker-scripts.ps1.
// recipes.addShaped(<galacticraftcore:collector>, [
//     [<ore:compressedAluminum>, <galacticraftcore:oxygen_concentrator>, <ore:compressedAluminum>],
//     [<galacticraftcore:air_vent>, <galacticraftcore:air_fan>, <ore:circuitLv>],
//     [<ore:compressedSteel>, <ore:cableGt02Aluminium>, <ore:compressedSteel>]
// ]);

// Superseded by GregTech: this machine is removed by gc_gregify_removals.zs,
// which loads after this file. See the note in tools\port-crafttweaker-scripts.ps1.
// recipes.addShaped(<galacticraftcore:oxygen_compressor>, [
//     [<ore:compressedAluminum>, <galacticraftcore:oxygen_concentrator>, <ore:compressedAluminum>],
//     [<ore:circuitLv>, <ore:compressedBronze>, <ore:craftingToolScrewdriver>],
//     [<ore:compressedSteel>, <ore:compressedBronze>, <ore:compressedSteel>]
// ]);

recipes.addShaped(<galacticraftcore:distributor>, [
    [<ore:compressedAluminum>, <galacticraftcore:air_fan>, <ore:compressedAluminum>],
    [<galacticraftcore:air_vent>, <ore:circuitBasic>, <galacticraftcore:air_vent>],
    [<ore:compressedSteel>, <galacticraftcore:air_fan>, <ore:compressedSteel>]
]);

recipes.addShaped(<galacticraftcore:sealer>, [
    [<ore:compressedAluminum>, <galacticraftcore:air_vent>, <ore:compressedAluminum>],
    [<galacticraftcore:air_vent>, <galacticraftcore:distributor>, <galacticraftcore:air_vent>],
    [<ore:compressedSteel>, <galacticraftcore:oxygen_detector>, <ore:compressedSteel>]
]);

recipes.addShaped(<galacticraftcore:oxygen_detector>, [
    [<ore:compressedSteel>, <ore:compressedSteel>],
    [<galacticraftcore:air_vent>, <galacticraftcore:air_vent>],
    [<ore:circuitBasic>, <ore:compressedAluminum>]
]);

// -------------------------------------------------------------------------- air lock
recipes.addShaped(<galacticraftcore:air_lock_frame> * 2, [
    [<ore:compressedMeteoricIron>, <ore:screwStainlessSteel>, <ore:compressedMeteoricIron>],
    [<galacticraftcore:air_vent>, <ore:craftingToolScrewdriver>, <galacticraftcore:air_vent>],
    [<ore:compressedAluminum>, <ore:screwStainlessSteel>, <ore:compressedAluminum>]
]);

// ------------------------------------------------------- solar dust, GT -> Galacticraft
// Galacticraft's circuit fabricator consumes its own solar dust item, which carries no ore
// dictionary name, so GregTech's solar dust is converted into it. (This used to be a KubeJS
// recipe and therefore never existed.)
recipes.addShapeless(<galacticraftplanets:basic_item_venus:4>, [<ore:dustSolar>]);

// ------------------------------------------------------------------- aluminium wire
// Galacticraft's wire used to be six for three aluminium ingots and six wool on the crafting table -
// copper-age wiring, and it is the item *everything* in a Galacticraft base is wired with. It cannot
// simply be deleted: 19 Galacticraft recipes use the wire as a material, including the life-support
// and logistics machines this pack deliberately keeps (machine2:0 / machine2:4 / machine2:12,
// enclosed:14 / enclosed:15, basic_item:0, ...), so deleting it would strand those machines instead
// of gregging anything.
//
// The owner's complaint was that *the crafting* was too easy, and the follow-up was "put all of them
// in the assembler", so **the whole wire family moves to a GregTech assembler at LV** - nothing about
// the wire is left on the crafting table:
//
//   wire:0  6 GregTech fine aluminium wire (a wiremill item) + 6 wool      -> 6 wires
//   wire:1  1 GT aluminium ingot + 1 wire:0 + 1 wool                      -> 1 heavy wire
//   wire:2  1 wire:0 + 1 repeater                                         -> 1 switch wire
//   wire:3  1 wire:1 + 1 repeater                                         -> 1 redstone-controlled wire
//
// Two notes on the shapes. Galacticraft shipped *two* mirrored grid recipes for wire:1 (one reading
// Z/Y/X and one reading X/Y/Z); an assembler recipe is a flat input list, so they collapse into the
// single wire:1 recipe below - the same materials, just not two mirror images of the same thing. The
// wool stays a wildcard: the original JSON used `data: 32767`, which is every colour, and it was
// checked against all sixteen on a live run rather than assumed.
recipes.remove(<galacticraftcore:aluminum_wire:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_2:16001> * 3, <minecraft:wool:*> * 6)
    .circuit(1)
    .outputs(<galacticraftcore:aluminum_wire:0> * 6)
    .duration(200).EUt(30)
    .buildAndRegister();

// catches both of Galacticraft's mirrored wire:1 recipes - a removal matches on the output
recipes.remove(<galacticraftcore:aluminum_wire:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:10001>, <galacticraftcore:aluminum_wire:0>, <minecraft:wool:*>)
    .circuit(1)
    .outputs(<galacticraftcore:aluminum_wire:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:aluminum_wire:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:aluminum_wire:0>, <minecraft:repeater:0>)
    .circuit(1)
    .outputs(<galacticraftcore:aluminum_wire:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:aluminum_wire:3>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:aluminum_wire:1>, <minecraft:repeater:0>)
    .circuit(1)
    .outputs(<galacticraftcore:aluminum_wire:3>)
    .duration(200).EUt(30)
    .buildAndRegister();
