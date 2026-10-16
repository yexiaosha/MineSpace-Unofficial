#priority 700
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Ender IO's ten alloys, its seven "endergy" alloys and Enderium Base are GregTech materials - the
// ingot, the nugget, the block, the dust and the molten fluid, and nothing else (see
// MinespaceMaterials.ENDER_IO_ALLOYS / .ENDER_IO_ENDERGY_ALLOYS / .ENDER_IO_OTHER_INGOTS). The shared
// ore dictionary names follow the pack's rule - the GregTech item wins - and `MinespaceMaterialRepoint`
// re-points the machine outputs, the machine *inputs* and the crafting-table inputs that used to hand
// out or eat Ender IO's copy.
//
// What it cannot re-point from Java is a crafting-table **output**: `IRecipe#getRecipeOutput()` is
// computed, not stored, so the only way to change what a recipe produces is to replace the recipe.
// Ender IO's auto-generated conversion recipes are exactly that case, and they are all switched off
// here rather than rebuilt:
//
//   9 ingots -> 1 block     the compressor's job   (GregTech has it for every one of these)
//   block -> 9 ingots       the decompressor's job (GregTech's alloy smelter / macerator have it)
//   9 nuggets -> 1 ingot    the compressor's job   (GregTech has it, see TJ-MIGRATION-PLAN.md 6bb)
//
// and the fourth - **1 ingot -> 9 nuggets** - goes with them since 2026-10-13. That one used to be kept
// because Ender IO's grinding balls are cast from its own nuggets, but the audit in **6bd** found the
// ball recipes the mod actually ships are the crafting-table ones (five **ingots** in a cross into
// twenty-four balls, for the ten alloys and, via the Endergy addon, for the seven), and the casting
// forms want Tinkers Construct, which this pack does not have. So the mod's nugget has no consumer left:
// every recipe that reads `nuggetX` by ore name gets GregTech's nugget, and Ender IO's own nugget items
// are produced by nothing once this file has run - which is what lets `jei_dupes.zs` hide them.
//
// The owner's call, 2026-10-13, supersedes what earlier versions of this file did: those three
// directions used to be rebuilt against GregTech's ingot or block, which left the crafting table
// doing the compressor's work. With the machine routes back in place (6bb) they are simply removed.

// ---- Dark Steel
recipes.remove(<enderio:item_alloy_ingot:6>);
recipes.remove(<enderio:block_alloy:6>);

// ---- Electrical Steel
recipes.remove(<enderio:item_alloy_ingot:0>);
recipes.remove(<enderio:block_alloy:0>);

// ---- Energetic Alloy
recipes.remove(<enderio:item_alloy_ingot:1>);
recipes.remove(<enderio:block_alloy:1>);

// ---- Vibrant Alloy
recipes.remove(<enderio:item_alloy_ingot:2>);
recipes.remove(<enderio:block_alloy:2>);

// ---- Redstone Alloy
recipes.remove(<enderio:item_alloy_ingot:3>);
recipes.remove(<enderio:block_alloy:3>);

// ---- Conductive Iron
recipes.remove(<enderio:item_alloy_ingot:4>);
recipes.remove(<enderio:block_alloy:4>);

// ---- Pulsating Iron
recipes.remove(<enderio:item_alloy_ingot:5>);
recipes.remove(<enderio:block_alloy:5>);

// ---- Soularium
recipes.remove(<enderio:item_alloy_ingot:7>);
recipes.remove(<enderio:block_alloy:7>);

// ---- End Steel
recipes.remove(<enderio:item_alloy_ingot:8>);
recipes.remove(<enderio:block_alloy:8>);

// ---- Construction Alloy ("Iron Alloy" in Ender IO's own lang file)
recipes.remove(<enderio:item_alloy_ingot:9>);
recipes.remove(<enderio:block_alloy:9>);

// ---- Ender IO's seven "endergy" alloys
// The mod ships the ingot, the nugget, the block and a grinding ball for each, but no production
// recipe at all - the Endergy module that used to make them is gone. Registering them as GregTech
// materials at least gives the family GregTech's own ingot / nugget / block / dust / fluid and
// GregTech's own machine routes between them (6bb).
recipes.remove(<enderio:item_alloy_endergy_ingot:0>);
recipes.remove(<enderio:block_alloy_endergy:0>);

recipes.remove(<enderio:item_alloy_endergy_ingot:1>);
recipes.remove(<enderio:block_alloy_endergy:1>);

recipes.remove(<enderio:item_alloy_endergy_ingot:2>);
recipes.remove(<enderio:block_alloy_endergy:2>);

recipes.remove(<enderio:item_alloy_endergy_ingot:3>);
recipes.remove(<enderio:block_alloy_endergy:3>);

recipes.remove(<enderio:item_alloy_endergy_ingot:4>);
recipes.remove(<enderio:block_alloy_endergy:4>);

recipes.remove(<enderio:item_alloy_endergy_ingot:5>);
recipes.remove(<enderio:block_alloy_endergy:5>);

recipes.remove(<enderio:item_alloy_endergy_ingot:6>);
recipes.remove(<enderio:block_alloy_endergy:6>);

// ---- and with them the mod's nuggets
// Removing a recipe by its *output* takes every recipe that makes it: Ender IO's own
// `auto_<alloy>_1_ingot_to_9_nuggets` from `generated.xml` and Gregicality's mirrored
// `nugget_disassembling_<alloy>`, which are the same table step written twice. GregTech's unpacker and
// alloy smelter still turn GregTech's ingot into GregTech's nugget, which is what every ore-name reader
// gets; only Ender IO's own item disappears, and it has no consumer left (see the header).
recipes.remove(<enderio:item_alloy_nugget:0>);
recipes.remove(<enderio:item_alloy_nugget:1>);
recipes.remove(<enderio:item_alloy_nugget:2>);
recipes.remove(<enderio:item_alloy_nugget:3>);
recipes.remove(<enderio:item_alloy_nugget:4>);
recipes.remove(<enderio:item_alloy_nugget:5>);
recipes.remove(<enderio:item_alloy_nugget:6>);
recipes.remove(<enderio:item_alloy_nugget:7>);
recipes.remove(<enderio:item_alloy_nugget:8>);
recipes.remove(<enderio:item_alloy_nugget:9>);
recipes.remove(<enderio:item_alloy_endergy_nugget:0>);
recipes.remove(<enderio:item_alloy_endergy_nugget:1>);
recipes.remove(<enderio:item_alloy_endergy_nugget:2>);
recipes.remove(<enderio:item_alloy_endergy_nugget:3>);
recipes.remove(<enderio:item_alloy_endergy_nugget:4>);
recipes.remove(<enderio:item_alloy_endergy_nugget:5>);
recipes.remove(<enderio:item_alloy_endergy_nugget:6>);

// ---- The seven endergy grinding balls
// Their recipes are in the Endergy addon too (`assets/enderio/config/recipes/endergy_balls.xml`, read
// out of the 5.3.72 addon jar), and they are the same shape the ten alloys use: five ingots in a cross
// on the crafting table into twenty-four balls. The addon's other two forms are Tinkers casting
// recipes - they want `tconstruct:cast_custom:2`, Tinkers Construct is not in this pack, and Ender IO
// skips any recipe whose dependency is missing - so the cross is the only form that exists here.
// Without these the seven balls were unobtainable, which matters because they are what Ender IO's SAG
// Mill grinds with.
val crudeSteel = oreDict.get("ingotCrudeSteel").firstItem;
val crystallineAlloy = oreDict.get("ingotCrystallineAlloy").firstItem;
val melodicAlloy = oreDict.get("ingotMelodicAlloy").firstItem;
val stellarAlloy = oreDict.get("ingotStellarAlloy").firstItem;
val crystallinePinkSlime = oreDict.get("ingotCrystallinePinkSlime").firstItem;
val energeticSilver = oreDict.get("ingotEnergeticSilver").firstItem;
val vividAlloy = oreDict.get("ingotVividAlloy").firstItem;

recipes.addShaped(<enderio:item_alloy_endergy_ball:0> * 24, [
    [null, crudeSteel, null],
    [crudeSteel, crudeSteel, crudeSteel],
    [null, crudeSteel, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:1> * 24, [
    [null, crystallineAlloy, null],
    [crystallineAlloy, crystallineAlloy, crystallineAlloy],
    [null, crystallineAlloy, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:2> * 24, [
    [null, melodicAlloy, null],
    [melodicAlloy, melodicAlloy, melodicAlloy],
    [null, melodicAlloy, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:3> * 24, [
    [null, stellarAlloy, null],
    [stellarAlloy, stellarAlloy, stellarAlloy],
    [null, stellarAlloy, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:4> * 24, [
    [null, crystallinePinkSlime, null],
    [crystallinePinkSlime, crystallinePinkSlime, crystallinePinkSlime],
    [null, crystallinePinkSlime, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:5> * 24, [
    [null, energeticSilver, null],
    [energeticSilver, energeticSilver, energeticSilver],
    [null, energeticSilver, null]
]);
recipes.addShaped(<enderio:item_alloy_endergy_ball:6> * 24, [
    [null, vividAlloy, null],
    [vividAlloy, vividAlloy, vividAlloy],
    [null, vividAlloy, null]
]);

// ============================================================== The one dust that is not GregTech's yet
//
// Ender IO's SAG Mill used to turn the ten alloy ingots into their dusts. Section 6e made the alloys
// GregTech materials, so `dustDarkSteel` and its nine siblings now resolve to GregTech's dust, and
// the mill's copies are switched off in config/enderio/recipes/user/user_recipes.xml (see the pack
// plan, section 6az).
//
// GregTech does not need any help for nine of the ten: Gregicality generates the ingot -> dust
// recipe itself, which the run's de-duplication log confirms with merges such as
// `duplicate recipe merge: macerator 1xgregtech:meta_item_1:10179 -> 1xgregtech:meta_item_1:2179`.
// **Soularium is the exception.** `dustSoularium` used to hold Ender IO's own powder
// (`enderio:item_material:74`) *first*, and that membership is why Gregicality's generator built the
// mill's old output: its macerator recipe reads
// `macerator IN ingotSoularium ... OUT enderio:item_material:74` and the storage-block form reads
// `... OUT 9x enderio:item_material:74`. So there is nothing to add here: `scripts/oredict.zs` takes
// that powder out of the shared name, and `MinespaceMaterialRepoint` - which exists for exactly this
// case, a machine output that hands out a mod's copy of a pack material - re-points those outputs, and
// every other machine output that used the powder, at GregTech's dust.
