package com.minespace.unofficial.mixin;

import gregtech.api.metatileentity.MetaTileEntity;
import net.minecraftforge.fml.common.FMLCommonHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Stops a GregTech machine from loading a client-only sound class on a dedicated server.
 *
 * <h2>The crash this fixes</h2>
 *
 * {@code MetaTileEntity.onRemoval()} has exactly one statement in it:
 *
 * <pre>
 *   public void onRemoval() {
 *       MachineSoundManager.stop(getPos());
 *   }
 * </pre>
 *
 * and {@code gregtech.common.sound.MachineSoundManager} is annotated client-only, so Forge strips it
 * from the dedicated server jar. The base body is <em>only</em> that call, so on a server any block
 * break on a machine block - and GregTech's own surface ore rocks are MetaTileEntities - tries to load
 * a class that is not there and the server dies with
 * {@code NoClassDefFoundError: gregtech/common/sound/MachineSoundManager} /
 * {@code Attempted to load class ... for invalid side SERVER}.
 *
 * <p>It does not need a player to trigger it either. Measured in this pack's own run of 2026-10-13:
 * Applied Energistics' meteorite generation places its crater through
 * {@code MeteoritePlacer.placeCrater -> World.setBlockState}, and when that overwrote one of the
 * GregTech surface rocks the server crashed in its tick loop about 30 seconds after {@code Done},
 * with no player online:
 *
 * <pre>
 *   at gregtech.api.metatileentity.MetaTileEntity.onRemoval(MetaTileEntity.java:1271)
 *   at gregtech.api.block.machines.BlockMachine.func_180663_b(BlockMachine.java:258)
 *   at appeng.worldgen.meteorite.MeteoritePlacer.placeCrater(MeteoritePlacer.java:174)
 *   Caused by: java.lang.ClassNotFoundException: gregtech.common.sound.MachineSoundManager
 * </pre>
 *
 * <h2>The patch</h2>
 *
 * Cancel the base body on the physical server. Nothing is lost: the base implementation does nothing
 * but stop a client sound, which a server has no sounds for. Subclasses that override
 * {@code onRemoval} keep their own behaviour - they call {@code super.onRemoval()} for this sound and
 * nothing else - and on a client the injection does not cancel, so the sound still stops normally.
 *
 * <p>{@code onRemoval} is a GregTech method that carries its name in both MCP and SRG, and no
 * Minecraft member is referenced by name in the body, so this mixin needs no refmap - only the mixins
 * list in {@code mixins.minespace.json}.
 */
@Mixin(MetaTileEntity.class)
public class MixinMetaTileEntityOnRemoval {

    @Inject(method = "onRemoval", at = @At("HEAD"), cancellable = true)
    private void minespace$skipClientOnlySoundOnServer(CallbackInfo callback) {
        if (!FMLCommonHandler.instance().getSide().isClient()) {
            callback.cancel();
        }
    }
}
