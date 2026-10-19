package com.minespace.unofficial.gtceu;

import net.minecraft.block.Block;
import net.minecraft.init.Items;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import net.minecraftforge.oredict.OreDictionary;

import java.util.HashSet;
import java.util.Set;

/**
 * Fills the standard Forge ore-dictionary names BYG does not register itself.
 *
 * <p>BYG already registers most wood families, but its own list is hand-written and misses
 * several variants; its special rocks are also split between {@code stone} and
 * {@code cobblestone} without a common {@code stone} entry. Recipes from GT, Forestry and the
 * other wood/stone consumers then cannot see those blocks. This runs in postInit, after BYG's
 * own {@code OreDictionaryEntries} pass, and only adds a stack when the name does not already
 * contain that exact item/metadata pair.</p>
 */
public final class MinespaceBygOreDictionary {

    private static final Set<String> STONES = new HashSet<>();

    static {
        STONES.add("rocky_stone");
        STONES.add("scoria");
        STONES.add("sepinite");
        STONES.add("soapstone");
        STONES.add("sodalite");
    }

    private MinespaceBygOreDictionary() {
    }

    public static void register() {
        if (!Loader.isModLoaded("byg")) {
            return;
        }

        for (Block block : ForgeRegistries.BLOCKS) {
            ResourceLocation id = block.getRegistryName();
            if (id == null || !"byg".equals(id.getResourceDomain())) {
                continue;
            }
            Item item = Item.getItemFromBlock(block);
            if (item == null || item == Items.AIR) {
                continue;
            }
            ItemStack stack = new ItemStack(item);
            String path = id.getResourcePath();

            if (path.endsWith("_log") || path.endsWith("_wood")
                    || path.startsWith("stripped_")) {
                add("logWood", stack);
            }
            if (path.endsWith("_planks")) {
                add("plankWood", stack);
            }
            if (path.endsWith("_stairs")) {
                add(isStone(path) ? "stoneStairs" : "stairWood", stack);
            }
            if (path.endsWith("_slab")) {
                add(isStone(path) ? "stoneSlab" : "slabWood", stack);
            }
            if (path.endsWith("_fence") || path.endsWith("_wood_wall")) {
                add("fenceWood", stack);
            }
            if (path.contains("_gate")) {
                add("fenceGateWood", stack);
            }
            if (path.endsWith("_bookshelf")) {
                add("bookshelfWood", stack);
            }
            if (path.endsWith("_leaves") || path.contains("_leaves_")) {
                add("treeLeaves", stack);
            }
            if (path.endsWith("_sapling")) {
                add("treeSapling", stack);
            }
            if (path.endsWith("_stick_pile")) {
                add("stickWood", stack);
            }

            if ((STONES.contains(path) || path.startsWith("polished_soapstone")
                    || path.startsWith("polished_sodalite"))
                    && !path.endsWith("_stairs") && !path.endsWith("_walls")) {
                add("stone", stack);
            }
            if (path.endsWith("_bricks") && isStone(path)) {
                add("stoneBrick", stack);
            }
            if (isStone(path) && (path.endsWith("_pillars") || path.endsWith("_tile"))) {
                add("stone", stack);
            }
            if (isStone(path) && path.endsWith("_walls")) {
                add("stoneWall", stack);
            }
        }

        // Doors are items, not blocks; BYG's own list covers most but not every wood family.
        for (Item item : ForgeRegistries.ITEMS) {
            ResourceLocation id = item.getRegistryName();
            if (id != null && "byg".equals(id.getResourceDomain())
                    && id.getResourcePath().endsWith("_door")) {
                add("doorWood", new ItemStack(item));
            }
        }
    }

    private static boolean isStone(String path) {
        return STONES.contains(path) || path.startsWith("scoria")
                || path.startsWith("sepinite") || path.startsWith("soapstone")
                || path.startsWith("sodalite") || path.startsWith("rocky_stone")
                || path.startsWith("polished_soapstone")
                || path.startsWith("polished_sodalite");
    }

    private static void add(String oreName, ItemStack stack) {
        if (stack.isEmpty()) {
            return;
        }
        for (ItemStack existing : OreDictionary.getOres(oreName, false)) {
            if (OreDictionary.itemMatches(existing, stack, false)) {
                return;
            }
        }
        OreDictionary.registerOre(oreName, stack);
    }
}
