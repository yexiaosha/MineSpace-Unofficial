package com.minespace.unofficial.gtceu;

import com.google.common.collect.ImmutableList;
import gregtech.api.unification.material.IMaterialHandler;
import gregtech.api.unification.material.MaterialIconSet;
import gregtech.api.unification.material.Materials;
import gregtech.api.unification.material.type.DustMaterial;
import gregtech.api.unification.material.type.GemMaterial;
import gregtech.api.unification.material.type.IngotMaterial;
import gregtech.api.unification.material.type.Material;
import gregtech.api.unification.stack.MaterialStack;
import net.minecraftforge.fml.common.Loader;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * GT materials for BYG's four named ores, plus the real sodalite already owned by GregTech.
 *
 * <p>The compositions are deliberately mineralogical rather than "magic gem" numbers:</p>
 * <ul>
 *   <li>Kasai - a native Ni-Cr-Co-Mo-W refractory superalloy (Nether, fire theme);</li>
 *   <li>Latharium - a mixed rare-earth fluorocarbonate, (Ce,La,Nd)CO3F, a bastnäsite analogue;</li>
 *   <li>Pendorite - beryl, Be3Al2Si6O18;</li>
 *   <li>Tamrelite - vanadium titanate, TiV2O6;</li>
 *   <li>Sodalite - Na8Al6Si6O24Cl2, GT's existing Sodalite material is reused.</li>
 * </ul>
 *
 * <p>Kasai is the EV superalloy of the set; Latharium is the rare-earth/optical source;
 * Pendorite feeds beryllium/aluminium chemistry; Tamrelite feeds titanium/vanadium chemistry;
 * sodalite feeds aluminium/sodium/chlorine. The processing recipes and tech uses live in
 * {@link MinespaceBygProcessing}.</p>
 */
@IMaterialHandler.RegisterMaterialHandler
public final class MinespaceBygMaterials implements IMaterialHandler {

    private static final Logger LOG = LogManager.getLogger("minespace_core");
    private static final Map<String, Material> MATERIALS = new LinkedHashMap<>();
    private static boolean initialized;

    public static final String KASAI = "kasai";
    public static final String LATHARIUM = "latharium";
    public static final String PENDORITE = "pendorite";
    public static final String TAMRELITE = "tamrelite";

    public MinespaceBygMaterials() {
    }

    @Override
    public void onMaterialsInit() {
        if (initialized) {
            return;
        }
        initialized = true;
        MATERIALS.put("Sodalite", Materials.Sodalite);
        if (!Loader.isModLoaded("byg")) {
            return;
        }

        register("kasai", new IngotMaterial(
                MinespaceMaterials.allocateMaterialId(), KASAI, 0xD07030,
                MaterialIconSet.METALLIC, 4,
                ImmutableList.of(
                        new MaterialStack(Materials.Nickel, 10),
                        new MaterialStack(Materials.Chrome, 4),
                        new MaterialStack(Materials.Cobalt, 3),
                        new MaterialStack(Materials.Molybdenum, 2),
                        new MaterialStack(Materials.Tungsten, 1)),
                DustMaterial.MatFlags.SMELT_INTO_FLUID
                        | DustMaterial.MatFlags.GENERATE_PLATE,
                10.0f, 2.0f, 1800));

        register("latharium", new GemMaterial(
                MinespaceMaterials.allocateMaterialId(), LATHARIUM, 0x9B6BD6,
                MaterialIconSet.OPAL, 4,
                ImmutableList.of(
                        new MaterialStack(Materials.Cerium, 1),
                        new MaterialStack(Materials.Lanthanum, 1),
                        new MaterialStack(Materials.Neodymium, 1),
                        new MaterialStack(Materials.Carbon, 3),
                        new MaterialStack(Materials.Oxygen, 9),
                        new MaterialStack(Materials.Fluorine, 3)),
                DustMaterial.MatFlags.GENERATE_PLATE,
                9.0f, 2.0f, 950));

        register("pendorite", new GemMaterial(
                MinespaceMaterials.allocateMaterialId(), PENDORITE, 0x2FAF9F,
                MaterialIconSet.EMERALD, 4,
                ImmutableList.of(
                        new MaterialStack(Materials.Beryllium, 3),
                        new MaterialStack(Materials.Aluminium, 2),
                        new MaterialStack(Materials.Silicon, 6),
                        new MaterialStack(Materials.Oxygen, 18)),
                DustMaterial.MatFlags.GENERATE_PLATE,
                12.0f, 3.0f, 1200));

        register("tamrelite", new GemMaterial(
                MinespaceMaterials.allocateMaterialId(), TAMRELITE, 0xB07A3C,
                MaterialIconSet.GEM_VERTICAL, 3,
                ImmutableList.of(
                        new MaterialStack(Materials.Titanium, 1),
                        new MaterialStack(Materials.Vanadium, 2),
                        new MaterialStack(Materials.Oxygen, 6)),
                DustMaterial.MatFlags.GENERATE_PLATE,
                5.0f, 3.0f, 750));

        LOG.info("BYG materials: Kasai, Latharium, Pendorite, Tamrelite; Sodalite reused");
    }

    private static void register(String name, Material material) {
        Material existing = Material.MATERIAL_REGISTRY.getObject(name);
        if (existing != null) {
            MATERIALS.put(name, existing);
            return;
        }
        MATERIALS.put(name, material);
    }

    public static Material material(String name) {
        return MATERIALS.get(name);
    }
}
