package com.minespace.unofficial.navigation;

import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;

/**
 * Server-side (and shared) half of this module's proxy.
 *
 * <p>The star map is a client screen, so this module owns two halves: this one registers the wire protocol
 * ({@link MinespaceNetwork}), and {@code navigation/client/NavigationClientProxy} registers the key binding and
 * the screen. Splitting them this way is why the core no longer has to know that a star map exists: a
 * dedicated server loads this class and never the client one.</p>
 */
public class CommonProxy {

    public void preInit(FMLPreInitializationEvent event) {
        // One setting so far: whose arrival screen a rocket shows (see MinespaceNavigationSettings).
        MinespaceNavigationSettings.load(event.getSuggestedConfigurationFile());
        // Galacticraft asks a WorldProvider's registered ITeleportType how to arrive. Registering ours is
        // what makes a custom dimension use GC's transfer and lander instead of the vanilla-style fallback.
        if (net.minecraftforge.fml.common.Loader.isModLoaded("galacticraftcore")) {
            MinespacePlanetTeleportType.register();
        }
        // One packet each way: "aim my rocket at that body" (client to server) and "you are in orbit, choose a
        // destination" (server to client). See MinespaceNetwork.
        MinespaceNetwork.register();
    }

    public void init(FMLInitializationEvent event) {
    }
}
