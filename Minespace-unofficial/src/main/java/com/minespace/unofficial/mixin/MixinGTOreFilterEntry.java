package com.minespace.unofficial.mixin;

import gregtech.api.unification.ore.StoneType;
import gregtech.api.unification.ore.StoneTypes;
import net.minecraft.block.state.IBlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

import java.util.Map;

/**
 * GT's ore filler maps a StoneType to the matching ore-block variant. BYG's custom
 * stone types are registered so GT veins can run inside BYG biomes, but an ore block
 * does not necessarily have a variant for every one of those types; the map then holds
 * a null value and the vein tries to place a null block.
 *
 * <p>Fall back to the ore's normal stone variant (or any non-null variant it has) instead
 * of aborting the chunk. The ore still appears; only its base-rock texture is the generic
 * one where the custom variant does not exist.</p>
 */
@Mixin(targets = "gregtech.api.worldgen.config.FillerConfigUtils$OreFilterEntry", remap = false)
public abstract class MixinGTOreFilterEntry {

    @Redirect(
            method = "apply",
            at = @At(
                    value = "INVOKE",
                    target = "Ljava/util/Map;get(Ljava/lang/Object;)Ljava/lang/Object;"
            ),
            remap = false
    )
    private static Object minespaceFallbackOreState(Map<?, ?> map, Object key) {
        Object value = map.get(key);
        if (value != null) {
            return value;
        }
        value = map.get(StoneTypes.STONE);
        if (value != null) {
            return value;
        }
        for (Object candidate : map.values()) {
            if (candidate != null) {
                return candidate;
            }
        }
        return null;
    }
}
