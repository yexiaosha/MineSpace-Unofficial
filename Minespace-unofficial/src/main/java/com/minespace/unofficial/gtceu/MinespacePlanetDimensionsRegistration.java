package com.minespace.unofficial.gtceu;

import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Biomes;
import net.minecraft.world.World;
import net.minecraft.world.DimensionType;
import net.minecraft.world.WorldProvider;
import net.minecraft.world.biome.BiomeProviderSingle;
import net.minecraft.world.chunk.Chunk;
import net.minecraft.world.chunk.ChunkPrimer;
import net.minecraft.world.gen.IChunkGenerator;
import net.minecraft.world.gen.ChunkGeneratorOverworld;
import net.minecraftforge.common.DimensionManager;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Registers the 81 planned dimensions from PLANET-CATALOG so every id this pack's vein files name is a
 * dimension that exists.
 *
 * <h2>What this deliberately is not</h2>
 *
 * No terrain, no per-body rock blocks, no sky, no atmosphere, no travel. The owner's call was "register
 * them all first, the star map can see them later" - and registering is genuinely cheap, because
 * <b>registering a dimension does not create a world</b>. 6dl measured that the hard way: all 25 planet
 * dimensions were registered, and Forge refused to create a single world for any of them until a player
 * travels there. So eighty-one registrations cost a list entry each and nothing else.
 *
 * What it buys: every {@code dimension_id} in the 126 vein files is now a dimension that exists, the
 * star map has something to point at, and the bodies whose cards are already written can stop being
 * {@code Pending} in {@code planet-veins.psd1}.
 *
 * <h2>The one thing it must not get wrong</h2>
 *
 * The pack's planet ore generation only runs for dimensions whose provider is a Galacticraft one - see
 * {@link MinespacePlanetOreGen#isPlanet}. These providers are not, so no ore will generate in them
 * until either the providers become Galacticraft-compatible or that guard is widened. That is the next
 * piece of work, not this one, and it is written down here so that "registered" is never mistaken for
 * "playable": a planet you can reach and mine nothing on is the bug 6cu set out to fix.
 */
public final class MinespacePlanetDimensionsRegistration {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private static boolean registered;

    private MinespacePlanetDimensionsRegistration() {
    }

    /** Called from this mod's preInit, after GregTech and before anything can look a dimension up. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;

        int added = 0;
        int skipped = 0;
        int foreign = 0;
        int landable = 0;
        for (MinespacePlanetDimensions.Planet planet : MinespacePlanetDimensions.PLANETS) {
            // Only the deep-space bands are ours to create: the catalog plans them from -2000 down
            // (-2000..-2099 nearby, -2100.. mid, -2200.. far, -2300.. deep, -2350.. ultra, -2400..
            // unknown). Everything above that belongs to somebody else - Galacticraft, Galaxy Space, or
            // another mod entirely - and registering into their range is not a near miss, it is a crash:
            // this table now carries the bodies that already exist so the star map can show them, and one
            // of those rows is at -11, which is Applied Energistics' spatial storage dimension. Claiming
            // it made AE2 throw "Invalid dimension id -11" during mod loading and took the whole game down.
            if (planet.dimensionId > -2000) {
                foreign++;
                continue;
            }
            if (DimensionManager.isDimensionRegistered(planet.dimensionId)) {
                // Somebody else owns this id. Never overwrite it - Galaxy Space and Galacticraft own the
                // ids they have, and a silent re-registration would move a real planet.
                LOG.warn("Planned dimension {} ({}) is already registered - left alone",
                        planet.dimensionId, planet.name);
                skipped++;
                continue;
            }
            // One body has real terrain now (see MinespacePlanetTerrainPrototype); everything else keeps the void
            // provider until it gets its own rock, stone type and sky.
            Class<? extends WorldProvider> provider = MinespacePlanetTerrainPrototype.isPrototype(planet)
                    ? MinespacePlanetTerrainPrototype.RockProvider.class
                    : VoidProvider.class;
            DimensionType type = DimensionType.register(
                    "minespace_" + planet.key, "_planet", planet.dimensionId,
                    provider, false);
            DimensionManager.registerDimension(planet.dimensionId, type);
            added++;
            if (planet.landable) {
                landable++;
            }
        }

        LOG.info("Registered {} planned dimensions ({} landable, {} observation only), {} already owned "
                        + "by another mod, {} left to their owners; {} in total from PLANET-CATALOG",
                added, landable, added - landable, skipped, foreign,
                MinespacePlanetDimensions.PLANETS.size());
    }

    /**
     * The shared provider. One class for eighty-one bodies because nothing about them differs yet - when
     * they get their own rock, stone type and sky, they will get their own provider, and that is the day
     * the Galacticraft interface has to be implemented too.
     */
    public static class VoidProvider extends WorldProvider {

        @Override
        protected void init() {
            this.biomeProvider = new BiomeProviderSingle(Biomes.PLAINS);
            this.hasSkyLight = true;
        }

        @Override
        public IChunkGenerator createChunkGenerator() {
            return new VoidChunkGenerator(this.world);
        }

        @Override
        public DimensionType getDimensionType() {
            return DimensionType.getById(getDimension());
        }

        @Override
        public boolean canRespawnHere() {
            return false;
        }

        @Override
        public boolean isSurfaceWorld() {
            return false;
        }
    }

    /**
     * Nothing at all: the placeholder world is empty until the planet is real.
     *
     * <p>It extends the overworld generator rather than implementing {@link IChunkGenerator} directly,
     * because half of that interface is boilerplate whose exact signatures the mapped snapshot does not
     * spell the same way - a stack trace about "cannot implement getPossibleCreatures" is not what this
     * piece of work is about. Overriding two methods is the whole difference between a world and a void.</p>
     */
    public static class VoidChunkGenerator extends ChunkGeneratorOverworld {

        /** Its own reference: the parent's world field is private. */
        private final World voidWorld;

        public VoidChunkGenerator(World world) {
            super(world, world.getSeed(), false, "");
            this.voidWorld = world;
        }

        @Override
        public Chunk generateChunk(int x, int z) {
            Chunk chunk = new Chunk(this.voidWorld, new ChunkPrimer(), x, z);
            chunk.generateSkylightMap();
            return chunk;
        }

        @Override
        public void populate(int x, int z) {
        }
    }
}
