package com.minespace.unofficial.navigation;

import net.minecraftforge.common.config.Configuration;

import java.io.File;

/**
 * This module's one setting, so far: whose screen a rocket arrival shows.
 *
 * <p>Default is this pack's own (6h) - the pack re-dresses Galacticraft's flight with its own star map and its own
 * arrival screen, the same way it took the map key. The setting exists because the alternative is a real one: the
 * owner may want Galacticraft's plain screen back without rebuilding the jar, which is what "configurable" means
 * here.</p>
 */
public final class MinespaceNavigationSettings {

    /** True: this pack's arrival screen. False: Galacticraft's own. */
    public static boolean ownTeleportScreen = true;

    private MinespaceNavigationSettings() {
    }

    /** Read at load: the file is named after the module's modid. */
    public static void load(File configFile) {
        Configuration configuration = new Configuration(configFile);
        configuration.load();
        ownTeleportScreen = configuration.getBoolean(
                "ownTeleportScreen",
                "interface",
                true,
                "Show this pack's arrival screen instead of Galacticraft's while a rocket loads the destination. "
                        + "Set to false for Galacticraft's own screen.");
        if (configuration.hasChanged()) {
            configuration.save();
        }
    }
}
