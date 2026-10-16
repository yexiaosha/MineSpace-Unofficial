package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.material.type.DustMaterial;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import net.minecraft.block.Block;
import net.minecraft.block.SoundType;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * Registers one GregTech stone type per Galaxy Space celestial body, so GregTech's ore veins can
 * generate on the new planets at all.
 *
 * <h2>Why the predicate is "any metadata of that block"</h2>
 *
 * A vein only replaces blocks that pass the vein's {@code generation_predicate}, and GregTech's
 * default is {@code StoneType.computeStoneType(state, world, pos) != null} - an unregistered
 * rock means no ore, anywhere. Galaxy Space puts every variant of a body (surface, subsurface,
 * its own ores) into one block with different metadata, and the vein generator can meet any of
 * them, so matching the whole block is both simpler and more robust than listing metadata
 * numbers. The base GT draws the ore on stays this mod's own rock block for that body.
 *
 * <p>Timing is the same contract as {@link MinespaceStoneTypes}: in GTCE-TJ the ore blocks are
 * baked during GT's own preInit, so these stone types are registered from
 * {@link MinespaceMaterials#onMaterialsInit()} - the only window early enough. Both block
 * references (this mod's base rock and Galaxy Space's rock for the predicate) are resolved
 * lazily, because no block exists yet at that point.
 */
public final class MinespaceGalaxySpaceStones {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** One lazy Galaxy Space block lookup per body, kept so {@link #verifyTargets()} can re-check. */
    private static final java.util.Map<String, Supplier<Block>> TARGETS =
            new java.util.LinkedHashMap<>();

    private static boolean registered;

    private MinespaceGalaxySpaceStones() {
    }

    /** Called from {@link MinespaceMaterials#onMaterialsInit()} - inside GT's preInit. */
    public static void register() {
        if (registered || !Loader.isModLoaded(MinespaceGalaxySpacePlanets.GALAXY_SPACE_MOD_ID)) {
            return;
        }
        registered = true;

        int count = 0;
        for (MinespaceGalaxySpacePlanets.Planet planet : MinespaceGalaxySpacePlanets.PLANETS) {
            if (registerStoneType(planet)) {
                count++;
            }
        }
        LOG.info("Registered {} Galaxy Space stone types - GregTech veins can now generate on "
                + "those bodies", count);
    }

    private static boolean registerStoneType(MinespaceGalaxySpacePlanets.Planet planet) {
        // GT's own stone material - see MinespaceMaterials for why this mod no longer registers
        // one material per body.
        DustMaterial stoneMaterial = Materials.Stone;

        Supplier<IBlockState> base = () -> MinespaceGalaxySpaceRocks.defaultState(planet);

        // The Galaxy Space rock is resolved lazily, and only ever by registry name: this runs inside
        // GT's preInit, long before any mod has registered a block, so an eager lookup would find
        // Forge's placeholder at that name instead - which for blocks is minecraft:air. A predicate
        // built from that placeholder matches every air block, and since air is everywhere in a
        // vein's sphere that turned every vein in the overworld into a NullPointerException.
        Supplier<Block> galaxySpaceRock = lazyBlock(planet.gsBlock);
        TARGETS.put(planet.key, galaxySpaceRock);
        Predicate<IBlockState> predicate = state -> {
            Block rock = galaxySpaceRock.get();
            return rock != null && state.getBlock() == rock;
        };

        // Rock texture copied from Galaxy Space into this mod's assets (see
        // MinespaceGalaxySpaceRocks); GTCE's StoneType takes it explicitly.
        new StoneType(
                planet.stoneTypeId,
                planet.stoneName(),
                new ResourceLocation(Minespace.MOD_ID, "blocks/" + planet.rockName()),
                SoundType.STONE,
                OrePrefix.ore,
                stoneMaterial,
                "pickaxe",
                0,
                base,
                predicate);
        return true;
    }

    /**
     * Post-init sanity check: logs the bodies whose Galaxy Space block never showed up under the
     * name this mod knows. Such a stone type is dead weight - the ore there falls back to the
     * overworld stone base - and names drift between Galaxy Space releases, so a silent miss is
     * worth a loud log line.
     */
    public static void verifyTargets() {
        if (!registered) {
            return;
        }
        java.util.List<String> missing = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, Supplier<Block>> entry : TARGETS.entrySet()) {
            try {
                if (entry.getValue().get() == null) {
                    missing.add(entry.getKey());
                }
            } catch (Throwable t) {
                missing.add(entry.getKey() + "(" + t + ")");
            }
        }
        if (missing.isEmpty()) {
            LOG.info("All {} Galaxy Space rock blocks resolved - the stone types are live",
                    TARGETS.size());
        } else {
            LOG.error("Galaxy Space blocks missing for {}: {} - ores there will use the overworld "
                    + "stone base", missing.size(), missing);
        }
    }

    /**
     * Resolves a Galaxy Space block by registry name, at the moment it is actually needed.
     *
     * <p>Returns null - never Forge's air placeholder - while the block does not exist, and caches
     * a hit, because a block that was registered once stays registered.
     */
    private static Supplier<Block> lazyBlock(String registryPath) {
        final ResourceLocation id = new ResourceLocation(
                MinespaceGalaxySpacePlanets.GALAXY_SPACE_MOD_ID, registryPath);
        return new Supplier<Block>() {
            private Block resolved;

            @Override
            public Block get() {
                if (resolved == null) {
                    Block found = ForgeRegistries.BLOCKS.getValue(id);
                    if (found == null || found == net.minecraft.init.Blocks.AIR) {
                        return null;
                    }
                    resolved = found;
                }
                return resolved;
            }
        };
    }
}
