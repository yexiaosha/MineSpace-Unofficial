// Client script — runs on the client only, reloaded with F3+T.
// Loaded from kubejs/client_scripts/.
//
// Listen with events.listen(...), not onEvent(...), and write ES5 only.
// See startup_scripts/00_pack_info.js for the full explanation.
//
// Client events cover things the server cannot know about: tooltips, JEI
// categories, screen overlays. Nothing here can affect world state.

// Add a tooltip line to any item. Handy for flagging pack-modified items.
events.listen('item.tooltip', function (event) {
    event.add('gregtech:meta_item_1', [
        'Minespace: GregTech material item',
        'Hold it and run /kubejs hand for the ore dictionary entry'
    ])
})

// Other client-side events available on 1.12.2:
//
//   events.listen('client.debug_info', function (event) { })   F3 debug lines
//   events.listen('client.tick', function (event) { })         every client tick
//   events.listen('client.logged_in', function (event) { })
//   events.listen('jei.add.items', function (event) { })       force items into JEI
//   events.listen('jei.hide.items', function (event) { })      hide items from JEI
//   events.listen('jei.remove.categories', function (event) { })
