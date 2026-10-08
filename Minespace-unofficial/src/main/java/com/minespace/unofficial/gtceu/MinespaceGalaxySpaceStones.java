package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.unification.material.Material;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import net.minecraft.block.Block;
import net.minecraft.block.SoundType;
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
 * <p>Timing is the same contract as {@link MinespaceStoneTypes}: this runs from the block
 * registry event at {@link EventPriority#HIGH}, after {@link MinespaceGalaxySpaceRocks}
 * registered the base blocks at {@link EventPriority#HIGHEST} and before GTCEu builds its ore
 * blocks at {@code NORMAL}. The materials were registered earlier still, from
 * {@code MaterialEvent}.
 */
@Mod.EventBusSubscriber(modid = Minespace.MOD_ID)
public final class MinespaceGalaxySpaceStones {

    private static final Logger LOG = LogManager.getLogger("minespace");

    private static boolean registered;

    private MinespaceGalaxySpaceStones() {
    }

    @SubscribeEvent(priority = EventPriority.HIGH)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
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
        Material material = MinespaceMaterials.lookup(planet.stoneName());
        if (material == null) {
            LOG.error("Material '{}' is missing, so {} gets no stone type", planet.stoneName(),
                    planet.key);
            return false;
        }

        Block spaceRock = ForgeRegistries.BLOCKS.getValue(
                new ResourceLocation(MinespaceGalaxySpacePlanets.GALAXY_SPACE_MOD_ID,
                        planet.gsBlock));
        if (spaceRock == null) {
            LOG.warn("Galaxy Space block '{}' is not in the registry - skipping {}",
                    planet.gsBlock, planet.key);
            return false;
        }

        Supplier<IBlockState> base = () -> MinespaceGalaxySpaceRocks.defaultState(planet);
        Predicate<IBlockState> predicate = state -> state.getBlock() == spaceRock;

        new StoneType(
                planet.stoneTypeId,
                planet.stoneName(),
                SoundType.STONE,
                OrePrefix.ore,
                material,
                base,
                predicate,
                false);
        return true;
    }
}
