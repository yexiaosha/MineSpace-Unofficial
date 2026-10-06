package com.minespace.unofficial;

import com.minespace.unofficial.gtceu.MinespaceMaterials;
import com.minespace.unofficial.proxy.CommonProxy;
import net.minecraft.item.ItemStack;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.SidedProxy;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import org.apache.logging.log4j.Logger;

/**
 * Minespace Unofficial — a GregTech CE: Unofficial and Galacticraft addon.
 *
 * <h2>Load order contract</h2>
 * The {@code dependencies} string below is the whole reason this mod loads at the
 * right moment, and getting it wrong is the most common cause of "my material is
 * missing" or a {@code NoClassDefFoundError} during registration:
 *
 * <ul>
 *   <li>{@code required-after:gregtech} — GTCEu must have created its material
 *       registries before this mod's preInit runs. CodeChickenLib comes first
 *       because GTCEu itself requires it.</li>
 *   <li>{@code after:galacticraftcore} — deliberately <em>after</em>, not
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

    public static final String MOD_ID = "minespace";
    public static final String MOD_NAME = "Minespace Unofficial";
    public static final String VERSION = "0.2.0";

    /** See the class javadoc: the order here is load bearing. */
    public static final String DEPENDENCIES =
            "required-after:forge@[14.23.5.2859,);"
            + "required-after:codechickenlib;"
            + "required-after:gregtech;"
            + "after:galacticraftcore";

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

        // NOTE: no GTCEu material setup here. GTCEu freezes its material manager
        // inside its own preInit, which (because of required-after:gregtech) has
        // already run by the time this method is reached. Creating a registry here
        // throws "Cannot create registries in phase FROZEN".
        //
        // Registration is event driven instead, see MinespaceMaterials: one handler
        // creates the registry from MaterialRegistryEvent, another adds materials
        // from MaterialEvent.

        proxy.preInit(event);
    }

    @EventHandler
    public void init(FMLInitializationEvent event) {
        proxy.init(event);
    }

    @EventHandler
    public void postInit(FMLPostInitializationEvent event) {
        proxy.postInit(event);

        // Everything is registered by now, so this is the first point where reading
        // back an addon material proves the whole chain worked: GTCEu ran its
        // material handlers and generated the item for the prefix we asked for.
        if (MinespaceMaterials.lookup(MinespaceMaterials.DESH_STEEL) != null) {
            ItemStack ingot = MinespaceMaterials.stack(
                    gregtech.api.unification.ore.OrePrefix.ingot,
                    MinespaceMaterials.DESH_STEEL);
            logger.info("GTCEu material check: desh_steel ingot -> {}",
                    ingot.isEmpty() ? "NOT GENERATED" : ingot.getDisplayName());
        } else {
            logger.warn("GTCEu materials were never registered — is the registry created in preInit?");
        }
    }

    public static Logger log() {
        return logger;
    }

    /**
     * True when the mod can use Galacticraft's API. Guard optional integration with
     * this rather than catching NoClassDefFoundError.
     */
    public static boolean hasGalacticraft() {
        return Loader.isModLoaded("galacticraftcore");
    }
}
