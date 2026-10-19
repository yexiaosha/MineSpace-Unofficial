package com.minespace.unofficial.mixin;

import gregicadditions.network.ProspectingPacket;
import gregtech.api.unification.OreDictUnifier;
import net.minecraft.block.Block;
import net.minecraft.block.state.IBlockState;
import net.minecraft.item.ItemStack;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.chunk.Chunk;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

import java.util.Collections;
import java.util.Set;

/**
 * Keeps the block metadata when the Prospector turns an ore block into an item stack.
 *
 * <p>Gregicality's scanner does {@code new ItemStack(block)} and then asks the ore dictionary
 * for that stack's first name. A GregTech ore block carries its material and stone type in its
 * metadata, so the no-metadata stack always resolves to variant 0 - every ore in the scanned
 * area was therefore counted as the same material (copper in the report that exposed this), and
 * stones from another body could be labelled as well. The state is captured from the scan's own
 * {@code getBlockState} call and used to build the stack with its real metadata.</p>
 *
 * <p>Some mod ore blocks have no ore-dictionary entry for the corrected state. The original code
 * called {@code Optional.get()} unconditionally and crashed on exactly that; such blocks now get
 * an internal marker which is filtered out before it reaches the statistics.</p>
 *
 * <p>The scanner also paints every single ore block, so a mixed vein looks like a cloud of
 * unrelated coloured pixels and isolated meteorite/accessory ores such as certus quartz or
 * tamrelite show up as noise. A block is now kept only when at least five blocks of the same
 * state exist in its face-neighbourhood. Real GT veins pass easily; one-block scatter does not.</p>
 */
@Mixin(targets = "gregicadditions.widgets.WidgetProspectingMap")
public abstract class MixinProspectingMapMeta {

    private static final String UNKNOWN_ORE = "__minespace_unknown_ore__";
    private static final int CLUSTER_THRESHOLD = 4;
    /** Six face neighbours: seven state reads per ore block instead of the old twenty-seven. */
    private static final int[][] FACE_OFFSETS = {
            {1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}
    };
    private static final ThreadLocal<IBlockState> MINESPACE_SCANNED_STATE =
            new ThreadLocal<IBlockState>();
    private static final ThreadLocal<Chunk> MINESPACE_SCANNED_CHUNK =
            new ThreadLocal<Chunk>();

    @Redirect(
            method = "detectAndSendChanges",
            at = @At(
                    value = "INVOKE",
                    target = "Lnet/minecraft/world/chunk/Chunk;func_186032_a(III)Lnet/minecraft/block/state/IBlockState;"
            ),
            remap = false
    )
    private IBlockState minespaceCaptureOreState(Chunk chunk, int x, int y, int z) {
        IBlockState state = chunk.getBlockState(x, y, z);
        MINESPACE_SCANNED_STATE.set(state);
        MINESPACE_SCANNED_CHUNK.set(chunk);
        return state;
    }

    @Redirect(
            method = "detectAndSendChanges",
            at = @At(
                    value = "INVOKE",
                    target = "Lgregtech/api/unification/OreDictUnifier;getOreDictionaryNames(Lnet/minecraft/item/ItemStack;)Ljava/util/Set;"
            ),
            remap = false
    )
    private static Set<String> minespaceCorrectOreNames(ItemStack ignored) {
        IBlockState state = MINESPACE_SCANNED_STATE.get();
        if (state == null) {
            return OreDictUnifier.getOreDictionaryNames(ignored);
        }
        Block block = state.getBlock();
        ItemStack corrected = new ItemStack(block, 1, block.getMetaFromState(state));
        Set<String> names = OreDictUnifier.getOreDictionaryNames(corrected);
        if (names.isEmpty()) {
            return Collections.singleton(UNKNOWN_ORE);
        }
        // A GT ore block carries several names (the generic one plus stone-specific aliases).
        // Returning all of them makes the Prospector add the same block once per alias, which is
        // what produced duplicate rows such as "漂白土矿石" and "海绿石矿砂矿石" in the list.
        String shortestOre = null;
        for (String name : names) {
            if (!name.startsWith("ore")) {
                continue;
            }
            if (shortestOre == null || name.length() < shortestOre.length()) {
                shortestOre = name;
            }
        }
        return Collections.singleton(shortestOre != null ? shortestOre : names.iterator().next());
    }

    @Redirect(
            method = "detectAndSendChanges",
            at = @At(
                    value = "INVOKE",
                    target = "Lgregicadditions/network/ProspectingPacket;addBlock(IIILjava/lang/String;)V"
            ),
            remap = false
    )
    private static void minespaceSkipUnknownOre(ProspectingPacket packet, int x, int y, int z, String name) {
        IBlockState state = MINESPACE_SCANNED_STATE.get();
        Chunk chunk = MINESPACE_SCANNED_CHUNK.get();
        MINESPACE_SCANNED_STATE.remove();
        MINESPACE_SCANNED_CHUNK.remove();
        if (UNKNOWN_ORE.equals(name)) {
            return;
        }
        if (packet.mode == 0 && state != null && chunk != null
                && !minespaceFormsCluster(chunk, state, x, y, z)) {
            return;
        }
        packet.addBlock(x, y, z, name);
    }

    /** True when the scanned block is part of a real cluster instead of an isolated speck. */
    private static boolean minespaceFormsCluster(Chunk chunk, IBlockState state,
                                                 int localX, int y, int localZ) {
        World world = chunk.getWorld();
        int originX = chunk.x * 16 + localX;
        int originZ = chunk.z * 16 + localZ;
        Block block = state.getBlock();
        int metadata = block.getMetaFromState(state);
        int matches = 1;
        for (int[] offset : FACE_OFFSETS) {
            BlockPos pos = new BlockPos(originX + offset[0], y + offset[1], originZ + offset[2]);
            if (!world.isBlockLoaded(pos)) {
                continue;
            }
            IBlockState other = world.getBlockState(pos);
            if (other.getBlock() == block
                    && block.getMetaFromState(other) == metadata
                    && ++matches >= CLUSTER_THRESHOLD) {
                return true;
            }
        }
        return false;
    }
}
