#priority 790
// GregTech's own gear crafting lanes, for the three metals Gregicality had pointed at another mod's
// gear - the gear half of what plate_bridge.zs does for the plates.
//
// The bug: Galacticraft / Galaxy Space own the plain `plateX` names and Forestry / AE2 own gear
// names, and Gregicality writes its recipes through `OreDictUnifier.get(prefix, material)`, which
// answers with the *first* stack in the name. So the gear recipes it generated for copper, tin and
// bronze were written against `forestry:gear_*` and the wooden one against AE2's gear, which left
// `gregtech:meta_item_2:26018 / 26071 / 26095 / 26196` with **no producer at all** - a live probe
// (2026-10-13) counted zero for those four against four for `gearIron`. oredict.zs now hands the four
// names to GregTech and MinespaceMaterialRepoint re-points the machine lanes that made the mod gear,
// so the extruder / alloy smelter / fluid solidifier routes come back. What is left is the crafting
// table: Gregicality's own `gear_<material>` recipe for iron survived as `gtadditions:gear_iron`
// (four sticks and four plates around a wrench), and the three hijacked copies of it had been deleted
// as "a machine makes the same item". They are written back here, in GregTech's own shape.
//
// The wooden gear is the one that needs a different answer, and that is GregTech's own doing: its
// gear generator only writes the extruder / alloy smelter / fluid solidifier lanes for an
// `IngotMaterial` (wood is not one) and the crafting lane needs double plates (there is no
// `doublePlateWood`), so GT itself ships **no** recipe for `gearWood` at all - the item exists but
// nothing makes it. The pack's own saw-and-file recipe in ae2_base.zs is therefore what produces it
// now, with its output moved to GregTech's gear: same four sticks, same saw and file, same cost as
// the AE2 gear it used to make.

// ---- copper, tin and bronze: GregTech's own shape, exactly as `gtadditions:gear_iron` uses it
// (four sticks at the corners, four plates at the edges, a wrench in the middle - the input list of
// that recipe is `stickIron, plateIron, stickIron, plateIron, craftingToolWrench, plateIron,
// stickIron, plateIron, stickIron`, and prefix 14 is the stick).
recipes.addShaped(<gregtech:meta_item_2:26018>, [
    [<gregtech:meta_item_1:14018>, <gregtech:meta_item_1:12018>, <gregtech:meta_item_1:14018>],
    [<gregtech:meta_item_1:12018>, <ore:craftingToolWrench>,     <gregtech:meta_item_1:12018>],
    [<gregtech:meta_item_1:14018>, <gregtech:meta_item_1:12018>, <gregtech:meta_item_1:14018>]
]);
recipes.addShaped(<gregtech:meta_item_2:26071>, [
    [<gregtech:meta_item_1:14071>, <gregtech:meta_item_1:12071>, <gregtech:meta_item_1:14071>],
    [<gregtech:meta_item_1:12071>, <ore:craftingToolWrench>,     <gregtech:meta_item_1:12071>],
    [<gregtech:meta_item_1:14071>, <gregtech:meta_item_1:12071>, <gregtech:meta_item_1:14071>]
]);
recipes.addShaped(<gregtech:meta_item_2:26095>, [
    [<gregtech:meta_item_1:14095>, <gregtech:meta_item_1:12095>, <gregtech:meta_item_1:14095>],
    [<gregtech:meta_item_1:12095>, <ore:craftingToolWrench>,     <gregtech:meta_item_1:12095>],
    [<gregtech:meta_item_1:14095>, <gregtech:meta_item_1:12095>, <gregtech:meta_item_1:14095>]
]);
