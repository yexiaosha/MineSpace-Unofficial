package com.minespace.unofficial.gtceu.nuclear;

import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeBuilder;
import gregtech.api.recipes.RecipeMap;
import gregtech.api.recipes.RecipeMaps;
import gregtech.api.recipes.ingredients.IntCircuitIngredient;
import gregtech.api.recipes.recipes.DummyRecipe;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.stack.MaterialStack;
import gregtech.common.items.MetaItems;
import nc.config.NCConfig;
import nc.recipe.BasicRecipe;
import nc.recipe.BasicRecipeHandler;
import nc.recipe.NCRecipes;
import nc.recipe.ingredient.ChanceFluidIngredient;
import nc.recipe.ingredient.ChanceItemIngredient;
import nc.recipe.ingredient.IFluidIngredient;
import nc.recipe.ingredient.IItemIngredient;
import nc.recipe.ingredient.OreIngredient;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.CraftingManager;
import net.minecraft.item.crafting.IRecipe;
import net.minecraft.init.Blocks;
import net.minecraft.init.Items;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fluids.FluidStack;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Copies NCO's material-processing recipes into TJ's machines.
 *
 * <p>NCO 2o.9.7 ships a GTCEu recipe bridge, but it references
 * {@code gregtech.api.recipes.ingredients.GTRecipeInput}, which TJ does not have. This bridge reads
 * the finished {@link BasicRecipe} objects instead, so it works against the TJ API without the
 * missing GTCEu class. Nuclear-only machines (fission, fusion, turbine, heat exchanger, irradiator,
 * scrubber, fuel reprocessing) are intentionally not mapped here.</p>
 */
public final class MinespaceNuclearMaterials {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private static final String[] HANDLER_NAMES = NCRecipes.BASIC_PROCESSOR_RECIPE_HANDLER_NAME_ARRAY;

    private static boolean registered;
    private static int skipped;

    private MinespaceNuclearMaterials() {
    }

    public static void register() {
        if (registered) {
            return;
        }
        registered = true;
        skipped = 0;

        int total = 0;
        for (BasicRecipeHandler handler : NCRecipes.getHandlers()) {
            RecipeMap<?> map = mapFor(handler.getName());
            if (map == null) {
                continue;
            }
            int index = Arrays.asList(HANDLER_NAMES).indexOf(handler.getName());
            int added = 0;
            int skippedBefore = skipped;
            for (BasicRecipe recipe : handler.getRecipeList()) {
                if (copy(handler.getName(), recipe, map, index)) {
                    added++;
                }
            }
            LOG.info("nuclear material bridge: {} -> {} recipes ({} skipped by slot limits); "
                            + "target {} items {}-{}, fluids {}-{}, item outputs {}-{}, "
                            + "fluid outputs {}-{}",
                    handler.getName(), added, skipped - skippedBefore, map.getUnlocalizedName(),
                    map.getMinInputs(), map.getMaxInputs(),
                    map.getMinFluidInputs(), map.getMaxFluidInputs(),
                    map.getMinOutputs(), map.getMaxOutputs(),
                    map.getMinFluidOutputs(), map.getMaxFluidOutputs());
            total += added;
        }
        LOG.info("nuclear material bridge: {} recipes registered into GregTech, {} skipped",
                total, skipped);
    }

    /**
     * NCO ships 3x3 ingot-to-block recipes for its own block items. The crafting table should not be
     * a free compressor: register the same conversions on GregTech's compressor and unpacker, then
     * {@link #removeBlockCraftingRecipes()} removes the table routes.
     */
    public static void registerBlockConversions() {
        Map<String, ItemStack> targets = com.minespace.unofficial.gtceu.MinespaceMaterialRepoint
                .currentTargets();
        int added = 0;
        for (Map.Entry<String, ItemStack> entry : targets.entrySet()) {
            String[] parts = entry.getKey().split(":");
            if (parts.length != 3 || !"nuclearcraft".equals(parts[0])
                    || (!"ingot_block".equals(parts[1]) && !"ingot_block2".equals(parts[1]))) {
                continue;
            }
            Item item = ForgeRegistries.ITEMS.getValue(new ResourceLocation(parts[0], parts[1]));
            if (item == null) {
                continue;
            }
            ItemStack block = new ItemStack(item, 1, Integer.parseInt(parts[2]));
            MaterialStack materialStack = OreDictUnifier.getMaterial(entry.getValue());
            if (materialStack == null || materialStack.material == null) {
                continue;
            }
            // OreDictUnifier.get(ingot, material) follows the ore dictionary's first entry, which
            // for copper / tin / lead / magnesium is still the mod's copy. Resolve the GregTech item
            // explicitly so these machine recipes are runnable.
            ItemStack ingot = gtIngot(materialStack.material.toCamelCaseString());
            if (ingot.isEmpty()) {
                continue;
            }
            RecipeMaps.COMPRESSOR_RECIPES.recipeBuilder()
                    .inputsIngredients(Collections.singletonList(
                            CountableIngredient.from(ingot, 9)))
                    .outputs(block.copy())
                    .duration(300).EUt(2).buildAndRegister();
            ItemStack nine = ingot.copy();
            nine.setCount(9);
            RecipeMaps.UNPACKER_RECIPES.recipeBuilder()
                    .inputs(block.copy())
                    .notConsumable(new IntCircuitIngredient(1))
                    .outputs(nine)
                    .duration(300).EUt(2).buildAndRegister();
            added++;
        }
        LOG.info("nuclear block conversions: {} NCO blocks now use compressor/unpacker", added);
    }

    private static ItemStack gtIngot(String materialName) {
        for (ItemStack candidate : OreDictionary.getOres("ingot" + materialName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id != null && "gregtech".equals(id.getResourceDomain())) {
                return candidate.copy();
            }
        }
        return ItemStack.EMPTY;
    }

    /** Removes NCO's own 3x3 block recipes; the machine routes above replace them. */
    public static int removeBlockCraftingRecipes() {
        List<ResourceLocation> victims = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ItemStack output = recipe.getRecipeOutput();
            if (output.isEmpty()) {
                continue;
            }
            ResourceLocation id = output.getItem().getRegistryName();
            if (id == null || !"nuclearcraft".equals(id.getResourceDomain())
                    || (!"ingot_block".equals(id.getResourcePath())
                    && !"ingot_block2".equals(id.getResourcePath()))) {
                continue;
            }
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name == null) {
                continue;
            }
            victims.add(name);
        }
        for (ResourceLocation name : victims) {
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        int removed = victims.size();
        LOG.info("nuclear block crafting: removed {} NCO table conversions", removed);
        return removed;
    }

    /**
     * NCO's four plating items were crafting-table recipes made from raw ingots and dusts. Replace
     * them with assembler recipes that consume GregTech plates.
     */
    public static void registerPlatingRecipes() {
        Item part = ForgeRegistries.ITEMS.getValue(new ResourceLocation("nuclearcraft", "part"));
        if (part == null) {
            return;
        }
        ItemStack leadPlate = gtOre("plateLead", 2);
        ItemStack graphitePlate = gtOre("plateGraphite", 2);
        ItemStack toughPlate = gtOre("plateTough", 2);
        ItemStack boronPlate = gtOre("plateBoron", 4);
        ItemStack binder = gtOre("dustCrystalBinder", 4);
        Item uranium = ForgeRegistries.ITEMS.getValue(new ResourceLocation("nuclearcraft", "uranium"));
        ItemStack u238 = uranium == null ? ItemStack.EMPTY : new ItemStack(uranium, 4, 10);
        if (leadPlate.isEmpty() || graphitePlate.isEmpty() || toughPlate.isEmpty()
                || boronPlate.isEmpty() || binder.isEmpty() || u238.isEmpty()) {
            LOG.warn("plating recipes skipped: missing GT plate/dust inputs "
                            + "(lead={}, graphite={}, tough={}, boron={}, binder={}, u238={})",
                    leadPlate.isEmpty(), graphitePlate.isEmpty(), toughPlate.isEmpty(),
                    boronPlate.isEmpty(), binder.isEmpty(), u238.isEmpty());
            return;
        }

        List<CountableIngredient> basicInputs = new ArrayList<>();
        basicInputs.add(CountableIngredient.from(leadPlate, 2));
        basicInputs.add(CountableIngredient.from(graphitePlate, 2));
        RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                .inputsIngredients(basicInputs)
                .outputs(new ItemStack(part, 2, 0))
                .duration(100).EUt(30).buildAndRegister();

        List<CountableIngredient> advancedInputs = new ArrayList<>();
        advancedInputs.add(CountableIngredient.from(toughPlate, 2));
        advancedInputs.add(CountableIngredient.from(new ItemStack(Items.REDSTONE, 2), 2));
        advancedInputs.add(CountableIngredient.from(new ItemStack(part, 1, 0), 1));
        RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                .inputsIngredients(advancedInputs)
                .outputs(new ItemStack(part, 1, 1))
                .duration(200).EUt(120).buildAndRegister();

        List<CountableIngredient> duInputs = new ArrayList<>();
        duInputs.add(CountableIngredient.from(binder, 4));
        duInputs.add(CountableIngredient.from(u238, 4));
        duInputs.add(CountableIngredient.from(new ItemStack(part, 1, 1), 1));
        RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                .inputsIngredients(duInputs)
                .outputs(new ItemStack(part, 1, 2))
                .duration(400).EUt(480).buildAndRegister();

        List<CountableIngredient> eliteInputs = new ArrayList<>();
        eliteInputs.add(CountableIngredient.from(binder, 4));
        eliteInputs.add(CountableIngredient.from(boronPlate, 4));
        eliteInputs.add(CountableIngredient.from(new ItemStack(part, 1, 2), 1));
        RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                .inputsIngredients(eliteInputs)
                .outputs(new ItemStack(part, 1, 3))
                .duration(800).EUt(1920).buildAndRegister();

        LOG.info("plating recipes: basic/advanced/DU/elite now assembled from GT plates");
    }

    private static ItemStack gtOre(String oreName, int count) {
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id != null && "gregtech".equals(id.getResourceDomain())) {
                ItemStack stack = candidate.copy();
                stack.setCount(count);
                return stack;
            }
        }
        return ItemStack.EMPTY;
    }

    /**
     * Resolves a GregTech plate by both ore-dictionary name and material, so a stale alias left by
     * another mod cannot silently turn a silicon-carbide plate into a different metal plate.
     */
    private static ItemStack gtPlate(String oreName) {
        String expected = oreName.substring("plate".length());
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id == null || !"gregtech".equals(id.getResourceDomain())) {
                continue;
            }
            MaterialStack material = OreDictUnifier.getMaterial(candidate);
            if (material != null && material.material != null
                    && expected.equals(material.material.toCamelCaseString())) {
                ItemStack result = candidate.copy();
                result.setCount(1);
                return result;
            }
        }
        return ItemStack.EMPTY;
    }

    /** Resolves a GregTech dust by ore-dictionary name and material, for the PV dopants. */
    private static ItemStack gtDust(String oreName) {
        String expected = oreName.substring("dust".length());
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id == null || !"gregtech".equals(id.getResourceDomain())) {
                continue;
            }
            MaterialStack material = OreDictUnifier.getMaterial(candidate);
            if (material != null && material.material != null
                    && expected.equals(material.material.toCamelCaseString())) {
                ItemStack result = candidate.copy();
                result.setCount(1);
                return result;
            }
        }
        return ItemStack.EMPTY;
    }

    /** Removes the four old table plating recipes (part, part_1..part_4). */
    public static int removePlatingCraftingRecipes() {
        List<ResourceLocation> victims = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            ItemStack output = recipe.getRecipeOutput();
            ResourceLocation outputId = output.isEmpty() ? null
                    : output.getItem().getRegistryName();
            if (name != null && outputId != null && "nuclearcraft".equals(
                    outputId.getResourceDomain()) && "part".equals(outputId.getResourcePath())
                    && output.getMetadata() >= 0 && output.getMetadata() <= 3) {
                victims.add(name);
            }
        }
        for (ResourceLocation name : victims) {
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        LOG.info("plating crafting: removed {} old NCO table recipes", victims.size());
        return victims.size();
    }

    /**
     * Replaces NCO's cheap battery table recipes with tiered GregTech assembler recipes.
     * Each block consumes a GT battery hull (or the previous tier block), the matching plating,
     * GT plates and a tier circuit.
     */
    public static void registerBatteryRecipes() {
        Item voltaicBasic = ncoItem("voltaic_pile_basic");
        Item voltaicAdvanced = ncoItem("voltaic_pile_advanced");
        Item voltaicDu = ncoItem("voltaic_pile_du");
        Item voltaicElite = ncoItem("voltaic_pile_elite");
        Item lithiumBasic = ncoItem("lithium_ion_battery_basic");
        Item lithiumAdvanced = ncoItem("lithium_ion_battery_advanced");
        Item lithiumDu = ncoItem("lithium_ion_battery_du");
        Item lithiumElite = ncoItem("lithium_ion_battery_elite");
        Item cell = ncoItem("lithium_ion_cell");
        Item part = ncoItem("part");
        if (voltaicBasic == null || voltaicAdvanced == null || voltaicDu == null
                || voltaicElite == null || lithiumBasic == null || lithiumAdvanced == null
                || lithiumDu == null || lithiumElite == null || cell == null || part == null) {
            LOG.warn("battery recipes skipped: an NCO battery/part item is missing");
            return;
        }
        ItemStack hullLv = MetaItems.BATTERY_HULL_LV.getStackForm();
        ItemStack hullMv = MetaItems.BATTERY_HULL_MV.getStackForm();
        ItemStack hullHv = MetaItems.BATTERY_HULL_HV.getStackForm();
        if (hullLv.isEmpty() || hullMv.isEmpty() || hullHv.isEmpty()) {
            LOG.warn("battery recipes skipped: GT battery hulls are missing");
            return;
        }

        List<CountableIngredient> inputs = new ArrayList<>();
        add(inputs, hullLv, 1);
        add(inputs, new ItemStack(part, 4, 0), 4);
        add(inputs, gtOre("plateLead", 2), 2);
        add(inputs, new ItemStack(Items.REDSTONE, 2), 2);
        add(inputs, gtOre("circuitBasic", 1), 1);
        assemble("voltaic_pile_basic", inputs, new ItemStack(voltaicBasic), 100, 30);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(voltaicBasic), 1);
        add(inputs, new ItemStack(part, 4, 1), 4);
        add(inputs, gtOre("plateAluminium", 2), 2);
        add(inputs, new ItemStack(Items.REDSTONE, 2), 2);
        add(inputs, gtOre("circuitGood", 1), 1);
        assemble("voltaic_pile_advanced", inputs, new ItemStack(voltaicAdvanced), 200, 120);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(voltaicAdvanced), 1);
        add(inputs, new ItemStack(part, 4, 2), 4);
        add(inputs, gtOre("plateStainlessSteel", 2), 2);
        add(inputs, gtOre("plateLead", 2), 2);
        add(inputs, gtOre("circuitAdvanced", 1), 1);
        assemble("voltaic_pile_du", inputs, new ItemStack(voltaicDu), 400, 480);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(voltaicDu), 1);
        add(inputs, new ItemStack(part, 4, 3), 4);
        add(inputs, gtOre("plateTitanium", 2), 2);
        add(inputs, gtOre("plateTungsten", 2), 2);
        add(inputs, gtOre("circuitElite", 1), 1);
        assemble("voltaic_pile_elite", inputs, new ItemStack(voltaicElite), 800, 1920);

        inputs = new ArrayList<>();
        add(inputs, hullHv, 1);
        add(inputs, gtOre("plateAluminium", 2), 2);
        add(inputs, gtOre("dustLithium", 2), 2);
        add(inputs, gtOre("dustCarbon", 1), 1);
        add(inputs, gtOre("circuitAdvanced", 1), 1);
        assemble("lithium_ion_cell", inputs, new ItemStack(cell), 200, 480);

        inputs = new ArrayList<>();
        add(inputs, hullHv, 1);
        add(inputs, new ItemStack(part, 4, 1), 4);
        add(inputs, new ItemStack(cell, 4, 0), 4);
        add(inputs, gtOre("plateAluminium", 2), 2);
        add(inputs, gtOre("circuitAdvanced", 1), 1);
        assemble("lithium_ion_battery_basic", inputs, new ItemStack(lithiumBasic), 400, 480);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(lithiumBasic), 1);
        add(inputs, new ItemStack(part, 4, 3), 4);
        add(inputs, new ItemStack(cell, 4, 0), 4);
        add(inputs, gtOre("plateStainlessSteel", 2), 2);
        add(inputs, gtOre("circuitElite", 1), 1);
        assemble("lithium_ion_battery_advanced", inputs, new ItemStack(lithiumAdvanced), 800, 1920);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(lithiumAdvanced), 1);
        add(inputs, new ItemStack(part, 4, 3), 4);
        add(inputs, new ItemStack(cell, 4, 0), 4);
        add(inputs, gtOre("plateTungstenSteel", 2), 2);
        add(inputs, gtOre("circuitMaster", 1), 1);
        assemble("lithium_ion_battery_du", inputs, new ItemStack(lithiumDu), 1600, 7680);

        inputs = new ArrayList<>();
        add(inputs, new ItemStack(lithiumDu), 1);
        add(inputs, new ItemStack(part, 4, 3), 4);
        add(inputs, new ItemStack(cell, 4, 0), 4);
        add(inputs, gtOre("plateHsse", 2), 2);
        add(inputs, gtOre("circuitUltimate", 1), 1);
        assemble("lithium_ion_battery_elite", inputs, new ItemStack(lithiumElite), 3200, 30720);
    }

    private static Item ncoItem(String name) {
        return ForgeRegistries.ITEMS.getValue(new ResourceLocation("nuclearcraft", name));
    }

    private static void add(List<CountableIngredient> inputs, ItemStack stack, int count) {
        if (!stack.isEmpty()) {
            inputs.add(CountableIngredient.from(stack, count));
        }
    }

    private static void assemble(String name, List<CountableIngredient> inputs, ItemStack output,
                                 int duration, int eu) {
        if (inputs.size() < 2 || output.isEmpty()) {
            LOG.warn("assembler recipe {} skipped: missing inputs or output", name);
            return;
        }
        RecipeMaps.ASSEMBLER_RECIPES.recipeBuilder()
                .inputsIngredients(inputs)
                .outputs(output)
                .duration(duration).EUt(eu).buildAndRegister();
    }

    /** Removes the nine old NCO battery/cell table recipes. */
    public static int removeBatteryCraftingRecipes() {
        List<String> names = Arrays.asList(
                "voltaic_pile_basic", "voltaic_pile_advanced", "voltaic_pile_du",
                "voltaic_pile_elite", "lithium_ion_battery_basic",
                "lithium_ion_battery_advanced", "lithium_ion_battery_du",
                "lithium_ion_battery_elite", "lithium_ion_cell");
        List<ResourceLocation> victims = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            ItemStack output = recipe.getRecipeOutput();
            ResourceLocation outputId = output.isEmpty() ? null
                    : output.getItem().getRegistryName();
            if (name != null && outputId != null && "nuclearcraft".equals(
                    outputId.getResourceDomain())
                    && names.contains(outputId.getResourcePath())) {
                victims.add(name);
            }
        }
        for (ResourceLocation name : victims) {
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        LOG.info("battery crafting: removed {} old NCO table recipes", victims.size());
        return victims.size();
    }

    /**
     * Replaces NCO's four crafting-table solar panels with GregTech assembler recipes built around
     * the parts a real photovoltaic module needs: a silicon absorber, a transparent cover, a frame,
     * busbars, encapsulation and a blocking diode / power-conditioning circuit.
     *
     * <p>The tiers follow NCO's 5 / 20 / 80 / 320 RF/t progression. Each tier reuses two panels from
     * the tier below instead of the old three, because the new material bill (silicon carbide heat
     * spreaders, lead/DU shielding, platinum busbars, the thicker elite silicon stack) already
     * carries the cost.</p>
     */
    public static void registerSolarPanelRecipes() {
        Item basic = ncoItem("solar_panel_basic");
        Item advanced = ncoItem("solar_panel_advanced");
        Item du = ncoItem("solar_panel_du");
        Item elite = ncoItem("solar_panel_elite");
        Item part = ncoItem("part");
        if (basic == null || advanced == null || du == null || elite == null || part == null) {
            LOG.warn("solar panel recipes skipped: an NCO solar panel or part item is missing");
            return;
        }

        ItemStack silicon = gtPlate("plateSilicon");
        ItemStack siliconCarbide = gtPlate("plateSiliconCarbide");
        ItemStack borosilicate = gtPlate("plateBorosilicateGlass");
        ItemStack aluminium = gtPlate("plateAluminium");
        ItemStack stainless = gtPlate("plateStainlessSteel");
        ItemStack titanium = gtPlate("plateTitanium");
        ItemStack tungstenSteel = gtPlate("plateTungstenSteel");
        ItemStack lead = gtPlate("plateLead");
        ItemStack ptfe = gtPlate("platePolytetrafluoroethylene");
        ItemStack siliconeRubber = gtPlate("plateSiliconRubber");
        ItemStack boronDust = gtDust("dustBoron");
        ItemStack phosphorusDust = gtDust("dustPhosphorus");
        ItemStack copperWire = gtOre("wireFineCopper", 1);
        ItemStack silverWire = gtOre("wireFineSilver", 1);
        ItemStack goldWire = gtOre("wireFineGold", 1);
        ItemStack platinumWire = gtOre("wireFinePlatinum", 1);
        ItemStack circuitBasic = gtOre("circuitBasic", 1);
        ItemStack circuitGood = gtOre("circuitGood", 1);
        ItemStack circuitAdvanced = gtOre("circuitAdvanced", 1);
        ItemStack circuitElite = gtOre("circuitElite", 1);
        if (silicon.isEmpty() || siliconCarbide.isEmpty() || borosilicate.isEmpty()
                || aluminium.isEmpty()
                || stainless.isEmpty() || titanium.isEmpty() || tungstenSteel.isEmpty()
                || lead.isEmpty() || ptfe.isEmpty() || siliconeRubber.isEmpty()
                || boronDust.isEmpty() || phosphorusDust.isEmpty()
                || copperWire.isEmpty() || silverWire.isEmpty() || goldWire.isEmpty()
                || platinumWire.isEmpty() || circuitBasic.isEmpty() || circuitGood.isEmpty()
                || circuitAdvanced.isEmpty() || circuitElite.isEmpty()) {
            LOG.warn("solar panel recipes skipped: a GT plate, wire or circuit is missing");
            return;
        }

        // Basic: a glass-covered monocrystalline module on an aluminium frame. Boron and phosphorus
        // are the p-type and n-type dopants that form the cell's junction; fine copper wires are the
        // interconnects and the silicon-rubber sheet is the encapsulant / backsheet.
        List<CountableIngredient> inputs = new ArrayList<>();
        add(inputs, silicon, 4);
        add(inputs, boronDust, 1);
        add(inputs, phosphorusDust, 1);
        add(inputs, new ItemStack(Blocks.GLASS, 2), 2);
        add(inputs, aluminium, 2);
        add(inputs, copperWire, 4);
        add(inputs, siliconeRubber, 1);
        add(inputs, circuitBasic, 1);
        assemble("solar_panel_basic", inputs, new ItemStack(basic), 400, 30);

        // Advanced: a laminated module with a silicon-carbide heat spreader and silver busbars.
        inputs = new ArrayList<>();
        add(inputs, new ItemStack(basic, 2), 2);
        add(inputs, silicon, 4);
        add(inputs, siliconCarbide, 2);
        add(inputs, borosilicate, 2);
        add(inputs, stainless, 2);
        add(inputs, silverWire, 4);
        add(inputs, ptfe, 1);
        add(inputs, circuitGood, 1);
        assemble("solar_panel_advanced", inputs, new ItemStack(advanced), 600, 120);

        // DU: a radiation-hardened module. Lead and NCO's depleted-uranium plating shield the cells;
        // gold busbars and a titanium frame carry the higher current and thermal load.
        inputs = new ArrayList<>();
        add(inputs, new ItemStack(advanced, 2), 2);
        add(inputs, siliconCarbide, 4);
        add(inputs, lead, 2);
        add(inputs, new ItemStack(part, 2, 2), 2);
        add(inputs, titanium, 2);
        add(inputs, goldWire, 4);
        add(inputs, circuitAdvanced, 1);
        assemble("solar_panel_du", inputs, new ItemStack(du), 800, 480);

        // Elite: a space-grade multi-junction module. The absorber is a thicker silicon stack,
        // backed by silicon-carbide heat spreaders and a refractory tungsten-steel frame.
        inputs = new ArrayList<>();
        add(inputs, new ItemStack(du, 2), 2);
        add(inputs, silicon, 4);
        add(inputs, siliconCarbide, 2);
        add(inputs, tungstenSteel, 2);
        add(inputs, ptfe, 2);
        add(inputs, platinumWire, 4);
        add(inputs, circuitElite, 1);
        assemble("solar_panel_elite", inputs, new ItemStack(elite), 1200, 1920);
    }

    /** Removes every crafting-table recipe whose output is one of NCO's four solar panels. */
    public static int removeSolarPanelCraftingRecipes() {
        Set<String> names = new HashSet<>(Arrays.asList(
                "solar_panel_basic", "solar_panel_advanced",
                "solar_panel_du", "solar_panel_elite"));
        List<ResourceLocation> victims = new ArrayList<>();
        for (IRecipe recipe : CraftingManager.REGISTRY) {
            ItemStack output = recipe.getRecipeOutput();
            if (output.isEmpty()) {
                continue;
            }
            ResourceLocation outputId = output.getItem().getRegistryName();
            if (outputId == null || !"nuclearcraft".equals(outputId.getResourceDomain())
                    || !names.contains(outputId.getResourcePath())) {
                continue;
            }
            ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
            if (name != null) {
                victims.add(name);
            }
        }
        for (ResourceLocation name : victims) {
            ForgeRegistries.RECIPES.register(new DummyRecipe().setRegistryName(name));
        }
        LOG.info("solar panel crafting: removed {} old NCO table recipes", victims.size());
        return victims.size();
    }

    /**
     * Alloy smelter recipes should accept ingots and dusts interchangeably. The NCO bridge often
     * produces only the ingot+ingot shape, so this pass adds the ingot+dust, dust+ingot and
     * dust+dust shapes with the same output, duration and EU/t.
     */
    public static int registerAlloyDustVariants() {
        List<Recipe> originals = new ArrayList<>(
                RecipeMaps.ALLOY_SMELTER_RECIPES.getRecipeList());
        Set<String> seen = new HashSet<>();
        for (Recipe recipe : originals) {
            seen.add(recipeKey(recipe.getInputs(), recipe.getOutputs()));
        }
        int added = 0;
        for (Recipe recipe : originals) {
            List<CountableIngredient> inputs = recipe.getInputs();
            if (inputs.size() != 2) {
                continue;
            }
            if (!hasIngotOutput(recipe.getOutputs())) {
                continue;
            }
            List<List<CountableIngredient>> options = new ArrayList<>();
            boolean hasDustChoice = false;
            for (CountableIngredient input : inputs) {
                List<CountableIngredient> choices = new ArrayList<>();
                choices.add(input);
                ItemStack dust = dustEquivalent(input);
                if (!dust.isEmpty()) {
                    choices.add(CountableIngredient.from(dust, input.getCount()));
                    hasDustChoice = true;
                }
                options.add(choices);
            }
            if (!hasDustChoice) {
                continue;
            }
            for (CountableIngredient first : options.get(0)) {
                for (CountableIngredient second : options.get(1)) {
                    List<CountableIngredient> combo = Arrays.asList(first, second);
                    String key = recipeKey(combo, recipe.getOutputs());
                    if (!seen.add(key)) {
                        continue;
                    }
                    RecipeMaps.ALLOY_SMELTER_RECIPES.recipeBuilder()
                            .inputsIngredients(combo)
                            .outputs(recipe.getOutputs())
                            .duration(recipe.getDuration())
                            .EUt(recipe.getEUt())
                            .buildAndRegister();
                    added++;
                }
            }
        }
        LOG.info("alloy dust variants: {} extra alloy-smelter recipes", added);
        return added;
    }

    private static boolean hasIngotOutput(Iterable<ItemStack> outputs) {
        for (ItemStack output : outputs) {
            if (output.isEmpty()) {
                continue;
            }
            for (int oreId : OreDictionary.getOreIDs(output)) {
                if (OreDictionary.getOreName(oreId).startsWith("ingot")) {
                    return true;
                }
            }
        }
        return false;
    }

    /** Returns GT's dust for an ingot-only input, or EMPTY when the input is not a plain ingot. */
    private static ItemStack dustEquivalent(CountableIngredient input) {
        ItemStack[] stacks = input.getIngredient().getMatchingStacks();
        if (stacks.length == 0) {
            return ItemStack.EMPTY;
        }
        String materialName = null;
        boolean ingotPreferred = false;
        for (int oreId : OreDictionary.getOreIDs(stacks[0])) {
            String name = OreDictionary.getOreName(oreId);
            if (name.startsWith("dust")) {
                return ItemStack.EMPTY;
            }
            if (name.startsWith("ingot") && !ingotPreferred) {
                materialName = name.substring("ingot".length());
                ingotPreferred = true;
            } else if (name.startsWith("item") && materialName == null) {
                // GT registers silicon as itemSilicon rather than ingotSilicon.
                materialName = name.substring("item".length());
            }
        }
        if (materialName == null || materialName.isEmpty()) {
            return ItemStack.EMPTY;
        }
        String dustName = "dust" + materialName;
        List<ItemStack> dusts = OreDictionary.getOres(dustName, false);
        if (dusts.isEmpty()) {
            return ItemStack.EMPTY;
        }
        for (ItemStack candidate : dusts) {
            ResourceLocation id = candidate.getItem().getRegistryName();
            if (id != null && "gregtech".equals(id.getResourceDomain())) {
                return candidate.copy();
            }
        }
        return dusts.get(0).copy();
    }

    private static String recipeKey(List<CountableIngredient> inputs,
                                    Iterable<ItemStack> outputs) {
        StringBuilder key = new StringBuilder();
        for (CountableIngredient input : inputs) {
            ItemStack[] stacks = input.getIngredient().getMatchingStacks();
            key.append(stacks.length == 0 ? "?" : itemId(stacks[0]))
                    .append('x').append(input.getCount()).append(';');
        }
        key.append("->");
        for (ItemStack output : outputs) {
            key.append(itemId(output)).append('x').append(output.getCount()).append(';');
        }
        return key.toString();
    }

    private static String itemId(ItemStack stack) {
        return String.valueOf(stack.getItem().getRegistryName()) + ":" + stack.getMetadata();
    }

    private static RecipeMap<?> mapFor(String name) {
        switch (name) {
            case "manufactory":
                return RecipeMaps.MACERATOR_RECIPES;
            case "alloy_furnace":
                return RecipeMaps.ALLOY_SMELTER_RECIPES;
            case "infuser":
                return RecipeMaps.CHEMICAL_RECIPES;
            case "melter":
                return RecipeMaps.FLUID_EXTRACTION_RECIPES;
            case "supercooler":
                return RecipeMaps.VACUUM_RECIPES;
            case "electrolyzer":
                return RecipeMaps.ELECTROLYZER_RECIPES;
            case "assembler":
                return RecipeMaps.ASSEMBLER_RECIPES;
            case "ingot_former":
                return RecipeMaps.FLUID_SOLIDFICATION_RECIPES;
            case "pressurizer":
                return RecipeMaps.BENDER_RECIPES;
            case "chemical_reactor":
                return RecipeMaps.CHEMICAL_RECIPES;
            case "salt_mixer":
                return RecipeMaps.MIXER_RECIPES;
            case "crystallizer":
                return RecipeMaps.CHEMICAL_RECIPES;
            case "enricher":
                return RecipeMaps.CHEMICAL_RECIPES;
            case "extractor":
                // NCO's extractor is one item in, one item plus one fluid out. GT's extractor map
                // in this fork has no fluid output, while the chemical reactor has exactly the
                // slots this recipe needs.
                return RecipeMaps.CHEMICAL_RECIPES;
            case "rock_crusher":
                return RecipeMaps.MACERATOR_RECIPES;
            default:
                return null;
        }
    }

    @SuppressWarnings({"rawtypes", "unchecked"})
    private static boolean copy(String handlerName, BasicRecipe recipe, RecipeMap<?> map, int index) {
        List<CountableIngredient> itemInputs = new ArrayList<>();
        for (IItemIngredient ingredient : recipe.getItemIngredients()) {
            if (ingredient == null) {
                continue;
            }
            if (ingredient instanceof OreIngredient) {
                OreIngredient ore = (OreIngredient) ingredient;
                if (ore.stackSize <= 0 || ore.oreName == null || ore.oreName.isEmpty()
                        || OreDictionary.getOres(ore.oreName, false).isEmpty()) {
                    return false;
                }
                itemInputs.add(CountableIngredient.from(ore.oreName, ore.stackSize));
                continue;
            }
            Object raw = ingredient.getStack();
            if (!(raw instanceof ItemStack)) {
                continue;
            }
            ItemStack stack = (ItemStack) raw;
            if (!stack.isEmpty()) {
                itemInputs.add(CountableIngredient.from(stack, stack.getCount()));
            }
        }

        List<FluidStack> fluidInputs = new ArrayList<>();
        for (IFluidIngredient ingredient : recipe.getFluidIngredients()) {
            if (ingredient == null) {
                continue;
            }
            Object raw = ingredient.getStack();
            if (raw instanceof FluidStack && ((FluidStack) raw).amount > 0) {
                fluidInputs.add(((FluidStack) raw).copy());
            }
        }
        if (itemInputs.isEmpty() && fluidInputs.isEmpty()) {
            return false;
        }

        List<ItemStack> outputs = new ArrayList<>();
        List<FluidStack> fluidOutputs = new ArrayList<>();
        List<ChanceItemIngredient> chancedItems = new ArrayList<>();
        for (IItemIngredient ingredient : recipe.getItemProducts()) {
            if (ingredient instanceof ChanceItemIngredient) {
                chancedItems.add((ChanceItemIngredient) ingredient);
                continue;
            }
            Object raw = ingredient == null ? null : ingredient.getStack();
            if (raw instanceof ItemStack && !((ItemStack) raw).isEmpty()) {
                outputs.add(((ItemStack) raw).copy());
            }
        }
        for (IFluidIngredient ingredient : recipe.getFluidProducts()) {
            if (ingredient == null) {
                continue;
            }
            if (ingredient instanceof ChanceFluidIngredient) {
                ingredient = ((ChanceFluidIngredient) ingredient).getRawIngredient();
            }
            Object raw = ingredient.getStack();
            if (raw instanceof FluidStack && ((FluidStack) raw).amount > 0) {
                fluidOutputs.add(((FluidStack) raw).copy());
            }
        }
        if (outputs.isEmpty() && fluidOutputs.isEmpty() && chancedItems.isEmpty()) {
            return false;
        }
        // Not every NCO processor recipe fits the GregTech map it is copied into. The assembler,
        // for example, requires two item inputs while some NCO assembler recipes use one. Asking
        // RecipeMap to validate those produces one ERROR stack trace per recipe (tens of thousands
        // of log lines) and registers nothing. Check the slot counts first and leave the recipe in
        // NCO's own machine, which is still available.
        int itemOutputCount = outputs.size() + chancedItems.size();
        int markerInputs = needsMarkerInput(handlerName) ? 1 : 0;
        if (itemInputs.size() + markerInputs < map.getMinInputs()
                || itemInputs.size() + markerInputs > map.getMaxInputs()
                || fluidInputs.size() < map.getMinFluidInputs()
                || fluidInputs.size() > map.getMaxFluidInputs()
                || itemOutputCount < map.getMinOutputs()
                || itemOutputCount > map.getMaxOutputs()
                || fluidOutputs.size() < map.getMinFluidOutputs()
                || fluidOutputs.size() > map.getMaxFluidOutputs()) {
            skipped++;
            return false;
        }

        RecipeBuilder builder = map.recipeBuilder();
        if (!itemInputs.isEmpty()) {
            builder.inputsIngredients(itemInputs);
        }
        if (!fluidInputs.isEmpty()) {
            builder.fluidInputs(fluidInputs);
        }
        if (!outputs.isEmpty()) {
            builder.outputs(outputs);
        }
        if (!fluidOutputs.isEmpty()) {
            builder.fluidOutputs(fluidOutputs);
        }
        for (ChanceItemIngredient chance : chancedItems) {
            Object raw = chance.getRawIngredient().getStack();
            if (raw instanceof ItemStack && !((ItemStack) raw).isEmpty()) {
                builder.chancedOutput((ItemStack) raw, chance.getChancePercent(), 0);
            }
        }
        if (needsMarkerInput(handlerName)) {
            // The bender and fluid solidifier reserve a second input slot for a non-consumable
            // shape. NCO's pressurizer / ingot former only have the material, so use a circuit as
            // the marker; it keeps the recipe runnable without inventing a shape per output.
            builder.notConsumable(new IntCircuitIngredient(1));
        }
        if ("crystallizer".equals(handlerName)) {
            builder.notConsumable(new IntCircuitIngredient(1));
        } else if ("enricher".equals(handlerName)) {
            builder.notConsumable(new IntCircuitIngredient(2));
        }

        int baseTime = index >= 0 && index < NCConfig.processor_time.length
                ? NCConfig.processor_time[index] : 200;
        int basePower = index >= 0 && index < NCConfig.processor_power.length
                ? NCConfig.processor_power[index] : 30;
        int duration = Math.max(1, (int) Math.round(recipe.getBaseProcessTime(baseTime)));
        int eu = Math.max(1, (int) Math.round(
                recipe.getBaseProcessPower(basePower) / Math.max(1, NCConfig.rf_per_eu)));
        builder.duration(duration).EUt(eu);
        try {
            builder.buildAndRegister();
            return true;
        } catch (RuntimeException invalid) {
            skipped++;
            return false;
        }
    }

    private static boolean needsMarkerInput(String handlerName) {
        return "pressurizer".equals(handlerName) || "ingot_former".equals(handlerName);
    }
}
