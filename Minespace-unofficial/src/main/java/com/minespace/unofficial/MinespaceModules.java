package com.minespace.unofficial;

import net.minecraftforge.fml.common.Loader;
import org.apache.logging.log4j.Logger;

/**
 * The four mods this one jar ships, and the module self-check.
 *
 * <h2>One jar, four mods</h2>
 *
 * <p>Forge builds one mod container per {@code @Mod} class it finds in a jar, so a single jar can present several
 * mods to the game. Galacticraft's own jar does exactly that in this pack: {@code micdoodlecore},
 * {@code galacticraftcore} and {@code galacticraftplanets} all live in
 * {@code Galacticraft-1.12.2-4.0.7.jar}, while its {@code mcmod.info} declares only one of them. The split uses
 * the same mechanism - four modules, one jar, four entries in the mod list, and a log or crash line that names
 * the module it came from.</p>
 *
 * <h2>Why the ids live here</h2>
 *
 * <p>So that the dependency direction stays one way. A module may refer to {@link #CORE} (every module is
 * {@code required-after:minespace_core}), while the core only ever sees strings and never another module's
 * class.</p>
 *
 * <p>The <em>content</em> namespace is a different thing entirely, and it is frozen in
 * {@link MinespaceContent}.</p>
 */
public final class MinespaceModules {

    public static final String CORE = "minespace_core";
    public static final String PLANETS = "minespace_planets";
    public static final String NAVIGATION = "minespace_navigation";
    public static final String COSMIC = "minespace_cosmic";

    public static final String CORE_NAME = "Minespace Core";

    /** Version of the whole jar. Keep in step with {@code mod_version} in gradle.properties. */
    public static final String VERSION = "0.2.0";

    /** mod id, display name, one-line summary. */
    private static final String[][] ALL = {
            {CORE, CORE_NAME, "contracts, GregTech geology and world plugins, the other mods"},
            {PLANETS, "Minespace Planets", "the celestial bodies, their geology and their ruins"},
            {NAVIGATION, "Minespace Navigation", "the star map and spaceflight"},
            {COSMIC, "Minespace Cosmic", "the stage-five systems"},
    };

    private MinespaceModules() {
    }

    /**
     * One line per module, with the version it actually loaded as, or {@code absent}.
     *
     * <p>Called from {@code loadComplete}, the first point at which all four are constructed and the answer is
     * final. A module that reads {@code absent} here is a build problem rather than a runtime one, because all
     * four ship in this jar.</p>
     */
    public static void report(Logger logger) {
        for (String[] module : ALL) {
            String version = "absent";
            if (Loader.isModLoaded(module[0]) && Loader.instance().getIndexedModList().containsKey(module[0])) {
                version = Loader.instance().getIndexedModList().get(module[0]).getVersion();
            }
            logger.info("module {} ({} v{}) - {}", module[0], module[1], version, module[2]);
        }
    }
}
