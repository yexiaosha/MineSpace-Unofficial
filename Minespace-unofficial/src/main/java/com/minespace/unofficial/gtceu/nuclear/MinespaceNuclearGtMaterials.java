package com.minespace.unofficial.gtceu.nuclear;

import com.google.common.collect.ImmutableList;
import com.minespace.unofficial.gtceu.MinespaceMaterials;
import gregtech.api.unification.material.IMaterialHandler;
import gregtech.api.unification.material.MaterialIconSet;
import gregtech.api.unification.material.type.DustMaterial;
import gregtech.api.unification.material.type.GemMaterial;
import gregtech.api.unification.material.type.IngotMaterial;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.stack.MaterialStack;
import gregtech.api.items.materialitem.MaterialMetaItem;
import gregtech.api.items.metaitem.MetaItem;
import net.minecraft.item.ItemStack;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.oredict.OreDictionary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Set;

/**
 * GregTech materials for the substances NCO and QMD shipped as their own items.
 *
 * <p>These are the materials the pack still had no GregTech counterpart for: NCO's alloys,
 * oxides, ceramics and polymers, QMD's superconductor precursor dusts, the isotopes GregTech
 * does not carry, and NCO's fission-product dusts. The ore dictionary names are the ones NCO and
 * QMD already use, so {@code MinespaceMaterialRepoint} can re-point their items at these materials
 * without renaming anything.</p>
 *
 * <p>Deliberately not registered here: reactor fuel assemblies and pellets (LEU/HEU/MIX/TBU,
 * TRISO, carbide/nitride/oxide/ZA fuel forms), machine parts, food items, and forms whose material
 * already exists in GregTech under another name. Those are either reactor-owned items or aliases,
 * not new substances. Chromium is re-pointed at GregTech's Chrome and Quartz at GregTech's
 * Nether Quartz in {@code MinespaceMaterialRepoint}.</p>
 */
@IMaterialHandler.RegisterMaterialHandler
public final class MinespaceNuclearGtMaterials implements IMaterialHandler {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private static final Set<String> NAMES = new LinkedHashSet<>();
    private static boolean initialized;

    /** Alloys and polymers: ingot, nugget, block, dust and a molten fluid. */
    private static final String[] METALS = {
            "SiliconCarbide", "PyrolyticCarbon", "HardCarbon", "Ferroboron", "Tough",
            "LeadPlatinum", "Hastelloy", "Extreme", "HSLASteel", "Zircaloy",
            "MagnesiumDiboride", "LithiumManganeseDioxide", "Shibuichi", "TinSilver",
            "Thermoconducting", "SiCSiCCMC", "ZirconiumMolybdenum", "SuperAlloy",
            "NiobiumTin", "Zirfon", "Polydimethylsilylene", "Polyethersulfone",
            "PolymethylsilyleneMethylene", "Polytetrafluoroethene"
    };

    /** Oxides: ingot, nugget, dust and block, without a fluid. */
    private static final String[] INGOTS = {
            "ManganeseOxide", "ManganeseDioxide", "TinOxide", "NickelOxide",
            "CobaltOxide", "RutheniumOxide", "IridiumOxide", "Zirconia", "CopperOxide"
    };

    /** Compounds, superconductor precursors and fission products: dust only. */
    private static final String[] DUSTS = {
            "Alugentum", "AmmoniumBisulfate", "AmmoniumPersulfate", "AmmoniumSulfate",
            "BSCCO", "BariumSulfide", "CalciumSulfate", "CarbonManganese", "CrystalBinder",
            "Dimensional", "Dysprholminite", "Energetic", "HafniumOxide", "HBCCO",
            "Hydroquinone", "IronFluoride", "IrradiatedBorax", "Nichromite",
            "PotassiumHydroxide", "PotassiumHydroquinone", "Silica",
            "SodiumHydroquinone", "SSFAF", "TBP", "TungstenOxide", "YBCO",
            "ZincSulfide"
    };

    /** Gem materials; GT generates both the gem and its dust. */
    private static final String[] GEMS = {
            "BoronArsenide", "BoronNitride", "Carobbiite", "Rhodochrosite", "Villiaumite"
    };

    /**
     * Forms whose base material GregTech already has in another shape: Boron is a GT dust,
     * Cobalt Oxide a GT dust/block, Fluorite a GT dust and Mercury a GT fluid. These materials
     * exist only to give the missing ingot / gem form a GregTech item, which is then registered
     * under the ore dictionary alias the mods already use.
     */
    private static final String[] FORM_INGOTS = {
            "BoronIngot", "CobaltOxideIngot", "MercuryIngot"
    };

    private static final String[] FORM_GEMS = {
            "FluoriteGem"
    };

    public MinespaceNuclearGtMaterials() {
    }

    @Override
    public void onMaterialsInit() {
        if (initialized) {
            return;
        }
        initialized = true;
        if (!Loader.isModLoaded("nuclearcraft") && !Loader.isModLoaded("qmd")) {
            return;
        }

        int created = 0;
        int reused = 0;
        for (String name : METALS) {
            if (registerIngot(name, DustMaterial.MatFlags.SMELT_INTO_FLUID
                    | DustMaterial.MatFlags.GENERATE_PLATE)) {
                created++;
            } else {
                reused++;
            }
        }
        for (String name : INGOTS) {
            if (registerIngot(name, DustMaterial.MatFlags.SMELT_INTO_FLUID)) {
                created++;
            } else {
                reused++;
            }
        }
        for (String name : DUSTS) {
            if (registerDust(name)) {
                created++;
            } else {
                reused++;
            }
        }
        for (String name : GEMS) {
            if (registerGem(name)) {
                created++;
            } else {
                reused++;
            }
        }
        for (String name : FORM_INGOTS) {
            if (registerIngot(name, DustMaterial.MatFlags.SMELT_INTO_FLUID
                    | DustMaterial.MatFlags.GENERATE_PLATE)) {
                created++;
            } else {
                reused++;
            }
        }
        for (String name : FORM_GEMS) {
            if (registerGem(name)) {
                created++;
            } else {
                reused++;
            }
        }

        int freeSlots = 0;
        for (int id = 0; id < 1000; id++) {
            if (Material.MATERIAL_REGISTRY.getObjectById(id) == null) {
                freeSlots++;
            }
        }
        LOG.info("NCO/QMD GregTech materials: {} created, {} reused, {} names; {} free ids left",
                created, reused, NAMES.size(), freeSlots);
    }

    private static boolean registerIngot(String name, long flags) {
        Material existing = findExisting(name);
        if (existing != null) {
            NAMES.add(name);
            LOG.info("  reusing GT material '{}' for NCO/QMD {}", existing, name);
            return false;
        }
        int id = MinespaceMaterials.allocateMaterialId();
        new IngotMaterial(id, toSnakeCase(name), colour(name, 0x808080),
                MaterialIconSet.METALLIC, 2, ImmutableList.of(), flags);
        NAMES.add(name);
        return true;
    }

    private static boolean registerDust(String name) {
        Material existing = findExisting(name);
        if (existing instanceof DustMaterial) {
            NAMES.add(name);
            LOG.info("  reusing GT material '{}' for NCO/QMD dust {}", existing, name);
            return false;
        }
        int id = MinespaceMaterials.allocateMaterialId();
        new DustMaterial(id, toSnakeCase(name), colour(name, 0x707070),
                MaterialIconSet.DULL, 1, ImmutableList.of(), 0L);
        NAMES.add(name);
        return true;
    }

    private static boolean registerGem(String name) {
        Material existing = findExisting(name);
        if (existing instanceof GemMaterial) {
            NAMES.add(name);
            LOG.info("  reusing GT gem material '{}' for NCO/QMD {}", existing, name);
            return false;
        }
        int id = MinespaceMaterials.allocateMaterialId();
        new GemMaterial(id, toSnakeCase(name), colour(name, 0xB0B0B0),
                MaterialIconSet.SHINY, 1, ImmutableList.of(), 0L);
        NAMES.add(name);
        return true;
    }

    /**
     * Finds a GT material under the spelling GT may have used. GT stores the registry key in
     * lower_snake_case while this class names materials in CamelCase, so both spellings are tried.
     */
    private static Material findExisting(String name) {
        Material existing = Material.MATERIAL_REGISTRY.getObject(name);
        if (existing == null) {
            existing = Material.MATERIAL_REGISTRY.getObject(name.toLowerCase(Locale.ROOT));
        }
        if (existing == null) {
            existing = Material.MATERIAL_REGISTRY.getObject(toSnakeCase(name));
        }
        return existing;
    }

    private static String toSnakeCase(String name) {
        // Acronym-heavy names need the boundaries a plain "uppercase -> underscore" pass misses:
        // HSLASteel must become hsla_steel (not h_s_l_a_steel) and Uranium233 becomes uranium_233.
        // SiC-SiC CMC is the one name whose intended word split cannot be recovered generically.
        if ("SiCSiCCMC".equals(name)) {
            return "sic_sic_cmc";
        }
        return name
                .replaceAll("([a-z0-9])([A-Z])", "$1_$2")
                .replaceAll("([A-Z]+)([A-Z][a-z])", "$1_$2")
                .replaceAll("([A-Za-z])([0-9])", "$1_$2")
                .replaceAll("([0-9])([A-Za-z])", "$1_$2")
                .toLowerCase(Locale.ROOT);
    }

    private static int colour(String name, int base) {
        return base | (name.hashCode() & 0x1F1F1F);
    }

    /**
     * Publishes the form-only materials under the ore dictionary names NCO/QMD already use.
     * Called from the recipe registry event, after GT has created its material items.
     */
    public static void registerFormAliases() {
        alias(OrePrefix.ingot, "boron_ingot", "ingotBoron");
        alias(OrePrefix.ingot, "cobalt_oxide_ingot", "ingotCobaltOxide");
        alias(OrePrefix.ingot, "mercury_ingot", "ingotMercury");
        alias(OrePrefix.gem, "fluorite_gem", "gemFluorite");
        alias(OrePrefix.plate, "boron_ingot", "plateBoron");
        alias(OrePrefix.plate, "cobalt_oxide_ingot", "plateCobaltOxide");
        alias(OrePrefix.plate, "mercury_ingot", "plateMercury");
    }

    private static void alias(OrePrefix prefix, String materialName, String oreName) {
        Material material = Material.MATERIAL_REGISTRY.getObject(materialName);
        if (material == null) {
            return;
        }
        ItemStack stack = OreDictUnifier.get(prefix, material);
        if (!stack.isEmpty()) {
            OreDictionary.registerOre(oreName, stack);
        }
    }

    /** Material names, for {@code MinespaceMaterialRepoint}'s stable-material set. */
    public static Set<String> materialNames() {
        return Collections.unmodifiableSet(NAMES);
    }

    /**
     * Diagnostic for GT's CraftTweaker bracket handler: it assumes every MaterialMetaItem entry
     * resolves to an ore prefix and a MaterialStack. A material item without either makes GT throw
     * a NullPointerException during the register-recipes-lowest pass, long after startup.
     */
    public static void diagnoseMetaItems() {
        int bad = 0;
        for (MetaItem item : MetaItem.getMetaItems()) {
            if (!(item instanceof MaterialMetaItem)) {
                continue;
            }
            for (ItemStack stack : ((MaterialMetaItem) item).getEntries()) {
                OrePrefix prefix = OreDictUnifier.getPrefix(stack);
                MaterialStack materialStack = OreDictUnifier.getMaterial(stack);
                if (prefix == null || materialStack == null || materialStack.material == null) {
                    bad++;
                    if (bad <= 30) {
                        int materialId = stack.getMetadata() % 1000;
                        Material byId = Material.MATERIAL_REGISTRY.getObjectById(materialId);
                        StringBuilder oreNames = new StringBuilder();
                        for (int oreId : OreDictionary.getOreIDs(stack)) {
                            if (oreNames.length() > 0) {
                                oreNames.append(',');
                            }
                            oreNames.append(OreDictionary.getOreName(oreId));
                        }
                        LOG.warn("material meta entry without prefix/material: {}:{} "
                                        + "prefix={} material={} materialId={} byId={} class={} "
                                        + "unlocalized={} oreNames=[{}]",
                                stack.getItem().getRegistryName(), stack.getMetadata(), prefix,
                                materialStack, materialId, byId,
                                byId == null ? "null" : byId.getClass().getName(),
                                stack.getUnlocalizedName(), oreNames);
                    }
                    continue;
                }
                try {
                    materialStack.material.toCamelCaseString();
                } catch (Throwable broken) {
                    bad++;
                    if (bad <= 30) {
                        LOG.warn("material meta entry whose toCamelCaseString() failed: {}:{} "
                                        + "prefix={} material={} class={}",
                                stack.getItem().getRegistryName(), stack.getMetadata(), prefix,
                                materialStack.material,
                                materialStack.material.getClass().getName(), broken);
                    }
                }
            }
        }
        LOG.info("material meta diagnostic: {} entries without a resolvable prefix/material", bad);
    }
}
