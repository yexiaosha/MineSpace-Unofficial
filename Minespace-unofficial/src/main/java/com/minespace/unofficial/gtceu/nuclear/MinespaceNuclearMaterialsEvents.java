package com.minespace.unofficial.gtceu.nuclear;

import com.minespace.unofficial.Minespace;
import net.minecraft.item.crafting.IRecipe;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Optional hook for the NuclearCraft material-processing bridge.
 *
 * <p>This class deliberately imports no NuclearCraft types. FML loads it even when NCO is absent;
 * only {@link MinespaceNuclearMaterials} (which does import NCO) is loaded when the mod is present.</p>
 */
@Mod.EventBusSubscriber(modid = Minespace.MOD_ID)
public final class MinespaceNuclearMaterialsEvents {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private MinespaceNuclearMaterialsEvents() {
    }

    @SubscribeEvent(priority = EventPriority.LOWEST)
    public static void onRegisterRecipes(RegistryEvent.Register<IRecipe> event) {
        if (Loader.isModLoaded("nuclearcraft") && Loader.isModLoaded("gregtech")) {
            // The four form-only materials (Boron ingot, Cobalt Oxide ingot, Mercury ingot,
            // Fluorite gem) need their mod ore-dictionary alias before the rewrite resolves targets.
            MinespaceNuclearGtMaterials.registerFormAliases();
            try {
                Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                        .getMethod("register")
                        .invoke(null);
            } catch (ReflectiveOperationException e) {
                LOG.warn("nuclear material bridge could not start", e);
            }
            if (Loader.isModLoaded("qmd")) {
                try {
                    Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceQmdCompatibility")
                            .getMethod("apply")
                            .invoke(null);
                } catch (ReflectiveOperationException e) {
                    LOG.warn("QMD compatibility pass could not start", e);
                }
            }
            rewriteLoadedRecipes();
        }
    }

    /**
     * Runs the NCO/QMD recipe rewrite again over the finished recipe lists.
     *
     * <p>The registry event happens during {@code init}, but several NCO/QMD processors add their
     * recipes in {@code postInit}, and CraftTweaker adds or removes recipes on top of that. A second
     * pass at load complete catches those late registrations; the pass is idempotent because a
     * rewritten slot already names the GregTech item.</p>
     */
    public static void rewriteLoadedRecipes() {
        if (!Loader.isModLoaded("nuclearcraft") || !Loader.isModLoaded("gregtech")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialRewrite")
                    .getMethod("apply")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear material rewrite could not start", e);
        }
    }

    /** Removes NCO's crafting-table block recipes after every mod has finished registering. */
    public static void removeNuclearBlockCrafting() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("removeBlockCraftingRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear block crafting cleanup could not run", e);
        }
    }

    /** Adds NCO block compressor/unpacker recipes after GT's own late recipe generation. */
    public static void registerNuclearBlockConversions() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("registerBlockConversions")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear block conversion registration could not run", e);
        }
    }

    public static void registerNuclearPlatingRecipes() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("registerPlatingRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear plating recipe registration could not run", e);
        }
    }

    public static void removeNuclearPlatingCrafting() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("removePlatingCraftingRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear plating crafting cleanup could not run", e);
        }
    }

    public static void registerNuclearBatteryRecipes() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("registerBatteryRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear battery recipe registration could not run", e);
        }
    }

    public static void removeNuclearBatteryCrafting() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("removeBatteryCraftingRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear battery crafting cleanup could not run", e);
        }
    }

    public static void registerNuclearSolarPanelRecipes() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("registerSolarPanelRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear solar panel recipe registration could not run", e);
        }
    }

    public static void removeNuclearSolarPanelCrafting() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("removeSolarPanelCraftingRecipes")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear solar panel crafting cleanup could not run", e);
        }
    }

    public static void registerNuclearAlloyDustVariants() {
        if (!Loader.isModLoaded("nuclearcraft")) {
            return;
        }
        try {
            Class.forName("com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterials")
                    .getMethod("registerAlloyDustVariants")
                    .invoke(null);
        } catch (ReflectiveOperationException e) {
            LOG.warn("nuclear alloy dust variant registration could not run", e);
        }
    }
}
