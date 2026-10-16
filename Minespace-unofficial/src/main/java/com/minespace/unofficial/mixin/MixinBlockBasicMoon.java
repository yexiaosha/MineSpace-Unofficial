package com.minespace.unofficial.mixin;

import com.google.common.base.Predicate;
import micdoodle8.mods.galacticraft.core.blocks.BlockBasicMoon;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.IBlockAccess;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/**
 * Makes Galacticraft's Lunar rock answer GregTech's stone-type question honestly.
 *
 * <h2>The problem</h2>
 *
 * GregTech picks the ore block variant for a vein by asking
 * {@code StoneType.computeStoneType(state, world, pos)}, which walks its stone type registry in
 * id order and returns the first type whose predicate accepts the block. The check is made
 * through {@code Block.isReplaceableOreGen(state, world, pos, predicate)} - a Forge method whose
 * whole point is to let a block decide whether <em>this</em> stone type may replace it.
 *
 * <p>{@code BlockBasicMoon} overrides that method and ignores the predicate it is handed:
 *
 * <pre>
 *   return variant == MOON_STONE || variant == MOON_DIRT;
 * </pre>
 *
 * So the <em>first</em> registered stone type wins for every Lunar rock - and that is GregTech's
 * own {@code stone} (id 0). Our {@code moon_stone} (id 16) is never reached, and Lunar ores are
 * generated as the overworld stone variant: the vein is right, the rock it is drawn on is not.
 * The same shape of bug lives in {@code BlockBasicMars} and {@code BlockBasicVenus}.
 *
 * <h2>The patch</h2>
 *
 * Inject at the head of the override and only ever turn a "yes" into a "no": if the asked-for
 * stone type's predicate does not accept this block, the answer is false regardless of what
 * Galacticraft's own variant list says. A "no" from Galacticraft is left untouched, so its
 * variant selection (which Moon/Mars/Venus rocks are eligible at all) is preserved exactly.
 *
 * <p>Nothing in this body references a Minecraft member by name, and the method name in
 * {@code method = "isReplaceableOreGen"} is Forge-added (identical in MCP and SRG), so the mixin
 * needs no refmap - only the {@code MixinConfigs} manifest entry that MixinBooter reads.
 */
@Mixin(BlockBasicMoon.class)
public abstract class MixinBlockBasicMoon {

    @Inject(method = "isReplaceableOreGen", at = @At("HEAD"), cancellable = true)
    private void minespace$honourStoneTypePredicate(IBlockState state, IBlockAccess world,
            BlockPos pos, Predicate<IBlockState> target, CallbackInfoReturnable<Boolean> cir) {
        if (target != null && !target.apply(state)) {
            cir.setReturnValue(false);
        }
    }
}
