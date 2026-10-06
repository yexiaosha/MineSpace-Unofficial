package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import gregtech.api.unification.material.Material;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import gregtech.common.blocks.BlockOre;
import gregtech.common.blocks.MetaBlocks;
import net.minecraft.block.Block;
import net.minecraft.block.state.IBlockState;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * Registers additional GregTech stone types, so GT's ore blocks can use a non-vanilla
 * rock as their base.
 *
 * <h2>Why this is needed at all</h2>
 *
 * The worldgen filler picks the ore block for a vein through
 * {@code FillerConfigUtils$OreFilterEntry.apply}:
 *
 * <pre>
 *   StoneType type = StoneType.computeStoneType(replacedState, world, pos);
 *   return blockStateMap.get(type != null ? type : defaultValue);
 * </pre>
 *
 * and {@code defaultValue} is {@code StoneTypes.STONE} whenever that key is present. So
 * any rock GT does not know about silently falls back to the <b>overworld stone</b> ore
 * texture — the ore still generates and drops correctly, it just renders on the wrong
 * base. Registering a stone type is what fixes the render, and there is no config or
 * script route to it on 1.12.2: {@code OrePrefix.registerOrePrefix} (used by the GTCEu
 * 1.20 walkthroughs) does not exist in this version, and an ore block's allowed stone
 * types are baked from {@link StoneType#STONE_TYPE_REGISTRY} at the moment the ore
 * blocks are constructed.
 *
 * <h2>Timing, which is the whole difficulty here</h2>
 *
 * The stone type has to exist <em>before</em> GTCEu builds its ore blocks, and GTCEu
 * builds all of them inside {@code CommonProxy.registerBlocks}, i.e. during
 * {@code RegistryEvent.Register<Block>}:
 *
 * <pre>
 *   preInit (all mods, in load order)   &lt;-- GT's own stone types are registered here
 *   RegistryEvent.Register&lt;Block&gt;       &lt;-- GT builds the ore blocks here
 *   init (all mods)
 * </pre>
 *
 * That rules out both obvious hooks:
 *
 * <ul>
 *   <li><b>preInit is too early.</b> Forge does not fire
 *       {@code RegistryEvent.Register<Block>} until every mod has finished preInit, so
 *       during this mod's preInit Galacticraft has not registered
 *       {@code galacticraftcore:basic_block_moon} yet and the lookup returns null.
 *       (Observed exactly that: "Galacticraft is loaded but 'basic_block_moon' is not in
 *       the block registry".)</li>
 *   <li><b>init is too late.</b> The ore blocks were already constructed by then, and a
 *       block's allowed property values cannot be changed afterwards.</li>
 * </ul>
 *
 * So the registration hangs off the block registry event itself, at
 * {@link EventPriority#HIGH}: Forge runs same-priority-cycle listeners in priority
 * order, GTCEu's {@code registerBlocks} is at the default
 * {@link EventPriority#NORMAL}, and this therefore runs first. (GTCEu's other handler,
 * {@code registerBlocksLast}, is explicitly {@code LOWEST} and only does fluids, pipes
 * and stone blocks.)
 *
 * <h2>Why the Galacticraft half lives in another class</h2>
 *
 * Galacticraft is an {@code after:} (optional) dependency. If the block-state predicate
 * were written inline, this class's constant pool would reference
 * {@code micdoodle8.mods.galacticraft.*} and loading it without GC installed could fail.
 * Everything Galacticraft-specific is confined to
 * {@link com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones}, which is
 * only touched when {@link Minespace#hasGalacticraft()} says GC is there.
 */
@Mod.EventBusSubscriber(modid = Minespace.MOD_ID)
public final class MinespaceStoneTypes {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** Kept in the pack's 32000+ addon range, after the two existing materials. */
    public static final int MOON_STONE_ID = 32002;

    public static final String MOON_STONE = "moon_stone";

    /** Ids 0..15 are taken by GT's own stone types; the registry holds up to 128. */
    private static final int MOON_STONE_TYPE_ID = 16;

    private static boolean registered;

    private MinespaceStoneTypes() {
    }

    @SubscribeEvent(priority = EventPriority.HIGH)
    public static void onRegisterBlocks(RegistryEvent.Register<Block> event) {
        if (registered) {
            return;
        }
        if (!Minespace.hasGalacticraft()) {
            LOG.info("Galacticraft not present — skipping the moon_stone stone type");
            return;
        }
        registerMoonStoneType();
    }

    private static void registerMoonStoneType() {
        // The material itself is registered from MaterialEvent (see MinespaceMaterials);
        // by now it is frozen but perfectly readable.
        Material moonStone = MinespaceMaterials.lookup(MOON_STONE);
        if (moonStone == null) {
            LOG.error("Material '{}' is missing, so the Lunar stone type cannot be built. "
                    + "It must be registered from MaterialEvent.", MOON_STONE);
            return;
        }

        // The base is this mod's own rock block rather than Galacticraft's
        // basic_block_moon: see MinespaceMoonRock for why pointing GT at the Galacticraft
        // block renders the ore on the wrong base.
        Supplier<IBlockState> base = () -> MinespaceMoonRock.defaultState();
        Predicate<IBlockState> predicate =
                com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones.moonStonePredicate();

        // The processing prefix is deliberately OrePrefix.ore rather than a new prefix:
        // GTCEu 1.12.2 has no OrePrefix.registerOrePrefix, and an extra prefix would also
        // give the same ore block a second ore dictionary name.
        new StoneType(
                MOON_STONE_TYPE_ID,
                MOON_STONE,
                net.minecraft.block.SoundType.STONE,
                OrePrefix.ore,
                moonStone,
                base,
                predicate,
                false);

        registered = true;
        LOG.info("Registered GTCEu stone type '{}' (id {}) — ores on the Moon now use the Lunar rock base",
                MOON_STONE, MOON_STONE_TYPE_ID);
    }

    /**
     * Resolves the models of the Lunar ore and its base, exactly as GT's renderer will.
     *
     * <p>Run from the first client tick (see {@link MinespaceModelCheck}), not from init:
     * before the model bake every state answers with an unbaked stand-in, which reads as
     * "zero quads" and would fail a perfectly good block.
     *
     * <p>This exists because neither the registration logging nor the ore block's property
     * values prove the render: GT draws an ore as "the base model plus the ore overlay", so
     * a base state whose model never baked leaves the ore looking wrong while everything
     * else reports success.
     */
    public static void probeOreModels() {
        if (!registered) {
            return;
        }
        try {
            StoneType lunarType = null;
            for (BlockOre ore : MetaBlocks.ORES) {
                for (StoneType type : ore.STONE_TYPE.getAllowedValues()) {
                    if (MOON_STONE.equals(type.name)) {
                        lunarType = type;
                        break;
                    }
                }
                if (lunarType != null) {
                    break;
                }
            }
            if (lunarType == null) {
                LOG.error("GTCEu did not add the '{}' stone type to any ore block — the "
                        + "block-registry listener ran too late. Lunar ores will render on the "
                        + "overworld stone base.", MOON_STONE);
                return;
            }
            LOG.info("Verified: GTCEu gave its ore blocks a '{}' variant", MOON_STONE);

            net.minecraft.client.renderer.BlockRendererDispatcher dispatcher =
                    net.minecraft.client.Minecraft.getMinecraft().getBlockRendererDispatcher();

            // The vanilla-stone probe is a positive control: if it also reports no geometry,
            // the registry is simply not readable yet and this check proves nothing.
            probe(dispatcher, "vanilla stone", net.minecraft.init.Blocks.STONE.getDefaultState());
            probe(dispatcher, "minespace:moon_rock", MinespaceMoonRock.defaultState());
        } catch (Throwable t) {
            LOG.warn("Could not probe the Lunar ore models: {}", t.toString());
        }
    }

    /** Resolves one state's model and reports what the renderer would get. */
    private static boolean probe(net.minecraft.client.renderer.BlockRendererDispatcher dispatcher,
                                 String label, IBlockState state) {
        if (state == null) {
            LOG.info("probe {}: state is null", label);
            return false;
        }
        net.minecraft.client.renderer.block.model.IBakedModel model = dispatcher.getModelForState(state);
        if (model == null) {
            LOG.info("probe {}: no model", label);
            return false;
        }
        int quads = model.getQuads(state, null, 0L).size();
        for (net.minecraft.util.EnumFacing facing : net.minecraft.util.EnumFacing.values()) {
            quads += model.getQuads(state, facing, 0L).size();
        }
        LOG.info("probe {}: {} quads, model {}", label, quads, model.getClass().getName());
        return quads > 0;
    }
}
