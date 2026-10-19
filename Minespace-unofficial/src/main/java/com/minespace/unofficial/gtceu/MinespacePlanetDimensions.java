package com.minespace.unofficial.gtceu;

import java.util.Arrays;
import java.util.List;

/**
 * The planned dimensions, generated from tools\planet-catalog.csv by
 * tools\gen-planet-dimension-table.ps1 - do not edit by hand, and re-run that script after the
 * catalog changes.
 *
 * <p>Registering these is deliberately cheap and deliberately incomplete: no terrain, no rock
 * blocks, one shared provider (see MinespacePlanetWorldProvider). Registering a dimension does
 * not create a world - 6dl measured that - so eighty-one of these cost nothing until something
 * travels to one. What it buys is that every id in planet-veins.psd1 points at a dimension that
 * exists, and that the star map work has ids to talk about.</p>
 */
public final class MinespacePlanetDimensions {

    /** One planned body. */
    public static final class Planet {

        public final int dimensionId;
        public final String name;
        public final String nameZh;
        public final int layer;
        public final int stage;
        /** False for a star, black hole, galaxy: it gets an id, and nothing can land on it. */
        public final boolean landable;
        /** How many veins its card carries once planet-veins.psd1 has written them. */
        public final int veins;
        /** Registry-safe key, used for the dimension type name. */
        public final String key;
        /**
         * The star this body orbits, from the catalog. Empty for a body that is not a planet -
         * a star, a black hole, a galaxy - which then stands as its own system on the star map.
         */
        public final String star;
        /**
         * Its orbital distance from that star, in AU, from the catalog. 0 when the catalog has no
         * figure - the star map then spaces the bodies of that system by rank instead. The solar
         * system is the one that matters here: a moon carries its parent's distance plus a small
         * offset, so the ring order is the real one (Mercury inside, the Kuiper belt outside).
         */
        public final float orbitAu;
        /**
         * The planet this body orbits, or empty for a planet, a belt or an object that orbits the star
         * directly. A moon is drawn around its planet on the star map, and its card says so.
         */
        public final String parent;
        /**
         * How far this body - or its star, for a planet - is from Earth, in light years. 0 when the
         * catalog has no figure. The solar system's own bodies carry their radius from the Sun here, which
         * is why the card prefers the orbital distance when the body is one of them.
         */
        public final float distanceLy;
        /** The kind of body, from the catalog: Planet, Moon, Star, BlackHole, Galaxy, Nebula, Pulsar... */
        public final String type;
        /**
         * Its orbital period in days, from the catalog - the real one, so that however fast the clock is
         * turned the bodies keep their true ratios to each other. 0 means no figure: drawn standing still.
         */
        public final float periodDays;

        Planet(int dimensionId, String name, String nameZh, int layer, int stage, boolean landable,
                int veins, String key, String star, float orbitAu, String parent, float distanceLy,
                String type, float periodDays) {
            this.dimensionId = dimensionId;
            this.name = name;
            this.nameZh = nameZh;
            this.layer = layer;
            this.stage = stage;
            this.landable = landable;
            this.veins = veins;
            this.key = key;
            this.star = star;
            this.orbitAu = orbitAu;
            this.parent = parent;
            this.distanceLy = distanceLy;
            this.type = type;
            this.periodDays = periodDays;
        }
    }

    public static final List<Planet> PLANETS = Arrays.asList(
            new Planet(-2418, "ULAS J1342+0928", "\u7c7b\u661f\u4f53 J1342+0928", 7, 8, false, 0, "ulas_j1342_0928", "", 0F, "", 13100000000F, "Quasar", 0F),
            new Planet(-2417, "J0313-1806", "\u7c7b\u661f\u4f53 J0313-1806", 7, 8, false, 0, "j0313_1806", "", 0F, "", 13000000000F, "Quasar", 0F),
            new Planet(-2416, "GRB 090423", "GRB 090423", 7, 8, false, 0, "grb_090423", "", 0F, "", 13000000000F, "Transient", 0F),
            new Planet(-2415, "MoM-z14", "MoM-z14", 7, 8, false, 0, "mom_z14", "", 0F, "", 13500000000F, "Galaxy", 0F),
            new Planet(-2413, "UHZ1", "UHZ1", 7, 8, false, 0, "uhz1", "", 0F, "", 13200000000F, "Galaxy", 0F),
            new Planet(-2412, "GW150914", "GW150914", 7, 8, false, 0, "gw150914", "", 0F, "", 1300000000F, "GravitationalWave", 0F),
            new Planet(-2410, "2I/Borisov", "2I/\u9c8d\u91cc\u7d22\u592b", 7, 8, false, 0, "2i_borisov", "", 0F, "", 0F, "InterstellarObject", 0F),
            new Planet(-2409, "'Oumuamua (1I/2017 U1)", "\u5965\u964c\u964c", 7, 8, false, 0, "oumuamua_1i_2017_u1", "", 0F, "", 0F, "InterstellarObject", 0F),
            new Planet(-2406, "Hercules-Corona Borealis Great Wall", "\u6b66\u4ed9-\u5317\u5195\u5ea7\u957f\u57ce", 7, 8, false, 0, "hercules_corona_borealis_great_wall", "", 0F, "", 0F, "CosmicWeb", 0F),
            new Planet(-2405, "Cosmic Microwave Background", "\u5b87\u5b99\u5fae\u6ce2\u80cc\u666f", 7, 8, false, 0, "cosmic_microwave_background", "", 0F, "", 46500000000F, "CMB", 0F),
            new Planet(-2404, "Ton 618", "Ton 618", 7, 8, false, 0, "ton_618", "", 0F, "", 10400000000F, "Quasar", 0F),
            new Planet(-2403, "3C 273", "\u7c7b\u661f\u4f53 3C 273", 7, 8, false, 0, "3c_273", "", 0F, "", 2400000000F, "Quasar", 0F),
            new Planet(-2402, "Earendel (WHL0137-LS)", "\u57c3\u96c5\u4ec1\u8fea\u5c14\uff08\u6668\u661f\uff09", 7, 8, false, 0, "earendel_whl0137_ls", "", 0F, "", 12900000000F, "Star", 0F),
            new Planet(-2401, "JADES-GS-z14-0", "JADES-GS-z14-0", 7, 8, false, 0, "jades_gs_z14_0", "", 0F, "", 13500000000F, "Galaxy", 0F),
            new Planet(-2400, "GN-z11", "GN-z11", 7, 8, false, 0, "gn_z11", "", 0F, "", 13400000000F, "Galaxy", 0F),
            new Planet(-2362, "Virgo Cluster", "\u5ba4\u5973\u5ea7\u661f\u7cfb\u56e2", 6, 8, false, 0, "virgo_cluster", "", 0F, "", 65000000F, "Cluster", 0F),
            new Planet(-2361, "M87* (Powehi)", "M87*", 6, 8, false, 0, "m87_powehi", "", 0F, "", 55000000F, "BlackHole", 0F),
            new Planet(-2360, "Messier 87", "\u5ba4\u5973\u5ea7 A\uff08M87\uff09", 6, 8, false, 0, "messier_87", "", 0F, "", 55000000F, "Galaxy", 0F),
            new Planet(-2359, "Antennae Galaxies (NGC 4038/4039)", "\u89e6\u987b\u661f\u7cfb", 6, 8, false, 0, "antennae_galaxies_ngc_4038_4039", "", 0F, "", 45000000F, "Galaxy", 0F),
            new Planet(-2358, "Sombrero Galaxy (M104)", "\u8349\u5e3d\u661f\u7cfb", 6, 8, false, 0, "sombrero_galaxy_m104", "", 0F, "", 31000000F, "Galaxy", 0F),
            new Planet(-2357, "Whirlpool Galaxy (M51)", "\u6da1\u72b6\u661f\u7cfb", 6, 8, false, 0, "whirlpool_galaxy_m51", "", 0F, "", 31000000F, "Galaxy", 0F),
            new Planet(-2356, "Centaurus A (NGC 5128)", "\u534a\u4eba\u9a6c\u5ea7 A", 6, 8, false, 0, "centaurus_a_ngc_5128", "", 0F, "", 12000000F, "Galaxy", 0F),
            new Planet(-2355, "Triangulum Galaxy (M33)", "\u4e09\u89d2\u5ea7\u661f\u7cfb", 6, 8, false, 0, "triangulum_galaxy_m33", "", 0F, "", 2700000F, "Galaxy", 0F),
            new Planet(-2354, "Andromeda Galaxy (M31)", "\u4ed9\u5973\u5ea7\u661f\u7cfb", 6, 8, false, 0, "andromeda_galaxy_m31", "", 0F, "", 2500000F, "Galaxy", 0F),
            new Planet(-2353, "Small Magellanic Cloud", "\u5c0f\u9ea6\u54f2\u4f26\u4e91", 6, 8, false, 0, "small_magellanic_cloud", "", 0F, "", 200000F, "Galaxy", 0F),
            new Planet(-2352, "SN 1987A", "SN 1987A", 6, 8, false, 0, "sn_1987a", "", 0F, "", 168000F, "SupernovaRemnant", 0F),
            new Planet(-2351, "Tarantula Nebula", "\u8718\u86db\u661f\u4e91", 6, 8, false, 0, "tarantula_nebula", "", 0F, "", 160000F, "Nebula", 0F),
            new Planet(-2350, "Large Magellanic Cloud", "\u5927\u9ea6\u54f2\u4f26\u4e91", 6, 8, false, 0, "large_magellanic_cloud", "", 0F, "", 163000F, "Galaxy", 0F),
            new Planet(-2318, "PSR J1748-2446ad", "PSR J1748-2446ad", 5, 7, false, 0, "psr_j1748_2446ad", "", 0F, "", 18000F, "Pulsar", 0F),
            new Planet(-2317, "GRS 1915+105", "GRS 1915+105", 5, 7, false, 0, "grs_1915_105", "", 0F, "", 40000F, "BlackHole", 0F),
            new Planet(-2316, "Great Annihilator (1E 1740.7-2942)", "\u5927\u6e6e\u706d\u8005", 5, 7, false, 0, "great_annihilator_1e_1740_7_2942", "", 0F, "", 23000F, "BlackHole", 0F),
            new Planet(-2315, "Sagittarius B2", "\u4eba\u9a6c\u5ea7 B2", 5, 7, false, 0, "sagittarius_b2", "", 0F, "", 27000F, "Nebula", 0F),
            new Planet(-2314, "Arches Cluster", "\u5f13\u7bad\u624b\u661f\u56e2", 5, 7, false, 0, "arches_cluster", "", 0F, "", 25000F, "Cluster", 0F),
            new Planet(-2312, "Westerlund 1", "Westerlund 1", 5, 7, false, 0, "westerlund_1", "", 0F, "", 15000F, "Cluster", 0F),
            new Planet(-2311, "Kepler-70 c", "\u5f00\u666e\u52d2 70 c", 5, 7, true, 0, "kepler_70_c", "KOI-55 B", 0F, "", 4015F, "Planet", 0.3429F),
            new Planet(-2310, "Kepler-70 b", "\u5f00\u666e\u52d2 70 b", 5, 7, true, 0, "kepler_70_b", "KOI-55 B", 0F, "", 4015F, "Planet", 0.2401F),
            new Planet(-2308, "Eta Carinae", "\u8239\u5e95\u5ea7 \u03b7", 5, 7, false, 0, "eta_carinae", "", 0F, "", 7500F, "Star", 0F),
            new Planet(-2307, "Cygnus X-1", "\u5929\u9e45\u5ea7 X-1", 5, 7, false, 0, "cygnus_x_1", "", 0F, "", 7200F, "BlackHole", 0F),
            new Planet(-2306, "Crab Pulsar (PSR B0531+21)", "\u87f9\u72b6\u661f\u4e91\u8109\u51b2\u661f", 5, 7, false, 0, "crab_pulsar_psr_b0531_21", "", 0F, "", 6500F, "Pulsar", 0F),
            new Planet(-2305, "S2", "S2 \u661f", 5, 7, false, 0, "s2", "", 0F, "", 26000F, "Star", 5862.2625F),
            new Planet(-2304, "Sagittarius A*", "\u4eba\u9a6c\u5ea7 A*", 5, 7, false, 0, "sagittarius_a", "", 0F, "", 26000F, "BlackHole", 0F),
            new Planet(-2303, "Methuselah (PSR B1620-26 b)", "PSR B1620-26 b\uff08\u739b\u571f\u6492\u62c9\uff09", 5, 7, true, 0, "methuselah_psr_b1620_26_b", "PSR B1620-26", 0F, "", 0F, "Planet", 0F),
            new Planet(-2228, "Vela Pulsar (PSR B0833-45)", "\u8239\u5e06\u5ea7\u8109\u51b2\u661f", 4, 6, false, 0, "vela_pulsar_psr_b0833_45", "", 0F, "", 960F, "Pulsar", 0F),
            new Planet(-2225, "Draugr (PSR B1257+12 b)", "PSR B1257+12 b\uff08\u5c38\u9b3c\uff09", 4, 6, true, 0, "draugr_psr_b1257_12_b", "PSR B1257+12", 0F, "", 1957F, "Planet", 25.262F),
            new Planet(-2224, "Betelgeuse", "\u53c2\u5bbf\u56db", 4, 6, false, 0, "betelgeuse", "", 0F, "", 548F, "Star", 0F),
            new Planet(-2223, "K2-18 b", "K2-18 b", 4, 6, true, 0, "k2_18_b", "K2-18 M2.5 V", 0F, "", 124F, "Planet", 32.9396F),
            new Planet(-2222, "Boyajian's Star (KIC 8462852)", "\u535a\u4e9a\u5409\u5b89\u661f", 4, 6, false, 0, "boyajian_s_star_kic_8462852", "", 0F, "", 1470F, "Star", 0F),
            new Planet(-2219, "Kepler-37 b", "\u5f00\u666e\u52d2 37 b", 4, 6, true, 0, "kepler_37_b", "Kepler-37", 0F, "", 208.5F, "Planet", 13.367F),
            new Planet(-2217, "Kepler-138 c", "\u5f00\u666e\u52d2 138 c", 4, 6, true, 0, "kepler_138_c", "Kepler-138 M1 V", 0F, "", 218.1F, "Planet", 13.7815F),
            new Planet(-2215, "Kepler-16 b", "\u5f00\u666e\u52d2 16 b", 4, 6, true, 0, "kepler_16_b", "Kepler-16", 0F, "", 244.9F, "Planet", 228.776F),
            new Planet(-2214, "Kepler-1649 c", "\u5f00\u666e\u52d2 1649 c", 4, 6, true, 0, "kepler_1649_c", "Kepler-1649", 0F, "", 300.7F, "Planet", 19.5353F),
            new Planet(-2212, "Kepler-22 b", "\u5f00\u666e\u52d2 22 b", 4, 6, true, 0, "kepler_22_b", "Kepler-22 G5 V", 0F, "", 634.8F, "Planet", 289.8639F),
            new Planet(-2211, "Kepler-442 b", "\u5f00\u666e\u52d2 442 b", 4, 6, true, 0, "kepler_442_b", "Kepler-442", 0F, "", 1194F, "Planet", 112.3053F),
            new Planet(-2210, "Kepler-62 f", "\u5f00\u666e\u52d2 62 f", 4, 6, true, 0, "kepler_62_f", "Kepler-62 K2 V", 0F, "", 981.3F, "Planet", 267.291F),
            new Planet(-2205, "Kepler-186 f", "\u5f00\u666e\u52d2 186 f", 4, 6, true, 0, "kepler_186_f", "Kepler-186 M1", 0F, "", 579.2F, "Planet", 129.9441F),
            new Planet(-2200, "Kepler-452 b", "\u5f00\u666e\u52d2 452 b", 4, 6, true, 0, "kepler_452_b", "Kepler-452 G2", 0F, "", 1799F, "Planet", 384.843F),
            new Planet(-2121, "HD 40307 g", "HD 40307 g", 3, 5, true, 0, "hd_40307_g", "HD 40307 K2.5 V", 0F, "", 42.2F, "Planet", 197.8F),
            new Planet(-2120, "51 Pegasi b", "\u98de\u9a6c\u5ea7 51 b", 3, 5, true, 0, "51_pegasi_b", "51 Peg G5V", 0F, "", 50.4F, "Planet", 4.2308F),
            new Planet(-2119, "55 Cancri e", "55 \u5de8\u87f9\u5ea7 e", 3, 5, true, 0, "55_cancri_e", "55 Cnc G8 V", 0F, "", 41F, "Planet", 0.7365F),
            new Planet(-2116, "HD 219134 b", "HD 219134 b", 3, 5, true, 0, "hd_219134_b", "HD 219134 K3 V", 0F, "", 21.3F, "Planet", 3.0929F),
            new Planet(-2113, "Gliese 876 b", "Gliese 876 b", 3, 5, true, 0, "gliese_876_b", "GJ 876 M2.5V", 0F, "", 15.2F, "Planet", 61.1166F),
            new Planet(-2111, "GJ 667 C c", "Gliese 667 C c", 3, 5, true, 0, "gj_667_c_c", "GJ 667 C M1.5 V", 0F, "", 23.6F, "Planet", 28.14F),
            new Planet(-2108, "Gliese 581 c", "Gliese 581 c", 3, 5, true, 0, "gliese_581_c", "GJ 581 M3.0 V", 0F, "", 20.5F, "Planet", 12.9211F),
            new Planet(-2106, "TRAPPIST-1 h", "TRAPPIST-1 h", 3, 5, true, 0, "trappist_1_h", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 18.7729F),
            new Planet(-2105, "TRAPPIST-1 g", "TRAPPIST-1 g", 3, 5, true, 0, "trappist_1_g", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 12.3524F),
            new Planet(-2104, "TRAPPIST-1 f", "TRAPPIST-1 f", 3, 5, true, 0, "trappist_1_f", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 9.2075F),
            new Planet(-2103, "TRAPPIST-1 e", "TRAPPIST-1 e", 3, 5, true, 0, "trappist_1_e", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 6.101F),
            new Planet(-2102, "TRAPPIST-1 d", "TRAPPIST-1 d", 3, 5, true, 0, "trappist_1_d", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 4.0492F),
            new Planet(-2101, "TRAPPIST-1 c", "TRAPPIST-1 c", 3, 5, true, 0, "trappist_1_c", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 2.4219F),
            new Planet(-2100, "TRAPPIST-1 b", "TRAPPIST-1 b", 3, 5, true, 0, "trappist_1_b", "TRAPPIST-1 M8.0 V", 0F, "", 40.5F, "Planet", 1.5108F),
            new Planet(-2029, "Alpha Centauri A", "\u5357\u95e8\u4e8c A", 2, 4, false, 0, "alpha_centauri_a", "", 0F, "", 4.37F, "Star", 0F),
            new Planet(-2028, "Sirius B", "\u5929\u72fc\u661f B", 2, 4, false, 0, "sirius_b", "", 0F, "", 8.6F, "WhiteDwarf", 0F),
            new Planet(-2026, "Wolf 1061 c", "\u6c83\u5c14\u592b 1061 c", 2, 4, true, 0, "wolf_1061_c", "Wolf 1061 M3.5", 0F, "", 14F, "Planet", 17.8719F),
            new Planet(-2023, "GJ 1002 b", "GJ 1002 b", 2, 4, true, 0, "gj_1002_b", "GJ 1002 M5.5 V", 0F, "", 15.8F, "Planet", 10.3465F),
            new Planet(-2022, "GJ 887 d", "GJ 887 d", 2, 4, true, 0, "gj_887_d", "GJ 887 M1 V", 0F, "", 10.7F, "Planet", 50.77F),
            new Planet(-2018, "GJ 1061 c", "GJ 1061 c", 2, 4, true, 0, "gj_1061_c", "GJ 1061 M5.5 V", 0F, "", 12F, "Planet", 6.6821F),
            new Planet(-2012, "Luyten's Star b", "\u9c81\u5766\u661f b", 2, 4, true, 0, "luyten_s_star_b", "GJ 273 M3.5", 0F, "", 19.3F, "Planet", 18.6498F),
            new Planet(-2011, "Ross 128 b", "\u7f57\u65af 128 b", 2, 4, true, 0, "ross_128_b", "Ross 128 M4", 0F, "", 11F, "Planet", 9.8658F),
            new Planet(-2008, "Teegarden's Star b", "\u8482\u52a0\u767b\u661f b", 2, 4, true, 0, "teegarden_s_star_b", "Teegarden's Star M7.0 V", 0F, "", 12.5F, "Planet", 4.9063F),
            new Planet(-2007, "Epsilon Eridani b", "\u5929\u82d1\u56db b", 2, 4, true, 0, "epsilon_eridani_b", "eps Eri K2 V", 0F, "", 10.4F, "Planet", 2680F),
            new Planet(-2002, "Proxima Centauri d", "\u6bd4\u90bb\u661f d", 2, 4, true, 0, "proxima_centauri_d", "Proxima Cen M5.5 V", 0F, "", 4.24F, "Planet", 5.1234F),
            new Planet(-1998, "Neptune", "\u6d77\u738b\u661f", 1, 3, false, 0, "neptune", "Sol", 30.069F, "", 0.0004754661F, "Planet", 60182F),
            new Planet(-1997, "Uranus", "\u5929\u738b\u661f", 1, 3, false, 0, "uranus", "Sol", 19.191F, "", 0.0003034577F, "Planet", 30688.5F),
            new Planet(-1996, "Saturn", "\u571f\u661f", 1, 3, false, 0, "saturn", "Sol", 9.583F, "", 0.0001515312F, "Planet", 10759.22F),
            new Planet(-1338, "Tau Ceti f", "\u5929\u4ed3\u4e94 f", 2, 4, true, 7, "tau_ceti_f", "Tau Ceti (G8 V)", 0F, "", 11.9F, "Planet", 636F),
            new Planet(-1032, "Barnard's Star d", "\u5df4\u7eb3\u5fb7 d\uff08\u73b0 Barnarda C2\uff09", 2, 4, true, 8, "barnard_s_star_d", "Barnard's star M3.5-4 V", 0F, "", 5.96F, "Planet", 2.3402F),
            new Planet(-1031, "Barnard's Star c", "\u5df4\u7eb3\u5fb7 c\uff08\u73b0 Barnarda C1\uff09", 2, 4, true, 8, "barnard_s_star_c", "Barnard's star M3.5-4 V", 0F, "", 5.96F, "Planet", 4.1244F),
            new Planet(-1030, "Barnard's Star b", "\u5df4\u7eb3\u5fb7 b\uff08\u73b0 Barnarda C\uff09", 2, 4, true, 8, "barnard_s_star_b", "Barnard's star M3.5-4 V", 0F, "", 5.96F, "Planet", 3.1542F),
            new Planet(-1026, "Jupiter", "\u6728\u661f", 1, 3, false, 0, "jupiter", "Sol", 5.204F, "", 0.0000822883F, "Planet", 4332.59F),
            new Planet(-1025, "Proxima Centauri b", "\u6bd4\u90bb\u661f b", 2, 4, true, 8, "proxima_centauri_b", "Proxima Cen M5.5 V", 0F, "", 4.24F, "Planet", 11.1847F),
            new Planet(-1024, "Miranda", "\u5929\u536b\u4e94", 1, 3, true, 5, "miranda", "Sol", 19.192F, "Uranus", 0F, "Moon", 1.413F),
            new Planet(-1023, "Haumea", "\u598a\u795e\u661f", 1, 3, true, 5, "haumea", "Sol", 43.1F, "", 0.0006815188F, "DwarfPlanet", 103731F),
            new Planet(-1022, "Callisto", "\u6728\u536b\u56db", 1, 3, true, 5, "callisto", "Sol", 5.208F, "Jupiter", 0F, "Moon", 16.689F),
            new Planet(-1021, "Triton", "\u6d77\u536b\u4e00", 1, 3, true, 5, "triton", "Sol", 30.07F, "Neptune", 0F, "Moon", 5.877F),
            new Planet(-1018, "Titan", "\u571f\u536b\u516d", 1, 3, true, 5, "titan", "Sol", 9.585F, "Saturn", 0F, "Moon", 15.945F),
            new Planet(-1017, "Enceladus", "\u571f\u536b\u4e8c", 1, 3, true, 5, "enceladus", "Sol", 9.584F, "Saturn", 0F, "Moon", 1.37F),
            new Planet(-1016, "Ganymede", "\u6728\u536b\u4e09", 1, 3, true, 6, "ganymede", "Sol", 5.207F, "Jupiter", 0F, "Moon", 7.155F),
            new Planet(-1015, "Europa", "\u6728\u536b\u4e8c", 1, 3, true, 6, "europa", "Sol", 5.206F, "Jupiter", 0F, "Moon", 3.551F),
            new Planet(-1014, "Io", "\u6728\u536b\u4e00", 1, 3, true, 6, "io", "Sol", 5.205F, "Jupiter", 0F, "Moon", 1.769F),
            new Planet(-1013, "Deimos", "\u706b\u536b\u4e8c", 1, 3, true, 5, "deimos", "Sol", 1.526F, "Mars", 0.0000000025F, "Moon", 1.263F),
            new Planet(-1012, "Phobos", "\u706b\u536b\u4e00", 1, 3, true, 5, "phobos", "Sol", 1.525F, "Mars", 0.000000001F, "Moon", 0.3189F),
            new Planet(-1009, "Kuiper belt", "\u67ef\u4f0a\u4f2f\u5e26", 1, 3, true, 6, "kuiper_belt", "Sol", 44F, "", 0F, "AsteroidBelt", 109500F),
            new Planet(-1008, "Pluto", "\u51a5\u738b\u661f", 1, 3, true, 6, "pluto", "Sol", 39.24F, "", 0.0006204193F, "DwarfPlanet", 90560F),
            new Planet(-1007, "Ceres", "\u8c37\u795e\u661f", 1, 3, true, 6, "ceres", "Sol", 2.77F, "", 0.0000438006F, "DwarfPlanet", 1680.15F),
            new Planet(-1005, "Mercury", "\u6c34\u661f", 1, 3, true, 6, "mercury", "Sol", 0.387F, "", 0.0000061194F, "Planet", 87.969F),
            new Planet(-31, "Venus", "\u91d1\u661f", 1, 3, true, 7, "venus", "Sol", 0.723F, "", 0.0000114324F, "Planet", 224.701F),
            new Planet(-30, "Asteroid belt", "\u5c0f\u884c\u661f\u5e26", 1, 3, true, 7, "asteroid_belt", "Sol", 2.7F, "", 0F, "AsteroidBelt", 1680F),
            new Planet(-29, "Mars", "\u706b\u661f", 1, 3, true, 7, "mars", "Sol", 1.524F, "", 0.0000240983F, "Planet", 686.98F),
            new Planet(-28, "Moon", "\u6708\u7403", 1, 2, true, 7, "moon", "Sol", 1.001F, "Earth", 0.0000000406F, "Moon", 27.3217F),
            new Planet(0, "Earth", "\u5730\u7403", 1, 0, true, 0, "earth", "Sol", 1F, "", 0.0000158125F, "Planet", 365.256F)
    );

    private MinespacePlanetDimensions() {
    }
}
