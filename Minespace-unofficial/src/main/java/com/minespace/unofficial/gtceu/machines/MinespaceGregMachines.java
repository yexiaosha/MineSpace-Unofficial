package com.minespace.unofficial.gtceu.machines;

import com.minespace.unofficial.Minespace;
import gregtech.api.GregTechAPI;
import net.minecraft.util.ResourceLocation;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Registers this mod's own GregTech machines.
 *
 * <h2>When this may run</h2>
 *
 * GTCEu's meta tile entity registry is <b>unfrozen</b> during GTCEu's own preInit (it
 * registers its machines there) and <b>frozen</b> at the start of GTCEu's init. GTCEu posts
 * {@code GregTechAPI.RegisterEvent} for UI factories and covers, but deliberately not for
 * machines - the machine registry is simply left open for the whole preInit phase. This mod
 * declares {@code required-after:gregtech}, so its preInit runs after GTCEu's preInit and
 * before GTCEu's init, which is exactly the window: machines are registered from there, by
 * calling {@code MTE_REGISTRY.register(id, name, machine)} directly.
 *
 * <p>Registering from init or later fails, because the registry is frozen by then.
 *
 * <h2>Item form</h2>
 *
 * No item or block is registered here. GregTech's machine item is
 * {@code gregtech:machine} with the registry id as its metadata
 * ({@code MetaTileEntity#getStackForm}), so a machine registered with id 32000 is the item
 * {@code gregtech:machine:32000} and shows up in GregTech's machine creative tab and in JEI
 * on its own. The ids start at 32000, well above everything GTCEu registers for itself; the
 * registry's maximum is 32767.
 */
public final class MinespaceGregMachines {

    private static final Logger LOG = LogManager.getLogger("minespace");

    /** Registry id of the oxygen compressor. Also its item metadata: gregtech:machine:32000. */
    public static final int OXYGEN_COMPRESSOR_ID = 32000;

    public static final ResourceLocation OXYGEN_COMPRESSOR =
            new ResourceLocation(Minespace.MOD_ID, "oxygen_compressor");

    /** Registry id of the rocket fuel loader: gregtech:machine:32001. */
    public static final int ROCKET_FUEL_LOADER_ID = 32001;

    public static final ResourceLocation ROCKET_FUEL_LOADER =
            new ResourceLocation(Minespace.MOD_ID, "rocket_fuel_loader");

    private static boolean registered;

    private MinespaceGregMachines() {
    }

    /** Called from this mod's preInit. */
    public static void register() {
        if (registered) {
            return;
        }
        registered = true;

        // One try/catch per machine instead of around the whole method: a single bad machine
        // should not take the rest of them (or the game) down.
        try {
            GregTechAPI.MTE_REGISTRY.register(
                    OXYGEN_COMPRESSOR_ID, OXYGEN_COMPRESSOR,
                    new MetaTileEntityOxygenCompressor(OXYGEN_COMPRESSOR, 1));
            LOG.info("Registered GregTech machine {} as gregtech:machine:{}",
                    OXYGEN_COMPRESSOR, OXYGEN_COMPRESSOR_ID);
        } catch (Throwable t) {
            LOG.error("Could not register GregTech machine {}", OXYGEN_COMPRESSOR, t);
        }

        // Galacticraft-specific: only registered when Galacticraft is present. The class
        // itself references Galacticraft types, which is why it is never loaded without it.
        if (Minespace.hasGalacticraft()) {
            try {
                GregTechAPI.MTE_REGISTRY.register(
                        ROCKET_FUEL_LOADER_ID, ROCKET_FUEL_LOADER,
                        new MetaTileEntityRocketFuelLoader(ROCKET_FUEL_LOADER, 1));
                LOG.info("Registered GregTech machine {} as gregtech:machine:{}",
                        ROCKET_FUEL_LOADER, ROCKET_FUEL_LOADER_ID);
            } catch (Throwable t) {
                LOG.error("Could not register GregTech machine {}", ROCKET_FUEL_LOADER, t);
            }

        }
    }
}
