package com.minespace.unofficial.gtceu;

import forestry.api.farming.IFarmable;
import forestry.core.utils.ItemStackUtil;
import forestry.farming.FarmRegistry;
import forestry.farming.logic.farmables.FarmableSapling;
import net.minecraft.block.Block;
import net.minecraft.init.Blocks;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Loader;
import net.minecraftforge.fml.common.registry.ForgeRegistries;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Registers every BYG sapling as a Forestry arboretum germling.
 *
 * <p>The arboretum does not read the {@code treeSapling} ore dictionary: it plants only entries
 * in its own {@code farmArboreal} farmable list. BYG's saplings therefore had to be added one by
 * one, with the same {@link FarmableSapling} adapter Forestry uses for vanilla saplings.</p>
 */
public final class MinespaceForestryBygFarm {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static boolean registered;

    private MinespaceForestryBygFarm() {
    }

    public static void register() {
        if (registered || !Loader.isModLoaded("forestry") || !Loader.isModLoaded("byg")) {
            return;
        }
        registered = true;

        int count = 0;
        for (Item item : ForgeRegistries.ITEMS) {
            ResourceLocation id = item.getRegistryName();
            if (id == null || !"byg".equals(id.getResourceDomain())
                    || !id.getResourcePath().endsWith("_sapling")) {
                continue;
            }
            ItemStack germling = new ItemStack(item);
            Block saplingBlock = ItemStackUtil.getBlock(germling);
            if (saplingBlock == null || saplingBlock == Blocks.AIR) {
                LOG.warn("Forestry arboretum: {} has no sapling block, skipping", id);
                continue;
            }
            IFarmable farmable = new FarmableSapling(germling,
                    new ItemStack[]{germling.copy()});
            FarmRegistry.getInstance().registerFarmables("farmArboreal", farmable);
            count++;
        }
        LOG.info("Forestry arboretum: registered {} BYG saplings as plantable germlings", count);
    }
}
