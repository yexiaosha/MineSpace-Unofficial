package com.minespace.unofficial.galacticraft;

import micdoodle8.mods.galacticraft.api.GalacticraftRegistry;
import micdoodle8.mods.galacticraft.api.galaxies.CelestialBody;
import micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry;
import micdoodle8.mods.galacticraft.api.item.ElectricItemHelper;
import micdoodle8.mods.galacticraft.api.item.IItemElectric;
import micdoodle8.mods.galacticraft.api.power.IEnergyStorageGC;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraft.world.WorldProvider;

/**
 * Galacticraft integration helpers.
 *
 * <p>Everything here is a thin, null-safe wrapper over Galacticraft's own API, so the
 * rest of the mod never has to touch GC classes directly. The mod declares
 * Galacticraft as {@code after:} rather than {@code required-after:}, so callers must
 * check {@link com.minespace.unofficial.Minespace#hasGalacticraft()} first.
 *
 * <p>Every method name and signature below was checked against the Galacticraft 4.0.7
 * jar. Nothing here is guessed.
 *
 * <h2>The GTCEu &lt;-&gt; Galacticraft energy boundary</h2>
 *
 * This is the single most useful integration point between the two mods, and it is
 * worth being precise about where the work sits:
 *
 * <pre>
 *   GTCEu side                    boundary                 GC side
 *   ----------                    --------                 -------
 *   IEnergyContainer      --&gt;  IEnergyStorageGC   &lt;--  GC machines / wires
 *   (long EU, tiers)           (float gJ, no tier)        (connect by adjacency)
 * </pre>
 *
 * {@link IEnergyStorageGC} is the interface GC machines and cables look for on a
 * neighbouring tile entity. A GTCEu addon therefore does not need to register
 * anything with GC: it implements the interface on its own tile entity and GC finds
 * it by itself. {@link #gcBridge} below is that implementation in its minimal form,
 * and is the piece to copy.
 *
 * <p>The reverse direction (a GC block powering a GTCEu machine) needs a GC
 * {@code TileEntity} subclass, which is GC-internal rather than API; that is left as
 * an exercise and is documented in DEV-NOTES.md.
 */
public final class MinespaceGalacticraft {

    /** Galacticraft's dungeon-chest tier for the Moon. */
    public static final int MOON_DUNGEON_TIER = 1;

    private MinespaceGalacticraft() {
    }

    // ------------------------------------------------------------------ registry

    /**
     * Adds an item to Galacticraft's dungeon loot for a tier.
     *
     * <p>Note the shape: GC takes a tier integer, not a celestial body. Passing an
     * {@link ItemStack} of one of this mod's GTCEu materials is the usual way to make
     * an addon material obtainable on the Moon.
     */
    public static void addDungeonLoot(int tier, ItemStack stack) {
        if (stack == null || stack.isEmpty()) {
            return;
        }
        GalacticraftRegistry.addDungeonLoot(tier, stack);
    }

    /**
     * Looks a celestial body up by its Galacticraft unlocalised name, e.g. "moon",
     * "mars".
     *
     * <p>Note the method name: Galacticraft has no plain {@code getCelestialBody(String)}.
     * The available lookups are {@code getCelestialBodyFromUnlocalizedName(String)},
     * {@code getCelestialBodyFromDimensionID(int)} and
     * {@code getPlanetOrMoonFromTranslationkey(String)}.
     *
     * @return the body, or null when it is not registered
     */
    public static CelestialBody body(String unlocalizedName) {
        return GalaxyRegistry.getCelestialBodyFromUnlocalizedName(unlocalizedName);
    }

    /** True when the named celestial body exists. Handy for guarding optional hooks. */
    public static boolean hasBody(String unlocalizedName) {
        return body(unlocalizedName) != null;
    }

    /** The celestial body owning a dimension id, or null. */
    public static CelestialBody bodyForDimension(int dimensionId) {
        return GalaxyRegistry.getCelestialBodyFromDimensionID(dimensionId);
    }

    /** The Moon, or null if Galacticraft did not register it. */
    public static CelestialBody moon() {
        return body("moon");
    }

    /**
     * Registers the rocket GUI texture for a world provider. This is the hook an addon
     * uses when it adds its own dimension and wants Galacticraft's rocket UI.
     */
    public static void registerRocketGui(Class<? extends WorldProvider> worldProvider, ResourceLocation gui) {
        if (worldProvider == null || gui == null) {
            return;
        }
        GalacticraftRegistry.registerRocketGui(worldProvider, gui);
    }

    // ------------------------------------------------------------------- energy

    /**
     * Adapts a GTCEu-style EU buffer to the interface Galacticraft machines look for
     * on neighbouring blocks.
     *
     * <p>Units: GC works in {@code float} gJ with no tiers; GTCEu works in {@code long}
     * EU with voltage tiers. This adapter deliberately does <b>not</b> invent a
     * conversion ratio — that is a balance decision. It uses 1 EU = 1 gJ and leaves the
     * ratio as a single obvious constant so it is easy to change.
     *
     * <p>Usage: hold one of these in your tile entity and return it from
     * {@code getCapability} / from a GC interface probe, then GC machines adjacent to
     * the block will charge from it.
     */
    public static final class GcEnergyBridge implements IEnergyStorageGC {

        /** GC gJ per GTCEu EU. 1.0 is the neutral starting point; tune as needed. */
        public static final float GJ_PER_EU = 1.0F;

        private final IEnergyBuffer buffer;

        public GcEnergyBridge(IEnergyBuffer buffer) {
            this.buffer = buffer;
        }

        @Override
        public float receiveEnergyGC(float amount, boolean simulate) {
            // GC pushing into us: convert and hand it to the EU buffer.
            long eu = (long) (amount / GJ_PER_EU);
            long accepted = buffer.insertEnergy(eu, simulate);
            return accepted * GJ_PER_EU;
        }

        @Override
        public float extractEnergyGC(float amount, boolean simulate) {
            // GC pulling from us: the direction that powers GC machines.
            long eu = (long) (amount / GJ_PER_EU);
            long extracted = buffer.extractEnergy(eu, simulate);
            return extracted * GJ_PER_EU;
        }

        @Override
        public float getEnergyStoredGC() {
            return buffer.getEnergyStored() * GJ_PER_EU;
        }

        @Override
        public float getCapacityGC() {
            return buffer.getEnergyCapacity() * GJ_PER_EU;
        }
    }

    /**
     * The small slice of EU-buffer behaviour {@link GcEnergyBridge} needs. Keep this
     * interface as narrow as possible; implement it on your GTCEu tile entity by
     * delegating to whatever {@code IEnergyContainer} you already expose.
     */
    public interface IEnergyBuffer {

        /** Store up to {@code amount} EU; return how much was actually taken. */
        long insertEnergy(long amount, boolean simulate);

        /** Remove up to {@code amount} EU; return how much was actually given. */
        long extractEnergy(long amount, boolean simulate);

        long getEnergyStored();

        long getEnergyCapacity();
    }

    /**
     * GC's own helper for charging an electric <em>item</em> (battery, drill, armour)
     * from an amount of gJ. Wraps {@link ElectricItemHelper} so callers do not need the
     * GC class directly.
     *
     * @return the gJ actually consumed
     */
    public static float chargeElectricItem(ItemStack stack, float amountGJ) {
        if (stack == null || stack.isEmpty() || !(stack.getItem() instanceof IItemElectric)) {
            return 0.0F;
        }
        return ElectricItemHelper.chargeItem(stack, amountGJ);
    }
}
