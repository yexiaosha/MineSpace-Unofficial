#priority 850
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
// Removes Galacticraft's own way of *making materials*, *processing materials* and
// *generating power*, so this pack's industry is GregTech's. This is the "take it away"
// half of the port; the "give it back" half lives in:
//
//   gc_gregify_crafting.zs    crafting-table re-additions built from GregTech parts
//   gc_gregify_machines.zs    GregTech machine recipes for Galacticraft items
//   gc_gregify_processing.zs  the ore-to-metal chain (macerator / implosion / blast furnace)
//
// What replaces what:
//
//   Galacticraft machine        GregTech replacement
//   --------------------------  -------------------------------------------------------
//   Compressor / Electric        Bender for plates; implosion compressor for Galacticraft's
//   Compressor / Advanced        compressed plates; compressor for block packing
//   Compressor (all three)
//   Electric Furnace (T1/T2)     GT electric / arc furnace and the multi smelter
//   Electric Arc Furnace         GT electric blast furnace (titanium is already ported)
//   Circuit Fabricator           GT circuit production (wafers are assembled in GT now)
//   Coal Generator / Solar       GT generators + GT's EU -> Forge Energy converter, which is
//   Panel / Energy Storage       what feeds Galacticraft's own machines (see the note at the
//                                bottom - Galacticraft eats Forge Energy, GTCEu can emit it)
//   Deconstructor                GT arc furnace / macerator recycling
//
// Galacticraft supplies 6 of the metals GregTech already has (copper, tin, aluminium,
// bronze, steel, iron) plus silicon. Those duplicates, their blocks, the compressed plates
// and the wafers stop being craftable here; GregTech's own ingots / plates / circuits are
// what the remaining Galacticraft recipes use, because Galacticraft registers them under the
// same ore dictionary names and the re-added recipes are written against those.

// ------------------------------------------------------------ material processing machines
// The `machine` and `machine_tiered` blocks hold nothing but machines:
//   0 Coal Generator        1 Energy Storage Module   2 Electric Furnace (T1)
//   3 Compressor            7 Electric Arc Furnace    8 Energy Storage Cluster
// `machine_tiered` holds the tier-2 versions of the same set. Both are removed whole.
recipes.remove(<galacticraftcore:machine:*>);
recipes.remove(<galacticraftcore:machine_tiered:*>);

// `machine2` also holds the Oxygen Storage Module (meta 6), which is life support and stays -
// so these are removed one meta at a time rather than with a wildcard.
recipes.remove(<galacticraftcore:machine2:0>);   // Electric Compressor
recipes.remove(<galacticraftcore:machine2:4>);   // Circuit Fabricator
recipes.remove(<galacticraftcore:machine2:12>);  // Deconstructor

recipes.remove(<galacticraftcore:machine4:0>);  // Advanced Compressor

// Fluid and gas processing. Each one is replaced by a GregTech recipe, see the "Fluids"
// section of gc_gregify_processing.zs:
//   Refinery            -> GT distillery (crude oil -> rocket fuel)
//   Oxygen Collector    -> GT gas collector (breathable oxygen out of the air)
//   Gas Liquefier       -> GT vacuum freezer / fluid handling
//   Methane Synthesizer -> GT chemical reactor
//   Water Electrolyzer  -> GT electrolyzer
recipes.remove(<galacticraftcore:refinery>);
recipes.remove(<galacticraftcore:collector>);          // Oxygen Collector
recipes.remove(<galacticraftplanets:mars_machine_t2:0>); // Gas Liquefier
recipes.remove(<galacticraftplanets:mars_machine_t2:4>); // Methane Synthesizer
recipes.remove(<galacticraftplanets:mars_machine_t2:8>); // Water Electrolyzer

// ------------------------------------------------------------------------- power generation
// 0 = Basic Solar Panel, 1 = Advanced Solar Panel. Both only make Galacticraft's own gJ,
// which GregTech cannot feed directly; GT's energy reaches Galacticraft through the
// EU -> Forge Energy converter instead (see the bottom of this file).
recipes.remove(<galacticraftcore:solar:*>);

// The Venus power set: a Solar Array Controller, its Solar Array Modules and the Geothermal
// Generator. Registry names read off a running server (CraftTweaker's
// itemUtils.getItemsByRegexRegistryName on ".*solar.*", ".*generator.*" and ".*beam.*"),
// because the block classes do not carry their own names:
//
//   galacticraftplanets:solar_array_controller   Solar Array Controller
//   galacticraftplanets:solar_array_module       Solar Array Module
//   galacticraftplanets:geothermal_generator     Geothermal Generator
//   galacticraftplanets:beam_receiver            Energy Beam Receiver
//
// The beam receiver/reflector pair only exists to carry the solar array's power around, so it
// goes with the array.
recipes.remove(<galacticraftplanets:solar_array_controller>);
recipes.remove(<galacticraftplanets:solar_array_module>);
recipes.remove(<galacticraftplanets:geothermal_generator>);
recipes.remove(<galacticraftplanets:beam_receiver>);

// ---------------------------------------------------------------------------- Galacticraft materials
// basic_item metadata, read out of the 4.0.7 jar with javap (index into ItemBasic#names):
//   2 raw silicon, 3 copper ingot, 4 tin ingot, 5 aluminium ingot,
//   6..11 compressed copper/tin/aluminium/steel/bronze/iron,
//   12 blue solar wafer, 13 basic wafer, 14 advanced wafer
// (meta 0/1 solar modules and 19/20 frequency module / thermal controller are Galacticraft
// parts rather than duplicate materials, so they stay craftable.)
recipes.remove(<galacticraftcore:basic_item:2>);
recipes.remove(<galacticraftcore:basic_item:3>);
recipes.remove(<galacticraftcore:basic_item:4>);
recipes.remove(<galacticraftcore:basic_item:5>);
recipes.remove(<galacticraftcore:basic_item:6>);
recipes.remove(<galacticraftcore:basic_item:7>);
recipes.remove(<galacticraftcore:basic_item:8>);
recipes.remove(<galacticraftcore:basic_item:9>);
recipes.remove(<galacticraftcore:basic_item:10>);
recipes.remove(<galacticraftcore:basic_item:11>);
recipes.remove(<galacticraftcore:basic_item:12>);
recipes.remove(<galacticraftcore:basic_item:13>);
recipes.remove(<galacticraftcore:basic_item:14>);

// basic_block_core: 6 copper block, 7 tin block, 8 aluminium block, 9 solid meteoric iron,
// 10 silicon block. (0/1 are the tin decoration/wall blocks, which are decorative and stay.)
recipes.remove(<galacticraftcore:basic_block_core:6>);
recipes.remove(<galacticraftcore:basic_block_core:7>);
recipes.remove(<galacticraftcore:basic_block_core:8>);
recipes.remove(<galacticraftcore:basic_block_core:9>);
recipes.remove(<galacticraftcore:basic_block_core:10>);

// Two more duplicate blocks the first pass missed. Both share their ore dictionary name with a
// GregTech block that is listed *first* there (blockAluminium -> gregtech:meta_block_compressed_0:1,
// blockSilicon -> ...:3:13), so every recipe written against those names already uses GregTech's
// block and only Galacticraft's own copy was still craftable from nine ingots:
//   11 aluminium block, 13 silicon block.
recipes.remove(<galacticraftcore:basic_block_core:11>);
recipes.remove(<galacticraftcore:basic_block_core:13>);

// And the two planet-metal ingots that were still obtainable by cutting a storage block back down.
// Both are duplicates - ingotTitanium lists GregTech's ingot first, ingotDesh likewise - and
// GregTech unpacks its own blocks in the compressor, so these only ever produced a second copy of a
// metal the player already has:
//   galacticraftplanets:item_basic_mars:2       desh ingot, from <ore:blockDesh>
//   galacticraftplanets:item_basic_asteroids:0  titanium ingot, from <ore:blockTitanium>
//   galacticraftplanets:basic_item_venus:1      lead ingot, from <ore:blockLead>
recipes.remove(<galacticraftplanets:item_basic_mars:2>);
recipes.remove(<galacticraftplanets:item_basic_asteroids:0>);
recipes.remove(<galacticraftplanets:basic_item_venus:1>);

// item_basic_moon: 0 meteoric iron ingot, 1 compressed meteoric iron, 2 lunar sapphire.
// The metal is GregTech's now (minespace:meteoric_iron), the sapphire is a gem.
recipes.remove(<galacticraftcore:item_basic_moon:0>);
recipes.remove(<galacticraftcore:item_basic_moon:1>);

// Storage blocks of the planet metals. GregTech makes its own blocks for both materials, so
// these are GregTech's items now (blockDesh / blockTitanium in the ore dictionary).
recipes.remove(<galacticraftplanets:mars:8>);            // block of desh
recipes.remove(<galacticraftplanets:asteroids_block:7>); // titanium block
recipes.remove(<galacticraftplanets:venus:12>);          // lead block

// --------------------------------------------------- wafers, now engraved out of GregTech's wafers
//
// Galacticraft's wafers were made by its Circuit Fabricator (removed above). The first version of
// this pack rebuilt them in GregTech's *assembler* from raw material - 2 silicon ingots plus 4
// circuits per wafer - which worked, but it put the mod's wafer beside GregTech's wafer line
// instead of on top of it: a Galacticraft wafer shared nothing with a GregTech wafer.
//
// GregTech's own ladder, read out of its machine recipes on a server run (`MinespaceWaferProbe`
// dumped every recipe that makes or eats each GregTech wafer), is
//
//     Silicon Boule            --cutting saw-->  16x Silicon Wafer
//     Glowstone-doped Boule    (2484K)        -->  32x Glowstone-doped Wafer
//     Naquadah-doped Boule     (5400K)        -->  64x Naquadah-doped Wafer
//     <any of those wafers>    --laser engraver + gem lens-->  Integrated Circuit Wafer, CPU Wafer,
//                                                              RAM / NAND / NOR / PIC / SoC Wafer, ...
//
// so the mod wafers now come off that same machine, one rung per mod tier, and the GregTech wafer
// is the input rather than the material behind it. Three details are deliberate:
//
//   * The **lens is `notConsumable`**, exactly as in GregTech's own engraving recipes: it is the
//     lithography mask, so it must be in the machine but is not spent. The lenses below are the ore
//     dictionary entries GregTech passes for its own wafers - lensGarnetRed (Integrated Circuit),
//     lensCubicZirconia (CPU), lensGreenSapphire (glowstone tier), lensSapphire (Power IC),
//     lensTopaz (naquadah tier) - so nothing new has to exist for these recipes.
//   * The **count is 2**. GregTech's silicon wafer is 1/16 of a boule and a boule is 32 silicon
//     dust, so one wafer carries 2 ingots of silicon: two of them is what the old assembler recipe
//     spent, and the recipe stays *on* the GregTech chain (boule, cutting saw, engraver) instead of
//     shortcutting it. Nothing here is cheaper than the shape it replaces.
//   * The **three engraving tiers are GregTech's own** - 120 EU/t for silicon, 480 EU/t for
//     glowstone, 1920 EU/t for naquadah - so every Galacticraft wafer lands in a laser engraver
//     tier the GregTech chain already has a use for.
//
// Item ids, all from the same probe: 32441 glowstone-doped wafer, 32442 naquadah-doped wafer,
// 32463 Integrated Circuit Wafer, 32464 CPU Wafer.

// Blue Solar Wafer - the photovoltaic substrate. GregTech's glowstone-doped wafer *is* silicon
// doped for light, so the mod's blue solar wafer is that wafer, engraved. (It had no source at all
// before this: the Circuit Fabricator that made it was removed and nothing replaced it, which left
// Galacticraft's Basic and Full Solar Panel items uncraftable.)
mods.gregtech.recipe.RecipeMap.getByName("laser_engraver").recipeBuilder()
    .inputs(<gregtech:meta_item_2:32441> * 2)
    .notConsumable(<ore:lensGreenSapphire>)
    .outputs(<galacticraftcore:basic_item:12>)
    .duration(500).EUt(480)
    .buildAndRegister();

// Basic Wafer - GregTech's Integrated Circuit Wafer, the LV logic wafer.
mods.gregtech.recipe.RecipeMap.getByName("laser_engraver").recipeBuilder()
    .inputs(<gregtech:meta_item_2:32463> * 2)
    .notConsumable(<ore:lensGarnetRed>)
    .outputs(<galacticraftcore:basic_item:13>)
    .duration(900).EUt(120)
    .buildAndRegister();

// Advanced Wafer - GregTech's CPU Wafer, the MV logic wafer (engraved from the glowstone-doped
// substrate, so the whole rung is MV).
mods.gregtech.recipe.RecipeMap.getByName("laser_engraver").recipeBuilder()
    .inputs(<gregtech:meta_item_2:32464> * 2)
    .notConsumable(<ore:lensCubicZirconia>)
    .outputs(<galacticraftcore:basic_item:14>)
    .duration(500).EUt(480)
    .buildAndRegister();

// Solar Array Wafer (Galacticraft-Planets) - the Venus rung of the same solar line, so the
// naquadah-doped substrate, one tier above the blue solar wafer's glowstone. The pack removed
// Galacticraft's solar *generators* long ago and nothing consumes the advanced solar panel item,
// so this is the last rung of a decorative line, not a power source.
mods.gregtech.recipe.RecipeMap.getByName("laser_engraver").recipeBuilder()
    .inputs(<gregtech:meta_item_2:32442> * 2)
    .notConsumable(<ore:lensTopaz>)
    .outputs(<galacticraftplanets:basic_item_venus:6>)
    .duration(200).EUt(1920)
    .buildAndRegister();

// --------------------------------------------------------------- keeping Galacticraft alive
// Left craftable on purpose, because deleting these breaks the mod rather than gregging it:
//
//   * Life support: Oxygen Collector / Compressor / Distributor / Sealer / Detector /
//     Storage Module, oxygen gear and tanks. Nothing in GregTech produces a breathable
//     atmosphere, and a Moon without oxygen is a dead Moon.
//   * Rocket logistics: Fuel Loader, Cargo Loader/Unloader, Launch Controller, Landing Pad,
//     Rocket Workbench, Parachest, buggy. These move a player and a rocket, they are not
//     material processing.
//   * Power *distribution* inside Galacticraft: aluminium wire, fluid pipes, fluid tanks,
//     air locks, space station parts.
//
// Galacticraft machines run on gJ but accept **Forge Energy** as an input, and GTCEu has the
// "Energy Converter" (EU -> FE) metatileentity, so once the Coal Generator and the solar
// panels are gone, power comes from GregTech: run GT power into an Energy Converter and put
// it against a Galacticraft aluminium wire. That was read out of both jars (GC's
// TileBaseUniversalElectrical$ForgeReceiver + energy.cfg "Disable INPUT of Forge Energy to
// GC machines" = false, and gregtech's MetaTileEntityConverter / EUToFEProvider); it still
// needs a play test in game, which cannot be done headless.
//
// Direction matters here, and Galacticraft's energy block goes both ways:
//
//   * GC machine wanting power  <- GT: energy.cfg "Disable INPUT of Forge Energy to GC
//     machines" = false, and GTCEu's converter does EU -> FE.
//   * GC generator into GT       <- also technically possible: energy.cfg "Disable OUTPUT of
//     Forge Energy from GC machines" = false (GC's TileBaseUniversalElectricalSource has a
//     ForgeEmitter), and gregtech's MetaTileEntityConverter has setFeToEu(true) (soft mallet
//     toggles it). So Galacticraft's generators *could* feed GregTech through one converter.
//
// They are removed anyway, by design: this pack generates power with GregTech machines only.
// Keep that in mind if a later change wants Galacticraft generation back - it is a one line
// revert per block in this file, not a dead end.
//
// ---------------------------------------------------------------------------------------
// The fluids those removed machines produced now come out of GregTech (recipes in the
// "Fluids" section of gc_gregify_processing.zs): crude oil -> rocket fuel in a distillery,
// breathable oxygen from the air in a gas collector.
//
// The fluid names had to be checked at runtime first, because Galacticraft falls back to
// "oilgc" / "fuelgc" when another mod already owns "oil" / "fuel" (config: useOldOilFluidID /
// useOldFuelFluidID), and GregTech registers a lot of fluids. A server run reported:
//
//   registered:     fuel, oil, oxygen, hydrogen, methane, liquid_oxygen, sulfuric_acid,
//                   bacterial_sludge
//   not registered: fuelgc, oilgc, methanegc, liquid_nitrogen, liquid_argon
//
// so Galacticraft owns the plain names and the GregTech recipes point straight at them.
// Steam line: if a later Galacticraft version moves to "fuelgc"/"oilgc", the two recipes in
// gc_gregify_processing.zs are the only place that has to change.

// --------------------------------------------------------------------------- JEI hygiene
// Removing a crafting recipe does not remove the machine from JEI, and Galacticraft's *machine*
// recipes are not crafting-table recipes at all: the compressed plates are a Java list the
// compressor reads (and JEI renders). That list is cleared by the addon
// (MinespaceGalacticraftMachineRecipes, called from postInit), which is also what makes an
// electric compressor from an old world stop working.
//
// What is left for the scripts is the display side: the categories whose machines are gone, and
// the machine items themselves. The ids below are Galacticraft's own JEI category uids, read
// out of its JEI classes.
mods.jei.JEI.hideCategory("galacticraft.ingotcompressor");  // Compressor / Electric / Advanced
mods.jei.JEI.hideCategory("galacticraft.circuits");         // Circuit Fabricator
mods.jei.JEI.hideCategory("galacticraft.refinery");         // Refinery
mods.jei.JEI.hideCategory("galacticraft.gas_liquefier");    // Mars gas chain
mods.jei.JEI.hideCategory("galacticraft.methaneSynthesizer"); // Mars gas chain - note the
                                                              // capital S: the id is not
                                                              // "galacticraft.methane" and
                                                              // hiding an unknown id throws
                                                              // "Unknown recipe category"
mods.jei.JEI.hideCategory("galacticraft.oxygencompressor"); // replaced by the GT machine
mods.jei.JEI.hideCategory("galacticraft.astroMiner");       // Astro Miner Base - see below

// The machines themselves, so they do not show up as obtainable items either.
//
// Only the stacks below are hidden, and that list is not a guess: JEI reports every stack it
// does not know with "Could not find any matching ingredients to remove", so the entries that
// produced that message were left out. Galacticraft does not expose all of its machine metas
// to JEI (machine 1/2/3/7/8, machine2 5/10, machine4 11, solar 1, oxygen_compressor 1 and
// mars_machine_t2 5/6 are not in JEI's ingredient list at all, so there is nothing to hide).
mods.jei.JEI.hide(<galacticraftcore:machine:0>);   // Coal Generator
mods.jei.JEI.hide(<galacticraftcore:machine2:0>);  // Electric Compressor
mods.jei.JEI.hide(<galacticraftcore:solar:0>);     // Basic Solar Panel
mods.jei.JEI.hide(<galacticraftcore:refinery>);
mods.jei.JEI.hide(<galacticraftcore:collector>);          // Oxygen Collector
mods.jei.JEI.hide(<galacticraftcore:oxygen_compressor:0>); // replaced by the GT machine
mods.jei.JEI.hide(<galacticraftcore:fuel_loader>);         // replaced by the GT machine
mods.jei.JEI.hide(<galacticraftplanets:solar_array_controller>);
mods.jei.JEI.hide(<galacticraftplanets:solar_array_module>);
mods.jei.JEI.hide(<galacticraftplanets:geothermal_generator>);
mods.jei.JEI.hide(<galacticraftplanets:beam_receiver>);
mods.jei.JEI.hide(<galacticraftplanets:mars_machine_t2:0>); // Gas Liquefier

// Added 2026-10-14, the two entries of GC-GREGFICATION-PLAN.md's "Still to do" table that were
// already decided rather than left open:
//
//   * **Astro Miner Base** (`miner_base` and its `miner_base_full` twin, the docked state):
//     "GregTech's ore/fluid drilling plants replace the job". Galacticraft's miner parks a mining
//     vehicle on an asteroid and rocks up with ore; a GregTech Mining Drill (or Fluid Rig) does the
//     same work inside this pack's chain, and the base's own recipes were the last Galacticraft
//     machine production this pack still fed by hand (`gaps.zs` rebuilt its grid, `hightech.zs`
//     rebuilt it again as an assembler recipe). Both rebuilds are gone with it.
//   * **Chromatic Applicator** (`machine3:0` - the plan's table said `:9`, which is the index its
//     lang file happens to use, but the metadata Galacticraft actually registers is 0: a probe on
//     2026-10-14 printed every `machine3` meta and the dye recipe in `hightech.zs` is on 0): it
//     paints a colour onto space glass. It is the plan's "Cosmetic; delete" row, approved by the
//     owner with "继续" on 2026-10-14. Nothing consumes it.
recipes.remove(<galacticraftplanets:miner_base>);
recipes.remove(<galacticraftcore:machine3:0>);
mods.jei.JEI.hide(<galacticraftplanets:miner_base>);      // Astro Miner Base
mods.jei.JEI.hide(<galacticraftcore:machine3:0>);         // Chromatic Applicator

// The first two rows of the "decide" set, taken on 2026-10-14 as part of the same sweep (section
// 6ci). Both are the plan's "no GregTech equivalent" cases where the answer is still delete, and the
// reason is the company they keep:
//
//   * **Energy Beam Reflector** (`beam_reflector:0`): a reflector only redirects the solar array's
//     energy beams. Its whole network - the Solar Array Controller, the Solar Array Module and the
//     Energy Beam Receiver - was removed earlier, and the pack had already rebuilt the reflector's
//     recipe in `assembler_2.zs`; that rebuild is gone with it.
//   * **Laser Turret** (`laser_turret`): "can target meteors, players, and mobs". A combat toy with
//     no place in the material chain. It is already uncraftable in this stack - a probe on
//     2026-10-14 found neither a crafting recipe nor any consumer - so this line only stops it
//     showing up as an obtainable item.
recipes.remove(<galacticraftplanets:beam_reflector>);
recipes.remove(<galacticraftplanets:laser_turret>);
mods.jei.JEI.hide(<galacticraftplanets:beam_reflector>);  // Energy Beam Reflector
mods.jei.JEI.hide(<galacticraftplanets:laser_turret>);    // Laser Turret

// ------------------------------------------------- the asteroid shards' smelting lane
// GregTech's own shard lane (`OreDictionaryLoader` -> `OreRecipeHandler.processMetalSmelting`) writes
// "one shard -> one ingot" furnace recipes for every `shardX` ore name it finds, and Galacticraft is
// the only thing in the pack that fills two of them: the **Iron Shard** and the **Titanium Shard**
// (`galacticraftplanets:item_basic_asteroids:3` / `:4`), which its asteroid rock drops
// (`BlockBasicAsteroids.getDrops` builds exactly those two stacks). So the lane handed out iron and
// titanium ingots from a mod item that never went through GregTech's chain - a source outside the
// material unification for two of the pack's metals.
//
// The iron lane exists and goes; the titanium one turns out never to have been written - the log says
// "1 recipes removed for: <minecraft:iron_ingot>" and "0 recipes removed for: <ore:ingotTitanium>",
// which is also why a progression probe over the crafting registry, every GregTech recipe map and
// vanilla smelting had flagged the Iron Shard but not the Titanium Shard: the iron recipe was their
// only consumer in the whole pack. The second call is written anyway, so that a future GregTech or
// Galacticraft update cannot quietly put the lane back. The two shards are hidden as well; they still
// drop from asteroid rock - that is the block's own behaviour, not a recipe - but nothing uses them.
furnace.remove(<minecraft:iron_ingot>, <ore:shardIron>);
furnace.remove(<ore:ingotTitanium>, <ore:shardTitanium>);
mods.jei.JEI.hide(<galacticraftplanets:item_basic_asteroids:3>);  // Iron Shard
mods.jei.JEI.hide(<galacticraftplanets:item_basic_asteroids:4>);  // Titanium Shard
