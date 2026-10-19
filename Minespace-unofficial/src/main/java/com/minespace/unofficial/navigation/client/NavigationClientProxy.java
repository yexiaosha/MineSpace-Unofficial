package com.minespace.unofficial.navigation.client;

import com.minespace.unofficial.navigation.CommonProxy;
import com.minespace.unofficial.navigation.MinespaceStarMapKey;
import net.minecraft.client.settings.KeyBinding;
import net.minecraftforge.fml.client.registry.ClientRegistry;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.lwjgl.input.Keyboard;

/**
 * Client half of the navigation proxy: the only class in this module that touches client-only code.
 *
 * <p>FML instantiates exactly one of the two proxies, at runtime, from the {@code @SidedProxy} annotation on
 * {@link com.minespace.unofficial.navigation.MinespaceNavigation} - so on a dedicated server this class is never
 * referenced, and neither is the screen it opens.</p>
 */
public class NavigationClientProxy extends CommonProxy {

    private static final Logger LOG = LogManager.getLogger("minespace_navigation");

    @Override
    public void init(FMLInitializationEvent event) {
        // This pack's map is the default one (6ev), on the key Galacticraft's own map used: M, with J kept as an
        // alias for anyone who learned it that way.
        ClientRegistry.registerKeyBinding(MinespaceStarMapKey.OPEN_MAP);
        ClientRegistry.registerKeyBinding(MinespaceStarMapKey.OPEN_MAP_ALT);
        MinespaceStarMapKey.register();
        releaseGalacticraftMapKey();
    }

    /**
     * One star map by default, and it is this pack's.
     *
     * <p>Galacticraft registers its own map on M through {@code ClientRegistry.registerKeyBinding}, and its key is a
     * public static field, so the takeover is a released binding rather than a mixin. Their entry stays in the controls
     * list - a player who wants that screen back can put a key on it there - and it is only released while it is still
     * on M: a key the player has already moved is their choice, not ours.</p>
     *
     * <p>The reason this pack's map is the one worth defaulting to: Galaxy Space's bodies are in Galacticraft's
     * registry whatever the research says, so that screen cannot show what has been surveyed (6eu), while this one is
     * built on the gate - and the pack's progression is built on this one.</p>
     */
    private static void releaseGalacticraftMapKey() {
        if (!net.minecraftforge.fml.common.Loader.isModLoaded("galacticraftcore")) {
            return;
        }
        try {
            KeyBinding theirs = micdoodle8.mods.galacticraft.core.tick.KeyHandlerClient.galaxyMap;
            if (theirs != null && theirs.getKeyCode() == Keyboard.KEY_M) {
                theirs.setKeyCode(Keyboard.KEY_NONE);
                LOG.info("star map: M opens this pack's map (J also works); Galacticraft's own map key released");
            }
        } catch (Throwable t) {
            // A mapping we could not read is not worth a crash: both maps on M is a nuisance, not a failure.
            LOG.warn("star map: could not release Galacticraft's own map key - both maps answer to M", t);
        }
    }
}
