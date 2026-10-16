#priority 697
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Forestry's machine-side items: the ones that belong to the machines and the apiary, gregified.
//
// The owner's note on Forestry: it is not the pack's exception any more. Items a Forestry *machine* makes
// are to be made more complex with GregTech items in them, and everything else gets the ordinary
// crafting-table treatment. This file is the workbench half of that - the items that belong to the
// machines and the apiary keep their recipe, shape and output and gain GregTech items in the slots the
// pattern already leaves empty:
//
//   * a file and a hard hammer where the object is shaped (the grafter), and a saw for the scoop;
//   * a **screw** and a screwdriver for the pulsating mesh - a mesh is held together with screws, and a
//     screw has to come off a GT lathe;
//   * a screwdriver for the worktable and the three special chests, which are boxes and are screwed
//     together;
//   * a screwdriver and an **LV circuit** for the habitat locator, which is an electronic locator;
//   * a hard hammer for each of the four apiarist armour pieces, woven silk beaten into shape.
//
// No ingredient is dropped and no count is lowered. Ingredients Forestry stores as a list of
// alternatives are written back as the ore name they came from (`blockGlass`, `treeSapling`,
// `chestWood`), never as the first member of the list.
//
// Deliberately left alone: the eight beekeeper bags (woven cloth and string - no GregTech tool fits),
// the untreated and impregnated frames and the genetic filter (their grids are completely full, so there
// is nowhere to put a tool without dropping one of their own parts, which would make them cheaper),
// the greenhouse and climatiser deconstruction recipes (they take a machine apart), and the peat bog and
// farm block placement flips.

recipes.remove(<forestry:grafter:0>);
recipes.addShaped(<forestry:grafter:0>, [
    [<ore:craftingToolFile>, <ore:craftingToolHardHammer>, <gregtech:meta_item_1:10095>],
    [null, <minecraft:stick>, null],
    [<minecraft:stick>, null, null]
]);

recipes.remove(<forestry:tree_chest:0>);
recipes.addShaped(<forestry:tree_chest:0>, [
    [<ore:craftingToolScrewdriver>, <ore:blockGlass>, null],
    [<ore:treeSapling>, <ore:chestWood>, <ore:treeSapling>],
    [<ore:treeSapling>, <ore:treeSapling>, <ore:treeSapling>]
]);

recipes.remove(<forestry:butterfly_chest:0>);
recipes.addShaped(<forestry:butterfly_chest:0>, [
    [<ore:craftingToolScrewdriver>, <ore:blockGlass>, null],
    [<forestry:butterfly_ge>, <ore:chestWood>, <forestry:butterfly_ge>],
    [<forestry:butterfly_ge>, <forestry:butterfly_ge>, <forestry:butterfly_ge>]
]);

recipes.remove(<forestry:worktable:0>);
recipes.addShaped(<forestry:worktable:0>, [
    [<ore:bookEmpty>, <minecraft:crafting_table>, <ore:chestWood>],
    [<ore:craftingToolScrewdriver>, null, null]
]);

recipes.remove(<forestry:apiarist_helmet:0>);
recipes.addShaped(<forestry:apiarist_helmet:0>, [
    [<forestry:crafting_material:3>, <forestry:crafting_material:3>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, <ore:craftingToolHardHammer>, <forestry:crafting_material:3>]
]);

recipes.remove(<forestry:apiarist_chest:0>);
recipes.addShaped(<forestry:apiarist_chest:0>, [
    [<forestry:crafting_material:3>, <ore:craftingToolHardHammer>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, <forestry:crafting_material:3>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, <forestry:crafting_material:3>, <forestry:crafting_material:3>]
]);

recipes.remove(<forestry:apiarist_legs:0>);
recipes.addShaped(<forestry:apiarist_legs:0>, [
    [<forestry:crafting_material:3>, <forestry:crafting_material:3>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, <ore:craftingToolHardHammer>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, null, <forestry:crafting_material:3>]
]);

recipes.remove(<forestry:apiarist_boots:0>);
recipes.addShaped(<forestry:apiarist_boots:0>, [
    [<forestry:crafting_material:3>, <ore:craftingToolHardHammer>, <forestry:crafting_material:3>],
    [<forestry:crafting_material:3>, null, <forestry:crafting_material:3>]
]);

recipes.remove(<forestry:habitat_locator:0>);
recipes.addShaped(<forestry:habitat_locator:0>, [
    [<ore:craftingToolScrewdriver>, <gregtech:meta_item_1:10095>, <ore:circuitBasic>],
    [<gregtech:meta_item_1:10095>, <minecraft:redstone>, <gregtech:meta_item_1:10095>],
    [null, <gregtech:meta_item_1:10095>, null]
]);

recipes.remove(<forestry:scoop:0>);
recipes.addShaped(<forestry:scoop:0>, [
    [<minecraft:stick>, <ore:wool>, <minecraft:stick>],
    [<minecraft:stick>, <minecraft:stick>, <minecraft:stick>],
    [<ore:craftingToolSaw>, <minecraft:stick>, null]
]);

recipes.remove(<forestry:crafting_material:1>);
recipes.addShaped(<forestry:crafting_material:1>, [
    [<forestry:propolis:2>, <ore:screwSteel>, <forestry:propolis:2>],
    [<ore:craftingToolScrewdriver>, <forestry:propolis:2>, null],
    [<forestry:propolis:2>, null, <forestry:propolis:2>]
]);

recipes.remove(<forestry:bee_chest:0>);
recipes.addShaped(<forestry:bee_chest:0>, [
    [<ore:craftingToolScrewdriver>, <ore:blockGlass>, null],
    [<ore:beeComb>, <ore:chestWood>, <ore:beeComb>],
    [<ore:beeComb>, <ore:beeComb>, <ore:beeComb>]
]);

