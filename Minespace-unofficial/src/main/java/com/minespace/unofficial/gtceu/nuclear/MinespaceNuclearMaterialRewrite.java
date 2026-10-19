package com.minespace.unofficial.gtceu.nuclear;

import com.minespace.unofficial.gtceu.MinespaceMaterialRepoint;
import nc.recipe.BasicRecipe;
import nc.recipe.BasicRecipeHandler;
import nc.recipe.NCRecipes;
import nc.recipe.ingredient.ChanceItemIngredient;
import nc.recipe.ingredient.IItemIngredient;
import nc.recipe.ingredient.ItemIngredient;
import nc.recipe.ingredient.OreIngredient;
import net.minecraft.item.ItemStack;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.oredict.OreDictionary;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.List;
import java.util.Map;

/**
 * Rewrites NCO recipe item stacks to the canonical GregTech item for stable materials.
 *
 * <p>The GT recipe maps are handled by {@link MinespaceMaterialRepoint}; this class covers the
 * NCO recipe handlers themselves, which otherwise keep producing and consuming their own copper,
 * tungsten, stainless steel, and similar copies. QMD's equivalent pass lives in
 * {@link MinespaceQmdRecipeRewrite} and is reached reflectively so this class still loads when QMD
 * is not installed.</p>
 */
public final class MinespaceNuclearMaterialRewrite {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private static int passes;

    private MinespaceNuclearMaterialRewrite() {
    }

    public static void apply() {
        passes++;
        Map<String, ItemStack> targets = MinespaceMaterialRepoint.currentTargets();
        int nco = 0;
        int qmd = 0;
        for (BasicRecipeHandler handler : NCRecipes.getHandlers()) {
            int changed = 0;
            for (BasicRecipe recipe : handler.getRecipeList()) {
                changed += rewrite(recipe.getItemIngredients(), targets);
                changed += rewriteOutputs(recipe.getItemProducts(), targets);
            }
            if (changed > 0) {
                handler.postInit();
                nco += changed;
            }
        }
        if (Loader.isModLoaded("qmd")) {
            try {
                qmd = (Integer) Class.forName(
                                "com.minespace.unofficial.gtceu.nuclear.MinespaceQmdRecipeRewrite")
                        .getMethod("apply", Map.class)
                        .invoke(null, targets);
            } catch (ReflectiveOperationException e) {
                LOG.warn("QMD recipe rewrite could not run", e);
            }
        }
        LOG.info("nuclear material rewrite (pass {}): {} NCO slots and {} QMD slots now use "
                + "GregTech items", passes, nco, qmd);
    }

    static int rewrite(List<IItemIngredient> ingredients, Map<String, ItemStack> targets) {
        int changed = 0;
        for (int i = 0; i < ingredients.size(); i++) {
            IItemIngredient ingredient = ingredients.get(i);
            if (ingredient == null) {
                continue;
            }
            if (ingredient instanceof OreIngredient) {
                OreIngredient ore = (OreIngredient) ingredient;
                if (ore.stackSize <= 0) {
                    continue;
                }
                ItemStack target = uniformOreTarget(ore.oreName, targets);
                if (target != null) {
                    target.setCount(ore.stackSize);
                    ingredients.set(i, new ItemIngredient(target));
                    changed++;
                }
                continue;
            }
            if (ingredient instanceof ChanceItemIngredient) {
                ChanceItemIngredient chance = (ChanceItemIngredient) ingredient;
                IItemIngredient raw = chance.getRawIngredient();
                ItemStack target;
                if (raw instanceof OreIngredient) {
                    OreIngredient ore = (OreIngredient) raw;
                    target = ore.stackSize <= 0 ? null : uniformOreTarget(ore.oreName, targets);
                    if (target != null) {
                        target.setCount(ore.stackSize);
                    }
                } else {
                    target = stack(raw, targets);
                }
                if (target != null) {
                    chance.ingredient = new ItemIngredient(target);
                    changed++;
                }
                continue;
            }
            ItemStack target = stack(ingredient, targets);
            if (target != null) {
                ingredients.set(i, new ItemIngredient(target));
                changed++;
            }
        }
        return changed;
    }

    /**
     * Resolves an ore dictionary name only when its every member is already unified: the GregTech
     * item plus mod copies this pack has mapped to it. A name that also lists a material from an
     * unrelated mod is left alone, so the recipe keeps accepting that material.
     */
    private static ItemStack uniformOreTarget(String oreName, Map<String, ItemStack> targets) {
        ItemStack canonical = null;
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            if (isGregTech(candidate)) {
                if (canonical != null && !canonical.isItemEqual(candidate)) {
                    return null;
                }
                canonical = candidate;
                continue;
            }
            if (!targets.containsKey(idOf(candidate))) {
                return null;
            }
        }
        return canonical == null ? null : canonical.copy();
    }

    /**
     * Rewrites recipe outputs, including ore-dictionary outputs.
     *
     * <p>NCO writes many outputs as {@link OreIngredient}. Its {@code getStack()} answers with the
     * first entry of the ore dictionary name, which is usually NCO's own dust or ingot - that is how
     * a GT machine ended up handing out NCO tin dust even though the tin mapping existed. The input
     * side can keep the ore dictionary name (GregTech's item is registered under the same name), but
     * an output has to name the canonical stack explicitly.</p>
     */
    static int rewriteOutputs(List<IItemIngredient> products, Map<String, ItemStack> targets) {
        int changed = 0;
        for (int i = 0; i < products.size(); i++) {
            IItemIngredient product = products.get(i);
            if (product == null) {
                continue;
            }
            if (product instanceof OreIngredient) {
                OreIngredient ore = (OreIngredient) product;
                ItemStack target = oreTarget(ore.oreName, targets);
                if (target != null) {
                    target.setCount(Math.max(1, ore.stackSize));
                    products.set(i, new ItemIngredient(target));
                    changed++;
                }
                continue;
            }
            if (product instanceof ChanceItemIngredient) {
                ChanceItemIngredient chance = (ChanceItemIngredient) product;
                IItemIngredient raw = chance.getRawIngredient();
                ItemStack target;
                if (raw instanceof OreIngredient) {
                    OreIngredient ore = (OreIngredient) raw;
                    target = oreTarget(ore.oreName, targets);
                    if (target != null) {
                        target.setCount(Math.max(1, ore.stackSize));
                    }
                } else {
                    target = stack(raw, targets);
                }
                if (target != null) {
                    chance.ingredient = new ItemIngredient(target);
                    changed++;
                }
                continue;
            }
            ItemStack target = stack(product, targets);
            if (target != null) {
                products.set(i, new ItemIngredient(target));
                changed++;
            }
        }
        return changed;
    }

    /**
     * Resolves an ore dictionary name to the canonical GregTech item, but only when that name also
     * holds a mod item this pack has already mapped. Names that belong solely to NCO/QMD (isotopes,
     * fission products, QMD's own chemistry) deliberately stay untouched.
     */
    private static ItemStack oreTarget(String oreName, Map<String, ItemStack> targets) {
        for (ItemStack candidate : OreDictionary.getOres(oreName, false)) {
            ItemStack target = targets.get(idOf(candidate));
            if (target != null && !target.isEmpty() && isGregTech(target)) {
                return target.copy();
            }
        }
        return null;
    }

    private static boolean isGregTech(ItemStack stack) {
        return stack.getItem().getRegistryName() != null
                && "gregtech".equals(stack.getItem().getRegistryName().getResourceDomain());
    }

    private static ItemStack stack(IItemIngredient ingredient, Map<String, ItemStack> targets) {
        Object raw = ingredient == null ? null : ingredient.getStack();
        if (!(raw instanceof ItemStack)) {
            return null;
        }
        ItemStack stack = (ItemStack) raw;
        if (stack.isEmpty()) {
            return null;
        }
        ItemStack target = targets.get(idOf(stack));
        if (target == null || target.isEmpty()) {
            return null;
        }
        ItemStack replacement = target.copy();
        replacement.setCount(stack.getCount());
        return replacement;
    }

    private static String idOf(ItemStack stack) {
        return String.valueOf(stack.getItem().getRegistryName()) + ":" + stack.getMetadata();
    }
}
