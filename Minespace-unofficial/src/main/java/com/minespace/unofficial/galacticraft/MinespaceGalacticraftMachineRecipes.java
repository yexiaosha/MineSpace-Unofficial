package com.minespace.unofficial.galacticraft;

import com.minespace.unofficial.Minespace;
import micdoodle8.mods.galacticraft.api.recipe.CircuitFabricatorRecipes;
import micdoodle8.mods.galacticraft.api.recipe.CompressorRecipes;
import net.minecraft.item.ItemStack;
import net.minecraft.item.crafting.IRecipe;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.List;

/**
 * Takes the recipes of Galacticraft's removed processing machines out of the game.
 *
 * <h2>Why a script cannot do this</h2>
 *
 * CraftTweaker's {@code recipes.remove()} only touches the vanilla crafting table. Galacticraft's
 * machine recipes are Java lists that its own machines and its JEI pages read directly, so the
 * compressed plates stayed listed in JEI even after the compressor's crafting recipe was removed
 * - and an electric compressor obtained from a creative menu (or from an old world) would still
 * run them. Both lists are exposed through Galacticraft's API, so they are cleared here instead:
 *
 * <ul>
 *   <li>{@link CompressorRecipes} - the ingot compressor, electric compressor and advanced
 *       compressor all read this one list (compressed plates and friends);</li>
 *   <li>{@link CircuitFabricatorRecipes} - the circuit fabricator (wafers).</li>
 * </ul>
 *
 * <p>Runs from this mod's {@code postInit}, which (because of {@code after:galacticraftcore})
 * is after Galacticraft has registered its recipes and before JEI builds its recipe pages - JEI
 * reads those lists in its plugin phase, which happens after every mod's postInit.
 */
public final class MinespaceGalacticraftMachineRecipes {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** Upper bound for the circuit fabricator walk; its list is a dozen entries at most. */
    private static final int MAX_FABRICATOR_RECIPES = 256;

    private MinespaceGalacticraftMachineRecipes() {
    }

    /** Called from this mod's postInit. No-op without Galacticraft. */
    public static void clearRemovedMachineRecipes() {
        if (!Minespace.hasGalacticraft()) {
            return;
        }
        int compressors = clearCompressorRecipes();
        int fabricators = clearCircuitFabricatorRecipes();
        LOG.info(
                "Cleared {} Galacticraft compressor recipes and {} circuit fabricator recipes "
                        + "(those machines are replaced by GregTech)",
                compressors, fabricators);
    }

    private static int clearCompressorRecipes() {
        // Copy first: removeRecipe() mutates the list this came from.
        List<IRecipe> recipes = new ArrayList<>(CompressorRecipes.getRecipeListAll());
        int count = 0;
        for (IRecipe recipe : recipes) {
            ItemStack output = recipe.getRecipeOutput();
            if (output == null || output.isEmpty()) {
                continue;
            }
            CompressorRecipes.removeRecipe(output);
            count++;
        }
        return count;
    }

    private static int clearCircuitFabricatorRecipes() {
        int count = 0;
        for (int index = 0; index < MAX_FABRICATOR_RECIPES; index++) {
            ItemStack output;
            try {
                output = CircuitFabricatorRecipes.getOutput(index);
            } catch (RuntimeException pastTheEnd) {
                // IndexOutOfBounds is how the list reports "no more recipes".
                break;
            }
            if (output == null || output.isEmpty()) {
                break;
            }
            CircuitFabricatorRecipes.removeRecipe(output);
            count++;
        }
        return count;
    }
}
