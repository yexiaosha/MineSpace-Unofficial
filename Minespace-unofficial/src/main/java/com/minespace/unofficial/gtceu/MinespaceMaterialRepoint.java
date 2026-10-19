package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearGtMaterials;
import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import gregtech.api.recipes.recipes.DummyRecipe;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.material.type.IngotMaterial;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.stack.MaterialStack;
import net.minecraft.creativetab.CreativeTabs;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.CraftingManager;
import net.minecraft.item.crafting.FurnaceRecipes;
import net.minecraft.item.crafting.IRecipe;
import net.minecraft.item.crafting.Ingredient;
import net.minecraft.util.NonNullList;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * "All materials come from GregTech": every recipe that hands out a mod's copy of a material GregTech
 * also makes is re-pointed at GregTech's item.
 *
 * <h2>Why this exists</h2>
 *
 * Gregicality registers a mod's metal as a GregTech <em>material</em> and then generates the whole ore
 * processing chain around it - and that chain was handing out the **mod's** item. A probe over the
 * finished registries shows it for meteoric iron: GregTech's own ore blocks and its own dust smelted
 * into `galacticraftcore:item_basic_moon:0` (Galacticraft's ingot), and the same pattern ran through
 * the macerator, packer, unpacker and the rest. Section 6i then took those mod copies <em>out</em> of
 * the shared ore dictionary names, so the item GregTech's own chain produced had become one that
 * nothing accepts any more.
 *
 * <h2>How the mapping is built</h2>
 *
 * It is not invented: the pairs come from `scripts/oredict.zs`, which is where the pack
 * decided which mod items leave which shared name. Each entry there is "this mod item was taken out of
 * this name", and because the pack then left GregTech's item in the name, the target is simply the
 * first item that name holds now - resolved at runtime, so a GregTech id change cannot break it.
 *
 * <p>Deliberately **not** in the map: the compressed / dense plates (`plateCopper`, `plateSteel`, the
 * GS cobalt and nickel plates, and Galacticraft's compressed aluminium). The pack's own decision, taken
 * earlier, is that a rocket part which needs a dense plate keeps needing a dense plate - those items
 * stay as items, produced by GregTech machines (section 6i and 6p), they are just not what a plain
 * `plateX` recipe hands out.</p>
 *
 * <h2>Where it is applied</h2>
 *
 * <ul>
 *   <li>vanilla smelting ({@link FurnaceRecipes}) - input, yield and experience unchanged;</li>
 *   <li>every GregTech recipe map's <em>outputs</em> - the recipe, its inputs, its EU/t and its
 *       duration are untouched, only the stack it produces changes.</li>
 * </ul>
 *
 * <p>Runs from the addon's postInit and again at load complete, because Gregicality registers these in
 * its own init / postInit. Idempotent: after the first pass nothing matches any more.</p>
 */
public final class MinespaceMaterialRepoint {

    private MinespaceMaterialRepoint() {
    }

    /**
     * The mod items this pack took out of the shared ore dictionary names - the ones nothing produces
     * any more. {@link MinespaceCraftingBlocks} uses this to find machine recipes that can no longer
     * be run because every item their ingredient accepts is one of these.
     */
    public static Set<String> unifiedAwayIds() {
        return sharedNames().keySet();
    }

    /** mod item id -> the shared ore dictionary name it was removed from (from oredict.zs). */
    private static Map<String, String> sharedNames() {
        Map<String, String> map = new HashMap<>();
        // ingots
        // Forestry's own ingots are here too: the owner's exception means its own recipes are not
        // deleted (see zzzzzz_minespace_materials.zs), not that GregTech's ore chain may hand them out.
        map.put("forestry:ingot_copper:0", "ingotCopper");
        map.put("galacticraftcore:basic_item:3", "ingotCopper");
        map.put("forestry:ingot_tin:0", "ingotTin");
        map.put("galacticraftcore:basic_item:4", "ingotTin");
        map.put("forestry:ingot_bronze:0", "ingotBronze");
        map.put("galacticraftcore:basic_item:5", "ingotAluminum");
        map.put("galacticraftcore:item_basic_moon:0", "ingotMeteoricIron");
        map.put("galacticraftplanets:item_basic_mars:2", "ingotDesh");
        map.put("galacticraftplanets:item_basic_asteroids:0", "ingotTitanium");
        map.put("galacticraftplanets:basic_item_venus:1", "ingotLead");
        map.put("galaxyspace:ingots:0", "ingotCobalt");
        map.put("galaxyspace:ingots:1", "ingotMagnesium");
        map.put("galaxyspace:ingots:2", "ingotNickel");
        // dusts
        map.put("enderio:item_material:26", "dustCopper");
        map.put("enderio:item_material:27", "dustTin");
        map.put("appliedenergistics2:material:49", "dustIron");
        map.put("enderio:item_material:24", "dustIron");
        map.put("appliedenergistics2:material:51", "dustGold");
        map.put("enderio:item_material:25", "dustGold");
        map.put("enderio:item_material:23", "dustCoal");
        map.put("enderio:item_material:32", "dustLapis");
        map.put("enderio:item_material:29", "dustObsidian");
        map.put("enderio:item_material:31", "dustCobalt");
        map.put("appliedenergistics2:material:2", "dustCertusQuartz");
        map.put("appliedenergistics2:material:3", "dustNetherQuartz");
        map.put("enderio:item_material:33", "dustNetherQuartz");
        map.put("appliedenergistics2:material:46", "dustEnderPearl");
        map.put("appliedenergistics2:material:4", "dustWheat");
        map.put("enderio:item_material:21", "dustWheat");
        map.put("forestry:ash:0", "dustAsh");
        map.put("galacticraftcore:ic2compat:0", "dustAluminium");
        map.put("galacticraftcore:ic2compat:0", "dustAluminum");
        map.put("galaxyspace:gs_basic:7", "dustSulfur");
        map.put("galacticraftplanets:item_basic_asteroids:9", "dustTitanium");
        // gears: Forestry's copper / tin / bronze gear and the two wooden gears (AE2's and Ender IO's)
        // leave the shared names in oredict.zs, and this is what moves everything that produced or ate
        // them onto GregTech's gear. The producers matter most: Gregicality writes its gear recipes
        // through OreDictUnifier, so the extruder / alloy smelter / fluid solidifier lanes for those
        // three metals were making the *mod's* gear and GregTech's own gear items had no source at all
        // (measured on a live run 2026-10-13 - see TJ-MIGRATION-PLAN.md 6bk). Every consumer of the
        // four names is written against the ore name rather than the exact item, so nothing needs a
        // bridge; the crafting lanes are restored by scripts/gear_bridge.zs.
        map.put("forestry:gear_copper:0", "gearCopper");
        map.put("forestry:gear_tin:0", "gearTin");
        map.put("forestry:gear_bronze:0", "gearBronze");
        map.put("appliedenergistics2:material:40", "gearWood");
        map.put("enderio:item_material:9", "gearWood");
        // ores: the Galacticraft / Galaxy Space ore blocks and Forestry's copper and tin ore leave
        // their names in oredict.zs (none of them can be obtained any more - their own ore generation
        // is switched off and nothing else makes them), so everything that produced or ate one is
        // re-pointed, and `pruneDeadSmelting` deletes the per-block furnace lanes that smelted them
        // into an ingot. GregTech's own ore processing is untouched by this: its macerator / chemical
        // bath / forge hammer lanes take an ore-name ingredient listing every entry of the name.
        map.put("forestry:resources:1", "oreCopper");
        map.put("galacticraftcore:basic_block_core:5", "oreCopper");
        map.put("galacticraftcore:basic_block_moon:0", "oreCopper");
        map.put("galaxyspace:ioblocks:3", "oreCopper");
        map.put("galaxyspace:barnarda_c_ores:7", "oreCopper");
        map.put("galaxyspace:proxima_b_blocks:7", "oreCopper");
        map.put("galacticraftplanets:mars:0", "oreCopper");
        map.put("galacticraftplanets:venus:7", "oreCopper");
        map.put("forestry:resources:2", "oreTin");
        map.put("galacticraftcore:basic_block_core:6", "oreTin");
        map.put("galacticraftcore:basic_block_moon:1", "oreTin");
        map.put("galaxyspace:barnarda_c_ores:8", "oreTin");
        map.put("galaxyspace:proxima_b_blocks:6", "oreTin");
        map.put("galacticraftplanets:mars:1", "oreTin");
        map.put("galacticraftplanets:venus:11", "oreTin");
        map.put("galacticraftcore:basic_block_core:7", "oreAluminium");
        map.put("galacticraftplanets:asteroids_block:3", "oreAluminium");
        map.put("galacticraftplanets:venus:6", "oreAluminium");
        map.put("galaxyspace:phobosblocks:5", "oreDesh");
        map.put("galacticraftplanets:mars:2", "oreDesh");
        map.put("galaxyspace:mercuryblocks:3", "oreNickel");
        map.put("galaxyspace:gsores:1", "oreNickel");
        map.put("galaxyspace:phobosblocks:4", "oreNickel");
        map.put("galaxyspace:mirandablocks:8", "oreNickel");
        map.put("galaxyspace:barnarda_c_ores:12", "oreNickel");
        map.put("galaxyspace:gsores:0", "oreCobalt");
        map.put("galaxyspace:mirandablocks:7", "oreCobalt");
        map.put("galaxyspace:barnarda_c_ores:11", "oreCobalt");
        map.put("galaxyspace:ceresblocks:2", "oreDolomite");
        map.put("galaxyspace:mirandablocks:4", "oreDolomite");
        map.put("galaxyspace:ganymedeblocks:3", "oreIlmenite");
        map.put("galacticraftplanets:asteroids_block:4", "oreIlmenite");
        map.put("galaxyspace:titanblocks:3", "oreSapphire");
        map.put("galaxyspace:ioblocks:4", "oreSulfur");
        map.put("galaxyspace:gsores:2", "oreUranium");
        // ... and Forestry's storage blocks for GregTech's metals, whose only producer was the
        // compressor lane Gregicality had written against Forestry's block (see oredict.zs).
        map.put("forestry:resource_storage:1", "blockCopper");
        map.put("forestry:resource_storage:2", "blockTin");
        map.put("forestry:resource_storage:3", "blockBronze");
        map.put("forestry:charcoal:0", "blockCharcoal");
        // Apatite, the last of the shared material names: Forestry's ore, gem and block all leave
        // their names (it is GregTech's apatite vein that generates now - `config/gregtech/worldgen/
        // overworld/apatite_vein.json`), so the lanes Gregicality had written against Forestry's gem
        // - the ore's own gem yield, the gem-to-flawed and gem-to-flawless conversions - are
        // re-pointed at GregTech's apatite, and `pruneDeadSmelting` clears the furnace lanes for the
        // ore. AE2's quartz ore is deliberately *not* in this table even though it leaves
        // `oreCertusQuartz`: its meteorite ore stays obtainable, so a pruner that deletes "unobtainable
        // inputs" must not be pointed at it.
        map.put("forestry:resources:0", "oreApatite");
        map.put("forestry:apatite:0", "gemApatite");
        map.put("forestry:resource_storage:0", "blockApatite");
        // blocks
        map.put("galacticraftcore:basic_block_core:9", "blockCopper");
        map.put("galacticraftcore:basic_block_core:10", "blockTin");
        map.put("galacticraftcore:basic_block_core:11", "blockAluminium");
        map.put("galacticraftcore:basic_block_core:11", "blockAluminum");
        map.put("galacticraftcore:basic_block_core:13", "blockSilicon");
        map.put("galacticraftplanets:asteroids_block:7", "blockTitanium");
        map.put("galacticraftplanets:mars:8", "blockDesh");
        map.put("galacticraftplanets:venus:12", "blockLead");
        // silicon (all three mods' items; the name now holds GregTech's silicon ingot)
        map.put("appliedenergistics2:material:5", "itemSilicon");
        map.put("galacticraftcore:basic_item:2", "itemSilicon");
        map.put("enderio:item_material:5", "itemSilicon");
        // Ender IO's ten alloys, now GregTech materials as well (ingot, nugget, dust, molten fluid -
        // see MinespaceMaterials.ENDER_IO_ALLOYS). Ender IO's ingot and nugget leave the shared names
        // in oredict.zs, so the target resolved here is GregTech's item; anything that
        // used to hand out Ender IO's copy hands out GregTech's instead.
        map.put("enderio:item_alloy_ingot:6", "ingotDarkSteel");
        map.put("enderio:item_alloy_ingot:0", "ingotElectricalSteel");
        map.put("enderio:item_alloy_ingot:1", "ingotEnergeticAlloy");
        map.put("enderio:item_alloy_ingot:2", "ingotVibrantAlloy");
        map.put("enderio:item_alloy_ingot:3", "ingotRedstoneAlloy");
        map.put("enderio:item_alloy_ingot:4", "ingotConductiveIron");
        map.put("enderio:item_alloy_ingot:5", "ingotPulsatingIron");
        map.put("enderio:item_alloy_ingot:7", "ingotSoularium");
        map.put("enderio:item_alloy_ingot:8", "ingotEndSteel");
        map.put("enderio:item_alloy_ingot:9", "ingotConstructionAlloy");
        map.put("enderio:item_alloy_nugget:6", "nuggetDarkSteel");
        map.put("enderio:item_alloy_nugget:0", "nuggetElectricalSteel");
        map.put("enderio:item_alloy_nugget:1", "nuggetEnergeticAlloy");
        map.put("enderio:item_alloy_nugget:2", "nuggetVibrantAlloy");
        map.put("enderio:item_alloy_nugget:3", "nuggetRedstoneAlloy");
        map.put("enderio:item_alloy_nugget:4", "nuggetConductiveIron");
        map.put("enderio:item_alloy_nugget:5", "nuggetPulsatingIron");
        map.put("enderio:item_alloy_nugget:7", "nuggetSoularium");
        map.put("enderio:item_alloy_nugget:8", "nuggetEndSteel");
        map.put("enderio:item_alloy_nugget:9", "nuggetConstructionAlloy");
        // The one dust among the ten that the mod actually ships as an item. `dustSoularium` held this
        // powder *first* and GregTech's dust second, which is why Gregicality generated its macerator
        // and alloy-smelter outputs against the powder id instead of the dust: without an entry here
        // the pack's own mill, its macerator and its storage-block recipes would keep handing the mod's
        // copy back (see section 6az). `scripts/oredict.zs` removes the powder from the shared name, so
        // the target resolved below is GregTech's dust.
        map.put("enderio:item_material:74", "dustSoularium");
        // Ender IO's seven endergy alloys, the same treatment as the ten above: they became GregTech
        // materials on 2026-10-13 (MinespaceMaterials.ENDER_IO_ENDERGY_ALLOYS), so their ingot and
        // nugget leave the shared names in oredict.zs and everything that used to hand out the mod's
        // copy hands out GregTech's instead. The mod's own block / ball items are deliberately left
        // alone, exactly as for the ten (see the class javadoc).
        map.put("enderio:item_alloy_endergy_ingot:0", "ingotCrudeSteel");
        map.put("enderio:item_alloy_endergy_ingot:1", "ingotCrystallineAlloy");
        map.put("enderio:item_alloy_endergy_ingot:2", "ingotMelodicAlloy");
        map.put("enderio:item_alloy_endergy_ingot:3", "ingotStellarAlloy");
        map.put("enderio:item_alloy_endergy_ingot:4", "ingotCrystallinePinkSlime");
        map.put("enderio:item_alloy_endergy_ingot:5", "ingotEnergeticSilver");
        map.put("enderio:item_alloy_endergy_ingot:6", "ingotVividAlloy");
        map.put("enderio:item_alloy_endergy_nugget:0", "nuggetCrudeSteel");
        map.put("enderio:item_alloy_endergy_nugget:1", "nuggetCrystallineAlloy");
        map.put("enderio:item_alloy_endergy_nugget:2", "nuggetMelodicAlloy");
        map.put("enderio:item_alloy_endergy_nugget:3", "nuggetStellarAlloy");
        map.put("enderio:item_alloy_endergy_nugget:4", "nuggetCrystallinePinkSlime");
        map.put("enderio:item_alloy_endergy_nugget:5", "nuggetEnergeticSilver");
        map.put("enderio:item_alloy_endergy_nugget:6", "nuggetVividAlloy");
        // Enderium Base, the last of Ender IO's own metal ingots (see ENDER_IO_OTHER_INGOTS).
        map.put("enderio:item_material:39", "ingotEnderiumBase");
        // ... and the seventeen block forms, which follow the ingots since 2026-10-13: the block name
        // now answers with GregTech's compressed block, so every machine output that used to hand out
        // the mod's block - Gregicality's fluid solidifier casting forms and the compressor's
        // nine-ingots-into-a-block - is re-pointed at GregTech's, and so is every machine recipe that
        // fed on the mod's block.
        map.put("enderio:block_alloy:6", "blockDarkSteel");
        map.put("enderio:block_alloy:0", "blockElectricalSteel");
        map.put("enderio:block_alloy:1", "blockEnergeticAlloy");
        map.put("enderio:block_alloy:2", "blockVibrantAlloy");
        map.put("enderio:block_alloy:3", "blockRedstoneAlloy");
        map.put("enderio:block_alloy:4", "blockConductiveIron");
        map.put("enderio:block_alloy:5", "blockPulsatingIron");
        map.put("enderio:block_alloy:7", "blockSoularium");
        map.put("enderio:block_alloy:8", "blockEndSteel");
        map.put("enderio:block_alloy:9", "blockConstructionAlloy");
        map.put("enderio:block_alloy_endergy:0", "blockCrudeSteel");
        map.put("enderio:block_alloy_endergy:1", "blockCrystallineAlloy");
        map.put("enderio:block_alloy_endergy:2", "blockMelodicAlloy");
        map.put("enderio:block_alloy_endergy:3", "blockStellarAlloy");
        map.put("enderio:block_alloy_endergy:4", "blockCrystallinePinkSlime");
        map.put("enderio:block_alloy_endergy:5", "blockEnergeticSilver");
        map.put("enderio:block_alloy_endergy:6", "blockVividAlloy");
        // Ender IO's three organic dyes, the same treatment as its blocks: `dyeBlack`, `dyeBrown` and
        // `dyeGreen` hold GregTech's own dye dusts, the mod's copies come out of the names in
        // oredict.zs, and this re-point moves the machine outputs that used to hand them out.
        map.put("enderio:item_material:50", "dyeBlack");
        map.put("enderio:item_material:49", "dyeBrown");
        map.put("enderio:item_material:48", "dyeGreen");
        addNuclearStableTargets(map);
        // Aliases where the two mods use a different harmless spelling:
        // QMD calls chromium "Chromium" while GT's material is Chrome, and NCO's crushed quartz
        // is registered under both "dustQuartz" and "dustNetherQuartz". The fission-product
        // caesium item also carries the American "Cesium" spelling.
        map.put("qmd:ingot:2", "ingotChrome");
        map.put("qmd:dust:2", "dustChrome");
        map.put("nuclearcraft:gem_dust:2", "dustNetherQuartz");
        return map;
    }

    /**
     * NCO and QMD register their own copies of the stable metals they need. Those copies are useful
     * to their own machines, but a GregTech machine should not hand them out a second time when the
     * same ingot/dust already exists in GregTech. Nuclear isotopes are deliberately absent: NCO owns
     * that chain, and QMD's mass spectrometer owns the GT-side isotope separation.
     */
    private static void addNuclearStableTargets(Map<String, String> map) {
        Set<String> stable = new HashSet<>(Arrays.asList(
                "Aluminium", "Aluminum", "Barium", "Beryllium", "Calcium", "Chromium",
                "Cobalt", "Copper", "Dysprosium", "Erbium", "Gadolinium", "Gold",
                "Graphite", "Hafnium", "Holmium", "Iridium", "Iron", "Lead",
                "Magnesium", "Manganese", "Molybdenum", "Neodymium", "Nickel",
                "Niobium", "Osmium", "Palladium", "Platinum", "Potassium", "Samarium",
                "Silver", "Sodium", "Strontium", "Titanium", "Tungsten", "Yttrium",
                "Ytterbium", "Zinc", "Zirconium", "Bronze", "Steel", "StainlessSteel",
                "Invar", "Electrum", "Constantan", "Nichrome", "Osmiridium",
                "NiobiumTin", "NiobiumTitanium", "TungstenCarbide", "HSLASteel",
                "Zircaloy", "Hastelloy", "CobaltOxide", "NickelOxide", "TinOxide",
                "IridiumOxide", "RutheniumOxide", "Diamond", "Obsidian", "Fluorite",
                "BoronNitride", "Coal", "Wheat", "Sulfur", "Bismuth", "Salt",
                "SodiumChloride", "Iodine", "SodiumHydroxide", "SodiumFluoride",
                "PotassiumFluoride", "Borax", "Niter", "Saltpeter", "SodiumNitrate",
                "Tin", "Boron", "Lithium",
                "Silicon", "Arsenic", "Barite", "Endstone", "NetherQuartz",
                "Radium", "Polonium", "Mercury",
                // Isotopes GregTech already ships. NCO-only isotopes (U-233/238, Pu-238/239/242,
                // Am-242, Cm-243, Bk-248, Cf-249/250) stay with NCO so its decay chain keeps its
                // own endpoints; the ones listed here have an exact GregTech counterpart and are
                // unified like any other shared material.
                "Uranium", "Thorium", "Uranium235", "Neptunium237", "Plutonium241",
                "Americium241", "Americium243", "Curium245", "Curium246", "Curium247",
                "Berkelium247", "Californium251", "Californium252"
        ));
        stable.addAll(MinespaceNuclearGtMaterials.materialNames());
        String[] prefixes = {"ingot", "dust", "block", "plate", "gear", "nugget", "gem", "rod",
                "item"};
        for (Item item : ForgeRegistries.ITEMS.getValuesCollection()) {
            ResourceLocation id = item.getRegistryName();
            if (id == null || !(id.getResourceDomain().equals("nuclearcraft") || id.getResourceDomain().equals("qmd"))) {
                continue;
            }
            NonNullList<ItemStack> stacks = NonNullList.create();
            try {
                item.getSubItems(CreativeTabs.SEARCH, stacks);
            } catch (Throwable ignored) {
                stacks.clear();
            }
            if (stacks.isEmpty()) {
                stacks.add(new ItemStack(item));
            }
            for (ItemStack stack : stacks) {
                if (stack.isEmpty()) {
                    continue;
                }
                String mappedName = null;
                for (int oreId : OreDictionary.getOreIDs(stack)) {
                    String oreName = OreDictionary.getOreName(oreId);
                    for (String prefix : prefixes) {
                        if (!oreName.startsWith(prefix)) {
                            continue;
                        }
                        String material = oreName.substring(prefix.length());
                        if (stable.contains(material)) {
                            if (hasGregTech(oreName)) {
                                mappedName = oreName;
                            } else if (mappedName == null) {
                                mappedName = oreName;
                            }
                        }
                        break;
                    }
                    if (mappedName != null && hasGregTech(mappedName)) {
                        break;
                    }
                }
                // A name the mod owns alone (Boron, for example) has no GregTech item to move to.
                // Mapping it to itself would turn an ore-dictionary output into an exact mod item,
                // so leave those alone.
                if (mappedName != null && hasGregTech(mappedName)) {
                    map.putIfAbsent(idOf(stack), mappedName);
                }
            }
        }
    }

    private static boolean hasGregTech(String oreName) {
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id != null && id.getResourceDomain().equals("gregtech")) {
                return true;
            }
        }
        return false;
    }

    /** mod item id -> GregTech's item, resolved from the ore dictionary at runtime. */
    /**
     * The same table {@link #resolveTargets()} builds, for passes that live outside this class - the
     * mods' own machine registries (Forestry's Carpenter) need it to re-point recipes CraftTweaker
     * cannot see. Read-only: callers must copy any stack they store.
     */
    public static Map<String, ItemStack> currentTargets() {
        return resolveTargets();
    }

    private static Map<String, ItemStack> resolveTargets() {
        Map<String, ItemStack> targets = new HashMap<>();
        for (Map.Entry<String, String> entry : sharedNames().entrySet()) {
            List<ItemStack> ores = OreDictionary.getOres(entry.getValue(), false);
            if (ores.isEmpty()) {
                Minespace.log().warn("material re-point: {} is empty, cannot re-point {}",
                        entry.getValue(), entry.getKey());
                continue;
            }
            ItemStack target = ores.get(0);
            for (ItemStack candidate : ores) {
                ResourceLocation id = candidate.getItem().getRegistryName();
                if (id != null && id.getResourceDomain().equals("gregtech")) {
                    target = candidate;
                    break;
                }
            }
            targets.put(entry.getKey(), target.copy());
        }
        return targets;
    }

    /** Re-points vanilla smelting outputs. */
    public static int repointSmelting(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        Map<ItemStack, ItemStack> smelting = FurnaceRecipes.instance().getSmeltingList();
        List<ItemStack> victims = new ArrayList<>();
        for (Map.Entry<ItemStack, ItemStack> entry : smelting.entrySet()) {
            if (targets.containsKey(idOf(entry.getValue()))) {
                victims.add(entry.getKey());
            }
        }
        int changed = 0;
        for (ItemStack input : victims) {
            ItemStack old = smelting.get(input);
            if (old == null) {
                continue;
            }
            ItemStack target = targets.get(idOf(old));
            if (target == null || target.isEmpty()) {
                continue;
            }
            ItemStack replacement = target.copy();
            replacement.setCount(old.getCount());
            float xp = FurnaceRecipes.instance().getSmeltingExperience(old);
            smelting.remove(input);
            FurnaceRecipes.instance().addSmeltingRecipe(input, replacement, xp);
            changed++;
            if (changed <= 3) {
                Minespace.log().info("material re-point (smelting): {} -> {} (was {})",
                        idOf(input), idOf(replacement), idOf(old));
            }
        }
        Minespace.log().info("material re-point ({} pass, smelting): {} recipes now yield GregTech's item",
                phase, changed);
        return changed;
    }

    /**
     * Deletes the vanilla-furnace entries whose <em>input</em> is an item this table has handed to
     * GregTech.
     *
     * <h2>Why a dead input matters</h2>
     *
     * <p>Every entry in {@link #sharedNames()} is a mod item the pack stopped producing when it gave
     * the shared ore dictionary name to GregTech's item - that is what the table means, and it is the
     * rule {@code jei_dupes.zs} hides those items on. A furnace recipe that smelts one of them into an
     * ingot (the mods' own ores do exactly this: `galacticraftcore:basic_block_core:5` into a copper
     * ingot, `galaxyspace:gsores:1` into a nickel ingot, and so on) is therefore unbuildable while JEI
     * still lists it, which is the "why is this still here?" wart. {@link #repointSmelting} has already
     * moved those outputs to GregTech's ingots; this removes the entries themselves.</p>
     *
     * <p>The input alone decides. An entry keyed on one of these items cannot be run by anybody - no
     * recipe produces the item any more - so deleting it removes nothing that works. Forestry's and
     * AE2's own obtainable material (apatite, certus quartz ore) is deliberately not in the table and
     * so is not touched. Runs after {@link #repointSmelting} in both rounds and is idempotent.</p>
     *
     * @return the number of smelting recipes deleted by this call
     */
    public static int pruneDeadSmelting(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        Map<ItemStack, ItemStack> smelting = FurnaceRecipes.instance().getSmeltingList();
        List<ItemStack> dead = new ArrayList<>();
        for (Map.Entry<ItemStack, ItemStack> entry : smelting.entrySet()) {
            if (targets.containsKey(idOf(entry.getKey()))) {
                dead.add(entry.getKey());
            }
        }
        int removed = 0;
        for (ItemStack input : dead) {
            ItemStack output = smelting.remove(input);
            if (output == null) {
                continue;
            }
            removed++;
            if (removed <= 3) {
                Minespace.log().info("material re-point (smelting prune): removed {} -> {}",
                        idOf(input), idOf(output));
            }
        }
        Minespace.log().info("material re-point ({} pass, smelting prune): {} furnace recipes whose "
                + "input the pack no longer produces were deleted", phase, removed);
        return removed;
    }

    /** Re-points the outputs of every GregTech machine recipe. */
    public static int repointMaps(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        int changed = 0;
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            for (Recipe recipe : map.getRecipeList()) {
                NonNullList<ItemStack> outputs = recipe.getOutputs();
                for (int i = 0; i < outputs.size(); i++) {
                    ItemStack old = outputs.get(i);
                    ItemStack target = targets.get(idOf(old));
                    if (target == null || target.isEmpty()) {
                        continue;
                    }
                    ItemStack replacement = target.copy();
                    replacement.setCount(old.getCount());
                    outputs.set(i, replacement);
                    changed++;
                    if (changed <= 3) {
                        Minespace.log().info("material re-point ({}): output {} -> {} (was {})",
                                map.getUnlocalizedName(), idOf(replacement), idOf(replacement),
                                idOf(old));
                    }
                }
                // Chanced outputs are a separate list and were the reason some NCO tin / boron
                // dusts survived the first pass. ChanceEntry is immutable, so replace the entry.
                List<Recipe.ChanceEntry> chanced = recipe.getChancedOutputs();
                for (int i = 0; i < chanced.size(); i++) {
                    Recipe.ChanceEntry entry = chanced.get(i);
                    ItemStack old = entry.getItemStack();
                    ItemStack target = targets.get(idOf(old));
                    if (target == null || target.isEmpty()) {
                        continue;
                    }
                    ItemStack replacement = target.copy();
                    replacement.setCount(old.getCount());
                    chanced.set(i, new Recipe.ChanceEntry(replacement, entry.getChance(),
                            entry.getBoostPerTier()));
                    changed++;
                    if (changed <= 3) {
                        Minespace.log().info("material re-point ({}): chanced output {} -> {} (was {})",
                                map.getUnlocalizedName(), idOf(replacement), idOf(replacement),
                                idOf(old));
                    }
                }
            }
        }
        Minespace.log().info("material re-point ({} pass, machines): {} machine outputs now yield "
                + "GregTech's item", phase, changed);
        return changed;
    }

    /**
     * Re-points the <em>inputs</em> of every GregTech machine recipe: an ingredient that can only be
     * satisfied by a mod's copy of a unified material is replaced by GregTech's item.
     *
     * <h2>Why this exists, and how it differs from the output pass</h2>
     *
     * {@link #repointMaps} fixes what a machine hands out. This fixes what it eats, and it closes a gap
     * the owner found on 2026-10-13 by opening JEI after the Ender IO registration: Gregicality builds
     * a lot of its material recipes against the item that happened to be <em>first</em> in a shared ore
     * dictionary name at generation time - and for the mods this pack unifies, that was the mod's copy.
     * A recipe written against `enderio:item_alloy_endergy_nugget:0` cannot be run once the pack stops
     * producing that nugget, so the second pass of {@link MinespaceCraftingBlocks} used to delete it.
     * Deleting is the wrong answer when the material still exists: what the recipe wants is the pack's
     * nugget, which is exactly GregTech's. Substituting it keeps the recipe, which is what the owner
     * asked for: *"the related recipes have to be adapted"*. The clearest case is the compressor's
     * nine nuggets into one ingot - with this pass it survives as `9x GregTech nugget -> GregTech ingot`
     * instead of vanishing, so the crafting table stops being the only route between the two.
     *
     * <p>The rule is the same conservative one {@link #repointCraftingInputs} uses: an ingredient is
     * only touched when <em>every</em> item it accepts is one of the unified mod items, so an ore
     * dictionary name that already lists GregTech's item among alternatives is left exactly as it is.
     * Counts, duration and EU/t are untouched, and the pack's own de-duplication pass merges the result
     * with GregTech's own recipe when the two end up identical.</p>
     *
     * <p>Runs immediately after {@link #repointMaps} in both the postInit and loadComplete rounds, so
     * {@link MinespaceCraftingBlocks#removeUnreachableMachineRecipes} only has to deal with what is
     * genuinely gone. Idempotent: after the first pass nothing matches any more.</p>
     */
    public static int repointMachineInputs(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        int changed = 0;
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            for (Recipe recipe : map.getRecipeList()) {
                List<CountableIngredient> inputs = recipe.getInputs();
                for (int i = 0; i < inputs.size(); i++) {
                    CountableIngredient input = inputs.get(i);
                    if (input == null || input.getIngredient() == null) {
                        continue;
                    }
                    ItemStack replacement =
                            unifiedReplacement(input.getIngredient().getMatchingStacks(), targets);
                    if (replacement != null) {
                        inputs.set(i, new CountableIngredient(
                                Ingredient.fromStacks(replacement.copy()), input.getCount()));
                        changed++;
                        if (changed <= 3) {
                            Minespace.log().info("material re-point ({} input): {} {} -> {}", phase,
                                    map.getUnlocalizedName(), idOf(match0(input)), idOf(replacement));
                        }
                    }
                }
            }
        }
        Minespace.log().info("material re-point ({} pass, machine inputs): {} ingredient slots now "
                + "take GregTech's item", phase, changed);
        return changed;
    }

    /**
     * GTCEu's {@code removeSmeltingForEBFMetals}, whose config default was {@code true} and whose
     * text was "Whether Gregtech should remove smelting recipes from the vanilla furnace for ingots
     * requiring the Electric Blast Furnace". GTCE-TJ has no such switch, and an audit of the finished
     * registries on 2026-10-15 found **243** dust-to-ingot furnace lanes - aluminium and titanium
     * among them - so a player could skip the electric blast furnace for exactly the metals it exists
     * for. This pass reproduces GTCEu's rule from its own bytecode
     * ({@code ModHandler.removeSmeltingEBFMetals}): for every furnace lane whose output is a GregTech
     * ingot of a material with a blast-furnace temperature, and whose input is that material's dust,
     * drop the lane.
     *
     * <p>GTCEu also spared a lane that a CraftTweaker script had added ("Not removing Smelting Recipe
     * for EBF material ... as it is added via CT"). Nothing in this pack adds a furnace lane - the one
     * script that touches the registry removes AE2's own silicon lane - so there is nothing to spare
     * and the check is not reproduced.</p>
     */
    public static int pruneEbfMetalSmelting(String phase) {
        Map<ItemStack, ItemStack> smelting = FurnaceRecipes.instance().getSmeltingList();
        List<ItemStack> victims = new ArrayList<>();
        for (Map.Entry<ItemStack, ItemStack> entry : smelting.entrySet()) {
            ItemStack input = entry.getKey();
            ItemStack output = entry.getValue();
            if (input == null || output == null || input.isEmpty() || output.isEmpty()) {
                continue;
            }
            MaterialStack materialStack = OreDictUnifier.getMaterial(output);
            if (materialStack == null || !(materialStack.material instanceof IngotMaterial)) {
                continue;
            }
            IngotMaterial material = (IngotMaterial) materialStack.material;
            if (material.blastFurnaceTemperature <= 0) {
                continue;
            }
            ItemStack dust = OreDictUnifier.get(OrePrefix.dust, material);
            ItemStack ingot = OreDictUnifier.get(OrePrefix.ingot, material);
            if (dust.isEmpty() || ingot.isEmpty()) {
                continue;
            }
            if (ingot.isItemEqual(output) && dust.isItemEqual(input)) {
                victims.add(input);
            }
        }
        for (ItemStack input : victims) {
            smelting.remove(input);
        }
        StringBuilder names = new StringBuilder();
        for (ItemStack input : victims) {
            if (names.length() > 0) {
                names.append(", ");
            }
            names.append(idOf(input));
        }
        Minespace.log().info("EBF-metal smelting ({} pass): {} dust-to-ingot furnace lanes removed "
                + "(GTCEu's removeSmeltingForEBFMetals): {}", phase, victims.size(), names);
        return victims.size();
    }

    private static ItemStack match0(CountableIngredient input) {
        ItemStack[] stacks = input.getIngredient().getMatchingStacks();
        return stacks.length == 0 ? ItemStack.EMPTY : stacks[0];
    }

    /**
     * Deletes the hand-crafting conversions that still hand out a mod's copy of a unified material
     * when <em>nothing in the game asks for that copy any more</em>.
     *
     * <p>This is the other half of {@link #repointMaps}: Gregicality's own hand recipes ("a mortar and
     * nine small dusts", "an ingot and a hammer", ...) were generated through
     * {@code OreDictUnifier.get(prefix, material)}, which answers with the <em>first</em> stack in the
     * shared name - so while a mod's dust was first in `dustIron`, Gregicality's crafting-table
     * conversion produced the mod's dust, not GregTech's. The machine maps were re-pointed long ago
     * ({@link #repointMaps}); the crafting table kept making the mod's item, which is why the same
     * powder still shows up twice in JEI.</p>
     *
     * <p>Nothing is re-pointed here, and that is deliberate. Building a replacement crafting recipe
     * means losing the shaped / shapeless layout JEI draws from the original class, and the recipes in
     * question all produce an item that <em>no recipe and no machine consumes</em> - so the honest move
     * is to delete the conversion and let the mod's item go, exactly as the silicons and the apatite
     * went. The two names that do have consumers keep their producer: AE2's certus quartz and nether
     * quartz dusts are still eaten by its own recipes, whose ingredients are mixed lists the
     * conservative input pass leaves alone.</p>
     */
    public static int removeDeadDuplicateCrafting(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        if (targets.isEmpty()) {
            return 0;
        }
        Set<String> needed = new java.util.HashSet<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            for (Ingredient ingredient : recipe.getIngredients()) {
                if (ingredient == null || ingredient == Ingredient.EMPTY) {
                    continue;
                }
                for (ItemStack match : ingredient.getMatchingStacks()) {
                    String id = idOf(match);
                    if (targets.containsKey(id)) {
                        needed.add(id);
                    }
                }
            }
        }
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            for (Recipe recipe : map.getRecipeList()) {
                for (CountableIngredient input : recipe.getInputs()) {
                    if (input == null || input.getIngredient() == null) {
                        continue;
                    }
                    for (ItemStack match : input.getIngredient().getMatchingStacks()) {
                        String id = idOf(match);
                        if (targets.containsKey(id)) {
                            needed.add(id);
                        }
                    }
                }
            }
        }

        List<ResourceLocation> victims = new ArrayList<>();
        Set<String> removedOutputs = new java.util.TreeSet<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            String out = idOf(recipe.getRecipeOutput());
            if (!targets.containsKey(out) || needed.contains(out)) {
                continue;
            }
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name == null) {
                continue;
            }
            victims.add(name);
            removedOutputs.add(out);
        }
        for (ResourceLocation name : victims) {
            // The pack's own way of deleting a crafting recipe: a placeholder under the same name.
            ForgeRegistries.RECIPES.register(
                    new DummyRecipe().setRegistryName(name));
        }
        Minespace.log().info("dead duplicate crafting ({} pass): {} recipes deleted, leaving {} "
                + "unified mod items with no producer: {}", phase, victims.size(),
                removedOutputs.size(), removedOutputs);
        return victims.size();
    }

    /**
     * Re-points crafting-table recipe <em>inputs</em>: an ingredient that can still be satisfied by a
     * mod's copy of a unified material is replaced by GregTech's item.
     *
     * <p>This is what makes it safe for {@code zzzzzz_minespace_materials.zs} to delete the mods' own
     * production recipes: a Galacticraft rocket part that was written against Galacticraft's desh
     * ingot by exact id keeps working, it simply costs GregTech's desh ingot now. Ore dictionary
     * ingredients are only touched when they can match a mod's item - an ingredient that already
     * resolves to GregTech's item is left alone.</p>
     */
    public static int repointCraftingInputs(String phase) {
        Map<String, ItemStack> targets = resolveTargets();
        int changed = 0;
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            NonNullList<Ingredient> ingredients = recipe.getIngredients();
            for (int i = 0; i < ingredients.size(); i++) {
                Ingredient ingredient = ingredients.get(i);
                if (ingredient == null) {
                    continue;
                }
                // Only replace an ingredient that can be satisfied *exclusively* by mod copies - an
                // exact-id ingredient, or a shared name whose every member is a mod item. A mixed name
                // (the way Ender IO's lapis powder sits in `dyeBlue` next to vanilla lapis) is left
                // alone, because replacing it with a dust would turn a "blue dye" slot into a dust slot.
                ItemStack replacement = unifiedReplacement(ingredient.getMatchingStacks(), targets);
                if (replacement != null) {
                    ingredients.set(i, Ingredient.fromStacks(replacement.copy()));
                    changed++;
                    if (changed <= 3) {
                        Minespace.log().info("material re-point (crafting input): {}.{} -> {}",
                                CraftingManager.REGISTRY.getNameForObject(recipe), i,
                                idOf(replacement));
                    }
                }
            }
        }
        Minespace.log().info("material re-point ({} pass, crafting inputs): {} ingredient slots now "
                + "take GregTech's item", phase, changed);
        return changed;
    }

    /**
     * Reduces an ingredient's alternatives to one canonical GregTech stack.
     *
     * <p>If the list already contains GregTech's item, that item wins - even when a mod copy in the
     * list is registered under several aliases (QMD's niter dust is also "dustSaltpeter" and
     * "dustSodiumNitrate", so its mapping does not necessarily point at the same alias). Every other
     * alternative must be a mod copy this pack has mapped; an unrelated mod's item keeps the
     * ingredient as it is. Without a GregTech item in the list, every mapped alternative must agree
     * on one target.</p>
     */
    private static ItemStack unifiedReplacement(ItemStack[] matches,
                                                Map<String, ItemStack> targets) {
        ItemStack gregTech = null;
        boolean allMapped = true;
        for (ItemStack match : matches) {
            ResourceLocation id = match.getItem().getRegistryName();
            if (id != null && id.getResourceDomain().equals("gregtech")) {
                if (gregTech == null) {
                    gregTech = match;
                } else if (!gregTech.isItemEqual(match)) {
                    return null;
                }
            } else if (!targets.containsKey(idOf(match))) {
                allMapped = false;
            }
        }
        if (gregTech != null && allMapped) {
            return gregTech;
        }
        ItemStack replacement = null;
        for (ItemStack match : matches) {
            ItemStack mapped = targets.get(idOf(match));
            if (mapped == null || mapped.isEmpty()) {
                return null;
            }
            if (replacement == null) {
                replacement = mapped;
            } else if (!replacement.isItemEqual(mapped)) {
                return null;
            }
        }
        return replacement;
    }

    private static String idOf(ItemStack stack) {
        if (stack == null || stack.isEmpty()) {
            return "<empty>";
        }
        Item item = stack.getItem();
        ResourceLocation name = ForgeRegistries.ITEMS.getKey(item);
        return name == null ? "<unknown>" : name + ":" + stack.getMetadata();
    }
}
