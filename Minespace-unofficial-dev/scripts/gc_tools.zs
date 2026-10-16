#priority 795
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Galacticraft's heavy steel tools and armour: the crafting-table pass.
//
// The owner's rule for anything made on the crafting table: keep the recipe and the output, but re-cost
// it the way GTNH does - GregTech materials where the real object is metal, and GregTech *tools* where
// the real object has to be filed, hammered or sawn into shape.
//
// Two changes per recipe:
//
//   * Galacticraft's compressed steel plate (`basic_item:9`, which this pack already makes in the GT
//     implosion compressor from two steel plates and four explosives) becomes GregTech's **dense steel
//     plate**. A heavy-duty tool or a suit of heavy armour really is made of the densest plate the pack
//     has; one dense plate is nine steel plates against the compressed one's two, so this is strictly
//     dearer - it never makes a recipe easier, which is the owner's standing instruction.
//   * the free grid slots take the tools the object needs: a **file** and a **hard hammer** for the
//     bladed and headed tools, a hard hammer alone for the armour plates, a **saw** for the steel pole,
//     and a **wrench** with a hammer or screwdriver for the wrench, the landing pad and the buggy wheels.
//
// No ingredient is dropped and no count is lowered; the shapes are Galacticraft's own, read out of the
// live recipe registry. Galacticraft's *machines* (oxygen concentrator, air lock frames, lighting
// panels, thrusters, oxygen tanks and so on) are deliberately left alone: their steel plate is
// Galacticraft's own compressed plate and GregTech already makes it, and deciding that a machine
// housing should take nine steel plates per slot is a different balance call from the one asked for here.

recipes.remove(<galacticraftcore:steel_axe:0>);
recipes.addShaped(<galacticraftcore:steel_axe:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:craftingToolHardHammer>, <minecraft:stick:0>, <ore:plateDenseSteel>],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_axe:0>);
recipes.addShaped(<galacticraftcore:steel_axe:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:craftingToolFile>],
    [<ore:plateDenseSteel>, <minecraft:stick:0>, <ore:craftingToolHardHammer>],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_helmet:0>);
recipes.addShaped(<galacticraftcore:steel_helmet:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, <ore:craftingToolHardHammer>, <ore:plateDenseSteel>]
]);

recipes.remove(<galacticraftcore:steel_hoe:0>);
recipes.addShaped(<galacticraftcore:steel_hoe:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:craftingToolFile>],
    [<ore:craftingToolHardHammer>, <minecraft:stick:0>, null],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_leggings:0>);
recipes.addShaped(<galacticraftcore:steel_leggings:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, <ore:craftingToolHardHammer>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, null, <ore:plateDenseSteel>]
]);

recipes.remove(<galacticraftcore:steel_chestplate:0>);
recipes.addShaped(<galacticraftcore:steel_chestplate:0>, [
    [<ore:plateDenseSteel>, <ore:craftingToolHardHammer>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>]
]);

recipes.remove(<galacticraftcore:standard_wrench:0>);
recipes.addShaped(<galacticraftcore:standard_wrench:0>, [
    [<ore:craftingToolHardHammer>, <ore:craftingToolFile>, <ore:plateDenseSteel>],
    [null, <galacticraftcore:basic_item:10>, null],
    [<galacticraftcore:basic_item:10>, null, null]
]);

recipes.remove(<galacticraftcore:steel_hoe:0>);
recipes.addShaped(<galacticraftcore:steel_hoe:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:craftingToolHardHammer>, <minecraft:stick:0>, null],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_pole:0>);
recipes.addShaped(<galacticraftcore:steel_pole:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:craftingToolSaw>, null, null]
]);

recipes.remove(<galacticraftcore:steel_sword:0>);
recipes.addShaped(<galacticraftcore:steel_sword:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseSteel>, <ore:craftingToolHardHammer>],
    [null, <ore:plateDenseSteel>, null],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:landing_pad:1>);
recipes.addShaped(<galacticraftcore:landing_pad:1>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<minecraft:iron_block:0>, <minecraft:iron_block:0>, <minecraft:iron_block:0>],
    [<ore:craftingToolWrench>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<galacticraftcore:steel_pickaxe:0>);
recipes.addShaped(<galacticraftcore:steel_pickaxe:0>, [
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>],
    [<ore:craftingToolFile>, <minecraft:stick:0>, <ore:craftingToolHardHammer>],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_shovel:0>);
recipes.addShaped(<galacticraftcore:steel_shovel:0>, [
    [<ore:craftingToolFile>, <ore:plateDenseSteel>, <ore:craftingToolHardHammer>],
    [null, <minecraft:stick:0>, null],
    [null, <minecraft:stick:0>, null]
]);

recipes.remove(<galacticraftcore:steel_boots:0>);
recipes.addShaped(<galacticraftcore:steel_boots:0>, [
    [<ore:plateDenseSteel>, <ore:craftingToolHardHammer>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, null, <ore:plateDenseSteel>]
]);

recipes.remove(<galacticraftcore:buggymat:0>);
recipes.addShaped(<galacticraftcore:buggymat:0>, [
    [<ore:craftingToolWrench>, <minecraft:leather:0>, <ore:craftingToolScrewdriver>],
    [<minecraft:leather:0>, <ore:plateDenseSteel>, <minecraft:leather:0>],
    [null, <minecraft:leather:0>, null]
]);

recipes.remove(<galacticraftcore:buggymat:1>);
recipes.addShaped(<galacticraftcore:buggymat:1>, [
    [<ore:craftingToolWrench>, <ore:craftingToolScrewdriver>, <ore:plateDenseSteel>],
    [null, <galacticraftcore:basic_item:11>, <ore:plateDenseSteel>],
    [<ore:plateDenseSteel>, <ore:plateDenseSteel>, <ore:plateDenseSteel>]
]);

