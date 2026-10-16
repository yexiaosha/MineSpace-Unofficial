package com.minespace.unofficial.gtceu;

import com.google.common.collect.ImmutableList;
import gregtech.api.unification.OreDictUnifier;
import gregtech.api.unification.material.IMaterialHandler;
import gregtech.api.unification.material.MaterialIconSet;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.material.type.DustMaterial;
import gregtech.api.unification.material.type.FluidMaterial;
import gregtech.api.unification.material.type.GemMaterial;
import gregtech.api.unification.material.type.IngotMaterial;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.ore.OrePrefix;
import gregtech.api.unification.stack.MaterialStack;
import net.minecraft.item.ItemStack;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Registers this mod's GregTech materials.
 *
 * <h2>The GTCE / TJ material contract</h2>
 *
 * This file was ported from GregTech CE: Unofficial (see {@code TJ-MIGRATION-PLAN.md}). The two
 * forks look similar but register materials in completely different ways:
 *
 * <pre>
 *   GTCEu 2.8   : two-stage events, MaterialRegistryEvent (phase PRE) then MaterialEvent
 *                 (phase OPEN), with `new Material.Builder(id, name).ingot().build()`
 *   GTCE / TJ   : an IMaterialHandler implementation, discovered through the
 *                 &#64;IMaterialHandler.RegisterMaterialHandler annotation, whose
 *                 onMaterialsInit() runs before GT builds its own material-driven items.
 *                 Materials are typed objects with constructors (IngotMaterial, DustMaterial,
 *                 GemMaterial, FluidMaterial, ...) and a `long` bitmask of MatFlags.
 * </pre>
 *
 * There is also no per-mod material namespace any more: GTCE keeps one global material list and
 * generates every material's items into its own meta item, so the old
 * {@code minespace:desh_steel} key is gone. What survives - and is what Galacticraft's own
 * recipes and this pack's CraftTweaker scripts actually depend on - are the ore dictionary
 * names derived from the material name, e.g. {@code ingotDesh}, {@code dustDesh},
 * {@code oreDesh}.
 */
@IMaterialHandler.RegisterMaterialHandler
public final class MinespaceMaterials implements IMaterialHandler {

    /** Kept for log messages; GTCE materials themselves are not namespaced. */
    public static final String NAMESPACE = com.minespace.unofficial.Minespace.MOD_ID;

    /**
     * Material ids are allocated at runtime.
     *
     * <p>GTCEu handed out material ids from 32000 upwards because its registry is a map; GTCE's
     * {@code Material.MATERIAL_REGISTRY} is a {@code GTControlledRegistry} with a fixed capacity
     * of <b>1000</b> ({@code new GTControlledRegistry<>(1000)}), so 32000 throws
     * {@code IndexOutOfBoundsException: Id is out of range}. A fixed block does not work either:
     * Gregicality already fills the top of the range - its {@code luv_superconductor_base} sits at
     * 972, which is where a hand-picked block collided.
     *
     * <p>So ids are handed out from the lowest free slot upwards: GT and Gregicality fill the low
     * ids densely and their free holes there are stable, while the top of the range is where
     * Gregicality keeps its late registrations. This mod only needs a handful of ids.
     */
    private static final int MATERIAL_ID_MAX = 999;

    private static int nextMaterialId = 0;

    public static final String DESH_STEEL = "desh_steel";
    public static final String METEORIC_IRON = "meteoric_iron";
    public static final String DESH = "desh";
    public static final String SOLAR = "solar";
    public static final String MARS_STONE = "mars_stone";
    public static final String VENUS_STONE = "venus_stone";
    public static final String ASTEROID_STONE = "asteroid_stone";
    public static final String DOLOMITE = "dolomite";
    public static final String ONYX = "onyx";

    /**
     * Ender IO's ten alloys, as GregTech materials.
     *
     * <p>The owner's call, 2026-10-12: "Ender IO's remaining materials can be expanded into GregTech
     * materials - the ingot, its molten fluid, the dust and the nugget; the other forms are not
     * wanted." Before this Ender IO's alloys existed only as Ender IO items, so GregTech could not
     * melt them, could not macerate them and had nothing to pour into a casting basin. Registering
     * them as {@link IngotMaterial}s with only {@code SMELT_INTO_FLUID} set gives exactly the set the
     * owner asked for - ingot, nugget, block, dust and the molten fluid - and nothing else, because
     * the plate / gear / rod / foil families all need a flag that is deliberately left unset.
     *
     * <p>The components list is deliberately **empty**: declaring what an alloy is made of makes
     * GregTech generate its own mixer and alloy-smelter recipes, and this pack already declares those
     * by hand in {@code scripts/integration.zs} (copied from Ender IO's own
     * {@code alloying.xml}). Two sources for the same alloy in the same recipe map is the kind of
     * duplicate this project has spent the whole migration avoiding.
     *
     * <p>The colours are taken from the mod's own textures and are approximations - they only drive
     * the tint of the GregTech ingot, dust, nugget, block and fluid.
     */
    private static final String[][] ENDER_IO_ALLOYS = {
            {"dark_steel", "0x4A4A55"},
            {"electrical_steel", "0xB4B4C8"},
            {"energetic_alloy", "0xE8A33D"},
            {"vibrant_alloy", "0x8CD25C"},
            {"redstone_alloy", "0xC13A3A"},
            {"conductive_iron", "0xB87333"},
            {"pulsating_iron", "0x6FA8A0"},
            {"soularium", "0xA8823C"},
            {"end_steel", "0x8F9BA8"},
            {"construction_alloy", "0x8A8A8A"},
    };

    /**
     * Ender IO's seven "endergy" alloys, as GregTech materials.
     *
     * <p>The owner's call, 2026-10-13: *"the non-GregTech metal ingots have to be registered on
     * GregTech's side too"*. These seven are the tail of {@link #ENDER_IO_ALLOYS}: Ender IO ships
     * their ingot, nugget, block and grinding ball, but the alloy itself has no production recipe
     * anywhere in the pack any more (the mod's Endergy module is gone and the pack never wrote one),
     * so before this the only thing a player could do with them was craft a block into nine ingots
     * and back. Registering them as GregTech {@link IngotMaterial}s - same shape as the ten above -
     * gives the family a GregTech ingot, nugget, block, dust and molten fluid, which is what
     * {@code MinespaceMaterialRepoint} then re-points every existing output at, and what
     * {@code scripts/eio_materials.zs} rebuilds the block / nugget conversions against.
     *
     * <p>The names are the ore dictionary names Ender IO already used, camel-cased by GT exactly as
     * the mod spelled them ({@code ingotCrudeSteel}, {@code ingotCrystallinePinkSlime}, ...), which is
     * what keeps Ender IO's own recipes working. Colours are approximations of the mod's textures.
     */
    private static final String[][] ENDER_IO_ENDERGY_ALLOYS = {
            {"crude_steel", "0x6B6B70"},
            {"crystalline_alloy", "0x7FD4E0"},
            {"melodic_alloy", "0xC98CE0"},
            {"stellar_alloy", "0x4A5AE0"},
            {"crystalline_pink_slime", "0xE08CC8"},
            {"energetic_silver", "0xCFCFD9"},
            {"vivid_alloy", "0x8CE06A"},
    };

    /**
     * Enderium Base - the last metal ingot Ender IO still shipped an item for.
     *
     * <p>It is not one of the mod's own alloys: it is the Thermal-Foundation intermediate Ender IO's
     * {@code alloying_modded.xml} brewed (three lead, one platinum and four ender pearls into four
     * ingots) on the way to Enderium, and GregTech has no material for it - only for Enderium itself.
     * Section 6az switched the alloy smelter entry off with the other fifteen, which left
     * {@code ingotEnderiumBase} holding Ender IO's item and nothing producing it. The owner's call,
     * 2026-10-13: *"the non-GregTech metal ingots have to be registered on GregTech's side too"*. So
     * it is registered like the rest, and its recipe is ported to GregTech's mixer in
     * {@code scripts/integration.zs} - three inputs is within the mixer's four slots, and it is the
     * same three materials and the same 1:4 ratio the mod used.
     */
    private static final String[][] ENDER_IO_OTHER_INGOTS = {
            {"enderium_base", "0x4E7A80"},
    };

    /**
     * Ender IO's ten fluids, as GregTech fluids.
     *
     * <p>The owner's call, 2026-10-13: *"those non-GregTech fluids can be registered as GregTech
     * fluids"*. Ender IO owns ten of them - the Vat's nutrient distillation, hootch, fire water, liquid
     * sunshine and their derivatives, the Ender distillation chain, rocket fuel, and its Liquid XP.
     * GregTech has no fluid for any of them, so a pack that wants "every material comes from GregTech"
     * has to hand them to GregTech without breaking the mod that makes them.
     *
     * <p>That is what {@link AdoptedFluidMaterial} does, and the two halves matter:
     *
     * <ul>
     *   <li>{@code shouldGenerateFluid()} returns {@code false}, so GregTech does <em>not</em> build a
     *       fluid of its own under these names. Ender IO registers its fluids from Forge's
     *       {@code RegistryEvent.Register<Block>}, which fires after every mod's preInit - and
     *       GregTech builds its material fluids in preInit - so a fluid GregTech made here would
     *       occupy the name first and Ender IO's {@code FluidRegistry.registerFluid} would return
     *       false, leaving the Vat and the Tank pointing at a fluid with none of the mod's own
     *       properties.</li>
     *   <li>{@link MinespaceEioFluids} then hands GregTech the fluid Ender IO actually registered
     *       ({@code setMaterialFluid}) and records it in GregTech's own fluid-to-material map, so
     *       GregTech treats it exactly like a fluid it built itself. One fluid object, GregTech's
     *       material, Ender IO's textures, buckets and fluid blocks.</li>
     * </ul>
     *
     * <p>Colours are Ender IO's own, read out of its {@code Fluids} enum, so the GregTech material and
     * the mod's fluid agree.
     */
    private static final String[][] ENDER_IO_FLUIDS = {
            {"nutrient_distillation", "0x5A5E00"},
            {"ender_distillation", "0x149535"},
            {"vapor_of_levity", "0x41716A"},
            {"hootch", "0xFFFFFF"},
            {"rocket_fuel", "0x707044"},
            {"fire_water", "0x8A490F"},
            {"xpjuice", "0x80FF20"},
            {"liquid_sunshine", "0xD2C561"},
            {"cloud_seed", "0x248589"},
            {"cloud_seed_concentrated", "0x3F5C5D"},
    };

    /** The fluids, by name, for {@link MinespaceEioFluids} to adopt once Ender IO has registered them. */
    private static final Map<String, FluidMaterial> ENDER_IO_FLUID_MATERIALS = new LinkedHashMap<>();

    /**
     * A {@link FluidMaterial} that leaves the fluid to somebody else.
     *
     * <p>{@code shouldGenerateFluid()} is the switch GregTech's {@code MetaFluids.init()} reads, and it
     * is not final, so overriding it is the supported way to say "this material has a fluid, but do not
     * create one". {@link MinespaceEioFluids} sets the real fluid later, when Ender IO has registered
     * it.
     */
    private static final class AdoptedFluidMaterial extends FluidMaterial {

        private AdoptedFluidMaterial(int id, String name, int colour, MaterialIconSet iconSet,
                                     long flags) {
            super(id, name, colour, iconSet, ImmutableList.of(), flags);
        }

        @Override
        public boolean shouldGenerateFluid() {
            return false;
        }
    }

    /**
     * An immediately usable logger.
     *
     * <p>Not {@code Minespace.log()}: because of {@code required-after:gregtech}, GT runs its
     * whole preInit - including the material handler call below - before this mod's own preInit,
     * so the logger in the main mod class is still null here.
     */
    private static final org.apache.logging.log4j.Logger LOG =
            org.apache.logging.log4j.LogManager.getLogger("minespace");

    /**
     * Our own name-to-material map.
     *
     * <p>GTCEu had {@code materialManager.getMaterial("minespace:desh_steel")}; GTCE has no
     * equivalent lookup by name, so the handler records what it creates. {@link #lookup(String)}
     * is what the rest of this mod (and the stone types) uses.
     */
    private static final Map<String, Material> REGISTERED = new LinkedHashMap<>();

    private static boolean initialized;

    public MinespaceMaterials() {
    }

    /** Called by GT once, before it builds its own material-driven blocks and items. */
    @Override
    public void onMaterialsInit() {
        if (initialized) {
            return;
        }
        initialized = true;

        // One id per material, taken from the lowest free slot in GT's 1000-slot registry.
        int deshId = allocateMaterialId();
        int meteoricIronId = allocateMaterialId();
        int deshSteelId = allocateMaterialId();
        int solarId = allocateMaterialId();
        int onyxId = allocateMaterialId();

        // dust / ingot / gem are decided by the type being constructed, and GENERATE_ORE is what
        // makes GT build the ore block (plus its stone-type variants and the ore dictionary
        // entries) that the planet veins place. No item registration happens here.
        // ------------------------------------------------------------------
        // The two metals come first: desh_steel is declared as an alloy of them, and a
        // components list needs the Material objects to exist already.
        // ------------------------------------------------------------------
        //
        // Galacticraft's own Mars / Venus ores. Galacticraft's generation for both is disabled
        // in its config and replaced by GregTech veins, so the metal has to be a real GT material
        // carrying the ore prefix.
        //
        // The names must stay Galacticraft's: GT derives oreDesh / dustDesh / ingotDesh /
        // blockDesh from "desh", and Galacticraft's rocket and block recipes look the metal up by
        // exactly those ore dictionary names, so a differently named material would silently
        // leave the tier 2 rocket uncraftable.
        register(new IngotMaterial(
                deshId, DESH, 0xE0A64B, MaterialIconSet.METALLIC, 2, ImmutableList.of(),
                DustMaterial.MatFlags.GENERATE_ORE | DustMaterial.MatFlags.GENERATE_PLATE));

        // GENERATE_ORE as well: the Martian desh vein lists meteoric iron as one of its four
        // layers, and GT can only place an ore block for a material that carries the ore flag.
        register(new IngotMaterial(
                meteoricIronId, METEORIC_IRON, 0x8A7F73, MaterialIconSet.ROUGH, 2,
                ImmutableList.of(),
                DustMaterial.MatFlags.GENERATE_ORE | DustMaterial.MatFlags.GENERATE_PLATE));

        // ------------------------------------------------------------------
        // desh_steel - the alloy that gives desh a place in the GregTech chain.
        //
        // Declaring the components is what makes GT generate the mixer and alloy smelter
        // recipes for it, and SMELT_INTO_FLUID is what gives the material a molten fluid, which
        // is what the old GTCEu build got from `.fluid()`.
        // ------------------------------------------------------------------
        Material desh = lookup(DESH);
        Material steel = Materials.Steel;
        ImmutableList<MaterialStack> deshSteelComponents = desh == null || steel == null
                ? ImmutableList.of()
                : ImmutableList.of(new MaterialStack(desh, 1), new MaterialStack(steel, 1));
        if (deshSteelComponents.isEmpty()) {
            LOG.warn("desh_steel has no components (desh={}, steel={}) - the alloy recipe will be missing",
                    desh, steel);
        }
        register(new IngotMaterial(
                deshSteelId, DESH_STEEL, 0x4C5A63, MaterialIconSet.METALLIC, 2,
                deshSteelComponents,
                DustMaterial.MatFlags.GENERATE_PLATE | DustMaterial.MatFlags.SMELT_INTO_FLUID));

        // The stone types (Moon, Mars, Venus, Asteroids and the 17 Galaxy Space bodies) do NOT get
        // materials of their own any more. GTCE's StoneType only needs a `stoneMaterial` to name and
        // build its ore *block* variant, and GT already has a perfectly good one for that job -
        // `Materials.Stone`, which carries GENERATE_ORE. Creating 21 extra materials instead put 21
        // more entries into GT's shared 1000-slot material registry, which is exactly the kind of
        // footprint that makes an addon collide with Gregicality's later registrations. The stone
        // type's *own* name and its rock texture stay ours, so ores on those bodies still look and
        // read as that body's rock (see MinespaceStoneTypes / MinespaceGalaxySpaceStones).

        register(new DustMaterial(
                solarId, SOLAR, 0xFFE873, MaterialIconSet.DULL, 1, ImmutableList.of(),
                DustMaterial.MatFlags.GENERATE_ORE));

        // The two ores only Galaxy Space generated, so that turning its ore generation off does
        // not delete them from the pack. A probe of the ore dictionary showed why they need to be
        // real GT materials:
        //
        //   oreDolomite existed (Galaxy Space's ore block registered it) but there was no dolomite
        //   item at all, so a GT vein has to be what puts oreDolomite back;
        //   Galaxy Space's onyx was not in the ore dictionary under any name, so a GT material is
        //   the only way to make it obtainable.
        //
        // Both carry GENERATE_ORE and can therefore be placed by a vein (see the dolomite and onyx
        // vein files under config/gregtech/worldgen/vein).
        //
        // dolomite is *not* created here: GTCE-TJ ships its own dolomite material (the literal
        // "dolomite" is in gtce's Materials class). Creating a second material with the same name
        // puts two entries into a registry keyed by name, and the fallout is not local - GT's own
        // later material creation trips over it and the load dies in
        // Material.toCamelCaseString with a NullPointerException during the ore dictionary pass.
        // So reuse GT's material, exactly like `steel` is reused above.
        Material dolomite = Material.MATERIAL_REGISTRY.getObject(DOLOMITE);
        if (dolomite == null) {
            LOG.warn("GT is expected to provide a '{}' material, but none is registered", DOLOMITE);
        } else {
            REGISTERED.put(DOLOMITE, dolomite);
            LOG.info("  reusing GT's own material '{}' ({})", dolomite,
                    dolomite.getClass().getSimpleName());
        }

        register(new GemMaterial(onyxId, ONYX, 0x2E2A33, MaterialIconSet.SHINY, 1,
                ImmutableList.of(), DustMaterial.MatFlags.GENERATE_ORE));

        // ------------------------------------------------------------------
        // Ender IO's ten alloys (see ENDER_IO_ALLOYS above).
        //
        // A name GT already owns is reused rather than re-created - a second material under the same
        // name corrupts GT's name-keyed registry and kills the load in Material.toCamelCaseString.
        // ------------------------------------------------------------------
        int reusedAlloys = 0;
        for (String[] alloy : ENDER_IO_ALLOYS) {
            String name = alloy[0];
            Material existing = Material.MATERIAL_REGISTRY.getObject(name);
            if (existing != null) {
                REGISTERED.put(name, existing);
                reusedAlloys++;
                LOG.info("  reusing GT's own material '{}' ({}) for Ender IO", name,
                        existing.getClass().getSimpleName());
                continue;
            }
            int id = allocateMaterialId();
            int colour = (int) Long.parseLong(alloy[1].substring(2), 16);
            register(new IngotMaterial(id, name, colour, MaterialIconSet.METALLIC, 2,
                    ImmutableList.of(), DustMaterial.MatFlags.SMELT_INTO_FLUID));
            LOG.info("  registered Ender IO alloy '{}' as a GregTech material (id {})", name, id);
        }
        LOG.info("Ender IO alloys as GregTech materials: {} registered/reused, {} already GT's",
                ENDER_IO_ALLOYS.length - reusedAlloys, reusedAlloys);

        // ------------------------------------------------------------------
        // Ender IO's seven endergy alloys (see ENDER_IO_ENDERGY_ALLOYS above). Same shape and the
        // same reasoning as the ten: SMELT_INTO_FLUID and an empty component list, so GT hands out
        // ingot / nugget / block / dust / molten fluid and nothing else, and no second source for
        // the recipes the pack writes by hand.
        // ------------------------------------------------------------------
        int reusedEndergy = 0;
        for (String[] alloy : ENDER_IO_ENDERGY_ALLOYS) {
            String name = alloy[0];
            Material existing = Material.MATERIAL_REGISTRY.getObject(name);
            if (existing != null) {
                REGISTERED.put(name, existing);
                reusedEndergy++;
                LOG.info("  reusing GT's own material '{}' ({}) for Ender IO's endergy alloys", name,
                        existing.getClass().getSimpleName());
                continue;
            }
            int id = allocateMaterialId();
            int colour = (int) Long.parseLong(alloy[1].substring(2), 16);
            register(new IngotMaterial(id, name, colour, MaterialIconSet.METALLIC, 2,
                    ImmutableList.of(), DustMaterial.MatFlags.SMELT_INTO_FLUID));
            LOG.info("  registered Ender IO endergy alloy '{}' as a GregTech material (id {})",
                    name, id);
        }
        LOG.info("Ender IO endergy alloys as GregTech materials: {} registered/reused, {} already GT's",
                ENDER_IO_ENDERGY_ALLOYS.length - reusedEndergy, reusedEndergy);

        // Enderium Base, the one metal ingot outside the two alloy families (see
        // ENDER_IO_OTHER_INGOTS above).
        for (String[] ingot : ENDER_IO_OTHER_INGOTS) {
            String name = ingot[0];
            Material existing = Material.MATERIAL_REGISTRY.getObject(name);
            if (existing != null) {
                REGISTERED.put(name, existing);
                LOG.info("  reusing GT's own material '{}' for Ender IO's {}", name, name);
                continue;
            }
            int id = allocateMaterialId();
            int colour = (int) Long.parseLong(ingot[1].substring(2), 16);
            register(new IngotMaterial(id, name, colour, MaterialIconSet.METALLIC, 2,
                    ImmutableList.of(), DustMaterial.MatFlags.SMELT_INTO_FLUID));
            LOG.info("  registered Ender IO metal '{}' as a GregTech material (id {})", name, id);
        }

        // ------------------------------------------------------------------
        // Ender IO's ten fluids (see ENDER_IO_FLUIDS above). An AdoptedFluidMaterial claims the
        // material and the name, but deliberately does not ask GT to create a fluid: Ender IO's own
        // fluid is registered later and handed to GT by MinespaceEioFluids. Vapor of Levity is the
        // one gas; the other nine are liquids.
        // ------------------------------------------------------------------
        int reusableFluids = 0;
        for (String[] fluid : ENDER_IO_FLUIDS) {
            String name = fluid[0];
            boolean gas = "vapor_of_levity".equals(name);
            long flags = gas ? FluidMaterial.MatFlags.STATE_GAS : 0L;
            Material existing = Material.MATERIAL_REGISTRY.getObject(name);
            if (existing instanceof FluidMaterial) {
                ENDER_IO_FLUID_MATERIALS.put(name, (FluidMaterial) existing);
                REGISTERED.put(name, existing);
                reusableFluids++;
                LOG.info("  reusing GT's own material '{}' for Ender IO's fluid", name);
                continue;
            }
            int id = allocateMaterialId();
            int colour = (int) Long.parseLong(fluid[1].substring(2), 16);
            FluidMaterial material = new AdoptedFluidMaterial(id, name, colour,
                    gas ? MaterialIconSet.GAS : MaterialIconSet.FLUID, flags);
            register(material);
            ENDER_IO_FLUID_MATERIALS.put(name, material);
            LOG.info("  registered Ender IO fluid '{}' as a GregTech fluid material (id {})", name, id);
        }
        LOG.info("Ender IO fluids as GregTech materials: {} registered, {} already GT's",
                ENDER_IO_FLUIDS.length - reusableFluids, reusableFluids);

        LOG.info("Registered {} GregTech materials: {}, {}, {}, {}, {} (plus GT's own {} and {})",
                REGISTERED.size(), DESH_STEEL, METEORIC_IRON, DESH, SOLAR, ONYX,
                DOLOMITE, "steel");

        // ------------------------------------------------------------------
        // Stone types, and why they are registered from a material handler.
        //
        // GTCE-TJ bakes its ore blocks inside its own preInit, right after this handler returns:
        //
        //   Material.runMaterialHandlers()   <-- onMaterialsInit(), i.e. we are here
        //   Material.freezeRegistry()
        //   MetaBlocks.init()                <-- StoneType.init() + one BlockOre group per material
        //
        // `createOreBlock` reads StoneType.STONE_TYPE_REGISTRY at that moment and bakes the ids it
        // finds into the block's `stone_type` property, 16 ids per block. A stone type registered
        // later is in the registry but in no ore block, and the vein filler -
        // FillerConfigUtils$OreFilterEntry.apply, which is a bare blockStateMap.get(...) with no
        // null check - then feeds a null state to World.setBlockState. The result is a
        // NullPointerException for every vein that meets that rock, not merely a wrong texture.
        //
        // So the stone types have to be created here, and everything block-shaped in them (the base
        // state GT draws and the ore-gen predicate) is resolved lazily: at this point no mod has
        // registered a block yet. See MinespaceStoneTypes for the full explanation.
        // ------------------------------------------------------------------
        MinespaceStoneTypes.register();
        MinespacePlanetStoneTypes.register();
        MinespaceGalaxySpaceStones.register();
        // ... and the first body with real terrain, whose stone type has to exist for the same reason.
        MinespacePlanetTerrainPrototype.register();
    }

    private static void register(Material material) {
        REGISTERED.put(material.toString(), material);
    }

    /**
     * The next free slot in GT's 1000-entry material registry.
     *
     * <p>Searched from the bottom up on purpose. GT and Gregicality fill the low ids densely, and
     * the free holes there are stable - while the *high* end of the range is where Gregicality
     * keeps its own late registrations (its {@code luv_superconductor_base} sits at 972), which a
     * top-down scan collides with. This mod only ever needs a handful of ids now, so it takes the
     * smallest holes it can find.
     */
    private static int allocateMaterialId() {
        while (nextMaterialId <= MATERIAL_ID_MAX) {
            int candidate = nextMaterialId++;
            if (Material.MATERIAL_REGISTRY.getObjectById(candidate) == null) {
                return candidate;
            }
        }
        throw new IllegalStateException(
                "The GT material registry has no free id left below " + MATERIAL_ID_MAX);
    }

    /**
     * The GT item for one of this mod's materials, e.g.
     * {@code stack(OrePrefix.ingot, DESH_STEEL)}.
     *
     * <p>Only valid after GT has built its material items (postInit onwards); before that the
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
     * Ender IO's ten fluids as GregTech {@link FluidMaterial}s, by fluid name, for
     * {@link MinespaceEioFluids} to hand the mod's own fluid to once it exists.
     */
    public static Map<String, FluidMaterial> enderIoFluids() {
        return ENDER_IO_FLUID_MATERIALS;
    }

    /**
     * The registered material, or null when it was never registered.
     *
     * <p>Callers may pass either the bare name ({@code desh_steel}) or the old namespaced form
     * ({@code minespace:desh_steel}); the namespace is stripped, because GTCE material names are
     * global and have no namespace.
     */
    public static Material lookup(String materialName) {
        if (materialName == null) {
            return null;
        }
        int colon = materialName.indexOf(':');
        String key = colon >= 0 ? materialName.substring(colon + 1) : materialName;
        return REGISTERED.get(key);
    }
}
