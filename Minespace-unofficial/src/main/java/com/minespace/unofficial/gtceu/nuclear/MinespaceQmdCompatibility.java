package com.minespace.unofficial.gtceu.nuclear;

import lach_01298.qmd.recipe.QMDRecipe;
import lach_01298.qmd.recipe.QMDRecipeHandler;
import lach_01298.qmd.recipes.QMDRecipes;
import nc.recipe.ingredient.IItemIngredient;
import nc.recipe.ingredient.OreIngredient;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Removes QMD's generic ore-processing shortcuts from the ore leacher and mass spectrometer.
 *
 * <p>QMD's defaults turn ordinary iron/copper/tin/lead/nickel/silver/aluminium ores into
 * three or four dusts. GT already owns that processing lane; the two QMD machines keep the
 * nuclear and rare-earth entries that justify their construction.</p>
 */
public final class MinespaceQmdCompatibility {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private static final Set<String> COMMON_ORES = new HashSet<>(Arrays.asList(
            "oreIron", "oreGold", "oreCopper", "oreTin", "oreLead",
            "oreNickel", "oreSilver", "oreAluminum", "oreAluminium"
    ));

    private MinespaceQmdCompatibility() {
    }

    public static void apply() {
        int oreLeacher = trim("ore_leacher");
        int spectrometer = trim("mass_spectrometer");
        if (oreLeacher + spectrometer > 0) {
            QMDRecipes.refreshRecipeCaches();
        }
        LOG.info("QMD compatibility: removed {} common-ore leacher recipes and {} common-ore mass-spectrometer recipes",
                oreLeacher, spectrometer);
    }

    private static int trim(String handlerName) {
        QMDRecipeHandler handler = QMDRecipes.getHandler(handlerName);
        if (handler == null) {
            return 0;
        }
        List<QMDRecipe> recipes = handler.getRecipeList();
        int before = recipes.size();
        recipes.removeIf(MinespaceQmdCompatibility::usesCommonOre);
        return before - recipes.size();
    }

    private static boolean usesCommonOre(QMDRecipe recipe) {
        for (IItemIngredient ingredient : recipe.getItemIngredients()) {
            if (ingredient instanceof OreIngredient
                    && COMMON_ORES.contains(((OreIngredient) ingredient).oreName)) {
                return true;
            }
        }
        return false;
    }
}
