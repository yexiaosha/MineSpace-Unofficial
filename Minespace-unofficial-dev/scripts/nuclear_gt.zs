#priority 792
// NuclearCraft: Overhauled - hide the processors whose material recipes are
// copied into GregTech by MinespaceNuclearMaterials.
//
// The Java bridge registers NCO's ordinary material recipes into TJ RecipeMaps.
// NCO's separator and centrifuge stay craftable: they are the isotope/fission
// separation machines, and must not be duplicated by GT thermal centrifuge.
// Nuclear-specific machines also stay: nuclear furnace, decay hastener,
// fuel reprocessor and electric furnace.

recipes.remove(<nuclearcraft:manufactory>);
recipes.remove(<nuclearcraft:alloy_furnace>);
recipes.remove(<nuclearcraft:infuser>);
recipes.remove(<nuclearcraft:melter>);
recipes.remove(<nuclearcraft:supercooler>);
recipes.remove(<nuclearcraft:electrolyzer>);
recipes.remove(<nuclearcraft:assembler>);
recipes.remove(<nuclearcraft:ingot_former>);
recipes.remove(<nuclearcraft:pressurizer>);
recipes.remove(<nuclearcraft:chemical_reactor>);
recipes.remove(<nuclearcraft:salt_mixer>);
recipes.remove(<nuclearcraft:crystallizer>);
recipes.remove(<nuclearcraft:enricher>);
recipes.remove(<nuclearcraft:extractor>);
recipes.remove(<nuclearcraft:rock_crusher>);

mods.jei.JEI.hide(<nuclearcraft:manufactory>);
mods.jei.JEI.hide(<nuclearcraft:alloy_furnace>);
mods.jei.JEI.hide(<nuclearcraft:infuser>);
mods.jei.JEI.hide(<nuclearcraft:melter>);
mods.jei.JEI.hide(<nuclearcraft:supercooler>);
mods.jei.JEI.hide(<nuclearcraft:electrolyzer>);
mods.jei.JEI.hide(<nuclearcraft:assembler>);
mods.jei.JEI.hide(<nuclearcraft:ingot_former>);
mods.jei.JEI.hide(<nuclearcraft:pressurizer>);
mods.jei.JEI.hide(<nuclearcraft:chemical_reactor>);
mods.jei.JEI.hide(<nuclearcraft:salt_mixer>);
mods.jei.JEI.hide(<nuclearcraft:crystallizer>);
mods.jei.JEI.hide(<nuclearcraft:enricher>);
mods.jei.JEI.hide(<nuclearcraft:extractor>);
mods.jei.JEI.hide(<nuclearcraft:rock_crusher>);
