package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import net.minecraft.world.World;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.event.terraingen.PopulateChunkEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.registry.GameRegistry;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.HashSet;
import java.util.Set;

/**
 * Runs the Forge world generators on Galacticraft's own dimensions.
 *
 * <h2>Why this is needed</h2>
 *
 * GregTech registers its ore veins as a plain Forge {@code IWorldGenerator}, and the only
 * thing that ever runs those is {@code GameRegistry.generateWorld(...)} — the call vanilla's
 * own chunk generator makes between the two {@code PopulateChunkEvent} posts.
 *
 * <p>Galacticraft's planet chunk providers ({@code ChunkProviderSpace} for the Moon, Mars
 * and Asteroids, and a hand-written {@code ChunkProviderVenus}) fire both of those events
 * and then decorate the planet themselves, but they never call
 * {@code GameRegistry.generateWorld}. Galacticraft's "Generate all other mods features on
 * planets" switch does not help: its coremod injects that call into the vanilla overworld
 * generator, which Galacticraft dimensions do not use. The observable result is that no
 * GregTech vein — and its own ore generation switch — produces anything on any planet.
 *
 * <p>So the missing call is made here instead. The chunk is already decorated by the time
 * this runs ({@code Post}), which is also where vanilla calls it, and GregTech's veins only
 * replace the planet rock, so running it at this point is equivalent to the vanilla order.
 *
 * <h2>Scope</h2>
 *
 * Only dimensions whose provider is a Galacticraft one. The overworld, Nether and End are
 * left alone: their generators already call {@code generateWorld} themselves, and calling
 * it again would run every other mod's generator twice.
 */
public final class MinespacePlanetOreGen {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private static final Set<Integer> REPORTED_DIMENSIONS = new HashSet<>();
    private static boolean registered;

    private MinespacePlanetOreGen() {
    }

    /** Called from this mod's init. No-op without Galacticraft, whose types this uses. */
    public static void register() {
        if (registered || !Minespace.hasGalacticraft()) {
            return;
        }
        registered = true;
        // Forge 1.12.2 posts BOTH PopulateChunkEvent.Pre and .Post on the regular event bus
        // (see ForgeEventFactory.onChunkPopulate) -- not on TERRAIN_GEN_BUS, which only
        // carries the biome/ore/minable terrain-gen events. Registering there silently
        // never receives anything.
        MinecraftForge.EVENT_BUS.register(MinespacePlanetOreGen.class);
        LOG.info("Registered the Galacticraft-dimension ore generation hook");
    }

    @SubscribeEvent
    public static void onPopulatePost(PopulateChunkEvent.Post event) {
        World world = event.getWorld();
        if (!(world.provider instanceof micdoodle8.mods.galacticraft.api.world.IGalacticraftWorldProvider)) {
            return;
        }

        GameRegistry.generateWorld(
                event.getChunkX(),
                event.getChunkZ(),
                world,
                event.getGenerator(),
                world.getChunkProvider());

        // Once per dimension, so the log proves the hook is live without spamming.
        Integer dimension = world.provider.getDimension();
        if (REPORTED_DIMENSIONS.add(dimension)) {
            LOG.info("Running Forge world generators on Galacticraft dimension {} — "
                    + "GregTech ore veins will now generate here", dimension);
        }
    }
}
