package com.minespace.unofficial.mixin;

import com.minespace.unofficial.gtceu.MinespaceBygNames;
import net.minecraft.util.ResourceLocation;
import net.minecraft.world.biome.Biome;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/**
 * BYG stores its biome names as hard-coded {@code BiomeProperties} strings, so the normal lang
 * file route does not reach them. Translate only BYG's own registry entries and leave every other
 * biome's name alone. The SRG method is {@code getBiomeName}.
 */
@Mixin(Biome.class)
public abstract class MixinBiomeName {

    @Inject(method = "func_185359_l", at = @At("RETURN"), cancellable = true, remap = false)
    private void minespaceTranslateBygBiome(CallbackInfoReturnable<String> cir) {
        Biome biome = (Biome) (Object) this;
        ResourceLocation id = biome.getRegistryName();
        if (id != null && "byg".equals(id.getResourceDomain())) {
            String translated = MinespaceBygNames.biomeName(id.getResourcePath());
            if (translated != null) {
                cir.setReturnValue(translated);
            }
        }
    }
}
