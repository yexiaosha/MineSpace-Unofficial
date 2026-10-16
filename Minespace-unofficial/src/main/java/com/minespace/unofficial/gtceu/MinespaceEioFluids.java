package com.minespace.unofficial.gtceu;

import gregtech.api.unification.material.type.FluidMaterial;
import gregtech.common.MetaFluids;
import net.minecraftforge.fluids.Fluid;
import net.minecraftforge.fluids.FluidRegistry;

import java.lang.reflect.Field;
import java.util.Map;

/**
 * Hands GregTech the fluids Ender IO registered, instead of letting GregTech make its own.
 *
 * <h2>Why this is a second step</h2>
 *
 * {@link MinespaceMaterials} registers Ender IO's ten fluids as GregTech {@code FluidMaterial}s while
 * GregTech's material list is still open - that happens in GregTech's preInit, long before Ender IO
 * has registered anything. The materials are created with
 * {@code shouldGenerateFluid() == false}, so GregTech deliberately does <em>not</em> build a fluid of
 * its own under those names. That leaves the name free for the mod: Ender IO registers its fluids from
 * Forge's {@code RegistryEvent.Register<Block>}, which fires after every mod's preInit, and its
 * {@code FluidRegistry.registerFluid} then succeeds as it always did.
 *
 * <p>This class closes the loop, from the addon's own {@code init} - the first point at which Ender
 * IO's fluids are guaranteed to be in the registry:
 *
 * <ol>
 *   <li>{@code material.setMaterialFluid(fluid)} - the material now <em>is</em> that fluid, so
 *       GregTech machines, tanks, pipes and recipe writers see Ender IO's fluid as GregTech's;</li>
 *   <li>the fluid is recorded in GregTech's own {@code MetaFluids.fluidToMaterialMappings}, the map
 *       {@code MetaFluids.getMaterialFromFluid} reads. GregTech fills that map when <em>it</em>
 *       creates a fluid, and a material that adopted somebody else's fluid is not in it, which would
 *       cost the fluid its GregTech tooltip and any code that asks "which material is this fluid".
 *       The field is private, so it goes in by reflection, guarded so a GregTech rename is a warning
 *       and not a crash.</li>
 * </ol>
 *
 * <p>Nothing is created and nothing is replaced: there is exactly one fluid object per name, it is
 * the one Ender IO's Vat, Tank, Enchanter and conduits already use, and it now belongs to a GregTech
 * material. Idempotent, so it runs from {@code init} and again from {@code postInit} as a safety net.
 */
public final class MinespaceEioFluids {

    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace");

    private MinespaceEioFluids() {
    }

    /**
     * Adopts every Ender IO fluid that has been registered by the time this runs.
     *
     * @param phase the caller, for the log line
     * @return the number of fluids adopted by this call
     */
    public static int adopt(String phase) {
        int adopted = 0;
        int missing = 0;
        for (Map.Entry<String, FluidMaterial> entry : MinespaceMaterials.enderIoFluids().entrySet()) {
            String name = entry.getKey();
            FluidMaterial material = entry.getValue();
            if (material == null) {
                continue;
            }
            if (material.getMaterialFluid() != null) {
                // Already done on an earlier pass - the whole method is idempotent.
                continue;
            }
            Fluid fluid = FluidRegistry.getFluid(name);
            if (fluid == null) {
                // Forge keeps a mod's fluids under its own name unless the mod prefixed them.
                fluid = FluidRegistry.getFluid("enderio:" + name);
            }
            if (fluid == null) {
                missing++;
                continue;
            }
            material.setMaterialFluid(fluid);
            adopted++;
            if (adopted <= 3) {
                LOG.info("adopted Ender IO fluid '{}' as GregTech's material '{}'",
                        fluid.getName(), material.toString());
            }
            recordInGregTechMap(fluid, material);
        }
        LOG.info("Ender IO fluids as GregTech fluids ({} pass): {} adopted, {} not registered yet",
                phase, adopted, missing);
        return adopted;
    }

    /**
     * Adds the fluid to GregTech's own fluid-to-material map, so {@code MetaFluids.getMaterialFromFluid}
     * answers for it the way it does for a fluid GregTech created itself.
     */
    @SuppressWarnings("unchecked")
    private static void recordInGregTechMap(Fluid fluid, FluidMaterial material) {
        try {
            Field field = MetaFluids.class.getDeclaredField("fluidToMaterialMappings");
            field.setAccessible(true);
            Object value = field.get(null);
            if (value instanceof Map) {
                ((Map<String, FluidMaterial>) value).put(fluid.getName(), material);
            }
        } catch (Throwable t) {
            LOG.warn("could not record Ender IO's fluid '{}' in GregTech's fluid-to-material map",
                    fluid.getName(), t);
        }
    }
}
