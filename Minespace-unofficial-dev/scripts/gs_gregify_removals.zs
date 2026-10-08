// Galaxy Space and Interstellar: Exoplanets get the same treatment Galacticraft got: their
// own power generation and the machines that duplicate a GregTech machine stop being craftable,
// and GregTech machines take over the job.
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

// No Interstellar: Exoplanets entry is needed: its only machine-like block is the satellite
// antenna (a prop for the rocket), and its ores smelting to GregTech ingots is GregTech's own
// behaviour - the "duplicate Furnace Recipe" lines in the log are GregTech reporting that its
// registration of the same ore -> ingot recipe was skipped because Exoplanets already had it.
// Same input, same output, so nothing to fix.
