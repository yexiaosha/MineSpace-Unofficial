package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import net.minecraft.item.ItemStack;
import net.minecraft.util.NonNullList;
import net.minecraftforge.oredict.OreDictionary;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Forestry's electron tubes stop being a Forestry-only job: every tube recipe in the Thermionic
 * Fabricator gains GregTech items.
 *
 * <h2>Why this is Java</h2>
 *
 * The owner's rule for Forestry: *items a Forestry machine makes are to be made more complex, with
 * GregTech items put into them*. The electron tubes are the clearest case - they are made only in the
 * Thermionic Fabricator, and that machine's recipes live in Forestry's own recipe manager rather than
 * in a data file.
 *
 * <p>ModTweaker could reach the manager, but its fabricator API works off the recipe's *plan* (its
 * cast), and a probe of the live registry shows every tube recipe has an **empty plan** - there is
 * nothing for `removeCast` to match on. The registered recipes are therefore rewritten here, through
 * Forestry's own `FabricatorRecipeManager`, which exposes `recipes()`, `removeRecipe` and `addRecipe`
 * for exactly this purpose.</p>
 *
 * <h2>What changes</h2>
 *
 * Each tube recipe keeps its plan, its molten glass, its output and its whole grid, and gains two
 * GregTech items in the two cells the 3x3 pattern already leaves empty: a **fine wire** - matched to
 * the tube's own metal where that metal is a GregTech material, copper otherwise - and an **iron
 * screw**. Both have to come out of a GregTech machine, and neither is free: nothing is dropped and no
 * count is lowered.
 *
 * <p>Nothing here is guessed: the grid, the output and the empty cells were read out of the live
 * registry by {@code MinespaceForestryProbe} before this class was written.</p>
 */
public final class MinespaceForestryTubes {

    /** Fine wires that are certain to exist, in the order they are tried. */
    private static final String[] WIRE_FALLBACKS = {"wireFineCopper", "wireFineTin", "wireFineIron",
            "wireFineGold", "wireFineBronze"};

    private static final String SCREW = "screwIron";

    private static boolean converted;

    private MinespaceForestryTubes() {
    }

    /** @return the number of recipes rewritten, 0 when there was nothing left to do */
    public static int convert(String phase) {
        if (converted) {
            return 0;
        }
        int changed = 0;
        try {
            Class<?> managers = Class.forName("forestry.api.recipes.RecipeManagers");
            Object manager = managers.getField("fabricatorManager").get(null);
            Class<?> recipeInterface = Class.forName("forestry.api.recipes.IFabricatorRecipe");
            Class<?> recipeClass = Class.forName("forestry.factory.recipes.FabricatorRecipe");

            Method remove = manager.getClass().getMethod("removeRecipe", recipeInterface);
            Method add = manager.getClass().getMethod("addRecipe", recipeInterface);
            Constructor<?> ctor = recipeClass.getConstructor(ItemStack.class,
                    net.minecraftforge.fluids.FluidStack.class, ItemStack.class, NonNullList.class,
                    NonNullList.class, int.class, int.class);

            Collection<?> recipes = (Collection<?>) manager.getClass().getMethod("recipes")
                    .invoke(manager);
            Minespace.log().info("forestry tubes ({} pass): {} fabricator recipes visible, manager {}",
                    phase, recipes.size(), manager.getClass().getName());
            List<Object> old = new ArrayList<>();
            List<Object> replacement = new ArrayList<>();
            int named = 0;
            for (Object recipe : new ArrayList<>(recipes)) {
                ItemStack output = (ItemStack) recipe.getClass().getMethod("getRecipeOutput")
                        .invoke(recipe);
                if (output.isEmpty()) {
                    continue;
                }
                if (!"forestry:thermionic_tubes".equals(String.valueOf(
                        output.getItem().getRegistryName()))) {
                    continue;
                }
                named++;
                NonNullList<NonNullList<ItemStack>> grid =
                        (NonNullList<NonNullList<ItemStack>>) recipe.getClass()
                                .getMethod("getIngredients").invoke(recipe);
                NonNullList<NonNullList<ItemStack>> newGrid = copy(grid);
                ItemStack wire = stack(wireFor(newGrid));
                ItemStack screw = stack(SCREW);
                if (wire.isEmpty() || screw.isEmpty()) {
                    Minespace.log().warn("forestry tubes ({}): no GT wire/screw available, {} left alone",
                            phase, output.getDisplayName());
                    continue;
                }
                int empty = fill(newGrid, wire);
                empty = fill(newGrid, screw);
                if (empty < 0) {
                    continue;
                }
                Object rebuilt = ctor.newInstance(
                        recipe.getClass().getMethod("getPlan").invoke(recipe),
                        recipe.getClass().getMethod("getLiquid").invoke(recipe),
                        output.copy(),
                        newGrid,
                        recipe.getClass().getMethod("getOreDicts").invoke(recipe),
                        recipe.getClass().getMethod("getWidth").invoke(recipe),
                        recipe.getClass().getMethod("getHeight").invoke(recipe));
                old.add(recipe);
                replacement.add(rebuilt);
            }
            for (Object recipe : old) {
                remove.invoke(manager, recipe);
            }
            for (Object recipe : replacement) {
                add.invoke(manager, recipe);
            }
            changed = replacement.size();
            converted = true;
            Minespace.log().info("forestry tubes ({} pass): {} of {} tube recipes rewritten ({} named)",
                    phase, changed, recipes.size(), named);
        } catch (ClassNotFoundException e) {
            // Forestry not installed - nothing to do
        } catch (Throwable t) {
            Minespace.log().error("forestry tubes ({}) failed", phase, t);
        }
        return changed;
    }

    private static NonNullList<NonNullList<ItemStack>> copy(NonNullList<NonNullList<ItemStack>> grid) {
        NonNullList<NonNullList<ItemStack>> copy = NonNullList.create();
        for (NonNullList<ItemStack> slot : grid) {
            NonNullList<ItemStack> newSlot = NonNullList.create();
            for (ItemStack alternative : slot) {
                newSlot.add(alternative == null ? ItemStack.EMPTY : alternative.copy());
            }
            copy.add(newSlot);
        }
        return copy;
    }

    /**
     * Puts a stack in the first empty slot.
     *
     * <p>The list Forestry hands back is the nine cells of the 3x3 pattern, and each entry is that
     * cell's list of accepted alternatives - an empty cell is a list with no alternatives in it, not a
     * cell holding an empty stack. That distinction is what the first version of this class got wrong:
     * it looked for an empty <em>stack</em>, found none, and quietly rewrote nothing.</p>
     *
     * @return the slot used, or -1 when the pattern is full
     */
    private static int fill(NonNullList<NonNullList<ItemStack>> grid, ItemStack stack) {
        for (int slot = 0; slot < grid.size(); slot++) {
            NonNullList<ItemStack> alternatives = grid.get(slot);
            if (alternatives.isEmpty()) {
                NonNullList<ItemStack> filled = NonNullList.create();
                filled.add(stack.copy());
                grid.set(slot, filled);
                return slot;
            }
        }
        return -1;
    }

    /** The fine wire of the tube's own metal when the grid names a GregTech ingot, copper otherwise. */
    private static String wireFor(NonNullList<NonNullList<ItemStack>> grid) {
        for (NonNullList<ItemStack> alternatives : grid) {
            for (ItemStack cell : alternatives) {
                for (int id : OreDictionary.getOreIDs(cell)) {
                    String name = OreDictionary.getOreName(id);
                    if (name != null && name.startsWith("ingot")) {
                        String candidate = "wireFine" + name.substring("ingot".length());
                        if (!OreDictionary.getOres(candidate, false).isEmpty()) {
                            return candidate;
                        }
                    }
                }
            }
        }
        for (String fallback : WIRE_FALLBACKS) {
            if (!OreDictionary.getOres(fallback, false).isEmpty()) {
                return fallback;
            }
        }
        return WIRE_FALLBACKS[0];
    }

    private static ItemStack stack(String oreName) {
        List<ItemStack> ores = OreDictionary.getOres(oreName, false);
        return ores.isEmpty() ? ItemStack.EMPTY : ores.get(0).copy();
    }
}
