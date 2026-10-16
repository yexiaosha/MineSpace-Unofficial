package com.minespace.unofficial.gtceu;

import com.minespace.unofficial.Minespace;
import net.minecraft.block.BlockStone;
import net.minecraft.block.state.IBlockState;
import net.minecraft.init.Blocks;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;
import net.minecraft.world.biome.BiomeDecorator;
import net.minecraft.world.gen.feature.WorldGenerator;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.common.config.Configuration;
import net.minecraftforge.event.world.BlockEvent;
import net.minecraftforge.event.terraingen.BiomeEvent;
import net.minecraftforge.fml.common.eventhandler.EventPriority;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.File;
import java.util.LinkedHashSet;
import java.util.Locale;
import java.util.Random;
import java.util.Set;

/**
 * Switches off the vanilla worldgen blobs this pack does not want.
 *
 * <h2>Two different mechanisms, because they really are different</h2>
 *
 * <b>Vanilla ores</b> (coal, iron, gold, diamond, lapis, redstone, quartz, emerald) are handled by
 * GregTech's own {@code B:disableVanillaOres} switch in {@code config/gregtech.cfg} - it is set to
 * {@code true} in this pack, and measuring a fresh overworld shows all eight at exactly 0 blocks.
 * Nothing in this class duplicates that.
 *
 * <b>The granite / diorite / andesite patches</b> (and dirt, gravel, silverfish) are not ores and
 * cannot be switched off through the ore-event API: they are built by
 * {@code BiomeDecorator.generateOres} calling its {@code graniteGen}/{@code dioriteGen}/
 * {@code andesiteGen} generators directly, and this Forge build never posts
 * {@code OreGenEvent.GenerateMinable} at all (checked: nothing in the mapped Minecraft/Forge jar
 * references the event, and a temporary listener in a running server received zero events while
 * the blobs were being placed).
 *
 * <p>So this class hooks Forge's {@code BiomeEvent.CreateDecorator} - fired the first time Forge
 * hands a biome its decorator - and replaces the named generators with a no-op. The generator
 * fields are public, the event is the intended extension point, and it works for every biome,
 * Galacticraft's planets included (they decorate through the same vanilla path).
 *
 * <p><b>And Gregicality generates them too.</b> {@code gregicadditions.worldgen.StoneGenEvents}
 * listens to {@code BlockEvent.FluidPlaceBlockEvent} and rewrites the stone that lava and water
 * make into a diorite/granite/andesite variant - which is where the tens of thousands of those
 * blocks in a fresh world actually come from (measured: patching the vanilla generators alone left
 * the counts unchanged at ~90k blocks per 144 chunks). That handler runs at the default priority,
 * so this class listens at {@link EventPriority#LOWEST} and puts the result back to plain
 * cobblestone: vanilla's own outcome for lava meeting water, and what a cobblestone generator
 * should produce.
 *
 * <p>The names are the {@code BiomeDecorator} fields in the config file {@code config/minespace.cfg}:
 * {@code GRANITE, DIORITE, ANDESITE} for the stone patches, {@code DIRT} and {@code GRAVEL} for the
 * underground blobs, and {@code COAL, IRON, GOLD, REDSTONE, DIAMOND, LAPIS} for the overworld ores
 * (those are normally left to GT's switch). Silverfish and emerald do not own a field in this
 * {@code BiomeDecorator}, so they are not offered here.
 */
public final class MinespaceVanillaWorldgen {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** Never generates anything: the target of every replacement below. */
    private static final WorldGenerator NOTHING = new WorldGenerator() {
        @Override
        public boolean generate(World world, Random random, BlockPos position) {
            return false;
        }
    };

    private static final Set<String> DISABLED = new LinkedHashSet<>();

    private static boolean registered;

    private static final String[] KNOWN = {
            "GRANITE", "DIORITE", "ANDESITE", "DIRT", "GRAVEL",
            "COAL", "IRON", "GOLD", "REDSTONE", "DIAMOND", "LAPIS",
    };

    private MinespaceVanillaWorldgen() {
    }

    /** Called from this mod's preInit: reads the config, so the file exists before worldgen. */
    public static void configure(File suggestedConfig) {
        Configuration configuration = new Configuration(suggestedConfig);
        configuration.load();
        String[] configured = configuration.getStringList(
                "disabledVanillaGenerators",
                "worldgen",
                new String[] { "GRANITE", "DIORITE", "ANDESITE" },
                "Vanilla biome-decorator generators to replace with a no-op. GRANITE/DIORITE/"
                        + "ANDESITE are the stone patches, DIRT/GRAVEL the underground blobs, and "
                        + "COAL/IRON/GOLD/REDSTONE/DIAMOND/LAPIS the overworld ores (normally left "
                        + "to GT's own B:disableVanillaOres switch in gregtech.cfg). Valid names: "
                        + String.join(", ", KNOWN) + ".");
        if (configuration.hasChanged()) {
            configuration.save();
        }

        for (String name : configured) {
            String trimmed = name.trim().toUpperCase(Locale.ROOT);
            if (trimmed.isEmpty()) {
                continue;
            }
            boolean known = false;
            for (String candidate : KNOWN) {
                if (candidate.equals(trimmed)) {
                    known = true;
                    break;
                }
            }
            if (known) {
                DISABLED.add(trimmed);
            } else {
                LOG.warn("Unknown vanilla generator '{}' in minespace.cfg - ignoring it. "
                        + "Valid names: {}", trimmed, String.join(", ", KNOWN));
            }
        }
    }

    /** Called from this mod's init, before any world is decorated. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;
        MinecraftForge.EVENT_BUS.register(MinespaceVanillaWorldgen.class);

        // Mutating the biomes up front, rather than waiting for Forge's CreateDecorator event, is
        // what actually takes effect here: every biome already carries its decorator object at
        // this point (Forge wraps it in a DeferredBiomeDecorator), and that event does not
        // necessarily fire before the first world is decorated. Forge's deferred wrapper copies
        // its own fields into the real decorator on first use, so setting them on both objects
        // covers either direction.
        LOG.info("Suppressing vanilla biome generators {} ({} biomes patched at init)",
                DISABLED, patchAllBiomes());
    }

    /**
     * Applies the replacement to every registered biome's decorator, and to the decorator Forge's
     * deferred wrapper will hand over to. Called at init and again whenever a world loads, because
     * Forge builds (and can rebuild) the effective decorator lazily.
     */
    private static int patchAllBiomes() {
        int patched = 0;
        for (net.minecraft.world.biome.Biome biome
                : net.minecraftforge.fml.common.registry.ForgeRegistries.BIOMES) {
            BiomeDecorator decorator = biome.decorator;
            if (decorator == null) {
                continue;
            }
            apply(decorator);
            BiomeDecorator wrapped = unwrap(decorator);
            if (wrapped != null) {
                apply(wrapped);
            }
            patched++;
        }
        return patched;
    }

    @SubscribeEvent
    public static void onWorldLoad(net.minecraftforge.event.world.WorldEvent.Load event) {
        patchAllBiomes();
    }

    /**
     * The reliable hook: Forge's decorator plumbing replaces or re-creates the decorator around
     * world load, so patching the biomes up front is not enough - the world ends up decorating
     * with generators we never touched. This event is posted at the very top of
     * {@code BiomeDecorator.decorate}, i.e. immediately before the ore pass that calls those
     * generators, so patching here is always in time.
     */
    @SubscribeEvent
    public static void onDecoratePre(net.minecraftforge.event.terraingen.DecorateBiomeEvent.Pre event) {
        patch(event.getWorld().getBiome(event.getPos()));
        // The world hands out its own biome instances, which are not necessarily the registered
        // ones - so patch every biome this chunk's provider reports, not just the reported one.
        try {
            net.minecraft.world.biome.Biome[] biomes = event.getWorld().getBiomeProvider()
                    .getBiomes(null, (event.getPos().getX() >> 4) << 4,
                            (event.getPos().getZ() >> 4) << 4, 16, 16, false);
            if (biomes != null) {
                for (net.minecraft.world.biome.Biome biome : biomes) {
                    patch(biome);
                }
            }
        } catch (Throwable t) {
            LOG.warn("Could not patch the chunk's biomes: {}", t.toString());
        }
    }

    private static void patch(net.minecraft.world.biome.Biome biome) {
        if (biome == null || biome.decorator == null) {
            return;
        }
        apply(biome.decorator);
        BiomeDecorator wrapped = unwrap(biome.decorator);
        if (wrapped != null) {
            apply(wrapped);
        }
    }

    @SubscribeEvent
    public static void onCreateDecorator(BiomeEvent.CreateDecorator event) {
        BiomeDecorator decorator = event.getNewBiomeDecorator();
        if (decorator == null) {
            return;
        }
        apply(decorator);
    }

    /**
     * Undoes Gregicality's lava-to-stone-variant flavour. Runs last, so the state it sees is
     * already Gregicality's; only the vanilla stone variants are rewritten, so the
     * lava-source-to-obsidian case and everything else is left exactly as it was.
     */
    @SubscribeEvent(priority = EventPriority.LOWEST)
    public static void onFluidPlaced(BlockEvent.FluidPlaceBlockEvent event) {
        IBlockState state = event.getNewState();
        if (state == null || state.getBlock() != Blocks.STONE) {
            return;
        }
        BlockStone.EnumType variant = state.getValue(BlockStone.VARIANT);
        if (variant != null && DISABLED.contains(variant.name())) {
            event.setNewState(Blocks.COBBLESTONE.getDefaultState());
        }
    }

    /** The decorator Forge's deferred wrapper will hand over to, or null for a plain one. */
    private static BiomeDecorator unwrap(BiomeDecorator decorator) {
        if (!(decorator instanceof net.minecraftforge.event.terraingen.DeferredBiomeDecorator)) {
            return null;
        }
        try {
            java.lang.reflect.Field field = net.minecraftforge.event.terraingen
                    .DeferredBiomeDecorator.class.getDeclaredField("wrapped");
            field.setAccessible(true);
            return (BiomeDecorator) field.get(decorator);
        } catch (Throwable t) {
            LOG.warn("Could not unwrap Forge's deferred biome decorator: {}", t.toString());
            return null;
        }
    }

    private static void apply(BiomeDecorator decorator) {
        for (String name : DISABLED) {
            switch (name) {
                case "GRANITE":
                    decorator.graniteGen = NOTHING;
                    break;
                case "DIORITE":
                    decorator.dioriteGen = NOTHING;
                    break;
                case "ANDESITE":
                    decorator.andesiteGen = NOTHING;
                    break;
                case "DIRT":
                    decorator.dirtGen = NOTHING;
                    break;
                case "GRAVEL":
                    decorator.gravelOreGen = NOTHING;
                    break;
                case "COAL":
                    decorator.coalGen = NOTHING;
                    break;
                case "IRON":
                    decorator.ironGen = NOTHING;
                    break;
                case "GOLD":
                    decorator.goldGen = NOTHING;
                    break;
                case "REDSTONE":
                    decorator.redstoneGen = NOTHING;
                    break;
                case "DIAMOND":
                    decorator.diamondGen = NOTHING;
                    break;
                case "LAPIS":
                    decorator.lapisGen = NOTHING;
                    break;
                default:
                    break;
            }
        }
    }
}
