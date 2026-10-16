#priority 800
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Gap fixes for the chains that lost an ingredient to this pack's machine removals.
//
// The removals in gc_gregify_removals.zs / gs_gregify_removals.zs take Galacticraft's and Galaxy
// Space's own machines out of the crafting grid (GregTech replaces them). Some *other* recipes
// used those machines as an ingredient, and picked this way they can never be built again:
//
//   Astro Miner Base        needed machine_tiered:0  (Energy Storage Module)
//   Rocket Assembly         needed machine2:0 / machine2:4 (Electric Compressor, Circuit
//                           Fabricator) and galaxyspace:assembly_machine
//   Air Lock Frame          needed item_basic_moon:1 (compressed meteoric iron), whose own
//                           recipe the pack removes
//
// This file loads last on purpose (zz_ prefix, CraftTweaker loads scripts in name order): the
// removal scripts run first, and anything added here survives.
//
// The replacements follow the pack's own rule - a removed machine becomes GregTech parts of a
// comparable tier, everything Galacticraft-specific stays as it was.

// ------------------------------------------------------- compressed meteoric iron
// Same shape as the other compressed plates in gc_gregify_processing.zs: two GregTech plates plus
// TNT in the implosion compressor. This is what keeps the Air Lock Frame chain alive, because that
// recipe is built from <ore:compressedMeteoricIron>.
mods.gregtech.recipe.RecipeMap.getByName("implosion_compressor").recipeBuilder()
    .inputs(<ore:plateMeteoricIron> * 2)
    .property("explosives", 4)
    .outputs(<galacticraftcore:item_basic_moon:1>)
    .duration(20).EUt(30)
    .buildAndRegister();

// --------------------------------------------------- Galacticraft's planet-metal ingots
// gc_gregify_removals.zs takes Galacticraft's own desh and lead ingots out of the crafting grid -
// they duplicate GregTech's, and ingotDesh / ingotLead both list GregTech's ingot first - but
// Galacticraft's own desh armour and tools, the arc lamp, the atmospheric valve, the Mars machine
// block and the atomic battery are written against the exact item ids
// `galacticraftplanets:item_basic_mars:2` and `basic_item_venus:1` rather than against the ore
// dictionary. A dead-recipe audit found 18 recipes that would have become unbuildable. They stay
// reachable through GregTech instead: one GregTech ingot converts to one Galacticraft ingot, so the
// metal still comes out of GregTech's chain while Galacticraft's own recipes keep working.
//
// (The titanium ingot, `item_basic_asteroids:0`, needed no bridge: once its own "cut the storage
// block back down" recipe is gone, nothing in the pack asks for it by id.)
//
// UPDATE 2026-10-12: these two bridges stay, and they are the owner's rule working as intended. The
// rule is "an item that needed another mod's *machine* should be made in a GregTech machine instead;
// an item the crafting table can make should be re-costed in GregTech materials" - not "delete the
// mods' crafting recipes". The bridges are crafting-table recipes that turn GregTech's ingot into
// Galacticraft's, which keeps Galacticraft's armour, arc lamp, atmospheric valve, Mars machine block
// and atomic battery buildable without a mod machine in the chain.
// UPDATE 2026-10-14 (section 6cf): the *desh* bridge is now redundant and is deleted again at load
// time by `MinespaceMaterialRepoint.removeDeadDuplicateCrafting`. The input re-point pass rewrites
// Galacticraft's own recipes to ask for GregTech's desh ingot directly, so nothing consumes
// `item_basic_mars:2` any more and the bridge would only keep a dead duplicate alive in JEI. The line
// stays as insurance in case that pass ever fails to run. The *lead* bridge is still load-bearing: a
// Galacticraft recipe does keep asking for `basic_item_venus:1` by id (its ingredient list is mixed,
// so the conservative re-point leaves it alone), which is why it is still here and still hidden from
// JEI as a bridge item rather than a duplicate a player would want to make.
recipes.addShapeless(<galacticraftplanets:item_basic_mars:2>, [<gregtech:meta_item_1:10000>]);
recipes.addShapeless(<galacticraftplanets:basic_item_venus:1>, [<gregtech:meta_item_1:10035>]);

// ------------------------------------------------------------ certus quartz: AE2 crystal <-> GT gem
// The same kind of bridge, for the one material where the mod's item is not a copy of GregTech's but
// AE2's own form of it - and where AE2 addresses it by item id. AE2's certus quartz crystal
// (`appliedenergistics2:material:0`) is what its charger, its inscriber and this pack's own AE2
// assembler recipes all ask for by *item*, so it cannot be replaced by GregTech's material; the
// player's way to the AE2 crystal was AE2's own meteorite ore, and GregTech's certus quartz - which
// the pack now generates as a vein on the Moon, Mars, Venus, the Galaxy Space bodies and a quarter of
// the overworld's quartz vein - produced a gem nothing in AE2 would take.
//
// One crystal is one gem, in both directions, so nothing is gained or lost: a player whose certus
// quartz came out of a GregTech vein can build the whole AE2 line, and AE2's meteorite crystals can
// be turned into GregTech's material for the GregTech recipes that want it. `oredict.zs` also adds
// GregTech's gem to `crystalCertusQuartz`, so every recipe written against that name takes either
// form without the conversion.
recipes.addShapeless(<appliedenergistics2:material:0>, [<gregtech:meta_item_1:8202>]);
recipes.addShapeless(<gregtech:meta_item_1:8202>, [<appliedenergistics2:material:0>]);

// --------------------------------------------------------------- Astro Miner Base - removed 2026-10-14
// This block used to rebuild Galacticraft's Astro Miner Base, whose own grid wanted the Energy
// Storage Module this pack deletes (an MV circuit filled that slot). GC-GREGFICATION-PLAN.md's
// "Still to do" table then decided the machine itself: "GregTech's ore/fluid drilling plants replace
// the job", so the base is removed rather than re-costed - its grid, the assembler recipe beside it
// in `hightech.zs`, its JEI category and its item are all gone now (`gc_removals.zs`).

// --------------------------------------------------------------- Rocket Assembly (Galaxy Space)
// Original: 2x advanced wafer, Rocket Workbench, Electric Compressor, machine frame, Circuit
// Fabricator, 2x heavy aluminium wire, Assembly Machine. The three machines are all removed;
// HV circuits stand in for the two compressor/fabricator slots and the compressed titanium plate -
// what the original asked for - for the assembly machine's tooling. (Galaxy Space's recipes used
// the shared `plateTitanium` name, which meant Galacticraft's compressed plate; see
// aa_minespace_oredict.zs and the matching section of gs_gregify_removals.zs.)
recipes.remove(<galaxyspace:rocket_assembler>);
recipes.addShaped(<galaxyspace:rocket_assembler>, [
    [<galacticraftcore:basic_item:14>,      <galacticraftcore:rocket_workbench>, <galacticraftcore:basic_item:14>],
    [<ore:circuitAdvanced>,                 <galaxyspace:machineframes>,         <ore:circuitAdvanced>],
    [<galacticraftcore:aluminum_wire:1>,    <ore:compressedTitanium>,            <galacticraftcore:aluminum_wire:1>]
]);

// ------------------------------------------------- Galaxy Space's Modern Wafer
// `galaxyspace:gs_basic:5` (WAFER_MODERN) was made in Galacticraft's **Circuit Fabricator**, which
// this pack clears (`MinespaceGalacticraftMachineRecipes`), so it had no source at all - and eight
// assembler recipes in this pack are built from it, including three of Galaxy Space's machines. A
// progression probe over the finished registries found it as a dead ingredient.
//
// Galaxy Space registers it from its own source (`.../overworld/recipes/CraftingRecipesOverworld`,
// `addCircuitFabricator()`) as the third rung of Galacticraft's wafer ladder: a diamond, two raw
// silicon and the *previous* wafer (`galacticraftcore:basic_item:14`, the advanced wafer). So it is
// the third rung, one tier above the advanced wafer - and the advanced wafer is now engraved out of
// GregTech's CPU Wafer in `gc_removals.zs`, using GregTech's own laser engraver, its own gem lens
// and its own engraving tiers. This rung is written the same way and one tier up: GregTech's
// **High-Power IC Wafer** (which is GregTech's PIC Wafer plus 2x indium in the chemical reactor, so
// the top of GregTech's own integrated-circuit line) engraved with the sapphire lens GregTech uses
// for the PIC Wafer, at GregTech's own 1920 EU/t engraving tier.
mods.gregtech.recipe.RecipeMap.getByName("laser_engraver").recipeBuilder()
    .inputs(<gregtech:meta_item_2:32465> * 2)
    .notConsumable(<ore:lensSapphire>)
    .outputs(<galaxyspace:gs_basic:5>)
    .duration(1200).EUt(1920)
    .buildAndRegister();

// ------------------------------------------- Galacticraft's Mars Heavy-Duty Plate
// `galacticraftplanets:item_basic_mars:3` (Heavy-Duty Plate, the Mars tier) was a **Compressor**
// recipe, cleared with the rest of them. It is what the pack's own Mars machine block needs
// (`assembler_2.zs`, 2 per machine) and what Galacticraft's own `item_basic_asteroids:2` recipe
// asks for, and with it gone the pack's Mars machine recipe was dead. Galacticraft's source has
// the exact recipe
// (`.../planets/mars/recipe/RecipeManagerMars`, `addUniversalRecipes()`):
//
//     Heavy-Duty Plate (Mars)  <-  1x Tier-1 Heavy-Duty Plate + 1x compressed meteoric iron
//
// It is the GT **assembler** that takes over, not the compressor, and that is not a choice: GTCE-TJ
// declares the compressor map with exactly one item input ("Invalid amount of recipe inputs. Actual:
// 2. Should be between 1 and 1 inclusive." - the first version of this recipe was rejected on load),
// while Galacticraft's recipe combines two *different* items. The cost is Galacticraft's own, not
// invented, and the tier is the same LV 30 the other Heavy-Duty Plate recipe runs at.
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<galacticraftcore:heavy_plating>, <galacticraftcore:item_basic_moon:1>)
    .circuit(1)
    .outputs(<galacticraftplanets:item_basic_mars:3>)
    .duration(200).EUt(30)
    .buildAndRegister();
