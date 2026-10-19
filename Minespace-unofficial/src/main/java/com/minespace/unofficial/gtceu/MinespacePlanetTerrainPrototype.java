package com.minespace.unofficial.gtceu;

import net.minecraft.block.Block;
import net.minecraft.block.SoundType;
import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.util.ResourceLocation;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.biome.BiomeProviderSingle;
import net.minecraft.init.Biomes;
import net.minecraft.world.chunk.Chunk;
import net.minecraft.world.chunk.ChunkPrimer;
import net.minecraft.world.gen.ChunkGeneratorOverworld;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import com.minespace.unofficial.MinespaceContent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * The first of the eighty-one planned bodies to become a real world rather than a placeholder.
 *
 * <h2>What was missing, and what this is</h2>
 *
 * {@link MinespacePlanetDimensionsRegistration} registers all eighty-one deep-space ids with one shared
 * {@code VoidProvider} that generates nothing at all. That is deliberate for ids nobody can reach yet, and it is
 * also a wall: GregTech generates ore by *replacing the stone of a world*, so a void dimension can never hold a
 * vein no matter how many vein files name it. The chain from "an id exists" to "a planet you can mine" is
 * **terrain, then a stone type, then veins**, and this class is the first two links for one body.
 *
 * The body is **TRAPPIST-1 e** (dimension {@code -2103}), the catalog's layer-3, stage-5 rocky world: it is one of
 * the named bodies players already read about on the star map, it is landable in the table, and it is mine.
 *
 * <h2>The rock is a stand-in, and that is on purpose</h2>
 *
 * The terrain is generated out of plain {@code minecraft:stone} under a one-block regolith layer of the same, and
 * the stone type's base is that same state. It is honest rather than pretty: what this round proves is the
 * *pipeline* - a provider that generates a real surface, a GregTech {@link StoneType} that makes that surface
 * eligible for ore, and a probe that measures both. The art pass (this mod's own rock block and texture per body)
 * and the vein files for this body are the next two rounds, and neither is needed to know whether this works.
 *
 * <h2>Timing</h2>
 *
 * The stone type is registered from {@code MinespaceMaterials.onMaterialsInit()} - inside GregTech's own preInit,
 * the only window early enough, because GTCE-TJ bakes its ore blocks there. See {@link MinespaceStoneTypes} for the
 * full explanation of that contract.
 */
public final class MinespacePlanetTerrainPrototype {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    /** The body this round makes real. Its dimension id comes from the generated table, never from a guess. */
    private static final String KEY = "trappist_1_e";

    /**
     * The GregTech stone type id. Sixteen and up belong to this pack's own bodies (see
     * {@link MinespaceGalaxySpacePlanets}); GT's own stone types are 0..15, so 64 is clear of both and of anything
     * Galaxy Space ships.
     */
    private static final int STONE_TYPE_ID = 64;

    /** How high the rock reaches, in blocks, before noise moves it. Sea level of the overworld, roughly. */
    private static final int BASE_HEIGHT = 62;

    private static boolean registered;

    private MinespacePlanetTerrainPrototype() {
    }

    /** The dimension id of the prototype body, or -1 when the catalog has no such row. */
    public static int dimensionId() {
        for (MinespacePlanetDimensions.Planet planet : MinespacePlanetDimensions.PLANETS) {
            if (planet.key.equals(KEY)) {
                return planet.dimensionId;
            }
        }
        return -1;
    }

    /** True for the one body whose provider is the rock provider instead of the shared void one. */
    public static boolean isPrototype(MinespacePlanetDimensions.Planet planet) {
        return planet.key.equals(KEY);
    }

    /** Called from {@link MinespaceMaterials#onMaterialsInit()} - inside GregTech's preInit. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;

        Supplier<IBlockState> base = () -> Blocks.STONE.getDefaultState();

        // The predicate decides which blocks a vein may replace. The overworld stone is a stand-in for this body's
        // rock, and being precise about it matters: matching "any block" would let a vein eat the whole world.
        Predicate<IBlockState> predicate = state -> state.getBlock() == Blocks.STONE;

        new StoneType(
                STONE_TYPE_ID,
                "trappist_1_e_stone",
                new ResourceLocation(MinespaceContent.NAMESPACE, "blocks/trappist_1_e_rock"),
                SoundType.STONE,
                OrePrefix.ore,
                Materials.Stone,
                "pickaxe",
                0,
                base,
                predicate);

        LOG.info("Registered a stone type for {} (id {}, stone type {}) - the terrain prototype",
                KEY, dimensionId(), STONE_TYPE_ID);
    }

    /**
     * The prototype's world provider: the void provider with a generator that actually builds ground.
     *
     * <p>Everything else - the single biome, the absent respawn, the "not a surface world" flags - is inherited,
     * because none of it is what is being tested.</p>
     */
    public static class RockProvider extends MinespacePlanetDimensionsRegistration.VoidProvider {

        @Override
        protected void init() {
            this.biomeProvider = new BiomeProviderSingle(Biomes.PLAINS);
            this.hasSkyLight = true;
        }

        @Override
        public net.minecraft.world.gen.IChunkGenerator createChunkGenerator() {
            return new RockChunkGenerator(this.world);
        }
    }

    /**
     * Bedrock, then rock to a noisy surface height, then air.
     *
     * <p>The height is a sum of two sines of the world coordinates - not fractal noise, and not trying to be: the
     * question this answers is "does a real chunk generator run here and produce ground the vein generator can walk
     * over", and a smooth ridge is enough to see that in a probe. Perlin and its friends come with the art pass.</p>
     */
    public static class RockChunkGenerator extends MinespacePlanetDimensionsRegistration.VoidChunkGenerator {

        private final World rockWorld;

        public RockChunkGenerator(World world) {
            super(world);
            this.rockWorld = world;
        }

        @Override
        public Chunk generateChunk(int x, int z) {
            ChunkPrimer primer = new ChunkPrimer();
            IBlockState stone = Blocks.STONE.getDefaultState();
            IBlockState bedrock = Blocks.BEDROCK.getDefaultState();
            long seed = this.rockWorld.getSeed();
            for (int bx = 0; bx < 16; bx++) {
                for (int bz = 0; bz < 16; bz++) {
                    int wx = x * 16 + bx;
                    int wz = z * 16 + bz;
                    double swell = Math.sin((wx + seed % 977) * 0.045D) * 6.0D
                            + Math.sin((wz + seed % 613) * 0.031D) * 4.0D
                            + Math.sin((wx + wz) * 0.017D) * 3.0D;
                    int height = BASE_HEIGHT + (int) swell;
                    primer.setBlockState(bx, 0, bz, bedrock);
                    for (int y = 1; y <= height; y++) {
                        primer.setBlockState(bx, y, bz, stone);
                    }
                }
            }
            Chunk chunk = new Chunk(this.rockWorld, primer, x, z);
            chunk.generateSkylightMap();
            return chunk;
        }

        /** Where a player would appear: on top of the ground, not inside it. */
        @Override
        public BlockPos getNearestStructurePos(World world, String structureName, BlockPos pos,
                boolean findUnexplored) {
            return pos;
        }
    }
}
