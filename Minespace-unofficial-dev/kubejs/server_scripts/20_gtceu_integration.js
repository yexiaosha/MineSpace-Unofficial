// Server script — GregTech CE: Unofficial integration examples.
//
// Listen with events.listen(...), not onEvent(...), and write ES5 only.
// See startup_scripts/00_pack_info.js for the full explanation.
//
// ============================ READ THIS FIRST ============================
// GregTech items are metadata variants of a handful of base items
// (gregtech:meta_item_1, meta_item_2, ...), so there is usually no readable
// registry name to type. Address them by ORE DICTIONARY instead:
//
//     'ore:ingotCopper'    'ore:plateIron'    'ore:dustTin'
//     'ore:circuitBasic'   'ore:gearSteel'    'ore:blockAluminium'
//
// Before enabling anything below, confirm the exact ore dictionary entry in
// game: JEI shows it in the item's tooltip (F3+H enables advanced tooltips),
// or hold the item and run /kubejs hand.
// =========================================================================
//
// The examples are left disabled on purpose: a wrong ore dictionary name makes
// KubeJS log a failed recipe, and this pack should boot clean on a fresh install.

events.listen('recipes', function (event) {
    log.info('[minespace] GregTech integration script loaded (examples disabled)')

    // --- Example 1: a Galacticraft part from GregTech plates ------------------
    // event.addShaped('galacticraftcore:basic_item', [
    //     'PPP',
    //     'P P',
    //     'PPP'
    // ], {
    //     P: 'ore:plateAluminium'
    // })

    // --- Example 2: shapeless conversion between plate and dust ---------------
    // event.addShapeless('ore:dustIron', [
    //     'ore:plateIron'
    // ])
})

// --- Removing GregTech recipes -------------------------------------------------
// Removal is a separate pair of events, keyed by what you match on:
//   recipes.remove.input   -> remove every recipe that consumes a match
//   recipes.remove.output  -> remove every recipe that produces a match
//
// events.listen('recipes.remove.output', function (event) {
//     log.info('[minespace] removing recipes that output bronze plates')
//     event.remove({ output: 'ore:plateBronze' })
// })