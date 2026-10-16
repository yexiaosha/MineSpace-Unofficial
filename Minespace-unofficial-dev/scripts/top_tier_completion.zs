#priority 795
// ==================================================== UXV: completed, not retired
//
// The owner's call on 2026-10-15: UXV and MAX must both be playable, so the tier that 6cn retired is
// completed instead. What was measured, and what this file does with it:
//
// * 56 crafting recipes - 46 single-block UXV machines, the 8 sized UXV energy hatches and the 2 UXV
//   converters - all need `gregtech:machine:3243`, the UXV Machine Hull;
// * the hull has no recipe anywhere, because Gregicality's own hull registration
//   (`MachineCraftingRecipes`) writes `ga_hull_ulv` .. `ga_hull_umv` and stops one tier short (6cn);
// * everything else the tier needs does exist. Read out of the UXV machine recipes themselves: the
//   tier's circuit is `gtadditions:ga_meta_item:32339`, its casing `gtadditions:ga_machine_casing:4`,
//   its cable `cableGtQuadruple(Neutronium)` (`gregtech:ga_cable:7993`), and the machines' recipes use
//   `gregtech:ga_cable:5993` (the 1x form of the same material).
//
// The owner's call on the routes (2026-10-15, 6cr): the top tiers keep the **machine** route and lose
// the crafting-table one, imitating what the tiers below do. Measured in the finished registries: every
// hull from UHV down to UMV has an assembler recipe of two tier cables plus the tier's casing, every
// tier casing has one of eight tier plates plus a programmed circuit, and GT's own `hull.max` has an
// assembler recipe only. So the two recipes this file writes for UXV are assembler recipes in exactly
// those shapes, and the same pair of recipes is removed from the table for the four tiers below.

recipes.remove(<gregtech:machine:3239>);
recipes.remove(<gregtech:machine:3240>);
recipes.remove(<gregtech:machine:3241>);
recipes.remove(<gregtech:machine:3242>);
recipes.remove(<gtadditions:ga_machine_casing:0>);
recipes.remove(<gtadditions:ga_machine_casing:1>);
recipes.remove(<gtadditions:ga_machine_casing:2>);
recipes.remove(<gtadditions:ga_machine_casing:3>);
recipes.remove(<gtadditions:ga_fusion_casing:0>);
recipes.remove(<gtadditions:ga_armor:8>);

// The UXV hull, in the shape `hull.uhv` .. `hull.umv` use: two of the tier's cables over the tier's
// casing, at the same EU/t and duration the other tiers' recipes carry (measured: EUt 16, 50 ticks).
// Neutronium is the tier's own material (its cable is what the UXV converters are built from).
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:ga_cable:7993> * 2, <gtadditions:ga_machine_casing:4>)
    .outputs(<gregtech:machine:3243>)
    .duration(50).EUt(16)
    .buildAndRegister();

// The UXV machine casing, in the shape `ga_casing_uhv` .. `ga_casing_umv` use: eight of the tier's
// plates around the same programmed circuit, and the same EU/t and duration as the tiers below.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateNeutronium> * 8)
    .circuit(0)
    .outputs(<gtadditions:ga_machine_casing:4>)
    .duration(50).EUt(16)
    .buildAndRegister();

// --- and the tier's two base energy hatches, which are the last items that show up in JEI with no
// --- recipe at all (the *sized* ones have recipes and the UHV..UMV base pairs do too; measured in the
// --- tier-gate sweep, 6cr). Same shape the tier's sized input hatch uses: the tier's cable and the
// --- tier's hull.
recipes.addShaped(<gregtech:machine:4029>, [
    [null, null, null],
    [<gregtech:ga_cable:5993>, <gregtech:machine:3243>, null],
    [null, null, null]
]);
recipes.addShaped(<gregtech:machine:4034>, [
    [null, null, null],
    [<gregtech:ga_cable:5993>, <gregtech:machine:3243>, null],
    [null, null, null]
]);

// ==================================================== the UHV..UXV battery buffers and chargers
//
// The last producer-less family in the stack: Gregicality registers four battery-buffer sizes and one
// charger per tier for UHV..UXV (25 machines) and nothing makes any of them - no table recipe, no
// machine-map recipe. GT's own family stops at UV and then jumps to MAX, which is why those 25 are the
// only buffers missing at these tiers.
//
// Written in GT's own shape, read out of `battery_buffer_max_1x1` and the MAX charger (see
// TJ-MIGRATION-PLAN.md 6co): a battery buffer is
//
//     cable / chestWood / cable
//     cable / hull      / cable
//
// with the cable stepping through the tier material's sizes as the buffer's slot count grows (GT's own
// progression: its 1-slot buffer takes the 1x cable, its 16-slot the largest), and the charger is that
// same block with a third row of the tier's circuits. The tier's material is the one Gregicality's own
// hull recipes use for it (UHV TungstenTitaniumCarbide, UEV Pikyonium, UIV Cinobite, UMV
// NaquadriaticTaranium, UXV Neutronium - the first four read out of `MachineCraftingRecipes`, the last
// out of the UXV machines' own recipes), and the circuits are the tier's converter circuits, measured
// from `convert_gteu.<tier>.1` in the finished registry.

val Chest = <ore:chestWood>;

// --- UHV
recipes.addShaped(<gregtech:machine:4145>, [
    [<ore:cableGtSingleTungstenTitaniumCarbide>, Chest, <ore:cableGtSingleTungstenTitaniumCarbide>],
    [<ore:cableGtSingleTungstenTitaniumCarbide>, <gregtech:machine:3239>, <ore:cableGtSingleTungstenTitaniumCarbide>]
]);
recipes.addShaped(<gregtech:machine:4146>, [
    [<ore:cableGtQuadrupleTungstenTitaniumCarbide>, Chest, <ore:cableGtQuadrupleTungstenTitaniumCarbide>],
    [<ore:cableGtQuadrupleTungstenTitaniumCarbide>, <gregtech:machine:3239>, <ore:cableGtQuadrupleTungstenTitaniumCarbide>]
]);
recipes.addShaped(<gregtech:machine:4147>, [
    [<ore:cableGtOctalTungstenTitaniumCarbide>, Chest, <ore:cableGtOctalTungstenTitaniumCarbide>],
    [<ore:cableGtOctalTungstenTitaniumCarbide>, <gregtech:machine:3239>, <ore:cableGtOctalTungstenTitaniumCarbide>]
]);
recipes.addShaped(<gregtech:machine:4148>, [
    [<ore:cableGtHexTungstenTitaniumCarbide>, Chest, <ore:cableGtHexTungstenTitaniumCarbide>],
    [<ore:cableGtHexTungstenTitaniumCarbide>, <gregtech:machine:3239>, <ore:cableGtHexTungstenTitaniumCarbide>]
]);
recipes.addShaped(<gregtech:machine:4149>, [
    [<ore:cableGtHexTungstenTitaniumCarbide>, Chest, <ore:cableGtHexTungstenTitaniumCarbide>],
    [<ore:cableGtHexTungstenTitaniumCarbide>, <gregtech:machine:3239>, <ore:cableGtHexTungstenTitaniumCarbide>],
    [<gregtech:meta_item_2:32501>, <gregtech:meta_item_2:32501>, <gregtech:meta_item_2:32501>]
]);

// --- UEV
recipes.addShaped(<gregtech:machine:4150>, [
    [<ore:cableGtSinglePikyonium>, Chest, <ore:cableGtSinglePikyonium>],
    [<ore:cableGtSinglePikyonium>, <gregtech:machine:3240>, <ore:cableGtSinglePikyonium>]
]);
recipes.addShaped(<gregtech:machine:4151>, [
    [<ore:cableGtQuadruplePikyonium>, Chest, <ore:cableGtQuadruplePikyonium>],
    [<ore:cableGtQuadruplePikyonium>, <gregtech:machine:3240>, <ore:cableGtQuadruplePikyonium>]
]);
recipes.addShaped(<gregtech:machine:4152>, [
    [<ore:cableGtOctalPikyonium>, Chest, <ore:cableGtOctalPikyonium>],
    [<ore:cableGtOctalPikyonium>, <gregtech:machine:3240>, <ore:cableGtOctalPikyonium>]
]);
recipes.addShaped(<gregtech:machine:4153>, [
    [<ore:cableGtHexPikyonium>, Chest, <ore:cableGtHexPikyonium>],
    [<ore:cableGtHexPikyonium>, <gregtech:machine:3240>, <ore:cableGtHexPikyonium>]
]);
recipes.addShaped(<gregtech:machine:4154>, [
    [<ore:cableGtHexPikyonium>, Chest, <ore:cableGtHexPikyonium>],
    [<ore:cableGtHexPikyonium>, <gregtech:machine:3240>, <ore:cableGtHexPikyonium>],
    [<gtadditions:ga_meta_item:32232>, <gtadditions:ga_meta_item:32232>, <gtadditions:ga_meta_item:32232>]
]);

// --- UIV
recipes.addShaped(<gregtech:machine:4155>, [
    [<ore:cableGtSingleCinobite>, Chest, <ore:cableGtSingleCinobite>],
    [<ore:cableGtSingleCinobite>, <gregtech:machine:3241>, <ore:cableGtSingleCinobite>]
]);
recipes.addShaped(<gregtech:machine:4156>, [
    [<ore:cableGtQuadrupleCinobite>, Chest, <ore:cableGtQuadrupleCinobite>],
    [<ore:cableGtQuadrupleCinobite>, <gregtech:machine:3241>, <ore:cableGtQuadrupleCinobite>]
]);
recipes.addShaped(<gregtech:machine:4157>, [
    [<ore:cableGtOctalCinobite>, Chest, <ore:cableGtOctalCinobite>],
    [<ore:cableGtOctalCinobite>, <gregtech:machine:3241>, <ore:cableGtOctalCinobite>]
]);
recipes.addShaped(<gregtech:machine:4158>, [
    [<ore:cableGtHexCinobite>, Chest, <ore:cableGtHexCinobite>],
    [<ore:cableGtHexCinobite>, <gregtech:machine:3241>, <ore:cableGtHexCinobite>]
]);
recipes.addShaped(<gregtech:machine:4159>, [
    [<ore:cableGtHexCinobite>, Chest, <ore:cableGtHexCinobite>],
    [<ore:cableGtHexCinobite>, <gregtech:machine:3241>, <ore:cableGtHexCinobite>],
    [<gtadditions:ga_meta_item:32337>, <gtadditions:ga_meta_item:32337>, <gtadditions:ga_meta_item:32337>]
]);

// --- UMV
recipes.addShaped(<gregtech:machine:4160>, [
    [<ore:cableGtSingleNaquadriaticTaranium>, Chest, <ore:cableGtSingleNaquadriaticTaranium>],
    [<ore:cableGtSingleNaquadriaticTaranium>, <gregtech:machine:3242>, <ore:cableGtSingleNaquadriaticTaranium>]
]);
recipes.addShaped(<gregtech:machine:4161>, [
    [<ore:cableGtQuadrupleNaquadriaticTaranium>, Chest, <ore:cableGtQuadrupleNaquadriaticTaranium>],
    [<ore:cableGtQuadrupleNaquadriaticTaranium>, <gregtech:machine:3242>, <ore:cableGtQuadrupleNaquadriaticTaranium>]
]);
recipes.addShaped(<gregtech:machine:4162>, [
    [<ore:cableGtOctalNaquadriaticTaranium>, Chest, <ore:cableGtOctalNaquadriaticTaranium>],
    [<ore:cableGtOctalNaquadriaticTaranium>, <gregtech:machine:3242>, <ore:cableGtOctalNaquadriaticTaranium>]
]);
recipes.addShaped(<gregtech:machine:4163>, [
    [<ore:cableGtHexNaquadriaticTaranium>, Chest, <ore:cableGtHexNaquadriaticTaranium>],
    [<ore:cableGtHexNaquadriaticTaranium>, <gregtech:machine:3242>, <ore:cableGtHexNaquadriaticTaranium>]
]);
recipes.addShaped(<gregtech:machine:4164>, [
    [<ore:cableGtHexNaquadriaticTaranium>, Chest, <ore:cableGtHexNaquadriaticTaranium>],
    [<ore:cableGtHexNaquadriaticTaranium>, <gregtech:machine:3242>, <ore:cableGtHexNaquadriaticTaranium>],
    [<gtadditions:ga_meta_item:32338>, <gtadditions:ga_meta_item:32338>, <gtadditions:ga_meta_item:32338>]
]);

// --- UXV
recipes.addShaped(<gregtech:machine:4165>, [
    [<ore:cableGtSingleNeutronium>, Chest, <ore:cableGtSingleNeutronium>],
    [<ore:cableGtSingleNeutronium>, <gregtech:machine:3243>, <ore:cableGtSingleNeutronium>]
]);
recipes.addShaped(<gregtech:machine:4166>, [
    [<ore:cableGtQuadrupleNeutronium>, Chest, <ore:cableGtQuadrupleNeutronium>],
    [<ore:cableGtQuadrupleNeutronium>, <gregtech:machine:3243>, <ore:cableGtQuadrupleNeutronium>]
]);
recipes.addShaped(<gregtech:machine:4167>, [
    [<ore:cableGtOctalNeutronium>, Chest, <ore:cableGtOctalNeutronium>],
    [<ore:cableGtOctalNeutronium>, <gregtech:machine:3243>, <ore:cableGtOctalNeutronium>]
]);
recipes.addShaped(<gregtech:machine:4168>, [
    [<ore:cableGtHexNeutronium>, Chest, <ore:cableGtHexNeutronium>],
    [<ore:cableGtHexNeutronium>, <gregtech:machine:3243>, <ore:cableGtHexNeutronium>]
]);
recipes.addShaped(<gregtech:machine:4169>, [
    [<ore:cableGtHexNeutronium>, Chest, <ore:cableGtHexNeutronium>],
    [<ore:cableGtHexNeutronium>, <gregtech:machine:3243>, <ore:cableGtHexNeutronium>],
    [<gtadditions:ga_meta_item:32339>, <gtadditions:ga_meta_item:32339>, <gtadditions:ga_meta_item:32339>]
]);
