package com.minespace.unofficial.gtceu;

import java.util.HashMap;
import java.util.Map;

/**
 * Chinese names for BYG Legacy Edition's hard-coded biome names.
 *
 * <p>BYG creates its biomes with {@code new BiomeProperties("Allium Fields")}, so the name is not
 * a language key and a resource-pack lang file cannot reach it. The client mixin on
 * {@code Biome.getBiomeName} maps the registry path through this table; registry ids and world
 * data are untouched.</p>
 */
public final class MinespaceBygNames {

    private static final Map<String, String> BIOMES = new HashMap<>();

    static {
        put("byg_allium_fields", "绒球葱原野");
        put("byg_alps", "阿尔卑斯");
        put("byg_amaranth_fields", "苋菜原野");
        put("byg_ancient_forest", "远古森林");
        put("byg_aspen_forest", "白杨森林");
        put("byg_baobab_savanna", "猴面包稀树草原");
        put("byg_bayou", "河口沼泽");
        put("byg_blue_taiga", "蓝色针叶林");
        put("byg_bluff_mountains", "悬崖山脉");
        put("byg_bog", "泥炭沼泽");
        put("byg_boreal_forest", "北方针叶林");
        put("byg_chaparral_lowlands", "查帕拉尔低地");
        put("byg_cherry_grove", "樱花林");
        put("byg_cika_forest", "西卡森林");
        put("byg_colored_canyons", "彩色峡谷");
        put("byg_coniferous_forest", "针叶林");
        put("byg_crystal_canyons", "水晶峡谷");
        put("byg_cypress_swamplands", "柏树沼泽");
        put("byg_dead_sea", "死海");
        put("byg_deciduous_forest", "落叶林");
        put("byg_dover_mountains", "多佛山");
        put("byg_dunes", "沙丘");
        put("byg_ebony_woods", "乌木森林");
        put("byg_enchanted_forest", "魔法森林");
        put("byg_evergreen_taiga", "常绿针叶林");
        put("byg_flowering_plains", "花海平原");
        put("byg_frosty_forest", "霜冻森林");
        put("byg_fungal_jungle", "真菌丛林");
        put("byg_giant_blue_spruce_taiga", "巨型蓝云杉针叶林");
        put("byg_giant_seasonal_spruce_taiga", "巨型季节云杉针叶林");
        put("byg_giant_snowy_spruce_taiga", "巨型雪云杉针叶林");
        put("byg_glaciers", "冰川");
        put("byg_glowshroom_bayou", "荧光蘑菇河口");
        put("byg_grassland_plateau", "草原高原");
        put("byg_great_lakes", "大湖");
        put("byg_great_oak_lowlands", "大橡木低地");
        put("byg_jacaranda_forest", "蓝花楹森林");
        put("byg_lush_desert", "繁茂沙漠");
        put("byg_mangrove_marshes", "红树沼泽");
        put("byg_maple_taiga", "枫树针叶林");
        put("byg_marshlands", "沼泽地");
        put("byg_meadow", "草甸");
        put("byg_mesa_highlands", "石柱高地");
        put("byg_northern_forest", "北方森林");
        put("byg_orchard", "果园");
        put("byg_outback", "内陆荒原");
        put("byg_outlands", "外域");
        put("byg_pine_lowlands", "松树低地");
        put("byg_pine_mountains", "松树山脉");
        put("byg_prairie", "草原");
        put("byg_quagmire", "泥沼");
        put("byg_red_desert", "红色沙漠");
        put("byg_red_oak_forest", "红橡森林");
        put("byg_red_outlands", "红色外域");
        put("byg_redwood_tropics", "红杉热带");
        put("byg_savanna_canopy", "稀树草原林冠");
        put("byg_seasonal_birch_forest", "季节桦树林");
        put("byg_seasonal_deciduous", "季节落叶林");
        put("byg_seasonal_forest", "季节森林");
        put("byg_seasonal_taiga", "季节针叶林");
        put("byg_shrublands", "灌木地");
        put("byg_skyris_highlands", "天灵高地");
        put("byg_snowy_coniferous_forest", "雪针叶林");
        put("byg_snowy_deciduous_forest", "雪落叶林");
        put("byg_snowy_evergreen_taiga", "雪常绿针叶林");
        put("byg_snowy_pine_mountains", "雪松山脉");
        put("byg_sonoran_desert", "索诺兰沙漠");
        put("byg_stellata_pasture", "星花牧场");
        put("byg_stone_brushlands", "石灌木地");
        put("byg_stone_pillar_savanna", "石柱稀树草原");
        put("byg_tropical_islands", "热带岛屿");
        put("byg_tropical_mountains", "热带山脉");
        put("byg_tropical_rainforest", "热带雨林");
        put("byg_weeping_witch_forest", "哭泣女巫森林");
        put("byg_whispering_woods", "低语森林");
        put("byg_woodlands", "林地");
        put("byg_zelkova_forest", "榉树森林");
    }

    private MinespaceBygNames() {
    }

    public static String biomeName(String registryPath) {
        return BIOMES.get(registryPath);
    }

    private static void put(String path, String name) {
        BIOMES.put(path, name);
    }
}
