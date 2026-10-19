package com.minespace.unofficial.cosmic;

import com.minespace.unofficial.MinespaceModules;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;

/**
 * Minespace Cosmic - the stage-five systems module.
 *
 * <h2>What belongs here</h2>
 *
 * <p>The plan's chapter 4.5 systems, one package each: {@code research/} (the four-machine research chain and
 * what it unlocks), {@code observation/} (the time observation instrument and the universe simulator, which feed
 * each other), {@code dyson/} (the Dyson cloud, ring and sphere), {@code ftl/} (the three faster-than-light
 * tiers, the galaxy gate and the cosmic-scale engineering that ends in the creation engine).</p>
 *
 * <p>The research data item and the table that says which tier opens which layer live in core, because navigation
 * reads them as its gate and this module produces them.</p>
 *
 * <p>Deliberately empty: nothing in stage five has been started, and a module that ships no content should not
 * pretend otherwise. It exists now because the split's first step is to prove that one jar can present four mods
 * to Forge.</p>
 */
@Mod(
        modid = MinespaceCosmic.MOD_ID,
        name = MinespaceCosmic.MOD_NAME,
        version = MinespaceModules.VERSION,
        acceptedMinecraftVersions = "[1.12.2]",
        dependencies = "required-after:" + MinespaceModules.CORE
)
public class MinespaceCosmic {

    public static final String MOD_ID = MinespaceModules.COSMIC;
    public static final String MOD_NAME = "Minespace Cosmic";

    @EventHandler
    public void preInit(FMLPreInitializationEvent event) {
        event.getModLog().info("{} {} starting up", MOD_NAME, MinespaceModules.VERSION);
    }
}
