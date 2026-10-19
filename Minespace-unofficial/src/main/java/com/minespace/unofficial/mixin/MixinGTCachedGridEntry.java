package com.minespace.unofficial.mixin;

import net.minecraft.block.state.IBlockState;
import net.minecraft.block.Block;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

/**
 * GT's vein populator writes every planned ore block through World.setBlockState. A
 * surface-rock or filler definition that resolves to no block state therefore hands
 * Chunk.setBlockState a null state and crashes the chunk populate pass. Skip the write
 * instead: the rest of the vein is still valid, and the malformed entry is logged once.
 */
@Mixin(targets = "gregtech.api.worldgen.generator.CachedGridEntry$ChunkDataEntry")
public abstract class MixinGTCachedGridEntry {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static boolean reported;

    @Redirect(
            method = "populateChunk",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/world/World;func_180501_a(Lnet/minecraft/util/math/BlockPos;"
                            + "Lnet/minecraft/block/state/IBlockState;I)Z"
            ),
            remap = false
    )
    private static boolean minespaceSkipNullVeinState(World world, BlockPos pos,
                                                       IBlockState state, int flags) {
        if (state == null) {
            if (!reported) {
                reported = true;
                LOG.warn("GT vein filler returned no block state at {}; skipping that block "
                        + "(further occurrences are suppressed)", pos);
            }
            return false;
        }
        return world.setBlockState(pos, state, flags);
    }

    @Redirect(
            method = "populateChunk",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/block/Block;func_176210_f("
                            + "Lnet/minecraft/block/state/IBlockState;)I"
            ),
            remap = false
    )
    private static int minespaceSafeStateId(IBlockState state) {
        return state == null ? 0 : Block.getStateId(state);
    }
}
