package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.Ingredient;
import net.minecraft.util.NonNullList;
import net.minecraftforge.oredict.OreDictionary;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * Forestry's Carpenter: the chipsets and the scented paneling take GregTech parts.
 *
 * <h2>The owner's rule</h2>
 *
 * *"Items a Forestry machine makes should be made more complex, with GregTech items put into them."*
 * A probe of the live registry (see {@link MinespaceForestryTubes}) shows the Carpenter makes 209
 * recipes, and almost all of them are things this rule has no business touching - crates (packaging),
 * comb and fruit conversions, stone, saplings, log peeling. The exceptions are Forestry's own machine
 * parts: the four **chipsets** (the circuit boards every Forestry machine eats - eight redstone and one
 * metal ingot) and the **scented paneling** (`crafting_material:6`, royal jelly + planks + beeswax +
 * pollen).
 *
 * <h2>What changes</h2>
 *
 * <ul>
 *   <li>the chipset's metal **ingot becomes a GregTech plate** of the same metal - the same amount of
 *       metal, but it has to come off a bending machine;</li>
 *   <li>one of the chipset's eight redstone becomes a **GregTech steel screw**. This is the one place in
 *       the migration where an ingredient is *replaced* rather than added, and it is deliberate: the
 *       chipset grids are completely full, so there is nowhere to put a screw, and a single redstone is
 *       as close to free as an item gets - swapping it for a lathe product can only make the recipe
 *       dearer. The number of ingredients is unchanged;</li>
 *   <li>the scented paneling has two empty cells, so it simply gains a **GregTech steel screw**.</li>
 * </ul>
 *
 * <h2>Why the recipe is edited in place</h2>
 *
 * The first three attempts rebuilt the recipe through {@code ShapedRecipeCustom}, and Forge's
 * {@code CraftingHelper.parseShaped} rejected the pattern every time - first because a "cell" Forestry
 * leaves empty turned out to be a list holding one <em>empty stack</em> (which is illegal in a shaped
 * pattern), then because the pattern had a trailing space, then with a fully trimmed pattern and
 * {@code Ingredient} values. Rebuilding was the wrong idea: the recipe's own ingredients are perfectly
 * good, so this class reaches into {@code ShapedOreRecipe}'s private {@code input} list and replaces
 * only the one or two cells that change. Nothing else about the recipe - the Carpenter's water, its
 * box, its packaging time, the other seven cells, every alternative in them - is touched.
 *
 * <p>Reached by reflection so this mod does not need Forestry at compile time.</p>
 */
public final class MinespaceForestryCarpenter {

    private static final String CHIPSET = "forestry:chipsets";
    private static final String PANELING = "forestry:crafting_material";
    private static final int PANELING_META = 6;
    private static final String SCREW = "screwIron";

    private static boolean converted;

    private MinespaceForestryCarpenter() {
    }

    /** @return the number of recipes rewritten, 0 when there was nothing left to do */
    public static int convert(String phase) {
        if (converted) {
            return 0;
        }
        int chipsets = 0;
        int panels = 0;
        try {
            Class<?> managers = Class.forName("forestry.api.recipes.RecipeManagers");
            Object manager = managers.getField("carpenterManager").get(null);

            ItemStack screw = stack(SCREW);
            if (screw.isEmpty()) {
                Minespace.log().warn("forestry carpenter ({}): no {} in the ore dictionary",
                        phase, SCREW);
                return 0;
            }

            Collection<?> recipes = (Collection<?>) manager.getClass().getMethod("recipes")
                    .invoke(manager);
            for (Object recipe : new ArrayList<>(recipes)) {
                Object gridRecipe = recipe.getClass().getMethod("getCraftingGridRecipe").invoke(recipe);
                if (gridRecipe == null) {
                    continue;
                }
                ItemStack output = (ItemStack) gridRecipe.getClass().getMethod("getOutput")
                        .invoke(gridRecipe);
                if (output.isEmpty()) {
                    continue;
                }
                String name = String.valueOf(output.getItem().getRegistryName());
                boolean isChipset = CHIPSET.equals(name);
                boolean isPanel = PANELING.equals(name) && output.getMetadata() == PANELING_META;
                if (!isChipset && !isPanel) {
                    continue;
                }
                NonNullList<NonNullList<ItemStack>> grid =
                        (NonNullList<NonNullList<ItemStack>>) gridRecipe.getClass()
                                .getMethod("getRawIngredients").invoke(gridRecipe);
                Object ingredients = inputOf(gridRecipe);
                if (ingredients == null) {
                    Minespace.log().warn("forestry carpenter ({}): cannot reach the ingredients of {}, "
                            + "left alone", phase, output.getDisplayName());
                    continue;
                }
                if (isChipset) {
                    int metalSlot = slotOf(grid, true);
                    int redstoneSlot = slotOf(grid, false);
                    if (metalSlot < 0 || redstoneSlot < 0
                            || !setIngredient(ingredients, metalSlot, plateOf(grid, metalSlot))
                            || !setIngredient(ingredients, redstoneSlot, screw)) {
                        Minespace.log().warn("forestry carpenter ({}): chipset {} did not look like a "
                                + "chipset, left alone", phase, output.getMetadata());
                        continue;
                    }
                    chipsets++;
                } else {
                    int free = freeSlot(grid);
                    if (free < 0 || !setIngredient(ingredients, free, screw)) {
                        continue;
                    }
                    panels++;
                }
            }
            converted = true;
            Minespace.log().info("forestry carpenter ({} pass): {} recipes rewritten - {} chipsets "
                    + "(GT plate + steel screw) and {} scented paneling (steel screw)",
                    phase, chipsets + panels, chipsets, panels);
        } catch (ClassNotFoundException e) {
            // Forestry not installed - nothing to do
        } catch (Throwable t) {
            Minespace.log().error("forestry carpenter ({}) failed", phase, t);
        }
        return chipsets + panels;
    }

    /** The cell holding a GregTech metal ingot (forMetal) or a redstone; -1 when there is none. */
    private static int slotOf(NonNullList<NonNullList<ItemStack>> grid, boolean forMetal) {
        for (int slot = 0; slot < grid.size(); slot++) {
            for (ItemStack candidate : grid.get(slot)) {
                for (int id : OreDictionary.getOreIDs(candidate)) {
                    String oreName = OreDictionary.getOreName(id);
                    if (oreName == null) {
                        continue;
                    }
                    if (forMetal && oreName.startsWith("ingot")) {
                        return slot;
                    }
                    if (!forMetal && "dustRedstone".equals(oreName)) {
                        return slot;
                    }
                }
            }
        }
        return -1;
    }

    /** The first cell with no alternatives at all. */
    private static int freeSlot(NonNullList<NonNullList<ItemStack>> grid) {
        for (int slot = 0; slot < grid.size(); slot++) {
            if (grid.get(slot).isEmpty()) {
                return slot;
            }
        }
        return -1;
    }

    /** The GregTech plate of the metal sitting in the given cell, or an empty stack. */
    private static ItemStack plateOf(NonNullList<NonNullList<ItemStack>> grid, int slot) {
        if (slot < 0) {
            return ItemStack.EMPTY;
        }
        for (ItemStack candidate : grid.get(slot)) {
            for (int id : OreDictionary.getOreIDs(candidate)) {
                String oreName = OreDictionary.getOreName(id);
                if (oreName != null && oreName.startsWith("ingot")) {
                    List<ItemStack> plate = OreDictionary.getOres(
                            "plate" + oreName.substring("ingot".length()), false);
                    if (!plate.isEmpty()) {
                        return plate.get(0).copy();
                    }
                }
            }
        }
        return ItemStack.EMPTY;
    }

    /**
     * The shaped recipe's own ingredient list, found reflectively.
     *
     * <p>{@code ShapedOreRecipe} keeps it in a private field called {@code input}. It is final, which is
     * fine: Java 8 lets a final instance field be written through reflection once it is accessible.</p>
     */
    private static Object inputOf(Object recipe) {
        for (Class<?> type = recipe.getClass(); type != null; type = type.getSuperclass()) {
            for (Field field : type.getDeclaredFields()) {
                if (!"input".equals(field.getName())) {
                    continue;
                }
                try {
                    field.setAccessible(true);
                    Object value = field.get(recipe);
                    if (value instanceof NonNullList || value instanceof Object[]) {
                        return value;
                    }
                } catch (Throwable ignored) {
                    // try the next one
                }
            }
        }
        return null;
    }

    /**
     * Replaces one cell's ingredient.
     *
     * <p>The list this writes into is Forestry's own {@code ShapedRecipeCustom.input}, and its cell
     * type is a {@code NonNullList<ItemStack>} - not a Forge {@code Ingredient}. Writing an
     * {@code Ingredient} there leaves the cell holding the wrong type, and
     * {@code ShapedRecipeCustom.checkMatch} (which reads that very list, not Forge's) compares cell
     * elements as stacks, so the recipe would throw when the Carpenter tried to match it.</p>
     *
     * <p>The cell is replaced by a <em>new</em> list rather than cleared and refilled: Forestry's
     * recipes share cell objects between recipes (the four chipsets share their redstone cells), so an
     * in-place edit would change every recipe using that cell - which is exactly how an earlier
     * version of this rewrite lost three of the four chipsets. A Forge ingredient list is still
     * handled, for the case of a recipe that hands us one.</p>
     */
    @SuppressWarnings("unchecked")
    private static boolean setIngredient(Object ingredients, int slot, ItemStack stacks) {
        if (stacks.isEmpty() || slot < 0 || !(ingredients instanceof NonNullList)) {
            return false;
        }
        try {
            Object cell = ((NonNullList<?>) ingredients).get(slot);
            if (cell instanceof NonNullList) {
                NonNullList<ItemStack> alternatives = NonNullList.create();
                alternatives.add(stacks.copy());
                ((NonNullList<Object>) ingredients).set(slot, alternatives);
                return true;
            }
            ((NonNullList<Ingredient>) ingredients).set(slot, Ingredient.fromStacks(stacks.copy()));
            return true;
        } catch (Throwable t) {
            Minespace.log().error("forestry carpenter: could not set ingredient {}", slot, t);
            return false;
        }
    }

    /**
     * Points Forestry's Carpenter recipes that hand out, or live on, an item this pack has given to
     * GregTech at GregTech's item.
     *
     * <h2>What it fixes</h2>
     *
     * <p>A mod's own machine registry is the one place none of the pack's other passes look, and the
     * Carpenter holds seven recipes that hand a retired item back out: the crate pairs for tin,
     * copper, bronze, apatite and ash ({@code forestry:crated.x -> x x9} and the filling recipe back)
     * and two "broken tool into ingots" recipes. They are not a way to get a retired item out of
     * nothing - a crate needs nine of the item to fill it and the broken tools cannot be made any
     * more - but they do make those items "produced by something", which is the rule
     * {@code jei_dupes.zs} hides them on, and they let an old crate turn GregTech's ingots back into
     * Forestry's. Re-pointing the output and the cells keeps the crate feature and stops producing
     * the retired copies.</p>
     *
     * @return the number of carpenter recipes changed by this call
     */
    public static int repointRetiredItems(String phase) {
        Map<String, ItemStack> targets = MinespaceMaterialRepoint.currentTargets();
        if (targets.isEmpty()) {
            return 0;
        }
        int repointed = 0;
        try {
            Class<?> managers = Class.forName("forestry.api.recipes.RecipeManagers");
            Object manager = managers.getField("carpenterManager").get(null);
            Collection<?> recipes = (Collection<?>) manager.getClass().getMethod("recipes")
                    .invoke(manager);
            for (Object recipe : new ArrayList<>(recipes)) {
                Object gridRecipe = recipe.getClass().getMethod("getCraftingGridRecipe")
                        .invoke(recipe);
                if (gridRecipe == null) {
                    continue;
                }
                boolean changed = false;
                ItemStack output = (ItemStack) gridRecipe.getClass().getMethod("getOutput")
                        .invoke(gridRecipe);
                ItemStack target = output.isEmpty() ? null : targets.get(idOf(output));
                if (target != null && !target.isEmpty()) {
                    changed = setOutput(gridRecipe, target.copy());
                }
                NonNullList<NonNullList<ItemStack>> grid =
                        (NonNullList<NonNullList<ItemStack>>) gridRecipe.getClass()
                                .getMethod("getRawIngredients").invoke(gridRecipe);
                for (int slot = 0; slot < grid.size(); slot++) {
                    NonNullList<ItemStack> cell = grid.get(slot);
                    if (cell.isEmpty()) {
                        continue;
                    }
                    ItemStack replacement = null;
                    boolean allRetired = true;
                    for (ItemStack candidate : cell) {
                        ItemStack candidateTarget = targets.get(idOf(candidate));
                        if (candidateTarget == null || candidateTarget.isEmpty()) {
                            allRetired = false;
                            break;
                        }
                        if (replacement == null) {
                            replacement = candidateTarget;
                        } else if (!ItemStack.areItemStacksEqual(replacement, candidateTarget)) {
                            allRetired = false;
                            break;
                        }
                    }
                    if (allRetired && replacement != null) {
                        // Replace the cell object, not its contents: Forestry shares cells between
                        // recipes and an in-place edit would change all of them.
                        NonNullList<ItemStack> fresh = NonNullList.create();
                        fresh.add(replacement.copy());
                        grid.set(slot, fresh);
                        changed = true;
                    }
                }
                if (changed) {
                    repointed++;
                    Minespace.log().info("forestry carpenter ({}): re-pointed a recipe making {}",
                            phase, idOf(output));
                }
            }
            Minespace.log().info("forestry carpenter ({} pass): {} recipes re-pointed at GregTech's "
                    + "item", phase, repointed);
        } catch (ClassNotFoundException e) {
            // Forestry not installed - nothing to do
        } catch (Throwable t) {
            Minespace.log().error("forestry carpenter ({}) re-point failed", phase, t);
        }
        return repointed;
    }

    /**
     * Replaces a shaped recipe's output.
     *
     * <p>Forge keeps it in a protected {@code ItemStack} field whose runtime name is obfuscated, so
     * the MCP name is looked up through {@code ObfuscationReflectionHelper}; if that ever fails, the
     * fallback finds the non-static {@code ItemStack} field in the recipe's hierarchy, which is the
     * same one.</p>
     */
    private static boolean setOutput(Object recipe, ItemStack output) {
        try {
            Field field = net.minecraftforge.fml.common.ObfuscationReflectionHelper
                    .findField(net.minecraftforge.oredict.ShapedOreRecipe.class, "output");
            field.setAccessible(true);
            field.set(recipe, output);
            return true;
        } catch (Throwable first) {
            for (Class<?> type = recipe.getClass(); type != null; type = type.getSuperclass()) {
                for (Field field : type.getDeclaredFields()) {
                    if (field.getType() != ItemStack.class
                            || java.lang.reflect.Modifier.isStatic(field.getModifiers())) {
                        continue;
                    }
                    try {
                        field.setAccessible(true);
                        field.set(recipe, output);
                        return true;
                    } catch (Throwable ignored) {
                        // try the next field
                    }
                }
            }
            Minespace.log().warn("forestry carpenter: could not set a recipe output", first);
            return false;
        }
    }

    private static String idOf(ItemStack stack) {
        if (stack == null || stack.isEmpty()) {
            return "-";
        }
        net.minecraft.util.ResourceLocation name =
                net.minecraftforge.fml.common.registry.ForgeRegistries.ITEMS.getKey(stack.getItem());
        return (name == null ? "<unknown>" : name.toString()) + ":" + stack.getMetadata();
    }

    /**
     * Removes the Squeezer's lava recipes.
     *
     * <h2>Why</h2>
     *
     * <p>Forestry's Squeezer ships four recipes that turn <em>two phosphor and one sand, dirt or
     * cobblestone</em> into 1,600 or 2,000 mB of lava. No GregTech route makes lava that cheap, and
     * lava is a GregTech fuel, so the pair is free EU with extra steps: apatite or GregTech's own
     * phosphor ore gives the phosphor, and a GregTech lava-fired generator turns the result into
     * power. This is the same line 6m draws for RF - the pack may *spend* power on a mod's machines,
     * it may not *make* power out of a mod's machine - and the four recipes are the only ones in the
     * Squeezer that produce a GregTech fuel.</p>
     *
     * <p>Everything else the Squeezer does is Forestry's own chain and stays: juice and seed oil out
     * of fruit, mulch, honey, ice, biomass, and the bee-comb rows that feed GregTech dusts.</p>
     *
     * @return the number of squeezer recipes removed by this call
     */
    public static int removeLavaSqueezing(String phase) {
        int removed = 0;
        try {
            Class<?> managers = Class.forName("forestry.api.recipes.RecipeManagers");
            Object manager = managers.getField("squeezerManager").get(null);
            Class<?> recipeInterface = Class.forName("forestry.api.recipes.ISqueezerRecipe");
            java.lang.reflect.Method remove = manager.getClass()
                    .getMethod("removeRecipe", recipeInterface);
            List<Object> victims = new ArrayList<>();
            Collection<?> recipes = (Collection<?>) manager.getClass().getMethod("recipes")
                    .invoke(manager);
            for (Object recipe : recipes) {
                Object fluid = recipe.getClass().getMethod("getFluidOutput").invoke(recipe);
                if (fluid instanceof net.minecraftforge.fluids.FluidStack
                        && ((net.minecraftforge.fluids.FluidStack) fluid).getFluid()
                        == net.minecraftforge.fluids.FluidRegistry.LAVA) {
                    victims.add(recipe);
                }
            }
            for (Object victim : victims) {
                if (Boolean.TRUE.equals(remove.invoke(manager, victim))) {
                    removed++;
                }
            }
            Minespace.log().info("forestry squeezer ({} pass): {} lava recipes removed", phase,
                    removed);
        } catch (ClassNotFoundException e) {
            // Forestry not installed - nothing to do
        } catch (Throwable t) {
            Minespace.log().error("forestry squeezer ({}) lava removal failed", phase, t);
        }
        return removed;
    }

    private static ItemStack stack(String oreName) {
        List<ItemStack> ores = OreDictionary.getOres(oreName, false);
        return ores.isEmpty() ? ItemStack.EMPTY : ores.get(0).copy();
    }
}
