#priority 793
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// ==================================================== power: RF and EU are equivalent at every tier
//
// Owner's rule (2026-10-17): RF and GregTech EU are two units for the same energy. The exchange is
// bidirectional at every voltage tier, with the same 4 FE = 1 EU ratio. The converter's tier only
// limits throughput (1 / 4 / 9 / 16 A); it does not decide whether a direction exists.
//
// Gregicality ships two mirrored converter families, one machine per GT tier and per amperage:
//
//   convert_gteu.<tier>.<amps>    "GTEU Energy Converter (TIER)"    EU -> FE
//   convert_forge.<tier>.<amps>   "Forge Energy Converter (TIER)"   FE -> EU
//
// Both families stay craftable at every tier. No recipe removals or JEI hides belong here. The
// converter recipes themselves already cost a tier hull, tier cables and a tier circuit.
//
// config/gtadditions.cfg keeps both disable flags false and "EU/FE Ratio" at 4.0, so the same
// exchange applies in both directions at every stage.
//
// The generator cleanup is separate from this exchange: Galacticraft's coal generator and solar
// panels, Galaxy Space's generators and energy cluster and Ender IO's generators are removed in
// gc_removals.zs / gs_removals.zs / integration.zs, and Forestry's engines are rebuilt in
// own_machines.zs. Those changes limit free power sources; they do not limit RF -> EU conversion.
