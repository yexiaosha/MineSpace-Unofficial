#priority 798
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Gregification of the four mods this pack added on top of GregTech: Forestry, Ender IO,
// Storage Drawers and Iron Chests.
//
// Modelled on the reference pack the pack owner supplied (Mods-Get-Gregged, GT5-scripts and
// Custom-Modpack-Scripts). Those scripts are 1.7.10, so nothing here is a transliteration - the
// *method* is what is ported:
//
//   * take the mod's own crafting recipe,
//   * swap its plain metal / gem / glass / obsidian for the matching GregTech plate,
//   * put an LV integrated circuit into machines that process items,
//   * and delete the generators GregTech already provides (that is how Galacticraft and Galaxy
//     Space are treated in gc_gregify_removals.zs / gs_gregify_removals.zs).
//
// Every id below was read off a live server run, not guessed: an unknown <ore:...> does not throw
// in CraftTweaker, it silently produces a recipe with a blank slot, so a misspelled name would look
// fine in JEI while being unbuildable. Two traps the probe settled:
//
//   * plateCopper / plateTin / plateBronze / plateIron / plateSteel are registered by Galacticraft
//     *first* (they are its compressed plates), so <ore:plateIron> is Galacticraft's item. Recipes
//     that must consume real GregTech metal use the exact GregTech id instead - the numbers are the
//     ones the probe printed (plateIron 12033, plateCopper 12018, plateTin 12071, plateBronze
//     12095, plateSteel 12184).
//   * GTCE-TJ kept GT5's circuit names. circuitBasic/circuitGood/circuitAdvanced hold stacks;
//     circuitLv/circuitMv/circuitHv are registered but EMPTY.
//
// This file is named zzz_ so CraftTweaker loads it after every removal script in the pack.

// ------------------------------------------------------------------ exact GregTech parts
val PlateIron = <gregtech:meta_item_1:12033>;
val PlateCopper = <gregtech:meta_item_1:12018>;
val PlateTin = <gregtech:meta_item_1:12071>;
val PlateBronze = <gregtech:meta_item_1:12095>;
val PlateSteel = <gregtech:meta_item_1:12184>;
val PlateStainless = <gregtech:meta_item_1:12183>;
val ScrewIron = <gregtech:meta_item_1:17033>;
val ScrewCopper = <gregtech:meta_item_1:17018>;
val ScrewTin = <gregtech:meta_item_1:17071>;
val ScrewBronze = <gregtech:meta_item_1:17095>;
val ScrewSilver = <gregtech:meta_item_1:17062>;
val ScrewGold = <gregtech:meta_item_1:17026>;
val ScrewSteel = <gregtech:meta_item_1:17184>;
val CircLv = <ore:circuitBasic>;
val CircMv = <ore:circuitGood>;
val CircHv = <ore:circuitAdvanced>;

// GT's own plates / blocks, used by name where no other mod contests the entry.
val PlateSilver = <ore:plateSilver>;
val PlateGold = <ore:plateGold>;
val PlateDiamond = <ore:plateDiamond>;
val PlateGlass = <ore:plateGlass>;
val PlateEmerald = <ore:plateEmerald>;
val PlateWood = <ore:plateWood>;
// Plain obsidian, by exact id: <ore:blockObsidian> resolves first to GregTech's *compressed*
// obsidian block (gregtech:meta_block_compressed_8:10), which is a different, far more expensive
// item even though the shaped recipes would still accept vanilla obsidian.
val Obsidian = <minecraft:obsidian>;
val Chest = <ore:chestWood>;
val Hammer = <ore:craftingToolHardHammer>;
val Screwdriver = <ore:craftingToolScrewdriver>;

// ================================================================================= Iron Chests
// The reference (GT5-scripts\Iron-Chests\IronChests.zs) deletes every chest and every upgrade and
// rebuilds them from eight plates around a centre, so a chest costs metal that had to go through a
// GregTech bender instead of vanilla ingots. Same eight-plate shape here.
//
// iron_chest metadata is IronChestType.ordinal() (read from the jar):
//   0 Iron  1 Gold  2 Diamond  3 Copper  4 Silver  5 Crystal  6 Obsidian  7 Dirt Chest  8 Wood
recipes.remove(<ironchest:iron_chest:*>);

recipes.addShaped(<ironchest:iron_chest:7>, [
    [<minecraft:dirt>, <minecraft:dirt>, <minecraft:dirt>],
    [<minecraft:dirt>, Chest,            <minecraft:dirt>],
    [<minecraft:dirt>, <minecraft:dirt>, <minecraft:dirt>]
]);

recipes.addShaped(<ironchest:iron_chest:3>, [
    [PlateCopper, PlateCopper, PlateCopper],
    [PlateCopper, Chest,       PlateCopper],
    [PlateCopper, PlateCopper, PlateCopper]
]);

recipes.addShaped(<ironchest:iron_chest:0>, [
    [PlateIron, PlateIron, PlateIron],
    [PlateIron, <ironchest:iron_chest:3>, PlateIron],
    [PlateIron, PlateIron, PlateIron]
]);

// The five tiers *above* the iron chest - silver, gold, diamond, crystal, obsidian - no longer have a
// crafting-table recipe at all. They are the mod's advanced tiers, so they are built in a GregTech
// assembler now, at the EU/t their metal earns: silver and gold LV, diamond MV, crystal and obsidian
// HV. The grids that used to sit here were moved verbatim, materials and all, into the "Iron Chests"
// section of zzzz_minespace_assembler.zs - a removal cannot be written in a later file than the add it
// is meant to undo, so the adds had to move, not be overwritten.
//
// What stays on the crafting table is the mod's own entry point: the copper chest, the iron chest that
// gives the mod its name, and the dirt chest. Obsidian still has no GregTech plate in this pack (the
// ore dictionary probe listed plateObsidian and gemObsidian as EMPTY), so the obsidian tier is the
// same eight blocks of obsidian it always was, only assembled rather than shaped.

// The nine chest upgrades. Same treatment: the metal in the ring becomes a plate, and nothing else
// changes. That matters - the mod builds every one of these as eight of the target metal around one
// of the source metal, and a GregTech screw is an eighth of an ingot, so replacing half of the ring
// with screws (which an earlier revision of this file did for copper -> silver and iron -> gold)
// quietly cut the metal in those two upgrades to four and a half ingots. The ring stays eight plates.
recipes.remove(<ironchest:wood_copper_chest_upgrade>);
recipes.remove(<ironchest:wood_iron_chest_upgrade>);
recipes.remove(<ironchest:copper_iron_chest_upgrade>);
recipes.remove(<ironchest:copper_silver_chest_upgrade>);
recipes.remove(<ironchest:silver_gold_chest_upgrade>);
recipes.remove(<ironchest:iron_gold_chest_upgrade>);
recipes.remove(<ironchest:gold_diamond_chest_upgrade>);
recipes.remove(<ironchest:diamond_crystal_chest_upgrade>);
recipes.remove(<ironchest:diamond_obsidian_chest_upgrade>);

recipes.addShaped(<ironchest:wood_copper_chest_upgrade>, [
    [PlateCopper, PlateCopper, PlateCopper],
    [PlateCopper, <ore:plankWood>, PlateCopper],
    [PlateCopper, PlateCopper, PlateCopper]
]);

recipes.addShaped(<ironchest:wood_iron_chest_upgrade>, [
    [PlateIron, PlateIron, PlateIron],
    [PlateIron, <ore:plankWood>, PlateIron],
    [PlateIron, PlateIron, PlateIron]
]);

recipes.addShaped(<ironchest:copper_iron_chest_upgrade>, [
    [PlateIron, PlateGlass, PlateIron],
    [PlateGlass, PlateCopper, PlateGlass],
    [PlateIron, PlateGlass, PlateIron]
]);

// The six upgrades that lead to a tier which itself moved - to silver, gold, diamond, crystal or
// obsidian - moved with it, and are assembled at that tier's voltage. The three that only reach the
// copper or iron chest stay above: an upgrade is no more "advanced" than the chest it produces.

// =========================================================================== Storage Drawers
// The reference (GTNH Storage-Drawers.zs) rebuilds every drawer family from one uniform block
// instead of the per-wood planks, so a drawer no longer comes straight out of any tree. This pack
// has no Carpenter's Block, so the GregTech equivalent is the wood plate: every wooden drawer part
// becomes a GT wood plate (which needs a cutting machine), and the metal / gem parts become GT
// plates. Shapes and counts are the mod's own, read off the run.
recipes.remove(<storagedrawers:basicdrawers:*>);
recipes.remove(<storagedrawers:trim:*>);
recipes.remove(<storagedrawers:compdrawers:*>);
recipes.remove(<storagedrawers:controller>);
recipes.remove(<storagedrawers:controllerslave>);
recipes.remove(<storagedrawers:framingtable>);
recipes.remove(<storagedrawers:customdrawers:*>);
recipes.remove(<storagedrawers:customtrim>);
recipes.remove(<storagedrawers:upgrade_template>);
recipes.remove(<storagedrawers:upgrade_storage:*>);
recipes.remove(<storagedrawers:upgrade_one_stack>);
recipes.remove(<storagedrawers:upgrade_status:*>);
recipes.remove(<storagedrawers:upgrade_void>);
recipes.remove(<storagedrawers:upgrade_conversion>);
recipes.remove(<storagedrawers:upgrade_redstone:*>);

// Basic drawers: metadata 0 is 1x1, 1 is 1x2, 2 is 2x2, 3 is half 1x2, 4 is half 2x2.
// The mod's own patterns are written as rings of the wood material around the chests (its
// `TemplateRecipe` rows are literally "xxx" / " y " / "xxx" and "xyx" / "xxx" / "xyx"), so the 1x1
// drawer is a full eight-plate ring - dropping the two plates beside the chest would have made it
// the only drawer in the family that is cheaper than its own recipe was.
recipes.addShaped(<storagedrawers:basicdrawers:0>, [
    [PlateWood, PlateWood, PlateWood],
    [PlateWood, Chest,     PlateWood],
    [PlateWood, PlateWood, PlateWood]
]);

// 1x2 full: two chests in the middle column.
recipes.addShaped(<storagedrawers:basicdrawers:1> * 2, [
    [PlateWood, Chest,     PlateWood],
    [PlateWood, PlateWood, PlateWood],
    [PlateWood, Chest,     PlateWood]
]);

// 2x2 full: four chests in the corners.
recipes.addShaped(<storagedrawers:basicdrawers:2> * 4, [
    [Chest,     PlateWood, Chest],
    [PlateWood, PlateWood, PlateWood],
    [Chest,     PlateWood, Chest]
]);

// Half-depth drawers: the mod builds these from slabs, and the slab is what keeps them a different
// recipe from the full drawers above - two shaped recipes with identical grids would collide and
// only one of them would ever be craftable.
recipes.addShaped(<storagedrawers:basicdrawers:3> * 2, [
    [<ore:slabWood>, Chest,           <ore:slabWood>],
    [<ore:slabWood>, <ore:slabWood>,  <ore:slabWood>],
    [<ore:slabWood>, Chest,           <ore:slabWood>]
]);

recipes.addShaped(<storagedrawers:basicdrawers:4>, [
    [Chest,          <ore:slabWood>, Chest],
    [<ore:slabWood>, <ore:slabWood>, <ore:slabWood>],
    [Chest,          <ore:slabWood>, Chest]
]);

// Trim, one per vanilla wood type (metadata 0..5 in registration order).
recipes.addShaped(<storagedrawers:trim:0> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:trim:1> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:trim:2> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:trim:3> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:trim:4> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:trim:5> * 4, [
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood,       PlateWood, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>]
]);

// The four drawer blocks that are machines rather than furniture - the compacting drawer, the drawer
// controller, its slave and the framing table - are built in a GregTech assembler now, at LV. They are
// the only Storage Drawers items that already needed a GregTech circuit or a GregTech screw to exist,
// so they are the ones the owner's rule ("an advanced item must be produced by a GregTech machine")
// applies to. The grids were moved verbatim into the "Storage Drawers" section of
// zzzz_minespace_assembler.zs. The plain drawers, trims and upgrade templates stay craftable by hand.

// Framed drawers and framed trim are built around the framing table, so they keep their shape and
// take GT wood plates like the basic family.
recipes.addShaped(<storagedrawers:customdrawers:0>, [
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>],
    [<ore:stickWood>, Chest,            <ore:stickWood>],
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:customdrawers:1> * 2, [
    [<ore:stickWood>, Chest,            <ore:stickWood>],
    [<ore:stickWood>, PlateWood,        <ore:stickWood>],
    [<ore:stickWood>, Chest,            <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:customdrawers:2> * 4, [
    [Chest,     <ore:stickWood>, Chest],
    [PlateWood, <ore:stickWood>, PlateWood],
    [Chest,     <ore:stickWood>, Chest]
]);
recipes.addShaped(<storagedrawers:customdrawers:3> * 2, [
    [<ore:stickWood>, Chest,          <ore:stickWood>],
    [<ore:stickWood>, <ore:slabWood>, <ore:stickWood>],
    [<ore:stickWood>, Chest,          <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:customdrawers:4> * 4, [
    [Chest,          <ore:stickWood>, Chest],
    [<ore:slabWood>, <ore:stickWood>, <ore:slabWood>],
    [Chest,          <ore:stickWood>, Chest]
]);
recipes.addShaped(<storagedrawers:customtrim> * 4, [
    [PlateWood, <ore:stickWood>, PlateWood],
    [<ore:stickWood>, PlateWood, <ore:stickWood>],
    [PlateWood, <ore:stickWood>, PlateWood]
]);

// Upgrades: the template needs GT screws, and every tier's metal or gem is a GregTech plate.
recipes.addShaped(<storagedrawers:upgrade_template> * 2, [
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>],
    [<ore:stickWood>, <ore:drawerBasic>, <ore:stickWood>],
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>]
]);

// Storage upgrade tier 0 (obsidian, the "1x" upgrade) stays on the crafting table - it is the one you
// start with. The four tiers above it are assembled, LV for iron and gold and MV for diamond and
// emerald: a drawer that holds 8x or 16x of a stack is not a hand-tool.
recipes.addShaped(<storagedrawers:upgrade_storage>, [
    [ScrewIron, ScrewIron, ScrewIron],
    [Obsidian, <storagedrawers:upgrade_template>, Obsidian],
    [ScrewIron, ScrewIron, ScrewIron]
]);

recipes.addShaped(<storagedrawers:upgrade_one_stack>, [
    [ScrewIron, ScrewIron, ScrewIron],
    [<ore:itemFlint>, <storagedrawers:upgrade_template>, <ore:itemFlint>],
    [ScrewIron, ScrewIron, ScrewIron]
]);

recipes.addShaped(<storagedrawers:upgrade_void>, [
    [Obsidian, Obsidian, Obsidian],
    [Obsidian, <storagedrawers:upgrade_template>, Obsidian],
    [Obsidian, Obsidian, Obsidian]
]);

recipes.addShaped(<storagedrawers:upgrade_conversion>, [
    [<ore:gemLapis>, <ore:stickWood>, <ore:gemLapis>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:gemLapis>, <ore:stickWood>, <ore:gemLapis>]
]);

recipes.addShaped(<storagedrawers:upgrade_status>, [
    [<ore:craftingRedstoneTorch>, <ore:stickWood>, <ore:craftingRedstoneTorch>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:dustRedstone>, <ore:stickWood>, <ore:dustRedstone>]
]);
recipes.addShaped(<storagedrawers:upgrade_status:1>, [
    [<minecraft:comparator>, <ore:stickWood>, <minecraft:comparator>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:dustRedstone>, <ore:stickWood>, <ore:dustRedstone>]
]);

recipes.addShaped(<storagedrawers:upgrade_redstone>, [
    [<ore:dustRedstone>, <ore:stickWood>, <ore:dustRedstone>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:dustRedstone>, <ore:stickWood>, <ore:dustRedstone>]
]);
recipes.addShaped(<storagedrawers:upgrade_redstone:1>, [
    [<ore:dustRedstone>, <ore:dustRedstone>, <ore:dustRedstone>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>]
]);
recipes.addShaped(<storagedrawers:upgrade_redstone:2>, [
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>],
    [<ore:stickWood>, <storagedrawers:upgrade_template>, <ore:stickWood>],
    [<ore:dustRedstone>, <ore:dustRedstone>, <ore:dustRedstone>]
]);

// =============================================================================== Ender IO
// Ender IO's own generators are the machines GregTech already provides: a stirling generator, a
// combustion generator, a lava generator, a zombie generator and a solar panel. They are removed
// exactly the way Galacticraft's coal generator and solar panels are, and hidden from JEI.
recipes.remove(<enderio:block_stirling_generator>);
recipes.remove(<enderio:block_simple_stirling_generator>);
recipes.remove(<enderio:block_combustion_generator>);
recipes.remove(<enderio:block_enhanced_combustion_generator>);
recipes.remove(<enderio:block_zombie_generator>);
recipes.remove(<enderio:block_franken_zombie_generator>);
recipes.remove(<enderio:block_ender_generator>);
recipes.remove(<enderio:block_lava_generator>);
recipes.remove(<enderio:block_solar_panel:*>);

mods.jei.JEI.hide(<enderio:block_stirling_generator>);
mods.jei.JEI.hide(<enderio:block_simple_stirling_generator>);
mods.jei.JEI.hide(<enderio:block_combustion_generator>);
mods.jei.JEI.hide(<enderio:block_enhanced_combustion_generator>);
mods.jei.JEI.hide(<enderio:block_zombie_generator>);
mods.jei.JEI.hide(<enderio:block_franken_zombie_generator>);
mods.jei.JEI.hide(<enderio:block_ender_generator>);
mods.jei.JEI.hide(<enderio:block_lava_generator>);
mods.jei.JEI.hide(<enderio:block_solar_panel:0>);
mods.jei.JEI.hide(<enderio:block_solar_panel:1>);
mods.jei.JEI.hide(<enderio:block_solar_panel:2>);
mods.jei.JEI.hide(<enderio:block_solar_panel:3>);
// The four dark steel upgrades that turn a machine into a solar machine go with them: their only
// input is one of these panels, so the recipes were unbuildable, and eio_upgrades.zs no longer writes
// them. Hidden here, next to the panels, because they are the same decision - the pack keeps neither
// a machine nor an upgrade that makes free RF.
mods.jei.JEI.hide(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiomachines:solar" }));
mods.jei.JEI.hide(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiomachines:solar1" }));
mods.jei.JEI.hide(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiomachines:solar2" }));
mods.jei.JEI.hide(<enderio:item_dark_steel_upgrade:1>.withTag({ "enderio:dsu": "enderiomachines:solar3" }));

// The machine chassis is Ender IO's root part: every one of its machines is built on it. Costing it
// in GregTech steel plate and screws gates the whole mod behind a GregTech rolling mill instead of
// behind vanilla iron bars and dust.
recipes.remove(<enderio:item_material:0>);
recipes.addShaped(<enderio:item_material:0>, [
    [<ore:barsIron>, PlateSteel, <ore:barsIron>],
    [PlateSteel,     <ore:dustBedrock>, PlateSteel],
    [<ore:barsIron>, PlateSteel, <ore:barsIron>]
]);

recipes.remove(<enderio:item_material:2> * 16);
recipes.addShaped(<enderio:item_material:2> * 16, [
    [PlateSteel, PlateSteel, PlateSteel],
    [PlateSteel, <enderio:item_material:1>, PlateSteel],
    [PlateSteel, PlateSteel, PlateSteel]
]);

// The three capacitors: the plain copper in the base tier becomes an LV GregTech circuit, so Ender
// IO's machine upgrades need a circuit line to exist first. Tiers 2 and 3 keep their shape.
recipes.remove(<enderio:item_basic_capacitor:0>);
recipes.addShaped(<enderio:item_basic_capacitor:0>, [
    [null,           <ore:nuggetGold>, <ore:dustBedrock>],
    [<ore:nuggetGold>, CircLv,         <ore:nuggetGold>],
    [<ore:dustBedrock>, <ore:nuggetGold>, null]
]);

// Power and fluid conduits come out of GregTech's assembler instead of the crafting grid, the way
// the reference does it, so a conduit run costs machine time.
recipes.remove(<enderio:item_power_conduit:0>);
recipes.remove(<enderio:item_power_conduit:1>);
recipes.remove(<enderio:item_power_conduit:2>);
recipes.remove(<enderio:item_liquid_conduit:0>);

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:itemConduitBinder> * 6, <ore:ingotConductiveIron> * 3)
    .outputs(<enderio:item_power_conduit:0> * 8)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:itemConduitBinder> * 6, <ore:ingotEnergeticAlloy> * 3)
    .outputs(<enderio:item_power_conduit:1> * 8)
    .duration(300).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:itemConduitBinder> * 6, <ore:ingotVibrantAlloy> * 3)
    .outputs(<enderio:item_power_conduit:2> * 8)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:itemConduitBinder> * 6, <ore:blockGlassColorless> * 3)
    .outputs(<enderio:item_liquid_conduit:0> * 8)
    .duration(200).EUt(30)
    .buildAndRegister();

// =============================================================================== Forestry
// Forestry's machines are its whole tech tree. The reference rebuilds them from GregTech parts;
// this does the same by swapping the metal in each of the mod's own recipes for the GregTech plate
// of that metal, and the plain glass for a GregTech glass plate. Bronze / copper / tin gears stay
// Forestry's (they are already made from plates and a wrench), and the machines that actually
// process something take an LV circuit in the slot that used to be empty.
//
// NOTE (added later): every Forestry *machine* below has since moved off the crafting table into
// the GregTech assembler - see zzzz_minespace_assembler.zs. Their crafting recipes are deliberately
// NOT re-added here any more (a `recipes.remove` in a later script cannot undo a recipe another
// script added: CraftTweaker applies all removals before all additions), which is why this file
// now only crafts the pieces that are meant to stay craftable - the sturdy casing, the apiary, the
// mailbox, the alveary-free farm blocks, the cans, the stamps and the goggles.
recipes.remove(<forestry:sturdy_machine>);
recipes.addShaped(<forestry:sturdy_machine>, [
    [PlateBronze, PlateBronze, PlateBronze],
    [PlateBronze, CircLv,      PlateBronze],
    [PlateBronze, PlateBronze, PlateBronze]
]);

recipes.remove(<forestry:carpenter>);

recipes.remove(<forestry:centrifuge>);

recipes.remove(<forestry:squeezer>);

recipes.remove(<forestry:fermenter>);

recipes.remove(<forestry:moistener>);

recipes.remove(<forestry:still>);

recipes.remove(<forestry:raintank>);

recipes.remove(<forestry:analyzer>);

recipes.remove(<forestry:fabricator>);

recipes.remove(<forestry:rainmaker>);

recipes.remove(<forestry:mailbox>);
recipes.addShaped(<forestry:mailbox>, [
    [null,        PlateTin,        null],
    [PlateTin,    <forestry:sturdy_machine>, PlateTin],
    [Chest,       Chest,           Chest]
]);

// Engines: the copper / bronze shell becomes a GT plate and the glass a GT glass plate.
recipes.remove(<forestry:engine_peat>);

recipes.remove(<forestry:engine_biogas>);

// Only the managed peat bog is rebuilt; the manual variant is the mod's own 1:1 conversion of it
// and is left alone so it stays reachable.
recipes.remove(<forestry:peat_bog:0>);

// The multi-block farm frame: copper becomes a GT plate and the voltage tube stays Forestry's.
recipes.remove(<forestry:ffarm:0>);

// Alveary: the plain block is the reference's target for a GregTech casing, and the modules below
// it take GT plates where they used ingots.
recipes.remove(<forestry:alveary.plain>);

recipes.remove(<forestry:alveary.swarmer>);

recipes.remove(<forestry:alveary.fan>);

recipes.remove(<forestry:alveary.heater>);

recipes.remove(<forestry:alveary.hygro>);

recipes.remove(<forestry:alveary.sieve>);

// The rest of Forestry's machine line. Same rule: the plain glass and the plain metal become GT
// glass plates and GT metal plates, while Forestry's own parts (electron tubes, chipsets, casings)
// stay because they are what makes the machines Forestry's.
recipes.remove(<forestry:bottler>);

recipes.remove(<forestry:habitat_former>);

recipes.remove(<forestry:trade_station>);

recipes.remove(<forestry:database>);

recipes.remove(<forestry:apiary>);
recipes.addShaped(<forestry:apiary>, [
    [<ore:slabWood>, <ore:slabWood>, <ore:slabWood>],
    [PlateWood, <forestry:impregnated_casing>, PlateWood],
    [PlateWood, PlateWood, PlateWood]
]);

// The single-block farms. Their only non-Forestry material is the plain glass.
recipes.remove(<forestry:arboretum:0>);
recipes.addShaped(<forestry:arboretum:0>, [
    [PlateGlass, <forestry:thermionic_tubes:4>, PlateGlass],
    [<forestry:thermionic_tubes:4>, <forestry:flexible_casing>, <forestry:thermionic_tubes:4>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

recipes.remove(<forestry:farm_crops:0>);
recipes.addShaped(<forestry:farm_crops:0>, [
    [PlateGlass, <forestry:thermionic_tubes:2>, PlateGlass],
    [<forestry:thermionic_tubes:2>, <forestry:flexible_casing>, <forestry:thermionic_tubes:2>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

recipes.remove(<forestry:farm_mushroom:0>);
recipes.addShaped(<forestry:farm_mushroom:0>, [
    [PlateGlass, <forestry:thermionic_tubes:10>, PlateGlass],
    [<forestry:thermionic_tubes:10>, <forestry:flexible_casing>, <forestry:thermionic_tubes:10>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

recipes.remove(<forestry:farm_gourd:0>);
recipes.addShaped(<forestry:farm_gourd:0>, [
    [PlateGlass, <forestry:thermionic_tubes:11>, PlateGlass],
    [<forestry:thermionic_tubes:11>, <forestry:flexible_casing>, <forestry:thermionic_tubes:11>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

recipes.remove(<forestry:farm_nether:0>);
recipes.addShaped(<forestry:farm_nether:0>, [
    [PlateGlass, <forestry:thermionic_tubes:7>, PlateGlass],
    [<forestry:thermionic_tubes:7>, <forestry:flexible_casing>, <forestry:thermionic_tubes:7>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

recipes.remove(<forestry:farm_ender:0>);
recipes.addShaped(<forestry:farm_ender:0>, [
    [PlateGlass, <forestry:thermionic_tubes:12>, PlateGlass],
    [<forestry:thermionic_tubes:12>, <forestry:flexible_casing>, <forestry:thermionic_tubes:12>],
    [PlateGlass, <forestry:chipsets:0>, PlateGlass]
]);

// ------------------------------------------- Forestry's duplicate materials and generic tools
// This is the same treatment Galacticraft's duplicate metals get in gc_gregify_removals.zs, and it
// is what the reference pack's Forestry.zs does first (its lines 60-80 remove gearBronze, gearCopper,
// gearTin, the four stamps, the wrench, the bronze/kit pickaxe and shovel). Forestry ships its own
// copper / tin / bronze ingots and gears that GregTech already provides, plus a pickaxe, a shovel and
// a wrench GregTech's tool set replaces. Nothing here is re-added: the ore dictionary entries
// (ingotCopper, gearBronze, ...) still list GregTech's items, so every recipe written against those
// names keeps working while the mod's own copy stops being craftable.
recipes.remove(<forestry:gear_bronze>);
recipes.remove(<forestry:gear_copper>);
recipes.remove(<forestry:gear_tin>);
recipes.remove(<forestry:ingot_copper>);
recipes.remove(<forestry:ingot_tin>);
recipes.remove(<forestry:ingot_bronze>);
recipes.remove(<forestry:bronze_pickaxe>);
recipes.remove(<forestry:bronze_shovel>);
recipes.remove(<forestry:kit_pickaxe>);
recipes.remove(<forestry:kit_shovel>);
recipes.remove(<forestry:wrench>);

// The remaining two shortcuts are kept but re-costed, because unlike the metals above they have no
// GregTech equivalent to fall back on and deleting them outright would leave a hole:
//   * the tin cans (Forestry's "canEmpty") become GT tin plate;
//   * the four stamps become GT plates / GT apatite plate instead of bare ingots and gems.
// (Stamps 20n/50n/100n have no crafting recipe in Forestry 5.8 at all - they are made in the
// Thermionic Fabricator from a wax cast, which is untouched.)
recipes.remove(<forestry:can>);
recipes.addShaped(<forestry:can> * 12, [
    [null, PlateTin, null],
    [PlateTin, null, PlateTin]
]);

recipes.remove(<forestry:stamps:0>);
recipes.remove(<forestry:stamps:1>);
recipes.remove(<forestry:stamps:2>);
recipes.remove(<forestry:stamps:3>);

recipes.addShaped(<forestry:stamps:0> * 9, [
    [<ore:gemApatite>, <ore:gemApatite>, <ore:gemApatite>],
    [<ore:paper>, <ore:paper>, <ore:paper>],
    [<ore:dropHoney>, <ore:dropHoney>, <ore:dropHoney>]
]);
recipes.addShaped(<forestry:stamps:1> * 9, [
    [PlateCopper, PlateCopper, PlateCopper],
    [<ore:paper>, <ore:paper>, <ore:paper>],
    [<ore:dropHoney>, <ore:dropHoney>, <ore:dropHoney>]
]);
recipes.addShaped(<forestry:stamps:2> * 9, [
    [PlateTin, PlateTin, PlateTin],
    [<ore:paper>, <ore:paper>, <ore:paper>],
    [<ore:dropHoney>, <ore:dropHoney>, <ore:dropHoney>]
]);
recipes.addShaped(<forestry:stamps:3> * 9, [
    [PlateGold, PlateGold, PlateGold],
    [<ore:paper>, <ore:paper>, <ore:paper>],
    [<ore:dropHoney>, <ore:dropHoney>, <ore:dropHoney>]
]);

// The naturalist's goggles are the beekeeper's own tool, so they are re-costed rather than deleted.
recipes.remove(<forestry:naturalist_helmet>);
recipes.addShaped(<forestry:naturalist_helmet>, [
    [null, PlateBronze, null],
    [PlateGlass, null, PlateGlass]
]);

// ----------------------------------------- Ender IO's dark steel tools and armour (same class)
// The reference pack removes exactly these too (GT5-scripts\Ender_IO\Ender-IO.zs lines 13-30:
// darkSteel_helmet / chestplate / leggings / boots / axe / sword / pickaxe, each also hidden from
// NEI). GregTech's own tool and armour sets replace them. Checked against the full crafting dump
// first: no recipe anywhere in the pack uses one of them as an ingredient, so nothing can be
// stranded by deleting them, and Ender IO's dark steel *upgrades* (which are built from
// item_dark_steel_upgrade:0 plus some other item) are untouched.
recipes.remove(<enderio:item_dark_steel_helmet>);
recipes.remove(<enderio:item_dark_steel_chestplate>);
recipes.remove(<enderio:item_dark_steel_leggings>);
recipes.remove(<enderio:item_dark_steel_boots>);
recipes.remove(<enderio:item_dark_steel_sword>);
recipes.remove(<enderio:item_dark_steel_pickaxe>);
recipes.remove(<enderio:item_dark_steel_axe>);

mods.jei.JEI.hide(<enderio:item_dark_steel_helmet>);
mods.jei.JEI.hide(<enderio:item_dark_steel_chestplate>);
mods.jei.JEI.hide(<enderio:item_dark_steel_leggings>);
mods.jei.JEI.hide(<enderio:item_dark_steel_boots>);
mods.jei.JEI.hide(<enderio:item_dark_steel_sword>);
mods.jei.JEI.hide(<enderio:item_dark_steel_pickaxe>);
mods.jei.JEI.hide(<enderio:item_dark_steel_axe>);

// ------------------------------- Iron Chests: the sixteen coloured shulker box chains
// The last family still on the mod's own recipes. Every colour has the same seven tiers and the
// same eleven recipes (each tier is reachable two ways: "vanilla shulker box up to tier 0/3" and
// "upgrade from the tier below"), so writing 176 recipe blocks by hand would only invite typos.
// CraftTweaker's `itemUtils.getItem(name, meta)` is the same code path as the `<item:...>` bracket
// handler with an explicit metadata, and ZenScript loops over a string array, so the whole family is
// generated. The shapes are the mod's own, read off a live run; only the materials change:
// ingot -> GregTech plate, vanilla glass -> GregTech glass plate, obsidian -> obsidian.
//
// Tier order (ironchest metadata): 0 Iron, 1 Gold, 2 Diamond, 3 Copper, 4 Silver, 5 Crystal,
// 6 Obsidian. The vanilla shulker box for light grey is `minecraft:silver_shulker_box` in 1.12.2.
val shulkerColours = ["white", "orange", "magenta", "light_blue", "yellow", "lime", "pink",
        "gray", "silver", "cyan", "purple", "blue", "brown", "green", "red", "black"] as string[];

val shulkerTiers = [0, 1, 2, 3, 4, 5, 6] as int[];

for colour in shulkerColours {
    for tier in shulkerTiers {
        recipes.remove(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, tier));
    }

    // Iron: vanilla shulker box, or up from copper.
    recipes.addShaped(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 0), [
        [PlateIron, PlateIron, PlateIron],
        [PlateIron, itemUtils.getItem("minecraft:" + colour + "_shulker_box", 0), PlateIron],
        [PlateIron, PlateIron, PlateIron]
    ]);
    recipes.addShaped(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 0), [
        [PlateIron, PlateGlass, PlateIron],
        [PlateGlass, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 3), PlateGlass],
        [PlateIron, PlateGlass, PlateIron]
    ]);

    // Copper: vanilla shulker box again.
    recipes.addShaped(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 3), [
        [PlateCopper, PlateCopper, PlateCopper],
        [PlateCopper, itemUtils.getItem("minecraft:" + colour + "_shulker_box", 0), PlateCopper],
        [PlateCopper, PlateCopper, PlateCopper]
    ]);

    // Only the two entry tiers - iron (0) and copper (3) - are still shaped by hand. The other five
    // are assembled at the same voltage as the matching chest, so a diamond shulker box cannot be a
    // way around the diamond chest's assembler step. Those recipes are generated by the same colour
    // loop in zzzz_minespace_assembler.zs; a shaped recipe may not be deleted later than it is added,
    // so the adds above had to go rather than be removed here.
}

// ---------------------------------------------------------- Iron Chests: shulker upgrades
// The nine shulker-box upgrades mirror the chest upgrades and get the same treatment. The per-colour
// shulker boxes themselves are *not* deleted - they are recolours of one chain, and the two entry
// tiers of that chain stay above - but the five tiers above iron are assembled now, like the chests.
recipes.remove(<ironchest:vanilla_iron_shulker_upgrade>);
recipes.remove(<ironchest:vanilla_copper_shulker_upgrade>);
recipes.remove(<ironchest:iron_gold_shulker_upgrade>);
recipes.remove(<ironchest:gold_diamond_shulker_upgrade>);
recipes.remove(<ironchest:copper_silver_shulker_upgrade>);
recipes.remove(<ironchest:silver_gold_shulker_upgrade>);
recipes.remove(<ironchest:copper_iron_shulker_upgrade>);
recipes.remove(<ironchest:diamond_crystal_shulker_upgrade>);
recipes.remove(<ironchest:diamond_obsidian_shulker_upgrade>);

recipes.addShaped(<ironchest:vanilla_iron_shulker_upgrade>, [
    [PlateIron, PlateIron, PlateIron],
    [PlateIron, <minecraft:shulker_shell>, PlateIron],
    [PlateIron, PlateIron, PlateIron]
]);

recipes.addShaped(<ironchest:vanilla_copper_shulker_upgrade>, [
    [PlateCopper, PlateCopper, PlateCopper],
    [PlateCopper, <minecraft:shulker_shell>, PlateCopper],
    [PlateCopper, PlateCopper, PlateCopper]
]);

recipes.addShaped(<ironchest:copper_iron_shulker_upgrade>, [
    [PlateGlass, PlateGlass, PlateGlass],
    [PlateIron,  PlateCopper, PlateIron],
    [PlateIron,  PlateGlass,  PlateIron]
]);

// The six shulker upgrades that lead above the iron tier are assembled, exactly like the six chest
// upgrades that do the same job; the three that lead to the copper or iron shulker box stay shaped.

// ------------------------------------------------------------ Storage Drawers: the drawer key
// The key is the one drawer item with metal in it; the concealment / personal / quantify keys are
// shapeless combinations of it and stay as they are.
recipes.remove(<storagedrawers:drawer_key>);
recipes.addShaped(<storagedrawers:drawer_key>, [
    [<ore:nuggetGold>, PlateGold, null],
    [PlateGold, null, <storagedrawers:upgrade_template>]
]);

// ==================================================================== Ender IO: its nine alloys
// Ender IO's alloy smelter is kept (removing it would leave its own machine tree unreachable), but
// its alloys are now also produced by GregTech. The inputs are copied from Ender IO's own
// `assets/enderio/config/recipes/alloying.xml`, read out of the jar, so the conversions are the
// mod's, not invented.
//
// Which GregTech machine depends on the recipe's arity: GTCE-TJ declares `alloy_smelter` as
// `new RecipeMap("alloy_smelter", 1, 2, ...)` - a hard maximum of two item inputs - while `mixer`
// is `(0, 4, ...)`. The two-input alloys therefore run in the alloy smelter and the three-input
// ones in the mixer. A recipe with more inputs than its map allows is rejected on load with
// "Invalid amount of recipe inputs", so this split is not cosmetic.

// --- alloy smelter (two inputs)
mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<ore:ingotEnergeticAlloy>, <ore:enderpearl>)
    .outputs(<enderio:item_alloy_ingot:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<ore:dustRedstone>, <ore:ingotSilicon>)
    .outputs(<enderio:item_alloy_ingot:3>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<ore:dustRedstone>, <ore:ingotIron>)
    .outputs(<enderio:item_alloy_ingot:4>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<ore:ingotIron>, <ore:enderpearl>)
    .outputs(<enderio:item_alloy_ingot:5>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<minecraft:soul_sand>, <ore:ingotGold>)
    .outputs(<enderio:item_alloy_ingot:7>)
    .duration(200).EUt(30)
    .buildAndRegister();

// The two "variant" recipes Ender IO also ships (steel instead of iron plus one more step).
mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(PlateSteel, <ore:ingotSilicon>)
    .outputs(<enderio:item_alloy_ingot:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(PlateSteel, <minecraft:obsidian>)
    .outputs(<enderio:item_alloy_ingot:6>)
    .duration(200).EUt(30)
    .buildAndRegister();

// --- mixer (three inputs)
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:ingotIron>, <ore:dustCoal>, <ore:ingotSilicon>)
    .outputs(<enderio:item_alloy_ingot:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:dustRedstone>, <ore:ingotGold>, <ore:dustGlowstone>)
    .outputs(<enderio:item_alloy_ingot:1>)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:ingotIron>, <ore:dustCoal>, <minecraft:obsidian>)
    .outputs(<enderio:item_alloy_ingot:6>)
    .duration(400).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:endstone>, <ore:ingotDarkSteel>, <minecraft:obsidian>)
    .outputs(<enderio:item_alloy_ingot:8>)
    .duration(400).EUt(30)
    .buildAndRegister();

// Construction Alloy accepts any of fourteen metals in Ender IO's XML; copper is the representative
// here, which keeps the recipe to one ingredient and matches the tier of the machine chassis it is
// used for.
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:ingotCopper> * 2, <ore:ingotIron>)
    .outputs(<enderio:item_alloy_ingot:9> * 3)
    .duration(400).EUt(30)
    .buildAndRegister();

// Enderium Base - the Thermal Foundation intermediate on Enderium's way, and the last metal ingot
// Ender IO still shipped an item for. Section 6az switched the mod's alloy smelter entry off with the
// other fifteen; section 6ba registers the metal as a GregTech material
// (`MinespaceMaterials.ENDER_IO_OTHER_INGOTS`) and this is its recipe, ported from that entry: three
// lead, one platinum and four ender pearls into four ingots, the same 1:4 ratio at the same three
// inputs - which is within the mixer's four slots. The output is written as Ender IO's item, exactly
// like the ten alloys above, because `MinespaceMaterialRepoint` re-points every machine output whose
// item the pack has unified to GregTech's by the time anyone can run it.
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:ingotLead> * 3, <ore:ingotPlatinum>, <ore:enderpearl> * 4)
    .outputs(<enderio:item_material:39> * 4)
    .duration(400).EUt(30)
    .buildAndRegister();

// ============================================================== Ender IO's seven "endergy" alloys
//
// The owner: *"why are these alloys' crafting methods gone? They go through the GT alloy smelter."*
// They were gone because the recipes are not in Ender IO itself - the base mod ships the seven alloys,
// their nuggets, blocks and grinding balls and the four auto conversions, and that is all. The
// production recipes live in the separate **Ender IO - Endergy** addon, which this pack does not
// install: version 5.3.72, `assets/enderio/config/recipes/endergy.xml`, read out of the addon jar.
// Every recipe below is that file's, with the same inputs and the same output counts, only moved onto
// GregTech's machines:
//
//   two inputs  -> the **alloy smelter** (its limit is two item slots)
//   three inputs -> the **mixer** (four slots) - the same split the ten alloys above use, and the
//                   reason `Alloy: Enderium Base` a moment ago went to the mixer as well
//
// Outputs are written as Ender IO's items, like every other alloy recipe in this file, because
// `MinespaceMaterialRepoint` re-points machine outputs onto GregTech's ingot by the time a player can
// run them (verified: the machine-output re-point count moves with these registrations).
//
// Two of the addon's eight entries are deliberately not here:
//
//   * `Alloy: Endergy Crystalline Pink Slime` needs `industrialforegoing:pink_slime_ingot`, and
//     Industrial Foregoing is not in this pack. The addon marks that entry `required="false"` for
//     exactly this reason, so leaving it out is the addon's own behaviour rather than a decision of
//     ours - but it does mean this one alloy still has no recipe.
//   * `Alloy: Endergy Combustive Metal` produces `ingotCombustiveMetal`, an item the *addon* adds.
//     The pack has no such item (only EIO 5.3.72 is installed), so there is nothing to make.

// Crude Steel: gravel + clay + cobblestone -> 1 ingot (three inputs, so the mixer).
// The clay is written as the item, not as EIO's `itemClay` ore name: that name is registered later
// than CraftTweaker's pass, so `<ore:itemClay>` is empty here and GregTech would take the recipe with
// a dead slot. `minecraft:clay_ball` is what the name holds (verified against the ore dictionary dump
// and against EIO's own `itemClay` alias).
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:gravel>, <minecraft:clay_ball>, <ore:cobblestone>)
    .outputs(<enderio:item_alloy_endergy_ingot:0>)
    .duration(400).EUt(30)
    .buildAndRegister();

// Crystalline Alloy: pulsating powder + gold -> 1 ingot.
mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<enderio:item_material:36>, <ore:ingotGold>)
    .outputs(<enderio:item_alloy_endergy_ingot:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Melodic Alloy: popped chorus fruit + end steel -> 1 ingot.
mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<minecraft:chorus_fruit_popped>, <ore:ingotEndSteel>)
    .outputs(<enderio:item_alloy_endergy_ingot:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Stellar Alloy: nether star + melodic alloy + clay x4 -> 2 ingots (three inputs, so the mixer).
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<minecraft:nether_star>, <ore:ingotMelodicAlloy>, <minecraft:clay_ball> * 4)
    .outputs(<enderio:item_alloy_endergy_ingot:3> * 2)
    .duration(400).EUt(30)
    .buildAndRegister();

// Energetic Silver: redstone + silver + glowstone -> 1 ingot (the Energetic Alloy pattern on silver;
// three inputs, so the mixer).
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<ore:dustRedstone>, <ore:ingotSilver>, <ore:dustGlowstone>)
    .outputs(<enderio:item_alloy_endergy_ingot:5>)
    .duration(400).EUt(30)
    .buildAndRegister();

// Vivid Alloy: ender pearl + energetic silver -> 1 ingot (the Vibrant Alloy pattern on silver).
mods.gregtech.recipe.RecipeMap.getByName("alloy_smelter").recipeBuilder()
    .inputs(<ore:enderpearl>, <ore:ingotEnergeticSilver>)
    .outputs(<enderio:item_alloy_endergy_ingot:6>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Crystalline Pink Slime - the seventh endergy alloy, and the one recipe that is **not** the addon's.
// The addon's entry reads `itemPulsatingPowder + industrialforegoing:pink_slime_ingot`, and Industrial
// Foregoing is not in this pack; the addon itself marks that entry `required="false"` and drops it, so
// the alloy was the one member of the family with no route at all. This substitutes the reagent rather
// than the shape: pink slime is a gelatinous pink material, so the mixer takes a slime ball with pink
// dye in its place, alongside the pulsating powder the addon asked for. Three inputs, so the mixer -
// and the output count stays the addon's one ingot. Recorded as a substitution on purpose: if
// Industrial Foregoing is ever added back, this recipe should be deleted and the addon's used.
mods.gregtech.recipe.RecipeMap.getByName("mixer").recipeBuilder()
    .inputs(<enderio:item_material:36>, <minecraft:slime_ball>, <ore:dyePink>)
    .outputs(<enderio:item_alloy_endergy_ingot:4>)
    .duration(400).EUt(30)
    .buildAndRegister();
