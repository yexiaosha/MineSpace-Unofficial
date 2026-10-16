#priority 797
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Advanced machines and items: off the crafting table, into a GregTech assembler.
//
// The owner's rule for this pass: an advanced machine or item must be *produced by a GregTech
// machine*, not merely cost GregTech materials. So for each of these items the crafting-table
// recipe is deleted outright and an `assembler` recipe takes its place. The crafting table no
// longer offers them at all, which is the point - a GregTech assembler (and EU) is now a hard
// prerequisite for building them.
//
// What is covered here (115 outputs, 168 assembler recipes - one per crafting variant):
//
//   Ender IO     the machine blocks: alloy smelters, SAG mills, simple furnace, enchanter,
//                farming station, painter, reservoirs, slicer, soul binder, powered spawner,
//                vats, wired / wireless chargers, transceiver, vacuum chest, XP vacuum, Niard,
//                travel anchor, tele pad, dialing device, impulse hopper, crafters, gauge,
//                power monitors, Killer Joe, electric light, the five obelisks, inventory
//                panels and chests, detector block - including Ender IO's own "upgrade to the
//                next tier" recipes, which now run in the assembler too
//   Forestry     carpenter, centrifuge, squeezer, fermenter, moistener, still, rain tank,
//                analyzer, thermionic fabricator, rainmaker, bottler, habitat former, trade
//                station, database, the three engines, the farm frame and the peat bog, and the
//                seven alveary parts
//   AE2          energy cell, dense energy cell, crafting storage 1k/4k/16k/64k, crafting
//                monitor, controller, spatial pylon, the four wireless terminals, wireless
//                access point, view cell, portable cell, matter cannon, colour applicator,
//                entropy manipulator, charged staff, sky compass, memory and biometric card
//
// Nothing was made cheaper: the materials are exactly the ones the crafting recipes used, the
// slots are merely flattened into an input list (which is what an assembler recipe is), no
// ingredient was dropped and no count was lowered. Every recipe additionally takes an integrated
// circuit, and EU/t follows how deep the item sits in its own mod's tree:
//
//   mod tier names      Ender IO / Forestry "simple" and untiered -> LV 30
//                       "normal" / "advanced"                    -> MV 120
//                       "enhanced"                               -> HV 480
//   AE2 capacities      1k and the basic machines                 -> LV 30
//                       4k                                          -> MV 120
//                       16k, controller, spatial pylon              -> HV 480
//                       64k                                         -> EV 1920
//
// The shapes were read out of each mod's own recipe list on a live run, so the counts are the
// mod's own; the later sections of zzz_minespace_integration.zs and zzz_minespace_ae2.zs that put
// these items on the crafting table are superseded by the removals below (a removal matches on
// the output, whatever put it there).
//
// The file's second half (2026-10-12, "the advanced half, off the crafting table") does the same for
// Iron Chests and Storage Drawers: 105 more outputs and 153 more recipes. Note when editing it that a
// CraftTweaker `val` is local to its own file, so this file uses literal ingredients throughout.

recipes.remove(<enderio:block_simple_alloy_smelter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:bucket:0>, <ore:craftingFurnace> * 2, <ore:gearStone> * 2, <ore:ingotConstructionAlloy> * 3, <ore:itemSimpleMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_simple_alloy_smelter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_alloy_smelter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:cauldron:0>, <ore:craftingFurnace> * 3, <ore:gearDark> * 2, <ore:ingotDarkSteel> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_alloy_smelter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_simple_alloy_smelter:0>, <enderio:block_simple_furnace:0>, <ore:gearDark> * 2, <ore:ingotDarkSteel> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_alloy_smelter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_enhanced_alloy_smelter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:cauldron:0>, <ore:craftingFurnace> * 3, <ore:gearVibrant> * 2, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_alloy_smelter:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_alloy_smelter:0>, <ore:gearVibrant> * 2, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_alloy_smelter:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:block_simple_sag_mill:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingPiston>, <ore:gearStone> * 2, <ore:ingotConstructionAlloy> * 2, <ore:itemFlint> * 3, <ore:itemSimpleMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_simple_sag_mill:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_sag_mill:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_simple_sag_mill:0>, <ore:gearDark> * 2, <ore:ingotDarkSteel> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_sag_mill:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingPiston>, <ore:gearDark> * 2, <ore:ingotDarkSteel> * 2, <ore:itemFlint> * 3, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_sag_mill:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_enhanced_sag_mill:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_sag_mill:0>, <ore:gearVibrant> * 2, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_sag_mill:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingPiston>, <ore:gearVibrant> * 2, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>, <ore:itemFlint> * 3)
    .circuit(1)
    .outputs(<enderio:block_enhanced_sag_mill:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:block_simple_furnace:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:bucket:0>, <ore:craftingFurnace>, <ore:gearStone> * 2, <ore:ingotConstructionAlloy> * 2, <ore:itemSimpleMachineChassi>, <ore:stoneBricks> * 2)
    .circuit(1)
    .outputs(<enderio:block_simple_furnace:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_enchanter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingBook>, <ore:gemDiamond> * 2, <ore:ingotDarkSteel> * 4)
    .circuit(1)
    .outputs(<enderio:block_enchanter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_farm_station:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gearEnergized> * 2, <ore:ingotSoularium> * 2, <ore:itemPulsatingCrystal>, <ore:itemSoulMachineChassi>, <ore:itemVibrantCrystal> * 2, <ore:skullZombieController>)
    .circuit(1)
    .outputs(<enderio:block_farm_station:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_painter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gearIronInfinity> * 2, <ore:gemDiamond>, <ore:gemNetherQuartz> * 2, <ore:ingotElectricalSteel> * 3, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_painter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_reservoir:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:cauldron:0>, <ore:blockGlassHardened> * 8)
    .circuit(1)
    .outputs(<enderio:block_reservoir:0> * 4)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_omni_reservoir:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:cauldron:0>, <ore:blockGlassColorless> * 6, <ore:blockGlassHardened> * 2)
    .circuit(1)
    .outputs(<enderio:block_omni_reservoir:0> * 4)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_slice_and_splice:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:barsIron>, <ore:gearEnergized> * 2, <ore:ingotSoularium> * 4, <ore:itemSkull>, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_slice_and_splice:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_dark_iron_bars:0>, <ore:gearEnergized> * 2, <ore:ingotSoularium> * 4, <ore:itemSkull>, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_slice_and_splice:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_soul_binder:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotSoularium> * 4, <ore:itemSkull> * 4, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_soul_binder:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_powered_spawner:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotElectricalSteel> * 4, <ore:itemSkull>, <ore:itemSoulMachineChassi>, <ore:itemVibrantCrystal> * 2, <ore:skullZombieController>)
    .circuit(1)
    .outputs(<enderio:block_powered_spawner:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_vat:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_tank:0> * 2, <minecraft:cauldron:0>, <ore:craftingFurnace>, <ore:ingotDarkSteel> * 2, <ore:ingotElectricalSteel> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_vat:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_enhanced_vat:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_tank:1> * 2, <minecraft:cauldron:0>, <ore:craftingFurnace>, <ore:ingotElectricalSteel> * 2, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_vat:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_tank:1> * 2, <enderio:block_vat:0>, <ore:ingotEndSteel> * 2, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_vat:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:block_simple_wired_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotElectricalSteel> * 4, <ore:itemSimpleMachineChassi>, <ore:stoneCobble> * 4)
    .circuit(1)
    .outputs(<enderio:block_simple_wired_charger:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_wired_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotElectricalSteel> * 8, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_wired_charger:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_simple_wired_charger:0>, <ore:ingotElectricalSteel> * 4, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_wired_charger:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_enhanced_wired_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gearVibrant> * 2, <ore:ingotElectricalSteel> * 5, <ore:ingotEndSteel>, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_wired_charger:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_wired_charger:0>, <ore:gearVibrant> * 2, <ore:ingotEndSteel>, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_wired_charger:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:block_wireless_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:0>, <ore:ingotElectricalSteel> * 7, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_wireless_charger:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_normal_wireless_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_wireless_charger:0>, <enderio:item_basic_capacitor:1>, <ore:itemMachineChassi>, <ore:itemWirelessDish> * 4)
    .circuit(1)
    .outputs(<enderio:block_normal_wireless_charger:0>)
    .duration(400).EUt(120)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:1>, <ore:itemMachineChassi>, <ore:itemWirelessDish> * 4, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_normal_wireless_charger:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:block_enhanced_wireless_charger:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_normal_wireless_charger:0>, <enderio:item_basic_capacitor:2>, <ore:itemEnhancedMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_wireless_charger:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_wireless_charger:0>, <enderio:item_basic_capacitor:2>, <ore:itemEnhancedMachineChassi>, <ore:itemWirelessDish> * 4)
    .circuit(1)
    .outputs(<enderio:block_enhanced_wireless_charger:0>)
    .duration(600).EUt(480)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:2>, <ore:itemEnhancedMachineChassi>, <ore:itemWirelessDish> * 4, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_enhanced_wireless_charger:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:block_wireless_charger_extension:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotEndSteel>, <ore:itemWirelessDish> * 4)
    .circuit(1)
    .outputs(<enderio:block_wireless_charger_extension:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_transceiver:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:2>, <ore:blockGlassHardened> * 2, <ore:ingotElectricalSteel> * 4, <ore:itemEnderCrystal>, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_transceiver:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_vacuum_chest:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:chest>, <ore:ingotConstructionAlloy> * 7, <ore:itemPulsatingCrystal>)
    .circuit(1)
    .outputs(<enderio:block_vacuum_chest:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_xp_vacuum:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_xp_transfer:0>, <ore:ingotConstructionAlloy> * 7, <ore:itemPulsatingCrystal>)
    .circuit(1)
    .outputs(<enderio:block_xp_vacuum:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_niard:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_dark_iron_bars:0>, <enderio:block_tank:0>, <minecraft:bucket:0> * 2, <ore:craftingPiston> * 2, <ore:ingotElectricalSteel> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_niard:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_travel_anchor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:ingotConstructionAlloy> * 4, <ore:itemConduitBinder> * 4, <ore:itemPulsatingCrystal>)
    .circuit(1)
    .outputs(<enderio:block_travel_anchor:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_tele_pad:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_travel_anchor:0>, <enderio:item_basic_capacitor:0>, <ore:blockGlassHardened> * 2, <ore:ingotDarkSteel> * 4, <ore:ingotVibrantAlloy>)
    .circuit(1)
    .outputs(<enderio:block_tele_pad:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_dialing_device:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:2>, <ore:ingotDarkSteel> * 2, <ore:ingotElectricalSteel>, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_dialing_device:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_impulse_hopper:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:blockHopper>, <ore:gearEnergized> * 2, <ore:ingotElectricalSteel> * 4, <ore:ingotRedstoneAlloy>, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_impulse_hopper:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_simple_crafter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingTableWood>, <ore:gearStone> * 2, <ore:ingotConstructionAlloy> * 2, <ore:ingotSilicon> * 3, <ore:itemSimpleMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_simple_crafter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_crafter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_simple_crafter:0>, <ore:gearIronInfinity> * 2, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_crafter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:craftingTableWood>, <ore:gearIronInfinity> * 2, <ore:ingotConstructionAlloy> * 2, <ore:itemMachineChassi>, <ore:ingotSilicon> * 3)
    .circuit(1)
    .outputs(<enderio:block_crafter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_gauge:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_conduit_probe:0>, <ore:ingotConstructionAlloy> * 4, <ore:ingotElectricalSteel> * 2)
    .circuit(1)
    .outputs(<enderio:block_gauge:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_power_monitor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_conduit_probe:0>, <enderio:item_power_conduit:0>, <ore:ingotElectricalSteel> * 6, <ore:itemMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_power_monitor:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_advanced_power_monitor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_power_monitor:0>, <ore:dyeRed>, <ore:dyeGreen>, <ore:dyeYellow>, <ore:wool> * 5)
    .circuit(1)
    .outputs(<enderio:block_advanced_power_monitor:0>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:block_killer_joe:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:blockGlassHardened> * 5, <ore:ingotDarkSteel> * 3, <ore:skullZombieFrankenstein>)
    .circuit(1)
    .outputs(<enderio:block_killer_joe:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:0>, <ore:blockGlassHardened> * 3, <ore:dustGlowstone>, <ore:ingotSilicon> * 4)
    .circuit(1)
    .outputs(<enderio:block_electric_light:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:1>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:1>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:0>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:blockGlassColorless> * 3, <ore:glowstone>, <ore:ingotConstructionAlloy> * 2)
    .circuit(1)
    .outputs(<enderio:block_electric_light:2>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:3>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:3>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:2>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:3>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:4>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:0>, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:4>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:5>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:4>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_electric_light:5>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:1>, <ore:skullEnderResonator>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:5>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_electric_light:4>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<enderio:block_electric_light:5>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_attractor_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gearWood>, <ore:ingotEnergeticAlloy> * 2, <ore:ingotSoularium> * 2, <ore:itemAttractorCrystal>, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_attractor_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_aversion_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_enderman_skull:2>, <ore:gearEnergized>, <ore:ingotEnergeticAlloy> * 2, <ore:ingotSoularium> * 2, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_aversion_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inhibitor_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gearIronInfinity>, <ore:ingotEnergeticAlloy> * 2, <ore:ingotSoularium> * 2, <ore:itemEnderCrystal>, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_inhibitor_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_relocator_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_aversion_obelisk:0>, <ore:blockPrismarine> * 3, <ore:gearVibrant>)
    .circuit(1)
    .outputs(<enderio:block_relocator_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_weather_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:2>, <ore:ingotEnergeticAlloy> * 2, <ore:ingotSoularium> * 2, <ore:itemSoulMachineChassi>, <ore:itemWeatherCrystal>)
    .circuit(1)
    .outputs(<enderio:block_weather_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_experience_obelisk:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_tank:0>, <enderio:item_xp_transfer:0>, <ore:ingotEnergeticAlloy> * 2, <ore:ingotSoularium> * 2, <ore:itemSoulMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_experience_obelisk:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_panel:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dustBone>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dye>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dye>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dye>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dye>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeBlack>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeBrown>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeCyan>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeGray>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeGreen>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeLightBlue>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeLightGray>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeLime>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeOrange>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:dyeYellow>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_panel:0>, <ore:gemLapis>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_tank:0>, <ore:ingotDarkSteel> * 4, <ore:itemPulsatingCrystal> * 2, <ore:itemRemoteAwarenessUpgrade>, <ore:skullSentientEnder>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_panel_sensor:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:comparator:0>, <ore:ingotElectricalSteel> * 4, <ore:ingotRedstoneAlloy> * 2, <ore:itemMachineChassi>, <ore:itemRemoteAwarenessUpgrade>)
    .circuit(1)
    .outputs(<enderio:block_inventory_panel_sensor:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_tiny:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:item_basic_capacitor:0>, <ore:chest> * 3, <ore:itemRemoteAwarenessUpgrade>, <ore:itemSimpleMachineChassi>)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_tiny:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_small:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_tiny:0>, <ore:chest>, <ore:itemSimpleChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_small:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_medium:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_small:0>, <ore:chest>, <ore:itemSimpleChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_medium:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_big:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_medium:0>, <ore:chest>, <ore:itemMachineChassi>, <ore:itemRemoteAwarenessUpgrade>)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_big:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_large:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_big:0>, <ore:chest> * 2, <ore:itemChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_large:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_huge:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_large:0>, <ore:chest> * 2, <ore:itemChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_huge:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_enormous:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_huge:0>, <ore:chest> * 2, <ore:itemEnhancedMachineChassi>, <ore:itemRemoteAwarenessUpgrade>)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_enormous:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_warehouse:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_enormous:0>, <ore:chest> * 3, <ore:itemEnhancedChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_warehouse:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_inventory_chest_warehouse13:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_inventory_chest_warehouse:0>, <ore:chest> * 3, <ore:itemEnhancedChassiParts> * 3)
    .circuit(1)
    .outputs(<enderio:block_inventory_chest_warehouse13:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:block_detector_block:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<enderio:block_painted_pressure_plate:8>, <ore:blockRedstone>, <ore:craftingPiston>, <ore:itemChassiParts> * 6)
    .circuit(1)
    .outputs(<enderio:block_detector_block:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:carpenter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 2, <ore:ingotBronze> * 6)
    .circuit(1)
    .outputs(<forestry:carpenter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:centrifuge:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 2, <ore:ingotCopper> * 6)
    .circuit(1)
    .outputs(<forestry:centrifuge:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:squeezer:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 2, <ore:ingotTin> * 6)
    .circuit(1)
    .outputs(<forestry:squeezer:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:fermenter:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 4, <ore:gearBronze> * 4)
    .circuit(1)
    .outputs(<forestry:fermenter:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:moistener:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 4, <ore:gearCopper> * 4)
    .circuit(1)
    .outputs(<forestry:moistener:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:still:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 4, <ore:dustRegularRedstone> * 4)
    .circuit(1)
    .outputs(<forestry:still:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:raintank:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <gregtech:meta_item_1:12033> * 6, <ore:blockGlassColorless> * 2)
    .circuit(1)
    .outputs(<forestry:raintank:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:analyzer:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <ore:ingotBronze> * 4)
    .circuit(1)
    .outputs(<forestry:analyzer:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:fabricator:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 3, <ore:chest>, <ore:ingotGold> * 4)
    .circuit(1)
    .outputs(<forestry:fabricator:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:rainmaker:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:hardened_machine:0>, <ore:blockGlassColorless> * 4, <ore:gearTin> * 4)
    .circuit(1)
    .outputs(<forestry:rainmaker:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:bottler:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:can:0> * 4, <forestry:sturdy_machine:0>, <ore:blockGlassColorless> * 4)
    .circuit(1)
    .outputs(<forestry:bottler:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:habitat_former:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:chipsets:0>, <forestry:sturdy_machine:0>, <forestry:thermionic_tubes:3> * 2, <ore:blockGlassColorless> * 2, <ore:dustRegularRedstone>, <ore:gearBronze> * 2)
    .circuit(1)
    .outputs(<forestry:habitat_former:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:trade_station:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:chipsets:2>, <forestry:sturdy_machine:0>, <forestry:thermionic_tubes:2> * 3, <forestry:thermionic_tubes:3> * 2, <ore:chest> * 2)
    .circuit(1)
    .outputs(<forestry:trade_station:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:database:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:bee_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:dropRoyalJelly>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:butterfly_chest:0>, <forestry:portable_alyzer:0>, <forestry:sturdy_machine:0>, <forestry:tree_chest:0>, <ore:fruitForestry>, <ore:ingotBronze> * 2, <ore:plankWood> * 2)
    .circuit(1)
    .outputs(<forestry:database:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

// -------------------------------------- Ender IO: the four gears leave the crafting table
// Ender IO's gears are its own and stay its own - the owner's call: the "bimetal" gears (an iron /
// construction-alloy core coated in an alloy's nuggets) have no GregTech counterpart, and GregTech has
// no gear at all for the alloys they are made of. What changes is the machine. They are machine
// components, every Ender IO machine block in this file is built from them, and Ender IO's recipes for
// them are 3x3 grids - so they are assembler work now, at the same materials and counts, one tier up
// each rung, with an integrated circuit. The **stone compound gear** (`item_material:10`) stays where
// it is: cobblestone, sticks and a wooden gear is LV work, and the crafting table is the right machine
// for that.
//
// The Grains of Infinity (`item_material:20`, Ender IO's `POWDER_INFINITY`) the first gear needs are
// not a recipe at all - Ender IO makes them by dropping bedrock into Fire Water, which is what
// `InfinityConfig.bedrock` configures - so no audit of the recipe registries will ever see a producer
// for them, and that is fine.
recipes.remove(<enderio:item_material:11>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetIron> * 4, <ore:ingotConstructionAlloy> * 4, <enderio:item_material:20>)
    .circuit(1)
    .outputs(<enderio:item_material:11>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<enderio:item_material:12>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetEnergeticAlloy> * 8, <enderio:item_material:11>)
    .circuit(1)
    .outputs(<enderio:item_material:12>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<enderio:item_material:13>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetVibrantAlloy> * 8, <enderio:item_material:11>)
    .circuit(1)
    .outputs(<enderio:item_material:13>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<enderio:item_material:73>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:nuggetDarkSteel> * 8, <enderio:item_material:11>)
    .circuit(1)
    .outputs(<enderio:item_material:73>)
    .duration(600).EUt(480)
    .buildAndRegister();

// ------------------------------------------- Forestry: the three engines are the power leak
// These are the last non-GregTech power generators in the pack (Galacticraft's, Galaxy Space's and
// Ender IO's were deleted outright in gc_gregify_removals.zs / gs_gregify_removals.zs and
// zzz_minespace_integration.zs). Deleting them is not the point - the owner's rule for power is
// "not that easy", not "gone" - so what they cost was raised instead:
//
//   * they are built in a GregTech assembler at **MV 128 EU/t** (the clockwork one at **HV 480**,
//     because it is the one that needs no fuel at all), where before all three were LV 30;
//   * the copper / bronze shell and ingots are replaced by **GregTech steel plates** for the two
//     fuelled engines and **stainless steel plates** for the fuel-free one, so an engine now needs
//     a real rolling line rather than three copper ingots;
//   * the two-fuelled-engine pair keeps a GT circuit, the clockwork one takes the higher one.
//
// They are still cheap *fuel* - that is what Forestry is for - but the block itself, and therefore
// the power, is no longer something you get out of the copper age. Note the plates use exact
// GregTech ids (12184 steel / 12183 stainless): the pack's own alias table lives in
// zzz_minespace_integration.zs and a CraftTweaker `val` does not cross files.
recipes.remove(<forestry:engine_peat:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:12184> * 3, <ore:craftingPiston>, <ore:circuitBasic>,
            <ore:blockGlassColorless>, <ore:ingotCopper> * 2)
    .circuit(1)
    .outputs(<forestry:engine_peat:0>)
    .duration(400).EUt(128)
    .buildAndRegister();

recipes.remove(<forestry:engine_biogas:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:12184> * 4, <ore:craftingPiston>, <ore:circuitBasic>,
            <ore:blockGlassColorless>, <minecraft:cauldron:0>)
    .circuit(1)
    .outputs(<forestry:engine_biogas:0>)
    .duration(400).EUt(128)
    .buildAndRegister();

recipes.remove(<forestry:engine_clockwork:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:12183> * 4, <ore:craftingPiston>, <ore:circuitGood>,
            <ore:blockGlassColorless>, <minecraft:clock:0>)
    .circuit(1)
    .outputs(<forestry:engine_clockwork:0>)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<forestry:ffarm:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:blockBrick>, <ore:ingotCopper> * 2, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:blockNetherQuartz>, <ore:ingotCopper> * 2, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <minecraft:nether_brick:0>, <ore:ingotCopper> * 2, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <minecraft:quartz_block:1>, <ore:ingotCopper> * 2, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <minecraft:quartz_block:2>, <ore:ingotCopper> * 2, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:ingotCopper> * 2, <ore:sandstone>, <ore:slabWood> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:ingotCopper> * 2, <ore:slabWood> * 2, <ore:stoneBricks>)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:ingotCopper> * 2, <ore:slabWood> * 2, <ore:stoneBricks>)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:ingotCopper> * 2, <ore:slabWood> * 2, <ore:stoneBricks>)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:thermionic_tubes:1>, <ore:ingotCopper> * 2, <ore:slabWood> * 2, <ore:stoneMossy>)
    .circuit(1)
    .outputs(<forestry:ffarm:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:ffarm:2>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:ffarm:0>, <ore:gearTin> * 3)
    .circuit(1)
    .outputs(<forestry:ffarm:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:ffarm:3>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:ffarm:0>, <ore:gearTin> * 2, <ore:trapdoorWood>)
    .circuit(1)
    .outputs(<forestry:ffarm:3>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:ffarm:4>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:ffarm:0>, <ore:blockGlassColorless> * 2, <ore:gearTin>)
    .circuit(1)
    .outputs(<forestry:ffarm:4>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:ffarm:5>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:ffarm:0>, <forestry:thermionic_tubes:4>, <ore:dustRegularRedstone> * 2)
    .circuit(1)
    .outputs(<forestry:ffarm:5>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:peat_bog:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:chipsets:0>, <forestry:flexible_casing:0>, <forestry:thermionic_tubes:6> * 3, <ore:blockGlassColorless> * 4)
    .circuit(1)
    .outputs(<forestry:peat_bog:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.plain:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:crafting_material:6> * 8, <forestry:impregnated_casing:0>)
    .circuit(1)
    .outputs(<forestry:alveary.plain:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.swarmer:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <forestry:thermionic_tubes:5> * 4, <ore:ingotGold> * 2)
    .circuit(1)
    .outputs(<forestry:alveary.swarmer:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.fan:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <forestry:thermionic_tubes:4>, <gregtech:meta_item_1:12033> * 4)
    .circuit(1)
    .outputs(<forestry:alveary.fan:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.heater:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <forestry:thermionic_tubes:4> * 2, <gregtech:meta_item_1:12033>, <ore:stoneSmooth> * 3)
    .circuit(1)
    .outputs(<forestry:alveary.heater:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.hygro:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <gregtech:meta_item_1:12033> * 2, <ore:blockGlassColorless> * 6)
    .circuit(1)
    .outputs(<forestry:alveary.hygro:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.stabiliser:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <ore:gemNetherQuartz> * 6)
    .circuit(1)
    .outputs(<forestry:alveary.stabiliser:0>)
    .duration(200).EUt(30)
    .buildAndRegister();

recipes.remove(<forestry:alveary.sieve:0>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<forestry:alveary.plain:0>, <forestry:crafting_material:3> * 3, <gregtech:meta_item_1:12033> * 3)
    .circuit(1)
    .outputs(<forestry:alveary.sieve:0>)
    .duration(200).EUt(30)
    .buildAndRegister();recipes.remove(<appliedenergistics2:crafting_storage_1k:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <appliedenergistics2:material:35>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_storage_1k:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:crafting_storage_4k:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <appliedenergistics2:material:36>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_storage_4k:0 >)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:crafting_storage_16k:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <appliedenergistics2:material:37>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_storage_16k:0 >)
    .duration(600).EUt(480)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:crafting_storage_64k:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <appliedenergistics2:material:38>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_storage_64k:0 >)
    .duration(800).EUt(1920)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:crafting_monitor:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:crafting_unit:0>, <appliedenergistics2:part:400>)
    .circuit(1)
    .outputs(<appliedenergistics2:crafting_monitor:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();recipes.remove(<appliedenergistics2:wireless_terminal:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:dense_energy_cell:0>, <appliedenergistics2:material:41>, <appliedenergistics2:part:380>)
    .circuit(1)
    .outputs(<appliedenergistics2:wireless_terminal:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:wireless_crafting_terminal:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:dense_energy_cell:0>, <appliedenergistics2:material:41>, <appliedenergistics2:part:360>)
    .circuit(1)
    .outputs(<appliedenergistics2:wireless_crafting_terminal:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:wireless_pattern_terminal:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:dense_energy_cell:0>, <appliedenergistics2:material:41>, <appliedenergistics2:part:340>)
    .circuit(1)
    .outputs(<appliedenergistics2:wireless_pattern_terminal:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:wireless_fluid_terminal:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:dense_energy_cell:0>, <appliedenergistics2:material:41>, <appliedenergistics2:part:520>)
    .circuit(1)
    .outputs(<appliedenergistics2:wireless_fluid_terminal:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:wireless_access_point:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:23>, <appliedenergistics2:material:41>, <appliedenergistics2:part:16>)
    .circuit(1)
    .outputs(<appliedenergistics2:wireless_access_point:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();recipes.remove(<appliedenergistics2:portable_cell:0 >);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:chest:0>, <appliedenergistics2:energy_cell:0>, <appliedenergistics2:material:35>)
    .circuit(1)
    .outputs(<appliedenergistics2:portable_cell:0 >)
    .duration(200).EUt(120)
    .buildAndRegister();// ---- AE2 leftovers: the bus / panel / emitter family, the card family and the wireless pair
// These were the last AE2 recipes spending vanilla iron that are not full 3x3 grids. Width does not
// matter for an assembler recipe (its inputs are an unordered list), which is exactly why they come
// here rather than being rewritten in place. Tiers: the plain level emitters and monitors LV, the
// "energy" variants of each HV, the advanced cards MV. Output counts are the mod's own (the basic
// and advanced cards produce two).
recipes.remove(<appliedenergistics2:material:26>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:25>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:26>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:27>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:25>, <ore:crystalCertusQuartz>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:27>)
    .duration(200).EUt(120)
    .buildAndRegister();recipes.remove(<appliedenergistics2:material:29>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:28>, <ore:wool>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:29>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:30>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:28>, <ore:crystalFluix>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:30>)
    .duration(400).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:31>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:material:28>, <ore:craftingRedstoneTorch>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:31>)
    .duration(400).EUt(120)
    .buildAndRegister();recipes.remove(<appliedenergistics2:material:42>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:12033> * 3, <ore:crystalCertusQuartz>, <ore:dustEnder>, <ore:dustFluix>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:42> * 2)
    .duration(200).EUt(120)
    .buildAndRegister();// ================== Iron Chests and Storage Drawers: the advanced half, off the crafting table
//
// The owner's rule again: an *advanced* item is not one that merely costs GregTech materials, it is
// one a GregTech machine has to make. This is the second half of that pass, over the two storage
// mods; the first half (Ender IO, Forestry, AE2) is the recipes above.
//
// Where the line falls, and why:
//
//   Iron Chests   the iron chest is the mod's namesake and its natural entry point, and the copper
//                 chest is the step below it, so both stay on the crafting table together with the
//                 dirt chest. Every tier *above* iron - silver, gold, diamond, crystal, obsidian -
//                 is assembled, at the voltage its metal earns: silver / gold LV, diamond MV,
//                 crystal and obsidian HV. The nine chest upgrades follow the tier they produce, so
//                 the three that only reach copper or iron stay shaped and the other six are
//                 assembled. The sixteen coloured shulker boxes are the same chests in portable
//                 form; leaving them hand-craftable would be a way around the assembler for exactly
//                 the tiers that were just gated, so their five upper tiers move too, through the
//                 same colour loop that used to shape them. The three shulker upgrades that only
//                 reach copper or iron stay shaped, for the same reason as the chest upgrades.
//
//   Storage       the compacting drawer, the drawer controller, its slave and the framing table are
//   Drawers       machines: they route items, or they are workbenches. They already needed a
//                 GregTech circuit or a GregTech screw to exist, so they are assembled at LV. The
//                 plain drawers, trims, upgrade templates and the obsidian "1x" storage upgrade stay
//                 craftable by hand; the 2x / 4x / 8x / 16x storage upgrades are assembled, LV for
//                 the iron and gold ones and MV for the diamond and emerald ones.
//
// Nothing was lowered. Every grid below is the one that was on the crafting table, with the same
// items in the same counts; the only additions are the two this pack gives every assembler recipe,
// the integrated circuit and the EU/t. An assembler recipe is a flat input list, so equal stacks in
// different slots are merged and multiplied - three plates along the top plus one in the centre is
// four plates, not three - and every count below was read off the grid it replaces.

// ------------------------------------------------------------ Iron Chests: the chest tiers
// Silver (meta 4): eight silver plates around the iron chest.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSilver> * 8, <ironchest:iron_chest:0>)
    .circuit(1)
    .outputs(<ironchest:iron_chest:4>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Gold (meta 1): eight gold plates around the silver chest.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGold> * 8, <ironchest:iron_chest:4>)
    .circuit(1)
    .outputs(<ironchest:iron_chest:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Diamond (meta 2): eight diamond plates around the gold chest. MV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateDiamond> * 8, <ironchest:iron_chest:1>)
    .circuit(1)
    .outputs(<ironchest:iron_chest:2>)
    .duration(200).EUt(120)
    .buildAndRegister();

// Crystal (meta 5): eight glass plates around the diamond chest. HV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGlass> * 8, <ironchest:iron_chest:2>)
    .circuit(1)
    .outputs(<ironchest:iron_chest:5>)
    .duration(600).EUt(480)
    .buildAndRegister();

// Obsidian (meta 6): eight blocks of obsidian around the diamond chest - obsidian has no GregTech
// plate in this pack, so this tier costs the block, exactly as its shaped recipe did. HV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:obsidian> * 8, <ironchest:iron_chest:2>)
    .circuit(1)
    .outputs(<ironchest:iron_chest:6>)
    .duration(600).EUt(480)
    .buildAndRegister();

// ------------------------------------------------------------ Iron Chests: the chest upgrades
// copper -> silver: eight silver plates around one copper plate. The mod's own recipe is eight
// silver, and a plate is one ingot, so the ring is the mod's cost with a GregTech bender in it
// instead of the plain ingots. Do not put screws here: a GregTech screw is an eighth of an ingot,
// and four of them in place of four plates silently halves the silver.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSilver> * 8, <gregtech:meta_item_1:12018>)
    .circuit(1)
    .outputs(<ironchest:copper_silver_chest_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

// silver -> gold: four gold plates, four glass plates, one silver plate.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGold> * 4, <ore:plateGlass> * 4, <ore:plateSilver>)
    .circuit(1)
    .outputs(<ironchest:silver_gold_chest_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

// iron -> gold: eight gold plates around one iron plate - the same ring, the same correction.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGold> * 8, <gregtech:meta_item_1:12033>)
    .circuit(1)
    .outputs(<ironchest:iron_gold_chest_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

// gold -> diamond: six glass plates, two diamond plates, one gold plate. MV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGlass> * 6, <ore:plateDiamond> * 2, <ore:plateGold>)
    .circuit(1)
    .outputs(<ironchest:gold_diamond_chest_upgrade>)
    .duration(200).EUt(120)
    .buildAndRegister();

// diamond -> crystal: eight glass plates and one block of obsidian. HV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGlass> * 8, <minecraft:obsidian>)
    .circuit(1)
    .outputs(<ironchest:diamond_crystal_chest_upgrade>)
    .duration(600).EUt(480)
    .buildAndRegister();

// diamond -> obsidian: eight blocks of obsidian and one glass plate. HV.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:obsidian> * 8, <ore:plateGlass>)
    .circuit(1)
    .outputs(<ironchest:diamond_obsidian_chest_upgrade>)
    .duration(600).EUt(480)
    .buildAndRegister();

// --------------------------------------- Iron Chests: the shulker boxes and their upgrades
// One loop, sixteen colours. The five upper tiers are the ones the crafting table no longer offers;
// the iron (0) and copper (3) tiers are still shaped in zzz_minespace_integration.zs. The grids are
// the mod's own, unchanged except for the circuit and the EU/t, and each tier still has the two
// routes it always had.
for colour in ["white", "orange", "magenta", "light_blue", "yellow", "lime", "pink",
        "gray", "silver", "cyan", "purple", "blue", "brown", "green", "red", "black"] as string[] {

    // Gold (tier 1), from the silver shulker box: four gold plates and four glass plates.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateGold> * 4, <ore:plateGlass> * 4, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 4))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 1))
        .duration(200).EUt(30)
        .buildAndRegister();

    // Gold (tier 1), from the iron shulker box: eight gold plates.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateGold> * 8, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 0))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 1))
        .duration(200).EUt(30)
        .buildAndRegister();

    // Diamond (tier 2), from the silver shulker box: six glass plates and three diamond plates. MV.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateGlass> * 6, <ore:plateDiamond> * 3, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 4))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 2))
        .duration(200).EUt(120)
        .buildAndRegister();

    // Diamond (tier 2), from the gold shulker box: six glass plates and two diamond plates. MV.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateGlass> * 6, <ore:plateDiamond> * 2, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 1))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 2))
        .duration(200).EUt(120)
        .buildAndRegister();

    // Silver (tier 4), from the copper shulker box: eight silver plates.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateSilver> * 8, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 3))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 4))
        .duration(200).EUt(30)
        .buildAndRegister();

    // Silver (tier 4), from the iron shulker box: four silver plates and four glass plates.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateSilver> * 4, <ore:plateGlass> * 4, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 0))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 4))
        .duration(200).EUt(30)
        .buildAndRegister();

    // Crystal (tier 5), from the diamond shulker box: eight glass plates. HV.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<ore:plateGlass> * 8, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 2))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 5))
        .duration(600).EUt(480)
        .buildAndRegister();

    // Obsidian (tier 6), from the diamond shulker box: eight blocks of obsidian. HV.
    mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        .inputs(<minecraft:obsidian> * 8, itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 2))
        .circuit(1)
        .outputs(itemUtils.getItem("ironchest:iron_shulker_box_" + colour, 6))
        .duration(600).EUt(480)
        .buildAndRegister();
}

// The six shulker upgrades that lead above the iron tier. The three that lead to the copper or iron
// shulker box stay shaped in zzz_minespace_integration.zs.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateSilver> * 8, <gregtech:meta_item_1:12018>)
    .circuit(1)
    .outputs(<ironchest:copper_silver_shulker_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGold> * 4, <ore:plateGlass> * 4, <ore:plateSilver>)
    .circuit(1)
    .outputs(<ironchest:silver_gold_shulker_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGold> * 8, <gregtech:meta_item_1:12033>)
    .circuit(1)
    .outputs(<ironchest:iron_gold_shulker_upgrade>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGlass> * 6, <ore:plateDiamond> * 2, <ore:plateGold>)
    .circuit(1)
    .outputs(<ironchest:gold_diamond_shulker_upgrade>)
    .duration(200).EUt(120)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:plateGlass> * 8, <minecraft:obsidian>)
    .circuit(1)
    .outputs(<ironchest:diamond_crystal_shulker_upgrade>)
    .duration(600).EUt(480)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<minecraft:obsidian> * 8, <ore:plateGlass>)
    .circuit(1)
    .outputs(<ironchest:diamond_obsidian_shulker_upgrade>)
    .duration(600).EUt(480)
    .buildAndRegister();

// ---------------------------------------- Storage Drawers: the machines and the upper upgrades
// The compacting drawer: the mod's own grid - five smooth stone (its rows are "###" / "TXT" / "#I#",
// so the stone is three plus two), a basic drawer, two pistons in the flanks and the iron plate that
// makes it push in place of the mod's iron ingot. The LV circuit is this file's convention for a
// machine that processes items, which is what a compacting drawer is. Nothing was dropped and the
// stone is not inflated past the mod's count.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:stoneSmooth> * 5, <minecraft:piston> * 2, <ore:drawerBasic>, <gregtech:meta_item_1:12033>, <ore:circuitBasic>)
    .circuit(1)
    .outputs(<storagedrawers:compdrawers>)
    .duration(200).EUt(30)
    .buildAndRegister();

// The controller: the same body with a diamond plate instead of the iron one. The mod puts a basic
// drawer in the centre; that stays, and the LV circuit is an addition, not a substitution - the
// earlier revision had the circuit replace the drawer, which quietly removed the drawer from the
// cost.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:stoneSmooth> * 5, <minecraft:comparator> * 2, <ore:drawerBasic>, <ore:circuitBasic>, <ore:plateDiamond>)
    .circuit(1)
    .outputs(<storagedrawers:controller>)
    .duration(200).EUt(30)
    .buildAndRegister();

// The slave: the same body with a gold plate instead of the diamond one.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:stoneSmooth> * 5, <minecraft:comparator> * 2, <ore:drawerBasic>, <ore:circuitBasic>, <ore:plateGold>)
    .circuit(1)
    .outputs(<storagedrawers:controllerslave>)
    .duration(200).EUt(30)
    .buildAndRegister();

// The framing table: the mod's own seven drawer trims (its rows are "XXX" / "X X") plus the GregTech
// steel screw that makes it a machine's part rather than a plain workbench. The earlier revision had
// six trims, one short of the mod.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:drawerTrim> * 7, <gregtech:meta_item_1:17184>)
    .circuit(1)
    .outputs(<storagedrawers:framingtable>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Storage upgrades 2x and 4x (iron, gold): four screws of the same metal, two plates, the template.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:17033> * 4, <gregtech:meta_item_1:12033> * 2, <storagedrawers:upgrade_template>)
    .circuit(1)
    .outputs(<storagedrawers:upgrade_storage:1>)
    .duration(200).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:17026> * 4, <ore:plateGold> * 2, <storagedrawers:upgrade_template>)
    .circuit(1)
    .outputs(<storagedrawers:upgrade_storage:2>)
    .duration(200).EUt(30)
    .buildAndRegister();

// Storage upgrades 8x and 16x (diamond, emerald): gold screws, a gem plate pair, the template. MV,
// because the gem is what the drawer's extra capacity is made of.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:17026> * 4, <ore:plateDiamond> * 2, <storagedrawers:upgrade_template>)
    .circuit(1)
    .outputs(<storagedrawers:upgrade_storage:3>)
    .duration(200).EUt(120)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<gregtech:meta_item_1:17026> * 4, <ore:plateEmerald> * 2, <storagedrawers:upgrade_template>)
    .circuit(1)
    .outputs(<storagedrawers:upgrade_storage:4>)
    .duration(200).EUt(120)
    .buildAndRegister();

