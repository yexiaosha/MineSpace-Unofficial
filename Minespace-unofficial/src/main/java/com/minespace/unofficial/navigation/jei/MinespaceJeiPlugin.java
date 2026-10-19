package com.minespace.unofficial.navigation.jei;

import gregtech.integration.jei.GTOreInfo;
import mezz.jei.api.IJeiRuntime;
import mezz.jei.api.IModPlugin;
import mezz.jei.api.IRecipeRegistry;
import mezz.jei.api.JEIPlugin;
import mezz.jei.api.recipe.IRecipeCategory;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.List;

/**
 * Replaces GregTech's one-slot-per-block JEI entries with one slot per ore.
 *
 * <p>GT registers one {@link GTOreInfo} per ore deposit. Its output list is one entry per unique
 * block, which in this pack means every stone variant gets its own slot: the nickel vein alone
 * becomes more than fifty slots and a page taller than the screen. This plugin swaps each original
 * wrapper for a {@link GroupedGTOreInfo}, which keeps one slot per ore and puts the stone variants
 * into that slot as JEI ingredient alternatives. The page returns to its 176x166 background and
 * GT's ore-weight tooltip indexes the ore list correctly again.</p>
 */
@JEIPlugin
@SideOnly(Side.CLIENT)
public class MinespaceJeiPlugin implements IModPlugin {

    private static final String ORE_CATEGORY = "gregtech:ore_spawn_location";
    private static final Logger LOG = LogManager.getLogger("minespace_navigation");

    @Override
    @SuppressWarnings({"unchecked", "rawtypes"})
    public void onRuntimeAvailable(IJeiRuntime runtime) {
        IRecipeRegistry registry = runtime.getRecipeRegistry();
        IRecipeCategory category = registry.getRecipeCategory(ORE_CATEGORY);
        if (category == null) {
            LOG.warn("JEI ore vein pagination: category {} is not registered", ORE_CATEGORY);
            return;
        }

        List<?> wrappers = registry.getRecipeWrappers(category);
        List<GTOreInfo> originals = new ArrayList<>();
        for (Object wrapper : wrappers) {
            if (wrapper instanceof GroupedGTOreInfo) {
                // Already grouped: onRuntimeAvailable may run again after a reload.
                return;
            }
            if (wrapper instanceof GTOreInfo) {
                originals.add((GTOreInfo) wrapper);
            }
        }

        for (GTOreInfo original : originals) {
            registry.removeRecipe(original, ORE_CATEGORY);
            registry.addRecipe(new GroupedGTOreInfo(original.getDefinition()), ORE_CATEGORY);
        }
        LOG.info("JEI ore veins: {} entries regrouped by ore material", originals.size());
    }
}
