package com.minespace.unofficial.navigation;

import com.minespace.unofficial.galacticraft.MinespacePlanetResearch;
import micdoodle8.mods.galacticraft.api.GalacticraftRegistry;
import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntityAutoRocket;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntitySpaceshipBase;
import micdoodle8.mods.galacticraft.api.world.ITeleportType;
import micdoodle8.mods.galacticraft.core.util.WorldUtil;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityList;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraft.nbt.NBTTagCompound;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.text.TextComponentString;
import net.minecraft.util.text.TextFormatting;
import net.minecraft.world.World;
import net.minecraft.world.WorldProvider;
import net.minecraft.world.WorldServer;

import java.util.Map;
import java.util.WeakHashMap;

/**
 * Where a rocket aimed from the star map is going, and what happens when Galacticraft asks.
 *
 * <h2>What is ours and what stays Galacticraft's</h2>
 *
 * <p>The rocket is Galacticraft's for the whole ascent - ignition, fuel, the flight up, the sound, the phase
 * changes. At the moment Galacticraft would open its celestial screen, the mixin on
 * {@code WorldUtil.toCelestialSelection} gives the choice to this pack's star map instead.</p>
 *
 * <p>The arrival is Galacticraft's too. {@link #transfer} loads the destination world and asks
 * {@code WorldUtil.transferEntityToDimension} to move the player, which reads the destination provider's
 * registered {@code ITeleportType}. Galaxy Space's bodies already have one; this pack's providers get one from
 * {@link MinespacePlanetTeleportType}. That is what produces the high spawn, the lander or ship descent, and
 * the loading screen sequence instead of a player suddenly standing on the surface.</p>
 *
 * <p>The map is keyed weakly on the rocket entity, so a rocket that lands, dies or unloads does not keep an entry
 * alive; the destination only ever matters during one ascent.</p>
 */
public final class MinespaceRocketDestinations {

    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace_navigation");

    private static final Map<EntityAutoRocket, Integer> PENDING = new WeakHashMap<EntityAutoRocket, Integer>();

    /**
     * The rockets that have already been asked once this flight.
     *
     * <p>Galacticraft calls {@code onReachAtmosphere} on **every tick** while the rocket is in the atmosphere, so the
     * first version of the bridge sent "open the star map" every tick as well - and the owner saw the map reopen
     * constantly ("能打开，但是一直闪烁"). One screen per flight is what a choice is.</p>
     */
    private static final java.util.Set<EntityAutoRocket> ASKED =
            java.util.Collections.newSetFromMap(new WeakHashMap<EntityAutoRocket, Boolean>());

    private MinespaceRocketDestinations() {
    }

    /** Remembers where this rocket is going, for the moment it reaches the atmosphere. */
    public static void aim(EntityAutoRocket rocket, int dimensionId) {
        synchronized (PENDING) {
            PENDING.put(rocket, Integer.valueOf(dimensionId));
        }
    }

    /** The destination this rocket was aimed at, or 0 when it was not aimed from the map. */
    public static int destination(EntityAutoRocket rocket) {
        synchronized (PENDING) {
            Integer value = PENDING.get(rocket);
            return value == null ? 0 : value.intValue();
        }
    }

    /** Forgets it once the flight is over, so a later GC flight from the same rocket is GC's business again. */
    public static void clear(EntityAutoRocket rocket) {
        synchronized (PENDING) {
            PENDING.remove(rocket);
        }
        synchronized (ASKED) {
            ASKED.remove(rocket);
        }
    }

    /** True the first time this rocket asks, false for every tick after that. */
    public static boolean firstAsk(EntityAutoRocket rocket) {
        synchronized (ASKED) {
            return ASKED.add(rocket);
        }
    }

    /**
     * The players this pack has asked "where do you want to go", with the tier of the rocket that asked.
     *
     * <h2>Why the question, and not the rocket (6ex)</h2>
     *
     * <p>An answered in-orbit choice used to be validated by the player still riding something - and 6ex measured what
     * that costs: the owner's map opened at the atmosphere, they browsed it for a minute, and by the time they pressed T
     * the flight was over and they were riding nothing, so the answer was refused with "get into a rocket". The
     * question this pack asked is the thing that authorises the answer, so it is remembered here - and remembering it
     * is also what keeps a client from claiming to be in orbit when it is not.</p>
     */
    private static final Map<java.util.UUID, Asked> ASKED_PLAYERS =
            new java.util.concurrent.ConcurrentHashMap<java.util.UUID, Asked>();

    /** How long an unanswered question stays valid: long enough to browse a chart, not a session. */
    private static final long ASK_TIMEOUT_TICKS = 12000L;

    /** One outstanding question: the tier of the rocket that asked, and when it was asked. */
    public static final class Asked {

        public final int tier;
        private final long askedAt;
        private final java.lang.ref.WeakReference<EntityAutoRocket> rocket;

        Asked(int tier, long askedAt, EntityAutoRocket rocket) {
            this.tier = tier;
            this.askedAt = askedAt;
            this.rocket = new java.lang.ref.WeakReference<EntityAutoRocket>(rocket);
        }

        EntityAutoRocket rocket() {
            return rocket.get();
        }
    }

    /** The tier of the rocket that asked this player, or 0 when this pack is not waiting for their answer. */
    public static int tierAwaitingAnswer(java.util.UUID playerId, long now) {
        Asked asked = ASKED_PLAYERS.get(playerId);
        if (asked == null) {
            return 0;
        }
        if (now - asked.askedAt > ASK_TIMEOUT_TICKS) {
            ASKED_PLAYERS.remove(playerId);
            return 0;
        }
        return asked.tier;
    }

    /**
     * The rocket that asked this player to choose, while it still exists.
     *
     * <p>The answer is authorised by the question (6ex), but the arrival still wants the ship when it is
     * there: Galacticraft then moves the ship with the player and lands it, the way Galaxy Space does.</p>
     */
    public static EntityAutoRocket rocketAwaitingAnswer(java.util.UUID playerId) {
        Asked asked = ASKED_PLAYERS.get(playerId);
        return asked == null ? null : asked.rocket();
    }

    /** The answer arrived: stop waiting for it. */
    public static void answered(java.util.UUID playerId) {
        ASKED_PLAYERS.remove(playerId);
    }

    /**
     * The arrival, through Galacticraft's own transfer when the destination knows how to receive a player.
     *
     * <h2>Why this is not a custom ITeleporter any more</h2>
     *
     * <p>Galaxy Space is a Galacticraft addon and does not re-implement arrival. Every body it adds registers
     * an {@code ITeleportType}; Galacticraft's {@code WorldUtil.transferEntityToDimension} reads that type and
     * lets it choose the spawn height, spawn the lander and run the after-arrival callback. The pack's earlier
     * {@code changeDimension(..., new MinespaceArrivalTeleporter())} skipped all of that, which is why the
     * player appeared standing on the surface instead of descending the way GC and GS do.</p>
     *
     * <p>The rocket is passed to Galacticraft when the player is actually riding it. In that case GC moves
     * the ship with the player and puts the player back in it; the ship is put into its landing phase first.
     * When the flight is already over, no rocket is passed and the destination's own teleport type spawns the
     * lander - the same route Galaxy Space uses when a player arrives without a ship.</p>
     */
    public static void transfer(EntityPlayerMP player, int dimensionId, String bodyName) {
        transfer(player, dimensionId, bodyName, null);
    }

    public static void transfer(EntityPlayerMP player, int dimensionId, String bodyName, EntityAutoRocket rocket) {
        if (player.dimension == dimensionId) {
            player.sendMessage(new TextComponentString(
                    TextFormatting.YELLOW + "你已经在 " + bodyName + " 上了"));
            return;
        }
        if (!net.minecraftforge.common.DimensionManager.isDimensionRegistered(dimensionId)
                || isStillVoid(dimensionId)) {
            // The last line of defence before Minecraft's own transfer, which reads the world for a dimension id and
            // finds nothing: see MinespaceRocketTarget.apply, which refuses the same case earlier with the same reason.
            player.sendMessage(new TextComponentString(TextFormatting.RED + "无法抵达 " + bodyName
                    + "：这个世界还没建成（维度 " + dimensionId + " 未注册）"));
            return;
        }
        int cameFrom = player.dimension;
        MinespaceNetwork.CHANNEL.sendTo(new MinespaceNetwork.TeleportingMessage(dimensionId), player);

        // Galacticraft's transfer needs the destination world to exist before it can read the provider's
        // teleport type. This is the same world creation changeDimension used to do, on the server thread.
        WorldServer targetWorld = null;
        try {
            // getWorld(id, true) only reloads an already-created world from Forge's map; it does not create one.
            // The destination has to be initialized here so Galacticraft's transfer can find it through
            // MinecraftServer.getWorld, which is what its own pads and worlds are normally already part of.
            targetWorld = net.minecraftforge.common.DimensionManager.getWorld(dimensionId, false);
            if (targetWorld == null) {
                net.minecraftforge.common.DimensionManager.initDimension(dimensionId);
                targetWorld = net.minecraftforge.common.DimensionManager.getWorld(dimensionId, false);
            }
        } catch (Throwable t) {
            LOG.warn("star map: loading destination world {} for {} failed", Integer.valueOf(dimensionId),
                    bodyName, t);
        }
        Class<? extends WorldProvider> actualProvider =
                targetWorld == null ? null : targetWorld.provider.getClass();
        ITeleportType teleportType = actualProvider == null ? null
                : GalacticraftRegistry.getTeleportTypeForDimension(actualProvider);
        CelestialBody knownBody = MinespacePlanetResearch.bodyKnownToGalacticraft(dimensionId);
        Class<? extends WorldProvider> declaredProvider =
                knownBody == null ? null : knownBody.getWorldProvider();
        if (teleportType == null && declaredProvider != null) {
            // World Engine providers are not always the class the addon registered its teleport type against:
            // Enceladus, for example, is a WorldProviderEnceladus_WE at registration time but can be seen as a
            // different WE provider once the world exists. Look the type up through the celestial body's declared
            // provider, then teach Galacticraft the same type for the class the world actually has.
            teleportType = GalacticraftRegistry.getTeleportTypeForDimension(declaredProvider);
            if (teleportType != null) {
                GalacticraftRegistry.registerTeleportType(actualProvider, teleportType);
                LOG.info("star map: mapped arrival type {} from declared provider {} to actual provider {}",
                        teleportType.getClass().getName(), declaredProvider.getName(), actualProvider.getName());
            }
        }
        LOG.info("star map: arrival to {} (dim {}) actualProvider={} declaredProvider={} teleportType={} rocket={}",
                bodyName, Integer.valueOf(dimensionId),
                actualProvider == null ? "(no world)" : actualProvider.getName(),
                declaredProvider == null ? "(none)" : declaredProvider.getName(),
                teleportType == null ? "(none)" : teleportType.getClass().getName(),
                rocket == null ? "(none)" : rocket.getClass().getName());
        if (targetWorld != null && teleportType != null) {
            // A multi-seat rocket puts a seat between the player and the ship; follow the chain, the same
            // way the launch side does (MinespaceRocketTarget.rocketRiddenBy).
            EntityAutoRocket ridden = rocket != null
                    && MinespaceRocketTarget.rocketRiddenBy(player) == rocket ? rocket : null;
            if (ridden != null) {
                prepareRocketLanding(ridden, targetWorld, dimensionId);
            }
            try {
                net.minecraft.entity.Entity arrived = WorldUtil.transferEntityToDimension(
                        player, dimensionId, targetWorld, false, ridden);
                if (arrived != null) {
                    if (ridden != null) {
                        player.sendMessage(new TextComponentString(
                                TextFormatting.GREEN + "已进入 " + bodyName + " 的着陆程序（火箭可回收）"));
                    } else {
                        if (rocket != null) {
                            bringRocketAlong(rocket, targetWorld, player);
                        }
                        player.sendMessage(new TextComponentString(
                                TextFormatting.GREEN + "已进入 " + bodyName + " 的着陆程序"
                                        + (rocket != null ? "（火箭可在着陆点回收）" : "")));
                    }
                    return;
                }
                LOG.warn("star map: Galacticraft declined the transfer to {} ({}); using the fallback",
                        bodyName, Integer.valueOf(dimensionId));
            } catch (Throwable t) {
                LOG.warn("star map: Galacticraft's arrival at {} ({}) failed - {}: {}",
                        bodyName, Integer.valueOf(dimensionId), t.getClass().getSimpleName(), t.getMessage(), t);
            }
        }

        if (player.getRidingEntity() != null) {
            player.dismountRidingEntity();
        }
        try {
            // No Galacticraft teleport type was available. Still give the player the same visible descent: place
            // them high, change dimension, then spawn the lander in the destination world.
            player.changeDimension(dimensionId, new MinespaceArrivalTeleporter(
                    MinespacePlanetTeleportType.arrivalY()));
        } catch (Throwable t) {
            // The respawn packet has already gone out - vanilla sends it before it places anybody - so a failure here
            // leaves the client on "Downloading terrain" while the server sits idle, which is the hang the owner hit
            // after 6ez. Send them back where they came from, through this pack's own placement, so they end up
            // standing somewhere real instead of nowhere at all.
            LOG.warn("star map: arriving at {} ({}) failed - {}: {}; sending the player back to {}",
                    bodyName, Integer.valueOf(dimensionId), t.getClass().getSimpleName(), t.getMessage(),
                    Integer.valueOf(cameFrom), t);
            try {
                MinespaceNetwork.CHANNEL.sendTo(new MinespaceNetwork.TeleportingMessage(cameFrom), player);
                player.changeDimension(cameFrom, new MinespaceArrivalTeleporter());
            } catch (Throwable back) {
                LOG.error("star map: and the way back to {} failed too", Integer.valueOf(cameFrom), back);
            }
            return;
        }
        if (player.world instanceof WorldServer) {
            MinespacePlanetTeleportType.spawnLander(player.world, player);
            if (rocket != null) {
                bringRocketAlong(rocket, (WorldServer) player.world, player);
            }
        }
        player.sendMessage(new TextComponentString(
                TextFormatting.GREEN + "已进入 " + bodyName + " 的着陆程序"
                        + (rocket != null ? "（火箭可在着陆点回收）" : "")));
    }

    /**
     * Gives a ship that is about to be moved a place to land and the phase that uses it.
     *
     * <p>Galacticraft's automatic landing needs a target block position and the LANDING phase. Our star map
     * destinations have no landing pad, so the target is the destination's own spawn column; the ship then
     * descends under GC's existing landing logic instead of being cloned into the sky in its launch phase.</p>
     */
    private static void prepareRocketLanding(EntityAutoRocket rocket, WorldServer targetWorld, int dimensionId) {
        // Land under the ship's own x/z, which is the column the player chose on the map. Using the world
        // spawn instead would make a ship that arrives far from 0,0 fly across the planet while descending.
        int x = MathHelper.floor(rocket.posX);
        int z = MathHelper.floor(rocket.posZ);
        int groundY = targetWorld.getSpawnPoint().getY();
        try {
            BlockPos top = targetWorld.getTopSolidOrLiquidBlock(new BlockPos(x, 0, z));
            if (top.getY() > 0) {
                groundY = top.getY();
            }
        } catch (Throwable ignored) {
            // The spawn height is a good enough target in a world whose chunks are still forming.
        }
        rocket.targetDimension = dimensionId;
        rocket.targetVec = new BlockPos(x, groundY, z);
        rocket.setLaunchPhase(EntitySpaceshipBase.EnumLaunchPhase.LANDING);
    }

    /**
     * Brings an unmanned rocket to the landing site so the player can recover it.
     *
     * <p>When the player arrives in a lander after the flight itself is over, the rocket no longer has a
     * rider to carry it through Galacticraft's transfer. Cloning its NBT into the destination and leaving it
     * unignited next to the landing site is the same entity GC would have landed, rather than silently
     * abandoning the ship in the origin world.</p>
     */
    private static void bringRocketAlong(EntityAutoRocket rocket, WorldServer targetWorld, EntityPlayerMP player) {
        if (rocket == null || rocket.isDead) {
            return;
        }
        try {
            // Put the recovered ship beside the pod's landing column, not at the world spawn, so the player
            // does not land hundreds of blocks away from the rocket they just flew.
            int x = MathHelper.floor(player.posX);
            int z = MathHelper.floor(player.posZ);
            BlockPos column = new BlockPos(x, 0, z);
            int groundY = targetWorld.getSpawnPoint().getY();
            BlockPos top = targetWorld.getTopSolidOrLiquidBlock(column);
            if (top.getY() > 0) {
                groundY = top.getY();
            }

            NBTTagCompound nbt = new NBTTagCompound();
            rocket.writeToNBT(nbt);
            Entity created = EntityList.createEntityFromNBT(nbt, targetWorld);
            if (!(created instanceof EntityAutoRocket)) {
                LOG.warn("star map: the flown rocket ({}) could not be recreated in {}; leaving it behind",
                        rocket.getClass().getName(), Integer.valueOf(targetWorld.provider.getDimension()));
                return;
            }
            EntityAutoRocket moved = (EntityAutoRocket) created;
            moved.setPad(null);
            moved.targetVec = null;
            moved.setLaunchPhase(EntitySpaceshipBase.EnumLaunchPhase.UNIGNITED);
            moved.targetDimension = targetWorld.provider.getDimension();
            moved.setLocationAndAngles(x + 2.5D, groundY + 1.0D, z + 2.5D, 0.0F, 0.0F);
            moved.motionX = 0.0D;
            moved.motionY = 0.0D;
            moved.motionZ = 0.0D;
            targetWorld.spawnEntity(moved);

            World source = rocket.world;
            if (source != null && source != targetWorld) {
                source.removeEntity(rocket);
            }
            rocket.setDead();
            LOG.info("star map: recovered the flown {} into {} at {}, {}, {}",
                    rocket.getClass().getSimpleName(), Integer.valueOf(targetWorld.provider.getDimension()),
                    Integer.valueOf(x + 2), Integer.valueOf(groundY + 1), Integer.valueOf(z + 2));
        } catch (Throwable t) {
            LOG.warn("star map: bringing the flown rocket along failed - {}: {}",
                    t.getClass().getSimpleName(), t.getMessage(), t);
        }
    }
    /**
     * True for a body whose world is registered but still the shared void provider.
     *
     * <p>Most of the planned bodies are in exactly that state (6dk: designed, not generated), and a player dropped into
     * one falls through nothing at all. A world that is not loaded yet answers false on purpose: the move itself is
     * what creates it.</p>
     */
    private static boolean isStillVoid(int dimensionId) {
        net.minecraft.world.WorldServer world =
                net.minecraftforge.common.DimensionManager.getWorld(dimensionId, false);
        return world != null && world.provider
                instanceof com.minespace.unofficial.gtceu.MinespacePlanetDimensionsRegistration.VoidProvider;
    }

    private static String nameOf(int dimensionId) {
        com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body =
        com.minespace.unofficial.navigation.MinespaceRocketTarget.bodyOf(dimensionId);
        return body == null ? ("维度 " + dimensionId) : body.name + "（" + body.nameZh + "）";
    }


    /**
     * The pack's answer to "where do you want to go", in place of Galacticraft's celestial screen (6ew).
     *
     * <p>Called from the one funnel every rocket in this pack reaches - Galacticraft's own tiered rockets and Galaxy
     * Space's overrides both ask through {@code WorldUtil.toCelestialSelection} - so this is the only place the choice
     * has to be taken over. The old per-rocket injection missed Galaxy Space entirely, because its tier-6 and
     * multi-seat rockets override {@code onReachAtmosphere} and never ran the parent's body: the owner launched,
     * and Galaxy Space's map appeared.</p>
     *
     * <p>Returns true when the pack answered. A rocket that was aimed before launch is taken straight there; one that
     * was not gets this pack's map, once per flight ({@link #firstAsk}).</p>
     */
    public static boolean takeOver(EntityPlayerMP player, EntityAutoRocket rocket) {
        int destination = destination(rocket);
        if (destination != 0) {
            transfer(player, destination, nameOf(destination), rocket);
            clear(rocket);
            return true;
        }
        if (firstAsk(rocket)) {
            ASKED_PLAYERS.put(player.getUniqueID(), new Asked(
                    rocket instanceof micdoodle8.mods.galacticraft.api.entity.IRocketType
                            ? ((micdoodle8.mods.galacticraft.api.entity.IRocketType) rocket).getRocketTier()
                            : 0,
                    player.world.getTotalWorldTime(), rocket));
            MinespaceNetwork.CHANNEL.sendTo(new MinespaceNetwork.OpenStarMapMessage(), player);
        }
        return true;
    }
}
