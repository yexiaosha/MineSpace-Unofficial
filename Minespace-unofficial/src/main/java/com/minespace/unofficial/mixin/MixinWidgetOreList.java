package com.minespace.unofficial.mixin;

import com.minespace.unofficial.gtceu.MinespaceProspectingDisplay;
import gregtech.api.unification.OreDictUnifier;
import net.minecraft.item.ItemStack;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

/** Uses the block the scanner actually saw as the list icon/name, not an arbitrary ore-dict entry. */
@Mixin(targets = "gregicadditions.widgets.WidgetOreList", remap = false)
public abstract class MixinWidgetOreList {

    @Redirect(
            method = "addOre",
            at = @At(
                    value = "INVOKE",
                    target = "Lgregtech/api/unification/OreDictUnifier;get(Ljava/lang/String;)"
                            + "Lnet/minecraft/item/ItemStack;"
            ),
            remap = false
    )
    private static ItemStack minespaceDisplayScannedOre(String oreName) {
        return MinespaceProspectingDisplay.stack(oreName);
    }
}
