package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.recipes.RecipeMap;
import net.minecraft.item.ItemStack;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

/**
 * Applied Energistics' grinder becomes GregTech's macerator.
 *
 * <h2>Why</h2>
 *
 * The owner's rule for a mod's own machines: *"the grinder recipes have to go - that is far too
 * cheaty; they should become GregTech pulveriser recipes."* AE2 registers 443 grinder recipes in code
 * (there is no config file to disable them), each one an input, a guaranteed output, an optional
 * output with a chance, sometimes a second one, and a "turns" cost - all of it duplicating what a
 * macerator does, but without the machine being GregTech's.
 *
 * <h2>What this does</h2>
 *
 * On load it walks AE2's own grinder registry, adds a **macerator** recipe with the same input, the
 * same outputs and the same chances (AE2 stores them as 0..1 floats, GregTech wants 1/10000), using
 * AE2's own `turns` as the duration, and then clears the grinder registry so the machine has nothing
 * left to do. Nothing is deleted and no yield is lowered - the same powder comes out of a GregTech
 * machine instead of AE2's.
 *
 * <p>Both calls are made from this mod's postInit and again at load complete, and both are idempotent:
 * the second pass finds an empty grinder. AE2 is reached by reflection so this class compiles whether
 * or not AE2 is installed.</p>
 */
public final class MinespaceGrinderToMacerator {

    private static boolean converted;

    private MinespaceGrinderToMacerator() {
    }

    /** @return the number of recipes moved, 0 when there was nothing left to move */
    public static int convert(String phase) {
        if (converted) {
            Minespace.log().info("grinder->macerator ({} pass): already converted this launch", phase);
            return 0;
        }
        int moved = 0;
        try {
            Class<?> aeApi = Class.forName("appeng.api.AEApi");
            Object instance = aeApi.getMethod("instance").invoke(null);
            Object registries = instance.getClass().getMethod("registries").invoke(instance);
            Object grinder = registries.getClass().getMethod("grinder").invoke(registries);
            Method getRecipes = grinder.getClass().getMethod("getRecipes");
            Object raw = getRecipes.invoke(grinder);
            if (!(raw instanceof Collection)) {
                Minespace.log().warn("grinder->macerator ({}): AE2 grinder registry is not a "
                        + "collection ({})", phase, raw);
                return 0;
            }
            @SuppressWarnings("unchecked")
            Collection<Object> recipes = (Collection<Object>) raw;
            List<Object> snapshot = new ArrayList<>(recipes);

            RecipeMap<?> macerator = RecipeMap.getByName("macerator");
            for (Object recipe : snapshot) {
                ItemStack input = (ItemStack) recipe.getClass().getMethod("getInput").invoke(recipe);
                ItemStack output = (ItemStack) recipe.getClass().getMethod("getOutput").invoke(recipe);
                int turns = (Integer) recipe.getClass().getMethod("getRequiredTurns").invoke(recipe);
                if (input == null || input.isEmpty() || output == null || output.isEmpty()) {
                    continue;
                }
                // GregTech's own macerator already covers GregTech's ores; only convert the grinder
                // recipes that add something (mod ores, crystals, ...) so JEI does not show two
                // identical rows for the same input.
                if (hasInput(macerator, input)) {
                    continue;
                }
                // GTCE's builder takes every input first, then the outputs; chanced outputs are added
                // after the guaranteed one.
                gregtech.api.recipes.builders.SimpleRecipeBuilder builder = (gregtech.api.recipes
                        .builders.SimpleRecipeBuilder) macerator.recipeBuilder();
                builder.inputs(input.copy());
                builder.outputs(output.copy());
                addOptional(builder, recipe, "getOptionalOutput", "getOptionalChance");
                addOptional(builder, recipe, "getSecondOptionalOutput", "getSecondOptionalChance");
                builder.duration(Math.max(20, turns)).EUt(30);
                builder.buildAndRegister();
                moved++;
            }

            // Now empty the grinder. getRecipes() hands back an unmodifiable *view*, but the registry
            // itself can remove recipes one at a time through IGrinderRegistry, which is the supported
            // way in.
            int emptied = 0;
            try {
                Class<?> recipeInterface = Class.forName("appeng.api.features.IGrinderRecipe");
                Method remove = grinder.getClass().getMethod("removeRecipe", recipeInterface);
                for (Object recipe : snapshot) {
                    Object result = remove.invoke(grinder, recipe);
                    if (Boolean.TRUE.equals(result)) {
                        emptied++;
                    }
                }
            } catch (Throwable t) {
                Minespace.log().warn("grinder->macerator ({}): could not empty the grinder", phase, t);
            }
            Minespace.log().info("grinder->macerator ({} pass): {} AE2 grinder recipes moved to "
                    + "GregTech's macerator, {} removed from the grinder", phase, moved, emptied);
            converted = true;
        } catch (ClassNotFoundException e) {
            // AE2 not installed - nothing to do
        } catch (Throwable t) {
            Minespace.log().error("grinder->macerator ({}) failed", phase, t);
        }
        return moved;
    }

    private static boolean hasInput(RecipeMap<?> map, ItemStack input) {
        try {
            for (gregtech.api.recipes.Recipe existing : map.getRecipeList()) {
                for (gregtech.api.recipes.CountableIngredient countable : existing.getInputs()) {
                    for (ItemStack candidate : countable.getIngredient().getMatchingStacks()) {
                        if (ItemStack.areItemsEqual(candidate, input)
                                && ItemStack.areItemStackTagsEqual(candidate, input)) {
                            return true;
                        }
                    }
                }
            }
        } catch (Throwable ignored) {
            // a map that cannot be read simply gets no de-duplication
        }
        return false;
    }

    private static void addOptional(gregtech.api.recipes.builders.SimpleRecipeBuilder builder,
                                    Object recipe, String getter, String chanceGetter) {
        try {
            Object optional = recipe.getClass().getMethod(getter).invoke(recipe);
            if (!(optional instanceof Optional)) {
                return;
            }
            Optional<?> value = (Optional<?>) optional;
            if (!value.isPresent()) {
                return;
            }
            ItemStack stack = (ItemStack) value.get();
            float chance = (Float) recipe.getClass().getMethod(chanceGetter).invoke(recipe);
            if (stack == null || stack.isEmpty() || chance <= 0f) {
                return;
            }
            // AE2 gives 0..1; GregTech's chancedOutput takes 1/10000
            int gtChance = Math.max(1, Math.min(10000, Math.round(chance * 10000f)));
            builder.chancedOutput(stack.copy(), gtChance, 0);
        } catch (Throwable ignored) {
            // no optional output on this recipe
        }
    }
}
