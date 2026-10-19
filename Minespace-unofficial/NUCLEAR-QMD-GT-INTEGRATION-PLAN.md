# 核电工艺与量子块动力学接入 GT 科技线方案

状态：**NCO / QMD 已安装并通过专用服务器首轮启动。**

范围：只讨论 NuclearCraft: Overhauled（下称 NCO）和 Quantum Minecraft Dynamics（下称 QMD）如何接入现有 GTCE-TJ + Minespace 科技线。本文不新增 Minespace 模块，不改任何现有注册名、贴图命名空间或天体表。

决策记录：2026-10-17，RF/EU 全阶段双向等效已确认；实例 `scripts/power.zs` 的旧 HV 封顶已移除。NCO / QMD 已安装，专用服务器实测加载 54 个 mod 并到达 `Done`。NCO 的分离器/离心机不进入 GT 桥，QMD 质谱仪保留为 GT 侧同位素分离入口。

---

## 0. 先确认两个模组的真实身份

| 中文叫法 | 实际模组 | modid | 1.12.2 版本 | 定位 |
| --- | --- | --- | --- | --- |
| 核电工艺 | NuclearCraft: Overhauled | `nuclearcraft` | `2o.9.7` beta | 裂变、熔盐裂变、聚变、燃料再处理、辐射、涡轮发电 |
| 量子块动力学 | Quantum Minecraft Dynamics | `qmd` | `1.6.1` | NCO 的粒子加速器附属：直线/同步加速器、靶室、衰变室、质谱仪、反物质、核合成 |
| NCO 前置 | NCO Java Legacy Lib | `nclegacy` | `1.2` | QMD 1.4+ 的必需前置 |
| 方块 ID 扩展 | Roughly Enough IDs | `jeid` | `2.3.1` | 解除 1.12.2 的 4096 方块 ID 上限，大型整合包必需 |

这里有一个必须先说清楚的结论：**QMD 不是量子计算机或量子存储模组。** 它的 “Quantum” 指粒子物理和高能物理，不是量子比特、量子电路或 AE2 量子网络。它提供的是加速器、粒子束、反物质和核合成，不会给 GT 增加一套量子计算科技线。若以后确实要做量子计算/量子存储，那是另一个模组或另一套自研内容，不能拿 QMD 顶替。

已核实：

- NCO 的 `mcmod.info` 声明 `modid=nuclearcraft`，并自带 `enable_gtce_eu` 与 `gtce_recipe_integration` 配置。
- QMD 的 `mcmod.info` 声明 `modid=qmd`，依赖 `nuclearcraft` 和 `nclegacy`。
- QMD 1.6.1 的配方系统有完整的 CraftTweaker 接口，覆盖靶室、核合成室、质谱仪、液化器、矿石浸出器等。
- QMD 只有 RF 能量接口，没有 GTCE 的 EU 接口；NCO 则原生支持 GTCE EU。
- NCO `2o.9.0` 与 QMD `1.6.1` 字段不兼容（`decay_pool_heat_source`）；QMD `1.6.1` 必须搭配 NCO `2o.9.7`。
- NCO 自带的 `gtce_recipe_integration` 在 TJ 上会因缺少 `gregtech.api.recipes.ingredients.GTRecipeInput` 崩溃，必须关闭，改用 CraftTweaker 手工迁移。

---

## 1. 现有科技阶梯与天体阶数

现有星表的阶段、电压和天体层级如下。这里把“阶段”按 `planet-catalog.csv` 的 `Stage` 列使用，不再另造一套编号。

| 阶段 | 天体范围 | 星表电压 | 研究数据门槛 | 说明 |
| --- | --- | --- | --- | --- |
| 0 | 地球 | 蒸汽 / LV 起点 | 无 | 主世界起点 |
| 2 | 月球 | 蒸汽~LV | 无，行星研究解锁 | GC 月球，第一颗外星 |
| 3 | 太阳系其余天体 | 蒸汽~EV | 行星研究逐天体解锁 | 水星、火星、金星、小行星带、木星/土星卫星等 |
| 4 | 近邻星系区 | IV | 研究数据 I | 比邻星、巴纳德、天仓五等 |
| 5 | 中距星系区 | LuV~ZPM | 研究数据 II | TRAPPIST-1、Gliese 等 |
| 6 | 远距星系区 | UV | 研究数据 III | 开普勒场等 |
| 7 | 深空星系区 | UHV | 研究数据 IV | 脉冲星、银心、星团 |
| 8 | 超深空 / 未知 | UHV+ | 研究数据 V / VI | 星系、超新星遗迹、未知层 |

接入原则：**NCO/QMD 不新增天体，也不改变星图解锁规则。** 它们只消费现有天体提供的矿脉、气体、辐射环境和研究进度。

---

## 2. 总体定位

### 2.1 两条支线的分工

```text
EV    NCO 固态裂变入门
      ├─ 铀/钍燃料、基础辐照、裂变控制棒
      └─ 辐射防护、裂变散热
IV    NCO 完整燃料循环
      ├─ 燃料再处理、钚/镎/锕系
      ├─ 熔盐裂变、热交换器、涡轮
      └─ QMD 阶段 0：空气分离、低温冷却剂、矿石浸出、NCO 辐照
LuV   QMD 阶段 1 + NCO 聚变
      ├─ 直线加速器、靶室、P/N 型掺杂硅
      ├─ NCO 聚变只做中子源/同位素增殖/辅助热源
      └─ GT 聚变 MK1 仍是主聚变线
ZPM   QMD 阶段 2
      ├─ 同步加速器、质谱仪、束流操控
      └─ BSCCO/SSFAF 等超导材料接入 GT 高端机器
UV    QMD 阶段 3
      ├─ 真空室、异常物质遏制、反物质
      ├─ 核合成室：只做重元素/超重元素/奇异物质
      └─ GT 聚变 MK3 与 GT UHV 材料仍是主线
UHV   规模化与终局
      └─ QMD 设备扩产、NCO 锎系燃料、GT UHV+ 组件
```

### 2.2 不能让这两条支线变成“平行 GT”

必须守住四条底线：

1. **NCO/QMD 的通用加工不替代 GT 的通用加工。** 普通粉碎、离心、电解、合金、组装等继续走 GT 机器。
2. **QMD 的质谱仪和矿石浸出器不能成为通用矿石四倍/三倍产线。** 只处理核燃料、稀有元素和 QMD 专属中间体。
3. **NCO 聚变不能绕过 GT 聚变 MK1/MK2/MK3。** 它只提供中子、同位素和热量。
4. **QMD 的核合成不能成为“任意元素免费制造机”。** 只保留超重元素、锕系、反物质和少量剧情材料。

---

## 3. 模块与代码归属

NCO 和 QMD 是外部模组，不是 `minespace_planets` / `minespace_navigation` 这类 Minespace 模块。接入代码不要塞进行星或星图模块。

| 内容 | 放置位置 | 原因 |
| --- | --- | --- |
| NCO/QMD 存在性检测 | `minespace_core` 的 `ModPresence` | core 是整合层，允许引用外部模组 |
| GT 配方迁移、能源桥、辐射桥 | `minespace_core` | 属于 GT/第三方整合，不改变行星和星图边界 |
| NCO/QMD 机器配方脚本 | 实例 `scripts/`，例如 `nuclear_gt.zs`、`qmd_gt.zs` | 配方是整合包运行时内容，不打进 Minespace jar |
| 天体矿脉、环境辐射数据 | 现有 `planets` / 数据表 | 不新建模块，不新增天体 |
| 星图、火箭、研究数据 | `navigation` / `core` 现有逻辑 | NCO/QMD 不参与星图解锁 |

`Minespace` 的依赖只应增加可选的 `after:`，不要写 `required-after:nuclearcraft` 或 `required-after:qmd`。这样没有装 NCO/QMD 时，Minespace 仍然能单独启动。

建议的依赖顺序：

```text
gregtech
  -> nuclearcraft
       -> nclegacy
            -> qmd
minespace_core
  -> minespace_planets
       -> minespace_navigation
            -> minespace_cosmic
```

`nclegacy` 是 QMD 的前置；QMD 必须排在 NCO 之后。Minespace 整体排在最后，便于读取最终注册表。

---

## 4. 材料、矿石与流体统一矩阵

### 4.1 唯一归属规则

| 类别 | 例子 | 唯一归属 | 处理方式 |
| --- | --- | --- | --- |
| 通用结构金属 | 铁、铜、锡、铅、铝、钢、不锈钢、钛、钨、铬、铌 | GT/TJ | NCO/QMD 配方改用 GT 的 `ore:` / `dust` / `ingot`；不新建 `minespace` 材料 |
| 普通化工流体 | 硫酸、盐酸、硝酸、水、蒸汽、液氧、液氮、液氦、氩、氖 | GT/TJ | 用 GT 的化学反应釜、蒸馏塔、电解机、真空冷冻机生产；QMD 只做消耗端 |
| 裂变/增殖同位素 | U-233/235/238、Th-232、Pu-238/239/240/241、Np、Am、Cm、Bk、Cf | NCO | 保留 NCO 的同位素物品与衰变数据；GT 只通过 1:1 转换或 `ore:` 别名接入 |
| QMD 稳定元素粉末 | 钨、铌、铬、钛、铪、锇、铱、铂、钇、钕等 | GT/TJ | QMD 配方改用 GT 粉末；QMD 自己不保留重复粉末 |
| QMD 奇异物质 | 反物质、反氘、粒子束、等离子体、核合成中间体 | QMD | 保留 QMD 原生物品/流体；不映射成 GT 材料 |
| NCO 专属冷却剂/熔盐 | 熔盐燃料、液态燃料载体、NCO 特有冷却剂 | NCO | 只在没有 GT 等价物时保留 |

### 4.2 不允许重复矿脉

- 关闭 NCO 的全部世界生成矿脉，包括主世界、下界和所有行星维度。
- QMD 不新增矿脉；它的矿石浸出器只吃 GT 已有的矿石/粉碎矿。
- 不把 NCO/QMD 的矿石写进 `tools/planet-veins.psd1`。
- 如果某个核材料没有 GT 矿脉，优先做成现有矿脉的副产物，不新开一条“核矿脉”。

需要重点检查的现有矿脉：铀、钍、锂、硼、铍、锆、独居石、沥青铀矿。`tools/ore-registry.txt` 已经有这些名字的统一记录，接入后要继续保持“0 个未统一”。

### 4.3 物品与流体桥

只允许两类桥：

1. **同物质 1:1 转换**：例如 GT 铀粉 ↔ NCO 铀粉、GT 液氮 ↔ NCO 液氮。转换不产出额外材料，不改变数量。
2. **同位素身份转换**：NCO 的 U-235 / Pu-239 等与 GT 对应同位素之间 1:1 转换；转换只解决物品身份，不增加燃料热值。

禁止：

- 用一条配方把普通 GT 矿石直接变成 NCO 的高热值燃料；
- 用流体转换复制液氦、液氮、氘、氚；
- 让 QMD 的矿石浸出器把 GT 普通矿石变成三份粉末而绕过 GT 的粉碎/洗矿/离心链。

### 4.4 与现有统一审计的衔接

接入后把 NCO/QMD 的物品加入现有 `ore-registry.txt` / `recipe-demand.txt` 的审计口径：

- 所有 `ingot*` / `dust*` 名字仍然只有一个主要来源；
- NCO/QMD 的重复粉末、锭、板在 JEI 中隐藏或只保留转换配方；
- 新加的转换配方必须在 `crafttweaker.log` 中为 0 error；
- 不修改 `minespace` 命名空间下的任何已有注册名。

---

## 5. 配方迁移：把 NCO 的通用机器并进 GT

NCO 自带 `gtce_recipe_integration`，但已实测它在 TJ 上不可用：NCO 的 `BasicRecipeHandler.addGTCERecipes` 引用 `gregtech.api.recipes.ingredients.GTRecipeInput`，TJ 没有这个类，启动会在配方阶段抛 `NoClassDefFoundError`。因此：

- `gtce_recipe_integration_global` 必须保持 `false`；
- 通用处理器配方由 `minespace_core` 的 NCO 兼容桥复制到 TJ 的 `RecipeMap`；
- NCO 自己的处理器方块保留注册，用于 NCO 内部进度和成就，但不作为 GT 主线加工入口；
- 迁移完成的方块在工作台配方和 JEI 中隐藏。

### 5.1 迁移映射参考

下表的“目标”表示兼容桥复制到的 GT 机器，不是 NCO 配置里的开关。NCO 自带的对应开关必须保持关闭。

| NCO 处理器 | GT 目标机器 | 建议 |
| --- | --- | --- |
| Manufactory | 研磨机 / Macerator | 实测后二选一，避免和 Rock Crusher 重复 |
| Separator | 不迁移 | 保留 NCO 分离器；它是同位素/裂变燃料分离入口 |
| Decay Hastener | 无对应 GT 机器 | 保留 NCO 机器，不迁移 |
| Fuel Reprocessor | 无对应 GT 机器 | 保留 NCO 机器，不迁移 |
| Alloy Furnace | 合金炉 / Alloy Smelter | 开启 |
| Infuser | 化学反应釜 / Chemical Reactor | 开启，检查电路编号冲突 |
| Melter | 流体提取机 / Extractor | 开启 |
| Supercooler | 真空冷冻机 / Vacuum Freezer | 开启，之后隐藏 NCO 超级冷却机 |
| Electrolyzer | 电解机 / Electrolyzer | 开启 |
| Assembler | 组装机 / Assembler | 开启 |
| Ingot Former | 流体固化机 / Fluid Solidification | 开启 |
| Pressurizer | 卷板机 / Bender | 统一复制到卷板机 |
| Chemical Reactor | 化学反应釜 | 开启 |
| Salt Mixer | 混合机 / Mixer | 开启 |
| Crystallizer | 化学反应釜（电路 1） | 实测后决定，避免配方冲突 |
| Enricher | 化学反应釜（电路 2） | 实测后决定 |
| Extractor | 提取机 | 开启 |
| Centrifuge | 不迁移 | 保留 NCO 离心机；避免 GT 离心机绕过质谱仪 |
| Rock Crusher | 研磨机 | 建议开启，处理矿石；与 Manufactory 只留一个主入口 |
| Electric Furnace | 无对应 GT 映射 | 保留 NCO 机器，不作为主线 |

### 5.2 兼容桥

`src/main/java/com/minespace/unofficial/gtceu/nuclear/` 下新增两个类：

- `MinespaceNuclearMaterialsEvents`：不引用 NCO 类型，只在 `nuclearcraft` 与 `gregtech` 同时存在时调用兼容桥。
- `MinespaceNuclearMaterials`：读取 `NCRecipes.getHandlers()` 中已经完成注册的 `BasicRecipe`，把物品输入、流体输入、物品/流体输出、概率输出复制到 TJ 的 `RecipeMap`。

兼容桥在 `RegistryEvent.Register<IRecipe>` 的 `LOWEST` 优先级运行，确保 NCO 和 GT 自己的配方都已经注册。它使用 NCO 的 `processor_time` / `processor_power` 作为基础时间与功率，并按 `rf_per_eu=4` 换算 EU/t。

### 5.3 机器本身的处理

- `scripts/nuclear_gt.zs` 删除 15 个已经完成普通材料迁移的 NCO 通用处理器的工作台配方并从 JEI 隐藏：制造机、合金炉、灌注机、熔化机、超级冷却机、电解机、组装机、铸锭机、压机、化学反应釜、盐混合机、结晶器、富集机、提取机、碎岩机。
- 保留 NCO 的分离器和离心机；它们是同位素/裂变燃料分离机器，不复制到 GT 热离心机或离心机，避免绕过 QMD 质谱仪。
- 保留 NCO 的核熔炉、衰变加速器、燃料再处理机和电炉；它们没有等价的 GT 普通材料处理入口。
- 保留 NCO 的核专用多方块：裂变控制器、熔盐裂变、燃料再处理、辐照器、热交换器、涡轮、聚变反应堆、辐射洗涤器。
- QMD 的专用多方块全部保留；矿石浸出器、衰变室控制器、液化器控制器已改为 GT 组装机配方。

### 5.4 当前已落地

- 兼容桥实测复制 3293 条 NCO 普通材料处理配方到 TJ，0 条跳过；服务器加载 54 个 mod，`Done (2.134s)`，`crafttweaker.log` 0 error。
- 兼容桥不迁移 NCO 的 `separator` 和 `centrifuge`，因此 GT 热离心机/离心机不再拥有 NCO 的同位素与裂变燃料分离配方，QMD 质谱仪仍是 GT 侧的同位素分离入口。
- 加入兼容桥后的配方卫生检查：71965 条、73 个 recipe map、5 条可合并重复、0 组输入重叠，没有出现 NCO/GT 双份配方对撞。
- NCO 的 GTCE EU 支持已打开，处理器和核机器的能量端口可以接 GT 电网。
- `scripts/nuclear_gt.zs` 已撤掉 17 个通用处理器的配方和 JEI 显示。
- NCO 的裂变、熔盐裂变、聚变、热交换器、涡轮、辐照器、辐射洗涤器等多方块的注册和配方不动。
- `scripts/qmd_gt.zs` 已把 QMD 的矿石浸出器、衰变室控制器、液化器控制器改为 GT 组装机配方，去掉对 NCO `chemical_reactor`、`rock_crusher`、`supercooler` 的依赖，改用 GT 的 elite/master 电路、钨钢/不锈钢/钛板，不再使用 NCO 的 `plateElite`。
- 添加 QMD 脚本后专用服务器仍加载 54 个 mod，多次启动在约 2.0~2.1 秒到达 `Done`，`crafttweaker.log` 0 error。

---

## 6. 能源桥：NCO 走 EU，RF/EU 全阶段双向等效

### 6.1 NCO

NCO 原生支持 GTCE EU：

```text
enable_gtce_eu = true
rf_per_eu = 4
enable_ic2_eu = false
```

NCO 的裂变、聚变、涡轮和电池端口可以直接接 GT 电缆。这样不需要额外的 RF→EU 转换器，也不会绕开 GT 的电网。

建议：

- NCO 裂变/熔盐/聚变的能量端口统一按 GT 电压分级；
- NCO 电池方块按 GT 的 ULV/LV/MV/HV 容量映射；
- NCO 涡轮保留，因为它理解 NCO 的蒸汽/热交换体系；它的输出直接是 EU；
- 不额外造一个“NCO EU 转换机”，避免重复。

### 6.2 QMD

QMD 只有 RF，使用 GT 的 EU→FE 转换器供电。能源规则改为：

- **每个电压等级都同时保留 EU→FE 和 FE→EU 两个方向；**
- **双向统一按 4 FE = 1 EU 等效转换；**
- 转换器等级只限制功率吞吐，不限制“这个阶段能不能转换”；
- 不再保留“FE→EU 只到 HV”的阶段封顶；
- 如果转换器有内部损耗，所有等级使用同一个损耗系数，不做阶段差异。

这表示 RF 和 EU 是同一套能量的两种计量单位，而不是两套科技阶段。玩家在 EV 用 EV 级转换器、在 UV 用 UV 级转换器，区别只是能通过的功率大小，转换关系本身完全相同。

这条规则覆盖 `TJ-MIGRATION-PLAN.md` 6m 中“FE→EU 只到 HV”的旧规则。实施时要同步修改 `scripts/power.zs`：恢复所有等级的 FE→EU 转换器，保留 EU→FE 转换器，并把两个方向统一到 4:1。

按这个比例估算 QMD 的 GT 供电需求：

| QMD 设备/阶段 | RF 消耗 | 约合 EU/t | 对应 GT 阶段 |
| --- | ---: | ---: | --- |
| 液化器示例链 | 16.1 kRF/t | 约 4.0 kEU/t | IV/LuV |
| 第一套直线加速器 | 22 kRF/t | 约 5.5 kEU/t | LuV |
| 大型加速器/后期链 | 40 kRF/t | 约 10 kEU/t | LuV/ZPM |

这意味着 QMD 的电力门槛天然落在 IV~ZPM，适合作为 LuV 之后的支线，而不是 EV 阶段就能铺开的通用机器。注意这是**设备成本和吞吐量**造成的门槛，不是 RF→EU 转换被人为封住。

### 6.3 QMD 的净输出

QMD 的核合成/聚变可以净输出 RF。按照上面的等效规则：

- QMD 的 RF 可以在任何阶段通过同等级 FE→EU 转换器反哺 GT 电网；
- 不另做“QMD 专属 EU 转换机”，也不做 UV 级额外门槛；
- 转换器只限制最大吞吐，不能因为阶段不同而改变 4:1 的比例；
- 双向转换必须避免无损循环叠能：EU→FE→EU 回来仍是同一份 EU，不允许出现净增益；
- 如果以后发现某种循环利用转换器刷能量，修的是循环本身，不是把某个阶段的 FE→EU 删掉。

因此，QMD 的净输出是合法的 GT 电力来源，和 NCO 的 EU 输出一样参与同一张电网。它的平衡点在于机器成本、转换器吞吐和维护成本，而不在于阶段封顶。

---

## 7. 裂变、聚变与核合成的分工

### 7.1 NCO 裂变

- EV：固态燃料裂变入门，LEU/HEU 基础燃料，裂变辐照器，基础辐射防护。
- IV：燃料再处理、钚/镎/锕系、熔盐裂变、热交换器、NCO 涡轮，完整燃料循环。
- 裂变燃料的热值、辐射、临界值保持 NCO 原值；只通过配方门槛控制阶段，不靠改数值硬压。

### 7.2 NCO 聚变与 GT 聚变

| 系统 | 定位 | 阶段 | 规则 |
| --- | --- | --- | --- |
| GT 聚变 MK1 | 主聚变线，产 EU / 高级等离子体 | LuV | 必须先于 NCO 聚变 |
| GT 聚变 MK2 | 更高级等离子体与材料 | ZPM | 保持主线 |
| GT 聚变 MK3 | 终局等离子体 | UV | 保持主线 |
| NCO 聚变 | 中子源、氚/氦-3 增殖、同位素活化、辅助热 | LuV 以后 | 不产出 GT 等离子体，不替代 MK2/MK3 |

NCO 聚变控制器的配方要包含 GT 聚变 MK1 的组件或 LuV 电路，确保它出现时玩家已经进入 GT 聚变阶段。它的产物优先写成“中子通量/活化同位素/热量”，而不是直接给 GT 的高级聚变材料。

### 7.3 QMD 核合成

QMD 的核合成室可以用轻元素造重元素，甚至理论上从氢造任意元素。必须限制：

- 只保留超重元素、锕系、反物质、奇异物质和少量剧情材料；
- 删除铁、铜、锡、铅、钛、钨、铬等通用结构材料的核合成配方；
- 保留的配方需要 GT 后期电路、真空室组件、巨大 EU 和稀有粒子种子；
- 不能比行星采矿更便宜，否则所有矿脉都会失去意义。

### 7.4 质谱仪与矿石浸出器

- 质谱仪的通用四倍矿石配方全部移除；
- 只保留核燃料、稀土、铂族、铌钽等少量“需要同位素分离”的配方；
- 矿石浸出器只处理核相关矿石和 QMD 专属中间体，不处理普通铁/铜/锡/煤；
- 如果 QMD 的浸出器需要副产物，用 GT 粉碎矿/洗矿产物作为输入，输出 1:1 的主金属粉加少量核副产物。

---

## 8. 辐射、防护与环境

NCO 的辐射系统作为唯一辐射模型。QMD 的 HEV 和反物质只作为这个模型的使用者，不再另起一套辐射数值。

### 8.1 环境辐射

把现有天体的辐射字段接到 NCO 的辐射源：

| 天体类型 | 辐射表现 | 防护要求 |
| --- | --- | --- |
| 月球/火星/金星 | 低~中等环境辐射，随维度/生物群系变化 | NCO 防化服或 GT 对应防护 |
| 水星/强辐射卫星 | 较高环境辐射，需要屏蔽 | NCO 高级防化服 / GT 量子套装 |
| 脉冲星/黑洞/超新星遗迹 | 极高辐射，短时间暴露即危险 | 后期屏蔽、远程采集、无人设备 |
| QMD 加速器/反物质室 | 局部强辐射，泄漏时扩散 | NCO 辐射洗涤器、屏蔽方块、HEV |

### 8.2 防护装备

- NCO 防化服：EV/IV 的核工业标准防护。
- GT 量子套装/高级装甲：通过 NCO 的 `radiation_shielding_custom_stacks` 获得分级抗性，不做完全免疫。
- QMD HEV：ZPM 级专用防护，抗性接近但不要全面超过 GT 量子套装；它的优势是加速器环境下的便携供能。
- 反物质容器：泄漏、爆炸、伽马闪光保留；容器配方用 GT 后期材料。

### 8.3 冷却剂

- GT 负责通用液氧、液氮、液氦、氩、氖、硫酸、盐酸、硝酸；
- QMD 负责加速器专用的低温闭环和氦/氖液化链；
- NCO 超级冷却机在 GT 真空冷冻机迁移后隐藏；
- QMD 液化器保留，但输入/输出统一到 GT 流体；
- 所有冷却剂走闭环，不允许把液氦当普通水一样无限排放。

---

## 9. 阶段门槛与配方门槛

这里的“门槛”指机器控制器/关键组件的配方，不是星图研究数据。**研究数据只负责解锁旅行，不在 NCO/QMD 机器配方里消耗**，否则玩家做出机器后会失去星图权限。

| 阶段 | GT 门槛 | NCO 内容 | QMD 内容 | 关键配方要求 |
| --- | --- | --- | --- | --- |
| 3 / EV | EV 电路、不锈钢、化学反应釜、蒸馏塔 | 固态裂变控制器、基础辐照器 | 无 | 裂变控制器用 EV 电路 + 不锈钢 + GT 化学反应釜组件 |
| 4 / IV | IV 电路、钛、钨钢、GT 离心/电解 | 燃料再处理、熔盐裂变、NCO 涡轮、热交换器 | 阶段 0：空气分离、低温冷却、矿石浸出、NCO 辐照 | 燃料再处理控制器用 IV 电路 + 钛/钨钢 + GT 离心机组件 |
| 5 / LuV | LuV 电路、GT 聚变 MK1、高级超导 | NCO 聚变（中子源/同位素） | 阶段 1：直线加速器、靶室、P/N 掺杂硅 | 直线加速器控制器用 LuV 电路 + GT MK1 组件 + QMD 阶段 0 产物 |
| 5 / ZPM | ZPM 电路、BSCCO/GT 超导 | 高级锕系燃料 | 阶段 2：同步加速器、质谱仪、束流操控 | 同步加速器控制器用 ZPM 电路 + BSCCO/GT 超导 + 质谱仪组件 |
| 6 / UV | UV 电路、GT 聚变 MK3、UHV 材料前体 | 锎系/超重燃料 | 阶段 3：真空室、异常物质遏制、反物质、核合成 | 真空室控制器用 UV 电路 + GT MK3 组件 + 反物质容器 |
| 7 / UHV | UHV 电路、装配线 | 终局燃料与辐照 | QMD 规模化 | 只做扩产，不新增阶段 |
| 8 / UHV+ | UHV+ 电路 | 可选 | 可选 | 与戴森球/宇宙工程衔接，不抢主线 |

### 9.1 为什么 QMD 不放在 EV

QMD 的第一套直线加速器就要约 22 kRF/t，折合约 5.5 kEU/t；它的阶段 0 还需要 NCO 裂变、空气分离、低温冷却和矿石浸出。放到 EV 会让玩家在还没完成 GT 化工和聚变前置时就被迫铺大型加速器，节奏断裂。放在 IV 做基础设施、LuV 做第一台加速器，和现有天体阶段 4/5 的电压吻合。

这个阶段安排只限制 **QMD 机器本身的配方和结构门槛**，不限制 RF/EU 转换。只要玩家有对应吞吐量的转换器，任何阶段都可以把 RF 和 EU 按 4:1 互相转换。

### 9.2 为什么 NCO 裂变从 EV 开始

EV 是 GT 进入不锈钢、化学反应釜和基础自动化的阶段，也是玩家第一次有稳定电力处理铀矿和辐射防护的阶段。NCO 裂变从这里进入，既不会抢 LV/MV 的蒸汽主线，也能为 IV 的燃料循环和 QMD 阶段 0 提供热源与中子源。

---

## 10. 天体资源与物流

NCO/QMD 不新增天体，资源来源按现有星表分配：

| 资源 | 主要来源 | 用途 |
| --- | --- | --- |
| 铀、钍、沥青铀矿 | 水星、火星、金星、小行星带、部分卫星 | 裂变燃料、增殖、辐照 |
| 锂、硼、铍 | 蒸发岩/伟晶岩/盐类矿脉 | 中子屏蔽、控制棒、聚变燃料 |
| 钨、铌、钛、铬 | 月球、火星、金星、小行星带 | 加速器腔体、靶室、结构件 |
| 铂族、铱、锇 | 小行星带、金属核天体 | 高级加速器磁体、反物质容器 |
| 氦-3 | 气态巨行星大气采集 | QMD/聚变燃料 |
| 氘 | 海洋/冰卫星/水 | 聚变燃料 |
| 稀土、钇、钕 | 稀土矿脉、月球/火星 | 超导、激光、磁体 |

星图仍然只显示已研究天体；NCO/QMD 的机器不会自动显示未研究天体，也不会给未研究天体发资源。

---

## 11. 安装与验证顺序

### 11.1 文件

已实测可用组合：

```text
nuclearcraft-1.12.2-2o.9.7.jar
NCOLegacyLib-1.12.2-1.2.jar
QMD-1.12.2-1.6.1.jar
RoughlyEnoughIDs-2.3.1.jar
I18nUpdateMod-3.7.0-all.jar   (已下载，client-only)
```

QMD 1.6.1 在 NCO `2o.9.0` 上会因 `decay_pool_heat_source` 缺失而崩溃，因此实际必须使用 `2o.9.7`。REID 也是必需项：当前整合包在加入 NCO 后会超过 1.12.2 的 4096 方块 ID 上限。

### 11.2 安装步骤

1. 备份 `Minespace-unofficial-dev/mods`、`config`、`scripts` 和当前世界。
2. 安装 NCO `2o.9.7`、NCO Legacy Lib `1.2`、QMD `1.6.1`、REID `2.3.1`。
3. 启动一次生成 `config/nuclearcraft.cfg` 和 `config/qmd.cfg`。
4. 设置 `enable_gtce_eu=true`、`rf_per_eu=4`、`enable_ic2_eu=false`。
5. 设置 `gtce_recipe_integration_global=false`；NCO 自带迁移在 TJ 上不可用。
6. 关闭 NCO 的八种矿石世界生成：`ore_gen` 全设为 `false`。
7. 保留 NCO 的处理器、被动机械、电池和量子计算机注册；关掉它们会造成 NCO 内置进度 JSON 找不到物品。
8. 修改 `scripts/power.zs`：移除 EV 以上的 FE→EU 配方删除和 JEI 隐藏，恢复全阶段双向转换；保持 4:1。
9. 加入 `scripts/nuclear_gt.zs`、`scripts/qmd_gt.zs`，跑一遍完整启动。
10. 新建测试世界；旧世界只做冒烟测试，不作为主要验收环境。

### 11.3 加载顺序

- `gregtech` 先于 `nuclearcraft`，让 NCO 的 GTCE EU 接口能读到 GT 能量 API；
- `nuclearcraft` 先于 `nclegacy` 和 `qmd`；
- `minespace_core` 只写 `after:nuclearcraft;after:nclegacy;after:qmd`，不强制依赖；
- 四个 Minespace mod 之间的顺序保持不变。

---

## 12. 验收清单

### 12.1 启动与注册

- [x] 专用服务器加载 `nuclearcraft`、`nclegacy`、`qmd`、`jeid`，共 54 个 mod 并到达 `Done`。
- [x] `crafttweaker.log` 0 error。
- [x] 测试实例的旧世界在 REID + NCO + QMD 下仍能加载并到达 `Done`。
- [ ] 客户端 mod 列表与专用服务器一致，QMD 不需要客户端专属类。
- [ ] 没有 NCO/QMD 的缺失依赖、重复 mod、mixin 崩溃。

### 12.2 材料与矿脉

- [x] NCO 八种矿石的世界生成已在 `nuclearcraft.cfg` 中全部关闭。
- [ ] 行星矿脉仍然只有 GT 矿脉；采样区块中无 NCO 矿石方块。
- [ ] `ingot*` / `dust*` 统一审计仍然 0 个未统一。
- [ ] NCO/QMD 的重复粉末/锭在 JEI 中隐藏或有 1:1 转换。
- [ ] 没有新的 `minespace` 材料注册名。

### 12.3 配方

- [x] NCO 普通材料处理配方由 core 兼容桥复制到对应 GT 机器（3293 条，0 跳过）。
- [x] 15 个 NCO 普通材料处理器的配方和 JEI 显示已移除。
- [x] NCO 分离器/离心机不迁移，GT 热离心机/离心机不再绕过 QMD 质谱仪。
- [ ] QMD 控制器和结构方块只能从 GT 组装机/装配线获得。
- [x] QMD 矿石浸出器、衰变室控制器、液化器控制器已改为 GT 组装机配方。
- [ ] QMD 质谱仪/矿石浸出器不处理普通铁、铜、锡、煤。
- [ ] QMD 核合成不产出普通结构金属。
- [ ] 所有关键控制器在 JEI 中能看出电压门槛。

### 12.4 能源

- [ ] NCO 能量端口能接收 GT EU，也能向 GT 电缆输出 EU。
- [ ] `rf_per_eu=4` 与实际 EU 输出一致。
- [ ] QMD 加速器能由 GT EU→FE 转换器稳定供电。
- [ ] EU→FE 和 FE→EU 在每个电压等级都存在。
- [ ] 双向转换统一保持 4 FE = 1 EU，没有阶段差异。
- [ ] 转换器等级只影响吞吐量，不影响转换比例。
- [ ] QMD 净输出可以通过同等级 FE→EU 转换器反哺 GT 电网。
- [ ] EU→FE→EU 循环不会产生净增益。

### 12.5 辐射与环境

- [ ] 辐射行星会让玩家累积辐射值。
- [ ] NCO 防化服/GT 量子套装能分级降低辐射。
- [ ] QMD HEV 不会完全替代 GT 装甲。
- [ ] 裂变/聚变熔毁会产生辐射和爆炸。
- [ ] 辐射洗涤器、屏蔽方块、反物质遏制室工作正常。

### 12.6 性能

- [ ] 单台 QMD 直线加速器在测试世界可稳定运行。
- [ ] 多台液化器/加速器不会造成明显 TPS 下降。
- [ ] NCO 裂变/聚变多方块在服务器 tick 下无异常。
- [ ] 大型 QMD 结构不会因区块加载产生持续卡顿。

---

## 13. 需要你确认的设计选择

以下选择会实质改变整合难度，建议先定下来再安装：

1. **NCO 版本**：先稳定版 `2o.9.0`，还是直接上 `2o.9.7` beta？
2. **QMD 起点**：按本文 IV 做基础设施、LuV 第一台加速器；还是整体再往后压到 LuV/ZPM？
3. **NCO 聚变门槛**：是否同意“必须先有 GT 聚变 MK1，NCO 聚变只做中子源/同位素”？
4. **QMD 矿石处理**：是否同意移除质谱仪和浸出器的通用矿石配方，只保留核/稀有元素？
5. **RF/EU 转换**：是否按“每个阶段双向等效、统一 4:1、等级只限吞吐”执行？
6. **NCO 通用机器**：是否同意迁移配方后隐藏 NCO 的通用单方块处理器，只保留核专用多方块？

我的建议是：**1 选稳定版，2 按本文，3 同意，4 同意，5 同意全阶段双向等效，6 同意。** 这样 NCO 是 EV/IV 的核工业支线，QMD 是 LuV 以后的高能物理支线，两者都不会变成第二套 GT。

---

## 14. 兼容性导出与修复记录

已加入可重复导出器 `MinespaceDiagnostics`。以 `-Dminespace.exportDiagnostics=true` 启动专用服务器后，会在游戏目录生成：

- `items.csv` / `blocks.csv`
- `ore-dictionary.csv`
- `gt-recipes.csv`
- `nco-recipes.csv`
- `qmd-recipes.csv` / `qmd-basic-recipes.csv`

最近一次导出：32102 个物品、4756 个方块、36235 条矿物词典记录、65053 条 GT 配方、5279 条 NCO 配方、863 条 QMD 配方。

修复记录：

- NCO `separator` / `centrifuge` 不再复制到 GT 热离心机/离心机，QMD 质谱仪保留 GT 侧同位素入口。
- QMD 矿石浸出器移除 8 条普通矿石配方，质谱仪移除 8 条普通矿石配方。
- GT/NCO/QMD 稳定材料增加 re-point；16 条 GT 机器输出和 242 个合成输入槽改为 GT 物品。
- 缺失基础注册表引用为 0；资源闭包检查 0 个矿石缺口、0 个过晚材料。

完整报告与导出文件见 [docs/compat-2026-10-17/REPORT.md](docs/compat-2026-10-17/REPORT.md)。
