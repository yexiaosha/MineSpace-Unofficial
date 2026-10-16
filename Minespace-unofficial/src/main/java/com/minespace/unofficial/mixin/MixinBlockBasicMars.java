package com.minespace.unofficial.mixin;

import com.google.common.base.Predicate;
import micdoodle8.mods.galacticraft.planets.mars.blocks.BlockBasicMars;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.IBlockAccess;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/** Martian rock: same fix as {@link MixinBlockBasicMoon}, see that class for the full story. */
@Mixin(BlockBasicMars.class)
public abstract class MixinBlockBasicMars {

    @Inject(method = "isReplaceableOreGen", at = @At("HEAD"), cancellable = true)
    private void minespace$honourStoneTypePredicate(IBlockState state, IBlockAccess world,
            BlockPos pos, Predicate<IBlockState> target, CallbackInfoReturnable<Boolean> cir) {
        if (target != null && !target.apply(state)) {
            cir.setReturnValue(false);
        }
    }
}
