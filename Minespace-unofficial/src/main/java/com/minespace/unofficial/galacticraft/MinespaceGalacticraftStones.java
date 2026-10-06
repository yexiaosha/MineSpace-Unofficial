package com.minespace.unofficial.galacticraft;

import gregtech.api.unification.ore.StoneType;
import micdoodle8.mods.galacticraft.core.blocks.BlockBasicMoon;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.registry.ForgeRegistries;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * The Galacticraft half of the Lunar stone type.
 *
 * <p>This class exists purely to keep Galacticraft types out of
 * {@code com.minespace.unofficial.gtceu.MinespaceStoneTypes}. Galacticraft is declared
 * {@code after:galacticraftcore}, so it may be absent, and a constant pool reference to
 * {@code micdoodle8.mods.galacticraft.*} in an always-loaded class is exactly how an
 * optional integration turns into a {@code NoClassDefFoundError}. Callers must
 * therefore check {@code Minespace.hasGalacticraft()} before touching anything here.
 *
 * <h2>What the two functions are for</h2>
 *
 * A GT {@link StoneType} is built from two block-related pieces:
 *
 * <ul>
 *   <li><b>stone</b> — a block <em>state</em>, not a texture name. GT's ore renderer
 *       resolves this state's baked model and draws it as the ore's base
 *       ({@code OreBakedModel.getBaseModel}), then overlays the material's ore texture.
 *       Handing it the real Moon Rock state is what makes the ore look like Moon Rock
 *       instead of overworld stone, and it needs no assets of our own: Galacticraft's
 *       {@code basic_block_moon} blockstate maps {@code basictypemoon=moon_stone} to
 *       {@code moon_stone_model}, which is a plain cube textured
 *       {@code galacticraftcore:blocks/bottom}.</li>
 *   <li><b>predicate</b> — asked, at worldgen time, whether a block a vein is about to
 *       overwrite counts as this stone type. This is what makes
 *       {@code StoneType.computeStoneType} resolve the Lunar type, and therefore what
 *       selects the Lunar ore variant in the filler's stone-type map.</li>
 * </ul>
 *
 * <p>Nothing here is guessed: {@code BlockBasicMoon.isReplaceableOreGen} returns true for
 * {@code MOON_STONE} and {@code MOON_DIRT}, which is Galacticraft explicitly declaring
 * those two as ore-gen targets. The other six variants (ores, turf, dungeon brick) are
 * left alone so they do not each drag in a pointless stone type.
 */
public final class MinespaceGalacticraftStones {

    /** Galacticraft's block id, matching GT's {@code block:galacticraftcore:basic_block_moon}. */
    public static final ResourceLocation MOON_ROCK = new ResourceLocation("galacticraftcore", "basic_block_moon");

    private MinespaceGalacticraftStones() {
    }

    /**
     * The state GT draws as the ore's base: the plain Moon Rock variant.
     *
     * <p>The lookup happens inside the returned lambda rather than here, both because GT
     * may only call it as late as model baking and so that a missing block yields a null
     * state (nothing drawn) instead of a crash at registration time.
     */
    public static Supplier<IBlockState> moonRockBase() {
        return () -> {
            net.minecraft.block.Block block = ForgeRegistries.BLOCKS.getValue(MOON_ROCK);
            return block == null ? null : block.getDefaultState();
        };
    }

    /**
     * True for the two Lunar variants Galacticraft itself marks as replaceable by ore
     * generation: {@code moon_stone} and {@code moon_dirt_moon}.
     */
    public static Predicate<IBlockState> moonStonePredicate() {
        return state -> {
            if (!(state.getBlock() instanceof BlockBasicMoon)) {
                return false;
            }
            BlockBasicMoon.EnumBlockBasicMoon variant = state.getValue(BlockBasicMoon.BASIC_TYPE_MOON);
            return variant == BlockBasicMoon.EnumBlockBasicMoon.MOON_STONE
                    || variant == BlockBasicMoon.EnumBlockBasicMoon.MOON_DIRT;
        };
    }
}
