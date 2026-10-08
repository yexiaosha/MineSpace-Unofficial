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

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The blocks the Mars / Venus / Asteroid ores draw their base from.
 *
 * <p>Same reasoning and same shape as {@link MinespaceMoonRock}: GT renders an ore as
 * "the stone type's block state model, with the ore texture on top", so this mod owns a
 * plain {@code block/cube_all} block per planet and copies Galacticraft's own rock texture
 * into it. Owning the block removes the whole class of "the base state resolved to
 * something unexpected" problems.
 *
 * <p>Registered from the block registry event at {@link EventPriority#HIGHEST} so the
 * blocks exist before {@link MinespaceStoneTypes} / {@link MinespacePlanetStoneTypes} build
 * the stone types from them.
 */
@Mod.EventBusSubscriber(modid = com.minespace.unofficial.Minespace.MOD_ID)
public final class MinespacePlanetRocks {

    private static final Logger LOG = LogManager.getLogger("minespace");
    private static final String MOD_ID = com.minespace.unofficial.Minespace.MOD_ID;

    public static final ResourceLocation MARS_ROCK = new ResourceLocation(MOD_ID, "mars_rock");
    public static final ResourceLocation VENUS_ROCK = new ResourceLocation(MOD_ID, "venus_rock");
    public static final ResourceLocation ASTEROID_ROCK = new ResourceLocation(MOD_ID, "asteroid_rock");

    private static final Map<ResourceLocation, Block> BLOCKS = new LinkedHashMap<>();

    private MinespacePlanetRocks() {
    }

    @SubscribeEvent(priority = EventPriority.HIGHEST)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
        register(event, MARS_ROCK);
        register(event, VENUS_ROCK);
        register(event, ASTEROID_ROCK);
    }

    private static void register(RegistryEvent.Register<Block> event, ResourceLocation id) {
        Block block = new Block(Material.ROCK);
        block.setRegistryName(id);
        block.setUnlocalizedName(id.getResourceDomain() + "." + id.getResourcePath());
        block.setHardness(1.5F);
        block.setResistance(6.0F);
        event.getRegistry().register(block);
        BLOCKS.put(id, block);
    }

    /**
     * The state GT draws as the ore base, resolved lazily because GT may only ask for it
     * as late as model baking. A missing block yields null (nothing drawn) rather than a
     * crash.
     */
    public static IBlockState defaultState(ResourceLocation id) {
        Block block = BLOCKS.get(id);
        if (block == null) {
            block = ForgeRegistries.BLOCKS.getValue(id);
        }
        if (block == null) {
            LOG.error("Block '{}' is not registered — ores will have no base to draw", id);
            return null;
        }
        return block.getDefaultState();
    }
}
