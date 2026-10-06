package com.minespace.unofficial;

import net.minecraftforge.fml.common.Loader;

/**
 * Reports which addon target mods are actually loaded, so a missing or
 * mis-versioned dependency shows up in the log instead of as a mystery crash
 * during material or recipe registration.
 */
public final class ModPresence {

    /** modid -> human readable name, for the mods this addon builds against. */
    private static final String[][] TRACKED = {
            {"gregtech", "GregTech CE: Unofficial"},
            {"codechickenlib", "CodeChicken Lib"},
            {"galacticraftcore", "Galacticraft"},
            {"galacticraftplanets", "Galacticraft Planets"},
    };

    private ModPresence() {
    }

    public static boolean isLoaded(String modId) {
        return Loader.isModLoaded(modId);
    }

    /** e.g. "GregTech CE: Unofficial=2.8.10-beta, Galacticraft=4.0.7, KubeJS=absent". */
    public static String describe() {
        StringBuilder sb = new StringBuilder();
        for (String[] entry : TRACKED) {
            if (sb.length() > 0) {
                sb.append(", ");
            }
            String modId = entry[0];
            sb.append(entry[1]).append('=');
            // Loader#getIndexedModList is the 1.12.2 accessor; the containers are
            // populated during construction, so this is safe to call from preInit.
            if (Loader.isModLoaded(modId) && Loader.instance().getIndexedModList().containsKey(modId)) {
                sb.append(Loader.instance().getIndexedModList().get(modId).getVersion());
            } else {
                sb.append("absent");
            }
        }
        return sb.toString();
    }
}
