package com.minespace.unofficial;

import com.minespace.unofficial.gtceu.MinespaceMaterials;
import com.minespace.unofficial.gtceu.MinespaceModelCheck;
import com.minespace.unofficial.gtceu.MinespacePlanetOreGen;
import com.minespace.unofficial.proxy.CommonProxy;
import net.minecraft.item.ItemStack;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.SidedProxy;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLLoadCompleteEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import org.apache.logging.log4j.Logger;

/**
 * Minespace Unofficial 鈥?a GregTech CE: Unofficial and Galacticraft addon.
 *
 * <h2>Load order contract</h2>
 * The {@code dependencies} string below is the whole reason this mod loads at the
 * right moment, and getting it wrong is the most common cause of "my material is
 * missing" or a {@code NoClassDefFoundError} during registration:
 *
 * <ul>
 *   <li>{@code required-after:gregtech} 鈥?GTCEu must have created its material
 *       registries before this mod's preInit runs. CodeChickenLib comes first
 *       because GTCEu itself requires it.</li>
 *   <li>{@code after:galacticraftcore} 鈥?deliberately <em>after</em>, not
 *       <em>required-after</em>: the Galacticraft integration is optional and the
 *       mod must still load when GC is not installed. Every GC call is guarded.</li>
 * </ul>
 */
@Mod(
        modid = Minespace.MOD_ID,
        name = Minespace.MOD_NAME,
        version = Minespace.VERSION,
        acceptedMinecraftVersions = "[1.12.2]",
        dependencies = Minespace.DEPENDENCIES
)
public class Minespace {

    public static final String MOD_ID = MinespaceModules.CORE;
    public static final String MOD_NAME = MinespaceModules.CORE_NAME;
    public static final String VERSION = MinespaceModules.VERSION;
    // NOTE 2026-10-16: this is the *core module's* Forge mod id, one of the four this jar ships (see
    // MinespaceModules). It is deliberately NOT the content namespace: registry names, model and texture paths,
    // translation keys and the GregTech material namespace stay on MinespaceContent.NAMESPACE, which is frozen
    // at "minespace" so that existing worlds and the generated resources under assets/minespace/ keep working.

    /** See the class javadoc: the order here is load bearing. */
    public static final String DEPENDENCIES =
            "required-after:forge@[14.23.5.2859,);"
            + "required-after:codechickenlib;"
            + "required-after:gregtech;"
            // galaxy space and AsmodeusCore are `after` for one measured reason: MinespaceCelestialRegistry reuses a
            // system Galacticraft already owns when one of this pack's keys shares it (the sun's system for the gas
            // giants), and registers its own bodies through AsmodeusCore's BodiesRegistry - both have to exist first.
            // `after` and not `required-after`: the pack still loads when any of them is missing, and every call is
            // guarded by a mod-presence check.
            + "after:galacticraftcore;"
            + "after:galaxyspace;"
            + "after:asmodeuscore;"
            + "after:planetprogression";

    @Mod.Instance(MOD_ID)
    public static Minespace instance;

    @SidedProxy(
            clientSide = "com.minespace.unofficial.proxy.ClientProxy",
            serverSide = "com.minespace.unofficial.proxy.CommonProxy"
    )
    public static CommonProxy proxy;

    private static Logger logger;

    @EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        logger = event.getModLog();
        logger.info("{} {} starting up", MOD_NAME, VERSION);
        logger.info("Target mods: {}", ModPresence.describe());

        // Vanilla's granite/diorite/andesite patches and friends: GT's own disableVanillaOres
        // flag does not cover those, so they are switched off here instead.
        com.minespace.unofficial.gtceu.MinespaceVanillaWorldgen
                .configure(event.getSuggestedConfigurationFile());

        // NOTE: no GTCEu material setup here. GTCEu freezes its material manager
        // inside its own preInit, which (because of required-after:gregtech) has
        // already run by the time this method is reached. Creating a registry here
        // throws "Cannot create registries in phase FROZEN".
        //
        // Registration is event driven instead, see MinespaceMaterials: one handler
        // creates the registry from MaterialRegistryEvent, another adds materials
        // from MaterialEvent. MinespaceStoneTypes adds GTCEu stone types from the block
        // registry event, which is the only point late enough for Galacticraft's blocks
        // to exist and early enough for GTCEu's ore blocks not to be built yet.

        // This mod's own GregTech machines. Unlike materials these are NOT registered from
        // an event: GTCEu leaves the machine registry open for the whole preInit phase and
        // freezes it at init, so registering here (after GTCEu's preInit because of
        // required-after:gregtech, before its init) is the supported window. See
        // MinespaceGregMachines for the details.
        com.minespace.unofficial.gtceu.machines.MinespaceGregMachines.register();

        // The 81 planned deep-space dimensions from PLANET-CATALOG: ids registered, no worlds created
        // (Forge only makes a world when something travels to one), no terrain. See the class javadoc
        // for what that does and does not buy.
        //
        // 6ds disabled this for a day on suspicion, and 6dt put it back. The suspicion was a client that
        // stopped - no crash report, no hs_err, no Windows event, the log simply ended inside Galacticraft's
        // init - and the 81 dimensions were the newest thing in the build, so they were the suspect. They
        // were not the cause: a client launched from the *same* jar reached the main menu, loaded a world
        // and opened the star map, and a second client run from a clean game directory did the same. What
        // is left is a process that was killed rather than one that failed, and an unproven suspect is not
        // a reason to keep a finished milestone switched off.
        com.minespace.unofficial.gtceu.MinespacePlanetDimensionsRegistration.register();

        // 6er: this pack's own bodies into Galacticraft's celestial registry, so PlanetProgression's telescope, its
        // research papers and its unlock-all command cover them - see MinespaceCelestialRegistry for what is registered
        // (everything Galacticraft does not already own) and what deliberately is not (no dimension info). It goes here,
        // after the dimensions exist, because PlanetProgression creates a research paper per registered body during the
        // item registry event, which runs after every mod's preInit and init.
        com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry.register();

        // DISABLED 2026-10-15 (6dq/6dr): the star map crashed the client twice from here - once on a
        // galaxy texture path, once because NewGuiCelestialSelection.drawCircles dereferences a
        // system's main star and a body's relative distance, and this registration sets neither. The
        // class is kept; the call returns when those fields are supplied and the result has been seen
        // in a client. Do not re-enable it without one to test on.
        // com.minespace.unofficial.navigation.MinespacePlanetSkyRegistry.register();  (the class moved to the
        // navigation module in the split; when it comes back the call belongs in that module's own init, not here)

        proxy.preInit(event);
    }

    @EventHandler
    public void init(FMLInitializationEvent event) {
        // Deferred to the first client tick: model queries during init return unbaked
        // stand-ins, so a check here would be meaningless. See MinespaceModelCheck.
        MinespaceModelCheck.register();

        // Vanilla biome decorators get their granite/diorite/andesite generators replaced with
        // no-ops (see MinespaceVanillaWorldgen); has to be in place before any chunk is decorated.
        com.minespace.unofficial.gtceu.MinespaceVanillaWorldgen.register();

        // Galacticraft's planet chunk providers never call GameRegistry.generateWorld, so
        // GTCEu's veins get no chance to run there. See MinespacePlanetOreGen.
        MinespacePlanetOreGen.register();

        // Ender IO registers its ten fluids from Forge's block registry event, which is the phase
        // between preInit and here - so this is the first point at which they exist. Handing them to
        // the GregTech FluidMaterials MinespaceMaterials created (instead of letting GregTech build
        // its own) is what makes them GregTech fluids without a second fluid object. Idempotent, and
        // called again from postInit as a safety net. See MinespaceEioFluids.
        com.minespace.unofficial.gtceu.MinespaceEioFluids.adopt("init");

        proxy.init(event);
    }

    @EventHandler
    public void postInit(FMLPostInitializationEvent event) {
        proxy.postInit(event);
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .registerNuclearAlloyDustVariants();

        // Safety net for the fluid adoption above: if a mod ever registers its fluids later than
        // Ender IO does, or the init pass saw an empty registry, this catches it.
        com.minespace.unofficial.gtceu.MinespaceEioFluids.adopt("postInit");

        // Gregicality's "free" producers for Galacticraft's compressed plates (a bender turning one
        // steel ingot into a compressed steel plate, and friends). Called here and again at load
        // complete, because Gregicality registers its material recipes in its own init / postInit and
        // which of the two calls sees them first depends on mod order. See the class javadoc for the
        // probe output that found this. Idempotent.
        com.minespace.unofficial.gtceu.MinespaceCompressedPlateGuard
                .repointCheapProducers("postInit");

        // GregTech's own ore chain was handing out the *mods'* copies of the same material (meteoric
        // iron from GregTech's own ore, and so on). Every smelting recipe and every machine recipe that
        // produces one of those copies is re-pointed at GregTech's item. See the class javadoc.
        // Idempotent, and run here and again at load complete because Gregicality registers late.
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointSmelting("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.pruneDeadSmelting("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.pruneEbfMetalSmelting("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointMaps("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointCraftingInputs("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint
                .removeDeadDuplicateCrafting("postInit");

        // AE2's grinder is a duplicate of GregTech's macerator: its 443 recipes are moved over and the
        // grinder is emptied. See the class javadoc. This *adds* macerator recipes, so the machine-input
        // re-point has to run after it - the recipes it brings over are Gregicality's, built on the mod
        // ingots, and the unreachable pass below would otherwise throw them away instead of letting the
        // re-point adapt them.
        com.minespace.unofficial.gtceu.MinespaceGrinderToMacerator.convert("postInit");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointMachineInputs("postInit");

        // The recipe clean-ups have to run here as well as at load complete, and the reason is JEI:
        // every mod's FMLLoadCompleteEvent handler runs in mod-load order, JEI loads before this mod,
        // and JEI *builds its recipe index in that very handler*. A deletion made at load complete is
        // therefore real in the registry but invisible in JEI, which is exactly what the owner kept
        // reporting ("the assembler and the crafting table both have it") after the first passes. By
        // postInit every source is in place - CraftTweaker applies its actions in its own postInit and
        // it loads before this mod, Gregicality's mirrored machine recipes likewise - so the same,
        // idempotent passes run here for JEI's benefit and again at load complete as a safety net.
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeCraftingTableCompression("postInit");
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeUnreachableMachineRecipes("postInit");
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeSubMvAe2BlockRecipes("postInit");
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeLeftoverCraftingRecipes("postInit");
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeDuplicatedTableRoutes("postInit");
        com.minespace.unofficial.gtceu.MinespaceRecipeDedupe.removeOrderDuplicates("postInit");

        // Galacticraft's machine recipes are Java lists, not crafting-table recipes, so the
        // scripts cannot remove them - without this the compressor still compresses plates and
        // JEI still lists it. Runs here because Galacticraft registered its recipes during its
        // own postInit (this mod is after:galacticraftcore) and JEI reads the lists later.
        com.minespace.unofficial.galacticraft.MinespaceGalacticraftMachineRecipes
                .clearRemovedMachineRecipes();

        // Everything is registered by now, so this is the first point where reading
        // back an addon material proves the whole chain worked: GTCEu ran its
        // material handlers and generated the item for the prefix we asked for.
        com.minespace.unofficial.gtceu.MinespaceGalaxySpaceStones.verifyTargets();
        if (MinespaceMaterials.lookup(MinespaceMaterials.DESH_STEEL) != null) {
            ItemStack ingot = MinespaceMaterials.stack(
                    gregtech.api.unification.ore.OrePrefix.ingot,
                    MinespaceMaterials.DESH_STEEL);
            logger.info("GregTech material check: desh_steel ingot -> {}",
                    ingot.isEmpty() ? "NOT GENERATED" : ingot.getDisplayName());
        } else {
            logger.warn("GregTech materials were never registered 鈥?is the registry created in preInit?");
        }

        // Remove the old NCO table routes and add their GT replacements before JEI builds its
        // recipe list at loadComplete. The block converter's machine half stays in loadComplete
        // because it must follow the unreachable-machine cleanup.
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .removeNuclearBlockCrafting();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .registerNuclearPlatingRecipes();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .removeNuclearPlatingCrafting();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .registerNuclearBatteryRecipes();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .removeNuclearBatteryCrafting();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .registerNuclearSolarPanelRecipes();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .removeNuclearSolarPanelCrafting();

        // BYG's own ore-dictionary list is hand-written; fill the standard wood/stone names
        // after BYG and every other block/item registry have finished.
        com.minespace.unofficial.gtceu.MinespaceBygOreDictionary.register();

        // Forestry's arboretum only plants entries in its own farmArboreal list, not anything
        // carrying treeSapling. The adapter is optional and loaded reflectively with Forestry.
        if (net.minecraftforge.fml.common.Loader.isModLoaded("forestry")
                && net.minecraftforge.fml.common.Loader.isModLoaded("byg")) {
            try {
                Class.forName("com.minespace.unofficial.gtceu.MinespaceForestryBygFarm")
                        .getMethod("register")
                        .invoke(null);
            } catch (ReflectiveOperationException e) {
                logger.warn("Forestry BYG sapling registration could not start", e);
            }
        }

        com.minespace.unofficial.gtceu.MinespaceBygProcessing.register();
    }

    public static Logger log() {
        return logger;
    }

    /**
     * Runs after every mod has finished postInit, so recipes a mod registers late are visible here.
     *
     * <p>First customer: {@link com.minespace.unofficial.gtceu.MinespaceCompressedPlateGuard}, which
     * re-points the Gregicality-generated Galacticraft compressed-plate recipes back at GregTech's own
     * plain plates (and deletes whatever it cannot re-point, so the compressed plate keeps exactly one
     * producer: the implosion compressor). It is called from postInit as well, because the two events
     * straddle Gregicality's own registration and only one of them will see the recipes. Idempotent, so
     * calling it twice costs one pass over the recipe maps.</p>
     */
    /**
     * The celestial registration's second standing check, at the moment a world is actually playable.
     *
     * <p>It is not the same question as the loadComplete one, and the difference is measured (6er): at loadComplete
     * *every* landable dimension of Galacticraft's and Galaxy Space's own worlds answers "not registered" - Mars and the
     * Moon included - because those mods register their dimensions later. Only here does "this body's dimension does not
     * exist" mean what it sounds like, which is that a landable body cannot be travelled to.</p>
     */
    @EventHandler
    public void serverStarted(net.minecraftforge.fml.common.event.FMLServerStartedEvent event) {
        com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry.verify("server started");
        com.minespace.unofficial.gtceu.nuclear.MinespaceDiagnosticsEvents.exportIfRequested();
    }

    @EventHandler
    public void loadComplete(FMLLoadCompleteEvent event) {
        com.minespace.unofficial.gtceu.MinespaceVeinSource.index();
        // NCO/QMD add part of their recipe lists in postInit, after the registry-event pass. Rewrite
        // once more before this file's own material re-point passes inspect the finished lists.
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .rewriteLoadedRecipes();
        com.minespace.unofficial.gtceu.MinespaceForestryTubes.convert("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceForestryCarpenter.convert("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceForestryCarpenter
                .repointRetiredItems("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceForestryCarpenter.removeLavaSqueezing("loadComplete");
        int removed = com.minespace.unofficial.gtceu.MinespaceCompressedPlateGuard
                .repointCheapProducers("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointSmelting("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.pruneDeadSmelting("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.pruneEbfMetalSmelting("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointMaps("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointMachineInputs("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint.repointCraftingInputs("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceMaterialRepoint
                .removeDeadDuplicateCrafting("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceGrinderToMacerator.convert("loadComplete");
        // The crafting table is not the compressor: Gregicality's 1074 "nine ingots into a block"
        // recipes go, unless no GregTech machine makes the same item, and machine recipes that can
        // only be fed with a unified-away mod item go with them. See MinespaceCraftingBlocks.
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeCraftingTableCompression("loadComplete");
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeUnreachableMachineRecipes("loadComplete");
        // The AE2 line starts at MV: Gregicality's LV packer route into AE2's quartz and fluix blocks
        // goes, and the MV replacements are in ae2_base.zs (TJ-MIGRATION-PLAN.md 6ar).
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeSubMvAe2BlockRecipes("loadComplete");
        // The rule the owner keeps running into - "if a machine makes it, the table must not" - has to
        // be enforced over the *finished* registries, because some of those machine routes were never
        // written by a script (Gregicality mirrors a mod's own crafting recipe onto a machine) and some
        // of the table recipes are named after the mod rather than after GregTech's generator.
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeDuplicatedTableRoutes("loadComplete");
        // ... and the same for the table itself: an item this pack moved into a machine must not be
        // craftable any more, even when the mod that owns it registers its recipes after CraftTweaker's
        // removal pass has already run. The list lives in minespace_machine_only.txt, generated from the
        // scripts; whatever this finds is logged item by item.
        com.minespace.unofficial.gtceu.MinespaceCraftingBlocks
                .removeLeftoverCraftingRecipes("loadComplete");
        // A machine has no slots, so it has no order: recipes that only differ by the order of the
        // same materials (each crafting-table shape moved to the assembler on its own) are one recipe.
        com.minespace.unofficial.gtceu.MinespaceRecipeDedupe.removeOrderDuplicates("loadComplete");
        // Standing guard: a machine has no slots, so a recipe that needs eight of an item must carry
        // one stack of eight. Reports (never rewrites) any recipe whose input list is not folded.
        com.minespace.unofficial.gtceu.MinespaceRecipeHygiene
                .checkUnmergedInputs("loadComplete");
        // The machine cleanup above treats NCO block items as "unified away" inputs and would delete
        // the unpacker half of these conversions. Register both machine routes after that cleanup.
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .registerNuclearBlockConversions();
        com.minespace.unofficial.gtceu.nuclear.MinespaceNuclearMaterialsEvents
                .removeNuclearBlockCrafting();
        // Standing guard for the celestial registration (6er): names, icons and dimensions are couplings to generated
        // files and to other mods, and all three fail silently. One line per start, like the recipe hygiene checks.
        com.minespace.unofficial.galacticraft.MinespaceCelestialRegistry.verify("loadComplete");
        if (removed > 0) {
            logger.info("Late recipe fixes at load complete: {} compressed-plate producers re-pointed",
                    removed);
        }

        // The module self-check (MinespaceModules): one line per module of this jar, with the version it actually
        // loaded as. All four ship together, so a line reading "absent" here is a build problem, not a config one.
        MinespaceModules.report(logger);

    }

    /**
     * True when the mod can use Galacticraft's API. Guard optional integration with
     * this rather than catching NoClassDefFoundError.
     */
    public static boolean hasGalacticraft() {
        return Loader.isModLoaded("galacticraftcore");
    }
}
