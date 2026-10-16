#priority 597
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// High-tech items come out of a GregTech machine, low-tech things may stay on the crafting table.
//
// This is the pass that closed the gap left by zzzz_minespace_assembler.zs and
// zzzz_minespace_assembler2.zs: those two took the machines of Ender IO, Forestry, AE2, Iron Chests,
// Storage Drawers, Galacticraft, Galacticraft Planets, Galaxy Space and PlanetProgression, but a
// second look for the same shape of item turned up the ones below still sitting on the crafting
// table. Nothing here is a *material* or a decoration - every one of them is a machine, a machine
// frame, a rocket part or an electronic component - so each keeps its own materials and output and
// simply moves to the assembler, with an integrated circuit, at LV 30 for Galacticraft's core-tier
// devices and AE2's 1k tier, MV 120 for the rest (the same rule the earlier two files use).
//
// Galacticraft core (LV 30)
//   air fan, oxygen bubble distributor, oxygen detector, spin thruster, display screen and the NASA
//   workbench itself. (The chromatic applicator was on this list until 2026-10-14, when the owner
//   approved deleting the machine itself - GC-GREGFICATION-PLAN.md's "Cosmetic; delete" row.)
//   Deliberately left on the table: the hydraulic platform and the air lock frame - both are
//   building blocks players place in quantity rather than machines.
// Galacticraft Planets (MV 120)
//   the Mars machine and the miner base.
// Galaxy Space (MV 120)
//   the two lower machine frames (the third tier was already moved by the earlier pass), the liquid
//   extractor, the hydroponic base, the modification table, the radiation stabiliser, the rocket
//   assembler, the first rocket module set and the two machine upgrades.
// Applied Energistics 2
//   the spatial and storage components (16/128 cubed and 1k..64k), the ME storage housing, the
//   blank pattern, the three fluid storage components, the three entry-level cells (item, fluid and
//   spatial) and the crafting accelerator - the last crafting-table electronics AE2 still had.
//   Left on the table: the cables and their dyeing, the paint balls, quartz glass and the
//   decorative cuts - all cheap, in-world work rather than devices.
//
// Every ingredient list below is the item's own crafting grid with the empty cells dropped and
// repeated cells folded into a count, and the hand tools the crafting grid asked for are gone: the
// machine does that work now.

// ------------------------------------------------------------------ Galacticraft core, LV 30
recipes.remove(<galacticraftcore:air_fan:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 4, <galacticraftcore:basic_item:13>, <minecraft:redstone>)
    .circuit(1)
    .outputs(<galacticraftcore:air_fan:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:distributor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:8> * 2, <galacticraftcore:air_fan:0> * 2, <galacticraftcore:air_vent:0> * 2, <ore:circuitBasic>, <galacticraftcore:basic_item:9> * 2)
    .circuit(1)
    .outputs(<galacticraftcore:distributor:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:oxygen_detector:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 2, <galacticraftcore:air_vent:0> * 2, <ore:circuitBasic>, <galacticraftcore:basic_item:8>)
    .circuit(1)
    .outputs(<galacticraftcore:oxygen_detector:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:spin_thruster:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 2, <galacticraftcore:fuel_canister_partial:1>, <galacticraftcore:basic_item:14>, <galacticraftcore:engine:0>, <gregtech:meta_item_1:10136>)
    .circuit(1)
    .outputs(<galacticraftcore:spin_thruster:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

recipes.remove(<galacticraftcore:view_screen:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 4, <galacticraftcore:basic_item:13> * 4, <minecraft:glass>)
    .circuit(1)
    .outputs(<galacticraftcore:view_screen:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

// The Chromatic Applicator's assembler recipe used to be built here - eight dyes and a compressed
// steel plate, with no integrated circuit because the nine inputs were already full (the lesson of
// TJ-MIGRATION-PLAN.md 6am). The machine is gone as of 2026-10-14: it is the GC-GREGFICATION-PLAN.md
// "Cosmetic; delete" row, approved by the owner, and `gc_removals.zs` carries the removal - recipe,
// item and the `machine3:0` correction (the plan's table had `:9`, which is only the index its lang
// file uses).

recipes.remove(<galacticraftcore:rocket_workbench:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 4, <minecraft:crafting_table>, <minecraft:lever> * 2, <galacticraftcore:basic_item:14>, <minecraft:redstone_torch>)
    .circuit(1)
    .outputs(<galacticraftcore:rocket_workbench:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

// ------------------------------------------------------------------ Galacticraft Planets, MV 120
recipes.remove(<galacticraftplanets:mars_machine:8>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:10000> * 4, <galacticraftcore:basic_item:19>, <galacticraftplanets:item_basic_mars:5> * 2, <galacticraftcore:basic_item:14>, <galacticraftcore:aluminum_wire>)
    .circuit(1)
    .outputs(<galacticraftplanets:mars_machine:8>)
    .duration(400).EUt(120)
    .buildAndRegister();

// The Astro Miner Base's assembler recipe used to be built here. The machine is gone as of
// 2026-10-14 (GC-GREGFICATION-PLAN.md's "Still to do": GregTech's ore/fluid drilling plants replace
// it), and `gc_removals.zs` carries the removal - grid, item and JEI category.

// The Orion Drive, and the one recipe in the pack that was still "nine raw ores in a 3x3 grid". The
// mod builds it from diamond, lapis, gold, redstone and coal ore, a block of moon rock, its own desh
// and ilmenite ores and an asteroid plate - nine things you dig up - and that is not a price for a
// nuclear-pulse propulsion unit. It is an HV assembler recipe now, and every ore is the material that
// comes out of it: a diamond plate, a desh plate, ilmenite dust and the pulse units as Uranium-235
// (two of them), all off a GregTech machine, plus a dense steel pusher plate and a titanium plate.
// The mod's own asteroid plating and moon block stay, so the mod's own chain still matters. The lapis
// and coal the grid used as filler are gone: the integrated circuit and the HV gate replace them.
recipes.remove(<galacticraftplanets:orion_drive:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_asteroids:8>, <galacticraftcore:basic_block_moon:2>, <ore:plateDenseSteel>, <ore:plateTitanium>, <ore:dustUranium235> * 2, <ore:plateDesh>, <ore:dustIlmenite>, <ore:plateDiamond>)
    .circuit(1)
    .outputs(<galacticraftplanets:orion_drive:0>)
    .duration(800).EUt(480)
    .buildAndRegister();

// ------------------------------------------------------------------ Galaxy Space, MV 120
recipes.remove(<galaxyspace:machineframes:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 4, <galacticraftcore:basic_item:13> * 2, <galacticraftcore:aluminum_wire> * 2, <minecraft:redstone_block>)
    .circuit(1)
    .outputs(<galaxyspace:machineframes:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:machineframes:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_asteroids:6> * 4, <galacticraftcore:basic_item:14> * 2, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes:0>)
    .circuit(1)
    .outputs(<galaxyspace:machineframes:1>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:liquid_extractor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 2, <galacticraftcore:fluid_tank>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes:0>, <galacticraftcore:basic_item:14> * 2, <galacticraftcore:fluid_pipe>)
    .circuit(1)
    .outputs(<galaxyspace:liquid_extractor:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:hydroponic_base:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 4, <galacticraftcore:basic_item:20>, <galacticraftcore:fluid_tank>, <galacticraftcore:oxygen_concentrator>, <galaxyspace:machineframes:0>, <galacticraftcore:aluminum_wire:1>)
    .circuit(1)
    .outputs(<galaxyspace:hydroponic_base:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:modification_table:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:14> * 2, <galaxyspace:compressed_plates:1>, <minecraft:redstone> * 2, <galaxyspace:machineframes:0>, <galacticraftcore:basic_item:10> * 2, <galaxyspace:gs_basic:5>)
    .circuit(1)
    .outputs(<galaxyspace:modification_table:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:radiation_stabiliser:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galaxyspace:gs_basic:3> * 4, <ore:blockCopper>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:machineframes:0>, <galaxyspace:gs_basic:5>)
    .circuit(1)
    .outputs(<galaxyspace:radiation_stabiliser:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:rocket_assembler:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:14> * 2, <galacticraftcore:rocket_workbench:0>, <ore:circuitAdvanced> * 2, <galaxyspace:machineframes:0>, <galacticraftcore:aluminum_wire:1> * 2, <galacticraftplanets:item_basic_asteroids:6>)
    .circuit(1)
    .outputs(<galaxyspace:rocket_assembler:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:rocket_modules:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:basic_item:9> * 3, <galacticraftcore:basic_item:19>, <galacticraftcore:buggymat:1>, <galacticraftcore:basic_item:6>, <galacticraftcore:steel_pole> * 2, <galacticraftcore:engine:0>)
    .circuit(1)
    .outputs(<galaxyspace:rocket_modules:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:upgrades:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:canister_partial_ln2:1>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:gs_basic:11>, <gregtech:meta_item_1:10044> * 2, <galaxyspace:gs_basic:5>)
    .circuit(1)
    .outputs(<galaxyspace:upgrades:2>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<galaxyspace:upgrades:3>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftplanets:basic_item_venus:4>, <galacticraftcore:aluminum_wire:1> * 2, <galaxyspace:gs_basic:11>, <gregtech:meta_item_1:10017> * 2, <galaxyspace:gs_basic:5>)
    .circuit(1)
    .outputs(<galaxyspace:upgrades:3>)
    .duration(400).EUt(120)
    .buildAndRegister();

// ------------------------------------------------------------------ Applied Energistics 2, storage
//
// Every storage item that used to live here - the 1k / 4k / 16k / 64k components and their fluid and
// spatial relatives, the ME storage housing, the blank pattern, the three entry-level cells and the
// crafting accelerator - moved to zzzzzzzz_minespace_ae2_storage.zs, where they were redesigned instead
// of being copied out of AE2's own grids. See that file for the recipe language.

// ------------------------------------------------------------------ Applied Energistics 2, higher tiers MV 120
