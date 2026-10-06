// Server script — runs on every world load and on /reload.
// Loaded from kubejs/server_scripts/.
//
// Listen with events.listen(...), not onEvent(...), and write ES5 only.
// See startup_scripts/00_pack_info.js for the full explanation.
//
// The 1.12.2 recipe API method names are the long forms — addShaped and
// addShapeless. The short forms (event.shaped / event.shapeless) documented for
// KubeJS 6 on 1.16+ do not exist on this version.
//
// These examples use only vanilla items, so they are safe to keep enabled.
// Check item names with JEI, or dump the held item with /kubejs hand.

events.listen('recipes', function (event) {
    log.info('[minespace] adding example recipes')

    // Shaped: output, pattern rows, then the key map. The same shape as a
    // vanilla shaped recipe json.
    event.addShaped('minecraft:torch', [
        'C',
        'S'
    ], {
        C: 'minecraft:coal',
        S: 'minecraft:stick'
    })

    // Shapeless: output, then a flat list of ingredients.
    event.addShapeless('4x minecraft:stick', [
        'minecraft:planks'
    ])

    // A leading "4x " sets the output count. Ore dictionary names work as
    // ingredients with the 'ore:' prefix — that is the practical way to address
    // GregTech materials, which have no readable registry name of their own.
    event.addShaped('minecraft:chest', [
        'WWW',
        'W W',
        'WWW'
    ], {
        W: 'ore:plankWood'
    })
})
