package com.minespace.unofficial.navigation.mixin;

import net.minecraft.client.gui.FontRenderer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

/**
 * Localizes and un-wraps the hard-coded labels in GregTech's JEI ore category.
 *
 * <p>{@code GTOreCategory} builds "Spawn Range:", "Vein Weight:", "Dimensions:" and
 * "SurfaceMaterial" as Java string literals; none has a language key. The last one is drawn with
 * the width of the word "Surface", so at the normal JEI scale it always wraps into
 * "Surface" / "Material". A Chinese label is shorter and is drawn with a fixed width instead.</p>
 */
@Mixin(targets = "gregtech.integration.jei.GTOreCategory")
public abstract class MixinGTOreCategory {

    @Redirect(
            method = "drawExtras",
            at = @At(
                    value = "INVOKE",
                    // SRG name: the released jar runs with SRG-named Minecraft members, and this
                    // project has no refmap, so targeting the MCP name would not match at runtime.
                    target = "Lnet/minecraft/client/gui/FontRenderer;func_78276_b(Ljava/lang/String;III)I"
            ),
            remap = false
    )
    private int minespaceLocalizeOreString(FontRenderer font, String text, int x, int y, int color) {
        return font.drawString(localize(text), x, y, color);
    }

    @Redirect(
            method = "drawExtras",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/client/gui/FontRenderer;func_78279_b(Ljava/lang/String;IIII)V"
            ),
            remap = false
    )
    private void minespaceLocalizeOreSplit(FontRenderer font, String text, int x, int y, int width, int color) {
        if ("SurfaceMaterial".equals(text)) {
            font.drawSplitString("表层材料", x, y, 80, color);
            return;
        }
        font.drawSplitString(text, x, y, width, color);
    }

    private static String localize(String text) {
        if ("Spawn Range:".equals(text)) {
            return "生成范围：";
        }
        if ("Vein Weight:".equals(text)) {
            return "矿脉权重：";
        }
        if ("Dimensions:".equals(text)) {
            return "维度：";
        }
        return text;
    }
}
