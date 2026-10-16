package com.minespace.unofficial.galacticraft;

import micdoodle8.mods.galacticraft.api.prefab.entity.EntityAutoRocket;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraft.util.text.TextComponentString;
import net.minecraft.util.text.TextFormatting;

import java.util.Map;
import java.util.WeakHashMap;

/**
 * Where a rocket aimed from the star map is going, and what happens when Galacticraft asks.
 *
 * <h2>Why Galacticraft's own route cannot be used as-is</h2>
 *
 * `EntityTieredRocket.onReachAtmosphere()` decides with one test: if {@code destinationFrequency == -1} the rocket has
 * no destination, and Galacticraft opens its celestial screen for the player to pick one. A frequency, though, is a
 * **landing pad** - Galacticraft's routes are pad to pad, resolved through
 * {@code setTarget(true, destinationFrequency)} - and the bodies this pack owns have no pads and are not in Galacticraft's
 * registry. So a preset {@code targetDimension} is not enough: it is overwritten by the screen, which is exactly what
 * the owner saw twice ("发射升空之后还是弹出 GS 的星图").
 *
 * <h2>What happens instead</h2>
 *
 * The rocket is Galacticraft's for the whole ascent - ignition, fuel, the flight up, the sound, the phase changes.
 * At the moment Galacticraft would ask for a destination, {@link MixinEntityTieredRocket} checks whether this rocket
 * was aimed from the star map; if it was, the screen is cancelled and **this class moves the player to the planet**.
 * That is the split the owner asked for: GC flies, the pack's own map aims, and the part that does not exist in
 * Galacticraft - a destination with no pad - is ours.
 *
 * <p>The map is keyed weakly on the rocket entity, so a rocket that lands, dies or unloads does not keep an entry
 * alive; the destination only ever matters during one ascent.</p>
 */
public final class MinespaceRocketDestinations {

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
     * The arrival: the player leaves the rocket and appears on the planet.
     *
     * <p>The rocket itself stays where it was. Moving it too would mean reimplementing Galacticraft's ship transfer -
     * its pad lookup, its landing sequence, its cargo - and a rocket that is left behind is a rocket the owner can
     * find again; a ship that half-transferred is a bug report. Recorded here because it is a deliberate limit of this
     * first version rather than an oversight.</p>
     */
    public static void transfer(EntityPlayerMP player, int dimensionId, String bodyName) {
        player.dismountRidingEntity();
        if (player.dimension == dimensionId) {
            player.sendMessage(new TextComponentString(
                    TextFormatting.YELLOW + "你已经在 " + bodyName + " 上了"));
            return;
        }
        if (!net.minecraftforge.common.DimensionManager.isDimensionRegistered(dimensionId)) {
            // The last line of defence before Minecraft's own transfer, which reads the world for a dimension id and
            // finds nothing: see MinespaceRocketTarget.apply, which refuses the same case earlier with the same reason.
            player.sendMessage(new TextComponentString(TextFormatting.RED + "无法抵达 " + bodyName
                    + "：这个世界还没建成（维度 " + dimensionId + " 未注册）"));
            return;
        }
        player.changeDimension(dimensionId);
        player.sendMessage(new TextComponentString(
                TextFormatting.GREEN + "已抵达 " + bodyName + "（火箭留在原地）"));
    }
}
