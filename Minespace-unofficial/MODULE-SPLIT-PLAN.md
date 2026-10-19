# Minespace 模块拆分设计（v0.4）

> 依据：《GTCEu 星系整合包详细实施方案》V1.0（2026-10-10）；基线：插件现状（2026-10-16 实测：单 jar `minespace-0.2.0.jar`、单 modid `minespace`、48 个 Java 文件 / 10613 行）。
>
> **范围**：只拆插件本体 `Minespace-unofficial/`。整合包侧的脚本、配置、实例与清单不参与划分；插件 `tools/` 下的数据管线属于插件项目，算在内。
>
> **已定**：① 打包仍是一个 jar，Forge 里显示多个 mod；② modid 用下划线写法；③ 存量注册名与资源命名空间一律不改；④ 遗迹不单独成模块，并进 `planets`。
>
> **沿革**：v0.1 的 9 个模块 → v0.2 的 5 个 → v0.4 的 4 个模块（v0.3 曾按"四个 jar"设计，已作废）。

## 零、形态：一个工程、一个 jar、Forge 里四条记录

**一个 jar 里多个 `@Mod` 类就是多个 Forge mod，这是 Forge 原生支持的**，不需要合并工具、不需要额外插件。证据就在本机实例里：

- `mods/` 里只有一个 `Galacticraft-1.12.2-4.0.7.jar`；
- 它的 `mcmod.info` 只声明了一条 `galacticraftcore`；
- 但这次运行的 mod 列表里三条都在：`micdoodlecore`、`galacticraftcore`、`galacticraftplanets`（`logs/latest.log` 的 mod 列表那一行），全项目 48 个 mod。

所以拆分的落地形状是：

```
Minespace-unofficial/                       <- 一个 Gradle 工程，打包仍是一个 jar
├─ settings.gradle / build.gradle           <- 基本不动
└─ src/main/
   ├─ java/com/minespace/unofficial/
   │  ├─ Minespace.java  api/  gtceu/  galacticraft/  mixin/  proxy/   -> minespace_core
   │  ├─ navigation/   (新包；今天星图那几件搬进来)                      -> minespace_navigation
   │  ├─ planets/      (新包；天体数据面搬进来，之后加 ruins/)           -> minespace_planets
   │  └─ cosmic/       (新包；阶段五)                                  -> minespace_cosmic
   └─ resources/assets/minespace/**          <- 原地不动（见第五节的命名空间硬规则）
```

多条 mod 记录带来的实际能力：日志按模块归属（`[minespace_planets]` 一眼看出是谁）、模块自检、源码边界清楚、外部模组依赖收敛。**没有**的一条：不能单独关闭某个模块——一个 jar 就是全部，这条在 v0.3 里写错了。

**不采用 Gradle 子项目 + 合并 jar**：输出已经是一个 jar，分模块要的是边界与归属，不是四个 classpath；子项目多出来的是一套构建配置和一步合并（还要处理 `mcmod.info` 数组与 manifest 属性）。留下升级路径：哪天想要编译期强制隔离，把这四个目录升成 Gradle 子项目、加一个合并任务即可，源码布局一行不用动。

## 一、参照系：Galacticraft 只用了四个模块

同一份证据还说明：模块在**源码**上分开，**打包**可以是一个 jar，而每个模块的**资源命名空间**与 **modid** 一直保留——`assets/galacticraftcore/` 与 `assets/galacticraftplanets/` 在同一个 jar 里并存。

| 模块 | 职责 |
| --- | --- |
| Galacticraft-API | 公共契约：天体注册、能量接口、事件 |
| Galacticraft-Core | 基座：机器、火箭、发射台、氧气系统、月球与空间站 |
| Galacticraft-Planets | 内容：火星、金星、小行星带及其岩石、矿脉、机器 |
| Micdungeons（并进 Planets 发布） | 跨星球的地牢内容——地牢不属于某一颗星球，但也没单独出一个 jar |

三条规则可以直接借：

1. **API 与实现分离**——但"分离"不等于"单独一个 jar"，也不等于"单独一个 Gradle 工程"。
2. **按"能不能独立生长"分模块，不按代码分工分**——一个模块 = 一条能独立生长、独立验收的内容线。
3. **依赖是树，不是网**——模块只依赖自己下面那层，跨模块调用走 core 里的公共包。

## 二、模块总览：4 个

| 模块（modid） | 源码目录 | 一句话职责 | 依赖 | 现有代码 |
| --- | --- | --- | --- | --- |
| `minespace_core` | 现存的 `gtceu/`、`galacticraft/`、`mixin/`、`proxy/`、`api/` + `Minespace.java` | 入口与加载契约、网络、配置、天体登记机制与注册表、GT 材料与石材与矿脉与维度地形、本包机器、与其它模组的对接和配方收口 | - | ~7514 行 |
| `minespace_planets` | `planets/` | 106 个天体的数据与呈现（目录表、矿脉表、岩石与维度条目、生物群系、环境伤害、气态采集、图标与名称），以及六档遗迹 | core | 数据面 |
| `minespace_navigation` | `navigation/` | 3D 星图、航道与燃料、发射平台、火箭等级桥接 | core, planets | ~3099 行 |
| `minespace_cosmic` | `cosmic/` | 阶段五的全部系统：行星研究、时间观测仪、宇宙模拟器、戴森球、超光速与星系门、创世引擎 | core, planets, navigation | 0（全新） |

```
minespace_core
 └─ minespace_planets          （遗迹在它的 ruins/ 包里）
      └─ minespace_navigation
           └─ minespace_cosmic
```

**为什么不是 9 个**（v0.1 砍掉的部分）：

- **API 不单独成模块**：独立 API 的价值是"有第三方要编译你的接口"。现在没有第三方，一个包 `com.minespace.unofficial.api` 就够；真要有人写附属模组，把那个包抽出去是小事。
- **机制与对接合成 core**：GT 材料/石材/矿脉/维度地形，和与 GC/AE2/EIO/林业 的对接与配方收口，成长方式完全一样——跟着别的模组的版本与配方走。这两块本来就是同一段 preInit/postInit 时序，拆开只会把时序契约切成两半。
- **研究与宇宙工程合成 cosmic**：共用同一把钥匙（研究数据物品），研究就是宇宙工程那条线的入口。内部按包分（`research/`、`observation/`、`dyson/`、`ftl/`）——包是免费的，模块不是。
- **遗迹并进 planets**：遗迹要落在天体上、跟着天体的分档与地质走，共用同一套天体数据与模板生产线，也没有独立的经济模型（对比 GC 的 Micdungeons 最终也是并进 Planets 发布）。

## 三、每个模块的功能

### 1. `minespace_core` —— 基座

今天已有的绝大部分代码住这里（约 7514 行 = 全项目的 71%）。三块职责：

**a. 基座本身**

- 入口与加载顺序契约：`Minespace.java` 的 `dependencies` 字符串，以及 preInit / init / postInit / loadComplete 的调用时序——全项目最容易出事的地方，只有一处。
- 代理、日志、配置、`ModPresence`、网络通道（`MinespaceNetwork`）。
- **公共契约包** `com.minespace.unofficial.api`：天体数据模型、星球设计表与矿脉变体的 schema、`IBodyRegistry`、`IResearchGate`、`IEnergyBridge`、`IProgressionLedger`——其它模块唯一被允许编译的接口面。
- **共享账本**：研究数据 I~VI 物品族、图鉴与里程碑（M1~M10）挂接点、"哪一级数据开哪一层"的关卡表。放 core 是因为 navigation 要读它当关卡、cosmic 要产出它。
- **模块自检**：启动时打印每个已装模块的 id 与版本。

**b. 格雷地质与维度机制**（只放机制，不放天体数据）

- GT 材料定义与生成（`MinespaceMaterials`）。
- 石材体系（`MinespaceStoneTypes`、`MinespacePlanetStoneTypes`、`MinespaceGalaxySpaceStones`）。
- 岩石方块类（`MinespacePlanetRocks`、`MinespaceMoonRock`、`MinespaceGalaxySpaceRocks`）——类在这里，"哪颗天体用哪块岩石、注册名叫什么"由 planets 给。
- 矿脉注入（`MinespacePlanetOreGen`：补上 `GameRegistry.generateWorld` 那一步）与矿脉表的读取校验。
- 维度注册机制与共享 provider、地形原型（`MinespacePlanetDimensionsRegistration`、`MinespacePlanetTerrainPrototype`）。
- 世界生成收口（`MinespaceVanillaWorldgen`：关掉原版花岗岩/闪长岩/安山岩斑块）。
- 本包的 GT 机器：氧气压缩机、火箭燃料装填机（`machines/*`）。
- mixin：`MixinBlockBasicMoon/Mars/Venus`、`MixinMetaTileEntityOnRemoval`。
- 数据管线：`tools/gen-planet-dimension-table.ps1`、`build-planet-veins.ps1`、`accept-planet-veins.ps1`。

**c. 对接与配方收口**（唯一允许直接 import GC / GS / AE2 / Ender IO / Forestry / PlanetProgression 的地方——navigation 对 GC 与 PP 有例外，见第七节）

- 对接：GC/GS/AsmodeusCore/PlanetProgression 薄封装（`MinespaceGalacticraft`）、EU ↔ gJ 能量桥、本包天体注册进 GC 星系表（`MinespaceCelestialRegistry`）、GC 石材命名空间规避（`MinespaceGalacticraftStones`）、GS 天体的 GT 侧登记（`MinespaceGalaxySpacePlanets`）。
- 配方收口：GC 机器配方清退（`MinespaceGalacticraftMachineRecipes`）、材料归一与配方重指向（`MinespaceMaterialRepoint`）、压板只留一条来源（`MinespaceCompressedPlateGuard`）、AE2 磨粉机并入 GT 研磨机（`MinespaceGrinderToMacerator`）、"合成台不是压缩机"（`MinespaceCraftingBlocks`）、配方去重与常驻卫生检查（`MinespaceRecipeDedupe`、`MinespaceRecipeHygiene`）。
- 第三方模组改造：Ender IO 流体认领（`MinespaceEioFluids`）、林业木工机与管路（`MinespaceForestryCarpenter`、`MinespaceForestryTubes`）。
- 度量工具：`tools/audit-eio-bypass.ps1`、`ore-registry.txt`、`ore-vocabulary.txt`、`recipe-demand.txt`。

### 2. `minespace_planets` —— 天体与遗迹

只放数据与呈现，不放机制。它是实施方案三条模板化生产线里的两条（星球设计表、矿脉变体）加第三条（遗迹模板）。

**a. 天体数据**

- **天体表与注册**：106 天体的维度 id、层、所属恒星系、可达性。**实测修正（第十一节）：表本身留在 core**——它被石材类型、维度注册、天体注册三处在 core 的 preInit 期间读取，而 core 的 preInit 早于本模块，所以本模块读不到它。本模块拿到的是"注册时机在全部 preInit 之后"的内容。
- **太阳系（20 天体，阶段 0~3）**：12 个可登陆天体的地质设定卡、矿脉表、岩石与维度条目、天空与图鉴条目。
- **深空（86 天体，阶段 4~8）**：区域 + 分层 delta + 特征矿脉的三段式组合（6cx / 6dg 定下的方案），逐层只增"这一层才有"的矿脉。
- **数据管线**：`tools/planet-catalog.psd1` + `planet-catalog.csv` + `build-planet-catalog.ps1`（NASA 来源的现实参数）；`tools/planet-veins.psd1` + `build-planet-veins.ps1` + `accept-planet-veins.ps1`（矿脉表）。
- **呈现资产**：`build-celestial-art.ps1`（按天体类型的图标）、`build-celestial-lang.ps1`（中英文名）。
- **环境参数**：大气与气压、温度、辐射、重力 → 环境伤害的数据面与它的 tick 处理。
- **生物群系**：阶段四"每颗系外行星 2~4 个"。
- **气态行星采集**（阶段五子模块 2）：轨道维度与大气维度的定义、浮空采集平台、轨道采集器、气体分离与提纯厂——它天生绑定某类天体的维度定义，所以留在本模块。

**b. 遗迹与考古**（`ruins/` 包，阶段三/六）

- **六档遗迹**：0 级、I 型、II 型（戴森球残骸）、III 型、IV 型、未知。
- **结构注入管线**：`PopulateChunkEvent.Post` 注入（不动地形生成器）；与 Recurrent Complex 对接。
- **遗迹奖励与联动**：剧情碎片、科技蓝图、模拟数据、蓝图碎片（M4"他们来过"的解锁物）；达到对应研究进度才解析得开。
- **遗迹模板生产线**：模板 → 按层/档批量出表。

缺少它（把它的 `@Mod` 记录与源码从构建里拿掉）：星图上还有天体，但每颗都是空壳——没矿石、没岩石、没名字、没危害、没有可探索的遗迹。

### 3. `minespace_navigation` —— 星图与航行

- **3D 星图**：无人深空式的界面——`MinespaceStarMapScreen`（2587 行，今天最大的一件）、`MinespaceStarMapKey`（J 键入口，与界面分离）；悬停卡片、平移、把滚轮当相机、轨道运动、真实比例与可看比例两套视图。
- **关卡与呈现**：未勘测的天体不上图（`MinespacePlanetResearch`——GC 已知的天体交给 PlanetProgression 的勘探，本包自有天体用 core 里那把研究数据钥匙）。
- **发射流程接管**：GC 的火箭逻辑照旧，瞄准用本包的图（`MixinEntityTieredRocket`、`MinespaceRocketTarget`、`MinespaceRocketDestinations`）。
- **天空盒反馈**：`MinespacePlanetSkyRegistry`（当前停用，等星图重做后回归）。
- **航道与燃料经济**：航道由研究数据解锁，跨星系飞行有真实的燃料账。
- **发射基建**（阶段四）：高级发射平台、火箭组装厂、轨道发射轨道的多方块，以及 Tier 11+ 火箭对 GC 等级上限的桥接。

本模块搬过来的现有类（7 个）：`MinespaceStarMapScreen`（2587 行）、`MinespaceStarMapKey`、`MinespaceRocketTarget`、`MinespaceRocketDestinations`、`MinespaceNetwork`（星图的收发协议本来就是它的，core 只是代为注册过）、`MinespacePlanetSkyRegistry`，以及 mixin `MixinEntityTieredRocket` —— 它放在 `navigation/mixin/` 子包里，理由见第五节。

`MinespacePlanetResearch` **留在 core**（这一条与 v0.4 的猜测不同）：core 的天体注册表要用它，`MinespaceCelestialRegistry` 调它两次来决定一颗天体归 PlanetProgression 还是归本包。它是一项被两侧共用的关卡策略，不是星图的私有代码。

### 4. `minespace_cosmic` —— 宇宙工程（阶段五）

内部按四个包分（`research/`、`observation/`、`dyson/`、`ftl/`）：

- **行星研究**：射电望远镜阵列 → 天文数据分析仪 → 深空探测器控制中心 → 理论物理研究站（实施方案表 4-2）；研究数据的产出逻辑在这里（物品族与关卡表在 core）。硬约束：未完成研究就造不出跨星系火箭。
- **时间观测仪**：UV 阶段多方块；消耗时间晶体与巨量 EU，锁定已消失天体进入观测维度；产出观测记录、模拟数据与极少量稳定样本，普通样本带回即衰变。
- **宇宙模拟器**：UHV 阶段多方块；输入观测数据与巨量 EU，输出暗物质粒子、时空晶体、宇宙弦片段、熵减核心——与时间观测仪构成一进一出的循环。
- **戴森球**：云 / 环 / 球三阶段，五类恒星差异化参数，耀斑与发射失败等风险事件，天空盒与星图进度反馈，能量并入玩家电网。
- **超光速与宇宙尺度工程**：星际跳跃 / 曲速折叠 / 星系门三级，以及星系引擎、宇宙弦、维度锚、熵逆转器、宇宙之网逐个立项（M8）。
- **创世引擎与超星系戴森结构**：M9、M10 的载体。

## 四、什么才够格单独成一个模块

四条同时满足才算：

1. 有自己的内容生产线（数据源 + 生成脚本 + 验收清单），能独立生长；
2. **各条内容线彼此不互相依赖**——去掉一条，其余照常工作；
3. 有明确的对外面（core 公共包里 1~2 个接口），别人不需要读它的内部细节；
4. 有独立的验收节点（能对上实施方案的阶段验收）。

按这四条，下面这些**不该**拆：mixin 单独成模块；每颗天体一个模块；遗迹单独成模块（已定：进 planets）；`tools/` 里的脚本成模块；把 cosmic 的四个系统各拆一个（包足够）。

## 五、落地机制

**一个 jar，四条 mod 记录**：

- **四个 `@Mod` 类**：`Minespace.java` 留给 core，另外三个模块各写一个（id / name / version / dependencies / 自己的注册回调）。FML 扫到四个 `@Mod` 就建四个 mod 容器——mod 列表与日志里就是四条。
- **依赖用 `required-after`**：`minespace_planets` 写 `required-after:minespace_core`，这样 core 的 preInit 一定先跑（`after:` 只保证顺序、不保证存在，这里两个模块是同一个 jar，用 `required-after`）。对 GC / GS / PP 仍是 `after:` 软依赖——今天 `Minespace` 已经是这个写法。
- **版本**：四条记录共用整合包版本号（从 `0.3.0` 起）。
- **`mcmod.info`**：一个 JSON 数组写四条（一条一个 modid）。FML 按 modid 匹配；写了四条就必须真有四个 `@Mod`，否则 mod 列表里会多出空条目。
- **mixin 按模块分配置**：`mixins.minespace.json`（core 的四个）与 `mixins.minespace.navigation.json`（navigation 的一个）；MixinBooter 从 manifest 的 `MixinConfigs` 读逗号分隔的列表，两条都加载（已在本机验证：mixinbooter.log 里两条 `Preparing config` 与五条 `APPLY` 审计行）。
- **配置里的 `package` 是"被 Mixin 所有的包"**：该包下不允许有普通类，否则连 `@Mod` 类都加载不了。第一次搬运就是这样崩的——mixin 和 `MinespaceNavigation` 同住 `com.minespace.unofficial.navigation`，启动直接 `IllegalClassLoadError: com.minespace.unofficial.navigation.MinespaceNavigation is in a defined mixin package ... and cannot be referenced directly`。所以每个模块的 mixin 有自己的子包：`com.minespace.unofficial.mixin`、`com.minespace.unofficial.navigation.mixin`。
- **每个模块有自己的横幅**：`assets/minespace_<module>/logo.png`，由 `tools/make-logo.py --all` 生成（同一套背景、星场、边框与打光，只换主色、徽记与三行文字），`mcmod.info` 的 `logoFile` 指向各自那份。另有一个**实测结论**：Forge 1.12.2 的 mod 列表其实不读 `logoFile`——`GuiModList#updateCache` 的字节码走的是 `FMLClientHandler.getResourcePackFor(modId).getPackImage()`，即资源包的 `pack.png`；而 `logoFile` 只在"该 mod 没有资源包"时才会用到，且那条分支是拿 Forge 自己那个类去 `getResourceAsStream`，对 jar 形态的 mod 永远找不到。本包的 mod 列表之所以一直没图，就是因为 jar 里没有 `pack.png`（整个实例 25 个 jar 里一个都没有）。一个 jar 就是一个资源包，所以四条记录共享同一张 `pack.png`（现在放的是伞标），每模块的横幅是各自资源域里的真资产。
- **打包与部署不变**：一次 `build` 一个 jar，`deployToInstance` 照旧拷一个进实例。

**命名空间硬规则（已定：存量注册名不改）**：

- 注册名、贴图域、语言键、GT 材料命名空间、网络通道名，凡是今天用 `minespace` 的**全部冻结在 `minespace`**，不跟着 modid 走。
- 这意味着代码里要把"内容命名空间"与"modid"分成两个常量：今天 `Minespace.MOD_ID`（`"minespace"`）被当成命名空间用了约 20 处（`new ResourceLocation(MOD_ID, ...)`、`assets/minespace/textures/...`、`setUnlocalizedName(MOD_ID + ".…")`、`MinespaceMaterials.NAMESPACE`、`MinespaceNetwork` 的通道名），这些点换成冻结常量，新的 modid 只用在 `@Mod` 上。
- 新内容才用新命名空间（`minespace_planets:` 之类）；已有资源继续留在 `assets/minespace/` 原地不动。
- **modid 改名的两处真实代价（已核实）**：① `config/minespace.cfg` 会变成 `config/minespace_core.cfg`（内容是两条 worldgen 列表，现值就是默认值，代价≈0，但要知道这件事）；② 每一处 `@Mod.EventBusSubscriber(modid = "...")` 的字符串必须改成对应模块的真实 modid，改错的话事件处理器会静默不注册——这是这次改动里最容易踩的一处。

**模块边界守卫**：已落地为 Gradle 任务 `checkModuleBoundaries`（build.gradle），随 `deployToInstance` 与 `check` 一起跑。

- 规则：每个模块一组源码目录 + 两张禁入表。`denyExternals` 是它不该认识的外部模组；`denyModules` 是它不该引用的同级模块（依赖图 `core → planets → navigation → cosmic`）。core 是整合层，可以 import 任何外部模组，但不许 import 同级模块——图的箭头是反的。
- 另有一条来自真实崩溃的规则（见第五节）：**mixin 只能待在 mixin 包里**，包外的代码不许 import `org.spongepowered.asm.mixin.*`。
- 行为：报告违反项（模块、文件、行号、被越界的包）并让构建失败。它照着 `MinespaceRecipeHygiene` 的风格只报告不改写；规则按当前源码校准过，所以失败意味着真的有人越了线。

## 六、拆分顺序与验收

三步，每步结束时实例都能跑、都能验收：

1. **骨架**：建三个新包与三个新 `@Mod` 类（注册回调先留空），`mcmod.info` 写四条，跑一次启动。
   验收：`logs/latest.log` 的 mod 列表里出现四条 Minespace 记录；`crafttweaker.log` 零错误。
2. **搬 navigation，再搬 planets 的数据面**：先搬那 7 个类（星图能开、能截图为证，`tools/capture-starmap.ps1` 现成），再把天体表、图标与名称的生成物搬进 planets。
   验收：矿脉表、资源闭环检查表、天体图标的生成结果与拆分前逐字节一致；星图截图与拆分前一致。
3. **停用测试**：把 `minespace_planets` 的 `@Mod` 与源码从构建里去掉，再打一次包并启动。
   验收：游戏照常起来，日志明确说出少了哪条内容线；恢复后一切照旧。

`cosmic` 在阶段五建模块——新代码直接进新模块，不需要迁移，也不需要先建空壳。

## 七、代价与红线

收益：日志与 mod 列表按模块归属；源码边界清楚；外部模组依赖收敛（AE2/EIO/林业 的引用只会出现在 core）；改一处不牵动全树。

代价：

- 没有编译期强制隔离——边界靠上面那个守卫检查与分层规则，不像 Gradle 子项目那样编译器直接拦（升级路径留在第零节）。
- 一个 jar 不能再"只装一部分模块"。
- `MOD_ID` 与内容命名空间要拆成两个常量（约 20 处，机械替换，但必须一次做对）。

红线：

- **存量注册名与资源命名空间不改**（已定），否则 `Minespace-unofficial-dev/world` 里的对应方块会丢。
- 不引入服务加载器或反射式插件系统——模块依赖写死在 `@Mod` 里。
- 只管插件本体：整合包侧的脚本、配置、实例与清单不参与划分。
- 不拆 mixin：跟着它修的东西走（GC 的发射流程 → navigation，GT 的崩溃修复 → core）。
- 临时探针不新开模块，放在所属模块的 `probe` 包，用完删除。

## 八、下一步

1. 建四个模块的骨架（三个新 `@Mod` + `mcmod.info` 四条 + 冻结命名空间常量），启动一次看 mod 列表里是不是四条。
2. 搬 navigation 的 7 个类与 planets 的数据面，各验收一次。
3. 之后所有新内容填进对应模块；`cosmic` 到阶段五再建。

## 九、第一步已完成（2026-10-16 实测）

**已落地**

- 新文件：`MinespaceContent`（冻结的内容命名空间）、`MinespaceModules`（四个 modid + 启动自检）、`planets/`、`navigation/`、`cosmic/` 三个新包与三个 `@Mod` 类。
- 核心 modid 从 `minespace` 改为 `minespace_core`；`mcmod.info` 写四条；内容命名空间仍冻结在 `minespace`（20 处已核对的替换点，其中 4 处 `@Mod.EventBusSubscriber` 正确地跟着 modid 走）。
- jar 名与部署路径不变（`minespace-0.2.0.jar`），版本暂不升——否则实例里会同时留下旧 jar 与新 jar，同名 mod 的两份容器会让启动直接失败。

**证据**（scratch 运行 `D:\minespace-capture-run`，与改动前的 `logs\2026-10-16-7.log.gz` 逐项对照）

| 检查项 | 结果 |
| --- | --- |
| Forge mod 列表 | 四条：`minespace_cosmic`、`minespace_core`、`minespace_navigation`、`minespace_planets`（基线是一条 `minespace`） |
| 启动日志 | 四条 preInit 行 + loadComplete 的模块自检四行（`module minespace_planets (Minespace Planets v0.2.0) - ...`） |
| 载入总数 | `Forge Mod Loader has successfully loaded 50 mods` |
| 注册名 | 未变：`minespace:oxygen_compressor`、`minespace:rocket_fuel_loader`、`minespace:mars_rock`、`minespace:venus_rock`、`minespace:asteroid_rock`；石种 `moon_stone`(16)、`mars_stone`(17)、`venus_stone`(18)、`asteroid_stone`(19) |
| crafttweaker.log | 零 ERROR（与基线相同），脚本名集合与基线逐个一致 |
| 服务器 | `Done (1.966s)!` |

**实测代价**（都在预期内，且都不影响游戏内容）

- WARN 5328 → 5356。其中 24 条是 FML 的 `Potentially Dangerous alternative prefix 'minespace' for name ... expected 'minespace_core'`——冻结的命名空间与改名后的 modid 并存，必然出现；注册名本身不受影响。其余几条只是 logger 名从 `minespace` 变成 `minespace_core`，同一行的内容变化。
- ERROR 40 → 41。唯一新增的是 `[FML.ModTracker]: This world was saved with mod minespace which appears to be missing`。世界是按注册名找方块的，注册名没变，所以它只是一条提示，会在旧世界上出现一次。
- `config/minespace.cfg` 旁新增 `config/minespace_core.cfg`（Forge 按 modid 命名配置文件）。新文件里的 `disabledVanillaGenerators` 仍是 GRANITE/DIORITE/ANDESITE，与旧文件的有效值一致；旧文件里多出的 `disabledOreGenTypes` 早在更早一轮就从代码里删掉了，所以两份文件的有效配置相同。

**遗留的可选整理**：约 20 处 `LogManager.getLogger("minespace")` 仍用旧名，日志里会出现 `[minespace]` 与 `[minespace_core]` 并存。这是纯机械替换，跟着"搬 navigation"那一步一起做即可。

## 十、第二步已完成：navigation 搬完（2026-10-16 实测）

**动的东西**

- 7 个类搬进 `com.minespace.unofficial.navigation`：星图屏幕与按键、火箭瞄准与目的地、星图协议（`MinespaceNetwork`）、天体天空注册、以及 mixin `MixinEntityTieredRocket`（放 `navigation/mixin/`）。
- navigation 有了自己的成对代理：`navigation/CommonProxy`（注册协议）与 `navigation/client/NavigationClientProxy`（注册按键，唯一接触客户端代码的类）。core 的 `ClientProxy` / `CommonProxy` 因此不再知道星图存在。
- 18 个 logger 从 `"minespace"` 改成 `"minespace_core"`（15 个）或 `"minespace_navigation"`（3 个）。
- `mixins.minespace.navigation.json` 新增；manifest 的 `MixinConfigs` 变成逗号分隔的两条。
- 全仓库对已搬走类旧 FQN 的残留引用：0 处。

**证据**（scratch 运行，与只改名的上一轮 `logs\2026-10-16-6.log.gz` 对照）

| 检查项 | 结果 |
| --- | --- |
| WARN / ERROR / alt-prefix | 两轮完全相同：5356 / 41 / 5291（唯一差异是 GregTech 配方报错里的对象哈希，以及一条随机的 "Can't keep up!" 计时警告） |
| mixin 审计 | 5 条 APPLY 全在；`MixinEntityTieredRocket` 现在来自 `mixins.minespace.navigation.json`，目标 `EntityTieredRocket` 不变 |
| mod 列表 | 四条不变；四条 preInit 行与自检四行都在 |
| logger 归属 | `[minespace_core]` 205 行、`[minespace_navigation]` 1 行、planets / cosmic 各 1 行；剩下的 8 条裸 `[minespace]` 是 KubeJS 启动脚本自己打印的文本，不是 logger |
| 注册名 | 未变：`minespace:oxygen_compressor`、`minespace:rocket_fuel_loader`、`minespace:mars_rock` / `venus_rock` / `asteroid_rock` |
| crafttweaker.log | 零 ERROR（887 行，与上一轮相同） |
| 服务器 | `Done (2.024s)!`，并且这次是收到 `stop` 干净停机的 |

**踩到并记住的一条**（已写进第五节）：mixin 配置的 `package` 是 Mixin 所有的包，包内不能有普通类——把 mixin 和 `@Mod` 类放在同一个包里会让启动直接失败。

## 十一、第三步的结论：planets 今天搬不走任何东西（2026-10-16 实测）

第三步原计划把天体表和天文/矿脉数据面搬进 `planets`。把依赖图量清楚之后，结论是**这一步的前提不成立**，原因正是项目自己踩过的那条"石材时机规则"：

1. 本包**所有**石材类型（月球、火星、金星、小行星带、17 个 Galaxy Space 天体、以及地形原型）都注册在 `MinespaceMaterials.onMaterialsInit()` 里，因为它必须落在 GT 的 `runMaterialHandlers()` 与 `MetaBlocks.init()` 之间——晚一步不是"贴图不对"，而是每条碰到那种岩石的矿脉都抛 NPE（见 `MinespaceStoneTypes` 的类注释）。
2. 那个窗口在 GregTech 的 preInit 里，而本包是在 **core 的 preInit** 期间到达它（core 是 `required-after:gregtech`）。
3. 天体表被这些石材类型读，也被维度注册（`MinespacePlanetDimensionsRegistration`）和天体注册（`MinespaceCelestialRegistry`）读——三处都在 core 的 preInit 期间。地形原型更进一步：它自己就注册一个石材类型。
4. FML 的加载顺序是 core 先、planets 后（planets 是 `required-after:minespace_core`），所以 planets 的 preInit 无论如何读不到那张表，也来不及注册石材类型。

把表或原型搬过去只有两条路：让 core 反向依赖 planets，或把这些注册挪出唯一可行的窗口。两条都不能要。**所以表和机制留在 core，planets 接的是"注册时机在全部 preInit 之后"的内容**——逐天体地形、生物群系、环境伤害、矿脉与遗迹，也就是阶段二到阶段六的工作。这一步省掉的是一次会用错方式完成的搬迁。

**这一步真正交付的：停用测试**（第三节"内容层"的验收项，也验证了模块边界成立）

做法：把 `planets/MinespacePlanets.java` 移出源码树 → `--offline build` → 用 scratch 目录启动。

| 检查项 | 结果 |
| --- | --- |
| mod 列表 | 只剩三条：`minespace_cosmic`、`minespace_core`、`minespace_navigation` |
| 载入总数 | 50 → 49 |
| 模块自检 | `module minespace_planets (Minespace Planets vabsent) - the celestial bodies, ...` —— 日志明确说出了少的是哪条内容线 |
| 服务器 | `Done (1.998s)!`，游戏本身完全可用 |
| mcmod.info 里多出的那条 | 没有造成任何报错（FML 会忽略没有对应 `@Mod` 的元数据） |

随后把文件放回、重新构建并复测：四条记录回来了、50 个 mod、`Done`、`crafttweaker.log` 零错误、WARN 5356（与搬动前一致）。

**顺带发现的一条小事**：四条 mod 各有自己的资源命名空间，而语言文件只有 `assets/minespace/lang/` 一份，于是 FML 每个启动都会念三行 `Missing English translation for minespace_core/...`。纯提示、不影响任何内容；要消掉的话，给每个模块加一个空的小 lang 文件即可（留给下一步）。

## 十二、收尾（2026-10-16 实测）

**一、模块边界守卫已落地并在拦人**

`build.gradle` 里的 `checkModuleBoundaries` 任务：把每个模块的源码目录读一遍，按两张禁入表报告越界，违反就失败构建。它随 `deployToInstance` 和 `check` 一起跑。

验证不是"跑通就算"——先证明它会拦：临时给 `planets/MinespacePlanets.java` 加一行 `import micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry;`，任务立刻报

```
checkModuleBoundaries: 1 violation(s) in 55 files
    planets: MinespacePlanets.java:4 imports micdoodle8 - micdoodle8.mods.galacticraft.api.galaxies.GalaxyRegistry
FAILURE: Build failed with an exception.
```

撤掉探针后是 `checkModuleBoundaries: 55 files checked, no violations`，随后整条 `deployToInstance` 正常通过。

**二、四条翻译提示已消掉**

先量了一下：那条 `Missing English translation` 是**全包范围的噪音**——本次启动一共 22 条（FML、chameleon、codechickenlib、crafttweakerjei、11 个 enderio 子模组、mjrlegendslib、modtweaker、mtlib，加我们的四条）。发消息的类是 `net.minecraftforge.fml.server.FMLServerHandler`，而它只检查"这个 mod 自己的命名空间下有没有那个文件"，内容不限。

所以给四条 mod 各加了一份 `assets/<modid>/lang/en_us.lang`，内容是四行注释（说明这个模块自己的键还没有、包里的键在冻结的 `minespace` 命名空间里）。效果：我们的四条提示全部消失，全包同类提示 22 → 18（剩下 18 条是别人的模组，不归本包管），WARN 总数 5356 → 5352。

**三、收尾后的基线**（2026-10-16 17:51 运行）

| 检查项 | 结果 |
| --- | --- |
| mod 列表 | 四条：`minespace_core` / `minespace_planets` / `minespace_navigation` / `minespace_cosmic` |
| 模块自检 | 四条 `module ... v0.2.0` |
| 载入总数 | 50 |
| 服务器 | `Done (2.029s)!` |
| ERROR / WARN | 40 / 5352（ERROR 全部是别人模组的老噪音：AE2 签名、GT 配方、AE2:S 配置） |
| crafttweaker.log | 零错误 |

到这里，拆分这件事的骨架、两条已完成的搬迁、边界守卫与噪音收尾都齐了；`planets` 与 `cosmic` 等阶段二~六的内容进来时直接填自己的模块，不需要再动结构。
