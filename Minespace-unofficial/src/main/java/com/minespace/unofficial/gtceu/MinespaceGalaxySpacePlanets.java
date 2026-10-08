package com.minespace.unofficial.gtceu;

import java.util.Arrays;
import java.util.List;

/**
 * The table behind Galaxy Space's stone types: one entry per celestial body whose rock GregTech
 * has to know about.
 *
 * <h2>Why a table</h2>
 *
 * Galaxy Space ships fifteen Solar System bodies plus three planets in other systems, and every
 * one of them needs the same three things: a rock block of our own to draw the ore on
 * ({@link MinespaceGalaxySpaceRocks}), a GregTech stone type pointing at it
 * ({@link MinespaceGalaxySpaceStones}) and a material for that stone type
 * (registered from {@link MinespaceMaterials}). Writing that out per planet would be fifteen
 * near-identical classes, so the bodies live here as data.
 *
 * <p>Deliberately free of Galaxy Space types: this class only holds strings and numbers, so the
 * material registration can use it without pulling Galaxy Space onto the class path.
 *
 * <h2>Names</h2>
 *
 * {@code key} is our own short name (it becomes {@code minespace:<key>_rock} and the
 * {@code <key>_stone} material and stone type). {@code gsBlock} is Galaxy Space's registry path
 * for that body's block, read out of its jar - note that the Solar System bodies use the
 * compact spelling ({@code callistoblocks}, {@code mercuryblocks}) while the other systems use
 * underscores ({@code proxima_b_blocks}, {@code barnarda_c_blocks}).
 */
public final class MinespaceGalaxySpacePlanets {

    public static final String GALAXY_SPACE_MOD_ID = "galaxyspace";

    /** Stone type ids start after the four Galacticraft ones (16..19); the registry holds 128. */
    private static final int FIRST_STONE_TYPE_ID = 20;

    /** Material ids continue this mod's 32000 range; 32000..32007 are taken. */
    private static final int FIRST_MATERIAL_ID = 32100;

    public static final class Planet {

        /** Our short name, e.g. {@code callisto}. */
        public final String key;
        /** Galaxy Space's block registry path, e.g. {@code callistoblocks}. */
        public final String gsBlock;
        /** Stone type id handed to GregTech. */
        public final int stoneTypeId;
        /** Material id handed to GregTech. */
        public final int materialId;
        /** Colour of the stone type's dust, chosen per body. */
        public final int color;

        /**
         * The material and stone type name, e.g. {@code callisto_stone}.
         *
         * <p>Note the underscore this adds: GregTech refuses material names that look like
         * "materialnumber" ("Cannot add materials with names like 'materialnumber'! Use
         * 'material_number' instead"), which {@code barnarda_c1_stone} would be - so a digit
         * directly after a letter gets an underscore in front of it. The <em>block</em> name is
         * untouched by that rule and stays {@code barnarda_c1_rock}.
         */
        private final String stoneName;

        Planet(String key, String gsBlock, int index, int color) {
            this.key = key;
            this.gsBlock = gsBlock;
            this.stoneTypeId = FIRST_STONE_TYPE_ID + index;
            this.materialId = FIRST_MATERIAL_ID + index;
            this.color = color;
            this.stoneName = key.replaceAll("([a-z])([0-9])", "$1_$2") + "_stone";
        }

        /** The material and stone type name GT registers for this body. */
        public String stoneName() {
            return stoneName;
        }

        /** The rock block this mod registers for this body. */
        public String rockName() {
            return key + "_rock";
        }
    }

    public static final List<Planet> PLANETS = Arrays.asList(
            // Solar System
            new Planet("mercury", "mercuryblocks", 0, 0x8A8A8A),
            new Planet("ceres", "ceresblocks", 1, 0x7A7068),
            new Planet("pluto", "plutoblocks", 2, 0x9A8C7A),
            new Planet("haumea", "haumeablocks", 3, 0xA8A29A),
            new Planet("phobos", "phobosblocks", 4, 0x6E6258),
            new Planet("io", "ioblocks", 5, 0xC2A34A),
            new Planet("europa", "europablocks", 6, 0xC8D4DC),
            new Planet("ganymede", "ganymedeblocks", 7, 0x9FA6A0),
            new Planet("callisto", "callistoblocks", 8, 0x7E7268),
            new Planet("enceladus", "enceladusblocks", 9, 0xDCE6EC),
            new Planet("titan", "titanblocks", 10, 0xB98B3E),
            new Planet("miranda", "mirandablocks", 11, 0xA8AEB4),
            new Planet("triton", "tritonblocks", 12, 0xB9C6CE),
            // Other systems
            new Planet("proxima_b", "proxima_b_blocks", 13, 0x8C4A3A),
            new Planet("barnarda_c", "barnarda_c_blocks", 14, 0x9C6B4A),
            new Planet("barnarda_c1", "barnarda_c1_blocks", 15, 0xD8DEE4),
            new Planet("tauceti_f", "tauceti_f_blocks", 16, 0x6E8C4A));

    private MinespaceGalaxySpacePlanets() {
    }
}
