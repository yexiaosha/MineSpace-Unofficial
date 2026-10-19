package com.minespace.unofficial.gtceu;

import gregtech.api.unification.OreDictUnifier;
import net.minecraft.item.ItemStack;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Remembers the actual block scanned for each ore-dictionary name, so the Prospector's
 * ore list does not use an arbitrary first entry from {@code OreDictUnifier.get(name)}.
 * A generic name such as {@code oreCoal} is shared by vanilla, GT and Galaxy Space;
 * picking the first entry made an overworld GT coal vein display as "Mars Coal Ore".
 */
public final class MinespaceProspectingDisplay {

    private static final Map<String, ItemStack> STACKS = new ConcurrentHashMap<>();

    private MinespaceProspectingDisplay() {
    }

    public static void remember(String oreName, ItemStack stack) {
        if (oreName != null && stack != null && !stack.isEmpty()) {
            ItemStack copy = stack.copy();
            copy.setCount(1);
            STACKS.put(oreName, copy);
        }
    }

    public static ItemStack stack(String oreName) {
        ItemStack stack = STACKS.get(oreName);
        return stack == null ? OreDictUnifier.get(oreName) : stack.copy();
    }
}
