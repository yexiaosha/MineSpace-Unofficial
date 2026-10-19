package com.minespace.unofficial.gtceu;

import gregtech.api.recipes.RecipeBuilder;
import gregtech.api.recipes.RecipeMaps;
import gregtech.api.recipes.ModHandler;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.worldgen.config.OreDepositDefinition;
import gregtech.api.worldgen.config.WorldGenRegistry;
import gregtech.api.worldgen.filler.FillerEntry;
import gregtech.common.items.MetaItems;
import net.minecraft.block.Block;
import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;


/**
 * GT processing and uses for BYG's ores.
 *
 * <p>The ore blocks are placed by GT veins through {@code block:byg:...} fillers, so they never
 * enter GT's automatic ore-prefix chain. These explicit recipes feed them into GT machines:
 * maceration produces the material dust and a mineral byproduct, centrifuging separates the
 * chemically distinct elements, and the resulting dusts/plates feed existing GT chains. Kasai's
 * dust is smelted back into its superalloy ingot.</p>
 */
public final class MinespaceBygProcessing {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static boolean registered;

    private MinespaceBygProcessing() {
    }

    public static void register() {
        if (registered || !Loader.isModLoaded("byg")) {
            return;
        }
        registered = true;

        registerOreNames();
        registerConversions();

        macerate("kasai_ore", "kasai", "nickel", 800, 120);
        macerate("latharium_ore", "latharium", "cerium", 600, 120);
        macerate("pendorite_ore", "pendorite", "beryllium", 600, 120);
        macerate("tamrelite_ore", "tamrelite", "titanium", 400, 30);
        macerate("sodalite", "Sodalite", "aluminium", 400, 30);

        // BYG ores drop gems rather than the ore block. Without these recipes a player who mines
        // normally (no silk touch) would get a gem that no GT chain can consume.
        macerateGem("latharium_gem", "latharium", "cerium", 300, 120);
        macerateGem("pendorite_gem", "pendorite", "beryllium", 300, 120);
        macerateGem("tamrelite_gem", "tamrelite", "titanium", 200, 30);

        // Kasai is a native Ni-Cr-Co-Mo-W alloy: remelting the separated/sorted dust closes the loop.
        ItemStack kasaiDust = stack("kasai", OrePrefix.dust);
        ItemStack kasaiIngot = stack("kasai", OrePrefix.ingot);
        if (!kasaiDust.isEmpty() && !kasaiIngot.isEmpty()) {
            RecipeMaps.ALLOY_SMELTER_RECIPES.recipeBuilder()
                    .inputs(kasaiDust)
                    .outputs(kasaiIngot)
                    .duration(200).EUt(120).buildAndRegister();
        }

        // Latharium's rare-earth content makes it an EV optical sensor/emitter material.
        ItemStack lathariumPlate = stack("latharium", OrePrefix.plate);
        ItemStack lathariumGem = stack("latharium", OrePrefix.gem);
        ItemStack circuitElite = gtOre("circuitElite");
        ItemStack stainlessPlate = gtOre("plateStainlessSteel");
        ItemStack optical = !lathariumPlate.isEmpty() ? count(lathariumPlate, 2) : lathariumGem;
        if (!optical.isEmpty() && !circuitElite.isEmpty() && !stainlessPlate.isEmpty()) {
            RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                    .inputs(optical, circuitElite, stainlessPlate)
                    .outputs(MetaItems.SENSOR_EV.getStackForm())
                    .duration(400).EUt(1920).buildAndRegister();
            RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                    .inputs(optical.copy(), circuitElite.copy(), stainlessPlate.copy())
                    .outputs(MetaItems.EMITTER_EV.getStackForm())
                    .duration(400).EUt(1920).buildAndRegister();
        }

        // Kasai's refractory strength is used in the EV turbine rotor.
        ItemStack kasaiPlate = stack("kasai", OrePrefix.plate);
        ItemStack rotorCore = OreDictUnifier.get(OrePrefix.rotor, Materials.TungstenSteel);
        if (!kasaiPlate.isEmpty() && !rotorCore.isEmpty() && !circuitElite.isEmpty()) {
            RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                    .inputs(count(kasaiPlate, 4), rotorCore, circuitElite)
                    .outputs(MetaItems.TURBINE_ROTOR.getStackForm())
                    .duration(800).EUt(1920).buildAndRegister();
        }

        verifyVeins();
        LOG.info("BYG ore processing: Kasai/Latharium/Pendorite/Tamrelite + Sodalite recipes registered");
    }

    /** Confirms that each BYG ore resolved as a component of an existing mixed GT vein. */
    private static void verifyVeins() {
        Map<String, Set<String>> hosts = new LinkedHashMap<>();
        hosts.put("byg:kasai_ore", new LinkedHashSet<>());
        hosts.put("byg:latharium_ore", new LinkedHashSet<>());
        hosts.put("byg:pendorite_ore", new LinkedHashSet<>());
        hosts.put("byg:tamrelite_ore", new LinkedHashSet<>());
        for (OreDepositDefinition definition : WorldGenRegistry.getOreDeposits()) {
            String name = definition.getDepositName();
            if (name == null) {
                continue;
            }
            Set<String> blocks = new LinkedHashSet<>();
            for (FillerEntry entry : definition.getBlockFiller().getAllPossibleStates()) {
                for (IBlockState state : entry.getPossibleResults()) {
                    ResourceLocation id = state.getBlock().getRegistryName();
                    blocks.add(String.valueOf(id));
                }
            }
            for (Map.Entry<String, Set<String>> entry : hosts.entrySet()) {
                if (blocks.contains(entry.getKey())) {
                    entry.getValue().add(name);
                }
            }
        }
        for (Map.Entry<String, Set<String>> entry : hosts.entrySet()) {
            if (entry.getValue().isEmpty()) {
                LOG.warn("BYG ore {} is not part of any GT vein", entry.getKey());
            } else {
                LOG.info("BYG mixed vein: {} appears in {}", entry.getKey(), entry.getValue());
            }
        }
    }

    /**
     * Called from postInit. The names must not exist while GT builds its recipe lists: GT treats an
     * {@code ore<Material>} entry as a generic ore and adds a cheap maceration fallback that would
     * replace the balanced byproduct recipes below.
     */
    public static void registerOreNames() {
        oreDict("kasai_ore", "oreKasai");
        oreDict("latharium_ore", "oreLatharium");
        oreDict("pendorite_ore", "orePendorite");
        oreDict("tamrelite_ore", "oreTamrelite");
        oreDict("sodalite", "blockSodalite");
    }

    /**
     * BYG keeps its own gem/ingot and storage-block items next to the GT material items. One-to-one
     * crafting conversions keep both item families usable instead of forcing players to guess which
     * copy a recipe accepts.
     */
    private static void registerConversions() {
        convertItem("kasai_ingot", "kasai", OrePrefix.ingot, "kasai_ingot");
        convertItem("latharium_gem", "latharium", OrePrefix.gem, "latharium_gem");
        convertItem("pendorite_gem", "pendorite", OrePrefix.gem, "pendorite_gem");
        convertItem("tamrelite_gem", "tamrelite", OrePrefix.gem, "tamrelite_gem");

        convertBlock("kasai_block", "blockKasai", "kasai_block");
        convertBlock("latharium_block", "blockLatharium", "latharium_block");
        convertBlock("pendorite_block", "blockPendorite", "pendorite_block");
        convertBlock("tamrelite_block", "blockTamrelite", "tamrelite_block");
    }

    private static void convertItem(String itemPath, String materialName,
                                    OrePrefix prefix, String recipeKey) {
        Item item = ForgeRegistries.ITEMS.getValue(new ResourceLocation("byg", itemPath));
        ItemStack gt = stack(materialName, prefix);
        if (item == null || gt.isEmpty()) {
            LOG.warn("BYG conversion: {} <-> GT {} skipped", itemPath, materialName);
            return;
        }
        ItemStack byg = new ItemStack(item);
        ModHandler.addShapelessRecipe("minespace_byg_" + recipeKey + "_to_gt",
                gt.copy(), byg.copy());
        ModHandler.addShapelessRecipe("minespace_gt_" + recipeKey + "_to_byg",
                byg.copy(), gt.copy());
    }

    private static void convertBlock(String blockPath, String blockOreName, String recipeKey) {
        Block block = ForgeRegistries.BLOCKS.getValue(new ResourceLocation("byg", blockPath));
        ItemStack gt = gtOre(blockOreName);
        if (block == null || block == Blocks.AIR || gt.isEmpty()) {
            LOG.warn("BYG conversion: {} block <-> GT {} skipped", blockPath, blockOreName);
            return;
        }
        ItemStack byg = new ItemStack(block);
        ModHandler.addShapelessRecipe("minespace_byg_" + recipeKey + "_to_gt",
                gt.copy(), byg.copy());
        ModHandler.addShapelessRecipe("minespace_gt_" + recipeKey + "_to_byg",
                byg.copy(), gt.copy());
    }

    private static void oreDict(String blockPath, String oreName) {
        Block block = ForgeRegistries.BLOCKS.getValue(new ResourceLocation("byg", blockPath));
        if (block == null || block == Blocks.AIR) {
            return;
        }
        if (OreDictionary.getOres(oreName, false).isEmpty()) {
            OreDictionary.registerOre(oreName, new ItemStack(block));
        }
    }

    private static void macerate(String blockPath, String materialName, String byproductName,
                                 int duration, int eu) {
        Block block = ForgeRegistries.BLOCKS.getValue(new ResourceLocation("byg", blockPath));
        ItemStack dust = stack(materialName, OrePrefix.dust);
        ItemStack byproduct = stack(byproductName, OrePrefix.dust);
        if (block == null || block == Blocks.AIR || dust.isEmpty()) {
            LOG.warn("BYG processing: maceration for {} skipped (block={}, dust={})",
                    blockPath, block != null, !dust.isEmpty());
            return;
        }
        RecipeBuilder<?> builder = RecipeMaps.MACERATOR_RECIPES.recipeBuilder()
                .inputs(new ItemStack(block))
                .outputs(count(dust, 2))
                .duration(duration).EUt(eu);
        if (!byproduct.isEmpty()) {
            builder.chancedOutput(count(byproduct, 1), 5000, 0);
        }
        builder.buildAndRegister();
    }

    private static void macerateGem(String itemPath, String materialName, String byproductName,
                                    int duration, int eu) {
        net.minecraft.item.Item item = ForgeRegistries.ITEMS.getValue(
                new ResourceLocation("byg", itemPath));
        ItemStack dust = stack(materialName, OrePrefix.dust);
        ItemStack byproduct = stack(byproductName, OrePrefix.dust);
        if (item == null || dust.isEmpty()) {
            LOG.warn("BYG processing: gem maceration for {} skipped (item={}, dust={})",
                    itemPath, item != null, !dust.isEmpty());
            return;
        }
        RecipeBuilder<?> builder = RecipeMaps.MACERATOR_RECIPES.recipeBuilder()
                .inputs(new ItemStack(item))
                .outputs(dust)
                .duration(duration).EUt(eu);
        if (!byproduct.isEmpty()) {
            builder.chancedOutput(count(byproduct, 1), 2500, 0);
        }
        builder.buildAndRegister();
    }

    private static ItemStack stack(String materialName, OrePrefix prefix) {
        Material material = MinespaceBygMaterials.material(materialName);
        if (material == null) {
            material = Material.MATERIAL_REGISTRY.getObject(materialName);
        }
        return material == null ? ItemStack.EMPTY : OreDictUnifier.get(prefix, material);
    }

    private static ItemStack gtOre(String oreName) {
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id != null && "gregtech".equals(id.getResourceDomain())) {
                return candidate.copy();
            }
        }
        return ItemStack.EMPTY;
    }

    private static ItemStack count(ItemStack stack, int count) {
        if (stack.isEmpty()) {
            return ItemStack.EMPTY;
        }
        ItemStack copy = stack.copy();
        copy.setCount(count);
        return copy;
    }
}
