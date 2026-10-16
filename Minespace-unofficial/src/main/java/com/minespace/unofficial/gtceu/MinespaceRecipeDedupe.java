package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.recipes.CountableIngredient;
import gregtech.api.recipes.Recipe;
import gregtech.api.recipes.RecipeMap;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fluids.FluidStack;
import net.minecraftforge.fml.common.registry.ForgeRegistries;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * A GregTech machine does not have slots, so it does not have an order either.
 *
 * <h2>The problem</h2>
 *
 * Moves into the assembler were made from crafting-table grids, and a grid is order-sensitive while a
 * machine is not: Galacticraft registers the beam reflector twice (the lever in either of two cells)
 * and the rocket engine twice (the flint and steel and the stone button swapped), and both shapes were
 * written out as their own assembler recipe. The machine cannot tell them apart - it matches the input
 * bus, not a pattern - so what a player sees is the same recipe listed twice in JEI, and the map holds
 * two entries for one job. The owner's report: *"some items in the assembler are recipes moved straight
 * over from the crafting table - they should be merged; the assembler has no need for material
 * order."*
 *
 * <h2>What this does</h2>
 *
 * Every recipe map is walked, and two recipes are treated as the same recipe when <em>everything the
 * machine can see</em> matches once the inputs are sorted instead of ordered:
 *
 * <ul>
 *   <li>the item inputs (each ingredient by the sorted list of the stacks it accepts, plus its count -
 *       so the integrated circuit, which is one of those inputs, keeps recipes apart, and two ore
 *       dictionary names holding the same item really are the same recipe);</li>
 *   <li>the fluid inputs <em>and fluid outputs</em>, the item outputs, and the chanced outputs (chance
 *       and boost included). The fluid outputs matter: a distillation recipe and its neighbour can
 *       share an input and still produce a different fluid, and those are two different recipes.</li>
 * </ul>
 *
 * Duration and EU/t are deliberately *not* part of that signature: the machine takes the first match
 * in the list either way, so removing the later one changes nothing about what a player gets back.
 *
 * <p>When a group has both a hidden and a visible recipe, the visible one is the one kept, so nothing
 * disappears from JEI. Runs once from {@code FMLLoadCompleteEvent}, after every mod has registered its
 * recipes, and is idempotent.</p>
 */
public final class MinespaceRecipeDedupe {

    /** How many individual merges to describe in the log; the counts are always complete. */
    private static final int SAMPLES = 20;

    private MinespaceRecipeDedupe() {
    }

    /**
     * Deletes every machine recipe that is a repeat of an earlier one once the input order is ignored.
     *
     * @return the number of recipes deleted by this call
     */
    public static int removeOrderDuplicates(String phase) {
        int removed = 0;
        int samples = 0;
        Map<String, Integer> perMap = new LinkedHashMap<>();
        for (RecipeMap<?> map : RecipeMap.getRecipeMaps()) {
            Map<String, Recipe> keptBySignature = new HashMap<>();
            List<Recipe> victims = new ArrayList<>();
            for (Recipe recipe : map.getRecipeList()) {
                String signature = signature(recipe);
                Recipe kept = keptBySignature.get(signature);
                if (kept == null) {
                    keptBySignature.put(signature, recipe);
                    continue;
                }
                // Prefer the visible recipe: a hidden one is an alias, and hiding a working recipe from
                // JEI by deleting its visible twin would be the wrong way round.
                if (kept.isHidden() && !recipe.isHidden()) {
                    keptBySignature.put(signature, recipe);
                    victims.add(kept);
                } else {
                    victims.add(recipe);
                }
            }
            for (Recipe victim : victims) {
                try {
                    if (map.removeRecipe(victim)) {
                        removed++;
                        perMap.merge(map.getUnlocalizedName(), 1, Integer::sum);
                        if (samples < SAMPLES) {
                            samples++;
                            Minespace.log().info("duplicate recipe merge: {} {} -> {}",
                                    map.getUnlocalizedName(), describeInputs(victim),
                                    describeOutputs(victim));
                        }
                    }
                } catch (Throwable t) {
                    Minespace.log().warn("could not remove a duplicate recipe from {}",
                            map.getUnlocalizedName(), t);
                }
            }
        }
        Minespace.log().info("recipe de-duplication ({} pass): {} recipes removed as input-order "
                + "duplicates; by map: {}", phase, removed, perMap);
        return removed;
    }

    /** Everything the machine can see, with the inputs sorted instead of ordered. */
    private static String signature(Recipe recipe) {
        List<String> parts = new ArrayList<>();
        for (CountableIngredient input : recipe.getInputs()) {
            parts.add("in:" + input.getCount() + ':' + acceptedStacks(input));
        }
        for (FluidStack fluid : recipe.getFluidInputs()) {
            parts.add("fluid:" + fluid.amount + ':'
                    + (fluid.getFluid() == null ? "<none>" : fluid.getFluid().getName()));
        }
        for (FluidStack fluid : recipe.getFluidOutputs()) {
            parts.add("fluidOut:" + fluid.amount + ':'
                    + (fluid.getFluid() == null ? "<none>" : fluid.getFluid().getName()));
        }
        for (ItemStack output : recipe.getOutputs()) {
            parts.add("out:" + output.getCount() + ':' + idOf(output));
        }
        for (Recipe.ChanceEntry entry : recipe.getChancedOutputs()) {
            parts.add("chance:" + entry.getChance() + ':' + entry.getBoostPerTier() + ':'
                    + idOf(entry.getItemStack()));
        }
        Collections.sort(parts);
        return String.join("|", parts);
    }

    private static String acceptedStacks(CountableIngredient input) {
        List<String> ids = new ArrayList<>();
        for (ItemStack stack : input.getIngredient().getMatchingStacks()) {
            ids.add(idOf(stack));
        }
        Collections.sort(ids);
        return String.join(",", ids);
    }

    private static String describeInputs(Recipe recipe) {
        List<String> parts = new ArrayList<>();
        for (CountableIngredient input : recipe.getInputs()) {
            parts.add(input.getCount() + "x" + acceptedStacks(input));
        }
        Collections.sort(parts);
        return String.join(" + ", parts);
    }

    private static String describeOutputs(Recipe recipe) {
        List<String> parts = new ArrayList<>();
        for (ItemStack output : recipe.getOutputs()) {
            parts.add(output.getCount() + "x" + idOf(output));
        }
        for (FluidStack fluid : recipe.getFluidOutputs()) {
            parts.add(fluid.amount + "mB "
                    + (fluid.getFluid() == null ? "<none>" : fluid.getFluid().getName()));
        }
        return String.join(" + ", parts);
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
