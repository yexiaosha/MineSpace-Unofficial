#priority 696
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Forestry's wood family: planks, fences, slabs, stairs and doors.
//
// The owner's rule for anything made on the crafting table: keep the recipe and the output, and re-cost it
// the way GTNH does. For wood that is the saw - GTNH cuts planks with one, and a fence or a slab is cut
// from planks the same way. Each recipe gains a GregTech saw in a slot the pattern already leaves empty;
// no ingredient is dropped and no count is lowered.
//
// Generated from the live recipe registry: the outputs are the Forestry wood items (registered under
// dotted names such as forestry:planks.fireproof.1) plus the six vanilla doors Forestry adds recipes
// for out of its fireproof planks. Wildcard ingredients were turned back into the ore name they came
// from (plankWood, logWood) rather than being narrowed to the first member.
//
// The output counts were missing until the reconciliation pass (TJ-MIGRATION-PLAN.md 6bt). Every one of
// the 315 recipes was written as `<output>` with no multiplier, so the table made ONE plank out of a log
// where the mod makes four, one slab where it makes six, and one fence / stair / door where it makes
// three or four - the exact opposite of the paragraph above, and invisible in every log the pack writes.
// The numbers are now the mod's own, read back out of the crafting registry before CraftTweaker ran
// (probe `init_all.txt`), and this pack's vanilla wood proves the intent: GregTech's own hard-wood pass
// leaves `minecraft:planks:0` at four per log and only adds the saw (`x4 <- saw + log`).
//
// The six vanilla doors are the other half of that finding. `recipes.remove(<minecraft:x_door>)`
// deletes *every* recipe for the output, and only Forestry's fireproof-plank form was written back, so
// the plain "six oak planks" door that vanilla ships disappeared. They are restored at the end of this
// file, exactly as vanilla had them (no saw - GregTech never touched the doors either).

recipes.remove(<forestry:planks.0:0>);
recipes.addShaped(<forestry:planks.0:0> * 4, [
    [<forestry:logs.0>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:0>);
recipes.addShaped(<forestry:slabs.0:0> * 6, [
    [<forestry:planks.0>, <forestry:planks.0>, <forestry:planks.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:0>);
recipes.addShaped(<forestry:fences.0:0> * 3, [
    [<forestry:planks.0>, <minecraft:stick>, <forestry:planks.0>],
    [<forestry:planks.0>, <minecraft:stick>, <forestry:planks.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.larch:0>);
recipes.addShaped(<forestry:stairs.larch:0> * 4, [
    [<forestry:planks.0>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0>, <forestry:planks.0>, null],
    [<forestry:planks.0>, <forestry:planks.0>, <forestry:planks.0>]
]);

recipes.remove(<forestry:doors.larch:0>);
recipes.addShaped(<forestry:doors.larch:0> * 3, [
    [<forestry:planks.0>, <forestry:planks.0>, <ore:craftingToolSaw>],
    [<forestry:planks.0>, <forestry:planks.0>, null],
    [<forestry:planks.0>, <forestry:planks.0>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:0>);
recipes.addShaped(<forestry:planks.fireproof.0:0> * 4, [
    [<forestry:logs.fireproof.0>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:0>);
recipes.addShaped(<forestry:slabs.fireproof.0:0> * 6, [
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:0>);
recipes.addShaped(<forestry:fences.fireproof.0:0> * 3, [
    [<forestry:planks.fireproof.0>, <minecraft:stick>, <forestry:planks.fireproof.0>],
    [<forestry:planks.fireproof.0>, <minecraft:stick>, <forestry:planks.fireproof.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.larch:0>);
recipes.addShaped(<forestry:stairs.fireproof.larch:0> * 4, [
    [<forestry:planks.fireproof.0>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, null],
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>]
]);

recipes.remove(<forestry:doors.larch:0>);
recipes.addShaped(<forestry:doors.larch:0> * 3, [
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, null],
    [<forestry:planks.fireproof.0>, <forestry:planks.fireproof.0>, null]
]);

recipes.remove(<forestry:planks.0:1>);
recipes.addShaped(<forestry:planks.0:1> * 4, [
    [<forestry:logs.0:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:1>);
recipes.addShaped(<forestry:slabs.0:1> * 6, [
    [<forestry:planks.0:1>, <forestry:planks.0:1>, <forestry:planks.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:1>);
recipes.addShaped(<forestry:fences.0:1> * 3, [
    [<forestry:planks.0:1>, <minecraft:stick>, <forestry:planks.0:1>],
    [<forestry:planks.0:1>, <minecraft:stick>, <forestry:planks.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.teak:0>);
recipes.addShaped(<forestry:stairs.teak:0> * 4, [
    [<forestry:planks.0:1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:1>, <forestry:planks.0:1>, null],
    [<forestry:planks.0:1>, <forestry:planks.0:1>, <forestry:planks.0:1>]
]);

recipes.remove(<forestry:doors.teak:0>);
recipes.addShaped(<forestry:doors.teak:0> * 3, [
    [<forestry:planks.0:1>, <forestry:planks.0:1>, <ore:craftingToolSaw>],
    [<forestry:planks.0:1>, <forestry:planks.0:1>, null],
    [<forestry:planks.0:1>, <forestry:planks.0:1>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:1>);
recipes.addShaped(<forestry:planks.fireproof.0:1> * 4, [
    [<forestry:logs.fireproof.0:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:1>);
recipes.addShaped(<forestry:slabs.fireproof.0:1> * 6, [
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:1>);
recipes.addShaped(<forestry:fences.fireproof.0:1> * 3, [
    [<forestry:planks.fireproof.0:1>, <minecraft:stick>, <forestry:planks.fireproof.0:1>],
    [<forestry:planks.fireproof.0:1>, <minecraft:stick>, <forestry:planks.fireproof.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.teak:0>);
recipes.addShaped(<forestry:stairs.fireproof.teak:0> * 4, [
    [<forestry:planks.fireproof.0:1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, null],
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>]
]);

recipes.remove(<forestry:doors.teak:0>);
recipes.addShaped(<forestry:doors.teak:0> * 3, [
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, null],
    [<forestry:planks.fireproof.0:1>, <forestry:planks.fireproof.0:1>, null]
]);

recipes.remove(<forestry:planks.0:2>);
recipes.addShaped(<forestry:planks.0:2> * 4, [
    [<forestry:logs.0:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:2>);
recipes.addShaped(<forestry:slabs.0:2> * 6, [
    [<forestry:planks.0:2>, <forestry:planks.0:2>, <forestry:planks.0:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:2>);
recipes.addShaped(<forestry:fences.0:2> * 3, [
    [<forestry:planks.0:2>, <minecraft:stick>, <forestry:planks.0:2>],
    [<forestry:planks.0:2>, <minecraft:stick>, <forestry:planks.0:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.acacia:0>);
recipes.addShaped(<forestry:stairs.acacia:0> * 4, [
    [<forestry:planks.0:2>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:2>, <forestry:planks.0:2>, null],
    [<forestry:planks.0:2>, <forestry:planks.0:2>, <forestry:planks.0:2>]
]);

recipes.remove(<forestry:doors.acacia:0>);
recipes.addShaped(<forestry:doors.acacia:0> * 3, [
    [<forestry:planks.0:2>, <forestry:planks.0:2>, <ore:craftingToolSaw>],
    [<forestry:planks.0:2>, <forestry:planks.0:2>, null],
    [<forestry:planks.0:2>, <forestry:planks.0:2>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:4>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:4> * 4, [
    [<forestry:logs.vanilla.fireproof.1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:4>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:4> * 6, [
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:4>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:4> * 3, [
    [<forestry:planks.vanilla.fireproof.0:4>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:4>],
    [<forestry:planks.vanilla.fireproof.0:4>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.acacia:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.acacia:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0:4>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, null],
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>]
]);

recipes.remove(<minecraft:acacia_door:0>);
recipes.addShaped(<minecraft:acacia_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, null],
    [<forestry:planks.vanilla.fireproof.0:4>, <forestry:planks.vanilla.fireproof.0:4>, null]
]);

recipes.remove(<forestry:planks.0:3>);
recipes.addShaped(<forestry:planks.0:3> * 4, [
    [<forestry:logs.0:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:3>);
recipes.addShaped(<forestry:slabs.0:3> * 6, [
    [<forestry:planks.0:3>, <forestry:planks.0:3>, <forestry:planks.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:3>);
recipes.addShaped(<forestry:fences.0:3> * 3, [
    [<forestry:planks.0:3>, <minecraft:stick>, <forestry:planks.0:3>],
    [<forestry:planks.0:3>, <minecraft:stick>, <forestry:planks.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.lime:0>);
recipes.addShaped(<forestry:stairs.lime:0> * 4, [
    [<forestry:planks.0:3>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:3>, <forestry:planks.0:3>, null],
    [<forestry:planks.0:3>, <forestry:planks.0:3>, <forestry:planks.0:3>]
]);

recipes.remove(<forestry:doors.lime:0>);
recipes.addShaped(<forestry:doors.lime:0> * 3, [
    [<forestry:planks.0:3>, <forestry:planks.0:3>, <ore:craftingToolSaw>],
    [<forestry:planks.0:3>, <forestry:planks.0:3>, null],
    [<forestry:planks.0:3>, <forestry:planks.0:3>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:3>);
recipes.addShaped(<forestry:planks.fireproof.0:3> * 4, [
    [<forestry:logs.fireproof.0:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:3>);
recipes.addShaped(<forestry:slabs.fireproof.0:3> * 6, [
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:3>);
recipes.addShaped(<forestry:fences.fireproof.0:3> * 3, [
    [<forestry:planks.fireproof.0:3>, <minecraft:stick>, <forestry:planks.fireproof.0:3>],
    [<forestry:planks.fireproof.0:3>, <minecraft:stick>, <forestry:planks.fireproof.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.lime:0>);
recipes.addShaped(<forestry:stairs.fireproof.lime:0> * 4, [
    [<forestry:planks.fireproof.0:3>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, null],
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>]
]);

recipes.remove(<forestry:doors.lime:0>);
recipes.addShaped(<forestry:doors.lime:0> * 3, [
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, null],
    [<forestry:planks.fireproof.0:3>, <forestry:planks.fireproof.0:3>, null]
]);

recipes.remove(<forestry:planks.0:4>);
recipes.addShaped(<forestry:planks.0:4> * 4, [
    [<forestry:logs.1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:4>);
recipes.addShaped(<forestry:slabs.0:4> * 6, [
    [<forestry:planks.0:4>, <forestry:planks.0:4>, <forestry:planks.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:4>);
recipes.addShaped(<forestry:fences.0:4> * 3, [
    [<forestry:planks.0:4>, <minecraft:stick>, <forestry:planks.0:4>],
    [<forestry:planks.0:4>, <minecraft:stick>, <forestry:planks.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.chestnut:0>);
recipes.addShaped(<forestry:stairs.chestnut:0> * 4, [
    [<forestry:planks.0:4>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:4>, <forestry:planks.0:4>, null],
    [<forestry:planks.0:4>, <forestry:planks.0:4>, <forestry:planks.0:4>]
]);

recipes.remove(<forestry:doors.chestnut:0>);
recipes.addShaped(<forestry:doors.chestnut:0> * 3, [
    [<forestry:planks.0:4>, <forestry:planks.0:4>, <ore:craftingToolSaw>],
    [<forestry:planks.0:4>, <forestry:planks.0:4>, null],
    [<forestry:planks.0:4>, <forestry:planks.0:4>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:4>);
recipes.addShaped(<forestry:planks.fireproof.0:4> * 4, [
    [<forestry:logs.fireproof.1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:4>);
recipes.addShaped(<forestry:slabs.fireproof.0:4> * 6, [
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:4>);
recipes.addShaped(<forestry:fences.fireproof.0:4> * 3, [
    [<forestry:planks.fireproof.0:4>, <minecraft:stick>, <forestry:planks.fireproof.0:4>],
    [<forestry:planks.fireproof.0:4>, <minecraft:stick>, <forestry:planks.fireproof.0:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.chestnut:0>);
recipes.addShaped(<forestry:stairs.fireproof.chestnut:0> * 4, [
    [<forestry:planks.fireproof.0:4>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, null],
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>]
]);

recipes.remove(<forestry:doors.chestnut:0>);
recipes.addShaped(<forestry:doors.chestnut:0> * 3, [
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, null],
    [<forestry:planks.fireproof.0:4>, <forestry:planks.fireproof.0:4>, null]
]);

recipes.remove(<forestry:planks.0:5>);
recipes.addShaped(<forestry:planks.0:5> * 4, [
    [<forestry:logs.1:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:5>);
recipes.addShaped(<forestry:slabs.0:5> * 6, [
    [<forestry:planks.0:5>, <forestry:planks.0:5>, <forestry:planks.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:5>);
recipes.addShaped(<forestry:fences.0:5> * 3, [
    [<forestry:planks.0:5>, <minecraft:stick>, <forestry:planks.0:5>],
    [<forestry:planks.0:5>, <minecraft:stick>, <forestry:planks.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.wenge:0>);
recipes.addShaped(<forestry:stairs.wenge:0> * 4, [
    [<forestry:planks.0:5>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:5>, <forestry:planks.0:5>, null],
    [<forestry:planks.0:5>, <forestry:planks.0:5>, <forestry:planks.0:5>]
]);

recipes.remove(<forestry:doors.wenge:0>);
recipes.addShaped(<forestry:doors.wenge:0> * 3, [
    [<forestry:planks.0:5>, <forestry:planks.0:5>, <ore:craftingToolSaw>],
    [<forestry:planks.0:5>, <forestry:planks.0:5>, null],
    [<forestry:planks.0:5>, <forestry:planks.0:5>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:5>);
recipes.addShaped(<forestry:planks.fireproof.0:5> * 4, [
    [<forestry:logs.fireproof.1:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:5>);
recipes.addShaped(<forestry:slabs.fireproof.0:5> * 6, [
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:5>);
recipes.addShaped(<forestry:fences.fireproof.0:5> * 3, [
    [<forestry:planks.fireproof.0:5>, <minecraft:stick>, <forestry:planks.fireproof.0:5>],
    [<forestry:planks.fireproof.0:5>, <minecraft:stick>, <forestry:planks.fireproof.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.wenge:0>);
recipes.addShaped(<forestry:stairs.fireproof.wenge:0> * 4, [
    [<forestry:planks.fireproof.0:5>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, null],
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>]
]);

recipes.remove(<forestry:doors.wenge:0>);
recipes.addShaped(<forestry:doors.wenge:0> * 3, [
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, null],
    [<forestry:planks.fireproof.0:5>, <forestry:planks.fireproof.0:5>, null]
]);

recipes.remove(<forestry:planks.0:6>);
recipes.addShaped(<forestry:planks.0:6> * 4, [
    [<forestry:logs.1:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:6>);
recipes.addShaped(<forestry:slabs.0:6> * 6, [
    [<forestry:planks.0:6>, <forestry:planks.0:6>, <forestry:planks.0:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:6>);
recipes.addShaped(<forestry:fences.0:6> * 3, [
    [<forestry:planks.0:6>, <minecraft:stick>, <forestry:planks.0:6>],
    [<forestry:planks.0:6>, <minecraft:stick>, <forestry:planks.0:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.baobab:0>);
recipes.addShaped(<forestry:stairs.baobab:0> * 4, [
    [<forestry:planks.0:6>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:6>, <forestry:planks.0:6>, null],
    [<forestry:planks.0:6>, <forestry:planks.0:6>, <forestry:planks.0:6>]
]);

recipes.remove(<forestry:doors.baobab:0>);
recipes.addShaped(<forestry:doors.baobab:0> * 3, [
    [<forestry:planks.0:6>, <forestry:planks.0:6>, <ore:craftingToolSaw>],
    [<forestry:planks.0:6>, <forestry:planks.0:6>, null],
    [<forestry:planks.0:6>, <forestry:planks.0:6>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:6>);
recipes.addShaped(<forestry:planks.fireproof.0:6> * 4, [
    [<forestry:logs.fireproof.1:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:6>);
recipes.addShaped(<forestry:slabs.fireproof.0:6> * 6, [
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:6>);
recipes.addShaped(<forestry:fences.fireproof.0:6> * 3, [
    [<forestry:planks.fireproof.0:6>, <minecraft:stick>, <forestry:planks.fireproof.0:6>],
    [<forestry:planks.fireproof.0:6>, <minecraft:stick>, <forestry:planks.fireproof.0:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.baobab:0>);
recipes.addShaped(<forestry:stairs.fireproof.baobab:0> * 4, [
    [<forestry:planks.fireproof.0:6>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, null],
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>]
]);

recipes.remove(<forestry:doors.baobab:0>);
recipes.addShaped(<forestry:doors.baobab:0> * 3, [
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, null],
    [<forestry:planks.fireproof.0:6>, <forestry:planks.fireproof.0:6>, null]
]);

recipes.remove(<forestry:planks.0:7>);
recipes.addShaped(<forestry:planks.0:7> * 4, [
    [<forestry:logs.1:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.0:7>);
recipes.addShaped(<forestry:slabs.0:7> * 6, [
    [<forestry:planks.0:7>, <forestry:planks.0:7>, <forestry:planks.0:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:7>);
recipes.addShaped(<forestry:fences.0:7> * 3, [
    [<forestry:planks.0:7>, <minecraft:stick>, <forestry:planks.0:7>],
    [<forestry:planks.0:7>, <minecraft:stick>, <forestry:planks.0:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.sequoia:0>);
recipes.addShaped(<forestry:stairs.sequoia:0> * 4, [
    [<forestry:planks.0:7>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:7>, <forestry:planks.0:7>, null],
    [<forestry:planks.0:7>, <forestry:planks.0:7>, <forestry:planks.0:7>]
]);

recipes.remove(<forestry:doors.sequoia:0>);
recipes.addShaped(<forestry:doors.sequoia:0> * 3, [
    [<forestry:planks.0:7>, <forestry:planks.0:7>, <ore:craftingToolSaw>],
    [<forestry:planks.0:7>, <forestry:planks.0:7>, null],
    [<forestry:planks.0:7>, <forestry:planks.0:7>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:7>);
recipes.addShaped(<forestry:planks.fireproof.0:7> * 4, [
    [<forestry:logs.fireproof.1:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.0:7>);
recipes.addShaped(<forestry:slabs.fireproof.0:7> * 6, [
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:7>);
recipes.addShaped(<forestry:fences.fireproof.0:7> * 3, [
    [<forestry:planks.fireproof.0:7>, <minecraft:stick>, <forestry:planks.fireproof.0:7>],
    [<forestry:planks.fireproof.0:7>, <minecraft:stick>, <forestry:planks.fireproof.0:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.sequoia:0>);
recipes.addShaped(<forestry:stairs.fireproof.sequoia:0> * 4, [
    [<forestry:planks.fireproof.0:7>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, null],
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>]
]);

recipes.remove(<forestry:doors.sequoia:0>);
recipes.addShaped(<forestry:doors.sequoia:0> * 3, [
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, null],
    [<forestry:planks.fireproof.0:7>, <forestry:planks.fireproof.0:7>, null]
]);

recipes.remove(<forestry:planks.0:8>);
recipes.addShaped(<forestry:planks.0:8> * 4, [
    [<forestry:logs.2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:0>);
recipes.addShaped(<forestry:slabs.1:0> * 6, [
    [<forestry:planks.0:8>, <forestry:planks.0:8>, <forestry:planks.0:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:8>);
recipes.addShaped(<forestry:fences.0:8> * 3, [
    [<forestry:planks.0:8>, <minecraft:stick>, <forestry:planks.0:8>],
    [<forestry:planks.0:8>, <minecraft:stick>, <forestry:planks.0:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.kapok:0>);
recipes.addShaped(<forestry:stairs.kapok:0> * 4, [
    [<forestry:planks.0:8>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:8>, <forestry:planks.0:8>, null],
    [<forestry:planks.0:8>, <forestry:planks.0:8>, <forestry:planks.0:8>]
]);

recipes.remove(<forestry:doors.kapok:0>);
recipes.addShaped(<forestry:doors.kapok:0> * 3, [
    [<forestry:planks.0:8>, <forestry:planks.0:8>, <ore:craftingToolSaw>],
    [<forestry:planks.0:8>, <forestry:planks.0:8>, null],
    [<forestry:planks.0:8>, <forestry:planks.0:8>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:8>);
recipes.addShaped(<forestry:planks.fireproof.0:8> * 4, [
    [<forestry:logs.fireproof.2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:0>);
recipes.addShaped(<forestry:slabs.fireproof.1:0> * 6, [
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:8>);
recipes.addShaped(<forestry:fences.fireproof.0:8> * 3, [
    [<forestry:planks.fireproof.0:8>, <minecraft:stick>, <forestry:planks.fireproof.0:8>],
    [<forestry:planks.fireproof.0:8>, <minecraft:stick>, <forestry:planks.fireproof.0:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.kapok:0>);
recipes.addShaped(<forestry:stairs.fireproof.kapok:0> * 4, [
    [<forestry:planks.fireproof.0:8>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, null],
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>]
]);

recipes.remove(<forestry:doors.kapok:0>);
recipes.addShaped(<forestry:doors.kapok:0> * 3, [
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, null],
    [<forestry:planks.fireproof.0:8>, <forestry:planks.fireproof.0:8>, null]
]);

recipes.remove(<forestry:planks.0:9>);
recipes.addShaped(<forestry:planks.0:9> * 4, [
    [<forestry:logs.2:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:1>);
recipes.addShaped(<forestry:slabs.1:1> * 6, [
    [<forestry:planks.0:9>, <forestry:planks.0:9>, <forestry:planks.0:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:9>);
recipes.addShaped(<forestry:fences.0:9> * 3, [
    [<forestry:planks.0:9>, <minecraft:stick>, <forestry:planks.0:9>],
    [<forestry:planks.0:9>, <minecraft:stick>, <forestry:planks.0:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.ebony:0>);
recipes.addShaped(<forestry:stairs.ebony:0> * 4, [
    [<forestry:planks.0:9>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:9>, <forestry:planks.0:9>, null],
    [<forestry:planks.0:9>, <forestry:planks.0:9>, <forestry:planks.0:9>]
]);

recipes.remove(<forestry:doors.ebony:0>);
recipes.addShaped(<forestry:doors.ebony:0> * 3, [
    [<forestry:planks.0:9>, <forestry:planks.0:9>, <ore:craftingToolSaw>],
    [<forestry:planks.0:9>, <forestry:planks.0:9>, null],
    [<forestry:planks.0:9>, <forestry:planks.0:9>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:9>);
recipes.addShaped(<forestry:planks.fireproof.0:9> * 4, [
    [<forestry:logs.fireproof.2:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:1>);
recipes.addShaped(<forestry:slabs.fireproof.1:1> * 6, [
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:9>);
recipes.addShaped(<forestry:fences.fireproof.0:9> * 3, [
    [<forestry:planks.fireproof.0:9>, <minecraft:stick>, <forestry:planks.fireproof.0:9>],
    [<forestry:planks.fireproof.0:9>, <minecraft:stick>, <forestry:planks.fireproof.0:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.ebony:0>);
recipes.addShaped(<forestry:stairs.fireproof.ebony:0> * 4, [
    [<forestry:planks.fireproof.0:9>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, null],
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>]
]);

recipes.remove(<forestry:doors.ebony:0>);
recipes.addShaped(<forestry:doors.ebony:0> * 3, [
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, null],
    [<forestry:planks.fireproof.0:9>, <forestry:planks.fireproof.0:9>, null]
]);

recipes.remove(<forestry:planks.0:10>);
recipes.addShaped(<forestry:planks.0:10> * 4, [
    [<forestry:logs.2:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:2>);
recipes.addShaped(<forestry:slabs.1:2> * 6, [
    [<forestry:planks.0:10>, <forestry:planks.0:10>, <forestry:planks.0:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:10>);
recipes.addShaped(<forestry:fences.0:10> * 3, [
    [<forestry:planks.0:10>, <minecraft:stick>, <forestry:planks.0:10>],
    [<forestry:planks.0:10>, <minecraft:stick>, <forestry:planks.0:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.mahogany:0>);
recipes.addShaped(<forestry:stairs.mahogany:0> * 4, [
    [<forestry:planks.0:10>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:10>, <forestry:planks.0:10>, null],
    [<forestry:planks.0:10>, <forestry:planks.0:10>, <forestry:planks.0:10>]
]);

recipes.remove(<forestry:doors.mahogany:0>);
recipes.addShaped(<forestry:doors.mahogany:0> * 3, [
    [<forestry:planks.0:10>, <forestry:planks.0:10>, <ore:craftingToolSaw>],
    [<forestry:planks.0:10>, <forestry:planks.0:10>, null],
    [<forestry:planks.0:10>, <forestry:planks.0:10>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:10>);
recipes.addShaped(<forestry:planks.fireproof.0:10> * 4, [
    [<forestry:logs.fireproof.2:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:2>);
recipes.addShaped(<forestry:slabs.fireproof.1:2> * 6, [
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:10>);
recipes.addShaped(<forestry:fences.fireproof.0:10> * 3, [
    [<forestry:planks.fireproof.0:10>, <minecraft:stick>, <forestry:planks.fireproof.0:10>],
    [<forestry:planks.fireproof.0:10>, <minecraft:stick>, <forestry:planks.fireproof.0:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.mahogany:0>);
recipes.addShaped(<forestry:stairs.fireproof.mahogany:0> * 4, [
    [<forestry:planks.fireproof.0:10>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, null],
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>]
]);

recipes.remove(<forestry:doors.mahogany:0>);
recipes.addShaped(<forestry:doors.mahogany:0> * 3, [
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, null],
    [<forestry:planks.fireproof.0:10>, <forestry:planks.fireproof.0:10>, null]
]);

recipes.remove(<forestry:planks.0:11>);
recipes.addShaped(<forestry:planks.0:11> * 4, [
    [<forestry:logs.2:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:3>);
recipes.addShaped(<forestry:slabs.1:3> * 6, [
    [<forestry:planks.0:11>, <forestry:planks.0:11>, <forestry:planks.0:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:11>);
recipes.addShaped(<forestry:fences.0:11> * 3, [
    [<forestry:planks.0:11>, <minecraft:stick>, <forestry:planks.0:11>],
    [<forestry:planks.0:11>, <minecraft:stick>, <forestry:planks.0:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.balsa:0>);
recipes.addShaped(<forestry:stairs.balsa:0> * 4, [
    [<forestry:planks.0:11>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:11>, <forestry:planks.0:11>, null],
    [<forestry:planks.0:11>, <forestry:planks.0:11>, <forestry:planks.0:11>]
]);

recipes.remove(<forestry:doors.balsa:0>);
recipes.addShaped(<forestry:doors.balsa:0> * 3, [
    [<forestry:planks.0:11>, <forestry:planks.0:11>, <ore:craftingToolSaw>],
    [<forestry:planks.0:11>, <forestry:planks.0:11>, null],
    [<forestry:planks.0:11>, <forestry:planks.0:11>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:11>);
recipes.addShaped(<forestry:planks.fireproof.0:11> * 4, [
    [<forestry:logs.fireproof.2:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:3>);
recipes.addShaped(<forestry:slabs.fireproof.1:3> * 6, [
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:11>);
recipes.addShaped(<forestry:fences.fireproof.0:11> * 3, [
    [<forestry:planks.fireproof.0:11>, <minecraft:stick>, <forestry:planks.fireproof.0:11>],
    [<forestry:planks.fireproof.0:11>, <minecraft:stick>, <forestry:planks.fireproof.0:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.balsa:0>);
recipes.addShaped(<forestry:stairs.fireproof.balsa:0> * 4, [
    [<forestry:planks.fireproof.0:11>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, null],
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>]
]);

recipes.remove(<forestry:doors.balsa:0>);
recipes.addShaped(<forestry:doors.balsa:0> * 3, [
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, null],
    [<forestry:planks.fireproof.0:11>, <forestry:planks.fireproof.0:11>, null]
]);

recipes.remove(<forestry:planks.0:12>);
recipes.addShaped(<forestry:planks.0:12> * 4, [
    [<forestry:logs.3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:4>);
recipes.addShaped(<forestry:slabs.1:4> * 6, [
    [<forestry:planks.0:12>, <forestry:planks.0:12>, <forestry:planks.0:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:12>);
recipes.addShaped(<forestry:fences.0:12> * 3, [
    [<forestry:planks.0:12>, <minecraft:stick>, <forestry:planks.0:12>],
    [<forestry:planks.0:12>, <minecraft:stick>, <forestry:planks.0:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.willow:0>);
recipes.addShaped(<forestry:stairs.willow:0> * 4, [
    [<forestry:planks.0:12>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:12>, <forestry:planks.0:12>, null],
    [<forestry:planks.0:12>, <forestry:planks.0:12>, <forestry:planks.0:12>]
]);

recipes.remove(<forestry:doors.willow:0>);
recipes.addShaped(<forestry:doors.willow:0> * 3, [
    [<forestry:planks.0:12>, <forestry:planks.0:12>, <ore:craftingToolSaw>],
    [<forestry:planks.0:12>, <forestry:planks.0:12>, null],
    [<forestry:planks.0:12>, <forestry:planks.0:12>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:12>);
recipes.addShaped(<forestry:planks.fireproof.0:12> * 4, [
    [<forestry:logs.fireproof.3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:4>);
recipes.addShaped(<forestry:slabs.fireproof.1:4> * 6, [
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:12>);
recipes.addShaped(<forestry:fences.fireproof.0:12> * 3, [
    [<forestry:planks.fireproof.0:12>, <minecraft:stick>, <forestry:planks.fireproof.0:12>],
    [<forestry:planks.fireproof.0:12>, <minecraft:stick>, <forestry:planks.fireproof.0:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.willow:0>);
recipes.addShaped(<forestry:stairs.fireproof.willow:0> * 4, [
    [<forestry:planks.fireproof.0:12>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, null],
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>]
]);

recipes.remove(<forestry:doors.willow:0>);
recipes.addShaped(<forestry:doors.willow:0> * 3, [
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, null],
    [<forestry:planks.fireproof.0:12>, <forestry:planks.fireproof.0:12>, null]
]);

recipes.remove(<forestry:planks.0:13>);
recipes.addShaped(<forestry:planks.0:13> * 4, [
    [<forestry:logs.3:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:5>);
recipes.addShaped(<forestry:slabs.1:5> * 6, [
    [<forestry:planks.0:13>, <forestry:planks.0:13>, <forestry:planks.0:13>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:13>);
recipes.addShaped(<forestry:fences.0:13> * 3, [
    [<forestry:planks.0:13>, <minecraft:stick>, <forestry:planks.0:13>],
    [<forestry:planks.0:13>, <minecraft:stick>, <forestry:planks.0:13>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.walnut:0>);
recipes.addShaped(<forestry:stairs.walnut:0> * 4, [
    [<forestry:planks.0:13>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:13>, <forestry:planks.0:13>, null],
    [<forestry:planks.0:13>, <forestry:planks.0:13>, <forestry:planks.0:13>]
]);

recipes.remove(<forestry:doors.walnut:0>);
recipes.addShaped(<forestry:doors.walnut:0> * 3, [
    [<forestry:planks.0:13>, <forestry:planks.0:13>, <ore:craftingToolSaw>],
    [<forestry:planks.0:13>, <forestry:planks.0:13>, null],
    [<forestry:planks.0:13>, <forestry:planks.0:13>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:13>);
recipes.addShaped(<forestry:planks.fireproof.0:13> * 4, [
    [<forestry:logs.fireproof.3:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:5>);
recipes.addShaped(<forestry:slabs.fireproof.1:5> * 6, [
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:13>);
recipes.addShaped(<forestry:fences.fireproof.0:13> * 3, [
    [<forestry:planks.fireproof.0:13>, <minecraft:stick>, <forestry:planks.fireproof.0:13>],
    [<forestry:planks.fireproof.0:13>, <minecraft:stick>, <forestry:planks.fireproof.0:13>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.walnut:0>);
recipes.addShaped(<forestry:stairs.fireproof.walnut:0> * 4, [
    [<forestry:planks.fireproof.0:13>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, null],
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>]
]);

recipes.remove(<forestry:doors.walnut:0>);
recipes.addShaped(<forestry:doors.walnut:0> * 3, [
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, null],
    [<forestry:planks.fireproof.0:13>, <forestry:planks.fireproof.0:13>, null]
]);

recipes.remove(<forestry:planks.0:14>);
recipes.addShaped(<forestry:planks.0:14> * 4, [
    [<forestry:logs.3:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:6>);
recipes.addShaped(<forestry:slabs.1:6> * 6, [
    [<forestry:planks.0:14>, <forestry:planks.0:14>, <forestry:planks.0:14>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:14>);
recipes.addShaped(<forestry:fences.0:14> * 3, [
    [<forestry:planks.0:14>, <minecraft:stick>, <forestry:planks.0:14>],
    [<forestry:planks.0:14>, <minecraft:stick>, <forestry:planks.0:14>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.greenheart:0>);
recipes.addShaped(<forestry:stairs.greenheart:0> * 4, [
    [<forestry:planks.0:14>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:14>, <forestry:planks.0:14>, null],
    [<forestry:planks.0:14>, <forestry:planks.0:14>, <forestry:planks.0:14>]
]);

recipes.remove(<forestry:doors.greenheart:0>);
recipes.addShaped(<forestry:doors.greenheart:0> * 3, [
    [<forestry:planks.0:14>, <forestry:planks.0:14>, <ore:craftingToolSaw>],
    [<forestry:planks.0:14>, <forestry:planks.0:14>, null],
    [<forestry:planks.0:14>, <forestry:planks.0:14>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:14>);
recipes.addShaped(<forestry:planks.fireproof.0:14> * 4, [
    [<forestry:logs.fireproof.3:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:6>);
recipes.addShaped(<forestry:slabs.fireproof.1:6> * 6, [
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:14>);
recipes.addShaped(<forestry:fences.fireproof.0:14> * 3, [
    [<forestry:planks.fireproof.0:14>, <minecraft:stick>, <forestry:planks.fireproof.0:14>],
    [<forestry:planks.fireproof.0:14>, <minecraft:stick>, <forestry:planks.fireproof.0:14>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.greenheart:0>);
recipes.addShaped(<forestry:stairs.fireproof.greenheart:0> * 4, [
    [<forestry:planks.fireproof.0:14>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, null],
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>]
]);

recipes.remove(<forestry:doors.greenheart:0>);
recipes.addShaped(<forestry:doors.greenheart:0> * 3, [
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, null],
    [<forestry:planks.fireproof.0:14>, <forestry:planks.fireproof.0:14>, null]
]);

recipes.remove(<forestry:planks.0:15>);
recipes.addShaped(<forestry:planks.0:15> * 4, [
    [<forestry:logs.3:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.1:7>);
recipes.addShaped(<forestry:slabs.1:7> * 6, [
    [<forestry:planks.0:15>, <forestry:planks.0:15>, <forestry:planks.0:15>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.0:15>);
recipes.addShaped(<forestry:fences.0:15> * 3, [
    [<forestry:planks.0:15>, <minecraft:stick>, <forestry:planks.0:15>],
    [<forestry:planks.0:15>, <minecraft:stick>, <forestry:planks.0:15>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.cherry:0>);
recipes.addShaped(<forestry:stairs.cherry:0> * 4, [
    [<forestry:planks.0:15>, <ore:craftingToolSaw>, null],
    [<forestry:planks.0:15>, <forestry:planks.0:15>, null],
    [<forestry:planks.0:15>, <forestry:planks.0:15>, <forestry:planks.0:15>]
]);

recipes.remove(<forestry:doors.cherry:0>);
recipes.addShaped(<forestry:doors.cherry:0> * 3, [
    [<forestry:planks.0:15>, <forestry:planks.0:15>, <ore:craftingToolSaw>],
    [<forestry:planks.0:15>, <forestry:planks.0:15>, null],
    [<forestry:planks.0:15>, <forestry:planks.0:15>, null]
]);

recipes.remove(<forestry:planks.fireproof.0:15>);
recipes.addShaped(<forestry:planks.fireproof.0:15> * 4, [
    [<forestry:logs.fireproof.3:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.1:7>);
recipes.addShaped(<forestry:slabs.fireproof.1:7> * 6, [
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.0:15>);
recipes.addShaped(<forestry:fences.fireproof.0:15> * 3, [
    [<forestry:planks.fireproof.0:15>, <minecraft:stick>, <forestry:planks.fireproof.0:15>],
    [<forestry:planks.fireproof.0:15>, <minecraft:stick>, <forestry:planks.fireproof.0:15>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.cherry:0>);
recipes.addShaped(<forestry:stairs.fireproof.cherry:0> * 4, [
    [<forestry:planks.fireproof.0:15>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, null],
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>]
]);

recipes.remove(<forestry:doors.cherry:0>);
recipes.addShaped(<forestry:doors.cherry:0> * 3, [
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, null],
    [<forestry:planks.fireproof.0:15>, <forestry:planks.fireproof.0:15>, null]
]);

recipes.remove(<forestry:planks.1:0>);
recipes.addShaped(<forestry:planks.1:0> * 4, [
    [<forestry:logs.4>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:0>);
recipes.addShaped(<forestry:slabs.2:0> * 6, [
    [<forestry:planks.1>, <forestry:planks.1>, <forestry:planks.1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:0>);
recipes.addShaped(<forestry:fences.1:0> * 3, [
    [<forestry:planks.1>, <minecraft:stick>, <forestry:planks.1>],
    [<forestry:planks.1>, <minecraft:stick>, <forestry:planks.1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.mahoe:0>);
recipes.addShaped(<forestry:stairs.mahoe:0> * 4, [
    [<forestry:planks.1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1>, <forestry:planks.1>, null],
    [<forestry:planks.1>, <forestry:planks.1>, <forestry:planks.1>]
]);

recipes.remove(<forestry:doors.mahoe:0>);
recipes.addShaped(<forestry:doors.mahoe:0> * 3, [
    [<forestry:planks.1>, <forestry:planks.1>, <ore:craftingToolSaw>],
    [<forestry:planks.1>, <forestry:planks.1>, null],
    [<forestry:planks.1>, <forestry:planks.1>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:0>);
recipes.addShaped(<forestry:planks.fireproof.1:0> * 4, [
    [<forestry:logs.fireproof.4>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:0>);
recipes.addShaped(<forestry:slabs.fireproof.2:0> * 6, [
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:0>);
recipes.addShaped(<forestry:fences.fireproof.1:0> * 3, [
    [<forestry:planks.fireproof.1>, <minecraft:stick>, <forestry:planks.fireproof.1>],
    [<forestry:planks.fireproof.1>, <minecraft:stick>, <forestry:planks.fireproof.1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.mahoe:0>);
recipes.addShaped(<forestry:stairs.fireproof.mahoe:0> * 4, [
    [<forestry:planks.fireproof.1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, null],
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>]
]);

recipes.remove(<forestry:doors.mahoe:0>);
recipes.addShaped(<forestry:doors.mahoe:0> * 3, [
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, null],
    [<forestry:planks.fireproof.1>, <forestry:planks.fireproof.1>, null]
]);

recipes.remove(<forestry:planks.1:1>);
recipes.addShaped(<forestry:planks.1:1> * 4, [
    [<forestry:logs.4:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:1>);
recipes.addShaped(<forestry:slabs.2:1> * 6, [
    [<forestry:planks.1:1>, <forestry:planks.1:1>, <forestry:planks.1:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:1>);
recipes.addShaped(<forestry:fences.1:1> * 3, [
    [<forestry:planks.1:1>, <minecraft:stick>, <forestry:planks.1:1>],
    [<forestry:planks.1:1>, <minecraft:stick>, <forestry:planks.1:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.poplar:0>);
recipes.addShaped(<forestry:stairs.poplar:0> * 4, [
    [<forestry:planks.1:1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:1>, <forestry:planks.1:1>, null],
    [<forestry:planks.1:1>, <forestry:planks.1:1>, <forestry:planks.1:1>]
]);

recipes.remove(<forestry:doors.poplar:0>);
recipes.addShaped(<forestry:doors.poplar:0> * 3, [
    [<forestry:planks.1:1>, <forestry:planks.1:1>, <ore:craftingToolSaw>],
    [<forestry:planks.1:1>, <forestry:planks.1:1>, null],
    [<forestry:planks.1:1>, <forestry:planks.1:1>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:1>);
recipes.addShaped(<forestry:planks.fireproof.1:1> * 4, [
    [<forestry:logs.fireproof.4:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:1>);
recipes.addShaped(<forestry:slabs.fireproof.2:1> * 6, [
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:1>);
recipes.addShaped(<forestry:fences.fireproof.1:1> * 3, [
    [<forestry:planks.fireproof.1:1>, <minecraft:stick>, <forestry:planks.fireproof.1:1>],
    [<forestry:planks.fireproof.1:1>, <minecraft:stick>, <forestry:planks.fireproof.1:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.poplar:0>);
recipes.addShaped(<forestry:stairs.fireproof.poplar:0> * 4, [
    [<forestry:planks.fireproof.1:1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, null],
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>]
]);

recipes.remove(<forestry:doors.poplar:0>);
recipes.addShaped(<forestry:doors.poplar:0> * 3, [
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, null],
    [<forestry:planks.fireproof.1:1>, <forestry:planks.fireproof.1:1>, null]
]);

recipes.remove(<forestry:planks.1:2>);
recipes.addShaped(<forestry:planks.1:2> * 4, [
    [<forestry:logs.4:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:2>);
recipes.addShaped(<forestry:slabs.2:2> * 6, [
    [<forestry:planks.1:2>, <forestry:planks.1:2>, <forestry:planks.1:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:2>);
recipes.addShaped(<forestry:fences.1:2> * 3, [
    [<forestry:planks.1:2>, <minecraft:stick>, <forestry:planks.1:2>],
    [<forestry:planks.1:2>, <minecraft:stick>, <forestry:planks.1:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.palm:0>);
recipes.addShaped(<forestry:stairs.palm:0> * 4, [
    [<forestry:planks.1:2>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:2>, <forestry:planks.1:2>, null],
    [<forestry:planks.1:2>, <forestry:planks.1:2>, <forestry:planks.1:2>]
]);

recipes.remove(<forestry:doors.palm:0>);
recipes.addShaped(<forestry:doors.palm:0> * 3, [
    [<forestry:planks.1:2>, <forestry:planks.1:2>, <ore:craftingToolSaw>],
    [<forestry:planks.1:2>, <forestry:planks.1:2>, null],
    [<forestry:planks.1:2>, <forestry:planks.1:2>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:2>);
recipes.addShaped(<forestry:planks.fireproof.1:2> * 4, [
    [<forestry:logs.fireproof.4:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:2>);
recipes.addShaped(<forestry:slabs.fireproof.2:2> * 6, [
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:2>);
recipes.addShaped(<forestry:fences.fireproof.1:2> * 3, [
    [<forestry:planks.fireproof.1:2>, <minecraft:stick>, <forestry:planks.fireproof.1:2>],
    [<forestry:planks.fireproof.1:2>, <minecraft:stick>, <forestry:planks.fireproof.1:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.palm:0>);
recipes.addShaped(<forestry:stairs.fireproof.palm:0> * 4, [
    [<forestry:planks.fireproof.1:2>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, null],
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>]
]);

recipes.remove(<forestry:doors.palm:0>);
recipes.addShaped(<forestry:doors.palm:0> * 3, [
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, null],
    [<forestry:planks.fireproof.1:2>, <forestry:planks.fireproof.1:2>, null]
]);

recipes.remove(<forestry:planks.1:3>);
recipes.addShaped(<forestry:planks.1:3> * 4, [
    [<forestry:logs.4:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:3>);
recipes.addShaped(<forestry:slabs.2:3> * 6, [
    [<forestry:planks.1:3>, <forestry:planks.1:3>, <forestry:planks.1:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:3>);
recipes.addShaped(<forestry:fences.1:3> * 3, [
    [<forestry:planks.1:3>, <minecraft:stick>, <forestry:planks.1:3>],
    [<forestry:planks.1:3>, <minecraft:stick>, <forestry:planks.1:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.papaya:0>);
recipes.addShaped(<forestry:stairs.papaya:0> * 4, [
    [<forestry:planks.1:3>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:3>, <forestry:planks.1:3>, null],
    [<forestry:planks.1:3>, <forestry:planks.1:3>, <forestry:planks.1:3>]
]);

recipes.remove(<forestry:doors.papaya:0>);
recipes.addShaped(<forestry:doors.papaya:0> * 3, [
    [<forestry:planks.1:3>, <forestry:planks.1:3>, <ore:craftingToolSaw>],
    [<forestry:planks.1:3>, <forestry:planks.1:3>, null],
    [<forestry:planks.1:3>, <forestry:planks.1:3>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:3>);
recipes.addShaped(<forestry:planks.fireproof.1:3> * 4, [
    [<forestry:logs.fireproof.4:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:3>);
recipes.addShaped(<forestry:slabs.fireproof.2:3> * 6, [
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:3>);
recipes.addShaped(<forestry:fences.fireproof.1:3> * 3, [
    [<forestry:planks.fireproof.1:3>, <minecraft:stick>, <forestry:planks.fireproof.1:3>],
    [<forestry:planks.fireproof.1:3>, <minecraft:stick>, <forestry:planks.fireproof.1:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.papaya:0>);
recipes.addShaped(<forestry:stairs.fireproof.papaya:0> * 4, [
    [<forestry:planks.fireproof.1:3>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, null],
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>]
]);

recipes.remove(<forestry:doors.papaya:0>);
recipes.addShaped(<forestry:doors.papaya:0> * 3, [
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, null],
    [<forestry:planks.fireproof.1:3>, <forestry:planks.fireproof.1:3>, null]
]);

recipes.remove(<forestry:planks.1:4>);
recipes.addShaped(<forestry:planks.1:4> * 4, [
    [<forestry:logs.5>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:4>);
recipes.addShaped(<forestry:slabs.2:4> * 6, [
    [<forestry:planks.1:4>, <forestry:planks.1:4>, <forestry:planks.1:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:4>);
recipes.addShaped(<forestry:fences.1:4> * 3, [
    [<forestry:planks.1:4>, <minecraft:stick>, <forestry:planks.1:4>],
    [<forestry:planks.1:4>, <minecraft:stick>, <forestry:planks.1:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.pine:0>);
recipes.addShaped(<forestry:stairs.pine:0> * 4, [
    [<forestry:planks.1:4>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:4>, <forestry:planks.1:4>, null],
    [<forestry:planks.1:4>, <forestry:planks.1:4>, <forestry:planks.1:4>]
]);

recipes.remove(<forestry:doors.pine:0>);
recipes.addShaped(<forestry:doors.pine:0> * 3, [
    [<forestry:planks.1:4>, <forestry:planks.1:4>, <ore:craftingToolSaw>],
    [<forestry:planks.1:4>, <forestry:planks.1:4>, null],
    [<forestry:planks.1:4>, <forestry:planks.1:4>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:4>);
recipes.addShaped(<forestry:planks.fireproof.1:4> * 4, [
    [<forestry:logs.fireproof.5>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:4>);
recipes.addShaped(<forestry:slabs.fireproof.2:4> * 6, [
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:4>);
recipes.addShaped(<forestry:fences.fireproof.1:4> * 3, [
    [<forestry:planks.fireproof.1:4>, <minecraft:stick>, <forestry:planks.fireproof.1:4>],
    [<forestry:planks.fireproof.1:4>, <minecraft:stick>, <forestry:planks.fireproof.1:4>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.pine:0>);
recipes.addShaped(<forestry:stairs.fireproof.pine:0> * 4, [
    [<forestry:planks.fireproof.1:4>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, null],
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>]
]);

recipes.remove(<forestry:doors.pine:0>);
recipes.addShaped(<forestry:doors.pine:0> * 3, [
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, null],
    [<forestry:planks.fireproof.1:4>, <forestry:planks.fireproof.1:4>, null]
]);

recipes.remove(<forestry:planks.1:5>);
recipes.addShaped(<forestry:planks.1:5> * 4, [
    [<forestry:logs.5:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:5>);
recipes.addShaped(<forestry:slabs.2:5> * 6, [
    [<forestry:planks.1:5>, <forestry:planks.1:5>, <forestry:planks.1:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:5>);
recipes.addShaped(<forestry:fences.1:5> * 3, [
    [<forestry:planks.1:5>, <minecraft:stick>, <forestry:planks.1:5>],
    [<forestry:planks.1:5>, <minecraft:stick>, <forestry:planks.1:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.plum:0>);
recipes.addShaped(<forestry:stairs.plum:0> * 4, [
    [<forestry:planks.1:5>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:5>, <forestry:planks.1:5>, null],
    [<forestry:planks.1:5>, <forestry:planks.1:5>, <forestry:planks.1:5>]
]);

recipes.remove(<forestry:doors.plum:0>);
recipes.addShaped(<forestry:doors.plum:0> * 3, [
    [<forestry:planks.1:5>, <forestry:planks.1:5>, <ore:craftingToolSaw>],
    [<forestry:planks.1:5>, <forestry:planks.1:5>, null],
    [<forestry:planks.1:5>, <forestry:planks.1:5>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:5>);
recipes.addShaped(<forestry:planks.fireproof.1:5> * 4, [
    [<forestry:logs.fireproof.5:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:5>);
recipes.addShaped(<forestry:slabs.fireproof.2:5> * 6, [
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:5>);
recipes.addShaped(<forestry:fences.fireproof.1:5> * 3, [
    [<forestry:planks.fireproof.1:5>, <minecraft:stick>, <forestry:planks.fireproof.1:5>],
    [<forestry:planks.fireproof.1:5>, <minecraft:stick>, <forestry:planks.fireproof.1:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.plum:0>);
recipes.addShaped(<forestry:stairs.fireproof.plum:0> * 4, [
    [<forestry:planks.fireproof.1:5>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, null],
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>]
]);

recipes.remove(<forestry:doors.plum:0>);
recipes.addShaped(<forestry:doors.plum:0> * 3, [
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, null],
    [<forestry:planks.fireproof.1:5>, <forestry:planks.fireproof.1:5>, null]
]);

recipes.remove(<forestry:planks.1:6>);
recipes.addShaped(<forestry:planks.1:6> * 4, [
    [<forestry:logs.5:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:6>);
recipes.addShaped(<forestry:slabs.2:6> * 6, [
    [<forestry:planks.1:6>, <forestry:planks.1:6>, <forestry:planks.1:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:6>);
recipes.addShaped(<forestry:fences.1:6> * 3, [
    [<forestry:planks.1:6>, <minecraft:stick>, <forestry:planks.1:6>],
    [<forestry:planks.1:6>, <minecraft:stick>, <forestry:planks.1:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.maple:0>);
recipes.addShaped(<forestry:stairs.maple:0> * 4, [
    [<forestry:planks.1:6>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:6>, <forestry:planks.1:6>, null],
    [<forestry:planks.1:6>, <forestry:planks.1:6>, <forestry:planks.1:6>]
]);

recipes.remove(<forestry:doors.maple:0>);
recipes.addShaped(<forestry:doors.maple:0> * 3, [
    [<forestry:planks.1:6>, <forestry:planks.1:6>, <ore:craftingToolSaw>],
    [<forestry:planks.1:6>, <forestry:planks.1:6>, null],
    [<forestry:planks.1:6>, <forestry:planks.1:6>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:6>);
recipes.addShaped(<forestry:planks.fireproof.1:6> * 4, [
    [<forestry:logs.fireproof.5:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:6>);
recipes.addShaped(<forestry:slabs.fireproof.2:6> * 6, [
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:6>);
recipes.addShaped(<forestry:fences.fireproof.1:6> * 3, [
    [<forestry:planks.fireproof.1:6>, <minecraft:stick>, <forestry:planks.fireproof.1:6>],
    [<forestry:planks.fireproof.1:6>, <minecraft:stick>, <forestry:planks.fireproof.1:6>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.maple:0>);
recipes.addShaped(<forestry:stairs.fireproof.maple:0> * 4, [
    [<forestry:planks.fireproof.1:6>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, null],
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>]
]);

recipes.remove(<forestry:doors.maple:0>);
recipes.addShaped(<forestry:doors.maple:0> * 3, [
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, null],
    [<forestry:planks.fireproof.1:6>, <forestry:planks.fireproof.1:6>, null]
]);

recipes.remove(<forestry:planks.1:7>);
recipes.addShaped(<forestry:planks.1:7> * 4, [
    [<forestry:logs.5:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.2:7>);
recipes.addShaped(<forestry:slabs.2:7> * 6, [
    [<forestry:planks.1:7>, <forestry:planks.1:7>, <forestry:planks.1:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:7>);
recipes.addShaped(<forestry:fences.1:7> * 3, [
    [<forestry:planks.1:7>, <minecraft:stick>, <forestry:planks.1:7>],
    [<forestry:planks.1:7>, <minecraft:stick>, <forestry:planks.1:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.citrus:0>);
recipes.addShaped(<forestry:stairs.citrus:0> * 4, [
    [<forestry:planks.1:7>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:7>, <forestry:planks.1:7>, null],
    [<forestry:planks.1:7>, <forestry:planks.1:7>, <forestry:planks.1:7>]
]);

recipes.remove(<forestry:doors.citrus:0>);
recipes.addShaped(<forestry:doors.citrus:0> * 3, [
    [<forestry:planks.1:7>, <forestry:planks.1:7>, <ore:craftingToolSaw>],
    [<forestry:planks.1:7>, <forestry:planks.1:7>, null],
    [<forestry:planks.1:7>, <forestry:planks.1:7>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:7>);
recipes.addShaped(<forestry:planks.fireproof.1:7> * 4, [
    [<forestry:logs.fireproof.5:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.2:7>);
recipes.addShaped(<forestry:slabs.fireproof.2:7> * 6, [
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:7>);
recipes.addShaped(<forestry:fences.fireproof.1:7> * 3, [
    [<forestry:planks.fireproof.1:7>, <minecraft:stick>, <forestry:planks.fireproof.1:7>],
    [<forestry:planks.fireproof.1:7>, <minecraft:stick>, <forestry:planks.fireproof.1:7>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.citrus:0>);
recipes.addShaped(<forestry:stairs.fireproof.citrus:0> * 4, [
    [<forestry:planks.fireproof.1:7>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, null],
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>]
]);

recipes.remove(<forestry:doors.citrus:0>);
recipes.addShaped(<forestry:doors.citrus:0> * 3, [
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, null],
    [<forestry:planks.fireproof.1:7>, <forestry:planks.fireproof.1:7>, null]
]);

recipes.remove(<forestry:planks.1:8>);
recipes.addShaped(<forestry:planks.1:8> * 4, [
    [<forestry:logs.6>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.3:0>);
recipes.addShaped(<forestry:slabs.3:0> * 6, [
    [<forestry:planks.1:8>, <forestry:planks.1:8>, <forestry:planks.1:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:8>);
recipes.addShaped(<forestry:fences.1:8> * 3, [
    [<forestry:planks.1:8>, <minecraft:stick>, <forestry:planks.1:8>],
    [<forestry:planks.1:8>, <minecraft:stick>, <forestry:planks.1:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.giganteum:0>);
recipes.addShaped(<forestry:stairs.giganteum:0> * 4, [
    [<forestry:planks.1:8>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:8>, <forestry:planks.1:8>, null],
    [<forestry:planks.1:8>, <forestry:planks.1:8>, <forestry:planks.1:8>]
]);

recipes.remove(<forestry:doors.giganteum:0>);
recipes.addShaped(<forestry:doors.giganteum:0> * 3, [
    [<forestry:planks.1:8>, <forestry:planks.1:8>, <ore:craftingToolSaw>],
    [<forestry:planks.1:8>, <forestry:planks.1:8>, null],
    [<forestry:planks.1:8>, <forestry:planks.1:8>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:8>);
recipes.addShaped(<forestry:planks.fireproof.1:8> * 4, [
    [<forestry:logs.fireproof.6>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.3:0>);
recipes.addShaped(<forestry:slabs.fireproof.3:0> * 6, [
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:8>);
recipes.addShaped(<forestry:fences.fireproof.1:8> * 3, [
    [<forestry:planks.fireproof.1:8>, <minecraft:stick>, <forestry:planks.fireproof.1:8>],
    [<forestry:planks.fireproof.1:8>, <minecraft:stick>, <forestry:planks.fireproof.1:8>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.giganteum:0>);
recipes.addShaped(<forestry:stairs.fireproof.giganteum:0> * 4, [
    [<forestry:planks.fireproof.1:8>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, null],
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>]
]);

recipes.remove(<forestry:doors.giganteum:0>);
recipes.addShaped(<forestry:doors.giganteum:0> * 3, [
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, null],
    [<forestry:planks.fireproof.1:8>, <forestry:planks.fireproof.1:8>, null]
]);

recipes.remove(<forestry:planks.1:9>);
recipes.addShaped(<forestry:planks.1:9> * 4, [
    [<forestry:logs.6:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.3:1>);
recipes.addShaped(<forestry:slabs.3:1> * 6, [
    [<forestry:planks.1:9>, <forestry:planks.1:9>, <forestry:planks.1:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:9>);
recipes.addShaped(<forestry:fences.1:9> * 3, [
    [<forestry:planks.1:9>, <minecraft:stick>, <forestry:planks.1:9>],
    [<forestry:planks.1:9>, <minecraft:stick>, <forestry:planks.1:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.ipe:0>);
recipes.addShaped(<forestry:stairs.ipe:0> * 4, [
    [<forestry:planks.1:9>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:9>, <forestry:planks.1:9>, null],
    [<forestry:planks.1:9>, <forestry:planks.1:9>, <forestry:planks.1:9>]
]);

recipes.remove(<forestry:doors.ipe:0>);
recipes.addShaped(<forestry:doors.ipe:0> * 3, [
    [<forestry:planks.1:9>, <forestry:planks.1:9>, <ore:craftingToolSaw>],
    [<forestry:planks.1:9>, <forestry:planks.1:9>, null],
    [<forestry:planks.1:9>, <forestry:planks.1:9>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:9>);
recipes.addShaped(<forestry:planks.fireproof.1:9> * 4, [
    [<forestry:logs.fireproof.6:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.3:1>);
recipes.addShaped(<forestry:slabs.fireproof.3:1> * 6, [
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:9>);
recipes.addShaped(<forestry:fences.fireproof.1:9> * 3, [
    [<forestry:planks.fireproof.1:9>, <minecraft:stick>, <forestry:planks.fireproof.1:9>],
    [<forestry:planks.fireproof.1:9>, <minecraft:stick>, <forestry:planks.fireproof.1:9>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.ipe:0>);
recipes.addShaped(<forestry:stairs.fireproof.ipe:0> * 4, [
    [<forestry:planks.fireproof.1:9>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, null],
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>]
]);

recipes.remove(<forestry:doors.ipe:0>);
recipes.addShaped(<forestry:doors.ipe:0> * 3, [
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, null],
    [<forestry:planks.fireproof.1:9>, <forestry:planks.fireproof.1:9>, null]
]);

recipes.remove(<forestry:planks.1:10>);
recipes.addShaped(<forestry:planks.1:10> * 4, [
    [<forestry:logs.6:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.3:2>);
recipes.addShaped(<forestry:slabs.3:2> * 6, [
    [<forestry:planks.1:10>, <forestry:planks.1:10>, <forestry:planks.1:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:10>);
recipes.addShaped(<forestry:fences.1:10> * 3, [
    [<forestry:planks.1:10>, <minecraft:stick>, <forestry:planks.1:10>],
    [<forestry:planks.1:10>, <minecraft:stick>, <forestry:planks.1:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.padauk:0>);
recipes.addShaped(<forestry:stairs.padauk:0> * 4, [
    [<forestry:planks.1:10>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:10>, <forestry:planks.1:10>, null],
    [<forestry:planks.1:10>, <forestry:planks.1:10>, <forestry:planks.1:10>]
]);

recipes.remove(<forestry:doors.padauk:0>);
recipes.addShaped(<forestry:doors.padauk:0> * 3, [
    [<forestry:planks.1:10>, <forestry:planks.1:10>, <ore:craftingToolSaw>],
    [<forestry:planks.1:10>, <forestry:planks.1:10>, null],
    [<forestry:planks.1:10>, <forestry:planks.1:10>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:10>);
recipes.addShaped(<forestry:planks.fireproof.1:10> * 4, [
    [<forestry:logs.fireproof.6:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.3:2>);
recipes.addShaped(<forestry:slabs.fireproof.3:2> * 6, [
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:10>);
recipes.addShaped(<forestry:fences.fireproof.1:10> * 3, [
    [<forestry:planks.fireproof.1:10>, <minecraft:stick>, <forestry:planks.fireproof.1:10>],
    [<forestry:planks.fireproof.1:10>, <minecraft:stick>, <forestry:planks.fireproof.1:10>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.padauk:0>);
recipes.addShaped(<forestry:stairs.fireproof.padauk:0> * 4, [
    [<forestry:planks.fireproof.1:10>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, null],
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>]
]);

recipes.remove(<forestry:doors.padauk:0>);
recipes.addShaped(<forestry:doors.padauk:0> * 3, [
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, null],
    [<forestry:planks.fireproof.1:10>, <forestry:planks.fireproof.1:10>, null]
]);

recipes.remove(<forestry:planks.1:11>);
recipes.addShaped(<forestry:planks.1:11> * 4, [
    [<forestry:logs.6:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.3:3>);
recipes.addShaped(<forestry:slabs.3:3> * 6, [
    [<forestry:planks.1:11>, <forestry:planks.1:11>, <forestry:planks.1:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:11>);
recipes.addShaped(<forestry:fences.1:11> * 3, [
    [<forestry:planks.1:11>, <minecraft:stick>, <forestry:planks.1:11>],
    [<forestry:planks.1:11>, <minecraft:stick>, <forestry:planks.1:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.cocobolo:0>);
recipes.addShaped(<forestry:stairs.cocobolo:0> * 4, [
    [<forestry:planks.1:11>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:11>, <forestry:planks.1:11>, null],
    [<forestry:planks.1:11>, <forestry:planks.1:11>, <forestry:planks.1:11>]
]);

recipes.remove(<forestry:doors.cocobolo:0>);
recipes.addShaped(<forestry:doors.cocobolo:0> * 3, [
    [<forestry:planks.1:11>, <forestry:planks.1:11>, <ore:craftingToolSaw>],
    [<forestry:planks.1:11>, <forestry:planks.1:11>, null],
    [<forestry:planks.1:11>, <forestry:planks.1:11>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:11>);
recipes.addShaped(<forestry:planks.fireproof.1:11> * 4, [
    [<forestry:logs.fireproof.6:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.3:3>);
recipes.addShaped(<forestry:slabs.fireproof.3:3> * 6, [
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:11>);
recipes.addShaped(<forestry:fences.fireproof.1:11> * 3, [
    [<forestry:planks.fireproof.1:11>, <minecraft:stick>, <forestry:planks.fireproof.1:11>],
    [<forestry:planks.fireproof.1:11>, <minecraft:stick>, <forestry:planks.fireproof.1:11>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.cocobolo:0>);
recipes.addShaped(<forestry:stairs.fireproof.cocobolo:0> * 4, [
    [<forestry:planks.fireproof.1:11>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, null],
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>]
]);

recipes.remove(<forestry:doors.cocobolo:0>);
recipes.addShaped(<forestry:doors.cocobolo:0> * 3, [
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, null],
    [<forestry:planks.fireproof.1:11>, <forestry:planks.fireproof.1:11>, null]
]);

recipes.remove(<forestry:planks.1:12>);
recipes.addShaped(<forestry:planks.1:12> * 4, [
    [<forestry:logs.7>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.3:4>);
recipes.addShaped(<forestry:slabs.3:4> * 6, [
    [<forestry:planks.1:12>, <forestry:planks.1:12>, <forestry:planks.1:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.1:12>);
recipes.addShaped(<forestry:fences.1:12> * 3, [
    [<forestry:planks.1:12>, <minecraft:stick>, <forestry:planks.1:12>],
    [<forestry:planks.1:12>, <minecraft:stick>, <forestry:planks.1:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.zebrawood:0>);
recipes.addShaped(<forestry:stairs.zebrawood:0> * 4, [
    [<forestry:planks.1:12>, <ore:craftingToolSaw>, null],
    [<forestry:planks.1:12>, <forestry:planks.1:12>, null],
    [<forestry:planks.1:12>, <forestry:planks.1:12>, <forestry:planks.1:12>]
]);

recipes.remove(<forestry:doors.zebrawood:0>);
recipes.addShaped(<forestry:doors.zebrawood:0> * 3, [
    [<forestry:planks.1:12>, <forestry:planks.1:12>, <ore:craftingToolSaw>],
    [<forestry:planks.1:12>, <forestry:planks.1:12>, null],
    [<forestry:planks.1:12>, <forestry:planks.1:12>, null]
]);

recipes.remove(<forestry:planks.fireproof.1:12>);
recipes.addShaped(<forestry:planks.fireproof.1:12> * 4, [
    [<forestry:logs.fireproof.7>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.fireproof.3:4>);
recipes.addShaped(<forestry:slabs.fireproof.3:4> * 6, [
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.fireproof.1:12>);
recipes.addShaped(<forestry:fences.fireproof.1:12> * 3, [
    [<forestry:planks.fireproof.1:12>, <minecraft:stick>, <forestry:planks.fireproof.1:12>],
    [<forestry:planks.fireproof.1:12>, <minecraft:stick>, <forestry:planks.fireproof.1:12>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.fireproof.zebrawood:0>);
recipes.addShaped(<forestry:stairs.fireproof.zebrawood:0> * 4, [
    [<forestry:planks.fireproof.1:12>, <ore:craftingToolSaw>, null],
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, null],
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>]
]);

recipes.remove(<forestry:doors.zebrawood:0>);
recipes.addShaped(<forestry:doors.zebrawood:0> * 3, [
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, <ore:craftingToolSaw>],
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, null],
    [<forestry:planks.fireproof.1:12>, <forestry:planks.fireproof.1:12>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:0>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:0> * 4, [
    [<forestry:logs.vanilla.fireproof.0>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:0>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:0> * 6, [
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:0>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0>],
    [<forestry:planks.vanilla.fireproof.0>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.oak:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.oak:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, null],
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>]
]);

recipes.remove(<minecraft:wooden_door:0>);
recipes.addShaped(<minecraft:wooden_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, null],
    [<forestry:planks.vanilla.fireproof.0>, <forestry:planks.vanilla.fireproof.0>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:1>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:1> * 4, [
    [<forestry:logs.vanilla.fireproof.0:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:1>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:1> * 6, [
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:1>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:1> * 3, [
    [<forestry:planks.vanilla.fireproof.0:1>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:1>],
    [<forestry:planks.vanilla.fireproof.0:1>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:1>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.spruce:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.spruce:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0:1>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, null],
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>]
]);

recipes.remove(<minecraft:spruce_door:0>);
recipes.addShaped(<minecraft:spruce_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, null],
    [<forestry:planks.vanilla.fireproof.0:1>, <forestry:planks.vanilla.fireproof.0:1>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:2>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:2> * 4, [
    [<forestry:logs.vanilla.fireproof.0:2>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:2>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:2> * 6, [
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:2>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:2> * 3, [
    [<forestry:planks.vanilla.fireproof.0:2>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:2>],
    [<forestry:planks.vanilla.fireproof.0:2>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:2>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.birch:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.birch:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0:2>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, null],
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>]
]);

recipes.remove(<minecraft:birch_door:0>);
recipes.addShaped(<minecraft:birch_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, null],
    [<forestry:planks.vanilla.fireproof.0:2>, <forestry:planks.vanilla.fireproof.0:2>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:3>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:3> * 4, [
    [<forestry:logs.vanilla.fireproof.0:3>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:3>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:3> * 6, [
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:3>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:3> * 3, [
    [<forestry:planks.vanilla.fireproof.0:3>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:3>],
    [<forestry:planks.vanilla.fireproof.0:3>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:3>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.jungle:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.jungle:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0:3>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, null],
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>]
]);

recipes.remove(<minecraft:jungle_door:0>);
recipes.addShaped(<minecraft:jungle_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, null],
    [<forestry:planks.vanilla.fireproof.0:3>, <forestry:planks.vanilla.fireproof.0:3>, null]
]);

recipes.remove(<forestry:planks.vanilla.fireproof.0:5>);
recipes.addShaped(<forestry:planks.vanilla.fireproof.0:5> * 4, [
    [<forestry:logs.vanilla.fireproof.1:1>, <ore:craftingToolSaw>, null]
]);

recipes.remove(<forestry:slabs.vanilla.fireproof.0:5>);
recipes.addShaped(<forestry:slabs.vanilla.fireproof.0:5> * 6, [
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:fences.vanilla.fireproof.0:5>);
recipes.addShaped(<forestry:fences.vanilla.fireproof.0:5> * 3, [
    [<forestry:planks.vanilla.fireproof.0:5>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:5>],
    [<forestry:planks.vanilla.fireproof.0:5>, <minecraft:stick>, <forestry:planks.vanilla.fireproof.0:5>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<forestry:stairs.vanilla.fireproof.dark_oak:0>);
recipes.addShaped(<forestry:stairs.vanilla.fireproof.dark_oak:0> * 4, [
    [<forestry:planks.vanilla.fireproof.0:5>, <ore:craftingToolSaw>, null],
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, null],
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>]
]);

recipes.remove(<minecraft:dark_oak_door:0>);
recipes.addShaped(<minecraft:dark_oak_door:0> * 3, [
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, <ore:craftingToolSaw>],
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, null],
    [<forestry:planks.vanilla.fireproof.0:5>, <forestry:planks.vanilla.fireproof.0:5>, null]
]);

// ---------------------------------------- the plain door routes the removes above had eaten
// The six doors are vanilla items, and vanilla makes each one from six of its own planks in the
// standard two-by-three door shape, three doors per craft. Removing by output took that route away as
// well as the fireproof one, so it is written back here unchanged - no saw, because GregTech's own
// hard-wood pass only touches planks. The fireproof recipes above stay next to them, which is what the
// mod ships.
recipes.addShaped(<minecraft:wooden_door:0> * 3, [
    [<minecraft:planks:0>, <minecraft:planks:0>, null],
    [<minecraft:planks:0>, <minecraft:planks:0>, null],
    [<minecraft:planks:0>, <minecraft:planks:0>, null]
]);
recipes.addShaped(<minecraft:spruce_door:0> * 3, [
    [<minecraft:planks:1>, <minecraft:planks:1>, null],
    [<minecraft:planks:1>, <minecraft:planks:1>, null],
    [<minecraft:planks:1>, <minecraft:planks:1>, null]
]);
recipes.addShaped(<minecraft:birch_door:0> * 3, [
    [<minecraft:planks:2>, <minecraft:planks:2>, null],
    [<minecraft:planks:2>, <minecraft:planks:2>, null],
    [<minecraft:planks:2>, <minecraft:planks:2>, null]
]);
recipes.addShaped(<minecraft:jungle_door:0> * 3, [
    [<minecraft:planks:3>, <minecraft:planks:3>, null],
    [<minecraft:planks:3>, <minecraft:planks:3>, null],
    [<minecraft:planks:3>, <minecraft:planks:3>, null]
]);
recipes.addShaped(<minecraft:acacia_door:0> * 3, [
    [<minecraft:planks:4>, <minecraft:planks:4>, null],
    [<minecraft:planks:4>, <minecraft:planks:4>, null],
    [<minecraft:planks:4>, <minecraft:planks:4>, null]
]);
recipes.addShaped(<minecraft:dark_oak_door:0> * 3, [
    [<minecraft:planks:5>, <minecraft:planks:5>, null],
    [<minecraft:planks:5>, <minecraft:planks:5>, null],
    [<minecraft:planks:5>, <minecraft:planks:5>, null]
]);

