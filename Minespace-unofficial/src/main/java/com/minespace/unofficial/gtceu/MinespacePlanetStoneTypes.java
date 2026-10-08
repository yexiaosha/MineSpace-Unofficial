package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.unification.material.Material;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import gregtech.common.blocks.BlockOre;
import gregtech.common.blocks.MetaBlocks;
import net.minecraft.block.Block;
import net.minecraft.block.SoundType;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;

/**
 * GTCEu stone types for the Galacticraft planet rocks (Mars, Venus, Asteroids).
 *
 * <p>Same problem and same timing constraints as {@link MinespaceStoneTypes}: an ore is
 * drawn as "base model + ore overlay", and the filler picks the ore variant by looking the
 * overwritten block's {@link StoneType} up, falling back to the overworld stone look for
 * anything GT does not know. Registering a type is the only way to make the planet ores
 * render on their own rock, and it has to happen from the block registry event at
 * {@link EventPriority#HIGH} — after Galacticraft's blocks exist, before GTCEu builds its
 * ore blocks at the default priority.
 */
@Mod.EventBusSubscriber(modid = Minespace.MOD_ID)
public final class MinespacePlanetStoneTypes {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** Ids 0..15 are GT's own stone types, 16 is the Lunar one, so these follow. */
    private static final int MARS_STONE_TYPE_ID = 17;
    private static final int VENUS_STONE_TYPE_ID = 18;
    private static final int ASTEROID_STONE_TYPE_ID = 19;

    private static final List<String> REGISTERED = new ArrayList<>();
    private static boolean registered;

    private MinespacePlanetStoneTypes() {
    }

    @SubscribeEvent(priority = EventPriority.HIGH)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
        if (registered) {
            return;
        }
        // The planet rocks live in the planets module, not in core, so both have to be
        // present before this class may touch BlockBasicMars/Venus/Asteroids.
        if (!Minespace.hasGalacticraft()
                || !net.minecraftforge.fml.common.Loader.isModLoaded("galacticraftplanets")) {
            LOG.info("Galacticraft planets not present — skipping the Mars/Venus/Asteroid stone types");
            return;
        }
        register(MARS_STONE_TYPE_ID, MinespaceMaterials.MARS_STONE,
                MinespacePlanetRocks.MARS_ROCK,
                com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones.marsStonePredicate());
        register(VENUS_STONE_TYPE_ID, MinespaceMaterials.VENUS_STONE,
                MinespacePlanetRocks.VENUS_ROCK,
                com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones.venusStonePredicate());
        register(ASTEROID_STONE_TYPE_ID, MinespaceMaterials.ASTEROID_STONE,
                MinespacePlanetRocks.ASTEROID_ROCK,
                com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones.asteroidStonePredicate());
        registered = true;
    }

    private static void register(int typeId, String materialName, ResourceLocation baseId,
                                 Predicate<IBlockState> predicate) {
        Material material = MinespaceMaterials.lookup(materialName);
        if (material == null) {
            LOG.error("Material '{}' is missing, so its stone type cannot be built. "
                    + "It must be registered from MaterialEvent.", materialName);
            return;
        }

        new StoneType(
                typeId,
                materialName,
                SoundType.STONE,
                OrePrefix.ore,
                material,
                () -> MinespacePlanetRocks.defaultState(baseId),
                predicate,
                false);

        REGISTERED.add(materialName);
        LOG.info("Registered GTCEu stone type '{}' (id {}) — ores there now use the '{}' base",
                materialName, typeId, baseId);
    }

    /**
     * Confirms the registration actually took, on the first client tick (see
     * {@link MinespaceModelCheck}). Two things are checked, because they fail
     * independently: that GTCEu added the type to its ore blocks, and that the base block
     * has a baked model for GT's renderer to draw.
     */
    public static void probeOreModels() {
        if (REGISTERED.isEmpty()) {
            return;
        }
        try {
            net.minecraft.client.renderer.BlockRendererDispatcher dispatcher =
                    net.minecraft.client.Minecraft.getMinecraft().getBlockRendererDispatcher();

            for (String name : REGISTERED) {
                boolean onOreBlock = false;
                for (BlockOre ore : MetaBlocks.ORES) {
                    for (StoneType type : ore.STONE_TYPE.getAllowedValues()) {
                        if (name.equals(type.name)) {
                            onOreBlock = true;
                            break;
                        }
                    }
                    if (onOreBlock) {
                        break;
                    }
                }
                if (onOreBlock) {
                    LOG.info("Verified: GTCEu gave its ore blocks a '{}' variant", name);
                } else {
                    LOG.error("GTCEu did not add the '{}' stone type to any ore block — "
                            + "the block-registry listener ran too late.", name);
                }
            }

            // Positive control, then the three bases.
            MinespaceOreModelProbe.probeVanillaStone(dispatcher);
            MinespaceOreModelProbe.probe(dispatcher, "minespace:mars_rock", MinespacePlanetRocks.defaultState(MinespacePlanetRocks.MARS_ROCK));
            MinespaceOreModelProbe.probe(dispatcher, "minespace:venus_rock", MinespacePlanetRocks.defaultState(MinespacePlanetRocks.VENUS_ROCK));
            MinespaceOreModelProbe.probe(dispatcher, "minespace:asteroid_rock", MinespacePlanetRocks.defaultState(MinespacePlanetRocks.ASTEROID_ROCK));
        } catch (Throwable t) {
            LOG.warn("Could not probe the planet ore models: {}", t.toString());
        }
    }
}
