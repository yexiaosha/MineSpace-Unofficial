package com.minespace.unofficial.navigation;

import com.minespace.unofficial.gtceu.MinespacePlanetDimensionsRegistration;
import com.minespace.unofficial.gtceu.MinespacePlanetTerrainPrototype;
import micdoodle8.mods.galacticraft.api.GalacticraftRegistry;
import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.vector.Vector3;
import micdoodle8.mods.galacticraft.api.world.ITeleportType;
import micdoodle8.mods.galacticraft.core.entities.EntityLander;
import micdoodle8.mods.galacticraft.core.entities.player.GCPlayerStats;
import micdoodle8.mods.galacticraft.core.util.CompatibilityManager;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.WorldProvider;
import net.minecraft.world.WorldServer;

import java.util.Random;

/**
 * Galacticraft's arrival contract for the dimensions this pack registered itself.
 *
 * <p>Galaxy Space does not re-implement the arrival screen or the descent. It registers one
 * {@link ITeleportType} per body, and Galacticraft's {@code WorldUtil.transferEntityToDimension} reads it:
 * the type chooses the spawn height, says whether a parachute is used, and is told when the player has
 * changed dimension. Galaxy Space's implementations return a high spawn (y=900) and, in
 * {@code onSpaceDimensionChanged}, spawn an {@code EntityLander} that the player rides down. That is the
 * landing the player sees.</p>
 *
 * <p>This is the same contract for the providers this pack owns. It is intentionally registered by
 * provider class, because that is how Galacticraft looks a teleport type up. The shared void provider and
 * the one terrain prototype are separate classes, so both are registered.</p>
 */
public final class MinespacePlanetTeleportType implements ITeleportType {

    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation");

    /** Galaxy Space's arrival altitude: high enough for the lander's descent to be visible. */
    private static final double ARRIVAL_Y = 900.0D;

    private static boolean registered;

    private MinespacePlanetTeleportType() {
    }

    /** The altitude a fallback arrival starts its lander descent from. */
    public static double arrivalY() {
        return ARRIVAL_Y;
    }

    /** Registers the type for every provider this pack registers. Idempotent. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;
        GalacticraftRegistry.registerTeleportType(
                MinespacePlanetDimensionsRegistration.VoidProvider.class,
                new MinespacePlanetTeleportType());
        GalacticraftRegistry.registerTeleportType(
                MinespacePlanetTerrainPrototype.RockProvider.class,
                new MinespacePlanetTeleportType());
        LOG.info("Registered Galacticraft teleport types for the pack's void and rock providers "
                + "(GC transfer + EntityLander arrival)");
    }

    /**
     * Diagnostic only: with {@code -Dminespace.probeDimension=<id>} this loads one dimension and reports the
     * provider class and teleport type the world actually resolves to. Used to verify World Engine addons whose
     * declared provider class is not what Forge instantiates.
     */
    public static void probeIfRequested() {
        String requested = System.getProperty("minespace.probeDimension");
        if (requested == null || requested.isEmpty()) {
            return;
        }
        try {
            int dimensionId = Integer.parseInt(requested);
            WorldServer world = net.minecraftforge.common.DimensionManager.getWorld(dimensionId, false);
            if (world == null) {
                net.minecraftforge.common.DimensionManager.initDimension(dimensionId);
                world = net.minecraftforge.common.DimensionManager.getWorld(dimensionId, false);
            }
            if (world == null) {
                LOG.warn("arrival probe: dimension {} did not produce a world", Integer.valueOf(dimensionId));
                return;
            }
            @SuppressWarnings("unchecked")
            Class<? extends WorldProvider> actual =
                    (Class<? extends WorldProvider>) (Class<?>) world.provider.getClass();
            ITeleportType type = GalacticraftRegistry.getTeleportTypeForDimension(actual);
            CelestialBody body = com.minespace.unofficial.galacticraft.MinespacePlanetResearch
                    .bodyKnownToGalacticraft(dimensionId);
            Class<? extends WorldProvider> declared = body == null ? null : body.getWorldProvider();
            LOG.info("arrival probe: dim={} actual={} declared={} typeForActual={} typeForDeclared={}",
                    Integer.valueOf(dimensionId), actual.getName(),
                    declared == null ? "(none)" : declared.getName(),
                    type == null ? "(none)" : type.getClass().getName(),
                    declared == null ? "(none)" : String.valueOf(
                            GalacticraftRegistry.getTeleportTypeForDimension(declared)));
        } catch (Throwable t) {
            LOG.warn("arrival probe failed for dimension {}", requested, t);
        }
    }

    @Override
    public boolean useParachute() {
        // Galaxy Space uses the lander on every body, atmosphere or not. A parachute is per teleport
        // type, not per player, so using the lander keeps this correct for airless bodies too.
        return false;
    }

    @Override
    public Vector3 getPlayerSpawnLocation(WorldServer world, EntityPlayerMP player) {
        BlockPos spawn = world.getSpawnPoint();
        return new Vector3(spawn.getX() + 0.5D, ARRIVAL_Y, spawn.getZ() + 0.5D);
    }

    @Override
    public Vector3 getEntitySpawnLocation(WorldServer world, Entity entity) {
        return new Vector3(entity.posX, ARRIVAL_Y, entity.posZ);
    }

    @Override
    public Vector3 getParaChestSpawnLocation(WorldServer world, EntityPlayerMP player, Random random) {
        return null;
    }

    @Override
    public void onSpaceDimensionChanged(World world, EntityPlayerMP player, boolean arrivedByRocket) {
        if (arrivedByRocket || player == null || world == null || world.isRemote) {
            return;
        }
        spawnLander(world, player);
    }

    /**
     * Starts the lander descent at the player's current position.
     *
     * <p>Also used by the fallback arrival path, so a destination whose provider cannot be matched to a
     * Galacticraft teleport type still gets the same visible capsule instead of the player simply standing
     * on the surface.</p>
     */
    public static void spawnLander(World world, EntityPlayerMP player) {
        if (player == null || world == null || world.isRemote) {
            return;
        }
        GCPlayerStats stats = GCPlayerStats.get(player);
        if (stats.getTeleportCooldown() > 0) {
            return;
        }
        if (player.capabilities.isFlying) {
            player.capabilities.isFlying = false;
            player.sendPlayerAbilities();
        }

        // This is Galaxy Space's arrival sequence verbatim: spawn the lander at the player, let it take
        // the player as its rider, and keep the chunks around it loaded while it descends.
        EntityLander lander = new EntityLander(player);
        lander.ignoreFrustumCheck = true;
        boolean forceLoaded = false;
        if (world instanceof WorldServer) {
            forceLoaded = CompatibilityManager.forceLoadChunks((WorldServer) world);
        }
        world.spawnEntity(lander);
        if (world instanceof WorldServer) {
            CompatibilityManager.forceLoadChunksEnd((WorldServer) world, forceLoaded);
        }
        stats.setTeleportCooldown(10);
    }

    @Override
    public void setupAdventureSpawn(EntityPlayerMP player) {
        // Nothing to reserve: the body's own spawn point is where the lander starts.
    }
}
