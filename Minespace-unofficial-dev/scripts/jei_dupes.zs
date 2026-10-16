#priority 699
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// The other half of "all materials come from GregTech": the emptied copies leave JEI.
//
// aa_minespace_oredict.zs hands every shared material name to GregTech's item and removes the mod's
// copy, and the scripts then delete the mod's own production. What was left is exactly what the owner
// saw: **the same material twice in JEI, and only one of the two with a recipe** - GregTech's copy
// is craftable, Ender IO's dark steel ingot (say) is not, and the player has no way to tell which is
// the real one.
//
// The rule applied here is precise and checkable: hide a mod item from JEI exactly when
//
//   (a) the pack removed it from a shared ore dictionary name (so GregTech's twin now answers to
//       that name), and
//   (b) nothing in the pack produces it any more
//       (checked against a full dump of the crafting registry, every GregTech recipe map and vanilla
//        smelting - the recipe audit probe described in TJ-MIGRATION-PLAN.md).
//
// Thirty-nine items qualified on the original pass. The list has grown twice since, both times for the
// same reason: Ender IO's seven "endergy" ingots and its Enderium Base ingot when those metals became
// GregTech materials (section 6ba), and its seventeen alloy blocks when the block names followed the
// ingots (section 6bc) - sixty-four in all. The items themselves stay in the game - they are still
// valid ingredients if a player has one - they simply stop cluttering JEI with a duplicate that cannot
// be made.

mods.jei.JEI.hide(<appliedenergistics2:material:5>); // was in itemSilicon
mods.jei.JEI.hide(<enderio:item_alloy_ingot:0>); // was in ingotElectricalSteel
mods.jei.JEI.hide(<enderio:item_alloy_ingot:1>); // was in ingotEnergeticAlloy
mods.jei.JEI.hide(<enderio:item_alloy_ingot:2>); // was in ingotVibrantAlloy
mods.jei.JEI.hide(<enderio:item_alloy_ingot:3>); // was in ingotRedstoneAlloy
mods.jei.JEI.hide(<enderio:item_alloy_ingot:4>); // was in ingotConductiveIron
mods.jei.JEI.hide(<enderio:item_alloy_ingot:5>); // was in ingotPulsatingIron
mods.jei.JEI.hide(<enderio:item_alloy_ingot:6>); // was in ingotDarkSteel
mods.jei.JEI.hide(<enderio:item_alloy_ingot:7>); // was in ingotSoularium
mods.jei.JEI.hide(<enderio:item_alloy_ingot:8>); // was in ingotEndSteel
mods.jei.JEI.hide(<enderio:item_alloy_ingot:9>); // was in ingotConstructionAlloy
mods.jei.JEI.hide(<enderio:item_material:21>); // was in dustWheat
mods.jei.JEI.hide(<enderio:item_material:24>); // was in dustIron
mods.jei.JEI.hide(<enderio:item_material:25>); // was in dustGold
mods.jei.JEI.hide(<enderio:item_material:26>); // was in dustCopper
mods.jei.JEI.hide(<enderio:item_material:27>); // was in dustTin
mods.jei.JEI.hide(<enderio:item_material:31>); // was in dustCobalt
mods.jei.JEI.hide(<enderio:item_material:33>); // was in dustNetherQuartz
mods.jei.JEI.hide(<enderio:item_material:5>); // was in itemSilicon
mods.jei.JEI.hide(<forestry:ingot_bronze:0>); // was in ingotBronze
mods.jei.JEI.hide(<forestry:ingot_copper:0>); // was in ingotCopper
mods.jei.JEI.hide(<forestry:ingot_tin:0>); // was in ingotTin
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:10>); // was in blockTin
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:11>); // was in blockAluminium
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:13>); // was in blockSilicon
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:9>); // was in blockCopper
mods.jei.JEI.hide(<galacticraftcore:basic_item:2>); // was in itemSilicon
mods.jei.JEI.hide(<galacticraftcore:basic_item:3>); // was in ingotCopper
mods.jei.JEI.hide(<galacticraftcore:basic_item:4>); // was in ingotTin
mods.jei.JEI.hide(<galacticraftcore:basic_item:5>); // was in ingotAluminum
mods.jei.JEI.hide(<galacticraftcore:item_basic_moon:0>); // was in ingotMeteoricIron
mods.jei.JEI.hide(<galacticraftplanets:asteroids_block:7>); // was in blockTitanium
mods.jei.JEI.hide(<galacticraftplanets:item_basic_asteroids:0>); // was in ingotTitanium
mods.jei.JEI.hide(<galacticraftplanets:item_basic_asteroids:9>); // was in dustTitanium
mods.jei.JEI.hide(<galacticraftplanets:mars:8>); // was in blockDesh
mods.jei.JEI.hide(<galacticraftplanets:venus:12>); // was in blockLead
mods.jei.JEI.hide(<galaxyspace:ingots:0>); // was in ingotCobalt
mods.jei.JEI.hide(<galaxyspace:ingots:1>); // was in ingotMagnesium
mods.jei.JEI.hide(<galaxyspace:ingots:2>); // was in ingotNickel

// 2026-10-13: Ender IO's seven "endergy" ingots and its Enderium Base ingot joined the list when
// section 6ba registered those metals on GregTech's side. Nothing produces these eight any more (the
// pack's own block / nugget conversions were rebuilt against GregTech's ingot, and the alloys have no
// production recipe in the mod at all), so they meet both halves of the rule above. The mod's nugget,
// block and grinding-ball items are deliberately *not* hidden: the nuggets and blocks still have
// producers, and Ender IO's grinding balls are made from its own nuggets.
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:0>); // was in ingotCrudeSteel
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:1>); // was in ingotCrystallineAlloy
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:2>); // was in ingotMelodicAlloy
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:3>); // was in ingotStellarAlloy
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:4>); // was in ingotCrystallinePinkSlime
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:5>); // was in ingotEnergeticSilver
mods.jei.JEI.hide(<enderio:item_alloy_endergy_ingot:6>); // was in ingotVividAlloy
mods.jei.JEI.hide(<enderio:item_material:39>);           // was in ingotEnderiumBase

// Four more the reachability audit found on its first run (TJ-MIGRATION-PLAN.md 6bh): Ender IO's three
// organic dyes, which left `dyeBlack` / `dyeBrown` / `dyeGreen` when GregTech's own dye dusts took those
// names over, and its wooden gear, which sits in `gearWood` beside AE2's and GregTech's and whose four
// five-stick recipes were already switched off by 6y - so nothing has produced the mod's copy since.
// All four are out of a shared name and produced by nothing, which is exactly the rule above.
mods.jei.JEI.hide(<enderio:item_material:48>); // organic green dye, was in dyeGreen
mods.jei.JEI.hide(<enderio:item_material:49>); // organic brown dye, was in dyeBrown
mods.jei.JEI.hide(<enderio:item_material:50>); // organic black dye, was in dyeBlack
mods.jei.JEI.hide(<enderio:item_material:9>);  // wooden gear, is in gearWood beside AE2's and GT's

// The same day, the other half: the block names follow the ingots. Ender IO's alloy blocks left
// `blockX` (GregTech's compressed block is what those names answer with now), which leaves the mod's
// seventeen block items with no producer - their crafting-table conversions are gone and every machine
// output that used to make them was re-pointed at GregTech's block - so they meet both halves of the
// rule above as well. Ender IO's grinding *balls* stay visible: those are cast from the mod's own
// nuggets by the mod's own recipes.
mods.jei.JEI.hide(<enderio:block_alloy:0>); // was in blockElectricalSteel
mods.jei.JEI.hide(<enderio:block_alloy:1>); // was in blockEnergeticAlloy
mods.jei.JEI.hide(<enderio:block_alloy:2>); // was in blockVibrantAlloy
mods.jei.JEI.hide(<enderio:block_alloy:3>); // was in blockRedstoneAlloy
mods.jei.JEI.hide(<enderio:block_alloy:4>); // was in blockConductiveIron
mods.jei.JEI.hide(<enderio:block_alloy:5>); // was in blockPulsatingIron
mods.jei.JEI.hide(<enderio:block_alloy:6>); // was in blockDarkSteel
mods.jei.JEI.hide(<enderio:block_alloy:7>); // was in blockSoularium
mods.jei.JEI.hide(<enderio:block_alloy:8>); // was in blockEndSteel
mods.jei.JEI.hide(<enderio:block_alloy:9>); // was in blockConstructionAlloy
mods.jei.JEI.hide(<enderio:block_alloy_endergy:0>); // was in blockCrudeSteel
mods.jei.JEI.hide(<enderio:block_alloy_endergy:1>); // was in blockCrystallineAlloy
mods.jei.JEI.hide(<enderio:block_alloy_endergy:2>); // was in blockMelodicAlloy
mods.jei.JEI.hide(<enderio:block_alloy_endergy:3>); // was in blockStellarAlloy
mods.jei.JEI.hide(<enderio:block_alloy_endergy:4>); // was in blockCrystallinePinkSlime
mods.jei.JEI.hide(<enderio:block_alloy_endergy:5>); // was in blockEnergeticSilver
mods.jei.JEI.hide(<enderio:block_alloy_endergy:6>); // was in blockVividAlloy

// ... and the seventeen nuggets, which joined the list the same day. Their only producer used to be
// Ender IO's `1 ingot -> 9 nuggets` table recipe (doubled by Gregicality's `nugget_disassembling_*`),
// kept because the mod's grinding balls were thought to be cast from them - but the ball recipes the mod
// actually ships are the crafting-table ones, five **ingots** into twenty-four balls, so the nuggets have
// no consumer at all. `scripts/eio_materials.zs` removes the producers and the items meet both halves of
// the rule above (out of a shared name, produced by nothing). TJ-MIGRATION-PLAN.md 6bh.
mods.jei.JEI.hide(<enderio:item_alloy_nugget:0>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:1>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:2>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:3>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:4>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:5>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:6>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:7>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:8>);
mods.jei.JEI.hide(<enderio:item_alloy_nugget:9>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:0>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:1>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:2>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:3>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:4>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:5>);
mods.jei.JEI.hide(<enderio:item_alloy_endergy_nugget:6>);

// Gears, the same rule a step further (TJ-MIGRATION-PLAN.md 6bk): `gearCopper` / `gearTin` /
// `gearBronze` answered with **Forestry's** gear and `gearWood` with **AE2's**, so GregTech's own gear
// items had no producer and the machines were making the mod's copies. `oredict.zs` now hands those
// four names to GregTech and `gear_bridge.zs` + `ae2_base.zs` write GregTech's crafting lanes, which
// leaves the mod copies out of a shared name and produced by nothing - the two halves of this file's
// rule. Ender IO's wooden gear above is the same item as AE2's, hidden for the same reason.
mods.jei.JEI.hide(<forestry:gear_copper:0>);
mods.jei.JEI.hide(<forestry:gear_tin:0>);
mods.jei.JEI.hide(<forestry:gear_bronze:0>);
mods.jei.JEI.hide(<appliedenergistics2:material:40>);

// Ores and storage blocks, 2026-10-13 (TJ-MIGRATION-PLAN.md 6bl): the Galacticraft and Galaxy Space
// ore blocks and Forestry's copper / tin ore left their `ore*` names, and Forestry's four storage
// blocks for GregTech's metals left the `block*` ones. Every one of them is unobtainable now - their
// own ore generation is switched off (GalaxySpace/world.conf and Galacticraft's own switches) or
// stopped by this pack (`config/forestry/common.cfg`: copper=false, tin=false), and their only other
// producer was the compressor lane that is re-pointed at GregTech's block - so they meet both halves
// of this file's rule. Forestry's apatite and AE2's quartz ore are deliberately *not* here: those are
// still obtained and are the same material as GregTech's.
mods.jei.JEI.hide(<forestry:resources:1>);              // Copper Ore
mods.jei.JEI.hide(<forestry:resources:2>);              // Tin Ore
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:5>);   // Copper Ore
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:6>);   // Tin Ore
mods.jei.JEI.hide(<galacticraftcore:basic_block_core:7>);   // Aluminium Ore
mods.jei.JEI.hide(<galacticraftcore:basic_block_moon:0>);   // Copper Ore
mods.jei.JEI.hide(<galacticraftcore:basic_block_moon:1>);   // Tin Ore
mods.jei.JEI.hide(<galacticraftplanets:mars:0>);            // Copper Ore
mods.jei.JEI.hide(<galacticraftplanets:mars:1>);            // Tin Ore
mods.jei.JEI.hide(<galacticraftplanets:mars:2>);            // Desh Ore
mods.jei.JEI.hide(<galacticraftplanets:venus:6>);           // Aluminium Ore
mods.jei.JEI.hide(<galacticraftplanets:venus:7>);           // Copper Ore
mods.jei.JEI.hide(<galacticraftplanets:venus:11>);          // Tin Ore
mods.jei.JEI.hide(<galacticraftplanets:asteroids_block:3>); // Aluminium Ore
mods.jei.JEI.hide(<galacticraftplanets:asteroids_block:4>); // Ilmenite Ore
mods.jei.JEI.hide(<galaxyspace:ioblocks:3>);            // Copper Ore
mods.jei.JEI.hide(<galaxyspace:ioblocks:4>);            // Sulfur Ore
mods.jei.JEI.hide(<galaxyspace:gsores:0>);              // Cobalt Ore
mods.jei.JEI.hide(<galaxyspace:gsores:1>);              // Nickel Ore
mods.jei.JEI.hide(<galaxyspace:gsores:2>);              // Uranium Ore
mods.jei.JEI.hide(<galaxyspace:mercuryblocks:3>);       // Nickel Ore
mods.jei.JEI.hide(<galaxyspace:phobosblocks:4>);        // Nickel Ore
mods.jei.JEI.hide(<galaxyspace:phobosblocks:5>);        // Desh Ore
mods.jei.JEI.hide(<galaxyspace:mirandablocks:4>);       // Dolomite Ore
mods.jei.JEI.hide(<galaxyspace:mirandablocks:7>);       // Cobalt Ore
mods.jei.JEI.hide(<galaxyspace:mirandablocks:8>);       // Nickel Ore
mods.jei.JEI.hide(<galaxyspace:ceresblocks:2>);         // Dolomite Ore
mods.jei.JEI.hide(<galaxyspace:ganymedeblocks:3>);      // Ilmenite Ore
mods.jei.JEI.hide(<galaxyspace:titanblocks:3>);         // Sapphire Ore
mods.jei.JEI.hide(<galaxyspace:barnarda_c_ores:7>);     // Copper Ore
mods.jei.JEI.hide(<galaxyspace:barnarda_c_ores:8>);     // Tin Ore
mods.jei.JEI.hide(<galaxyspace:barnarda_c_ores:11>);    // Cobalt Ore
mods.jei.JEI.hide(<galaxyspace:barnarda_c_ores:12>);    // Nickel Ore
mods.jei.JEI.hide(<galaxyspace:proxima_b_blocks:6>);    // Tin Ore
mods.jei.JEI.hide(<galaxyspace:proxima_b_blocks:7>);    // Copper Ore
mods.jei.JEI.hide(<forestry:resource_storage:1>);       // Copper Block
mods.jei.JEI.hide(<forestry:resource_storage:2>);       // Tin Block
mods.jei.JEI.hide(<forestry:resource_storage:3>);       // Bronze Block
mods.jei.JEI.hide(<forestry:charcoal:0>);               // Charcoal Block

// Apatite, the same day (TJ-MIGRATION-PLAN.md 6bn): Forestry's apatite ore generation is switched
// off and GregTech's own overworld apatite vein is the source, so the mod's ore, gem and block have no
// producer left - the two halves of this file's rule. `forestry:apatite:0` in particular was produced
// only by the Gregicality lanes that now output GregTech's apatite. AE2's quartz ore is *not* hidden
// here: it still comes out of its meteorites, it simply stopped being what `oreCertusQuartz` answers
// with.
mods.jei.JEI.hide(<forestry:resources:0>);              // Apatite Ore
mods.jei.JEI.hide(<forestry:apatite:0>);                // Apatite
mods.jei.JEI.hide(<forestry:resource_storage:0>);       // Apatite Block

// ------------------------------------------------------------------- the display-name sweep, 2026-10-14
// A client probe listed every item whose *display name* is shared with a different item (section
// 6ce). Ninety-four of those names cross a mod boundary; most are the documented-legit families -
// ore blocks (an iron ore block is an iron ore block, one per planet), the wood family, vanilla's
// dyes, AE2's quartz - and the rest were already hidden here or are handled by a rename. These ten
// are what was left, and they are the same shape as everything above: a mod copy of a material
// GregTech already ships, whose only recipe is the neutral round trip that turns it back into the
// GregTech item. Nothing in the pack consumes any of them, so they leave JEI and the GregTech item
// stays the one a player makes:
//
//   blocksmetals:0/1/2   Galaxy Space's cobalt / nickel / magnesium *blocks* - GregTech's own block
//                        of the same metal is the one to make, and its unpacker already converts
//                        the GregTech block back into nine ingots
//   nuggets:0/1/2        the matching nuggets, same story at the nugget size
//   ultimate_battery:0   the *empty* state of Galaxy Space's Ultimate Battery; the charged one is
//                        `:100` and is the item its own recipe makes
//   basic_item_venus:1   Galacticraft-Planets' lead ingot, now only reachable through the one-to-one
//                        bridge from GregTech's lead ingot (gaps.zs) and consumed by nothing
//   ic2compat:0          Galacticraft-IC2-Compat's aluminium dust, produced only by crafting it out
//                        of GregTech aluminium and consumed by nothing
//   oxygen_compressor:0  Galacticraft's own Oxygen Compressor. Its own recipe is gone with the rest
//                        of the mod's power-consuming machines, and this pack's GregTech-powered
//                        `gregtech:machine:32000` of the same name is what replaces it (section 6m) -
//                        which is also why the two of them used to share a display name.
mods.jei.JEI.hide(<galaxyspace:blocksmetals:0>);        // Cobalt Block
mods.jei.JEI.hide(<galaxyspace:blocksmetals:1>);        // Nickel Block
mods.jei.JEI.hide(<galaxyspace:blocksmetals:2>);        // Magnesium Block
mods.jei.JEI.hide(<galaxyspace:nuggets:0>);             // Cobalt Nugget
mods.jei.JEI.hide(<galaxyspace:nuggets:1>);             // Magnesium Nugget
mods.jei.JEI.hide(<galaxyspace:nuggets:2>);             // Nickel Nugget
mods.jei.JEI.hide(<galaxyspace:ultimate_battery:0>);    // Ultimate Battery (empty)
mods.jei.JEI.hide(<galacticraftplanets:basic_item_venus:1>);  // Lead Ingot
mods.jei.JEI.hide(<galacticraftcore:ic2compat:0>);            // Aluminium Dust
mods.jei.JEI.hide(<galacticraftcore:oxygen_compressor:0>);    // Oxygen Compressor (the mod's own)

// ------------------------------------------------------------------- the hand-recipe pass, 2026-10-14
// Section 6cf: Gregicality's *crafting-table* conversions ("a mortar and nine small dusts", "an ingot
// and a hammer", ...) were generated against the shared ore name and therefore produced the mod's copy
// of a material rather than GregTech's - the same bug the machine maps had, in a registry the re-point
// pass did not cover. Those recipes are now deleted, and deleting them leaves these nine items with no
// producer at all while nothing in the pack or the mods consumes them, which is exactly this file's
// rule. The three items that do still have a consumer keep their producer and stay visible (AE2's
// certus quartz and nether quartz dusts).
mods.jei.JEI.hide(<appliedenergistics2:material:49>);        // Iron Dust
mods.jei.JEI.hide(<appliedenergistics2:material:51>);        // Gold Dust
mods.jei.JEI.hide(<appliedenergistics2:material:46>);        // Ender Pearl Dust
mods.jei.JEI.hide(<enderio:item_material:23>);               // Powdered Coal
mods.jei.JEI.hide(<enderio:item_material:29>);               // Obsidian Powder
mods.jei.JEI.hide(<enderio:item_material:74>);               // Soularium Powder
mods.jei.JEI.hide(<forestry:ash:0>);                         // Ash
mods.jei.JEI.hide(<galaxyspace:gs_basic:7>);                 // Sulfur Dust
mods.jei.JEI.hide(<galacticraftplanets:item_basic_mars:2>);  // Desh Ingot (its bridge in gaps.zs is
                                                             // moot now: the recipes that asked for it
                                                             // by id ask for GregTech's ingot instead)
