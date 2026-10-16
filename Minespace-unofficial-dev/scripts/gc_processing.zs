#priority 847
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Ported from the GTCEu-era script of the same name (see TJ-MIGRATION-PLAN.md, section 6d).
// The recipe map accessor is GTCE-TJ's:
//     <recipemap:assembler>.recipeBuilder()                                   [GTCEu]
//  -> mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()    [GTCE-TJ]
// Everything else - inputs/outputs/duration/EUt/property/circuit/fluidInputs/
// buildAndRegister, the ore dictionary names, the Galacticraft item ids and the JEI calls -
// is unchanged, because those APIs are the same in both forks.
// CraftTweaker port of the "Mods-Get-Gregged" Galacticraft *processing* recipes - the
// GregTech machine recipes at the end of GT5-scripts\Galacticraft\Galacticraft.zs.
//
//   gc_gregify_crafting.zs    crafting table (removals + re-additions)
//   gc_gregify_machines.zs    canner (canned food), bender (canisters), assembler
//                             (glowstone torch)
//   gc_gregify_processing.zs  this file - the ore-to-metal chain:
//                             macerator, implosion compressor, electric blast furnace
//
// Still unported from that source file, each for a concrete reason:
//
//   * Assembler - basic/advanced wafer (source: 2x silicon + 4x basic circuit, 1600 ticks).
//     Superseded rather than ported: the mod wafers are now engraved out of GregTech's own wafers
//     in GregTech's laser engraver (gc_removals.zs for the Galacticraft ones, gaps.zs for Galaxy
//     Space's), so there is no assembler shape left to translate.
//   * Extruder - oxygen pipe / canisters / steel pole. CEu wants an extruder shape item
//     (notConsumable) that GT5 passed as a "mold" metaitem, so the shape has to be picked
//     per recipe; the bender already covers the canisters in gc_gregify_machines.zs.
//   * Vacuum freezer - GT5's recipes produced IC2 fluid cells of liquid oxygen / nitrogen.
//     GC 4.0.7 has its own gas liquefier and canister chain for those, so the mapping is not
//     1:1.
//   * Compressor - deliberately not ported, see the section note further down.
//
// Two porting problems, both solved the same way as in the other two scripts:
//
//   * Machine access. GT5 exposed one script class per machine
//     (Macerator.addRecipe(out, in), ImplosionCompressor.addRecipe(out, in, tnt), ...).
//     GTCEu exposes the same machines through <recipemap:NAME>, so each line becomes
//     <recipemap:NAME>.recipeBuilder().inputs(..).outputs(..).duration(..).EUt(..)
//     .buildAndRegister(). Recipe map names are the ones GTCEu registers in RecipeMaps:
//     macerator, compressor, implosion_compressor, electric_blast_furnace, ...
//
//   * Ingredients. GT5's gt.metaitem.01:xxxxx ids do not exist in GTCEu and its item
//     metadata is assigned at runtime, so every GregTech ingredient is addressed by ore
//     dictionary name. Those names were not guessed: a temporary probe script printed
//     every ore dictionary entry this pack cares about on a real server run, and only
//     names that came back are used here (dustDesh, ingotDesh, plateTitanium, ...).
//
// Galacticraft item metadata is the index into the item class's `names` array, read out
// of Galacticraft-1.12.2-4.0.7 with javap. The values that appear below:
//
//   galacticraftcore:basic_block_core   9 solid meteoric iron
//   galacticraftcore:basic_item         6 compressed copper, 7 compressed tin,
//                                       8 compressed aluminium, 9 compressed steel,
//                                       10 compressed bronze, 11 compressed iron
//   galacticraftcore:canister           0 tin canister, 1 copper canister
//   galacticraftcore:meteoric_iron_raw  raw meteoric iron (drops from a fallen meteor)
//   galacticraftplanets:mars            2 desh ore, 8 block of desh
//   galacticraftplanets:asteroids_block 4 ilmenite ore, 7 titanium block
//   galacticraftplanets:item_basic_mars 0 unrefined desh
//   galacticraftplanets:item_basic_asteroids 4 titanium shard, 6 compressed titanium
//
// (Galacticraft 3.x and 4.0.7 agree on these values - the GT5 script's own metadata
// numbers match the 4.0.7 name arrays exactly, so nothing needed shifting.)
//
// One more CraftTweaker detail: GregTech's recipe builder takes inputs as IIngredient
// (so <ore:...> is fine there) but outputs as IItemStack, so an ore dictionary entry
// cannot be written directly as an output. The stacks below are pulled out of the ore
// dictionary instead. Note the member name: ZenScript exposes the Java getters of
// IOreDictEntry as properties (getFirstItem -> firstItem, getItems -> items, isEmpty ->
// empty), and calling the Java names fails with "No such member ... getFirstItem".
//
// Which stack comes back matters, so it was checked on a server run rather than assumed.
// These four entries hold exactly one stack each, and it is the GregTech meta item:
//
//   dustDesh         -> minespace:meta_dust:32003
//   dustMeteoricIron -> minespace:meta_dust:32001
//   dustTitanium     -> gregtech:meta_dust:113
//   ingotTitanium    -> gregtech:meta_ingot:113
//
// (ingotDesh and ingotMeteoricIron, by contrast, hold two stacks each and Galacticraft's
// is the *first* one for meteoric iron - which is why nothing here uses firstItem on a
// name Galacticraft also registers.)
val dustDesh = oreDict.get("dustDesh").firstItem;
val dustMeteoricIron = oreDict.get("dustMeteoricIron").firstItem;
val dustTitanium = oreDict.get("dustTitanium").firstItem;
val ingotTitanium = oreDict.get("ingotTitanium").firstItem;

// ============================================================== Macerator
// Desh: ore -> unrefined desh -> dust, and the storage block mills back into 9 dust.
// GT5: Macerator.addRecipe(item.null * 2, tile.mars:2) / (desh dust, item.null).
mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftplanets:mars:2>)
    .outputs(<galacticraftplanets:item_basic_mars:0> * 2)
    .duration(300).EUt(8)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_mars:0>)
    .outputs(dustDesh)
    .duration(200).EUt(8)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftplanets:mars:8>)
    .outputs(dustDesh * 9)
    .duration(600).EUt(8)
    .buildAndRegister();

// Meteoric iron. The block and the raw drop are Galacticraft's, the dust is GregTech's,
// which is what pulls meteoric iron into the GregTech chain (and feeds desh_steel).
// GT5: Macerator.addRecipe(meteoric iron dust * 9, tile.gcBlockCore:12) /
//      (item.meteoricIronRaw * 2, tile.fallenMeteor).
mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftcore:basic_block_core:9>)
    .outputs(dustMeteoricIron * 9)
    .duration(600).EUt(8)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftcore:fallen_meteor>)
    .outputs(<galacticraftcore:meteoric_iron_raw> * 2)
    .duration(300).EUt(8)
    .buildAndRegister();

// Galacticraft's own meteoric iron ingot also mills down to GregTech dust, so the two
// metals are interchangeable instead of the Galacticraft one being a dead end.
mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftcore:item_basic_moon:0>)
    .outputs(dustMeteoricIron)
    .duration(200).EUt(8)
    .buildAndRegister();

// Titanium. GT5: Macerator.addRecipe(itemBasicAsteroids:4 * 2, asteroidsBlock:4).
mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftplanets:asteroids_block:4>)
    .outputs(<galacticraftplanets:item_basic_asteroids:4> * 2)
    .duration(300).EUt(8)
    .buildAndRegister();

// Same shape as the desh block above, for consistency: titanium block -> 9 titanium dust.
mods.gregtech.recipe.RecipeMap.getByName("macerator").recipeBuilder()
    .inputs(<galacticraftplanets:asteroids_block:7>)
    .outputs(dustTitanium * 9)
    .duration(600).EUt(8)
    .buildAndRegister();

// ============================================================== Compressor (nothing to add)
// GT5 turned 9 meteoric iron / 9 desh ingots into Galacticraft's storage blocks here.
// GregTech does not need that ported: because both materials carry the ingot flag, GTCEu
// already registers its own block items and the matching "9 ingots -> block" compressor
// recipes. Writing them again was rejected on the first test run with
//
//   Recipe duplicate or conflict found in RecipeMap compressor ... inputs([ingotDesh * 9])
//   ... Which conflicts with ... outputs([<metaitem:blockDesh>])
//
// so the GT recipe wins and nothing is added here.

// ============================================================== Implosion compressor
// Galacticraft's compressed plates (made by its own Electric Compressor) also come out of
// GregTech's implosion compressor, from GregTech plates plus TNT - this is the step that
// makes Galacticraft's machine components reachable from the GregTech chain.
// GT5: ImplosionCompressor.addRecipe(<basicItem>, <plate> * 2, 4)  [4 = TNT].
mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateCopper> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:6>)
    .duration(20).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateTin> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:7>)
    .duration(20).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateAluminium> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:8>)
    .duration(20).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateSteel> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:9>)
    .duration(20).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateBronze> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:10>)
    .duration(20).EUt(30)
    .buildAndRegister();

mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateIron> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:basic_item:11>)
    .duration(20).EUt(30)
    .buildAndRegister();

// Compressed titanium (GT5 used itemBasicAsteroids:6 here).
mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateTitanium> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftplanets:item_basic_asteroids:6>)
    .duration(20).EUt(30)
    .buildAndRegister();

// Compressed desh - the same shape as the seven above, and it was missing.
//
// Gregicality's mis-pointed desh plate recipes (one desh ingot in a bender, and the rest of the
// family) used to be the only source of `item_basic_mars:5`, so nothing noticed the hole while they
// existed; `MinespaceCompressedPlateGuard` turns them back into plain GregTech desh plates, which is
// what they were meant to be, and Galacticraft's Mars parts (assembler_2.zs, gaps.zs, hightech.zs)
// are built from the compressed plate. Mars would have been unbuildable. Two desh plates plus TNT is
// exactly the price the other seven metals pay.
mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateDesh> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftplanets:item_basic_mars:5>)
    .duration(20).EUt(30)
    .buildAndRegister();

// ============================================================== Electric blast furnace
// Titanium ingots out of titanium shards; GT5:
// BlastFurnace.addRecipe(titanium ingot, itemBasicAsteroids:4 * 2, null, 1500, 120, 1500)
// - 1500 ticks, 120 EU/t, 1500 K. GTCEu takes the temperature as a recipe property.
mods.gregtech.recipe.RecipeMap.getByName("blast_furnace").recipeBuilder()
    .inputs(<galacticraftplanets:item_basic_asteroids:4> * 2)
    .outputs(ingotTitanium)
    .property("temperature", 1500)
    .duration(1500).EUt(120)
    .buildAndRegister();

// ============================================================== Fluids
// Galacticraft's own fluid and gas machines are removed in gc_gregify_removals.zs (Refinery,
// Oxygen Collector, Gas Liquefier, Methane Synthesizer, Water Electrolyzer), so the two
// fluids a rocket and a space suit actually need - rocket fuel and breathable oxygen - are
// produced by GregTech instead.
//
// The registry names were checked on a server run before being written here, because
// Galacticraft silently falls back to "oilgc" / "fuelgc" when another mod already owns "oil" /
// "fuel" (config: useOldOilFluidID / useOldFuelFluidID), and GregTech registers a lot of
// fluids. The run reported:
//
//   registered:     fuel, oil, oxygen, hydrogen, methane, liquid_oxygen, sulfuric_acid,
//                   bacterial_sludge
//   not registered: fuelgc, oilgc, methanegc, liquid_nitrogen, liquid_argon
//
// so these are Galacticraft's own fluids and a GregTech recipe can point straight at them.
// If a later Galacticraft moves to the "gc" names, this is the only place to change.

// Crude oil -> rocket fuel, the job of Galacticraft's Refinery, at the same 1:1 ratio.
// GTCE-TJ's distillery takes exactly one *item* input, so the recipe needs an integrated
// circuit even though it is a pure fluid conversion - without .circuit(1) it is rejected with
// "Invalid amount of recipe inputs. Actual: 0. Should be between 1 and 1 inclusive."
mods.gregtech.recipe.RecipeMap.getByName("distillery").recipeBuilder()
    .circuit(1)
    .fluidInputs(<liquid:oil> * 1000)
    .fluidOutputs(<liquid:fuel> * 1000)
    .duration(100).EUt(30)
    .buildAndRegister();

// Breathable oxygen out of the air, the job of Galacticraft's Oxygen Collector. GTCEu's gas
// collector is dimension based (the Overworld is dimension 0, the same place Galacticraft's
// collector worked) and it selects what to collect with the integrated circuit, exactly like
// GTCEu's own three recipes do: circuit 1 -> air, 2 -> nether air, 3 -> ender air, all 10000
// mB in 200 ticks at 16 EU/t. Oxygen therefore takes circuit 4. Without .circuit() the recipe
// is rejected with "Invalid amount of recipe inputs. Recipe inputs are empty." - the gas
// collector has no item input of its own, the circuit *is* the input.
//
// Oxygen produced here is carried in Galacticraft's own tanks; adding the Moon (dimension -28)
// or Mars (-29) as collection sites is one extra recipe each, should that turn out to be
// wanted.
// UNPORTABLE - GTCE-TJ has no gas collector recipe map, so this statement
// cannot be ported. Oxygen comes from GregTech's electrolyser (water ->
// hydrogen + oxygen) and is bottled by the addon's Oxygen Compressor.
// mods.gregtech.recipe.RecipeMap.getByName("gas_collector").recipeBuilder()
//     .circuit(4)
//     .fluidOutputs(<liquid:oxygen> * 1000)
//     .property("dimension", 0)
//     .duration(200).EUt(16)
//     .buildAndRegister();

// ======================== Gregicality's "free" producers for Galacticraft's compressed plates
//
// The compressed plate is the pack's "dense" tier for Galacticraft's metals, and this file is where
// its price is set: an implosion compressor, two GregTech plates plus TNT (the recipes above). That
// must be the only route.
//
// It was not. Gregicality unifies a mod's material forms onto GregTech's machines, and because
// Galacticraft registers its compressed plates in the ore dictionary it generated a full set of
// "make this item out of GregTech material" recipes for them, which made the dense plate cheaper than
// the plain one - a bender turning 1 steel INGOT into 1 compressed steel plate, a forge hammer turning
// 3 ingots into 2, a cutting saw turning 1 steel BLOCK into 9, and so on, on every map from
// metal_bender to electric_implosion, for every metal in the family (copper, tin, aluminium, steel,
// bronze, iron, titanium, desh, meteoric iron).
//
// Those cannot be removed from here: CraftTweaker's GregTech integration exposes no recipe-removal
// method for a machine map, and Gregicality registers them in its own init / postInit, so a script
// either cannot see them or is not allowed to touch them. The pack's own rule applies (section 6e):
// "a mod which registers after CraftTweaker can only be undone in that mod's own config, or through a
// late removal in the addon (FMLLoadCompleteEvent), never through a script". So the removal lives in
//
//     src/main/java/com/minespace/unofficial/gtceu/MinespaceCompressedPlateGuard.java
//
// and runs from this mod's postInit and again at load complete. It leaves the implosion compressor
// alone, because that is where the recipes above live.

