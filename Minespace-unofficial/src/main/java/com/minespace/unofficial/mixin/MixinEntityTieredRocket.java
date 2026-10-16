package com.minespace.unofficial.mixin;

import com.minespace.unofficial.galacticraft.MinespaceRocketDestinations;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntityAutoRocket;
import micdoodle8.mods.galacticraft.api.prefab.entity.EntityTieredRocket;
import net.minecraft.entity.player.EntityPlayerMP;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Takes over the moment Galacticraft would ask the player where they are going.
 *
 * <h2>What Galacticraft does there</h2>
 *
 * {@code EntityTieredRocket.onReachAtmosphere()} opens its celestial screen when {@code destinationFrequency == -1} -
 * no pad, no destination - and a frequency is a landing pad, so a body this pack owns can never satisfy it. The owner
 * met this twice: aiming on the star map and launching still brought up Galacticraft's map.
 *
 * <h2>What this injection does</h2>
 *
 * At the head of that method: if this rocket was aimed from the star map
 * ({@link MinespaceRocketDestinations#destination}), the vanilla behaviour is cancelled and the player is moved to the
 * planet instead. Everything before this point is Galacticraft's - the fuel, the ascent, the phase changes - so the
 * launch the owner watches is still GC's launch; only the part that has no GC equivalent (a destination without a pad)
 * is ours.
 */
@Mixin(EntityTieredRocket.class)
public abstract class MixinEntityTieredRocket {

    @Inject(method = "onReachAtmosphere", at = @At("HEAD"), cancellable = true)
    private void minespaceArriveFromStarMap(CallbackInfo ci) {
        EntityTieredRocket rocket = (EntityTieredRocket) (Object) this;
        if (rocket.world == null || rocket.world.isRemote) {
            return;
        }
        if (rocket.getPassengers().isEmpty()) {
            // Nobody to ask: a cargo rocket with a frequency is Galacticraft's business, untouched.
            return;
        }
        Object rider = rocket.getPassengers().get(0);
        if (!(rider instanceof EntityPlayerMP)) {
            return;
        }
        EntityPlayerMP player = (EntityPlayerMP) rider;
        int destination = MinespaceRocketDestinations.destination(rocket);
        // Galacticraft's moment of choosing, with the pack's own map in it: this is what GC would have spent on its
        // celestial screen, and it is cancelled in both branches so that screen never appears.
        if (destination == 0) {
            // **Once.** This method runs every tick while the rocket is up there, so sending the message every time
            // reopened the map over and over - the flicker the owner reported.
            if (MinespaceRocketDestinations.firstAsk(rocket)) {
                com.minespace.unofficial.galacticraft.MinespaceNetwork.CHANNEL
                        .sendTo(new com.minespace.unofficial.galacticraft.MinespaceNetwork.OpenStarMapMessage(), player);
            }
        } else {
            // Aimed on the ground already: no need to ask, take them there.
            MinespaceRocketDestinations
                    .transfer(player, destination, nameOf(destination));
            MinespaceRocketDestinations.clear(rocket);
        }
        ci.cancel();
    }

    private static String nameOf(int dimensionId) {
        com.minespace.unofficial.gtceu.MinespacePlanetDimensions.Planet body =
                com.minespace.unofficial.galacticraft.MinespaceRocketTarget.bodyOf(dimensionId);
        return body == null ? ("维度 " + dimensionId) : body.name + "（" + body.nameZh + "）";
    }
}
