package com.minespace.unofficial.gtceu;

import gregtech.api.GregTechAPI;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.material.Material;
import gregtech.api.unification.material.event.MaterialEvent;
import gregtech.api.unification.material.event.MaterialRegistryEvent;
import gregtech.api.unification.material.info.MaterialIconSet;
import gregtech.api.unification.material.registry.IMaterialRegistryManager;
import gregtech.api.unification.material.registry.MaterialRegistry;
import gregtech.api.unification.ore.OrePrefix;
import net.minecraft.item.ItemStack;
import net.minecraft.util.ResourceLocation;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;

/**
 * Registers this mod's GregTech materials.
 *
 * <h2>The GTCEu material registration contract</h2>
 *
 * This is the part that is easy to get wrong, and getting it wrong produces a
 * hard crash rather than a warning. GTCEu registers everything inside its own
 * {@code CoreModule.preInit}, in this exact order:
 *
 * <pre>
 *   1. post MaterialRegistryEvent        phase is PRE
 *        addons call createRegistry()     &lt;-- only legal while phase == PRE
 *   2. unfreezeRegistries()              phase PRE -> OPEN
 *   3. GTCEu registers its own materials
 *   4. post MaterialEvent                phase is OPEN
 *        addons call register(material)   &lt;-- only legal while phase == OPEN
 *   5. freezeRegistries()                phase -> FROZEN, items get generated
 * </pre>
 *
 * Two consequences:
 *
 * <ul>
 *   <li>Creating the registry in this mod's own {@code preInit} is <b>too late</b>
 *       — it runs after GTCEu's preInit, so the manager is already FROZEN and
 *       {@code createRegistry} throws {@code IllegalStateException: Cannot create
 *       registries in phase FROZEN}. That is exactly what happened on the first
 *       version of this class.</li>
 *   <li>Materials must be added from {@link MaterialEvent}, not from
 *       {@link MaterialRegistryEvent}: at registry-event time the phase is still
 *       PRE, and nothing may be added yet.</li>
 * </ul>
 *
 * Both events are Forge generic events over {@link Material}, firing on each phase
 * transition, which is what makes this independent of addon load order.
 */
@Mod.EventBusSubscriber(modid = com.minespace.unofficial.Minespace.MOD_ID)
public final class MinespaceMaterials {

    /** Must match the id given to createRegistry; also becomes the item namespace. */
    public static final String NAMESPACE = com.minespace.unofficial.Minespace.MOD_ID;

    /**
     * Material ids. Must be unique across GTCEu and every addon: the builder takes a
     * numeric id and GTCEu keeps its own below 32000.
     */
    public static final int DESH_STEEL_ID = 32000;
    public static final int METEORIC_IRON_ID = 32001;

    public static final String DESH_STEEL = "desh_steel";
    public static final String METEORIC_IRON = "meteoric_iron";

    private MinespaceMaterials() {
    }

    /**
     * An immediately usable logger.
     *
     * <p>Deliberately not {@code Minespace.log()}: GTCEu runs its whole preInit —
     * including firing {@link MaterialEvent} — <em>before</em> this mod's own preInit,
     * because of {@code required-after:gregtech}. The logger in the main mod class is
     * therefore still null at this point, and using it here throws a
     * {@code NullPointerException} that surfaces as a crash "from GregTech".
     */
    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace");

    /**
     * Step 1 of the contract: create this mod's registry while the manager is still
     * in the PRE phase. GTCEu fires {@link MaterialRegistryEvent} precisely so addons
     * can do this, so this must NOT be called from preInit.
     */
    @SubscribeEvent
    public static void onMaterialRegistry(MaterialRegistryEvent event) {
        IMaterialRegistryManager manager = GregTechAPI.materialManager;
        if (manager == null) {
            return;
        }
        if (manager.getPhase() != IMaterialRegistryManager.Phase.PRE) {
            // Should not happen; logged because it means the contract changed and this
            // class needs revisiting rather than failing silently.
            LOG.warn(
                    "MaterialRegistryEvent fired in phase {} (expected PRE) — skipping registry creation",
                    manager.getPhase());
            return;
        }
        manager.createRegistry(NAMESPACE);
    }

    /**
     * Step 2 of the contract: add materials while the manager is OPEN. GTCEu
     * unfreezes the registries right before firing this event.
     */
    @SubscribeEvent
    public static void onMaterial(MaterialEvent event) {
        IMaterialRegistryManager manager = GregTechAPI.materialManager;
        if (manager == null || manager.getPhase() != IMaterialRegistryManager.Phase.OPEN) {
            return;
        }
        registerMaterials(manager.getRegistry(NAMESPACE));
    }

    private static void registerMaterials(MaterialRegistry registry) {
        if (registry == null) {
            LOG.error(
                    "GTCEu material registry '{}' does not exist — was it created from MaterialRegistryEvent?",
                    NAMESPACE);
            return;
        }

        // dust() / ingot() / gem() add the matching MaterialFlag, and GTCEu then
        // generates the items, the ore dictionary entries and the crafting/machine
        // recipes for them. No manual item registration is needed or possible.
        //
        // Builder.build() ALREADY registers the material with the registry that is
        // current for the calling mod. Calling registry.register(material) afterwards
        // therefore fails with:
        //   "Tried to reassign id 32000 to desh_steel (desh_steel), but it is already
        //    assigned to desh_steel (desh_steel)"
        // which reads confusingly because the "conflict" is the object with itself.
        // So: build(), and nothing else.
        new Material.Builder(DESH_STEEL_ID, new ResourceLocation(NAMESPACE, DESH_STEEL))
                .ingot()
                .fluid()
                .color(0x4C5A63)
                .iconSet(MaterialIconSet.METALLIC)
                .build();

        new Material.Builder(METEORIC_IRON_ID, new ResourceLocation(NAMESPACE, METEORIC_IRON))
                .dust()
                .ingot()
                .color(0x8A7F73)
                .iconSet(MaterialIconSet.ROUGH)
                .build();

        // The rock type behind MinespaceStoneTypes' Lunar stone type. It MUST be added
        // from here, not from preInit: GTCEu froze the registries at the end of this
        // event, so registering later logs
        //   "Materials cannot be registered in the PostMaterialEvent (or after)!"
        // and silently drops the material. Note this is only the Material — the
        // StoneType itself cannot be built yet, because Galacticraft's block is not in
        // the block registry until after every mod's preInit. See MinespaceStoneTypes.
        new Material.Builder(
                MinespaceStoneTypes.MOON_STONE_ID,
                new ResourceLocation(NAMESPACE, MinespaceStoneTypes.MOON_STONE))
                .dust()
                .color(0x636362)
                .build();

        LOG.info("Registered 3 GregTech materials in registry '{}': {}, {}, {}",
                NAMESPACE, DESH_STEEL, METEORIC_IRON, MinespaceStoneTypes.MOON_STONE);
    }

    /**
     * The GTCEu item for one of this mod's materials, e.g.
     * {@code stack(OrePrefix.ingot, DESH_STEEL)}.
     *
     * <p>Only valid after materials are frozen (postInit onwards); before that the
     * items do not exist yet and the result is empty.
     */
    public static ItemStack stack(OrePrefix prefix, String materialName) {
        Material material = lookup(materialName);
        if (material == null) {
            return ItemStack.EMPTY;
        }
        return OreDictUnifier.get(prefix, material);
    }

    /**
     * The registered material, or null when it was never registered.
     *
     * <p>Note the key format: {@code IMaterialRegistryManager#getMaterial} is keyed by
     * the <b>full</b> registry name including the namespace, e.g.
     * {@code "minespace:desh_steel"}. Passing the bare path ({@code "desh_steel"})
     * silently returns null, which looks exactly like the material never registered —
     * this cost a debugging round, hence the explicit note.
     *
     * <p>Callers may pass either form; the namespace is added when it is missing.
     */
    public static Material lookup(String materialName) {
        if (GregTechAPI.materialManager == null) {
            return null;
        }
        String key = materialName.contains(":") ? materialName : NAMESPACE + ":" + materialName;
        return GregTechAPI.materialManager.getMaterial(key);
    }
}
