# NCO / QMD 兼容性导出与修复报告

日期：2026-10-17

> 二阶段更新：稳定材料、GT 已有同位素、概率产出和矿物词典输入已经完成同化。
> 本目录的 CSV 已替换为最新导出；设计说明和最终残留统计见
> [`../nuclear-gt-unification-2026-10-17.md`](../nuclear-gt-unification-2026-10-17.md)。
>
> 最新计数：材料目标 370 条，GT 配方 67854，NCO 配方 5439，QMD 配方 863，工作台配方 22403。
> NCO 四块太阳能板已从工作台迁移到 GT 组装机，旧配方全部变为 `DummyRecipe`；剩余残留项均为
> NCO 反应堆燃料形式、带数字后缀的独有核素、机器部件、食物/医疗物品和 QMD 粒子单元。

## 导出方式

在专用服务器启动参数中加入：

```text
-Dminespace.exportDiagnostics=true
```

导出器只读注册表和配方表，不修改存档。导出目录：

```text
minespace-diagnostics/
```

本目录是修复后的导出结果。

| 文件 | 内容 | 行数/大小 |
| --- | --- | ---: |
| `items.csv` | 物品注册名、metadata、unlocalized、显示名、堆叠上限、矿物词典 | 32102 行 |
| `blocks.csv` | 方块注册名、unlocalized、类名 | 4756 行 |
| `ore-dictionary.csv` | 每个矿物词典名下的全部物品 | 36235 行 |
| `gt-recipes.csv` | GT `RecipeMap` 的输入、流体、输出、概率输出、时间、EU/t | 65053 行 |
| `nco-recipes.csv` | NCO `BasicRecipe` 列表 | 5279 行 |
| `qmd-recipes.csv` | QMD 粒子/流体/物品配方 | 863 行 |
| `qmd-basic-recipes.csv` | QMD 的 NCO 风格基础配方 | 少量 |
| `summary.txt` | 导出计数 | - |

## 已修复的问题

### 1. 1.12.2 方块 ID 上限

加入 NCO 后，Gregicality 注册方块时出现：

```text
Invalid id 4096 - maximum id range exceeded
```

修复：加入 Roughly Enough IDs `2.3.1`，解除 4096 上限。

### 2. NCO / QMD 版本字段不兼容

QMD `1.6.1` + NCO `2o.9.0` 在配方阶段崩溃：

```text
NoSuchFieldError: decay_pool_heat_source
```

修复：改用 NCO `2o.9.7`。旧 `2o.9.0` 已移到 `mods-staging/superseded/`，没有删除。

### 3. NCO 自带 GTCE 配方迁移不可用

NCO 的 `gtce_recipe_integration` 引用 TJ 不存在的：

```text
gregtech.api.recipes.ingredients.GTRecipeInput
```

修复：保持 `gtce_recipe_integration_global=false`，由
`MinespaceNuclearMaterials` 直接读取 NCO 的 `BasicRecipe` 并写入 TJ `RecipeMap`。

当前迁移 3293 条普通材料配方，0 条跳过；NCO 的 `separator`/`centrifuge`
不迁移，保留为核专用机器。

### 4. GT 热离心机绕过 QMD 质谱仪

NCO 的 `separator` 本身就是铀/硼/锂同位素与裂变燃料分离；把它映射到
GT 热离心机会让质谱仪的配方变成 GT 可做。

修复：

- 兼容桥不迁移 `separator` 和 `centrifuge`。
- `nuclear_gt.zs` 不隐藏 NCO 的这两台机器。
- GT 热离心机/离心机不再获得 NCO 的同位素分离配方。

### 5. QMD 普通矿石倍产入口

QMD 的矿石浸出器原本给铁/金/铜/锡/铅/镍/银/铝等普通矿石 3 份粉；
质谱仪也有同样的普通矿石 4 倍入口。

修复：`MinespaceQmdCompatibility` 移除两类机器的 8 条普通矿石配方，
保留铀、钍、锂、镁、硼、锇、铱、铂等核/稀有矿入口。

- 矿石浸出器：16 → 8 条
- 质谱仪：130 → 122 条

### 6. NCO / QMD 稳定材料重复产出

导出显示 GT 与 NCO 共享 109 个矿物词典名，GT 与 QMD 共享 47 个。
这些名字大多同时列出 GT 和模组自己的锭/粉，导致 GT 机器仍可能产出
NCO/QMD 的重复物品。

修复：`MinespaceMaterialRepoint` 增加稳定材料映射，目标优先选择
`gregtech:` 物品；核同位素不在映射中。

修复后：

- 16 条 GT 机器输出从 NCO/QMD 稳定粉/锭改为 GT 物品。
- 242 个合成输入槽改为接受 GT 物品。
- GT 机器配方中仍保留 444 条 NCO 输出和 62 条 QMD 输出；这些是
  tough alloy、ferroboron、QMD 粒子/部件等模组专属物品，不应强行合并。

### 7. 缺失注册表引用

对 GT/NCO/QMD 配方里的物品注册名做基础 ID 检查：

```text
missing_base_registries = 0
```

没有发现配方引用不存在的物品注册名。

### 8. 资源闭包

运行 `tools/check-resource-closure.ps1`：

```text
[ OK ] no ore-bearing material is left without a source (0 gaps)
[ OK ] no material is supplied after its last use (0 too late)
```

## 剩余风险

1. **矿物词典仍保留 GT/NCO/QMD 的同名条目。** 修复的是 GT 机器输出和
   合成输入，NCO/QMD 自己的机器配方仍使用自己的物品。JEI 中仍可能看到
   同名的锭/粉条目；要彻底消除，需要继续改写 QMD/NCO 自身的配方输出。

2. **NCO 分离器/离心机仍然存在。** 它们可以处理核燃料和同位素；
   QMD 质谱仪是 GT 侧入口，但 NCO 侧仍有自己的同位素链。若希望
   “只有质谱仪能做同位素分离”，需要禁用或重新门槛化 NCO 这两台机器，
   并为 NCO 燃料链补替代路线。

3. **QMD 质谱仪仍有 122 条配方。** 已移除普通矿石入口，但还保留
   普通材料/化学品配方；是否继续裁剪取决于最终平衡目标。

4. **客户端模型/贴图未在专用服务器验证。** `items.csv` 能证明注册表
   完整，不能证明每个模型文件存在；需要进客户端或运行客户端模型检查
   才能覆盖这一项。

## 验证基线

- `deployToInstance` 成功；模块边界 67 个文件，0 违规。
- 专用服务器加载 54 个 mod，`Done (2.067s)`。
- `crafttweaker.log` 0 error。
- 配方卫生：71529 条、73 个 recipe map、5 条可合并重复、0 组输入重叠。
