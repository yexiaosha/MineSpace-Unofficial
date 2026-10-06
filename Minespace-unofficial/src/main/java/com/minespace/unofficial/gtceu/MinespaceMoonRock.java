package com.minespace.unofficial.gtceu;

import net.minecraft.block.Block;
import net.minecraft.block.material.Material;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * The block a Lunar ore draws its base from.
 *
 * <h2>Why this exists instead of using Galacticraft's own block</h2>
 *
 * GT renders an ore as "the stone type's block state model, with the ore texture drawn on
 * top" ({@code OreBakedModel.getBaseModel} → {@code BlockRendererDispatcher.getModelForState}).
 * Pointing that at Galacticraft's {@code galacticraftcore:basic_block_moon} looked like the
 * obvious move, and it does not work: the ore comes out on the wrong base. Owning the block
 * removes the whole class of problem — the blockstate and model below are direct, vanilla
 * {@code block/cube_all} assets from this mod, so there is nothing environment-specific
 * left for the renderer to resolve.
 *
 * <p>The texture is Galacticraft's real Moon Rock ({@code galacticraftcore:blocks/bottom},
 * the sprite its {@code basictypemoon=moon_stone} model points at), copied into this mod's
 * assets so the ore looks like the terrain it is embedded in.
 *
 * <h2>Registration</h2>
 *
 * Registered from the block registry event at {@link EventPriority#HIGH}, so it exists
 * before {@link MinespaceStoneTypes} builds the stone type from it. Like the stone type,
 * this is far too late for {@code new Block(...)} to be a field initialiser, which is why
 * it is constructed here rather than declared {@code static final}.
 *
 * <p>Deliberately absent from the creative tabs: it is a render base for ores, not a block
 * anyone is meant to place.
 */
@Mod.EventBusSubscriber(modid = com.minespace.unofficial.Minespace.MOD_ID)
public final class MinespaceMoonRock {

    private static final Logger LOG = LogManager.getLogger("minespace");

    public static final ResourceLocation ID =
            new ResourceLocation(com.minespace.unofficial.Minespace.MOD_ID, "moon_rock");

    private static Block block;

    private MinespaceMoonRock() {
    }

    @SubscribeEvent(priority = EventPriority.HIGHEST)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
        Block moonRock = new Block(Material.ROCK);
        moonRock.setRegistryName(ID);
        moonRock.setUnlocalizedName(com.minespace.unofficial.Minespace.MOD_ID + ".moon_rock");
        moonRock.setHardness(1.5F);
        moonRock.setResistance(6.0F);
        event.getRegistry().register(moonRock);
        block = moonRock;
    }

    /** The registered block, or null before the block registry event has run. */
    public static Block block() {
        if (block != null) {
            return block;
        }
        // Falls back to the registry so callers are not order-dependent.
        return ForgeRegistries.BLOCKS.getValue(ID);
    }

    /**
     * The state GT draws as the ore base. Resolved lazily, because GT may only ask for it
     * as late as model baking.
     */
    public static IBlockState defaultState() {
        Block registered = block();
        if (registered == null) {
            LOG.error("Block '{}' is not registered — Lunar ores will have no base to draw",
                    ID);
            return null;
        }
        return registered.getDefaultState();
    }

    /** True when this mod's render base is available. */
    public static boolean isAvailable() {
        return block() != null;
    }
}
