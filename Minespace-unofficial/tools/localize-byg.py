#!/usr/bin/env python3
"""Adapt the community BYG 1.12.2 translation to BYG Legacy Edition's underscored keys."""

import argparse
import io
import re


WOODS = {
    "aspen": "白杨", "baobab": "猴面包", "blue_enchanted": "蓝色魔法",
    "brown_enchanted": "棕色魔法", "cherry": "樱花", "cika": "西卡",
    "cypress": "柏树", "ebony": "乌木", "eucalyptus": "桉树",
    "rainbow_eucalyptus": "彩虹桉", "fir": "冷杉", "frozen_oak": "冰封橡木",
    "great_oak": "大橡木", "green_enchanted": "绿色魔法", "hawthorn": "山楂",
    "holly": "冬青", "ironwood": "铁木", "jacaranda": "蓝花楹",
    "mahogany": "桃花心木", "mangrove": "红树", "maple": "枫树",
    "palm": "棕榈", "palo_verde": "绿檀", "pine": "松树",
    "redwood": "红杉", "rowan": "花楸", "skyris": "天灵",
    "willow": "柳树", "witch_hazel": "金缕梅", "zelkova": "榉树",
    "yellow_enchanted": "黄色魔法", "purple_enchanted": "紫色魔法",
    "red_enchanted": "红色魔法", "cyan_enchanted": "青色魔法",
    "orange_enchanted": "橙色魔法", "white_enchanted": "白色魔法",
    "black_enchanted": "黑色魔法", "pink_enchanted": "粉色魔法",
    "lime_enchanted": "黄绿色魔法", "gray_enchanted": "灰色魔法",
    "light_blue_enchanted": "淡蓝色魔法", "magenta_enchanted": "品红色魔法",
    "red_birch": "红桦", "yellow_birch": "黄桦", "orange_birch": "橙桦",
    "brown_birch": "棕桦", "silver_maple": "银枫", "red_maple": "红枫",
    "dry_green_oak": "干绿橡木", "dry_brown_oak": "干棕橡木",
    "latharium": "拉萨利姆", "pendorite": "彭多莱特", "tamrelite": "塔姆雷特",
    "kasai": "卡塞", "rocky_stone": "岩石", "scoria": "火山渣",
    "sepinite": "云母", "soapstone": "皂石", "sodalite": "方钠石",
    "overgrown_stone": "覆苔石", "red": "红色", "blue": "蓝色",
    "green": "绿色", "purple": "紫色", "white": "白色",
    "light_blue": "淡蓝色", "pink": "粉色", "yellow": "黄色",
    "orange": "橙色", "cyan": "青色", "magenta": "品红色",
    "lime": "黄绿色", "gray": "灰色", "black": "黑色", "brown": "棕色",
}

SUFFIXES = {
    "planks": "木板", "log": "原木", "wood": "木材", "leaves": "树叶",
    "sapling": "树苗", "stairs": "楼梯", "slab": "台阶", "fence": "栅栏",
    "gate": "栅栏门", "wall": "墙", "bookshelf": "书架", "door": "门",
    "trapdoor": "活板门", "sign": "告示牌", "button": "按钮",
    "pressureplate": "压力板", "carpet": "地毯", "boat": "船",
    "chest": "箱子", "craftingtable": "工作台", "ladder": "梯子",
    "stick": "木棍", "woodwall": "木墙", "bricks": "砖", "pillars": "柱",
    "tile": "瓦", "walls": "墙", "cobblestone": "圆石", "stone": "石",
    "sand": "沙", "sandstone": "砂岩", "crackedsand": "裂沙",
    "chiseledsandstone": "雕纹砂岩", "smoothsandstone": "平滑砂岩",
    "crystalblock": "水晶块", "ore": "矿石", "block": "块",
    "glowshroom": "荧光蘑菇", "petal": "花瓣", "rose": "玫瑰",
    "amaranth": "苋菜", "stickpile": "枝堆",
    "tulip": "郁金香", "brickstairs": "砖楼梯", "brickwalls": "砖墙",
}

SPECIAL = {
    "rocky_grass": "岩草", "rocky_grass_alps": "高山岩草",
    "sappy_maple_log": "流脂枫树原木", "maple_tap": "枫树液采集器",
    "allium_bush": "绒球葱丛", "pink_allium_bush": "粉色绒球葱丛",
    "alpine_bellflower": "高山风铃草", "angelica": "当归",
    "delphinium": "飞燕草", "daffodil": "水仙", "iris": "鸢尾",
    "japanese_orchid": "日本兰花", "lollipop_flower": "棒棒糖花",
    "protea_flower": "帝王花", "torch_ginger": "火炬姜",
    "winter_rose": "冬玫瑰", "winter_succulent": "冬多肉",
    "weeping_milk_cap": "流泪乳菇", "wood_blewit": "紫丁香蘑",
    "shelf_fungi": "层孔菌", "short_dead_grass": "枯草",
    "prairie_grass": "草原草", "reed": "芦苇", "reeds": "芦苇",
    "poison_ivy": "毒常春藤", "ivy": "常春藤", "thorn_branches": "荆棘枝",
    "thorn_block": "荆棘块", "flowers": "花", "plant_stem": "植物茎",
    "maple_sap": "枫树液", "maple_syrup": "枫糖浆",
    "maple_pancakes": "枫糖煎饼", "baobab_fruit": "猴面包果",
    "baobab_powder": "猴面包粉", "berry_juice": "浆果汁",
    "cattail": "香蒲", "cattail_rhizome": "香蒲根茎",
    "cooked_cattail_rhizome": "烤香蒲根茎", "green_apple": "青苹果",
    "green_apple_pie": "青苹果派", "silver_apple": "银苹果",
    "mud_balls": "泥球", "worm": "蠕虫", "wooden_mortar": "木臼",
    "light_blue_crystals": "淡蓝色水晶", "purple_crystals": "紫色水晶",
    "red_crystals": "红色水晶", "white_crystals": "白色水晶",
    "tropical_fish_soup": "热带鱼汤", "spider_eye_soup": "蛛眼汤",
    "glowshroom_soup_blue": "蓝色荧光蘑菇汤",
    "glowshroom_soup_purple": "紫色荧光蘑菇汤",
    "green_glowshroom_stew": "绿色荧光蘑菇汤",
    "golden_beetroot": "金甜菜根", "hawthorn_berries": "山楂果",
    "holly_berries": "冬青果", "rowan_berries": "花楸果",
    "salal_berry": "沙龙白珠果", "rudo_beans": "鲁多豆",
    "rudo_beans_roasted": "烤鲁多豆", "pumpkin_bread": "南瓜面包",
    "pumpkin_mash": "南瓜泥",
    "algae": "藻类", "azalea": "杜鹃花", "begonia": "秋海棠",
    "bistort": "拳参", "black_puff": "黑粉菌", "blanket_weed": "毯草",
    "carved_melon": "雕刻南瓜", "cattails": "香蒲", "cracked_sand": "裂沙",
    "fairy_slipper": "仙履兰", "golden_spined_cactus": "金刺仙人掌",
    "itemGroup.tabbyg": "BYG 物品", "itemGroup.tabbygbiomes": "BYG 生物群系传送器",
    "byg_logo": "BYG 标志",
    "scoria": "火山渣", "overgrown_stone": "覆苔石",
    "polished_soapstone": "抛光皂石",
    "polished_soapstone_stairs": "抛光皂石楼梯",
    "polished_soapstone_walls": "抛光皂石墙",
    "polished_sodalite": "抛光方钠石",
    "polished_sodalite_stairs": "抛光方钠石楼梯",
    "polished_sodalite_walls": "抛光方钠石墙",
    "sodalite_brick_stairs": "方钠石砖楼梯",
    "sodalite_brick_walls": "方钠石砖墙",
    "silver_apple_white_skyris_leaves": "银苹果白色天灵树叶",
    "white_skyris_leaves": "白色天灵树叶",
    "medium_blue_glowshroom": "中型蓝色荧光蘑菇",
    "medium_green_glowshroom": "中型绿色荧光蘑菇",
    "medium_purple_glowshroom": "中型紫色荧光蘑菇",
    "small_blue_glowshroom": "小型蓝色荧光蘑菇",
    "small_green_glowshroom": "小型绿色荧光蘑菇",
    "small_purple_glowshroom": "小型紫色荧光蘑菇",
    "green_tulip": "绿色郁金香", "guzmania": "果子蔓",
    "hawthorn_leaves_flowering": "开花山楂树叶", "horseweed": "飞蓬",
    "jackomelon": "杰克瓜", "kovan": "科万花",
    "lazarus_bell_flower": "拉撒路风铃草", "osiria_rose": "奥西里亚玫瑰",
    "pasture_dirt": "牧场土", "prickly_pear": "仙人掌果",
    "purple_age": "紫色鼠尾草", "richea": "里奇花",
    "rudo_stalk": "鲁多茎", "salal_bush": "沙龙白珠灌木",
    "salal_bush_ripe": "成熟沙龙白珠灌木", "stone_pebbles": "碎石",
    "wild_rudo": "野生鲁多",
}

DIRECT = {
    "entity.crystalcrawler.name": "水晶爬虫",
    "fluid.springwater": "泉水",
    "fluid.test": "测试流体",
    "itemGroup.tabbyg": "BYG 物品",
    "itemGroup.tabbygbiomes": "BYG 生物群系传送器",
    "effect.clarity": "清晰",
    "potion.effect.clarity": "清晰药水",
    "potion.effect.clarity_potion": "清晰药水",
    "splash_potion.effect.clarity_potion": "喷溅型清晰药水",
    "lingering_potion.effect.clarity_potion": "滞留型清晰药水",
    "tipped_arrow.effect.clarity_potion": "清晰之箭",
    "advancements.byg.root.title": "你将去的地方",
    "advancements.byg.root.description": "探索纱线之外的世界",
    "advancements.byg.kasai_full_set.title": "烈焰锻造",
    "advancements.byg.kasai_full_set.description": "获得一整套卡塞盔甲",
    "advancements.byg.latharium_full_set.title": "云端之上",
    "advancements.byg.latharium_full_set.description": "获得一整套拉萨利姆盔甲",
    "advancements.byg.spore_wars.title": "孢子战争",
    "advancements.byg.spore_wars.description": "击败一只真菌僵尸",
    "advancements.byg.sweet_tooth.title": "甜食爱好者",
    "advancements.byg.sweet_tooth.description": "获得蓝莓派、青苹果派、草莓派和枫糖煎饼",
    "advancements.byg.tamrelite_gem.title": "地下的第一步",
    "advancements.byg.tamrelite_gem.description": "获得塔姆雷特宝石",
    "advancements.byg.pendorite_gem.title": "深入远古",
    "advancements.byg.pendorite_gem.description": "获得彭多莱特宝石",
    "advancements.byg.kasai_ingot.title": "点燃熔炉",
    "advancements.byg.kasai_ingot.description": "获得卡塞锭",
    "advancements.byg.maple_sap.title": "从树液到糖浆",
    "advancements.byg.maple_sap.description": "用枫树液采集器收集枫树液",
    "advancements.byg.token_of_love.title": "爱的信物",
    "advancements.byg.token_of_love.description": "给已驯服的动物喂食金甜菜根",
    "tooltip.byg.latharium_armor": "全套效果：潜行时漂浮",
    "tooltip.byg.kasai_armor": "全套效果：着火时获得抗火效果 %s（冷却 %s）",
    "item.byg.biome_teleporter.named": "传送：%s",
    "item.byg.biome_teleporter.no_biome": "（无生物群系）",
    "tooltip.byg.biome_teleporter": "仅创造模式。右键传送到最近的匹配生物群系。",
    "message.byg.biome_teleporter.creative_only": "生物群系传送器只能在创造模式使用。",
    "message.byg.biome_teleporter.invalid_biome": "物品没有有效的生物群系：%s",
    "message.byg.biome_teleporter.searching": "正在寻找生物群系：%s...",
    "message.byg.biome_teleporter.not_found": "在 %s 格范围内找不到 %s（这种世界类型会生成它吗？）。",
    "message.byg.biome_teleporter.teleported": "已传送到 %s（%s, %s）。",
    "tooltip.byg.maple_syrup": "饮用可恢复饥饿并获得速度，也可用于烹饪",
    "tooltip.byg.maple_syrup_sips": "剩余口数：%s",
    "tooltip.byg.baobab_powder": "可酿造清晰药水",
    "tooltip.byg.glowcane_stalk": "只能种在荧光菌土上",
    "tooltip.byg.worm": "钓鱼时携带可缩短等待时间，抛竿时消耗",
    "tooltip.byg.baobab_fruit.clear_effects": "食用后清除当前药水效果",
    "tooltip.byg.baobab_fruit.plant": "对猴面包树叶使用以种植果实",
    "tooltip.byg.berry_juice.heals": "恢复饥饿值和饱和度，并治疗你",
    "tooltip.byg.nether_furnace.unlit": "在这个熔炉正下方点火即可点燃",
    "tooltip.byg.golden_beetroot.player": "食用后获得生命恢复 I，持续 %s",
    "tooltip.byg.golden_beetroot.pet": "喂给已驯服的生物可使其永久缓慢恢复生命",
    "tile.silver_vase_flower.name": "银瓶花",
}

# BYG's decorative rocks/crystals must not share a Chinese name with a GT material or another
# installed mod's ore/gem. These overrides are checked before the community translation.
ZH_OVERRIDES = {
    "tile.sodalite.name": "碧纹岩",
    "tile.polished_sodalite.name": "抛光碧纹岩",
    "tile.polished_sodalite_stairs.name": "抛光碧纹岩楼梯",
    "tile.polished_sodalite_walls.name": "抛光碧纹岩墙",
    "tile.sodalite_tile.name": "雕纹碧纹岩",
    "tile.sodalite_bricks.name": "碧纹岩砖",
    "tile.sodalite_brick_stairs.name": "碧纹岩砖楼梯",
    "tile.sodalite_brick_walls.name": "碧纹岩砖墙",
    "tile.scoria.name": "熔孔岩",
    "tile.scoria_bricks.name": "熔孔岩砖",
    "tile.scoria_pillars.name": "熔孔岩柱",
    "tile.scoria_stairs.name": "熔孔岩楼梯",
    "tile.scoria_walls.name": "熔孔岩墙",
    "tile.sepinite.name": "赛平岩",
    "tile.sepinite_bricks.name": "赛平岩砖",
    "tile.sepinite_pillars.name": "赛平岩柱",
    "tile.sepinite_stairs.name": "赛平岩楼梯",
    "tile.sepinite_tile.name": "赛平岩瓦",
    "tile.sepinite_walls.name": "赛平岩墙",
    "tile.soapstone.name": "滑腻岩",
    "tile.soapstone_pillars.name": "滑腻岩柱",
    "tile.soapstone_tile.name": "雕纹滑腻岩",
    "tile.polished_soapstone.name": "抛光滑腻岩",
    "tile.polished_soapstone_stairs.name": "抛光滑腻岩楼梯",
    "tile.polished_soapstone_walls.name": "抛光滑腻岩墙",
    "tile.rocky_stone.name": "崎岖岩",
    "tile.rocky_grass.name": "崎岖草",
    "tile.rocky_grass_alps.name": "高山崎岖草",
    "tile.mud_block.name": "塘泥块",
    "tile.mud_bricks.name": "塘泥砖",
    "tile.peat_dirt.name": "腐殖土",
    "tile.peat_grass.name": "腐殖草方块",
    "tile.light_blue_crystal_block.name": "淡蓝彩晶块",
    "tile.purple_crystal_block.name": "紫色彩晶块",
    "tile.red_crystal_block.name": "红色彩晶块",
    "tile.white_crystal_block.name": "白色彩晶块",
    "item.light_blue_crystals.name": "淡蓝彩晶",
    "item.purple_crystals.name": "紫色彩晶",
    "item.red_crystals.name": "红色彩晶",
    "item.white_crystals.name": "白色彩晶",
}

EQUIPMENT = {
    "helmet": "头盔", "body": "胸甲", "legs": "护腿", "boots": "靴子",
    "pickaxe": "镐", "axe": "斧", "shovel": "锹", "sword": "剑",
    "hoe": "锄", "battleaxe": "战斧", "gem": "宝石", "ingot": "锭",
    "armour": "盔甲", "chain_plating": "链甲片", "block": "块",
    "armour_helmet": "头盔", "armour_body": "胸甲", "armour_legs": "护腿",
    "armour_boots": "靴子",
}


def parse(path):
    entries = {}
    for line in io.open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        entries[key.strip()] = value
    return entries


def translate(key, english, old, old_norm):
    if key in ZH_OVERRIDES:
        return ZH_OVERRIDES[key]
    if key in DIRECT:
        return DIRECT[key]
    chinese = re.compile(r"[\u4e00-\u9fff]")
    if key in old:
        if chinese.search(old[key]):
            return old[key]
    normalized = key.replace("_", "")
    if normalized in old_norm and chinese.search(old_norm[normalized]):
        return old_norm[normalized]
    if not (key.startswith("tile.") or key.startswith("item.")):
        return english

    path = key.split(".", 1)[1]
    if path.endswith(".name"):
        path = path[:-5]
    stripped = path.startswith("stripped_")
    if stripped:
        path = path[9:]
    potted = path.startswith("potted_")
    if potted:
        path = path[7:]
    path = re.sub(r"_(door_)?open_(bottom|top)$", "_door", path)
    path = re.sub(r"_door_(bottom|top)$", "_door", path)
    path = re.sub(r"_gate_(closed|open)$", "_gate", path)
    path = re.sub(r"_(open|closed)$", "", path)
    path_norm = path.replace("_", "")

    for wood in sorted(WOODS, key=len, reverse=True):
        wood_norm = wood.replace("_", "")
        if path_norm.startswith(wood_norm):
            suffix = path_norm[len(wood_norm):]
            if suffix in SUFFIXES:
                value = WOODS[wood] + SUFFIXES[suffix]
                if stripped:
                    value = "去皮" + value
                if potted:
                    value = "盆栽" + value
                return value

    if path in SPECIAL:
        return SPECIAL[path]

    # Equipment items: latharium_pickaxe, pendorite_armour_body, ...
    for material in ("latharium", "pendorite", "tamrelite", "kasai"):
        if path.startswith(material + "_"):
            suffix = path[len(material) + 1:]
            if suffix in EQUIPMENT:
                return WOODS[material] + EQUIPMENT[suffix]
    return english


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--old", required=True)
    parser.add_argument("--en", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    old = parse(args.old)
    old_norm = {key.replace("_", ""): value for key, value in old.items()}
    english = parse(args.en)

    with io.open(args.out, "w", encoding="utf-8", newline="\n") as out:
        out.write("# BYG Legacy Edition Chinese names, adapted from the community BYG 1.12.2 translation.\n")
        translated = 0
        for key, value in english.items():
            result = translate(key, value, old, old_norm)
            if result != value:
                translated += 1
            out.write(f"{key}={result}\n")
    print(f"translated {translated} / {len(english)}")


if __name__ == "__main__":
    main()
