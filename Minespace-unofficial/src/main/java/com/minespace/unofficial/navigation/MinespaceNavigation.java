package com.minespace.unofficial.navigation;

import com.minespace.unofficial.MinespaceModules;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.SidedProxy;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLServerStartedEvent;

/**
 * Minespace Navigation - the star map and spaceflight module.
 *
 * <h2>What belongs here</h2>
 *
 * <p>The 3D star map and everything that hangs off it: the screen and its key binding, the surveyed-body gate,
 * the launch flow (Galacticraft flies the rocket, this pack's map aims it), the sky box feedback, the lanes and
 * their fuel economy, and the multi-block launch infrastructure with the tier 11+ rocket bridge.</p>
 *
 * <p>This is the one module besides core that is allowed to import Galacticraft and PlanetProgression directly,
 * and the reason is in the name: a map of Galacticraft's own celestial registry is Galacticraft's interface, and
 * the gate reads PlanetProgression's research state for the bodies Galacticraft already knows. For the bodies
 * only this pack knows, the gate is the research data key that lives in core.</p>
 *
 * <p>Today it is the only content of the module's future home: the seven classes that make up the star map and
 * the rocket side move here in the step after this one.</p>
 */
@Mod(
        modid = MinespaceNavigation.MOD_ID,
        name = MinespaceNavigation.MOD_NAME,
        version = MinespaceModules.VERSION,
        acceptedMinecraftVersions = "[1.12.2]",
        dependencies = "required-after:" + MinespaceModules.CORE
)
public class MinespaceNavigation {

    public static final String MOD_ID = MinespaceModules.NAVIGATION;
    public static final String MOD_NAME = "Minespace Navigation";

    @SidedProxy(
            clientSide = "com.minespace.unofficial.navigation.client.NavigationClientProxy",
            serverSide = "com.minespace.unofficial.navigation.CommonProxy"
    )
    public static CommonProxy proxy;

    @EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        event.getModLog().info("{} {} starting up", MOD_NAME, MinespaceModules.VERSION);
        proxy.preInit(event);
    }

    @EventHandler
    public void init(FMLInitializationEvent event) {
        proxy.init(event);
    }

    @EventHandler
    public void serverStarted(FMLServerStartedEvent event) {
        MinespacePlanetTeleportType.probeIfRequested();
    }
}
