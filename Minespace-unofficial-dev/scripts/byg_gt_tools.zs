// BYG's own tools are not part of the GT tool tier system. Keep BYG armour, but let the
// GT-generated pickaxe/shovel/sword/axe/hoe recipes be the only craftable tool line.
recipes.remove(<byg:kasai_pickaxe>);
recipes.remove(<byg:kasai_shovel>);
recipes.remove(<byg:kasai_sword>);

recipes.remove(<byg:latharium_axe>);
recipes.remove(<byg:latharium_battleaxe>);
recipes.remove(<byg:latharium_hoe>);
recipes.remove(<byg:latharium_pickaxe>);
recipes.remove(<byg:latharium_shovel>);
recipes.remove(<byg:latharium_sword>);

recipes.remove(<byg:pendorite_axe>);
recipes.remove(<byg:pendorite_battleaxe>);
recipes.remove(<byg:pendorite_hoe>);
recipes.remove(<byg:pendorite_pickaxe>);
recipes.remove(<byg:pendorite_shovel>);
recipes.remove(<byg:pendorite_sword>);

recipes.remove(<byg:tamrelite_axe>);
recipes.remove(<byg:tamrelite_battleaxe>);
recipes.remove(<byg:tamrelite_hoe>);
recipes.remove(<byg:tamrelite_pickaxe>);
recipes.remove(<byg:tamrelite_shovel>);
recipes.remove(<byg:tamrelite_sword>);

mods.jei.JEI.hide(<byg:kasai_pickaxe>);
mods.jei.JEI.hide(<byg:kasai_shovel>);
mods.jei.JEI.hide(<byg:kasai_sword>);
mods.jei.JEI.hide(<byg:latharium_axe>);
mods.jei.JEI.hide(<byg:latharium_battleaxe>);
mods.jei.JEI.hide(<byg:latharium_hoe>);
mods.jei.JEI.hide(<byg:latharium_pickaxe>);
mods.jei.JEI.hide(<byg:latharium_shovel>);
mods.jei.JEI.hide(<byg:latharium_sword>);
mods.jei.JEI.hide(<byg:pendorite_axe>);
mods.jei.JEI.hide(<byg:pendorite_battleaxe>);
mods.jei.JEI.hide(<byg:pendorite_hoe>);
mods.jei.JEI.hide(<byg:pendorite_pickaxe>);
mods.jei.JEI.hide(<byg:pendorite_shovel>);
mods.jei.JEI.hide(<byg:pendorite_sword>);
mods.jei.JEI.hide(<byg:tamrelite_axe>);
mods.jei.JEI.hide(<byg:tamrelite_battleaxe>);
mods.jei.JEI.hide(<byg:tamrelite_hoe>);
mods.jei.JEI.hide(<byg:tamrelite_pickaxe>);
mods.jei.JEI.hide(<byg:tamrelite_shovel>);
mods.jei.JEI.hide(<byg:tamrelite_sword>);

// GT compressor/packer owns storage-block conversion; remove BYG's 3x3 round trips.
recipes.remove(<byg:kasai_block>);
recipes.remove(<byg:kasai_ingot>);
recipes.remove(<byg:latharium_block>);
recipes.remove(<byg:latharium_gem>);
recipes.remove(<byg:pendorite_block>);
recipes.remove(<byg:pendorite_gem>);
recipes.remove(<byg:tamrelite_block>);
recipes.remove(<byg:tamrelite_gem>);

// Armour keeps the BYG items, but is now made from GT plates.
recipes.remove(<byg:kasai_armour_helmet>);
recipes.remove(<byg:kasai_armour_body>);
recipes.remove(<byg:kasai_armour_legs>);
recipes.remove(<byg:kasai_armour_boots>);
recipes.addShaped(<byg:kasai_armour_helmet>, [
    [<ore:plateKasai>, <ore:plateKasai>, <ore:plateKasai>],
    [<ore:plateKasai>, null, <ore:plateKasai>]
]);
recipes.addShaped(<byg:kasai_armour_body>, [
    [<ore:plateKasai>, null, <ore:plateKasai>],
    [<ore:plateKasai>, <ore:plateKasai>, <ore:plateKasai>],
    [<ore:plateKasai>, <ore:plateKasai>, <ore:plateKasai>]
]);
recipes.addShaped(<byg:kasai_armour_legs>, [
    [<ore:plateKasai>, <ore:plateKasai>, <ore:plateKasai>],
    [<ore:plateKasai>, null, <ore:plateKasai>],
    [<ore:plateKasai>, null, <ore:plateKasai>]
]);
recipes.addShaped(<byg:kasai_armour_boots>, [
    [<ore:plateKasai>, null, <ore:plateKasai>],
    [<ore:plateKasai>, null, <ore:plateKasai>]
]);

recipes.remove(<byg:latharium_armour_helmet>);
recipes.remove(<byg:latharium_armour_body>);
recipes.remove(<byg:latharium_armour_legs>);
recipes.remove(<byg:latharium_armour_boots>);
recipes.addShaped(<byg:latharium_armour_helmet>, [
    [<ore:plateLatharium>, <ore:plateLatharium>, <ore:plateLatharium>],
    [<ore:plateLatharium>, null, <ore:plateLatharium>]
]);
recipes.addShaped(<byg:latharium_armour_body>, [
    [<ore:plateLatharium>, null, <ore:plateLatharium>],
    [<ore:plateLatharium>, <ore:plateLatharium>, <ore:plateLatharium>],
    [<ore:plateLatharium>, <ore:plateLatharium>, <ore:plateLatharium>]
]);
recipes.addShaped(<byg:latharium_armour_legs>, [
    [<ore:plateLatharium>, <ore:plateLatharium>, <ore:plateLatharium>],
    [<ore:plateLatharium>, null, <ore:plateLatharium>],
    [<ore:plateLatharium>, null, <ore:plateLatharium>]
]);
recipes.addShaped(<byg:latharium_armour_boots>, [
    [<ore:plateLatharium>, null, <ore:plateLatharium>],
    [<ore:plateLatharium>, null, <ore:plateLatharium>]
]);

recipes.remove(<byg:pendorite_armour_helmet>);
recipes.remove(<byg:pendorite_armour_body>);
recipes.remove(<byg:pendorite_armour_legs>);
recipes.remove(<byg:pendorite_armour_boots>);
recipes.addShaped(<byg:pendorite_armour_helmet>, [
    [<ore:platePendorite>, <ore:platePendorite>, <ore:platePendorite>],
    [<ore:platePendorite>, null, <ore:platePendorite>]
]);
recipes.addShaped(<byg:pendorite_armour_body>, [
    [<ore:platePendorite>, null, <ore:platePendorite>],
    [<ore:platePendorite>, <ore:platePendorite>, <ore:platePendorite>],
    [<ore:platePendorite>, <ore:platePendorite>, <ore:platePendorite>]
]);
recipes.addShaped(<byg:pendorite_armour_legs>, [
    [<ore:platePendorite>, <ore:platePendorite>, <ore:platePendorite>],
    [<ore:platePendorite>, null, <ore:platePendorite>],
    [<ore:platePendorite>, null, <ore:platePendorite>]
]);
recipes.addShaped(<byg:pendorite_armour_boots>, [
    [<ore:platePendorite>, null, <ore:platePendorite>],
    [<ore:platePendorite>, null, <ore:platePendorite>]
]);

recipes.remove(<byg:tamrelite_armour_helmet>);
recipes.remove(<byg:tamrelite_armour_body>);
recipes.remove(<byg:tamrelite_armour_legs>);
recipes.remove(<byg:tamrelite_armour_boots>);
recipes.addShaped(<byg:tamrelite_armour_helmet>, [
    [<ore:plateTamrelite>, <ore:plateTamrelite>, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>]
]);
recipes.addShaped(<byg:tamrelite_armour_body>, [
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, <ore:plateTamrelite>, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, <ore:plateTamrelite>, <ore:plateTamrelite>]
]);
recipes.addShaped(<byg:tamrelite_armour_legs>, [
    [<ore:plateTamrelite>, <ore:plateTamrelite>, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>]
]);
recipes.addShaped(<byg:tamrelite_armour_boots>, [
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>],
    [<ore:plateTamrelite>, null, <ore:plateTamrelite>]
]);
