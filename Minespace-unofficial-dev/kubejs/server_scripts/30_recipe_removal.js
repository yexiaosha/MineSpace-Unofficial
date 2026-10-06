// Server script — removing existing recipes.
//
// Listen with events.listen(...), not onEvent(...), and write ES5 only.
// See startup_scripts/00_pack_info.js for the full explanation.
//
// Two dedicated events exist for removal, and they match on different sides of
// a recipe:
//
//   recipes.remove.input   -> drop every recipe that CONSUMES a match
//   recipes.remove.output  -> drop every recipe that PRODUCES a match
//
// They are separate on purpose: "the recipe that makes X" and "the recipe that
// uses X" are different questions, and matching both at once silently removes
// more than you want.
//
// Everything here is commented out so a fresh install keeps its vanilla
// recipes. Uncomment, then check the log on world load for what was removed.

// events.listen('recipes.remove.output', function (event) {
//     log.info('[minespace] removing recipes that output planks')
//     event.remove({ output: 'minecraft:planks' })
// })

// events.listen('recipes.remove.input', function (event) {
//     log.info('[minespace] removing recipes that consume cobblestone')
//     event.remove({ input: 'minecraft:cobblestone' })
// })

// events.listen('recipes', function (event) {
//     // Re-add a recipe after removing the original, e.g. a lower plank yield.
//     event.addShapeless('2x minecraft:planks', [
//         'ore:logWood'
//     ])
// })

// Matching shapes accepted by event.remove(...):
//
//   { output: 'minecraft:stone_bricks' }   one output
//   { input: 'minecraft:cobblestone' }     one input
//   { mod: 'minecraft' }                   everything registered by one mod
//   { output: '4x minecraft:torch' }       count-sensitive
//
// Item names: for GregTech materials use the ore dictionary form
// ('ore:ingotCopper'); for vanilla logs and planks the ore dictionary names are
// 'ore:logWood' and 'ore:plankWood'. A plain metadata item such as
// 'minecraft:planks' matches the item, so it removes every metadata variant.
