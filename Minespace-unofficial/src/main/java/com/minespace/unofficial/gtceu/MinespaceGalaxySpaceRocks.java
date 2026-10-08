package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import net.minecraft.block.Block;
import net.minecraft.block.material.Material;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * This mod's own copies of Galaxy Space's planet rocks, one per celestial body.
 *
 * <p>Exactly the reason {@link MinespacePlanetRocks} exists for Mars, Venus and the asteroids:
 * GregTech draws an ore as "the stone type's block state, with the ore texture on top", so the
 * ore base has to be a block whose model this mod controls. Each block here is a plain
 * {@code block/cube_all} cube textured with that body's rock texture, copied out of Galaxy
 * Space's own assets ({@code assets/galaxyspace/textures/blocks/<system>/<body>/*.png}) into
 * {@code assets/minespace/textures/blocks/<key>_rock.png}.
 *
 * <p>Registered at {@link EventPriority#HIGHEST} so the blocks exist before
 * {@link MinespaceGalaxySpaceStones} builds the stone types from them at {@code HIGH}.
 * Without Galaxy Space nothing is registered at all.
 */
@Mod.EventBusSubscriber(modid = Minespace.MOD_ID)
public final class MinespaceGalaxySpaceRocks {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private static final Map<String, Block> BLOCKS = new LinkedHashMap<>();

    private MinespaceGalaxySpaceRocks() {
    }

    @SubscribeEvent(priority = EventPriority.HIGHEST)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
        if (!Loader.isModLoaded(MinespaceGalaxySpacePlanets.GALAXY_SPACE_MOD_ID)) {
            return;
        }
        for (MinespaceGalaxySpacePlanets.Planet planet : MinespaceGalaxySpacePlanets.PLANETS) {
            ResourceLocation id = new ResourceLocation(Minespace.MOD_ID, planet.rockName());
            Block block = new Block(Material.ROCK);
            block.setRegistryName(id);
            block.setUnlocalizedName(Minespace.MOD_ID + "." + planet.rockName());
            block.setHardness(1.5F);
            block.setResistance(6.0F);
            event.getRegistry().register(block);
            BLOCKS.put(planet.key, block);
        }
        LOG.info("Registered {} Galaxy Space rock blocks for GregTech ore bases", BLOCKS.size());
    }

    /**
     * The state GregTech draws as the ore base for one body, resolved lazily because GT may only
     * ask for it as late as model baking. A missing block yields null (nothing drawn) rather
     * than a crash.
     */
    public static IBlockState defaultState(MinespaceGalaxySpacePlanets.Planet planet) {
        Block block = BLOCKS.get(planet.key);
        if (block == null) {
            block = ForgeRegistries.BLOCKS.getValue(
                    new ResourceLocation(Minespace.MOD_ID, planet.rockName()));
        }
        if (block == null) {
            LOG.error("Rock block '{}' is not registered - ores on {} will have no base to draw",
                    planet.rockName(), planet.key);
            return null;
        }
        return block.getDefaultState();
    }
}
