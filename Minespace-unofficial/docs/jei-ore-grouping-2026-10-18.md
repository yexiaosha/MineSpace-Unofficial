# JEI 矿脉页按矿石种类分组

日期：2026-10-18

## 问题

GregTech 的 JEI 矿脉分类（`gregtech:ore_spawn_location`）把一条矿脉的所有**唯一方块**
按 5 列铺开。整合包加入大量行星石种后，同一种镍矿在每个石种里都成了一个独立槽位，
一条镍矿脉有 50 多个格子，页面被撑到屏幕外；同时 GT 的矿石权重提示按槽位序号索引
矿物列表，序号超过矿物种类数时会抛 `IndexOutOfBoundsException`。

## 方案

`MinespaceJeiPlugin` 在 JEI 运行时把每条原始 `GTOreInfo` 替换成
`GroupedGTOreInfo`。它重写 `findUniqueBlocksAsItemStack`，按 GT 材料把方块分组：
镍、石榴石镍矿、钴镍矿等各占一个槽位；同一矿石在不同石种里的方块作为该槽位的
JEI 可选变体保留，鼠标移到槽位上可以切换查看，没有丢失任何变体。

这样矿脉页恢复成正常高度，槽位数回到矿石种类数，GT 的权重提示也能按正确序号显示。

## 页面高度

GT 的矿脉分类使用固定的 176×166 背景。按矿石分组后，第二个输入格结束于 y=91，
生成范围/权重/维度文字结束于 y≈100，166 的下半部分全是空白；在 GUI 自动档为 3–4 时，
这 46 像素的空白会把页面底部推到屏幕外。

`MixinGTOrePageHeight` 在原分类构造完成后把背景替换为 `MinespaceOreBackground`，高度改为
120。页面内容保持不变，只是去掉空白；在 4x 下少占 184 像素高度。若以后某条矿脉的维度
文字仍超过 120，再在该区域加入滚动偏移，而不是继续加高页面。

## 文件

- `navigation/jei/MinespaceJeiPlugin.java`：JEI 插件入口，移除原始条目并注册分组条目；
- `navigation/jei/GroupedGTOreInfo.java`：按材料分组输出方块的 `GTOreInfo` 子类；
- `build.gradle`：以 `compileOnly` 方式编译 JEI API，不把 JEI 打进 jar。

分组键优先使用 `OreDictUnifier.getMaterial(stack)`；没有材料的方块退回物品注册名 +
metadata，避免把不相关的方块合并。
