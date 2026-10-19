package com.minespace.unofficial.gtceu;

import net.minecraft.block.state.IBlockState;
import net.minecraft.server.MinecraftServer;
import net.minecraft.util.ResourceLocation;
import net.minecraft.world.WorldServer;
import net.minecraft.world.chunk.Chunk;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.Map;
import java.util.TreeMap;

/**
 * Diagnostic-only worldgen scanner, enabled with
 * {@code -Dminespace.probeWorldgen=true}. It generates a square of overworld chunks
 * (radius configurable with {@code -Dminespace.probeRadius=N}) and writes
 * {@code worldgen-probe.csv} with the number of GT/BYG ore blocks actually present.
 *
 * <p>This is the tool used to answer "are all the configured veins being generated?"
 * without asking a player to fly around the world.</p>
 */
public final class MinespaceWorldgenProbe {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    private MinespaceWorldgenProbe() {
    }

    public static void runIfRequested(MinecraftServer server) {
        if (!Boolean.getBoolean("minespace.probeWorldgen")) {
            return;
        }
        WorldServer world = server.worlds[0];
        int radius = Integer.getInteger("minespace.probeRadius", 6);
        Map<String, Integer> counts = new TreeMap<>();

        // Generate terrain first, then populate. Populating one chunk while its neighbours
        // are absent is what causes GT's 3x3 vein writes to land on unloaded chunks.
        for (int x = -radius; x <= radius; x++) {
            for (int z = -radius; z <= radius; z++) {
                world.getChunkFromChunkCoords(x, z);
            }
        }
        for (int x = -radius; x <= radius; x++) {
            for (int z = -radius; z <= radius; z++) {
                Chunk chunk = world.getChunkFromChunkCoords(x, z);
                if (!chunk.isPopulated()) {
                    chunk.populate(world.getChunkProvider(),
                            world.getChunkProvider().chunkGenerator);
                }
            }
        }

        for (int x = -radius; x <= radius; x++) {
            for (int z = -radius; z <= radius; z++) {
                Chunk chunk = world.getChunkFromChunkCoords(x, z);
                for (int y = 0; y < 256; y++) {
                    for (int lx = 0; lx < 16; lx++) {
                        for (int lz = 0; lz < 16; lz++) {
                            IBlockState state = chunk.getBlockState(lx, y, lz);
                            if (state == null || state.getBlock() == net.minecraft.init.Blocks.AIR) {
                                continue;
                            }
                            ResourceLocation id = ForgeRegistries.BLOCKS.getKey(state.getBlock());
                            if (id == null) {
                                continue;
                            }
                            String key = id.toString();
                            if (key.startsWith("gregtech:ore_") || key.startsWith("byg:")
                                    && key.endsWith("_ore")) {
                                counts.merge(key, 1, Integer::sum);
                            }
                        }
                    }
                }
            }
        }

        File out = new File(world.getSaveHandler().getWorldDirectory(), "worldgen-probe.csv");
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(out))) {
            writer.write("block,count\n");
            for (Map.Entry<String, Integer> entry : counts.entrySet()) {
                writer.write(entry.getKey());
                writer.write(',');
                writer.write(Integer.toString(entry.getValue()));
                writer.newLine();
            }
        } catch (Throwable t) {
            LOG.warn("worldgen probe could not write {}: {}", out, t.toString());
        }
        LOG.info("Worldgen probe: {} ore types, {} ore blocks in {}x{} chunks -> {}",
                counts.size(), counts.values().stream().mapToInt(Integer::intValue).sum(),
                radius * 2 + 1, radius * 2 + 1, out.getAbsolutePath());
    }
}
