package com.minespace.unofficial.gtceu;

import net.minecraft.creativetab.CreativeTabs;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.util.NonNullList;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.relauncher.SideOnly;

/**
 * The six pieces of survey data that unlock the six tiers of the star map.
 *
 * <h2>Why research data and not another machine</h2>
 *
 * The plan's section 4.3 says the lanes are opened by research data, and the star map's own specification (6dr) put
 * the gate down as the one decision only the owner could make. The owner has now made it: the tiers are the star
 * map's **layers**, one piece of data per layer, and holding the data is what opens that layer's systems.
 *
 * | tier | data | layer | the band it opens |
 * |---|---|---|---|
 * | I | 研究数据 I | 2 | 近邻 (IV) - Proxima, Barnard, Tau Ceti and kin |
 * | II | 研究数据 II | 3 | 中距 (LuV~ZPM) - TRAPPIST-1 and the Gliese systems |
 * | III | 研究数据 III | 4 | 远距 (UV) - the Kepler field |
 * | IV | 研究数据 IV | 5 | 深空 (UHV) |
 * | V | 研究数据 V | 6 | 超深空 (UHV+) |
 * | VI | 研究数据 VI | 7 | 未知 (UHV+) |
 *
 * <p>One item with six metadata values rather than six items: they differ only in which tier they name, the check is
 * a metadata comparison, and the recipes (see `scripts\research_data.zs`) chain one into the next.</p>
 *
 * <p>Ids are **not** left open on purpose: a piece of data is a *key*, not a levelled tool, so it never wears out and
 * never stacks above a handful.</p>
 */
@Mod.EventBusSubscriber(modid = com.minespace.unofficial.Minespace.MOD_ID)
public final class MinespaceResearchData extends Item {

    /** How many tiers exist. The star map's layers 2..7, so six. */
    public static final int TIERS = 6;

    public static final String REGISTRY_NAME = "research_data";

    /** The single item; its metadata is the tier, one-based (1..6). */
    public static final MinespaceResearchData ITEM = new MinespaceResearchData();

    private MinespaceResearchData() {
        setRegistryName(com.minespace.unofficial.Minespace.MOD_ID, REGISTRY_NAME);
        setUnlocalizedName(com.minespace.unofficial.Minespace.MOD_ID + "." + REGISTRY_NAME);
        setHasSubtypes(true);
        setMaxDamage(0);
        setMaxStackSize(16);
    }

    /** One-based metadata, because "研究数据 0" reads like a bug. */
    @Override
    public String getUnlocalizedName(ItemStack stack) {
        int tier = Math.max(1, Math.min(TIERS, stack.getMetadata()));
        return super.getUnlocalizedName() + "." + tier;
    }

    @Override
    @SideOnly(Side.CLIENT)
    public void getSubItems(CreativeTabs tab, NonNullList<ItemStack> items) {
        if (!isInCreativeTab(tab)) {
            return;
        }
        for (int tier = 1; tier <= TIERS; tier++) {
            items.add(new ItemStack(this, 1, tier));
        }
    }

    @SubscribeEvent
    public static void onRegisterItems(RegistryEvent.Register<Item> event) {
        event.getRegistry().register(ITEM);
    }

    /**
     * The tier the owner holds, or 0 for none.
     *
     * <p>Scanned from the player's own inventory on the client, which is where the star map draws: the map must not
     * ask the server anything to know whether a lane is open, and a piece of data is not consumed by looking at
     * it.</p>
     */
    public static int highestHeld(net.minecraft.entity.player.EntityPlayer player) {
        if (player == null) {
            return 0;
        }
        int best = 0;
        for (int slot = 0; slot < player.inventory.getSizeInventory(); slot++) {
            ItemStack stack = player.inventory.getStackInSlot(slot);
            if (stack.getItem() == ITEM) {
                best = Math.max(best, stack.getMetadata());
            }
        }
        return best;
    }

    /** The star map's tier for a catalog layer: layer 2 is tier I, layer 7 tier VI. */
    public static int tierOfLayer(int layer) {
        return Math.max(1, Math.min(TIERS, layer - 1));
    }
}
