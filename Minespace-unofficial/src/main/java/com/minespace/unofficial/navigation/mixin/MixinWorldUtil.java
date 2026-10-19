package com.minespace.unofficial.navigation.mixin;

import com.minespace.unofficial.navigation.MinespaceRocketDestinations;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntityAutoRocket;
import micdoodle8.mods.galacticraft.core.entities.player.GCPlayerStats;
import micdoodle8.mods.galacticraft.core.util.WorldUtil;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.EntityPlayerMP;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * The one funnel: every rocket that asks Galacticraft where to go asks here.
 *
 * <h2>Why this and not the rocket classes (6ew)</h2>
 *
 * <p>The first version injected into {@code EntityTieredRocket.onReachAtmosphere}, which is where Galacticraft's own
 * tiered rockets ask. Galaxy Space's do not use it: {@code EntityTier6Rocket} and {@code EntityMultiSeatRocket}
 * **override** {@code onReachAtmosphere} and never run the parent's body, so the injection never fired for them - the
 * owner launched and Galaxy Space's map appeared. Both of them, and Galacticraft's own rockets, do call
 * {@code WorldUtil.toCelestialSelection} on the way out, and that is the funnel this mixin takes.</p>
 *
 * <p>It is also more correct than the per-rocket version was: {@code toCelestialSelection} is only reached when the
 * rocket has no destination to fly to (a frequency the pad route resolved takes the other branch), so a pad-to-pad
 * flight to a space station is no longer intercepted - the old injection cancelled Galacticraft's method
 * unconditionally and asked this pack's map instead.</p>
 *
 * <h2>What it deliberately leaves alone</h2>
 *
 * <p>{@code toCelestialSelection} has other callers - the {@code /planetteleport} command and Galacticraft's player
 * handler - so the takeover only happens when the player asking is **riding a rocket**. Anything else is Galacticraft's
 * business and still gets Galacticraft's screen.</p>
 */
@Mixin(WorldUtil.class)
public abstract class MixinWorldUtil {

    @Inject(
            method = "toCelestialSelection(Lnet/minecraft/entity/player/EntityPlayerMP;"
                    + "Lmicdoodle8/mods/galacticraft/core/entities/player/GCPlayerStats;I)V",
            at = @At("HEAD"),
            cancellable = true
    )
    private static void minespaceUseOwnMap(EntityPlayerMP player, GCPlayerStats stats, int tier, CallbackInfo ci) {
        if (player == null) {
            return;
        }
        Entity ridden = player.getRidingEntity();
        if (!(ridden instanceof EntityAutoRocket)) {
            return;
        }
        if (MinespaceRocketDestinations.takeOver(player, (EntityAutoRocket) ridden)) {
            ci.cancel();
        }
    }
}
