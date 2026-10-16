#priority 793
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// ==================================================== power: RF works, but only up to a point
//
// The owner's rule, settled 2026-10-12: converting RF into GregTech EU is *wanted* - it should be a
// little easier than building GregTech's own generation, because that is the point of having the
// RF mods at all - **but it must not carry a base through every voltage tier**. So this file does not
// make the exchange a bad deal; it puts a ceiling on it.
//
// Generators first, because those were the other half of "power is too easy": Galacticraft's coal
// generator and solar panels, Galaxy Space's generators and energy cluster and Ender IO's five
// generators are deleted (gc_removals.zs, gs_removals.zs, integration.zs), and Forestry's three
// engines - the last non-GregTech generators in the pack - were rebuilt in own_machines.zs's
// neighbourhood at MV 128 EU/t (HV 480 for the fuel-free clockwork one) out of GregTech steel /
// stainless plates and circuits. Cheap fuel, real machine.
//
// Then the exchange. Gregicality ships two mirrored converter families, one machine per GT tier and
// per amperage size (1 / 4 / 9 / 16 A):
//
//   convert_gteu.<tier>.<amps>    "GTEU Energy Converter (TIER)"    EU -> FE   (GregTech feeds the mods)
//   convert_forge.<tier>.<amps>   "Forge Energy Converter (TIER)"   FE -> EU   (the mods feed GregTech)
//
// **Which family is which was measured, not read off the names - see TJ-MIGRATION-PLAN.md 6cl.**
// The names are written from the *input* side and they read backwards: the machine called "GTEU
// Energy Converter" is the one that *takes* GregTech EU and puts out FE, and hovering it in game says
// so ("Converts GTEU to FE" - `gtadditions.converter.description` is filled with the machine's own
// input and output). In the jar that is `EnergyConverterType.CONVERT_GTEU` with `isGTEU = true`:
// `ConverterType.getInput(true)` is `Energy.GTEU`, `getOutput(true)` is `Energy.FE`, the traits it
// builds are `TraitGTEUIn` + `TraitFEOut`, and the ratio it applies is 1 EU in for 4 FE out. The
// registration loop in `GATileEntities` puts the GTEU member of each (tier, amperage) pair *first*,
// so in every pair the lower id is the EU -> FE machine and the higher id is the FE -> EU one.
//
// The first version of this file had that the other way round, which put the ceiling on the wrong
// family: it removed the EU -> FE machines from EV up (so at EV and above GregTech power could no
// longer be spent on a Forestry / Ender IO / Galacticraft / Galaxy Space / AE2 machine at all) and
// left the FE -> EU machines craftable at *every* tier (so an RF-driven base could still be carried
// through every voltage tier - exactly what the rule above forbids). The two statements below are the
// corrected ones.
//
// EU -> FE stays complete at every tier: it is GregTech power being spent on the mods' machines, and
// FE cannot come back by itself. Nothing below touches those ids.
//
// FE -> EU is kept for **ULV, LV, MV and HV** and removed from **EV upwards**, by removing the
// crafting recipe of each `Forge Energy Converter` of that tier and hiding the item from JEI. That is
// the ceiling: an RF-driven base is a perfectly good way to run the early and middle tiers - slightly
// easier than GregTech's own generation, which is the point - and it stops being an option at EV,
// where the player has to have built real GregTech power.
//
// The converter itself is not the cheap part and was left alone: a probe read the recipes straight out
// of the registry and each one is a machine hull of its own tier plus eight tier cables plus that
// tier's circuit (EV 1A = `gregtech:machine:504`, 8x `cableGtSingleAluminium`, `circuitExtreme`), so
// the FE -> EU machines already cost real industry at every tier they exist in.
//
// config/gtadditions.cfg: "Disable GregTech EU to FE Energy Converters?" was switched from true to
// false - as shipped, the *safe* direction was the disabled one and the arbitrage direction was the
// enabled one. "EU/FE Ratio" stays 4.0, the same ballpark as GT New Horizons' published 1 EU = 3.6 RF,
// i.e. the exchange is deliberately not punitive. Those two booleans are read by Gregicality's
// `EnergyConverterType.isDisabled()` (`disableEUtoFEConverter` gates the GTEU/EU->FE family,
// `disableFEtoEUConverter` the Forge/FE->EU family - the same mapping as the directions above), and
// they gate whether a converter *works*, not whether it is registered. Both are false now.
//
// These are ordinary CraftingManager recipes, so recipes.remove is enough (unlike Ender IO's XML
// recipes, which are registered after CraftTweaker has run and need the mod's own disabled flag).
// CraftTweaker applies these removals in its own postInit, i.e. after Gregicality has registered the
// recipes - a script that reads the crafting registry while the scripts are still loading sees them
// all still present, which is what the first version of the 6cl probe stumbled over.
//
// To move the ceiling, move these lines: keeping a tier means deleting its block, stopping a tier
// earlier means adding one.

// --- EV and up: no FE to EU conversion from here on (the `convert_forge` machine of each pair)
recipes.remove(<gregtech:machine:2933>);   // Forge Energy Converter (EV) 1A
recipes.remove(<gregtech:machine:2935>);   // Forge Energy Converter (EV) 4A
recipes.remove(<gregtech:machine:2937>);   // Forge Energy Converter (EV) 9A
recipes.remove(<gregtech:machine:2939>);   // Forge Energy Converter (EV) 16A

recipes.remove(<gregtech:machine:2941>);   // Forge Energy Converter (IV) 1A
recipes.remove(<gregtech:machine:2943>);   // Forge Energy Converter (IV) 4A
recipes.remove(<gregtech:machine:2945>);   // Forge Energy Converter (IV) 9A
recipes.remove(<gregtech:machine:2947>);   // Forge Energy Converter (IV) 16A

recipes.remove(<gregtech:machine:2949>);   // Forge Energy Converter (LuV) 1A
recipes.remove(<gregtech:machine:2951>);   // Forge Energy Converter (LuV) 4A
recipes.remove(<gregtech:machine:2953>);   // Forge Energy Converter (LuV) 9A
recipes.remove(<gregtech:machine:2955>);   // Forge Energy Converter (LuV) 16A

recipes.remove(<gregtech:machine:2957>);   // Forge Energy Converter (ZPM) 1A
recipes.remove(<gregtech:machine:2959>);   // Forge Energy Converter (ZPM) 4A
recipes.remove(<gregtech:machine:2961>);   // Forge Energy Converter (ZPM) 9A
recipes.remove(<gregtech:machine:2963>);   // Forge Energy Converter (ZPM) 16A

recipes.remove(<gregtech:machine:2965>);   // Forge Energy Converter (UV) 1A
recipes.remove(<gregtech:machine:2967>);   // Forge Energy Converter (UV) 4A
recipes.remove(<gregtech:machine:2969>);   // Forge Energy Converter (UV) 9A
recipes.remove(<gregtech:machine:2971>);   // Forge Energy Converter (UV) 16A

// The UHV-and-up block is registered by a second loop that skips the pairs it cannot register, so these
// tiers carry fewer sizes than the nine below them: UHV and UEV four each, UIV three, UMV two, and UXV
// only its 4 A and 16 A machines (ids 4101..4104, measured 2026-10-15 - the first version of this file
// missed the UXV pair entirely, because the old list stopped at 4099).
recipes.remove(<gregtech:machine:4076>);   // Forge Energy Converter (UHV) 1A
recipes.remove(<gregtech:machine:4078>);   // Forge Energy Converter (UHV) 4A
recipes.remove(<gregtech:machine:4080>);   // Forge Energy Converter (UHV) 9A
recipes.remove(<gregtech:machine:4082>);   // Forge Energy Converter (UHV) 16A

recipes.remove(<gregtech:machine:4084>);   // Forge Energy Converter (UEV) 1A
recipes.remove(<gregtech:machine:4086>);   // Forge Energy Converter (UEV) 4A
recipes.remove(<gregtech:machine:4088>);   // Forge Energy Converter (UEV) 9A
recipes.remove(<gregtech:machine:4090>);   // Forge Energy Converter (UEV) 16A

recipes.remove(<gregtech:machine:4092>);   // Forge Energy Converter (UIV) 1A
recipes.remove(<gregtech:machine:4094>);   // Forge Energy Converter (UIV) 4A
recipes.remove(<gregtech:machine:4096>);   // Forge Energy Converter (UIV) 9A

recipes.remove(<gregtech:machine:4098>);   // Forge Energy Converter (UMV) 1A
recipes.remove(<gregtech:machine:4100>);   // Forge Energy Converter (UMV) 16A
recipes.remove(<gregtech:machine:4102>);   // Forge Energy Converter (UXV) 4A
recipes.remove(<gregtech:machine:4104>);   // Forge Energy Converter (UXV) 16A

// Hidden as well, so JEI does not offer ten tiers of machines that cannot be built. The EU -> FE
// machines of the same tiers are deliberately *not* hidden: they are craftable and should show.
mods.jei.JEI.hide(<gregtech:machine:2933>);
mods.jei.JEI.hide(<gregtech:machine:2935>);
mods.jei.JEI.hide(<gregtech:machine:2937>);
mods.jei.JEI.hide(<gregtech:machine:2939>);
mods.jei.JEI.hide(<gregtech:machine:2941>);
mods.jei.JEI.hide(<gregtech:machine:2943>);
mods.jei.JEI.hide(<gregtech:machine:2945>);
mods.jei.JEI.hide(<gregtech:machine:2947>);
mods.jei.JEI.hide(<gregtech:machine:2949>);
mods.jei.JEI.hide(<gregtech:machine:2951>);
mods.jei.JEI.hide(<gregtech:machine:2953>);
mods.jei.JEI.hide(<gregtech:machine:2955>);
mods.jei.JEI.hide(<gregtech:machine:2957>);
mods.jei.JEI.hide(<gregtech:machine:2959>);
mods.jei.JEI.hide(<gregtech:machine:2961>);
mods.jei.JEI.hide(<gregtech:machine:2963>);
mods.jei.JEI.hide(<gregtech:machine:2965>);
mods.jei.JEI.hide(<gregtech:machine:2967>);
mods.jei.JEI.hide(<gregtech:machine:2969>);
mods.jei.JEI.hide(<gregtech:machine:2971>);
mods.jei.JEI.hide(<gregtech:machine:4076>);
mods.jei.JEI.hide(<gregtech:machine:4078>);
mods.jei.JEI.hide(<gregtech:machine:4080>);
mods.jei.JEI.hide(<gregtech:machine:4082>);
mods.jei.JEI.hide(<gregtech:machine:4084>);
mods.jei.JEI.hide(<gregtech:machine:4086>);
mods.jei.JEI.hide(<gregtech:machine:4088>);
mods.jei.JEI.hide(<gregtech:machine:4090>);
mods.jei.JEI.hide(<gregtech:machine:4092>);
mods.jei.JEI.hide(<gregtech:machine:4094>);
mods.jei.JEI.hide(<gregtech:machine:4096>);
mods.jei.JEI.hide(<gregtech:machine:4098>);
mods.jei.JEI.hide(<gregtech:machine:4100>);
mods.jei.JEI.hide(<gregtech:machine:4102>);
mods.jei.JEI.hide(<gregtech:machine:4104>);
