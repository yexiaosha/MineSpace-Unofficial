package com.minespace.unofficial.gtceu;

import gregtech.api.worldgen.config.OreDepositDefinition;
import gregtech.api.worldgen.config.WorldGenRegistry;
import gregtech.api.worldgen.filler.BlockFiller;
import gregtech.api.worldgen.populator.IVeinPopulator;

import java.util.IdentityHashMap;
import java.util.Map;

/** Maps GT's filler/populator instances back to the vein file that owns them, for diagnostics. */
public final class MinespaceVeinSource {

    private static final Map<BlockFiller, String> FILLERS = new IdentityHashMap<>();
    private static final Map<IVeinPopulator, String> POPULATORS = new IdentityHashMap<>();

    private MinespaceVeinSource() {
    }

    public static void index() {
        FILLERS.clear();
        POPULATORS.clear();
        for (OreDepositDefinition definition : WorldGenRegistry.getOreDeposits()) {
            if (definition.getBlockFiller() != null) {
                FILLERS.put(definition.getBlockFiller(), definition.getDepositName());
            }
            if (definition.getVeinPopulator() != null) {
                POPULATORS.put(definition.getVeinPopulator(), definition.getDepositName());
            }
        }
    }

    public static String filler(BlockFiller value) {
        return FILLERS.getOrDefault(value, "<unknown filler>");
    }

    public static String populator(IVeinPopulator value) {
        return POPULATORS.getOrDefault(value, "<unknown populator>");
    }
}
