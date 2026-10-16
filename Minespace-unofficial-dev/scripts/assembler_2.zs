#priority 796
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Advanced machines that were still built at the crafting table, moved into the GregTech assembler.
//
// The "an advanced machine has to come out of a GregTech machine" rule of zzzz_minespace_assembler.zs
// was applied to Ender IO, Forestry and AE2. This file finishes the job for the other three mods:
// what is left of Galacticraft's, Galacticraft-Planets', Galaxy Space's and PlanetProgression's
// machines still sits on the crafting table. Each grid is read out of the live recipe registry by a
// probe, flattened into an assembler input list - nothing dropped, no yield lowered - plus an
// integrated circuit, at the voltage the item's own tier puts it at (Galacticraft core simple ->
// LV 30, everything else -> MV 120).
//
// The probe printed one entry per crafting-grid *slot*; the lists below fold the repeated slots into
// a count (`<X> * 4`). That folding is not cosmetic. GregTech's assembler accepts at most nine
// inputs, and the integrated circuit built with `.circuit(n)` is one of them - so a list written as
// nine separate stacks plus a circuit is rejected outright with
//
//   Invalid amount of recipe inputs. Actual: 10. Should be between 1 and 9 inclusive.
//
// the recipe is dropped, and the machine it was supposed to make is left with no route at all. That
// is exactly what happened here on the first pass: all twenty-four recipes below were silently lost
// (a probe over the finished recipe maps found the outputs gone, not merely re-priced), which is what
// the owner saw as "you deleted the recipes and now they cannot be made". Every input list in this
// file now folds to eight entries or fewer, and a verification pass reads the assembler map back at
// load complete to prove each of these outputs has a recipe again.
//
// Two entries the probe printed truncated (an ingredient with more than six alternatives) are
// deliberately skipped: guessing which alternative was meant would silently narrow the recipe.

recipes.remove(<galaxyspace:hydroponic_farm:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:glass> * 5, <minecraft:dirt>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes>)
    .circuit(1)
    .outputs(<galaxyspace:hydroponic_farm:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:energy_pad:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:futureglass_none> * 2, <galacticraftcore:platform>, <minecraft:redstone> * 2, <galaxyspace:gs_basic:5>, <galacticraftplanets:item_basic_mars:5> * 2, <galacticraftcore:aluminum_wire:1>)
    .circuit(1)
    .outputs(<galaxyspace:energy_pad:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:planet_shield:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_mars:6> * 2, <galaxyspace:gravitation_module>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes:2>, <galaxyspace:hdp> * 3)
    .circuit(1)
    .outputs(<galaxyspace:planet_shield:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:oxygen_storage_module_1:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:machine2:8> * 4, <galacticraftcore:oxygen_concentrator>, <galacticraftcore:fluid_pipe> * 2, <galaxyspace:machineframes:1>, <galaxyspace:gs_basic:5>)
    .circuit(1)
    .outputs(<galaxyspace:oxygen_storage_module_1:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:gravitation_module:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:compressed_plates:4> * 2, <galaxyspace:gs_basic:8>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes>, <galacticraftcore:basic_item:14> * 2, <galaxyspace:machineframes:2>)
    .circuit(1)
    .outputs(<galaxyspace:gravitation_module:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:machineframes:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:compressed_plates:2> * 4, <galaxyspace:gs_basic:5> * 2, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes:1>)
    .circuit(1)
    .outputs(<galaxyspace:machineframes:2>)
    .duration(400).EUt(120)
    .buildAndRegister();

// PlanetProgression's remaining item: a credit-card-sized reader card for Galacticraft's
// communication dish. It was still on the crafting table, and it is exactly the kind of item
// GregTech expects out of an assembler - a card with a chip in it - so it moves there as well, with
// the mod's own nine materials and an integrated circuit, at LV.
recipes.remove(<galacticraftplanets:mars_machine:4>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_mars:5> * 6, <galacticraftplanets:item_basic_mars:3> * 2, <minecraft:bed>)
    .circuit(1)
    .outputs(<galacticraftplanets:mars_machine:4>)
    .duration(400).EUt(120)
    .buildAndRegister();

// The Energy Beam Reflector's assembler recipe used to be built here - "the mod ships it twice, as a
// grid and as its mirror image", folded into three inputs. The machine is gone as of 2026-10-14
// (TJ-MIGRATION-PLAN.md 6ci): a reflector only redirects the *solar array's* energy beams, and every
// other part of that network - the Solar Array Controller, the Solar Array Module and the Energy Beam
// Receiver - was already removed, so it is the last orphan of a chain this pack deletes.

recipes.remove(<galacticraftplanets:telepad_short:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_asteroids:6> * 5, <galacticraftplanets:item_basic_asteroids:8>, <minecraft:ender_pearl> * 2, <minecraft:redstone>)
    .circuit(1)
    .outputs(<galacticraftplanets:telepad_short:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galacticraftplanets:heavy_nose_cone:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:redstone_torch>, <galacticraftplanets:item_basic_asteroids:5> * 3)
    .circuit(1)
    .outputs(<galacticraftplanets:heavy_nose_cone:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

// The engine has the same mirror-image pair as the beam reflector. Four of the nine slots held heavy
// plating, so they fold into one stack of four.
recipes.remove(<galacticraftcore:engine:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:stone_button>, <minecraft:flint_and_steel>, <galacticraftcore:heavy_plating> * 4, <galacticraftcore:canister>, <galacticraftcore:air_vent>)
    .circuit(1)
    .outputs(<galacticraftcore:engine:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:cargo:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 5, <minecraft:hopper>, <galacticraftcore:basic_item:8> * 2, <minecraft:chest>)
    .circuit(1)
    .outputs(<galacticraftcore:cargo:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:cargo:4>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 5, <galacticraftcore:basic_item:8> * 2, <minecraft:chest>, <minecraft:hopper>)
    .circuit(1)
    .outputs(<galacticraftcore:cargo:4>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:dishbase:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:8> * 3, <galacticraftcore:basic_item:19>, <galacticraftcore:basic_item:14> * 2, <minecraft:iron_block>)
    .circuit(1)
    .outputs(<galacticraftcore:dishbase:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:buggymat:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 6, <galacticraftcore:basic_item:11> * 2, <minecraft:chest>)
    .circuit(1)
    .outputs(<galacticraftcore:buggymat:2>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:basic_item:19>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:8>, <galacticraftcore:basic_item:11> * 2, <minecraft:repeater>, <minecraft:redstone> * 2, <galacticraftcore:basic_item:13>)
    .circuit(1)
    .outputs(<galacticraftcore:basic_item:19>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:basic_item:20>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:redstone> * 2, <galacticraftcore:air_vent>, <galacticraftcore:basic_item:10> * 4, <galacticraftcore:basic_item:9>, <galacticraftcore:basic_item:13>)
    .circuit(1)
    .outputs(<galacticraftcore:basic_item:20>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:telemetry:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:7> * 4, <galacticraftcore:basic_item:19>, <galacticraftcore:basic_item:13>, <galacticraftcore:basic_item:6> * 3)
    .circuit(1)
    .outputs(<galacticraftcore:telemetry:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:battery:100>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:7> * 5, <minecraft:redstone>, <minecraft:coal>)
    .circuit(1)
    .outputs(<galacticraftcore:battery:100>)
    .duration(400).EUt(30)
    .buildAndRegister();


// ---- Galacticraft's Heavy-Duty Plate, which the deleted compressor used to make
//
// GC's own recipe (its `RecipeManagerGC`, disassembled out of the jar) is a *compressor* shape:
// "XYZ"/"XYZ" with X = compressed steel, Y = compressed aluminium, Z = compressed bronze, giving two
// Heavy-Duty Plates. Galacticraft's compressor is gone in this pack, so that recipe went with it and
// **nothing else produces the plate** - which left every GC rocket part that needs one (the engine,
// the nose cone, the fins) uncraftable. The three compressed plates are themselves already made in
// GregTech machines, so this becomes an assembly job: the same six plates, the same two out, in the
// assembler.
recipes.remove(<galacticraftcore:heavy_plating>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:compressedSteel> * 2, <ore:compressedAluminum> * 2, <ore:compressedBronze> * 2)
    .circuit(1)
    .outputs(<galacticraftcore:heavy_plating> * 2)
    .duration(400).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ Ender IO's conduits and the
// ------------------------------------------------------------------ second capacitor tier
//
// The owner's follow-up: "the other things that look high-tech can go into the assembler as well".
// Ender IO's liquid and item conduits and the second capacitor tier were still crafting-table work:
// eight pieces of Conduit Binder around the interesting part. A conduit is a machine component, so it
// is an assembler job now, with an integrated circuit. Materials unchanged, no count lowered.
//
// The alloy ingots in these grids are already GregTech's by the time this runs -
// MinespaceMaterialRepoint re-points the crafting-table inputs (see zzzzzz_minespace_eio_materials.zs).
//
// *Not* in this batch, on purpose: the ME conduits. One of their three recipes accepts *any* of the
// seventeen coloured AE2 cables in its centre slot, the recipe dump prints that slot truncated, and
// removing the output would take all three recipes with it - including the one that cannot be written
// back without guessing. They stay as they are.

recipes.remove(<enderio:item_liquid_conduit:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_material:4> * 6, <enderio:block_fused_quartz> * 3)
    .circuit(1)
    .outputs(<enderio:item_liquid_conduit:1>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_liquid_conduit:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_material:4> * 6, <enderio:block_fused_quartz> * 2, <enderio:item_liquid_conduit>)
    .circuit(1)
    .outputs(<enderio:item_liquid_conduit:1>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_liquid_conduit:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_material:4> * 6, <enderio:item_alloy_ingot:2> * 2, <enderio:block_fused_quartz>)
    .circuit(1)
    .outputs(<enderio:item_liquid_conduit:2>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_liquid_conduit:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_material:4> * 6, <enderio:item_alloy_ingot:2> * 2, <enderio:item_liquid_conduit:1>)
    .circuit(1)
    .outputs(<enderio:item_liquid_conduit:2>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_item_conduit:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_material:4> * 6, <enderio:item_alloy_nugget:5> * 3)
    .circuit(1)
    .outputs(<enderio:item_item_conduit:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_basic_capacitor:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_alloy_ingot:2> * 2, <enderio:item_basic_capacitor:1> * 2, <minecraft:glowstone>)
    .circuit(1)
    .outputs(<enderio:item_basic_capacitor:2>)
    .duration(400).EUt(120)
    .buildAndRegister();

