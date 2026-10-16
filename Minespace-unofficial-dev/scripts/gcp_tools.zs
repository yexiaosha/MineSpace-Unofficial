#priority 794
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Galacticraft-Planets' tools and armour: titanium from dense plates, desh from plates.
//
// The same crafting-table pass the Galacticraft core tools got in zzzz_minespace_gc_tools.zs, for the
// two metal families of the asteroids and Mars:
//
//   * **titanium** - the tools and armour were built from Galacticraft's compressed titanium plate
//     (`item_basic_asteroids:6`, which this pack makes in the GT implosion compressor from two titanium
//     plates and explosives). They take GregTech's **dense titanium plate** now: one dense plate is nine
//     titanium plates against the compressed one's two, so the recipe is strictly dearer, never easier.
//   * **desh** - those tools were three plain GregTech desh *ingots* and a handle, because the material
//     re-point had already made them GregTech's. A tool head is not an ingot: the ingots become GregTech
//     **desh plates**, one ingot each, but they have to come off a bending machine first.
//
// Both families also take the GregTech tools the object needs, in slots the pattern already leaves empty:
// a file and a hard hammer for the bladed and headed tools, a hard hammer alone for the armour plates.
// No ingredient is dropped and no count is lowered; the shapes are Galacticraft-Planets' own, read out of
// the live recipe registry.

recipes.remove(<galacticraftplanets:desh_chestplate:0>);
recipes.addShaped(<galacticraftplanets:desh_chestplate:0>, [
    [<ore:plateDesh>, <ore:craftingToolHardHammer>, <ore:plateDesh>],
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>],
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>]
]);

recipes.remove(<galacticraftplanets:titanium_axe:0>);
recipes.addShaped(<galacticraftplanets:titanium_axe:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:craftingToolHardHammer>, <minecraft:iron_ingot:0>, <ore:plateDenseTitanium>],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:titanium_shovel:0>);
recipes.addShaped(<galacticraftplanets:titanium_shovel:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseTitanium>, <ore:craftingToolHardHammer>],
    [null, <minecraft:iron_ingot:0>, null],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:desh_pick:0>);
recipes.addShaped(<galacticraftplanets:desh_pick:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>],
    [<ore:craftingToolFile>, <galacticraftplanets:item_basic_mars:1>, <ore:craftingToolHardHammer>],
    [null, <galacticraftplanets:item_basic_mars:1>, null]
]);

recipes.remove(<galacticraftplanets:desh_sword:0>);
recipes.addShaped(<galacticraftplanets:desh_sword:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <galacticraftplanets:item_basic_mars:1>],
    [<ore:craftingToolFile>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<galacticraftplanets:desh_hoe:0>);
recipes.addShaped(<galacticraftplanets:desh_hoe:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <galacticraftplanets:item_basic_mars:1>],
    [<ore:craftingToolFile>, <galacticraftplanets:item_basic_mars:1>, <ore:craftingToolHardHammer>]
]);

recipes.remove(<galacticraftplanets:titanium_chestplate:0>);
recipes.addShaped(<galacticraftplanets:titanium_chestplate:0>, [
    [<ore:plateDenseTitanium>, <ore:craftingToolHardHammer>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>]
]);

recipes.remove(<galacticraftplanets:titanium_helmet:0>);
recipes.addShaped(<galacticraftplanets:titanium_helmet:0>, [
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, <ore:craftingToolHardHammer>, <ore:plateDenseTitanium>]
]);

recipes.remove(<galacticraftplanets:titanium_pickaxe:0>);
recipes.addShaped(<galacticraftplanets:titanium_pickaxe:0>, [
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:craftingToolFile>, <minecraft:iron_ingot:0>, <ore:craftingToolHardHammer>],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:titanium_leggings:0>);
recipes.addShaped(<galacticraftplanets:titanium_leggings:0>, [
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, <ore:craftingToolHardHammer>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, null, <ore:plateDenseTitanium>]
]);

recipes.remove(<galacticraftplanets:titanium_axe:0>);
recipes.addShaped(<galacticraftplanets:titanium_axe:0>, [
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:craftingToolFile>],
    [<ore:plateDenseTitanium>, <minecraft:iron_ingot:0>, <ore:craftingToolHardHammer>],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:desh_boots:0>);
recipes.addShaped(<galacticraftplanets:desh_boots:0>, [
    [<ore:plateDesh>, <ore:craftingToolHardHammer>, <ore:plateDesh>],
    [<ore:plateDesh>, null, <ore:plateDesh>]
]);

recipes.remove(<galacticraftplanets:desh_axe:0>);
recipes.addShaped(<galacticraftplanets:desh_axe:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <galacticraftplanets:item_basic_mars:1>],
    [<ore:plateDesh>, <galacticraftplanets:item_basic_mars:1>, <ore:craftingToolFile>],
    [<ore:craftingToolHardHammer>, null, null]
]);

recipes.remove(<galacticraftplanets:titanium_hoe:0>);
recipes.addShaped(<galacticraftplanets:titanium_hoe:0>, [
    [<ore:plateDenseTitanium>, <ore:plateDenseTitanium>, <ore:craftingToolFile>],
    [<ore:craftingToolHardHammer>, <minecraft:iron_ingot:0>, null],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:desh_hoe:0>);
recipes.addShaped(<galacticraftplanets:desh_hoe:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <ore:craftingToolFile>],
    [<galacticraftplanets:item_basic_mars:1>, <ore:craftingToolHardHammer>, <galacticraftplanets:item_basic_mars:1>]
]);

recipes.remove(<galacticraftplanets:titanium_sword:0>);
recipes.addShaped(<galacticraftplanets:titanium_sword:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseTitanium>, <ore:craftingToolHardHammer>],
    [null, <ore:plateDenseTitanium>, null],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:titanium_boots:0>);
recipes.addShaped(<galacticraftplanets:titanium_boots:0>, [
    [<ore:plateDenseTitanium>, <ore:craftingToolHardHammer>, <ore:plateDenseTitanium>],
    [<ore:plateDenseTitanium>, null, <ore:plateDenseTitanium>]
]);

recipes.remove(<galacticraftplanets:titanium_hoe:0>);
recipes.addShaped(<galacticraftplanets:titanium_hoe:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseTitanium>, <ore:plateDenseTitanium>],
    [<ore:craftingToolHardHammer>, <minecraft:iron_ingot:0>, null],
    [null, <minecraft:iron_ingot:0>, null]
]);

recipes.remove(<galacticraftplanets:desh_axe:0>);
recipes.addShaped(<galacticraftplanets:desh_axe:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>],
    [<galacticraftplanets:item_basic_mars:1>, <ore:craftingToolFile>, <galacticraftplanets:item_basic_mars:1>],
    [<ore:craftingToolHardHammer>, null, null]
]);

recipes.remove(<galacticraftplanets:desh_helmet:0>);
recipes.addShaped(<galacticraftplanets:desh_helmet:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>],
    [<ore:plateDesh>, <ore:craftingToolHardHammer>, <ore:plateDesh>]
]);

recipes.remove(<galacticraftplanets:desh_leggings:0>);
recipes.addShaped(<galacticraftplanets:desh_leggings:0>, [
    [<ore:plateDesh>, <ore:plateDesh>, <ore:plateDesh>],
    [<ore:plateDesh>, <ore:craftingToolHardHammer>, <ore:plateDesh>],
    [<ore:plateDesh>, null, <ore:plateDesh>]
]);

recipes.remove(<galacticraftplanets:desh_spade:0>);
recipes.addShaped(<galacticraftplanets:desh_spade:0>, [
    [<ore:plateDesh>, <galacticraftplanets:item_basic_mars:1>, <galacticraftplanets:item_basic_mars:1>],
    [<ore:craftingToolFile>, <ore:craftingToolHardHammer>, null]
]);

