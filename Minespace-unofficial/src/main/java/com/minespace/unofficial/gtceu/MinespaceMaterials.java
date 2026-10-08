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
import gregtech.api.unification.stack.MaterialStack;
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
    public static final int DESH_ID = 32003;
    public static final int SOLAR_ID = 32004;
    public static final int MARS_STONE_ID = 32005;
    public static final int VENUS_STONE_ID = 32006;
    public static final int ASTEROID_STONE_ID = 32007;
    /** Ores that only Galaxy Space generated; see the note where they are registered. */
    public static final int DOLOMITE_ID = 32120;
    public static final int ONYX_ID = 32121;

    public static final String DESH_STEEL = "desh_steel";
    public static final String METEORIC_IRON = "meteoric_iron";
    public static final String DESH = "desh";
    public static final String SOLAR = "solar";
    public static final String MARS_STONE = "mars_stone";
    public static final String VENUS_STONE = "venus_stone";
    public static final String ASTEROID_STONE = "asteroid_stone";
    public static final String DOLOMITE = "dolomite";
    public static final String ONYX = "onyx";

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
        // ------------------------------------------------------------------
        // The two metals come first: desh_steel (below) is declared as an alloy of them, and
        // a components() list needs the Material objects to exist already.
        // ------------------------------------------------------------------
        //
        // Galacticraft's own Mars / Venus ores. Galacticraft's generation for both is
        // disabled in its config and replaced by GregTech veins, so the metal has to be a
        // real GT material carrying the ore prefix: that is what makes GT build the ore
        // block, its stone-type variants and the ore dictionary entries.
        //
        // The names must stay Galacticraft's. GT registers oreDesh / dustDesh / ingotDesh /
        // blockDesh for "desh", and Galacticraft's rocket and block recipes look the metal
        // up by exactly those ore dictionary names, so a differently named material would
        // silently leave the tier 2 rocket uncraftable.
        new Material.Builder(DESH_ID, new ResourceLocation(NAMESPACE, DESH))
                .dust()
                .ingot()
                .ore()
                .color(0xE0A64B)
                .iconSet(MaterialIconSet.METALLIC)
                .build();

        // ore() as well: the Martian desh vein lists meteoric iron as one of its four
        // layers, and GTCEu can only place an ore block for a material that carries the
        // ore flag.
        new Material.Builder(METEORIC_IRON_ID, new ResourceLocation(NAMESPACE, METEORIC_IRON))
                .dust()
                .ingot()
                .ore()
                .color(0x8A7F73)
                .iconSet(MaterialIconSet.ROUGH)
                .build();

        // ------------------------------------------------------------------
        // desh_steel — the alloy that gives desh a place in the GregTech chain.
        //
        // Declaring the components is what makes GTCEu generate the mixer and alloy
        // smelter recipes for it. Without them the material is inert: it has items, but
        // nothing consumes or produces it, which is exactly the "no real use" state the
        // desh vein was in.
        // ------------------------------------------------------------------
        Material desh = lookup(DESH);
        // GTCEu's own registry is keyed by bare names; ours needs the namespace (see lookup).
        Material steel = GregTechAPI.materialManager.getMaterial("steel");
        Material.Builder deshSteel = new Material.Builder(DESH_STEEL_ID, new ResourceLocation(NAMESPACE, DESH_STEEL))
                .ingot()
                .fluid()
                .color(0x4C5A63)
                .iconSet(MaterialIconSet.METALLIC);
        if (desh != null && steel != null) {
            deshSteel.components(new MaterialStack(desh, 1), new MaterialStack(steel, 1));
        } else {
            LOG.warn("desh_steel has no components (desh={}, steel={}) — the alloy recipe will be missing",
                    desh, steel);
        }
        deshSteel.build();

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

        // One dust-only material per Galaxy Space celestial body, so that body's stone type has
        // something to hang on (see MinespaceGalaxySpacePlanets / MinespaceGalaxySpaceStones).
        // Registered unconditionally: without Galaxy Space they are simply unused, and this keeps
        // the stone type registration free of Galaxy Space types.
        for (MinespaceGalaxySpacePlanets.Planet planet : MinespaceGalaxySpacePlanets.PLANETS) {
            new Material.Builder(planet.materialId, new ResourceLocation(NAMESPACE, planet.stoneName()))
                    .dust()
                    .color(planet.color)
                    .build();
        }

        new Material.Builder(SOLAR_ID, new ResourceLocation(NAMESPACE, SOLAR))
                .dust()
                .ore()
                .color(0xFFE873)
                .iconSet(MaterialIconSet.DULL)
                .build();

        // Rock materials behind the Mars / Venus / Asteroid stone types, exactly like
        // moon_stone above: these exist so MinespacePlanetStoneTypes has a material to hang
        // each stone type on.
        new Material.Builder(MARS_STONE_ID, new ResourceLocation(NAMESPACE, MARS_STONE))
                .dust()
                .color(0x9A4C2A)
                .build();

        new Material.Builder(VENUS_STONE_ID, new ResourceLocation(NAMESPACE, VENUS_STONE))
                .dust()
                .color(0xC8A55B)
                .build();

        new Material.Builder(ASTEROID_STONE_ID, new ResourceLocation(NAMESPACE, ASTEROID_STONE))
                .dust()
                .color(0x7A7166)
                .build();

        // The two ores only Galaxy Space generated, so that turning its ore generation off does
        // not delete them from the pack. A probe of the ore dictionary showed why they need to
        // be real GT materials:
        //
        //   oreDolomite existed (Galaxy Space's ore block registered it) but there was no
        //   dolomite item at all, so a GT vein has to be what puts oreDolomite back;
        //   Galaxy Space's onyx was not in the ore dictionary under any name, so a GT material
        //   is the only way to make it obtainable.
        //
        // Both carry ore() and can therefore be placed by a vein (see the dolomite and onyx vein
        // files under config/gregtech/worldgen/vein).
        new Material.Builder(DOLOMITE_ID, new ResourceLocation(NAMESPACE, DOLOMITE))
                .dust()
                .ore()
                .color(0xC8BFA8)
                .iconSet(MaterialIconSet.DULL)
                .build();

        new Material.Builder(ONYX_ID, new ResourceLocation(NAMESPACE, ONYX))
                .gem()
                .ore()
                .color(0x2E2A33)
                .iconSet(MaterialIconSet.SHINY)
                .build();

        // One material per Galaxy Space body and per Galaxy Space-only ore on top of the eight
        // registered above, so the count is computed rather than spelled out.
        int total = 8 + MinespaceGalaxySpacePlanets.PLANETS.size() + 2;
        LOG.info("Registered {} GregTech materials in registry '{}': {}, {}, {}, {}, {}, {}, {}, {}, "
                        + "{} Galaxy Space stone materials and {} Galaxy Space-only ores",
                total, NAMESPACE, DESH_STEEL, METEORIC_IRON, DESH, SOLAR,
                MARS_STONE, VENUS_STONE, ASTEROID_STONE, MinespaceStoneTypes.MOON_STONE,
                MinespaceGalaxySpacePlanets.PLANETS.size(), 2);
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
