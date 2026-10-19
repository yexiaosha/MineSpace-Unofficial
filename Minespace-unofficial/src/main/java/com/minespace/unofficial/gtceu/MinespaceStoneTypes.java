package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import com.minespace.unofficial.MinespaceContent;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.material.type.DustMaterial;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.ore.StoneType;
import gregtech.common.blocks.BlockOre;
import gregtech.common.blocks.MetaBlocks;
import net.minecraft.block.Block;
import net.minecraft.block.state.IBlockState;
import net.minecraft.util.ResourceLocation;
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
 * The stone type has to exist <em>before</em> GTCE builds its ore blocks. In GTCE (and therefore
 * in GTCE-TJ) that happens much earlier than it did in GTCEu 2.8 - inside GT's own preInit:
 *
 * <pre>
 *   GregTechMod.preInit
 *     Materials.register()
 *     Material.runMaterialHandlers()    &lt;-- MinespaceMaterials.onMaterialsInit() runs here
 *     Material.freezeRegistry()
 *     MetaBlocks.init()                 &lt;-- StoneType.init() and the ore blocks are built here
 * </pre>
 *
 * The ore blocks are built by iterating {@code StoneType.STONE_TYPE_REGISTRY} 16 ids at a time and
 * baking the current ids into each block's {@code stone_type} property. A stone type that is not
 * in the registry at that instant is <b>not</b> in the ore block, and then
 * {@code FillerConfigUtils$OreFilterEntry.apply} - which does a plain
 * {@code blockStateMap.get(computeStoneType(...))} with no null guard - hands a null state to
 * {@code World.setBlockState} and the vein dies with a NullPointerException. Registering late is
 * therefore not "the ore looks wrong", it is "every vein that meets that rock throws".
 *
 * The only window in GTCE-TJ is between {@code runMaterialHandlers()} and
 * {@code MetaBlocks.init()}, i.e. inside this mod's material handler - see
 * {@link MinespaceMaterials#onMaterialsInit()}. Every block-based piece of a stone type (the
 * base state and the ore-gen predicate) is therefore resolved <em>lazily</em>: no other mod has
 * registered a block yet at that point, but worldgen and model baking only happen after all of
 * them have.
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
public final class MinespaceStoneTypes {

    private static final Logger LOG = LogManager.getLogger("minespace_core");

    /** Kept in the pack's 32000+ addon range, after the two existing materials. */
    // The material id for the Lunar rock is allocated at runtime in MinespaceMaterials: GTCE's
    // material registry has only 1000 slots and Gregicality already occupies much of the range.

    public static final String MOON_STONE = "moon_stone";

    /** Ids 0..15 are taken by GT's own stone types; the registry holds up to 128. */
    private static final int MOON_STONE_TYPE_ID = 16;

    private static boolean registered;

    private MinespaceStoneTypes() {
    }

    /**
     * Called from {@link MinespaceMaterials#onMaterialsInit()}, i.e. inside GT's preInit between
     * its own material registration and {@code MetaBlocks.init()}. That is the only moment early
     * enough for GT to bake this stone type into its ore blocks - see the class javadoc.
     */
    public static void register() {
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
        // GTCE's StoneType wants a stoneMaterial to name and build its ore block variant with.
        // GT's own Materials.Stone is exactly that, so this mod deliberately does not register a
        // material of its own for the rock: it keeps the addon's footprint in GT's shared
        // 1000-slot material registry as small as possible. The stone type's name and texture
        // below are still ours.
        DustMaterial stoneMaterial = Materials.Stone;

        // The base is this mod's own rock block rather than Galacticraft's
        // basic_block_moon: see MinespaceMoonRock for why pointing GT at the Galacticraft
        // block renders the ore on the wrong base.
        Supplier<IBlockState> base = () -> MinespaceMoonRock.defaultState();
        Predicate<IBlockState> predicate =
                com.minespace.unofficial.galacticraft.MinespaceGalacticraftStones.moonStonePredicate();

        // The processing prefix is deliberately OrePrefix.ore rather than a new prefix:
        // GTCEu 1.12.2 has no OrePrefix.registerOrePrefix, and an extra prefix would also
        // give the same ore block a second ore dictionary name.
        // GTCE's StoneType takes the ore's background texture explicitly (GTCEu derived it from
        // the block state model), plus a harvest tool and the stone type's flags.
        new StoneType(
                MOON_STONE_TYPE_ID,
                MOON_STONE,
                new ResourceLocation(MinespaceContent.NAMESPACE, "blocks/moon_rock"),
                net.minecraft.block.SoundType.STONE,
                OrePrefix.ore,
                stoneMaterial,
                "pickaxe",
                0,
                base,
                predicate);

        registered = true;
        LOG.info("Registered GregTech stone type '{}' (id {}) — ores on the Moon now use the Lunar rock base",
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
            MinespaceOreModelProbe.probeVanillaStone(dispatcher);
            MinespaceOreModelProbe.probe(dispatcher, "minespace:moon_rock", MinespaceMoonRock.defaultState());
        } catch (Throwable t) {
            LOG.warn("Could not probe the Lunar ore models: {}", t.toString());
        }
    }
}
