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
recipes.remove(<galacticraftcore:machine2:4>);   // Electric Compressor
recipes.remove(<galacticraftcore:machine2:5>);   // Circuit Fabricator
recipes.remove(<galacticraftcore:machine2:10>);  // Deconstructor

recipes.remove(<galacticraftcore:machine4:11>);  // Advanced Compressor

// Fluid and gas processing. Each one is replaced by a GregTech recipe, see the "Fluids"
// section of gc_gregify_processing.zs:
//   Refinery            -> GT distillery (crude oil -> rocket fuel)
//   Oxygen Collector    -> GT gas collector (breathable oxygen out of the air)
//   Gas Liquefier       -> GT vacuum freezer / fluid handling
//   Methane Synthesizer -> GT chemical reactor
//   Water Electrolyzer  -> GT electrolyzer
recipes.remove(<galacticraftcore:refinery>);
recipes.remove(<galacticraftcore:collector>);          // Oxygen Collector
recipes.remove(<galacticraftplanets:mars_machine_t2:4>); // Gas Liquefier
recipes.remove(<galacticraftplanets:mars_machine_t2:5>); // Methane Synthesizer
recipes.remove(<galacticraftplanets:mars_machine_t2:6>); // Water Electrolyzer

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

// item_basic_moon: 0 meteoric iron ingot, 1 compressed meteoric iron, 2 lunar sapphire.
// The metal is GregTech's now (minespace:meteoric_iron), the sapphire is a gem.
recipes.remove(<galacticraftcore:item_basic_moon:0>);
recipes.remove(<galacticraftcore:item_basic_moon:1>);

// Storage blocks of the planet metals. GregTech makes its own blocks for both materials, so
// these are GregTech's items now (blockDesh / blockTitanium in the ore dictionary).
recipes.remove(<galacticraftplanets:mars:8>);            // block of desh
recipes.remove(<galacticraftplanets:asteroids_block:7>); // titanium block
recipes.remove(<galacticraftplanets:venus:12>);          // lead block

// --------------------------------------------------- wafers, now assembled in GregTech
// Galacticraft's wafers were made by its Circuit Fabricator (removed above). Galacticraft
// recipes that still call for a wafer - sensor glasses, display screen, telemetry - get it
// from GregTech's assembler instead, using the same shape the GT5 source used: 2 silicon plus
// 4 circuits. Two naming traps, both checked on a server run rather than assumed:
//
//   * CEu's circuit ore dictionary names are the voltage tiers (circuitLv = basic,
//     circuitMv = the next one up). GT5's circuitBasic exists as a name in CEu but its entry
//     is *empty*, so a recipe built on it would have a blank slot.
//   * <ore:itemSilicon> is **Galacticraft's** raw silicon (basic_item:2 still owns that name),
//     not GregTech's. GregTech's silicon is gregtech:meta_ingot:99 under <ore:ingotSilicon>
//     (dustSilicon and plateSilicon are the other two forms).
<recipemap:assembler>.recipeBuilder()
    .inputs(<ore:ingotSilicon> * 2, <ore:circuitLv> * 4)
    .outputs(<galacticraftcore:basic_item:13>)
    .duration(1600).EUt(8)
    .buildAndRegister();

<recipemap:assembler>.recipeBuilder()
    .inputs(<ore:ingotSilicon> * 2, <ore:circuitMv> * 4)
    .outputs(<galacticraftcore:basic_item:14>)
    .duration(3200).EUt(30)
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

// The machines themselves, so they do not show up as obtainable items either.
//
// Only the stacks below are hidden, and that list is not a guess: JEI reports every stack it
// does not know with "Could not find any matching ingredients to remove", so the entries that
// produced that message were left out. Galacticraft does not expose all of its machine metas
// to JEI (machine 1/2/3/7/8, machine2 5/10, machine4 11, solar 1, oxygen_compressor 1 and
// mars_machine_t2 5/6 are not in JEI's ingredient list at all, so there is nothing to hide).
mods.jei.JEI.hide(<galacticraftcore:machine:0>);   // Coal Generator
mods.jei.JEI.hide(<galacticraftcore:machine2:4>);  // Electric Compressor
mods.jei.JEI.hide(<galacticraftcore:solar:0>);     // Basic Solar Panel
mods.jei.JEI.hide(<galacticraftcore:refinery>);
mods.jei.JEI.hide(<galacticraftcore:collector>);          // Oxygen Collector
mods.jei.JEI.hide(<galacticraftcore:oxygen_compressor:0>); // replaced by the GT machine
mods.jei.JEI.hide(<galacticraftcore:fuel_loader>);         // replaced by the GT machine
mods.jei.JEI.hide(<galacticraftplanets:solar_array_controller>);
mods.jei.JEI.hide(<galacticraftplanets:solar_array_module>);
mods.jei.JEI.hide(<galacticraftplanets:geothermal_generator>);
mods.jei.JEI.hide(<galacticraftplanets:beam_receiver>);
mods.jei.JEI.hide(<galacticraftplanets:mars_machine_t2:4>); // Gas Liquefier
