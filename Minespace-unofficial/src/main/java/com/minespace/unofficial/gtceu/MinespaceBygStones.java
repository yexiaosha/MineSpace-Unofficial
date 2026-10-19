package com.minespace.unofficial.gtceu;

import gregtech.api.unification.material.Materials;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import net.minecraft.block.Block;
import net.minecraft.block.SoundType;
import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * GT stone types for the underground rocks BYG uses in its special biomes.
 *
 * <p>Most BYG biomes sit on vanilla stone, which GT already knows. Dead Sea, the scoria/sepinite
 * canyons, soapstone and sodalite biomes replace that base with a BYG rock, and without a stone
 * type GT's vein predicate rejects every block there - the ore is simply absent. These types are
 * registered from {@link MinespaceMaterials#onMaterialsInit()}, before GT bakes its ore blocks,
 * with lazy block lookups because BYG registers its blocks later.</p>
 */
public final class MinespaceBygStones {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static final String BYG = "byg";
    private static final int FIRST_STONE_TYPE_ID = 40;

    private static final String[] STONE_NAMES = {
            "rocky_stone", "scoria", "sepinite", "soapstone", "sodalite"
    };

    private static boolean registered;

    private MinespaceBygStones() {
    }

    public static void register() {
        if (registered || !Loader.isModLoaded(BYG)) {
            return;
        }
        registered = true;

        int id = FIRST_STONE_TYPE_ID;
        int count = 0;
        for (String name : STONE_NAMES) {
            while (StoneType.STONE_TYPE_REGISTRY.getObjectById(id) != null) {
                id++;
            }
            Supplier<Block> rock = lazyBlock(name);
            Predicate<IBlockState> predicate = state -> {
                Block block = rock.get();
                return block != null && state.getBlock() == block;
            };
            new StoneType(
                    id,
                    "byg_" + name,
                    new ResourceLocation(BYG, "blocks/" + name),
                    SoundType.STONE,
                    OrePrefix.ore,
                    Materials.Stone,
                    "pickaxe",
                    0,
                    () -> {
                        Block block = rock.get();
                        return block == null ? Blocks.STONE.getDefaultState() : block.getDefaultState();
                    },
                    predicate);
            count++;
            id++;
        }
        LOG.info("Registered {} BYG stone types - GT veins can generate in BYG's special rocks",
                count);
    }

    private static Supplier<Block> lazyBlock(String name) {
        final ResourceLocation id = new ResourceLocation(BYG, name);
        return new Supplier<Block>() {
            private Block resolved;

            @Override
            public Block get() {
                if (resolved == null) {
                    Block found = ForgeRegistries.BLOCKS.getValue(id);
                    if (found == null || found == Blocks.AIR) {
                        return null;
                    }
                    resolved = found;
                }
                return resolved;
            }
        };
    }
}
