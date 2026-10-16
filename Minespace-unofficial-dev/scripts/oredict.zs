#priority 900
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Separate Galacticraft / Galaxy Space's "compressed" plates from GregTech's plain plates.
//
// The problem this fixes: Galacticraft registers its *compressed* copper / tin / steel / bronze /
// iron plate under the plain ore dictionary names (`plateCopper`, `plateTin`, ...) as well as under
// its own `compressedX` names, and Galaxy Space does the same with its cobalt / nickel plates. That
// leaves each of those names holding two very different items:
//
//     plateCopper -> [galacticraftcore:basic_item:6 (compressed, 2 GregTech plates + TNT),
//                     gregtech:meta_item_1:12018 (one plain plate)]
//
// so a recipe written as `<ore:plateCopper>` accepted either of them, and one could not tell a
// two-plate compressed plate from a single plain one. That cuts both ways: a GregTech machine could
// be built from a compressed plate (wasteful), and - the real problem - a Galacticraft / Galaxy
// Space recipe that was meant to need the compressed plate could be satisfied with one cheap plain
// plate, skipping the implosion compressor entirely.
//
// The fix is to take the mods' plates back out of the shared names, so `plateX` means GregTech's
// plate and nothing else. Galacticraft's own recipes already ask for `compressedX` (its own name),
// which is untouched - and Galaxy Space's recipes that asked for the generic name are rebuilt
// against the compressed plate they always meant, in the "Galaxy Space machines that must keep the
// compressed plates" section of gs_gregify_removals.zs. That last part is the important half: taking
// the compressed plate out of the name on its own would have let those machines be built from one
// plain GregTech plate instead of the compressed one, which would have been a discount. As it
// stands every affected recipe costs exactly what it did, and only the ambiguity is gone.
//
// This file must load *first* (the `aa_` prefix). CraftTweaker turns `<ore:...>` into a concrete
// ingredient when it applies a recipe action, in script order, so the dictionary has to be corrected
// before any of the pack's own recipes are built - otherwise those recipes would keep the old,
// ambiguous ingredient list. (Mod-registered recipes use Forge's lazy `OreIngredient`, which reads
// the dictionary on first use, so they pick the change up too.)
//
// This comment used to say that the names holding an *unobtainable* duplicate - Galacticraft's
// ingots, whose crafting recipes gc_removals.zs deletes, and the GC/GS dusts - were deliberately
// left alone because they are a display wart rather than an exploit. A client-side sweep of every
// shared name on 2026-10-14 (section 6ce) shows that they were closed in the passes since: fifteen
// names still hold both a GregTech (or this pack's) item and a mod's, and every one of them is a
// family the pack keeps on purpose - the nine `oreX` names where a planet's ore block is the same
// tier as GregTech's, the wood family (`logWood`, `plankWood`, `treeSapling`, `treeLeaves`), AE2's
// certus quartz, and Ender IO's lapis dust as a blue dye. No name is left with a *processed*
// duplicate (an ingot, a dust, a plate), which is what this file is for.

oreDict.get("plateCopper").remove(<galacticraftcore:basic_item:6>);
oreDict.get("plateTin").remove(<galacticraftcore:basic_item:7>);
oreDict.get("plateSteel").remove(<galacticraftcore:basic_item:9>);
oreDict.get("plateBronze").remove(<galacticraftcore:basic_item:10>);
oreDict.get("plateIron").remove(<galacticraftcore:basic_item:11>);
oreDict.get("plateTitanium").remove(<galacticraftplanets:item_basic_asteroids:6>);
oreDict.get("plateDesh").remove(<galacticraftplanets:item_basic_mars:5>);
oreDict.get("plateCobalt").remove(<galaxyspace:compressed_plates:1>);
oreDict.get("plateNickel").remove(<galaxyspace:compressed_plates:3>);

// The last two of the family, added 2026-10-14. GregTech owns neither name - it has no coal plate
// and no magnesium plate at all - so these two do not move to a GregTech item the way the eight
// above do: they simply end up **empty**, and the two items become reachable only as
// `galaxyspace:compressed_plates:0` / `:2`, which is what they always were. The three recipes that
// read the names are rebuilt by item id in the same commit (`gs_removals.zs` for Galaxy Space's two
// decorative blocks, and the Ender IO one below). See the long note further down for why this was
// left alone until now.
oreDict.get("plateCoal").remove(<galaxyspace:compressed_plates:0>);
oreDict.get("plateMagnesium").remove(<galaxyspace:compressed_plates:2>);

// -------------------------------------------------------------------------------------------
// Gears: the same surgery, and the same reason as the plates.
//
// Gregicality writes its plate *and* gear recipes through `OreDictUnifier.get(prefix, material)`,
// which answers with the first stack in the name - so as long as Forestry's copper / tin / bronze
// gear and the AE2 / Ender IO wooden gears were first in `gearCopper`, `gearTin`, `gearBronze` and
// `gearWood`, GregTech's own gear items had **no source at all** (a live probe on 2026-10-13: 0
// producers for `gregtech:meta_item_2:26018 / 26071 / 26095 / 26196`, against four for
// `gearIron`), and the machines were making the mod's gear instead. Taking the mods' copies out of
// the names hands them to GregTech, `MinespaceMaterialRepoint` re-points everything that produced
// or consumed the mod copies (both are measured, not assumed: every consumer of these four names is
// written against the *ore name*, so the swap breaks nothing), the gear entries in that table are
// what makes the re-point cover gears too, and `gear_bridge.zs` puts GregTech's own crafting lanes
// back.
//
// What is *not* here: Ender IO's five gears (`gearStone`, `gearIronInfinity`, `gearEnergized`,
// `gearVibrant`, `gearDark`). Those are single-material parts of Ender IO's own tree - its "bimetal"
// gears are an iron/construction-alloy core coated in an alloy's nuggets - GregTech has no gear for
// those materials, so there is nothing to hand the names to; they stay Ender IO's, made in GT
// machines (see assembler_1.zs).
oreDict.get("gearCopper").remove(<forestry:gear_copper:0>);
oreDict.get("gearTin").remove(<forestry:gear_tin:0>);
oreDict.get("gearBronze").remove(<forestry:gear_bronze:0>);
oreDict.get("gearWood").remove(<appliedenergistics2:material:40>);
oreDict.get("gearWood").remove(<enderio:item_material:9>);

// -------------------------------------------------------------------------------------------
// Ores and the mods' storage blocks: the same surgery again, and the rule for which names get it.
//
// The rule, worked out from a live sweep of every ore dictionary name holding both a GregTech item
// and another mod's item (2026-10-13, `MinespaceOreSweepProbe`): a mod item leaves the name when it
// is **unobtainable** - then the name has no business answering with it, and handing it to GregTech
// is pure cleanup. A mod item that is still *obtained* and is the *same material* stays (the pack's
// older note: "an ingot is an ingot"), and Forestry's own material stays because Forestry is the
// owner's exception. That leaves exactly three names alone, listed at the bottom.
//
// Why the Galacticraft and Galaxy Space ore blocks are unobtainable, measured rather than assumed:
// their own config switches are all off (`GalaxySpace/world.conf`: enableOresGeneration=false,
// enableOverworldOres=false, enableMarsNewOres=false; `Galacticraft/planets.cfg` and the Moon
// section of `core.cfg`: every "Disable X Ore Gen" true), the only thing that ever produced the
// blocks was their own ore generation, and a probe of the crafting registry, every GregTech map and
// vanilla smelting finds **zero** producers for each of them. Forestry's copper and tin ore blocks
// were the last live duplicate in the world - its `common.cfg` had copper=true and tin=true while
// GregTech's own ores are the ones this pack generates - so those two were switched off in the same
// pass (apatite stays: Forestry's own material). The Forestry **storage** blocks are in the list for
// the other half of the same reason: their only producer is the Gregicality compressor lane that
// this pack is re-pointing at GregTech's compressed block (`block_compress_copper` and friends were
// written against `forestry:resource_storage:1` because Forestry's block is first in `blockCopper`).
//
// What the swap does *not* touch: GregTech's own ore processing. Its macerator / chemical bath /
// forge hammer lanes take an ore-name ingredient listing all 34 `oreCopper` entries, so they keep
// working on every block; the per-block vanilla smelting entries (mod ore block -> GregTech ingot)
// are deleted by `MinespaceMaterialRepoint.pruneDeadSmelting`, which removes a furnace recipe whose
// input the pack has handed to GregTech.

// ---- ores: the Galacticraft / Galaxy Space blocks, and Forestry's copper and tin ore
oreDict.get("oreCopper").remove(<forestry:resources:1>);
oreDict.get("oreCopper").remove(<galacticraftcore:basic_block_core:5>);
oreDict.get("oreCopper").remove(<galacticraftcore:basic_block_moon:0>);
oreDict.get("oreCopper").remove(<galaxyspace:ioblocks:3>);
oreDict.get("oreCopper").remove(<galaxyspace:barnarda_c_ores:7>);
oreDict.get("oreCopper").remove(<galaxyspace:proxima_b_blocks:7>);
oreDict.get("oreCopper").remove(<galacticraftplanets:mars:0>);
oreDict.get("oreCopper").remove(<galacticraftplanets:venus:7>);
oreDict.get("oreTin").remove(<forestry:resources:2>);
oreDict.get("oreTin").remove(<galacticraftcore:basic_block_core:6>);
oreDict.get("oreTin").remove(<galacticraftcore:basic_block_moon:1>);
oreDict.get("oreTin").remove(<galaxyspace:barnarda_c_ores:8>);
oreDict.get("oreTin").remove(<galaxyspace:proxima_b_blocks:6>);
oreDict.get("oreTin").remove(<galacticraftplanets:mars:1>);
oreDict.get("oreTin").remove(<galacticraftplanets:venus:11>);
oreDict.get("oreAluminium").remove(<galacticraftcore:basic_block_core:7>);
oreDict.get("oreAluminium").remove(<galacticraftplanets:asteroids_block:3>);
oreDict.get("oreAluminium").remove(<galacticraftplanets:venus:6>);
oreDict.get("oreDesh").remove(<galaxyspace:phobosblocks:5>);
oreDict.get("oreDesh").remove(<galacticraftplanets:mars:2>);
oreDict.get("oreNickel").remove(<galaxyspace:mercuryblocks:3>);
oreDict.get("oreNickel").remove(<galaxyspace:gsores:1>);
oreDict.get("oreNickel").remove(<galaxyspace:phobosblocks:4>);
oreDict.get("oreNickel").remove(<galaxyspace:mirandablocks:8>);
oreDict.get("oreNickel").remove(<galaxyspace:barnarda_c_ores:12>);
oreDict.get("oreCobalt").remove(<galaxyspace:gsores:0>);
oreDict.get("oreCobalt").remove(<galaxyspace:mirandablocks:7>);
oreDict.get("oreCobalt").remove(<galaxyspace:barnarda_c_ores:11>);
oreDict.get("oreDolomite").remove(<galaxyspace:ceresblocks:2>);
oreDict.get("oreDolomite").remove(<galaxyspace:mirandablocks:4>);
oreDict.get("oreIlmenite").remove(<galaxyspace:ganymedeblocks:3>);
oreDict.get("oreIlmenite").remove(<galacticraftplanets:asteroids_block:4>);
oreDict.get("oreSapphire").remove(<galaxyspace:titanblocks:3>);
oreDict.get("oreSulfur").remove(<galaxyspace:ioblocks:4>);
oreDict.get("oreUranium").remove(<galaxyspace:gsores:2>);

// ---- blocks: Forestry's storage blocks for GregTech's metals (and charcoal), not its own apatite
oreDict.get("blockCopper").remove(<forestry:resource_storage:1>);
oreDict.get("blockTin").remove(<forestry:resource_storage:2>);
oreDict.get("blockBronze").remove(<forestry:resource_storage:3>);
oreDict.get("blockCharcoal").remove(<forestry:charcoal:0>);

// Apatite and certus quartz: the last two, and the owner's rule for them is that **GregTech must have
// the vein**. It does, and it is GregTech's own ore block that the vein places, not the mod's - the
// vein files `config/gregtech/worldgen/overworld/apatite_vein.json` (weight 60, radius 13, 60%
// `ore:apatite`) and `moon|certus_quartz_vein.json` / `overworld/quartz_vein.json` are GregTech's own
// assets, and `OreConfigUtils.getOreStateMap("ore:<material>")` resolves that notation through
// `getOreForMaterial`, i.e. `MetaBlocks.ORES` - GregTech's blocks - never through the ore dictionary
// (that is the separate `ore_dict:` notation, which these veins do not use). The planets get them too:
// `MinespacePlanetOreGen` drives GregTech's veins on the Galacticraft bodies, and the certus vein's
// `dimension_filter` covers the Moon and the fourteen Galaxy Space bodies.
//
// So the mods' copies are duplicates of a source that exists, exactly like Forestry's copper and tin
// ore, and they leave the names here:
//   * `gemApatite` / `oreApatite` / `blockApatite` - Forestry's apatite ore also stops generating
//     (`common.cfg`: apatite=false); GregTech's apatite chain is ore -> dust (2226) -> gem (8226) ->
//     flawed (23226) -> flawless (24226), and `MinespaceMaterialRepoint` re-points the lanes whose
//     outputs Gregicality had written against Forestry's gem, so a GregTech apatite vein now yields
//     GregTech's apatite. Forestry's machines ask for `<ore:gemApatite>`, which answers with
//     GregTech's gem - same material, so its fertiliser chain is untouched.
//   * `oreCertusQuartz` - AE2's quartz ore comes from its meteorites, which stay (they are the sky
//     stone the whole AE2 line is built from); it simply is no longer the answer the *name* gives.
//     `oreChargedCertusQuartz` is left alone - that name holds only AE2's charged ore and GregTech has
//     no charged certus ore at all.
oreDict.get("oreApatite").remove(<forestry:resources:0>);
oreDict.get("gemApatite").remove(<forestry:apatite:0>);
oreDict.get("blockApatite").remove(<forestry:resource_storage:0>);
oreDict.get("oreCertusQuartz").remove(<appliedenergistics2:quartz_ore:0>);
oreDict.get("oreCertusQuartz").remove(<appliedenergistics2:charged_quartz_ore:0>);

// -------------------------------------------------------------------------------------------
// The rest of the leftovers, sorted by whether the mod's copy can still be obtained at all.
// A probe walked every ore dictionary name holding both a GregTech item and a Galacticraft /
// Galaxy Space item and asked, for the mod's item, whether any surviving crafting or furnace
// recipe produces it. Two outcomes, and they are treated differently:
//
//   * **The mod's copy has no source at all.** These are pure leftovers - nothing a player can
//     hold - so taking them out of the name only stops JEI offering a choice that cannot be made.
//     Galacticraft's copper / tin / aluminium / silicon blocks and the planet-metal blocks, and
//     Galacticraft's titanium dust, are in this group: their crafting recipes were deleted
//     earlier and nothing else makes them.
//
//   * **The mod's copy is obtainable and is the same material.** Galacticraft's copper, tin,
//     aluminium, meteoric-iron, desh, lead and titanium ingots (smelted from the mod's own ores, or
//     in the desh and lead case converted one-to-one from GregTech's ingot), Galaxy Space's cobalt,
//     magnesium and nickel ingots (smelted from its ores) and the sulphur / aluminium dusts are all
//     in this group. They are *deliberately left in place*: an ingot is an ingot and a dust is a
//     dust, so a recipe written as `<ore:ingotCopper>` taking either is correct rather than a
//     discount, and several of those entries are what Gregicality's own ore-processing recipes
//     hand out - removing them would leave those recipes producing an item nothing can use.
//
// (Galacticraft's `blockAluminum` with one `i` and `plateAluminum` are the mod's own US spelling
// and GregTech registers the British `Aluminium` spellings, so those names never shared anything.)
oreDict.get("blockCopper").remove(<galacticraftcore:basic_block_core:9>);
oreDict.get("blockTin").remove(<galacticraftcore:basic_block_core:10>);
oreDict.get("blockAluminium").remove(<galacticraftcore:basic_block_core:11>);
oreDict.get("blockSilicon").remove(<galacticraftcore:basic_block_core:13>);
oreDict.get("blockTitanium").remove(<galacticraftplanets:asteroids_block:7>);
oreDict.get("blockDesh").remove(<galacticraftplanets:mars:8>);
oreDict.get("blockLead").remove(<galacticraftplanets:venus:12>);
oreDict.get("dustTitanium").remove(<galacticraftplanets:item_basic_asteroids:9>);

// -------------------------------------------------------------------------------------------
// Unifying the ingots and the dusts on GregTech.
//
// Other mods register their own copper / tin / bronze ingots, their own powders and their own
// quartz, coal, iron and gold dusts under the same ore dictionary names GregTech uses, so a recipe
// written as `<ore:ingotCopper>` or `<ore:dustIron>` could be fed with either. The pack owner asked
// for the GregTech product to be *the* one everywhere, so every ingot / dust name that holds both a
// GregTech item and another mod's item is cut down to the GregTech item:
//
//   Forestry's copper / tin / bronze ingots          -> ingotCopper / ingotTin / ingotBronze
//   Ender IO's copper / tin / coal / lapis /
//     obsidian / cobalt powders                      -> the matching dust names
//   AE2's certus, nether quartz, ender pearl,
//     iron, gold and wheat dusts                     -> the matching dust names
//   Galacticraft's and Galaxy Space's remaining
//     ingots and dusts                               -> as above
//
// Nothing is deleted: the mods' items stay obtainable (their own recipes are untouched) and a recipe
// that names one of them by its exact id still works - what changes is that a *generic* ore
// dictionary reference now means GregTech. Two consequences, both intended:
//
//   * A mod whose own ore processing produced one of those items (Gregicality's dust recipes handed
//     out Galacticraft's aluminium dust, for instance) keeps producing that item, but `<ore:...>`
//     recipes no longer accept it. It is still the same material, just not the unified one.
//   * Anything that used to be fed with the mod's copy now needs GregTech's, which for a powder
//     means GregTech's macerator rather than the other mod's own grinding. That is the point of the
//     unification, not an accident.
//
// Names holding only GregTech plus vanilla Minecraft (`ingotIron`, `dustRedstone`, `dustGlowstone`,
// ...) are left alone: vanilla's item *is* the GregTech item in those cases.
oreDict.get("ingotCopper").remove(<forestry:ingot_copper:0>);
oreDict.get("ingotCopper").remove(<galacticraftcore:basic_item:3>);
oreDict.get("ingotTin").remove(<forestry:ingot_tin:0>);
oreDict.get("ingotTin").remove(<galacticraftcore:basic_item:4>);
oreDict.get("ingotBronze").remove(<forestry:ingot_bronze:0>);
oreDict.get("ingotAluminum").remove(<galacticraftcore:basic_item:5>);
oreDict.get("ingotMeteoricIron").remove(<galacticraftcore:item_basic_moon:0>);
oreDict.get("ingotDesh").remove(<galacticraftplanets:item_basic_mars:2>);
oreDict.get("ingotTitanium").remove(<galacticraftplanets:item_basic_asteroids:0>);
oreDict.get("ingotLead").remove(<galacticraftplanets:basic_item_venus:1>);
oreDict.get("ingotCobalt").remove(<galaxyspace:ingots:0>);
oreDict.get("ingotMagnesium").remove(<galaxyspace:ingots:1>);
oreDict.get("ingotNickel").remove(<galaxyspace:ingots:2>);

oreDict.get("dustCopper").remove(<enderio:item_material:26>);
oreDict.get("dustTin").remove(<enderio:item_material:27>);
oreDict.get("dustIron").remove(<appliedenergistics2:material:49>);
oreDict.get("dustIron").remove(<enderio:item_material:24>);
oreDict.get("dustGold").remove(<appliedenergistics2:material:51>);
oreDict.get("dustGold").remove(<enderio:item_material:25>);
oreDict.get("dustCoal").remove(<enderio:item_material:23>);

// Ender IO's "powdered coal" (`item_material:23`) - the mod's spelling of a coal dust, and one of the
// duplicates this file already takes out of `dustCoal` above.
//
// One of its five crafting recipes reads the generic name `<ore:plateCoal>`, "any coal plate", and
// until 2026-10-14 the only member of that name was Galaxy Space's *compressed* coal plate (nine coal
// through GregTech's compressor). That pairing is an accident of two mods sharing a name rather than
// a design, and it is the one recipe the name cleanup above would have left holding an empty
// ingredient. It goes - together with its four siblings, and that is the interesting part: CraftTweaker's
// `recipes.remove(output, ingredient)` does **not** filter by ingredient (the ingredient list it
// accepts narrows nothing here; the version written against `<ore:plateCoal>` behaved the same way
// once the name was empty), so the only lever it gives is "remove every recipe with this output".
// Rather than leave the item with no source at all, the pack adds the bridge it uses everywhere else
// for a mod's copy of a material GregTech owns: one GregTech coal dust in, one powdered coal out.
// That keeps the item reachable for anything that addresses it by id - Ender IO's own recipe files
// (config/enderio/recipes, checked: no machine recipe of theirs consumes it) and any other mod -
// while the material itself still originates in GregTech's chain, and it cannot be run backwards
// because the name `dustCoal` no longer holds Ender IO's item.
recipes.remove(<enderio:item_material:23>);
recipes.addShapeless(<enderio:item_material:23>, [<ore:dustCoal>]);
oreDict.get("dustLapis").remove(<enderio:item_material:32>);
oreDict.get("dustObsidian").remove(<enderio:item_material:29>);
oreDict.get("dustCobalt").remove(<enderio:item_material:31>);
oreDict.get("dustCertusQuartz").remove(<appliedenergistics2:material:2>);
oreDict.get("dustNetherQuartz").remove(<appliedenergistics2:material:3>);
oreDict.get("dustNetherQuartz").remove(<enderio:item_material:33>);
oreDict.get("dustEnderPearl").remove(<appliedenergistics2:material:46>);
oreDict.get("dustWheat").remove(<appliedenergistics2:material:4>);
oreDict.get("dustWheat").remove(<enderio:item_material:21>);
oreDict.get("dustAsh").remove(<forestry:ash:0>);
oreDict.get("dustAluminium").remove(<galacticraftcore:ic2compat:0>);
oreDict.get("dustSulfur").remove(<galaxyspace:gs_basic:7>);

// ------------------------------------------------ Ender IO's ten alloys, unified onto GregTech
// The owner's call, 2026-10-12: Ender IO's own materials are expanded into GregTech materials -
// the ingot, its molten fluid, the dust and the nugget, and nothing else. `MinespaceMaterials`
// registers them in GT (an `IngotMaterial` with only `SMELT_INTO_FLUID` set gives exactly that set),
// so GregTech's ingot and nugget now land in the same ore names as Ender IO's items.
//
// The pack's rule is that the GregTech item wins the shared name, so Ender IO's ingot and nugget come
// out of `ingotX` / `nuggetX` here - before any script resolves a recipe against those names. Ender
// IO's items keep their ids (its own blocks, grinding balls and machines still refer to them by id),
// they simply stop answering to the shared ore dictionary name. `MinespaceMaterialRepoint` then
// re-points the machine outputs and the crafting-table inputs that used to hand out the mod's copy.
//
// The *block* forms are deliberately left alone: the owner asked for ingot, fluid, dust and nugget,
// and blocks are the one form GregTech builds along with the ingot whether one wants it or not.
oreDict.get("ingotDarkSteel").remove(<enderio:item_alloy_ingot:6>);
oreDict.get("ingotElectricalSteel").remove(<enderio:item_alloy_ingot:0>);
oreDict.get("ingotEnergeticAlloy").remove(<enderio:item_alloy_ingot:1>);
oreDict.get("ingotVibrantAlloy").remove(<enderio:item_alloy_ingot:2>);
oreDict.get("ingotRedstoneAlloy").remove(<enderio:item_alloy_ingot:3>);
oreDict.get("ingotConductiveIron").remove(<enderio:item_alloy_ingot:4>);
oreDict.get("ingotPulsatingIron").remove(<enderio:item_alloy_ingot:5>);
oreDict.get("ingotSoularium").remove(<enderio:item_alloy_ingot:7>);
oreDict.get("ingotEndSteel").remove(<enderio:item_alloy_ingot:8>);
oreDict.get("ingotConstructionAlloy").remove(<enderio:item_alloy_ingot:9>);

oreDict.get("nuggetDarkSteel").remove(<enderio:item_alloy_nugget:6>);
oreDict.get("nuggetElectricalSteel").remove(<enderio:item_alloy_nugget:0>);
oreDict.get("nuggetEnergeticAlloy").remove(<enderio:item_alloy_nugget:1>);
oreDict.get("nuggetVibrantAlloy").remove(<enderio:item_alloy_nugget:2>);
oreDict.get("nuggetRedstoneAlloy").remove(<enderio:item_alloy_nugget:3>);
oreDict.get("nuggetConductiveIron").remove(<enderio:item_alloy_nugget:4>);
oreDict.get("nuggetPulsatingIron").remove(<enderio:item_alloy_nugget:5>);
oreDict.get("nuggetSoularium").remove(<enderio:item_alloy_nugget:7>);
oreDict.get("nuggetEndSteel").remove(<enderio:item_alloy_nugget:8>);
oreDict.get("nuggetConstructionAlloy").remove(<enderio:item_alloy_nugget:9>);

// The dust side of the same ten, for the one alloy where Ender IO actually ships a powder item.
// `dustSoularium` held Ender IO's own powder *first* and GregTech's dust second, so Ender IO's SAG
// Mill - and anything else that resolves the name to its first member - was handing out the mod's
// powder rather than the pack's. Taking the mod's powder out of the name makes the ten alloys behave
// alike: `dustSoularium` is GregTech's, and scripts/eio_materials.zs gives GregTech the ingot -> dust
// step the mill used to perform (see the pack plan, section 6az). The other nine never had a mod
// powder item to remove.
oreDict.get("dustSoularium").remove(<enderio:item_material:74>);

// The same treatment for Ender IO's seven "endergy" alloys, which became GregTech materials on
// 2026-10-13 (see the pack plan, section 6ba). Their ingot and nugget are the two forms the owner
// asked to move; the block and the grinding ball stay the mod's own items, exactly as for the ten
// alloys above.
oreDict.get("ingotCrudeSteel").remove(<enderio:item_alloy_endergy_ingot:0>);
oreDict.get("ingotCrystallineAlloy").remove(<enderio:item_alloy_endergy_ingot:1>);
oreDict.get("ingotMelodicAlloy").remove(<enderio:item_alloy_endergy_ingot:2>);
oreDict.get("ingotStellarAlloy").remove(<enderio:item_alloy_endergy_ingot:3>);
oreDict.get("ingotCrystallinePinkSlime").remove(<enderio:item_alloy_endergy_ingot:4>);
oreDict.get("ingotEnergeticSilver").remove(<enderio:item_alloy_endergy_ingot:5>);
oreDict.get("ingotVividAlloy").remove(<enderio:item_alloy_endergy_ingot:6>);

oreDict.get("nuggetCrudeSteel").remove(<enderio:item_alloy_endergy_nugget:0>);
oreDict.get("nuggetCrystallineAlloy").remove(<enderio:item_alloy_endergy_nugget:1>);
oreDict.get("nuggetMelodicAlloy").remove(<enderio:item_alloy_endergy_nugget:2>);
oreDict.get("nuggetStellarAlloy").remove(<enderio:item_alloy_endergy_nugget:3>);
oreDict.get("nuggetCrystallinePinkSlime").remove(<enderio:item_alloy_endergy_nugget:4>);
oreDict.get("nuggetEnergeticSilver").remove(<enderio:item_alloy_endergy_nugget:5>);
oreDict.get("nuggetVividAlloy").remove(<enderio:item_alloy_endergy_nugget:6>);

// Enderium Base is a metal ingot too, just not one of the two alloy families: it is the Thermal
// Foundation intermediate on Enderium's way, and Ender IO's `alloying_modded.xml` entry for it was
// switched off in section 6az. `MinespaceMaterials.ENDER_IO_OTHER_INGOTS` registers it as a GregTech
// material and `scripts/integration.zs` ports that entry to GregTech's mixer, so the name now answers
// with GregTech's ingot.
oreDict.get("ingotEnderiumBase").remove(<enderio:item_material:39>);

// -------------------------------------------------------- Ender IO's alloy blocks (the other half)
// The owner's call, 2026-10-13: the block names follow the ingots. Every `blockX` name used to hold
// Ender IO's block *first* and GregTech's compressed block second, which meant two things: a recipe
// that resolved the name got the mod's block, and Gregicality's own machine recipes - its fluid
// solidifier casting forms and the compressor's nine-ingots-into-a-block - were built against it, so
// GregTech machines were handing out a mod block. Taking the mod's block out of the name makes the
// name answer with GregTech's block, and `MinespaceMaterialRepoint` (which gained the same seventeen
// pairs) re-points those machine recipes and every machine recipe that *fed on* the mod's block.
//
// The mod's block items stay in the game: Ender IO's own recipes that name them by id keep working,
// the input re-point turns them into GregTech's block, and `jei_dupes.zs` hides the now producer-less
// items so JEI does not show the same block twice. Ender IO's grinding *balls* are a different case
// and are deliberately left alone - that is the mod's own consumable, made from its own nuggets.
oreDict.get("blockDarkSteel").remove(<enderio:block_alloy:6>);
oreDict.get("blockElectricalSteel").remove(<enderio:block_alloy:0>);
oreDict.get("blockEnergeticAlloy").remove(<enderio:block_alloy:1>);
oreDict.get("blockVibrantAlloy").remove(<enderio:block_alloy:2>);
oreDict.get("blockRedstoneAlloy").remove(<enderio:block_alloy:3>);
oreDict.get("blockConductiveIron").remove(<enderio:block_alloy:4>);
oreDict.get("blockPulsatingIron").remove(<enderio:block_alloy:5>);
oreDict.get("blockSoularium").remove(<enderio:block_alloy:7>);
oreDict.get("blockEndSteel").remove(<enderio:block_alloy:8>);
oreDict.get("blockConstructionAlloy").remove(<enderio:block_alloy:9>);
oreDict.get("blockCrudeSteel").remove(<enderio:block_alloy_endergy:0>);
oreDict.get("blockCrystallineAlloy").remove(<enderio:block_alloy_endergy:1>);
oreDict.get("blockMelodicAlloy").remove(<enderio:block_alloy_endergy:2>);
oreDict.get("blockStellarAlloy").remove(<enderio:block_alloy_endergy:3>);
oreDict.get("blockCrystallinePinkSlime").remove(<enderio:block_alloy_endergy:4>);
oreDict.get("blockEnergeticSilver").remove(<enderio:block_alloy_endergy:5>);
oreDict.get("blockVividAlloy").remove(<enderio:block_alloy_endergy:6>);

// Ender IO's three organic dye items. `dyeBlack`, `dyeBrown` and `dyeGreen` hold GregTech's own dye
// dusts as well, and the pack's rule is that the GregTech item is the one a shared name answers with -
// so the mod's three come out here and their alloy smelter recipes are switched off in
// config/enderio/recipes/user/user_recipes.xml (the `Alloy: <colour> Dye` family, the same rule the
// Red Dye entry follows). `MinespaceMaterialRepoint` gains the three pairs so any machine output that
// used to hand one out hands out GregTech's dust, and `jei_dupes.zs` hides the three orphaned items.
oreDict.get("dyeBlack").remove(<enderio:item_material:50>);
oreDict.get("dyeBrown").remove(<enderio:item_material:49>);
oreDict.get("dyeGreen").remove(<enderio:item_material:48>);

// ----------------------------------------------------------- AE2's identity tag for certus quartz
// AE2's own recipes do not name `crystalCertusQuartz`; they use an item tag (`certusCrystal`) that
// accepts three crystals - the plain one (material:0), the charged one (material:1) and the pure,
// grown one (material:10). Only the plain crystal is registered under `crystalCertusQuartz` itself,
// and the storage components and the ME cores have been rewritten against that ore name, so a player
// whose only certus quartz is the pure crystal the growth chamber produces could not make them at
// all. Putting the two crystals AE2 itself accepted into the ore name restores exactly the tag the
// mod used, and it restores it for every recipe on that name rather than for these two fixes alone.
// Nothing is removed here: this only widens a name back to what AE2 meant by it.
oreDict.get("crystalCertusQuartz").add(<appliedenergistics2:material:1>);
oreDict.get("crystalCertusQuartz").add(<appliedenergistics2:material:10>);

// ... and one more crystal, added 2026-10-13 (TJ-MIGRATION-PLAN.md 6bo): GregTech's own certus
// quartz gem. GregTech's certus quartz is a material like any other - it has a vein on the Moon, Mars,
// Venus and the Galaxy Space bodies (`config/gregtech/worldgen/*/certus_quartz_vein.json`, plus a
// quarter of the overworld's quartz vein), an ore, a crushed line, a dust (`2202`) and a gem
// (`gregtech:meta_item_1:8202`, what the autoclave makes out of the dust) - and AE2's recipes need
// AE2's *crystal*, so without this a player who mined GregTech's ore had material nothing would take.
// Appended rather than prepended, so AE2's plain crystal stays the first entry, which is what AE2's
// own code expects. Recipes that ask `<ore:crystalCertusQuartz>` - the pack's AE2 tools, the grindstone
// and the storage rewrites - now take either material. The recipes and machines that address AE2's
// crystal by *item id* (the pack's own AE2 assembler recipes for the energy cell, the view cell and
// the processors, and AE2's charger and inscriber) are covered by the 1:1 bridges in `gaps.zs`, one
// crystal for one gem and back.
oreDict.get("crystalCertusQuartz").add(<gregtech:meta_item_1:8202>);

// ------------------------------------------------------------------ the aluminium spelling gap
// GregTech registers the British spellings - `plateAluminium`, `blockAluminium` - and Galacticraft
// registers its compressed aluminium under the American ones. Up to here the two never met, so
// nothing was removed and nothing was unified: `<ore:plateAluminum>` was a name that *looked* like a
// plate slot but held only Galacticraft's compressed plate (two GregTech plates plus TNT), while
// `<ore:plateAluminium>` held one plain GregTech plate. Same metal, two names, two different costs.
//
// Galacticraft's own recipes never use the bare name - `gc_gregify_crafting.zs` rebuilds them against
// `<ore:compressedAluminum>`, and Galacticraft itself registers its plate under that name too - so the
// bare name is free to become the GregTech spelling's alias. That is what the four lines below do:
// the mod's compressed item leaves the bare name (it keeps `compressedAluminum`), and the GregTech
// item takes its place. Nothing is deleted and no recipe changes cost: the item a recipe can reach
// through `plateAluminum` / `blockAluminum` is now the same one it reaches through the British
// spelling, which is the whole point of unifying on GregTech.
oreDict.get("plateAluminum").remove(<galacticraftcore:basic_item:8>);
oreDict.get("plateAluminum").add(<gregtech:meta_item_1:12001>);
oreDict.get("blockAluminum").remove(<galacticraftcore:basic_block_core:11>);
oreDict.get("blockAluminum").add(<gregtech:meta_block_compressed_0:1>);

// The same gap in the dust names, and it is the same metal again: Galacticraft registers its aluminium
// dust under the American `dustAluminum` as well as the British `dustAluminium`, and the ingot half of
// this was already cut down to GregTech in the section above (`ingotAluminum`). Leaving the dust alone
// would leave `<ore:dustAluminum>` pointing at Galacticraft's dust and `<ore:dustAluminium>` at
// GregTech's, which is exactly the split the owner asked to close - "other mods' ingots and dusts come
// out of the shared names". The mod's dust keeps its own identity and stays craftable by id; only the
// shared name moves to GregTech.
oreDict.get("dustAluminum").remove(<galacticraftcore:ic2compat:0>);
oreDict.get("dustAluminum").add(<gregtech:meta_item_1:2001>);

// Galaxy Space's `plateCoal` and `plateMagnesium` were left alone for a year of this migration and
// are cleaned up now - the reasoning, because it changed rather than being missed:
//
//   * GregTech has no coal plate and no magnesium plate (it stops at ingot / dust / block for
//     magnesium), so there is no GregTech item to unify those two names onto. Unlike the eight
//     plates above, these two names therefore end up **empty**; Galaxy Space's compressed coal /
//     magnesium plate is reachable as `galaxyspace:compressed_plates:0` / `:2` and nowhere else.
//   * That is the point. The other fourteen plates were fixed because a *compressed* plate (two
//     GregTech plates and TNT) sitting under a *plain* `plateX` name let it satisfy a requirement
//     written for a plain plate. These two had the same shape, and the live dump of every recipe
//     that reads their items (2026-10-14) found exactly what it costs: Ender IO's "any coal plate"
//     powdering recipe was eating Galaxy Space's compressed coal plate, and Galaxy Space's own two
//     decorative blocks are built against the magnesium one. So the names go empty, the two
//     decorative blocks are rebuilt by item id in `gs_removals.zs`, and the Ender IO recipe is
//     dropped just below.
//   * GregTech's own plate lanes are *not* affected either way. They were generated from the ore
//     dictionary when Galaxy Space registered the entries, and they hold the item, not the name:
//     macerating a compressed coal plate still gives a coal dust, and arc-furnacing a compressed
//     magnesium plate still gives a magnesium ingot. Both routes are lossy round trips through
//     GregTech machinery, so neither is a shortcut, and both are left as they are.

// ------------------------------------------------------------------------------- silicon
// Three mods ship their own silicon and all three put it under the *same* shared name: Galacticraft's
// raw silicon, Ender IO's and Applied Energistics' silicon are the three members of `itemSilicon`.
// GregTech's silicon is a different material spelling family - `ingotSilicon`, `dustSilicon`,
// `plateSilicon` - so the shared name held three foreign items and no GregTech one, and because the
// first member wins, Galacticraft's own silicon recipes (its config literally points them at the name
// `itemSilicon`) and AE2's printed-silicon recipe were consuming whichever mod's lump came first.
//
// The owner's call, 2026-10-12: the three mods' silicon is discarded outright, and so is the crafting
// that made it. The items come out of the shared name and GregTech's silicon ingot goes in, so every
// recipe that names `itemSilicon` now consumes GregTech's silicon - Galacticraft's own, Ender IO's
// XML recipes (which resolve the name at their postInit, after this file) and AE2's inscriber. The
// three items are hidden from JEI as well, because nothing in the pack refers to them any more.
oreDict.get("itemSilicon").remove(<appliedenergistics2:material:5>);
oreDict.get("itemSilicon").remove(<galacticraftcore:basic_item:2>);
oreDict.get("itemSilicon").remove(<enderio:item_material:5>);
oreDict.get("itemSilicon").add(<gregtech:meta_item_1:10061>);

mods.jei.JEI.hide(<appliedenergistics2:material:5>);
mods.jei.JEI.hide(<galacticraftcore:basic_item:2>);
mods.jei.JEI.hide(<enderio:item_material:5>);
