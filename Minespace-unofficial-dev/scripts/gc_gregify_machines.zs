// CraftTweaker port of the "Mods-Get-Gregged" Galacticraft machine recipes.
//
// The original is Minetweaker/CraftTweaker ZenScript from a GT5 pack, but GT5 exposed one
// script class per machine (mods.gregtech.Assembler.addRecipe, mods.gregtech.PlateBender, ...).
// GTCEu (CE Unofficial) exposes the same machines through its RecipeMap bracket handler, so
// the port is a mechanical rewrite:
//
//     PlateBender.addRecipe(out, in * 2, 200, 8);
//  -> <recipemap:bender>.recipeBuilder()
//         .inputs(in * 2).outputs(out).duration(200).EUt(8).buildAndRegister();
//
// RecipeMap names are the unlocalised names GTCEu registers (read from RecipeMaps.class):
// assembler, bender, canner, macerator, electric_blast_furnace, vacuum_freezer, extruder,
// wiremill, arc_furnace, mixer, chemical_reactor, ... The GT5 scripts' `gt.metaitem.01:xxxxx`
// numbers do not exist in GTCEu, so ingredients are addressed by ore dictionary instead.
//
// EUt: GTCEu's lowest usable tier is ULV = 8 EU/t, and the GT5 scripts sometimes used 1.
// Those are raised to 8 here.

// -------------------------------------------------------------------------- Canner
// The source cans food with the GT canner instead of letting Galacticraft do it in a
// crafting grid. GC 4.0.7's canned food is basic_item meta 15..18 (dehydrated apple /
// carrot / melon / potato - the metadata is the index into ItemBasic's `names` array,
// read out of the jar with javap; see the note in gc_gregify_crafting.zs), and the empty
// can is galacticraftcore:canister (meta 0 = tin canister).
<recipemap:canner>.recipeBuilder()
    .inputs(<minecraft:apple> * 6, <galacticraftcore:canister>)
    .outputs(<galacticraftcore:basic_item:15>)
    .duration(800).EUt(8)
    .buildAndRegister();

<recipemap:canner>.recipeBuilder()
    .inputs(<minecraft:carrot> * 8, <galacticraftcore:canister>)
    .outputs(<galacticraftcore:basic_item:16>)
    .duration(800).EUt(8)
    .buildAndRegister();

<recipemap:canner>.recipeBuilder()
    .inputs(<minecraft:melon> * 8, <galacticraftcore:canister>)
    .outputs(<galacticraftcore:basic_item:17>)
    .duration(800).EUt(8)
    .buildAndRegister();

<recipemap:canner>.recipeBuilder()
    .inputs(<minecraft:potato> * 16, <galacticraftcore:canister>)
    .outputs(<galacticraftcore:basic_item:18>)
    .duration(800).EUt(8)
    .buildAndRegister();

// -------------------------------------------------------------------------- Bender
// The source bends the canisters out of compressed plate instead of crafting them:
// tin canister (canister meta 0) from compressed tin, copper canister (meta 1) from
// compressed copper. In GC 4.0.7 those are basic_item meta 7 and meta 6.
<recipemap:bender>.recipeBuilder()
    .inputs(<ore:compressedTin> * 2)
    .outputs(<galacticraftcore:canister>)
    .duration(200).EUt(8)
    .buildAndRegister();

<recipemap:bender>.recipeBuilder()
    .inputs(<ore:compressedCopper> * 2)
    .outputs(<galacticraftcore:canister:1>)
    .duration(200).EUt(8)
    .buildAndRegister();

// -------------------------------------------------------------------------- Assembler
// Straight port of the source's one simple assembler recipe that uses no GT meta items:
// glowstone dust + redstone torch -> Galacticraft's glowstone torch.
<recipemap:assembler>.recipeBuilder()
    .inputs(<minecraft:redstone_torch>, <minecraft:glowstone_dust>)
    .outputs(<galacticraftcore:glowstone_torch>)
    .duration(200).EUt(16)
    .buildAndRegister();
