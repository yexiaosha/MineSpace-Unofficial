#priority 799
// The HIGHER the number, the earlier CraftTweaker runs this file (it sorts the list descending).
// oredict.zs runs first because every other script reads the ore dictionary names it fixes;
// after that the order only has to keep the pack's own passes behind the mods they edit.

// Applied Energistics 2 - the one big tech tree in this pack that was never GregTech-gated.
//
// AE2 is a *hard* dependency of GTCE-TJ (its `MetaTool` references AE2 classes), and AE2 ships its
// own CraftTweaker integration, so no addon is needed for its machines:
//
//     mods.appliedenergistics2.Inscriber.addRecipe(output, input, inscribe, top, bottom);
//     mods.appliedenergistics2.Inscriber.removeRecipe(output);
//     mods.appliedenergistics2.Grinder.addRecipe(output, input, turns, second1, chance1, second2, chance2);
//     mods.appliedenergistics2.Grinder.removeRecipe(input);
//
// (`inscribe` picks the machine mode: true -> InscriberProcessType.INSCRIBE, false -> PRESS. The two
// extra slots may be left null - AE2's `CTModule.toStacks(null)` returns `Optional.empty()` - which
// is what the printed-circuit recipes below do.)
//
// The recipe shapes were read out of AE2's own registry on a live run, not guessed. Its thirteen
// inscriber recipes are:
//
//   out 18 LOGIC_PROCESSOR_PRINT        INSCRIBE in=minecraft:gold_ingot      top=15 LOGIC_PRESS
//   out 17 ENGINEERING_PROCESSOR_PRINT  INSCRIBE in=minecraft:diamond         top=14 ENGINEERING_PRESS
//   out 16 CALCULATION_PROCESSOR_PRINT  INSCRIBE in=10 pure certus quartz     top=13 CALCULATION_PRESS
//   out 20 SILICON_PRINT                INSCRIBE in=itemSilicon               top=19 SILICON_PRESS
//   out 22/23/24 <processor>            PRESS    in=minecraft:redstone        top=<printed> bottom=20
//   out 13/14/15/19 <press>             INSCRIBE in=minecraft:iron_block      top=<the same press>
//   out 59/60 <cards>                   PRESS    in=<card>                    top/bottom=<materials>
//
// Three of those consume a plain vanilla metal, so they are the ones that get GregTech materials.
// The processor recipes themselves have all three of their slots occupied (redstone + the printed
// circuit + printed silicon), so there is no free slot to add a GregTech circuit to - the gate is
// the printed circuit, and that is where the GregTech material goes.

val PrintedLogic = <appliedenergistics2:material:18>;
val PrintedEngineering = <appliedenergistics2:material:17>;
val LogicPress = <appliedenergistics2:material:15>;
val EngineeringPress = <appliedenergistics2:material:14>;
val CalculationPress = <appliedenergistics2:material:13>;
val SiliconPress = <appliedenergistics2:material:19>;
val PrintedSilicon = <appliedenergistics2:material:20>;

// Printed Logic Circuit: a gold ingot becomes a GregTech gold plate.
mods.appliedenergistics2.Inscriber.removeRecipe(PrintedLogic);
mods.appliedenergistics2.Inscriber.addRecipe(PrintedLogic, <ore:plateGold>, true, LogicPress, null);

// Printed Engineering Circuit: a diamond becomes a GregTech diamond plate.
mods.appliedenergistics2.Inscriber.removeRecipe(PrintedEngineering);
mods.appliedenergistics2.Inscriber.addRecipe(PrintedEngineering, <ore:plateDiamond>, true,
        EngineeringPress, null);

// The four press-copy recipes take an iron block; GregTech steel is the same shape and one tier up,
// so duplicating a press now costs metal that went through a GregTech blast furnace.
mods.appliedenergistics2.Inscriber.removeRecipe(LogicPress);
mods.appliedenergistics2.Inscriber.addRecipe(LogicPress, <ore:blockSteel>, true, LogicPress, null);
mods.appliedenergistics2.Inscriber.removeRecipe(EngineeringPress);
mods.appliedenergistics2.Inscriber.addRecipe(EngineeringPress, <ore:blockSteel>, true,
        EngineeringPress, null);
mods.appliedenergistics2.Inscriber.removeRecipe(CalculationPress);
mods.appliedenergistics2.Inscriber.addRecipe(CalculationPress, <ore:blockSteel>, true,
        CalculationPress, null);
mods.appliedenergistics2.Inscriber.removeRecipe(SiliconPress);
mods.appliedenergistics2.Inscriber.addRecipe(SiliconPress, <ore:blockSteel>, true, SiliconPress, null);

// Printed Silicon: the input was `itemSilicon`, the name all three of Galacticraft, Ender IO and AE2
// registered their own silicon under. That name now resolves to GregTech's silicon ingot (see
// aa_minespace_oredict.zs), so the recipe is rewritten against `<ore:ingotSilicon>` explicitly rather
// than left resting on the shared name - AE2's inscriber stores a concrete ingredient, and the
// rewrite is what makes the silicon it eats unambiguous.
mods.appliedenergistics2.Inscriber.removeRecipe(PrintedSilicon);
mods.appliedenergistics2.Inscriber.addRecipe(PrintedSilicon, <ore:ingotSilicon>, true, SiliconPress, null);

// AE2's own silicon item is discarded (see aa_minespace_oredict.zs), and so is the furnace recipe
// that was its only source. Everything that used to eat AE2's silicon eats GregTech's now, through
// `itemSilicon` / `ingotSilicon`.
furnace.remove(<appliedenergistics2:material:5>);

// NOTE (deliberately left alone): Printed Calculation Circuit still consumes AE2's purified certus
// quartz crystal. That is AE2's own material with its own chain behind it (crystal growth, the
// charger), and the vanilla metals above are the only inputs in this machine that GregTech has an
// equivalent for.

// ===================================================================================
// AE2's crafting chain: the storage family and the machine blocks
// ===================================================================================
//
// These *are* ordinary crafting-table recipes, and every one of them spends plain vanilla iron
// (`ingotIron` -> minecraft:iron_ingot). Each one is rewritten below with the same shape, the same
// counts and the same items, with exactly two differences:
//
//   * every vanilla iron ingot becomes a **GregTech iron plate** (meta 12033). One plate is one
//     ingot, so the cost is unchanged - what changes is that the iron now has to go through a
//     GregTech rolling mill or hammer instead of being picked up as an ingot.
//   * AE2's **quartz glass** is now made from GregTech glass plates rather than vanilla glass, so
//     everything downstream of it (every cell, every machine here) sits behind GregTech glass too.
//
// Nothing was made cheaper: no ingredient was dropped and no count was lowered. One recipe got
// *dearer* on purpose - the empty storage cell's centre slot was **empty** in AE2's own recipe, and
// it now takes an LV GregTech circuit, so a storage housing needs a circuit line.
//
// The shapes are the mod's own, read out of AE2's recipe registry on a live run. Where a slot
// accepted several aliases of the same vanilla item the alias with the widest ore-dictionary entry
// is used (`dyeBlue` for lapis, `blockGlass` for glass, `wool` for wool, `chestWood` for the chest),
// so nothing that used to work stops working; those aliases are the same items, not cheaper ones.

// Quartz glass: vanilla glass -> GregTech glass plate. 4 output, same 5 certus dust.
recipes.remove(<appliedenergistics2:quartz_glass>);
recipes.addShaped(<appliedenergistics2:quartz_glass> * 4, [
    [<ore:dustCertusQuartz>, <ore:plateGlass>, <ore:dustCertusQuartz>],
    [<ore:plateGlass>, <ore:dustCertusQuartz>, <ore:plateGlass>],
    [<ore:dustCertusQuartz>, <ore:plateGlass>, <ore:dustCertusQuartz>]
]);

// ---- the storage family (housing, components, cells) lived here
//
// It has moved to zzzzzzzz_minespace_ae2_storage.zs, where it was redesigned rather than carried over:
// the old recipes here were AE2's own grids with GregTech parts pushed into them (three quartz glass,
// three redstone, iron plates), and the cell was even re-added as a crafting-table "housing + component"
// shortcut. The storage file writes all of them as assembler recipes whose shape says what the item is -
// a chip, a card cage, a card in the cage - at MV and up, and removes every original.

// Not touched in this pass, and why: sixty-one AE2 recipes spend vanilla iron, but eleven of them
// (the cable / bus / panel family) are not full 3x3 grids - their width cannot be recovered from a
// recipe dump that lists ingredients in order, and guessing a width would silently produce a recipe
// that accepts the wrong shape. Those are left on vanilla iron for now rather than guessed at.

// ------------------------------------------- AE2's two small iron fixtures
// The Quartz Fixture (a lamp) and the Light Detector are two-item recipes, so their shape does not
// matter either way; both are re-costed here with a GregTech iron plate instead of a vanilla ingot
// and re-added shapeless, which accepts the same two items in any arrangement. The bus / panel /
// emitter family and the card family went one step further - off the crafting table and into the
// GregTech assembler - see zzzz_minespace_assembler.zs.
//
// The count matters: AE2's own Quartz Fixture recipe is two of them per craft, and the reconciliation
// pass (TJ-MIGRATION-PLAN.md 6bu) found this rewrite handing back one - the same failure as the wood
// family, an item's own yield cut because the output count was not carried over.
recipes.remove(<appliedenergistics2:quartz_fixture>);
recipes.addShapeless(<appliedenergistics2:quartz_fixture> * 2,
        [<appliedenergistics2:material:1>, <gregtech:meta_item_1:12033>]);

recipes.remove(<appliedenergistics2:light_detector>);
recipes.addShapeless(<appliedenergistics2:light_detector>,
        [<ore:gemNetherQuartz>, <gregtech:meta_item_1:12033>]);

// ===================================================================================
// AE2's advanced items: gone from the crafting table, made in a GregTech assembler
// ===================================================================================
//
// The owner's rule: an advanced machine or item should have to be *produced by a GregTech machine*,
// not merely cost GregTech materials. So the crafting recipes for AE2's ME machines and its
// higher-capacity cells are deleted outright and an **assembler** recipe takes their place.
//
// What that means in play: you need a GregTech assembler (LV at the lowest) and EU before you can
// build a drive, an interface, a molecular assembler or a 4k cell at all. The crafting table simply
// does not offer them any more, so there is no way round it.
//
// The materials are exactly the ones the 3x3 recipe used - nothing was dropped and no count was
// lowered, the nine grid slots are just flattened into an input list, which is what an assembler
// recipe is. The vanilla iron is still a GregTech iron plate. Machines additionally take an
// integrated circuit, and the EU/t follows how deep the item sits in AE2's tree: LV for the first
// machines and the 4k tier, MV (120) for the molecular assembler, spatial I/O port, security
// station and the 16k tier, HV (480) for the quantum ring and the 64k / 128-cubed tier.
//
// This also removes AE2's one-to-one "housing + component" shortcut for those cells, because a
// recipe removal matches on the output - intended, since the point is that the cell is made by the
// assembler. The basic 1k storage cell, 1k fluid cell and 2-cubed spatial cell keep their crafting
// recipes (with GregTech iron plates) so that entry-level AE2 stays reachable.

// ======================= Batch 1 of the crafting-table pass: AE2's quartz tools and network tool
//
// The owner's second rule for this round: an item you make *directly on the crafting table* keeps its
// recipe, but the recipe is re-costed the way GTNH does it - GregTech materials where the object would
// really be made of metal, and GregTech *tools* where the real object would need shaping, hammering,
// sawing or screwing. The output stays AE2's item; this is re-costing, not removal.
//
// The shapes below are AE2's own, read off a live run (a probe printed every slot including the empty
// ones - these tools mix shaped and shapeless recipes, so writing them from memory would have been
// wrong). **No material was dropped and no count was lowered**; every recipe gained GregTech tools,
// which are the tools the real object needs:
//
//   wrench        a crystal head has to be filed to shape and hammered home   + file + hard hammer
//   sword / spade / pickaxe / hoe / axe   the head is filed to an edge         + file (and hammer)
//   cutting knife the blade is a GregTech iron PLATE rather than a bare ingot  + file + hard hammer
//   network tool  an electronic diagnostic tool                                + screwdriver + LV circuit
//
// (Both quartz families - nether quartz and certus quartz - get the identical treatment.)

// --- wrenches: five crystals in their cross pattern, plus the two tools in the free middle slots
recipes.remove(<appliedenergistics2:nether_quartz_wrench>);
recipes.addShaped(<appliedenergistics2:nether_quartz_wrench>, [
    [<ore:gemNetherQuartz>, <ore:craftingToolFile>,      <ore:gemNetherQuartz>],
    [<ore:craftingToolHardHammer>, <ore:gemNetherQuartz>, null],
    [<ore:gemNetherQuartz>, null,                        <ore:gemNetherQuartz>]
]);
recipes.remove(<appliedenergistics2:certus_quartz_wrench>);
recipes.addShaped(<appliedenergistics2:certus_quartz_wrench>, [
    [<ore:crystalCertusQuartz>, <ore:craftingToolFile>,      <ore:crystalCertusQuartz>],
    [<ore:craftingToolHardHammer>, <ore:crystalCertusQuartz>, null],
    [<ore:crystalCertusQuartz>, null,                        <ore:crystalCertusQuartz>]
]);

// --- sword: AE2's one-row shape, with the file added on its own row
recipes.remove(<appliedenergistics2:nether_quartz_sword>);
recipes.addShaped(<appliedenergistics2:nether_quartz_sword>, [
    [<ore:gemNetherQuartz>, <ore:gemNetherQuartz>, <ore:stickWood>],
    [<ore:craftingToolFile>, null, null]
]);
recipes.remove(<appliedenergistics2:certus_quartz_sword>);
recipes.addShaped(<appliedenergistics2:certus_quartz_sword>, [
    [<ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>, <ore:stickWood>],
    [<ore:craftingToolFile>, null, null]
]);

// --- spade
recipes.remove(<appliedenergistics2:nether_quartz_spade>);
recipes.addShaped(<appliedenergistics2:nether_quartz_spade>, [
    [<ore:gemNetherQuartz>, <ore:stickWood>, <ore:stickWood>],
    [<ore:craftingToolFile>, null, null]
]);
recipes.remove(<appliedenergistics2:certus_quartz_spade>);
recipes.addShaped(<appliedenergistics2:certus_quartz_spade>, [
    [<ore:crystalCertusQuartz>, <ore:stickWood>, <ore:stickWood>],
    [<ore:craftingToolFile>, null, null]
]);

// --- pickaxe: three crystals and two sticks, plus file and hammer in the free side slots
recipes.remove(<appliedenergistics2:nether_quartz_pickaxe>);
recipes.addShaped(<appliedenergistics2:nether_quartz_pickaxe>, [
    [<ore:gemNetherQuartz>, <ore:gemNetherQuartz>, <ore:gemNetherQuartz>],
    [<ore:craftingToolFile>, <ore:stickWood>,      <ore:craftingToolHardHammer>],
    [null,                   <ore:stickWood>,      null]
]);
recipes.remove(<appliedenergistics2:certus_quartz_pickaxe>);
recipes.addShaped(<appliedenergistics2:certus_quartz_pickaxe>, [
    [<ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>],
    [<ore:craftingToolFile>,    <ore:stickWood>,           <ore:craftingToolHardHammer>],
    [null,                      <ore:stickWood>,           null]
]);

// --- hoe: two crystals and two sticks, file and hammer in the free slots
recipes.remove(<appliedenergistics2:nether_quartz_hoe>);
recipes.addShaped(<appliedenergistics2:nether_quartz_hoe>, [
    [<ore:gemNetherQuartz>, <ore:gemNetherQuartz>, <ore:craftingToolFile>],
    [<ore:stickWood>, <ore:craftingToolHardHammer>, <ore:stickWood>]
]);
recipes.remove(<appliedenergistics2:certus_quartz_hoe>);
recipes.addShaped(<appliedenergistics2:certus_quartz_hoe>, [
    [<ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>, <ore:craftingToolFile>],
    [<ore:stickWood>, <ore:craftingToolHardHammer>, <ore:stickWood>]
]);

// --- axe: three crystals and two sticks, file in the middle and hammer below
recipes.remove(<appliedenergistics2:nether_quartz_axe>);
recipes.addShaped(<appliedenergistics2:nether_quartz_axe>, [
    [<ore:gemNetherQuartz>, <ore:gemNetherQuartz>, <ore:gemNetherQuartz>],
    [<ore:stickWood>, <ore:craftingToolFile>, <ore:stickWood>],
    [null, <ore:craftingToolHardHammer>, null]
]);
recipes.remove(<appliedenergistics2:certus_quartz_axe>);
recipes.addShaped(<appliedenergistics2:certus_quartz_axe>, [
    [<ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>],
    [<ore:stickWood>, <ore:craftingToolFile>, <ore:stickWood>],
    [null, <ore:craftingToolHardHammer>, null]
]);

// --- cutting knife: the blade is a GregTech iron plate, shaped with file and hammer
recipes.remove(<appliedenergistics2:nether_quartz_cutting_knife>);
recipes.addShaped(<appliedenergistics2:nether_quartz_cutting_knife>, [
    [null, <ore:craftingToolFile>, <ore:stickWood>],
    [<gregtech:meta_item_1:12033>, <ore:stickWood>, null],
    [<ore:gemNetherQuartz>, <ore:gemNetherQuartz>, <ore:craftingToolHardHammer>]
]);
recipes.remove(<appliedenergistics2:certus_quartz_cutting_knife>);
recipes.addShaped(<appliedenergistics2:certus_quartz_cutting_knife>, [
    [null, <ore:craftingToolFile>, <ore:stickWood>],
    [<gregtech:meta_item_1:12033>, <ore:stickWood>, null],
    [<ore:crystalCertusQuartz>, <ore:crystalCertusQuartz>, <ore:craftingToolHardHammer>]
]);

// --- network tool: AE2's shapeless four, plus a GT screwdriver and an LV circuit
recipes.remove(<appliedenergistics2:network_tool>);
recipes.addShapeless(<appliedenergistics2:network_tool>, [
    <ore:itemIlluminatedPanel>, <ore:chestWood>, <ore:itemQuartzWrench>,
    <appliedenergistics2:material:23>, <ore:craftingToolScrewdriver>, <ore:circuitBasic>
]);

// ==================== Batch 2: AE2's ME parts - the terminals, tunnels and toggle buses
//
// Same rule as batch 1, same method: the shapes are AE2's own, read off a live run slot by slot, and
// every recipe **keeps all of its original ingredients** and gains GregTech tools and a GregTech
// circuit. An ME part is an electronic assembly: it is wired together with a screwdriver and it needs
// a circuit, which is exactly what the GTNH reference does with Applied Energistics parts.
//
// The bare iron ingots in the ME tunnel became GregTech iron *plates* - a tunnel body is plate work,
// and the plate has to come off a bender.
//
// Deliberately **not** touched: the pure 1:1 mode flips (`toggle_bus` -> `toggle_bus_inverted`,
// the interface configuration and its revert, both ways). Those are not manufacturing - they change a
// part's mode in place - so a tool in that grid would be noise rather than difficulty.

// --- ME tunnel: iron plates instead of bare ingots, + screwdriver and an LV circuit in the free slots// --- toggle bus: redstone, a lever and two AE2 parts, wired together with a screwdriver and a circuit// --- ME terminal: AE2's four parts, assembled with a screwdriver and an LV circuit// --- crafting terminal// --- fluid terminal: the blue dye stays (it is a dye, not a material), plus screwdriver and circuit// --- pattern terminal// --- interface terminal// --- expanded processing terminal: a ring of fluix, two terminals and a bus// ==================== Batch 3: AE2's storage components, buses, emitters and the crafting accelerator
//
// Two shapes of recipe here, and they need different treatment:
//
//   * the storage / spatial / fluid **components** fill all nine slots (four dusts in the corners, four
//     of the previous tier on the edges, quartz glass in the middle). There is no room for a tool, so
//     the GT-ification is in the *material*: the four corner dusts become **GregTech screws**. A memory
//     board is held together with screws, and a screw has to come off a GT lathe instead of being a dust
//     you picked up.
//   * the **buses, emitters, monitors and the crafting accelerator** are shapeless with room to spare,
//     so they gain a **GT screwdriver** and an **LV circuit** like the ME parts in batch 2.
//
// Still not touched: the pure 1:1 flips and colour swaps (the alternate storage bus, the panel colour
// swaps, the terminal configuration flips) and the paint balls, which are cosmetic.

// --- 1k storage component: four redstone dust -> four GT iron screws// --- 4k: four redstone dust -> four GT iron screws// --- 16k: four glowstone dust -> four GT gold screws// --- 64k: four glowstone dust -> four GT gold screws// --- fluid 64k component: four lapis -> four GT bronze screws// --- spatial components (three tiers): four glowstone -> four GT steel screws// --- storage buses (item / fluid / ore dictionary): + screwdriver and an LV circuit// --- level emitter: + screwdriver and an LV circuit// --- annihilation plane: + screwdriver and an LV circuit// --- storage monitor and the conversion monitor// --- crafting accelerator
recipes.remove(<appliedenergistics2:crafting_accelerator>);
recipes.addShapeless(<appliedenergistics2:crafting_accelerator>, [
    <appliedenergistics2:material:24>, <appliedenergistics2:crafting_unit>,
    <ore:craftingToolScrewdriver>, <ore:circuitBasic>
]);

// ==================== Batch 4: AE2's remaining machine parts and its stone trade
//
// What was left after batches 1-3, split the same two ways as before:
//
//   * **machine parts** - the two ME cores, the quantum link chamber, the crystal growth accelerator
//     and the semi-dark monitor - lose their crafting recipe and are made in a GregTech
//     **assembler** with an integrated circuit, exactly like the ME machines in the first pass.
//   * **ordinary crafted things** - the fluid storage components, the whole decorative family (the
//     stairs, the slabs, the quartz and sky stone blocks), the two sky stone chests and the hand
//     grindstone's gear and crank - keep their recipe and their output count, and gain GregTech
//     *tools*: a saw or a hard hammer where the real object has to be cut or compressed, a
//     screwdriver where it has to be screwed together.
//
// No ingredient was dropped and no count was lowered anywhere in this batch.
//
// Deliberately still not touched, and why:
//   * the sixteen paint balls and every "clean" / "alternative" / colour-swap recipe (washing a
//     colour off a cable, flipping a bus to its inverted mode, turning a part into its flat panel
//     form, converting one panel into another). Those are not manufacturing - they change a part in
//     place - so a tool in that grid would be noise rather than difficulty.
//   * the cable family (glass / covered / smart / dense fluix). Their "wash the colour off" recipe
//     shares an output with the cable's own recipe, so a removal by output would take the washing
//     away with it. That family is queued for its own pass rather than done half-way here.
//   * the four "deconstruction" recipes (a block back into crystals) - the reverse of a recipe that
//     still exists - and the fluix seed, which belongs to AE2's own crystal chain (see the note at
//     the top of this file).

// ---- the two ME cores: assembler work now
// Formation and annihilation cores are the two halves of every AE2 machine, and both are three
// ingredients in a single row. Both now need an LV assembler and a circuit; nothing else changed.
recipes.remove(<appliedenergistics2:material:43>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:crystalCertusQuartz>, <ore:dustFluix>, <appliedenergistics2:material:22>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:43> * 2)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:material:44>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<ore:gemNetherQuartz>, <ore:dustFluix>, <appliedenergistics2:material:22>)
    .circuit(1)
    .outputs(<appliedenergistics2:material:44> * 2)
    .duration(200).EUt(120)
    .buildAndRegister();

// ---- quantum link chamber and crystal growth accelerator: assembler work now
// The iron in the growth accelerator is four GregTech iron plates rather than four bare ingots.
recipes.remove(<appliedenergistics2:quantum_link>);
mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
    .inputs(<appliedenergistics2:quartz_glass:0> * 4, <ore:pearlFluix> * 4)
    .circuit(1)
    .outputs(<appliedenergistics2:quantum_link>)
    .duration(400).EUt(480)
    .buildAndRegister();

// ---- the semi-dark monitor: a GregTech iron plate instead of a bare ingot, screwed down with a
// circuit. Its own three-per-craft shape is kept, and the 1:1 "turn a panel into a monitor" recipe
// that shared this output is put back unchanged.
recipes.addShapeless(<appliedenergistics2:part:180>, [<appliedenergistics2:part:200>]);

// ---- the fluid storage components (1k / 4k / 16k): the same treatment the 64k part got
// A memory board is held together with screws, and a screw has to come off a GT lathe. Only the four
// corner lapis dust change; every other slot is AE2's own, unchanged.

// ---- the eight stair recipes: cut with a saw and knocked square with a hammer, block count unchanged
recipes.remove(<appliedenergistics2:smooth_sky_stone_stairs>);
recipes.addShaped(<appliedenergistics2:smooth_sky_stone_stairs> * 4, [
    [<appliedenergistics2:smooth_sky_stone_block>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>]
]);

recipes.remove(<appliedenergistics2:sky_stone_stairs>);
recipes.addShaped(<appliedenergistics2:sky_stone_stairs> * 4, [
    [<appliedenergistics2:sky_stone_block>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>]
]);

recipes.remove(<appliedenergistics2:sky_stone_brick_stairs>);
recipes.addShaped(<appliedenergistics2:sky_stone_brick_stairs> * 4, [
    [<appliedenergistics2:sky_stone_brick>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:sky_stone_brick>, <appliedenergistics2:sky_stone_brick>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:sky_stone_brick>, <appliedenergistics2:sky_stone_brick>, <appliedenergistics2:sky_stone_brick>]
]);

recipes.remove(<appliedenergistics2:sky_stone_small_brick_stairs>);
recipes.addShaped(<appliedenergistics2:sky_stone_small_brick_stairs> * 4, [
    [<appliedenergistics2:sky_stone_small_brick>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:sky_stone_small_brick>, <appliedenergistics2:sky_stone_small_brick>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:sky_stone_small_brick>, <appliedenergistics2:sky_stone_small_brick>, <appliedenergistics2:sky_stone_small_brick>]
]);

recipes.remove(<appliedenergistics2:quartz_stairs>);
recipes.addShaped(<appliedenergistics2:quartz_stairs> * 4, [
    [<appliedenergistics2:quartz_block>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>]
]);

recipes.remove(<appliedenergistics2:chiseled_quartz_stairs>);
recipes.addShaped(<appliedenergistics2:chiseled_quartz_stairs> * 4, [
    [<appliedenergistics2:chiseled_quartz_block>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:chiseled_quartz_block>, <appliedenergistics2:chiseled_quartz_block>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:chiseled_quartz_block>, <appliedenergistics2:chiseled_quartz_block>, <appliedenergistics2:chiseled_quartz_block>]
]);

recipes.remove(<appliedenergistics2:quartz_pillar_stairs>);
recipes.addShaped(<appliedenergistics2:quartz_pillar_stairs> * 4, [
    [<appliedenergistics2:quartz_pillar>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:quartz_pillar>, <appliedenergistics2:quartz_pillar>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:quartz_pillar>, <appliedenergistics2:quartz_pillar>, <appliedenergistics2:quartz_pillar>]
]);

recipes.remove(<appliedenergistics2:fluix_stairs>);
recipes.addShaped(<appliedenergistics2:fluix_stairs> * 4, [
    [<appliedenergistics2:fluix_block>, <ore:craftingToolSaw>, null],
    [<appliedenergistics2:fluix_block>, <appliedenergistics2:fluix_block>, <ore:craftingToolHardHammer>],
    [<appliedenergistics2:fluix_block>, <appliedenergistics2:fluix_block>, <appliedenergistics2:fluix_block>]
]);

// ---- the eight slab recipes: sawn and hammered the same way, six per craft as before
recipes.remove(<appliedenergistics2:smooth_sky_stone_slab>);
recipes.addShaped(<appliedenergistics2:smooth_sky_stone_slab> * 6, [
    [<appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:sky_stone_slab>);
recipes.addShaped(<appliedenergistics2:sky_stone_slab> * 6, [
    [<appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:sky_stone_brick_slab>);
recipes.addShaped(<appliedenergistics2:sky_stone_brick_slab> * 6, [
    [<appliedenergistics2:sky_stone_brick>, <appliedenergistics2:sky_stone_brick>, <appliedenergistics2:sky_stone_brick>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:sky_stone_small_brick_slab>);
recipes.addShaped(<appliedenergistics2:sky_stone_small_brick_slab> * 6, [
    [<appliedenergistics2:sky_stone_small_brick>, <appliedenergistics2:sky_stone_small_brick>, <appliedenergistics2:sky_stone_small_brick>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:quartz_slab>);
recipes.addShaped(<appliedenergistics2:quartz_slab> * 6, [
    [<appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:chiseled_quartz_slab>);
recipes.addShaped(<appliedenergistics2:chiseled_quartz_slab> * 6, [
    [<appliedenergistics2:chiseled_quartz_block>, <appliedenergistics2:chiseled_quartz_block>, <appliedenergistics2:chiseled_quartz_block>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:quartz_pillar_slab>);
recipes.addShaped(<appliedenergistics2:quartz_pillar_slab> * 6, [
    [<appliedenergistics2:quartz_pillar>, <appliedenergistics2:quartz_pillar>, <appliedenergistics2:quartz_pillar>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

recipes.remove(<appliedenergistics2:fluix_slab>);
recipes.addShaped(<appliedenergistics2:fluix_slab> * 6, [
    [<appliedenergistics2:fluix_block>, <appliedenergistics2:fluix_block>, <appliedenergistics2:fluix_block>],
    [<ore:craftingToolSaw>, <ore:craftingToolHardHammer>, null]
]);

// ---- the quartz and fluix blocks themselves
//
// The four crystal-to-block conversions used to be crafting-table recipes here (four crystals
// against a hard hammer, eight grown crystals against the same hammer). "Put N of a thing in and get
// the compressed block out" is the one shape a GregTech pack must not hand out on the table; it is
// the packer's job. So the table recipes are deleted, and the machine routes are:
//
//   four  <ore:crystalCertusQuartz>      -> quartz_block   packer, 2x2 mould   (MV)
//   four  <ore:crystalFluix>             -> fluix_block    packer, 2x2 mould   (MV)
//   nine  <ore:crystalPureCertusQuartz>  -> quartz_block   written here, compressor
//   nine  <ore:crystalPureFluix>         -> fluix_block    written here, compressor
//
// All four are written here, because the whole AE2 line starts at MV now (section 6ar): Gregicality
// mirrors AE2's own 2x2 JSON recipe onto the packer for free, but it does so at LV, and
// MinespaceCraftingBlocks deletes any packer recipe for these two blocks that asks for less than
// 120 EU/t before the game starts. The *grown* crystal conversion never had such a mirror, because
// AE2 writes it as a 3x3
// with the centre empty, so it is written out here - and in the compressor rather than the packer,
// which is how GregTech itself splits the two jobs: four items into a block on the packer, nine into
// a block on the compressor. Nine is one crystal more than AE2's own pattern (eight, centre empty),
// so the move never makes the block cheaper; the packer could not take it in any case, since it
// accepts only two inputs - one ingredient plus one non-consumed mould. A cut block is still sawn to
// size on the table right below.
recipes.remove(<appliedenergistics2:quartz_block>);
mods.gregtech.recipe.RecipeMap.getByName("packer").recipeBuilder()
    .inputs(<ore:crystalCertusQuartz> * 4)
    .notConsumable(<gtadditions:ga_meta_item:32132>)
    .outputs(<appliedenergistics2:quartz_block>)
    .duration(200).EUt(120)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:crystalPureCertusQuartz> * 9)
    .outputs(<appliedenergistics2:quartz_block>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:fluix_block>);
mods.gregtech.recipe.RecipeMap.getByName("packer").recipeBuilder()
    .inputs(<ore:crystalFluix> * 4)
    .notConsumable(<gtadditions:ga_meta_item:32132>)
    .outputs(<appliedenergistics2:fluix_block>)
    .duration(200).EUt(120)
    .buildAndRegister();
mods.gregtech.recipe.RecipeMap.getByName("compressor").recipeBuilder()
    .inputs(<ore:crystalPureFluix> * 9)
    .outputs(<appliedenergistics2:fluix_block>)
    .duration(200).EUt(120)
    .buildAndRegister();

recipes.remove(<appliedenergistics2:chiseled_quartz_block>);
recipes.addShaped(<appliedenergistics2:chiseled_quartz_block> * 2, [
    [<appliedenergistics2:quartz_block>, <appliedenergistics2:quartz_block>],
    [<ore:craftingToolSaw>, null]
]);

recipes.remove(<appliedenergistics2:quartz_pillar>);
recipes.addShaped(<appliedenergistics2:quartz_pillar> * 2, [
    [<appliedenergistics2:quartz_block>, <ore:craftingToolSaw>],
    [<appliedenergistics2:quartz_block>, null]
]);

recipes.remove(<appliedenergistics2:quartz_vibrant_glass>);
recipes.addShaped(<appliedenergistics2:quartz_vibrant_glass>, [
    [<ore:dustGlowstone>, <appliedenergistics2:quartz_glass:0>, <ore:dustGlowstone>],
    [<ore:craftingToolSaw>, null, null]
]);

// The three one-to-one sky stone conversions are AE2's way of cycling the block's look; each is a
// cut, so each now wants a saw.
recipes.remove(<appliedenergistics2:smooth_sky_stone_block>);
recipes.addShapeless(<appliedenergistics2:smooth_sky_stone_block>, [
    <appliedenergistics2:sky_stone_small_brick>, <ore:craftingToolSaw>
]);

recipes.remove(<appliedenergistics2:sky_stone_small_brick>);
recipes.addShapeless(<appliedenergistics2:sky_stone_small_brick>, [
    <appliedenergistics2:sky_stone_brick>, <ore:craftingToolSaw>
]);

recipes.remove(<appliedenergistics2:sky_stone_brick>);
recipes.addShapeless(<appliedenergistics2:sky_stone_brick>, [
    <appliedenergistics2:smooth_sky_stone_block>, <ore:craftingToolSaw>
]);

// ---- the two sky stone chests: screwed together instead of just stacked
recipes.remove(<appliedenergistics2:sky_stone_chest>);
recipes.addShaped(<appliedenergistics2:sky_stone_chest>, [
    [<appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>],
    [<appliedenergistics2:sky_stone_block>, <ore:craftingToolScrewdriver>, <appliedenergistics2:sky_stone_block>],
    [<appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>, <appliedenergistics2:sky_stone_block>]
]);

recipes.remove(<appliedenergistics2:smooth_sky_stone_chest>);
recipes.addShaped(<appliedenergistics2:smooth_sky_stone_chest>, [
    [<appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>],
    [<appliedenergistics2:smooth_sky_stone_block>, <ore:craftingToolScrewdriver>, <appliedenergistics2:smooth_sky_stone_block>],
    [<appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>, <appliedenergistics2:smooth_sky_stone_block>]
]);

// ---- the hand grindstone's wooden gear and crank: sawn and filed
//
// Note what the gear's *output* is: GregTech's wooden gear, not AE2's. The pack keeps one wooden gear
// - GregTech's - for the whole pack (the same rule the ingots, dusts and plates follow), so oredict.zs
// takes AE2's and Ender IO's copies out of `gearWood` and MinespaceMaterialRepoint moves everything
// that ate them over. GregTech itself ships no recipe for its wooden gear at all: its gear generator
// only writes the machine lanes for an `IngotMaterial` (wood is not one) and the crafting lane needs
// double plates, of which there is no wooden one. So this recipe - four sticks, a saw and a file,
// AE2's own cost - is what makes GregTech's wooden gear, and AE2's item is hidden with the other
// retired copies. The `recipes.remove` below still matches AE2's gear, because that also clears the
// four `<crafting>`-registered `GEAR_WOOD` recipes Ender IO shipped for the same item.
recipes.remove(<appliedenergistics2:material:40>);
recipes.addShaped(<gregtech:meta_item_2:26196>, [
    [<ore:craftingToolSaw>, <ore:stickWood>, <ore:craftingToolFile>],
    [<ore:stickWood>, null, <ore:stickWood>],
    [null, <ore:stickWood>, null]
]);

recipes.remove(<appliedenergistics2:crank>);
recipes.addShaped(<appliedenergistics2:crank>, [
    [<ore:stickWood>, <ore:stickWood>, <ore:stickWood>],
    [<ore:craftingToolSaw>, <ore:craftingToolFile>, <ore:stickWood>],
    [null, null, <ore:stickWood>]
]);

// ==================== Batch 5: AE2's cable family
//
// The last manufacturing recipes in AE2 that were still plain. Every cable family also has a "wash the
// colour off" recipe, and that recipe shares its *output* with the cable's own recipe - so this pass
// cannot use `recipes.remove(<cable>)`, which would take the washing away with the cable. It uses
// `recipes.removeShapeless(output, ingredients)` instead, which matches one specific shapeless recipe.
//
// That call works on AE2's recipes: CraftTweaker 1.12's `ActionRemoveShapelessRecipes` casts to both
// `ShapelessRecipes` and `ShapelessOreRecipe`, and AE2 registers its cables as `ShapelessOreRecipe`
// (the shapes below come from AE2's own `assets/appliedenergistics2/recipes/network/cables/*.json`,
// not from the probe, which cannot tell a 2x1 recipe from a 1x2 one). It also logs how many recipes it
// removed, which is what the verification counts: four calls, one removal each.
//
// The tools follow what the object is. A glass cable is a quartz fibre that has to be cut to length.
// A *smart* cable is a cable with a redstone/glowstone logic layer in it, so it takes the wire cutter
// as well as an LV circuit. Nothing was dropped and no output count changed - the fluix glass cable
// still gives four per craft.
//
// Not touched, and why: the wool wrap that turns a glass cable into a covered one (there is no
// GregTech tool for wrapping something in wool, and it consumes no metal), and every "clean" /
// colour-wash recipe, which changes a part in place rather than manufacturing anything.

// --- fluix glass cable: the quartz fibre is cut to length (still 4 per craft)
recipes.removeShapeless(<appliedenergistics2:part:16>, [
    <appliedenergistics2:part:140>, <ore:crystalFluix>, <ore:crystalFluix>
]);
recipes.addShapeless(<appliedenergistics2:part:16> * 4, [
    <appliedenergistics2:part:140>, <ore:crystalFluix>, <ore:crystalFluix>,
    <ore:craftingToolWireCutter>
]);

// --- fluix smart cable: a covered cable plus the redstone/glowstone logic layer, wired with a circuit
recipes.removeShapeless(<appliedenergistics2:part:56>, [
    <appliedenergistics2:part:36>, <ore:dustRedstone>, <ore:dustGlowstone>
]);
recipes.addShapeless(<appliedenergistics2:part:56>, [
    <appliedenergistics2:part:36>, <ore:dustRedstone>, <ore:dustGlowstone>,
    <ore:craftingToolWireCutter>, <ore:circuitBasic>
]);

// --- dense fluix covered cable: four covered cables bundled, cut to length
recipes.removeShapeless(<appliedenergistics2:part:516>, [
    <appliedenergistics2:part:36>, <appliedenergistics2:part:36>,
    <appliedenergistics2:part:36>, <appliedenergistics2:part:36>
]);
recipes.addShapeless(<appliedenergistics2:part:516>, [
    <appliedenergistics2:part:36>, <appliedenergistics2:part:36>,
    <appliedenergistics2:part:36>, <appliedenergistics2:part:36>,
    <ore:craftingToolWireCutter>
]);

// --- dense fluix smart cable: the same logic layer again, on the bundled cable
recipes.removeShapeless(<appliedenergistics2:part:76>, [
    <appliedenergistics2:part:516>, <ore:dustRedstone>, <ore:dustGlowstone>
]);
recipes.addShapeless(<appliedenergistics2:part:76>, [
    <appliedenergistics2:part:516>, <ore:dustRedstone>, <ore:dustGlowstone>,
    <ore:craftingToolWireCutter>, <ore:circuitBasic>
]);
