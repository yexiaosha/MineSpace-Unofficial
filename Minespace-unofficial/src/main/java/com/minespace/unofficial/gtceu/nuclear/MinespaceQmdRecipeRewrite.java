package com.minespace.unofficial.gtceu.nuclear;

import lach_01298.qmd.recipe.QMDRecipe;
import lach_01298.qmd.recipe.QMDRecipeHandler;
import lach_01298.qmd.recipes.QMDRecipes;
import net.minecraft.item.ItemStack;

import java.util.Map;

/**
 * The QMD half of the nuclear recipe rewrite.
 *
 * <p>Kept in its own class because it imports QMD types: {@link MinespaceNuclearMaterialRewrite}
 * reaches it only through reflection and only when QMD is loaded, so the NCO-only installation does
 * not need QMD on the classpath.</p>
 */
public final class MinespaceQmdRecipeRewrite {

    private MinespaceQmdRecipeRewrite() {
    }

    public static int apply(Map<String, ItemStack> targets) {
        int changed = 0;
        for (QMDRecipeHandler handler : QMDRecipes.getHandlers()) {
            int handlerChanged = 0;
            for (QMDRecipe recipe : handler.getRecipeList()) {
                handlerChanged += MinespaceNuclearMaterialRewrite
                        .rewrite(recipe.getItemIngredients(), targets);
                handlerChanged += MinespaceNuclearMaterialRewrite
                        .rewriteOutputs(recipe.getItemProducts(), targets);
            }
            changed += handlerChanged;
        }
        if (changed > 0) {
            QMDRecipes.refreshRecipeCaches();
        }
        return changed;
    }
}
