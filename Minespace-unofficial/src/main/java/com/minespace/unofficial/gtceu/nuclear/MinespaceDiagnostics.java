package com.minespace.unofficial.gtceu.nuclear;

import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import gregtech.api.recipes.RecipeMaps;
import lach_01298.qmd.particle.ParticleStack;
import lach_01298.qmd.recipe.QMDRecipe;
import lach_01298.qmd.recipe.QMDRecipeHandler;
import lach_01298.qmd.recipe.ingredient.IParticleIngredient;
import lach_01298.qmd.recipes.QMDRecipes;
import nc.recipe.BasicRecipe;
import nc.recipe.BasicRecipeHandler;
import nc.recipe.NCRecipes;
import nc.recipe.ingredient.ChanceFluidIngredient;
import nc.recipe.ingredient.ChanceItemIngredient;
import nc.recipe.ingredient.IFluidIngredient;
import nc.recipe.ingredient.IItemIngredient;
import nc.recipe.ingredient.OreIngredient;
import net.minecraft.block.Block;
import net.minecraft.creativetab.CreativeTabs;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.CraftingManager;
import net.minecraft.item.crafting.IRecipe;
import net.minecraft.item.crafting.Ingredient;
import net.minecraft.util.NonNullList;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fluids.FluidStack;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * One-shot exporter for compatibility audits.
 *
 * <p>Run the pack with {@code -Dminespace.exportDiagnostics=true}; the server writes CSV files
 * under {@code minespace-diagnostics/} in its game directory. The exporter only reads registries
 * and recipe lists, so it does not change the world or the pack.</p>
 */
public final class MinespaceDiagnostics {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private MinespaceDiagnostics() {
    }

    public static void exportAll() {
        File dir = new File("minespace-diagnostics");
        if (!dir.isDirectory() && !dir.mkdirs()) {
            LOG.warn("diagnostics: could not create {}", dir.getAbsolutePath());
            return;
        }
        try {
            int items = exportItems(new File(dir, "items.csv"));
            int blocks = exportBlocks(new File(dir, "blocks.csv"));
            int oreEntries = exportOreDictionary(new File(dir, "ore-dictionary.csv"));
            int gtRecipes = exportGtRecipes(new File(dir, "gt-recipes.csv"));
            int ncoRecipes = exportNcoRecipes(new File(dir, "nco-recipes.csv"));
            int qmdRecipes = exportQmdRecipes(new File(dir, "qmd-recipes.csv"));
            int craftingRecipes = exportCraftingRecipes(new File(dir, "crafting-recipes.csv"));
            int materialTargets = exportMaterialTargets(new File(dir, "material-targets.csv"));
            try (Writer out = writer(new File(dir, "summary.txt"))) {
                out.write("items=" + items + "\n");
                out.write("blocks=" + blocks + "\n");
                out.write("ore_dictionary_rows=" + oreEntries + "\n");
                out.write("gt_recipes=" + gtRecipes + "\n");
                out.write("nco_recipes=" + ncoRecipes + "\n");
                out.write("qmd_recipes=" + qmdRecipes + "\n");
                out.write("crafting_recipes=" + craftingRecipes + "\n");
                out.write("material_targets=" + materialTargets + "\n");
            }
            LOG.info("diagnostics: exported items={}, blocks={}, oredict={}, gt={}, nco={}, qmd={} to {}",
                    items, blocks, oreEntries, gtRecipes, ncoRecipes, qmdRecipes, dir.getAbsolutePath());
        } catch (IOException e) {
            LOG.warn("diagnostics export failed", e);
        }
    }

    private static int exportMaterialTargets(File file) throws IOException {
        int count = 0;
        java.util.Map<String, ItemStack> targets =
                com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.currentTargets();
        try (Writer out = writer(file)) {
            row(out, "source", "target");
            List<String> keys = new ArrayList<>(targets.keySet());
            keys.sort(String::compareTo);
            for (String source : keys) {
                ItemStack target = targets.get(source);
                row(out, source, target == null ? "" : itemId(target));
                count++;
            }
        }
        return count;
    }

    private static int exportItems(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "registry", "meta", "unlocalized", "display", "max_stack", "ore_dict");
            Set<String> seen = new HashSet<>();
            List<Item> items = new ArrayList<>(ForgeRegistries.ITEMS.getValuesCollection());
            items.sort(Comparator.comparing(item -> String.valueOf(item.getRegistryName())));
            for (Item item : items) {
                NonNullList<ItemStack> stacks = NonNullList.create();
                try {
                    item.getSubItems(CreativeTabs.SEARCH, stacks);
                } catch (Throwable ignored) {
                    stacks.clear();
                }
                if (stacks.isEmpty()) {
                    stacks.add(new ItemStack(item));
                }
                ResourceLocation name = item.getRegistryName();
                for (ItemStack stack : stacks) {
                    if (stack.isEmpty()) {
                        continue;
                    }
                    String key = String.valueOf(name) + ":" + stack.getMetadata();
                    if (!seen.add(key)) {
                        continue;
                    }
                    row(out,
                            String.valueOf(name),
                            stack.getMetadata(),
                            stack.getUnlocalizedName(),
                            display(stack),
                            stack.getMaxStackSize(),
                            oreNames(stack));
                    count++;
                }
            }
        }
        return count;
    }

    private static int exportBlocks(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "registry", "unlocalized", "class");
            List<Block> blocks = new ArrayList<>(ForgeRegistries.BLOCKS.getValuesCollection());
            blocks.sort(Comparator.comparing(block -> String.valueOf(block.getRegistryName())));
            for (Block block : blocks) {
                row(out,
                        String.valueOf(block.getRegistryName()),
                        block.getUnlocalizedName(),
                        block.getClass().getName());
                count++;
            }
        }
        return count;
    }

    private static int exportOreDictionary(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "ore_name", "registry", "meta", "display", "count");
            List<String> names = new ArrayList<>(Arrays.asList(OreDictionary.getOreNames()));
            names.sort(String::compareTo);
            for (String name : names) {
                for (ItemStack stack : OreDictionary.getOres(name, false)) {
                    if (stack.isEmpty()) {
                        continue;
                    }
                    row(out, name, String.valueOf(stack.getItem().getRegistryName()),
                            stack.getMetadata(), display(stack), stack.getCount());
                    count++;
                }
            }
        }
        return count;
    }

    private static int exportCraftingRecipes(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "name", "output", "inputs", "class");
            for (IRecipe recipe : CraftingManager.REGISTRY) {
                ResourceLocation name = CraftingManager.REGISTRY.getNameForObject(recipe);
                ItemStack output = recipe.getRecipeOutput();
                List<String> inputs = new ArrayList<>();
                for (Ingredient ingredient : recipe.getIngredients()) {
                    if (ingredient == null || ingredient == Ingredient.EMPTY) {
                        continue;
                    }
                    ItemStack[] stacks = ingredient.getMatchingStacks();
                    if (stacks.length == 0) {
                        inputs.add("?");
                        continue;
                    }
                    String id = itemId(stacks[0]);
                    if (stacks.length > 1) {
                        id += " (+" + (stacks.length - 1) + " alts)";
                    }
                    inputs.add(id);
                }
                row(out, String.valueOf(name),
                        itemId(output) + " x" + output.getCount(),
                        String.join("; ", inputs),
                        recipe.getClass().getSimpleName());
                count++;
            }
        }
        return count;
    }

    private static int exportGtRecipes(File file) throws IOException {
        int count = 0;
        List<Field> maps = new ArrayList<>();
        for (Field field : RecipeMaps.class.getFields()) {
            if (Modifier.isStatic(field.getModifiers()) && RecipeMap.class.isAssignableFrom(field.getType())) {
                maps.add(field);
            }
        }
        maps.sort(Comparator.comparing(Field::getName));
        try (Writer out = writer(file)) {
            row(out, "map", "index", "inputs", "fluid_inputs", "outputs",
                    "fluid_outputs", "chanced_outputs", "duration", "eut", "hidden");
            for (Field field : maps) {
                RecipeMap<?> map = (RecipeMap<?>) field.get(null);
                if (map == null) {
                    continue;
                }
                int index = 0;
                for (Recipe recipe : map.getRecipeList()) {
                    row(out, field.getName(), index++,
                            countable(recipe.getInputs()),
                            fluids(recipe.getFluidInputs()),
                            items(recipe.getOutputs()),
                            fluids(recipe.getFluidOutputs()),
                            chanced(recipe.getChancedOutputs()),
                            recipe.getDuration(), recipe.getEUt(), recipe.isHidden());
                    count++;
                }
            }
        } catch (ReflectiveOperationException e) {
            throw new IOException("cannot read RecipeMaps", e);
        }
        return count;
    }

    private static int exportNcoRecipes(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "handler", "index", "item_inputs", "fluid_inputs",
                    "item_outputs", "fluid_outputs", "extras");
            for (BasicRecipeHandler handler : NCRecipes.getHandlers()) {
                int index = 0;
                for (BasicRecipe recipe : handler.getRecipeList()) {
                    row(out, handler.getName(), index++,
                            ncoItems(recipe.getItemIngredients(), false),
                            ncoFluids(recipe.getFluidIngredients()),
                            ncoItems(recipe.getItemProducts(), true),
                            ncoFluids(recipe.getFluidProducts()),
                            String.valueOf(recipe.getExtras()));
                    count++;
                }
            }
        }
        return count;
    }

    private static int exportQmdRecipes(File file) throws IOException {
        int count = 0;
        try (Writer out = writer(file)) {
            row(out, "handler", "index", "item_inputs", "fluid_inputs", "particle_inputs",
                    "item_outputs", "fluid_outputs", "particle_outputs", "extras");
            for (QMDRecipeHandler handler : QMDRecipes.getHandlers()) {
                int index = 0;
                for (QMDRecipe recipe : handler.getRecipeList()) {
                    row(out, handler.getName(), index++,
                            ncoItems(recipe.getItemIngredients(), false),
                            ncoFluids(recipe.getFluidIngredients()),
                            particles(recipe.getParticleIngredients()),
                            ncoItems(recipe.getItemProducts(), true),
                            ncoFluids(recipe.getFluidProducts()),
                            particles(recipe.getParticleProducts()),
                            String.valueOf(recipe.getExtras()));
                    count++;
                }
            }
        }
        if (Loader.isModLoaded("qmd")) {
            try (Writer out = writer(new File(file.getParentFile(), "qmd-basic-recipes.csv"))) {
                row(out, "handler", "index", "item_inputs", "fluid_inputs",
                        "item_outputs", "fluid_outputs", "extras");
                for (BasicRecipeHandler handler : QMDRecipes.getBasicHandlers()) {
                    int index = 0;
                    for (BasicRecipe recipe : handler.getRecipeList()) {
                        row(out, handler.getName(), index++,
                                ncoItems(recipe.getItemIngredients(), false),
                                ncoFluids(recipe.getFluidIngredients()),
                                ncoItems(recipe.getItemProducts(), true),
                                ncoFluids(recipe.getFluidProducts()),
                                String.valueOf(recipe.getExtras()));
                        count++;
                    }
                }
            }
        }
        return count;
    }

    private static String countable(List<CountableIngredient> ingredients) {
        List<String> parts = new ArrayList<>();
        for (CountableIngredient ingredient : ingredients) {
            ItemStack[] stacks = ingredient.getIngredient().getMatchingStacks();
            if (stacks.length == 0) {
                parts.add("? x" + ingredient.getCount());
            } else {
                parts.add(itemId(stacks[0]) + " x" + ingredient.getCount()
                        + (stacks.length > 1 ? " (" + stacks.length + " alts)" : ""));
            }
        }
        return String.join("; ", parts);
    }

    private static String items(Iterable<ItemStack> stacks) {
        List<String> parts = new ArrayList<>();
        for (ItemStack stack : stacks) {
            if (!stack.isEmpty()) {
                parts.add(itemId(stack) + " x" + stack.getCount());
            }
        }
        return String.join("; ", parts);
    }

    private static String fluids(Iterable<FluidStack> stacks) {
        List<String> parts = new ArrayList<>();
        for (FluidStack stack : stacks) {
            if (stack != null && stack.amount > 0) {
                parts.add(stack.getFluid().getName() + " x" + stack.amount);
            }
        }
        return String.join("; ", parts);
    }

    private static String chanced(Iterable<Recipe.ChanceEntry> entries) {
        List<String> parts = new ArrayList<>();
        for (Recipe.ChanceEntry entry : entries) {
            parts.add(itemId(entry.getItemStack()) + " x" + entry.getItemStack().getCount()
                    + " @" + entry.getChance() + "%+" + entry.getBoostPerTier());
        }
        return String.join("; ", parts);
    }

    private static String ncoItems(Iterable<IItemIngredient> ingredients, boolean output) {
        List<String> parts = new ArrayList<>();
        for (IItemIngredient ingredient : ingredients) {
            if (ingredient == null) {
                continue;
            }
            if (ingredient instanceof OreIngredient) {
                OreIngredient ore = (OreIngredient) ingredient;
                parts.add(ore.oreName + " x" + ore.stackSize);
                continue;
            }
            if (ingredient instanceof ChanceItemIngredient) {
                ChanceItemIngredient chance = (ChanceItemIngredient) ingredient;
                Object raw = chance.getRawIngredient().getStack();
                if (raw instanceof ItemStack && !((ItemStack) raw).isEmpty()) {
                    parts.add(itemId((ItemStack) raw) + " x" + ((ItemStack) raw).getCount()
                            + " @" + chance.getChancePercent() + "%");
                }
                continue;
            }
            Object raw = ingredient.getStack();
            if (raw instanceof ItemStack && !((ItemStack) raw).isEmpty()) {
                parts.add(itemId((ItemStack) raw) + " x" + ((ItemStack) raw).getCount());
            }
        }
        return String.join("; ", parts);
    }

    private static String ncoFluids(Iterable<IFluidIngredient> ingredients) {
        List<String> parts = new ArrayList<>();
        for (IFluidIngredient ingredient : ingredients) {
            if (ingredient == null) {
                continue;
            }
            if (ingredient instanceof ChanceFluidIngredient) {
                ingredient = ((ChanceFluidIngredient) ingredient).getRawIngredient();
            }
            Object raw = ingredient.getStack();
            if (raw instanceof FluidStack && ((FluidStack) raw).amount > 0) {
                parts.add(((FluidStack) raw).getFluid().getName() + " x" + ((FluidStack) raw).amount);
            }
        }
        return String.join("; ", parts);
    }

    private static String particles(Iterable<IParticleIngredient> ingredients) {
        List<String> parts = new ArrayList<>();
        for (IParticleIngredient ingredient : ingredients) {
            if (ingredient == null) {
                continue;
            }
            Object raw = ingredient.getStack();
            if (raw instanceof ParticleStack) {
                ParticleStack stack = (ParticleStack) raw;
                parts.add(stack.getParticle().getName() + " x" + stack.getAmount()
                        + " E=" + stack.getMeanEnergy() + " F=" + stack.getFocus());
            }
        }
        return String.join("; ", parts);
    }

    private static String itemId(ItemStack stack) {
        return String.valueOf(stack.getItem().getRegistryName()) + ":" + stack.getMetadata();
    }

    private static String display(ItemStack stack) {
        try {
            return stack.getDisplayName();
        } catch (Throwable ignored) {
            return stack.getUnlocalizedName();
        }
    }

    private static String oreNames(ItemStack stack) {
        List<String> names = new ArrayList<>();
        for (int id : OreDictionary.getOreIDs(stack)) {
            names.add(OreDictionary.getOreName(id));
        }
        return String.join("|", names);
    }

    private static Writer writer(File file) throws IOException {
        return new OutputStreamWriter(new FileOutputStream(file), StandardCharsets.UTF_8);
    }

    private static void row(Writer out, Object... values) throws IOException {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) {
                out.write(',');
            }
            out.write(quote(values[i]));
        }
        out.write('\n');
    }

    private static String quote(Object value) {
        String text = value == null ? "" : String.valueOf(value);
        return '"' + text.replace("\"", "\"\"") + '"';
    }
}
