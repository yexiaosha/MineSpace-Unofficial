package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.worldgen.generator.GTWorldGenCapability;
import net.minecraft.world.World;
import net.minecraft.world.chunk.Chunk;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.event.terraingen.PopulateChunkEvent;
import net.minecraftforge.event.world.ChunkEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;
import net.minecraftforge.fml.common.registry.GameRegistry;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;

/**
 * Runs GregTech's ore veins on Galacticraft's planets.
 *
 * <h2>Why the generator has to be driven from here</h2>
 *
 * GregTech registers its veins as a plain Forge {@code IWorldGenerator}, and the only thing that
 * ever runs those is {@code GameRegistry.generateWorld(...)} - the call vanilla's own chunk
 * generator makes between the two {@code PopulateChunkEvent} posts.
 *
 * <p>Galacticraft's planet chunk providers ({@code ChunkProviderSpace} for the Moon, Mars and the
 * Asteroids, and a hand-written {@code ChunkProviderVenus}) fire those events and then decorate
 * the planet themselves, but they never call {@code GameRegistry.generateWorld}. Galacticraft's
 * "Generate all other mods features on planets" switch does not help either: its coremod injects
 * that call into the vanilla overworld generator, which Galacticraft dimensions do not use. The
 * observable result is that no GregTech vein - and none of its ore - appears on any planet.
 *
 * <h2>What this class does</h2>
 *
 * <ol>
 *   <li>{@link #onPopulatePre} hands GregTech the terrain heights it needs, before it generates
 *       anything. {@code CachedGridEntry} only measures the terrain when <em>no</em> chunk of its
 *       3x3 cell is generated yet; in a Galacticraft dimension the chunk already counts as
 *       generated, so GregTech would keep the chunk capability's default {@code 0/0} heights,
 *       compute {@code maximumHeight = min(0, heightLimit[1] - offset) = 0 < minimumHeight} and
 *       skip every vein. See {@link #primeVeinHeights}.</li>
 *   <li>{@link #onPopulatePost} makes the missing {@code GameRegistry.generateWorld} call, which
 *       is where vanilla would do it.</li>
 *   <li>{@link #onChunkLoad} and {@link #onServerTick} are a fallback for dimensions whose
 *       provider fires no populate events at all (Venus in this build): the chunk is queued and,
 *       if its dimension never registered itself through the two hooks above, GregTech's
 *       generator is driven directly a couple of seconds later.</li>
 * </ol>
 *
 * <p>Only dimensions whose provider is a Galacticraft one are touched. The overworld, Nether and
 * End are left alone: their generators already call {@code generateWorld} themselves, and calling
 * it again would run every other mod's generator twice.
 */
public final class MinespacePlanetOreGen {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private static final Set<Integer> REPORTED_DIMENSIONS = new HashSet<>();

    /** Dimensions whose providers do fire the populate events (Moon, Mars, the Asteroids). */
    private static final Set<Integer> POPULATED_DIMENSIONS = new HashSet<>();

    /** Chunks waiting for the fallback pass: key -> {dimension, chunkX, chunkZ, dueTick}. */
    private static final Map<Long, int[]> FALLBACK_QUEUE = new LinkedHashMap<>();

    private static final int FALLBACK_DELAY_TICKS = 40;

    private static int ticks;
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
    public static void onPopulatePre(PopulateChunkEvent.Pre event) {
        World world = event.getWorld();
        if (!isPlanet(world)) {
            return;
        }
        POPULATED_DIMENSIONS.add(world.provider.getDimension());
        primeVeinHeights(world, event.getChunkX(), event.getChunkZ());
    }

    @SubscribeEvent
    public static void onPopulatePost(PopulateChunkEvent.Post event) {
        World world = event.getWorld();
        if (!isPlanet(world)) {
            return;
        }
        POPULATED_DIMENSIONS.add(world.provider.getDimension());

        GameRegistry.generateWorld(
                event.getChunkX(),
                event.getChunkZ(),
                world,
                event.getGenerator(),
                world.getChunkProvider());

        // Once per dimension, so the log proves the hook is live without spamming.
        Integer dimension = world.provider.getDimension();
        if (REPORTED_DIMENSIONS.add(dimension)) {
            LOG.info("Running Forge world generators on Galacticraft dimension {} - "
                    + "GregTech ore veins will now generate here", dimension);
        }
    }

    @SubscribeEvent
    public static void onChunkLoad(ChunkEvent.Load event) {
        World world = event.getWorld();
        if (!isPlanet(world)) {
            return;
        }
        Chunk chunk = event.getChunk();
        if (chunk == null) {
            return;
        }
        int dimension = world.provider.getDimension();
        if (POPULATED_DIMENSIONS.contains(dimension)) {
            return;
        }
        long key = ((long) dimension << 48) ^ ((long) chunk.x << 24) ^ chunk.z;
        synchronized (FALLBACK_QUEUE) {
            if (!FALLBACK_QUEUE.containsKey(key)) {
                FALLBACK_QUEUE.put(key,
                        new int[] { dimension, chunk.x, chunk.z, ticks + FALLBACK_DELAY_TICKS });
            }
        }
    }

    @SubscribeEvent
    public static void onServerTick(TickEvent.ServerTickEvent event) {
        if (event.phase != TickEvent.Phase.END) {
            return;
        }
        ticks++;

        List<int[]> due = new ArrayList<>();
        synchronized (FALLBACK_QUEUE) {
            Iterator<Map.Entry<Long, int[]>> iterator = FALLBACK_QUEUE.entrySet().iterator();
            while (iterator.hasNext()) {
                Map.Entry<Long, int[]> entry = iterator.next();
                if (entry.getValue()[3] <= ticks) {
                    due.add(entry.getValue());
                    iterator.remove();
                }
            }
        }

        for (int[] pending : due) {
            int dimension = pending[0];
            // A dimension that does fire the populate events has registered itself by now (the
            // fallback waits a couple of seconds on purpose), so its queue entries are dropped
            // rather than generating the same veins a second time.
            if (POPULATED_DIMENSIONS.contains(dimension)) {
                continue;
            }
            net.minecraft.world.WorldServer world =
                    net.minecraftforge.common.DimensionManager.getWorld(dimension);
            if (world == null) {
                continue;
            }
            try {
                primeVeinHeights(world, pending[1], pending[2]);
                // GregTech's generator ignores the random and the chunk generator/provider it is
                // handed (it works off its own per-cell state), so the fallback can drive it
                // directly - and only it, leaving every other mod's world generator untouched.
                new gregtech.api.worldgen.generator.WorldGeneratorImpl().generate(
                        new Random(world.getSeed()), pending[1], pending[2], world, null, null);
                if (REPORTED_DIMENSIONS.add(dimension)) {
                    LOG.info("Running GregTech ore generation on Galacticraft dimension {} "
                            + "through the chunk-load fallback (its provider fires no populate "
                            + "events)", dimension);
                }
            } catch (Throwable t) {
                LOG.warn("Fallback ore generation failed for dimension {} chunk {},{}: {}",
                        dimension, pending[1], pending[2], t.toString());
            }
        }
    }

    private static boolean isPlanet(World world) {
        // Galacticraft's planets, and this mod's own planned dimensions (6dm). The test is not "is this
        // a Galacticraft planet" but "does this dimension's generator skip GameRegistry.generateWorld",
        // which is the whole reason this class exists: Galacticraft's chunk providers never call it, and
        // neither does the void generator the 81 planned dimensions use. Both therefore need the call
        // made for them. Anything that does call it - the overworld, the Nether, the End - stays out,
        // because running every mod's generator twice is worse than running none.
        return world.provider
                instanceof micdoodle8.mods.galacticraft.api.world.IGalacticraftWorldProvider
                || world.provider
                instanceof MinespacePlanetDimensionsRegistration.VoidProvider;
    }

    /**
     * Gives GregTech's vein grid the terrain heights it needs, for every already generated chunk
     * of the current chunk's 3x3 cell - see the class javadoc for why that is required. The
     * values are the ones GregTech itself reads: {@code getPrecipitationHeight} for the terrain
     * height and {@code getTopSolidOrLiquidBlock} for the bottom height.
     */
    private static void primeVeinHeights(World world, int chunkX, int chunkZ) {
        int baseX = Math.floorDiv(chunkX, 3) * 3;
        int baseZ = Math.floorDiv(chunkZ, 3) * 3;
        for (int x = baseX; x < baseX + 3; x++) {
            for (int z = baseZ; z < baseZ + 3; z++) {
                if (!world.isChunkGeneratedAt(x, z)) {
                    continue;
                }
                try {
                    Chunk chunk = world.getChunkFromChunkCoords(x, z);
                    GTWorldGenCapability capability = chunk == null ? null
                            : chunk.getCapability(GTWorldGenCapability.CAPABILITY, null);
                    if (capability == null
                            || (capability.getMaxHeight() > 0
                                    && capability.getMaxBottomHeight() > 0)) {
                        continue;
                    }
                    net.minecraft.util.math.BlockPos pos = new net.minecraft.util.math.BlockPos(
                            (x << 4) + 8, 0, (z << 4) + 8);
                    capability.setMaxHeight(world.getPrecipitationHeight(pos).getY(),
                            world.getTopSolidOrLiquidBlock(pos).getY());
                } catch (Throwable t) {
                    LOG.warn("Could not prime GregTech vein heights for chunk {},{},{}: {}",
                            world.provider.getDimension(), x, z, t.toString());
                }
            }
        }
    }
}
