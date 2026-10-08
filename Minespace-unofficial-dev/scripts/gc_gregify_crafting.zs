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
recipes.addShaped(<galacticraftcore:landing_pad> * 3, [
    [<ore:compressedIron>,      <ore:compressedIron>,      <ore:compressedIron>],
    [<ore:plateAlloyAdvanced>,  <ore:plateAlloyAdvanced>,  <ore:plateAlloyAdvanced>],
    [<minecraft:iron_block>,    <minecraft:iron_block>,    <minecraft:iron_block>]
]);

// ------------------------------------------------------------------------- oxygen chain
// The original recipes were built from Galacticraft's own machines plus GT circuits and
// cables; GC 4.0.7's compressed plates are "compressedAluminum" (its own US spelling).
//
// The circuit is <ore:circuitLv>, not GT5's <ore:circuitBasic>: CEu renamed its circuit ore
// dictionary names after voltage tiers (circuitLv .. circuitUhv), and a server run showed
// circuitBasic resolves but is an *empty* entry there - a recipe built on it would have a
// blank slot (the server log printed "circuit EMPTY circuitBasic" against
// "circuit OK circuitLv -> 3 stack(s), first gregtech:meta_item_1:621").
recipes.addShaped(<galacticraftcore:collector>, [
    [<ore:compressedAluminum>, <galacticraftcore:oxygen_concentrator>, <ore:compressedAluminum>],
    [<galacticraftcore:air_vent>, <galacticraftcore:air_fan>, <ore:circuitLv>],
    [<ore:compressedSteel>, <ore:cableGt02Aluminium>, <ore:compressedSteel>]
]);

recipes.addShaped(<galacticraftcore:oxygen_compressor>, [
    [<ore:compressedAluminum>, <galacticraftcore:oxygen_concentrator>, <ore:compressedAluminum>],
    [<ore:circuitLv>, <ore:compressedBronze>, <ore:craftingToolScrewdriver>],
    [<ore:compressedSteel>, <ore:compressedBronze>, <ore:compressedSteel>]
]);

recipes.addShaped(<galacticraftcore:distributor>, [
    [<ore:compressedAluminum>, <galacticraftcore:air_fan>, <ore:compressedAluminum>],
    [<galacticraftcore:air_vent>, <ore:circuitLv>, <galacticraftcore:air_vent>],
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
    [<ore:circuitLv>, <ore:compressedAluminum>]
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
