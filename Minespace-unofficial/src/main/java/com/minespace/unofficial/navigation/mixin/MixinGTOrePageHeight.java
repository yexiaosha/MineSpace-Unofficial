package com.minespace.unofficial.navigation.mixin;

import com.minespace.unofficial.navigation.jei.MinespaceOreBackground;
import mezz.jei.api.IGuiHelper;
import mezz.jei.api.gui.IDrawable;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import java.lang.reflect.Field;

/**
 * Replaces GregTech's tall ore-page background with one sized to the actual content.
 *
 * <p>The field is declared by {@code PrimitiveRecipeCategory}, so reflection is used instead of a
 * shadow: this mixin targets the concrete category but the drawable lives one class up.</p>
 */
@Mixin(targets = "gregtech.integration.jei.GTOreCategory")
public abstract class MixinGTOrePageHeight {

    private static final Logger LOG = LogManager.getLogger("minespace_navigation");

    @Inject(method = "<init>", at = @At("RETURN"), remap = false)
    private void minespaceUseContentHeight(IGuiHelper helper, CallbackInfo ci) {
        try {
            Field field = Class.forName(
                    "gregtech.integration.jei.recipe.primitive.PrimitiveRecipeCategory")
                    .getDeclaredField("background");
            field.setAccessible(true);
            IDrawable original = (IDrawable) field.get(this);
            field.set(this, new MinespaceOreBackground(original));
            LOG.info("JEI ore page background: {} -> 120", original == null ? -1
                    : original.getHeight());
        } catch (ReflectiveOperationException ignored) {
            // Leaving the original 166-pixel background is better than failing the JEI category.
        }
    }
}
