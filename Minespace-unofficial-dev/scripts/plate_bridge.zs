#priority 790
// The nine GregTech plates that Gregicality mis-pointed at Galacticraft's compressed plates.
//
// ---------------------------------------------------------------------------------------------
// The bug, in one sentence: `OreDictUnifier.get(OrePrefix.plate, material)` returns the *first*
// stack in the ore dictionary name, Galacticraft and Galaxy Space register their compressed plate
// under GregTech's plain name (`plateCopper` first held `galacticraftcore:basic_item:6`), so every
// recipe Gregicality generated for these nine metals was written against the compressed plate.
//
// Two halves, fixed in two places:
//
//   * the machine side - the bender, forge hammer, extruder, cutting saw, alloy smelter, fluid
//     solidifier and the two magnetic-plate smelting recipes - is in
//     MinespaceCompressedPlateGuard, which now re-points those outputs at the plain plate instead
//     of deleting them (it deletes only what it cannot re-point, so a compressed plate still has
//     exactly one producer: the implosion compressor).
//
//   * the crafting-table side is here, because those recipes are mod-registered Forge
//     ShapedOreRecipes that only CraftTweaker can take out of the registry.
//
// ---------------------------------------------------------------------------------------------
// What the table used to do, and what it does now.
//
// Gregicality's own `plate_x` / `flatten_plate_x` recipes (the GT5 shape: a hard hammer over two
// ingots in a column) also wrote their output through OreDictUnifier, so for these nine metals the
// crafting grid handed out the *compressed* plate - two ingots and a hammer for the dense tier
// that is supposed to need the implosion compressor. Part 1 removes them; the compressor is the
// only route to a compressed plate again.
//
// That left the plain plate with no source at all, so Part 2 gives it back: the same recipe
// Gregicality meant to write, at the same cost and shape as every other metal in the pack
// (compare `gtadditions:plate_aluminium`, which was never hijacked and is what this mirrors).
// `<ore:ingotX>` is GregTech's ingot - oredict.zs left the ingot names clean - and the output is
// the exact GregTech plate, the same id integration.zs and the GC/GS scripts already build with.

// ------------------------------------------------------------------------- 1. no table-made dense plate
// (a no-op for any metal whose generator recipe is already gone, so the list is the same nine either way)
recipes.remove(<galacticraftcore:basic_item:6>);                   // compressed copper
recipes.remove(<galacticraftcore:basic_item:7>);                   // compressed tin
recipes.remove(<galacticraftcore:basic_item:9>);                   // compressed steel
recipes.remove(<galacticraftcore:basic_item:10>);                  // compressed bronze
recipes.remove(<galacticraftcore:basic_item:11>);                  // compressed iron
recipes.remove(<galacticraftplanets:item_basic_mars:5>);           // compressed desh
recipes.remove(<galacticraftplanets:item_basic_asteroids:6>);      // compressed titanium
recipes.remove(<galaxyspace:compressed_plates:1>);                 // compressed cobalt
recipes.remove(<galaxyspace:compressed_plates:3>);                 // compressed nickel

// --------------------------------------------------------------------------- 2. the plain plate again
// hammer + two ingots in a column -> one GregTech plate; the ids in the comment are the ore
// dictionary names these plates carry (plateCopper, plateTin, plateSteel, plateBronze, plateIron,
// plateDesh, plateTitanium, plateCobalt, plateNickel).
recipes.addShaped(<gregtech:meta_item_1:12018>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotCopper>],
    [<ore:ingotCopper>]
]);
recipes.addShaped(<gregtech:meta_item_1:12071>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotTin>],
    [<ore:ingotTin>]
]);
recipes.addShaped(<gregtech:meta_item_1:12184>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotSteel>],
    [<ore:ingotSteel>]
]);
recipes.addShaped(<gregtech:meta_item_1:12095>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotBronze>],
    [<ore:ingotBronze>]
]);
recipes.addShaped(<gregtech:meta_item_1:12033>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotIron>],
    [<ore:ingotIron>]
]);
recipes.addShaped(<gregtech:meta_item_1:12000>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotDesh>],
    [<ore:ingotDesh>]
]);
recipes.addShaped(<gregtech:meta_item_1:12072>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotTitanium>],
    [<ore:ingotTitanium>]
]);
recipes.addShaped(<gregtech:meta_item_1:12017>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotCobalt>],
    [<ore:ingotCobalt>]
]);
recipes.addShaped(<gregtech:meta_item_1:12044>, [
    [<ore:craftingToolHardHammer>],
    [<ore:ingotNickel>],
    [<ore:ingotNickel>]
]);
