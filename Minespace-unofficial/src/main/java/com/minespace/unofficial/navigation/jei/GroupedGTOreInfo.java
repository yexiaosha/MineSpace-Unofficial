package com.minespace.unofficial.navigation.jei;

import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.stack.MaterialStack;
import gregtech.api.worldgen.config.OreDepositDefinition;
import gregtech.integration.jei.GTOreInfo;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * GregTech's JEI ore-vein entry, with output blocks grouped by ore rather than by stone type.
 *
 * <p>{@link GTOreInfo} builds one output slot per unique block. A vein that can generate in many
 * stone types therefore turns one ore into dozens of slots, pushes the page past the screen, and
 * breaks GT's ore-weight tooltip, which assumes slot 2+n is the n-th ore in the filler. Grouping
 * the blocks by material restores one slot per ore; the different stone variants remain in that
 * slot as JEI's normal ingredient alternatives, so no block is lost.</p>
 */
public class GroupedGTOreInfo extends GTOreInfo {

    private static final Logger LOG = LogManager.getLogger("minespace_navigation");

    public GroupedGTOreInfo(OreDepositDefinition definition) {
        super(definition);
    }

    @Override
    public void addTooltip(int slotIndex, boolean input, Object ingredient, List<String> tooltip) {
        try {
            super.addTooltip(slotIndex, input, ingredient, tooltip);
        } catch (IndexOutOfBoundsException ignored) {
            // A complex filler can expose more groups than one weighted entry list. The item name
            // is still drawn by JEI; only GT's extra weight line is skipped.
        }
    }

    @Override
    public List<List<ItemStack>> findUniqueBlocksAsItemStack(List<ItemStack> inputs) {
        Map<String, List<ItemStack>> groups = new LinkedHashMap<>();
        Map<String, Set<String>> seen = new LinkedHashMap<>();
        for (ItemStack stack : inputs) {
            if (stack == null || stack.isEmpty()) {
                continue;
            }
            String key = materialKey(stack);
            List<ItemStack> group = groups.get(key);
            if (group == null) {
                group = new ArrayList<>();
                groups.put(key, group);
                seen.put(key, new LinkedHashSet<>());
            }
            if (seen.get(key).add(itemKey(stack))) {
                group.add(stack.copy());
            }
        }
        if (inputs.size() > 20) {
            LOG.info("JEI ore grouping: {} block states -> {} ore groups", inputs.size(),
                    groups.size());
        }
        return new ArrayList<>(groups.values());
    }

    /**
     * Uses the ore's GT material when available, so all stone variants of one ore share a group.
     * The fallback keeps unrelated blocks apart even if they have no material.
     */
    private static String materialKey(ItemStack stack) {
        MaterialStack material = OreDictUnifier.getMaterial(stack);
        if (material != null && material.material != null) {
            return material.material.toCamelCaseString();
        }
        ResourceLocation id = stack.getItem().getRegistryName();
        return String.valueOf(id) + ':' + stack.getMetadata();
    }

    private static String itemKey(ItemStack stack) {
        ResourceLocation id = stack.getItem().getRegistryName();
        return String.valueOf(id) + ':' + stack.getMetadata();
    }
}
