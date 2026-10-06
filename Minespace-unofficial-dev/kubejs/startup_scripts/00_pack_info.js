// priority: 1000
// Startup script — runs once, while the game is loading.
// Loaded from kubejs/startup_scripts/.
//
// ===================== TWO RULES FOR KUBEJS 1.12.2 =====================
// 1. LISTEN WITH `events.listen(...)`, NOT `onEvent(...)`.
//    The global `onEvent` function documented for KubeJS 6 (1.16+) does not
//    exist here. The binding is an object called `events`:
//        events.listen('event.id', function (event) { ... })
//    A script using onEvent() throws
//    `ReferenceError: "onEvent" is not defined` and none of its handlers run.
//
// 2. WRITE ES5, NOT ES6.
//    1.12.2 scripts run on Nashorn, the JavaScript engine inside Java 8, which
//    is ES5-only. `const`, `let`, arrow functions (=>), template literals and
//    `for...of` all fail to parse. Use `var`, `function () {}` and string
//    concatenation.
//
// Logging goes through the `log` binding; there is no `console` object.
//    log.info('...')   log.warn('...')   log.error('...')   log.debug('...')
// ======================================================================

events.listen('server.load', function (event) {
    log.info('[minespace] KubeJS startup script ran (server.load)')
})

// The code below runs immediately when this file is evaluated, outside any
// event. That is what makes it a "startup" concern: item, block and fluid
// registration has to happen this early in the loading process.
var PACK = {
    name: 'Minespace Unofficial',
    minecraft: '1.12.2',
    mods: {
        gregtech: '2.8.10-beta',
        galacticraft: '4.0.7',
        kubejs: '1.1.0.65',
        codechickenlib: '3.2.3.358'
    }
}

log.info('[minespace] ' + PACK.name + ' on MC ' + PACK.minecraft)

// `for...in` over an object is ES5 and works; `for...of` over an array is not.
for (var modId in PACK.mods) {
    if (PACK.mods.hasOwnProperty(modId)) {
        log.info('[minespace]   ' + modId + ' ' + PACK.mods[modId])
    }
}
