# HANDOFF — 新会话从这里开始

本文件给"下一个会话/接手的人"看：当前状态、已经踩过的坑、下一步该做什么。
细节文档：[README.md](README.md)（工作区总览）、[DEV-NOTES.md](DEV-NOTES.md)（踩坑与
契约，**动手前必读**）。

---

## 1. 这是什么

为 **Minecraft 1.12.2** 开发的 **GregTech CE: Unofficial + Galacticraft 附属模组**。

单一 git 仓库（`github.com/yexiaosha/MineSpace-Unofficial`），两个工程：

```
MineSpace-Unofficial\            <- git 仓库根（本目录的上一级）
├─ .gitignore  .gitattributes  README.md
├─ Minespace-unofficial\       附属模组开发工作区（Gradle 工程）= 本目录
└─ Minespace-unofficial-dev\   可启动实例 = 附属模组的测试运行环境
```

> 工具链（`tools\jdk8`、`git`、`gradle-4.10.3`，约 700 MB）、实例的
> `runtime` / `assets` / `libraries` / `versions`（约 360 MB）、第三方 mod jar 与构建
> 产物**都不在 git 里**。克隆后先跑 `tools\bootstrap.ps1` 与 `tools\install-pack.ps1`
> 重建，详见仓库根 README。

两个工程各自有一份 README；实例侧还有 `MOD-MANIFEST.md` 记录模组来源。

## 2. 当前状态：可用

附属模组**编译通过且实机运行成功**。最后一次验证的日志：

```
[minespace]: Registered 2 GregTech materials in registry 'minespace': desh_steel, meteoric_iron
[minespace]: Target mods: GregTech CE: Unofficial=2.8.10-beta, CodeChicken Lib=3.2.3.358,
             Galacticraft=4.0.7, Galacticraft Planets=4.0.7
[minespace]: GTCEu material check: desh_steel ingot -> minespace.material.desh_steel Ingot
[KubeJS]: Loaded 5/5 scripts in 0.342s
Forge Mod Loader has successfully loaded 11 mods
```

即：附属模组注册的格雷材质，GTCEu 已经为它们生成了物品。不是"只是编译过"。

## 3. 一分钟上手

```powershell
. .\tools\env.ps1                        # 启用本地工具链（可选，gradle.ps1 已自带）
.\tools\gradle.ps1 deployToInstance       # 编译 + 部署到实例
..\Minespace-unofficial-dev\Play-Minespace.bat
```

看自己的日志：

```powershell
Select-String -Path ..\Minespace-unofficial-dev\logs\latest.log -Pattern '\[minespace\]'
```

## 4. 环境事实（省得重新发现）

| 事项 | 事实 |
| --- | --- |
| Java | 机器上原本没有 Java。工具链自带 Temurin **JDK 8**（`tools\jdk8`），1.12.2 ForgeGradle **必须**用它 |
| Gradle | `tools\gradle-4.10.3`。用 `tools\gradle.ps1` 调用（它会注入 `JAVA_HOME`） |
| PATH | 工具链**不写入**系统 PATH 与注册表，不影响其他 Java 项目 |
| 系统 PATH 里没有 | `java` / `javac` / `gradle` / `git` —— 全部走 `tools\` |
| `pwsh` 不存在 | 只有 Windows PowerShell 5.1，脚本用 `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` 绕过执行策略 |
| 磁盘 | 剩余约 425 GB |

### 网络：这几个域名在本机不可达

`github.com`、`api.github.com`、`services.gradle.org`、`raw.githubusercontent.com`
（后者的 DNS 解析为 0.0.0.0）。

**可达**：BMCLAPI、清华 Adoptium 镜像、腾讯云 Gradle 镜像、`edge.forgecdn.net`、
`libraries.minecraft.net`、`cursemaven.com`、`maven.minecraftforge.net`。

所有脚本都改成了镜像优先 + 官方源回退。

> **注意 BMCLAPI 的 `/maven/` 会返回错误内容**：曾把 2.5 MB 的 Guava 返回成 508 字节，
> 直接导致 `NoClassDefFoundError: com/google/common/collect/Lists`。因此
> `install-pack.ps1` 对每个库都做 SHA1 校验，失败自动回退官方源。

## 5. 三个必须知道的技术结论

**① `runClient` 在本机不可用 —— 用 `deployToInstance` 代替。**
ForgeGradle 3 的 userdev 客户端加载 GTCEu / Galacticraft 时会在 FML 的
`NetworkRegistry.newChannel`（Forge 2859 源码第 207 行）NPE 崩溃。已二分定位：
只装 Galacticraft + CCL 也崩，无模组基线正常。这是 userdev 与核心模组的交互问题，
与附属模组本身无关。完整分析见 [DEV-NOTES.md](DEV-NOTES.md) 第 3 节。

**② GTCEu 材质注册是两段式事件，不能在 `preInit` 里建注册表。**
GTCEu 在自己的 preInit 里走完 `PRE → OPEN → CLOSED → FROZEN`：

- `MaterialRegistryEvent`（**PRE**）里 `createRegistry()`
- `MaterialEvent`（**OPEN**）里 `new Material.Builder(...).build()`

在 `preInit` 建表会抛 `Cannot create registries in phase FROZEN`。

**③ 三个静默陷阱**（都实际踩过）：

- `build()` **已经自动注册**，不要再调 `registry.register()`，否则报一个看起来像自冲突的
  `Tried to reassign id 32000 to desh_steel ... already assigned to desh_steel`
- `materialManager.getMaterial()` 要**带命名空间**（`minespace:desh_steel`），传裸路径
  静默返回 null，和"没注册成功"一模一样
- 材质处理器里**别用 `Minespace.log()`**：GTCEu 的 preInit 先跑，此时它还是 null，
  会抛出伪装成 "GregTech 崩溃" 的 NPE。用即时 log4j logger

## 6. 下一步可做的事（按价值排序）

1. **自定义格雷机器**（`MetaTileEntity`）。基类与注册入口已确认：
   `GregTechAPI.MTE_REGISTRY`、基类 `TieredMetaTileEntity` / `SimpleMachineMetaTileEntity`。
   难点是需要自己的 `ModularUI`（`ModularUI.defaultBuilder()` 等已确认存在）。
   这是最自然的下一步。
2. **GC 侧方块**。目前 `MinespaceGalacticraft.GcEnergyBridge` 是给你在**自己的
   `TileEntity` 里实现**的 EU↔gJ 适配器（已实现 `IEnergyStorageGC` 全部四个方法），
   还不是一个成品方块。GC 的 `TileEntity` 属于内部类而非 API，需要读它的实现。
3. **新增星系天体/维度**。入口已确认：`GalaxyRegistry.registerMoon/registerPlanet/
   registerSolarSystem`、`CelestialBody.setDimensionInfo(int, Class<WorldProvider>)`、
   `GalacticraftRegistry.registerRocketGui`。还需要自己写 `WorldProvider` 与维度注册。
4. **用 GTCEu 的矿脉系统给新材质配矿石**。入口：
   `config/gregtech/worldgen/vein`（45 个内置定义，GTCEu 首次启动会解压出来），
   `gregtech.api.worldgen` 包。目前材质只有 `ingot/dust/fluid`，没有 `ore` 前缀。

## 7. 有用的命令

```powershell
.\tools\gradle.ps1 build                              # 编译 + 重新混淆
.\tools\gradle.ps1 deployToInstance                   # 编译 + 部署到实例（主力调试回路）
.\tools\gradle.ps1 installMods -PskipMods=gregtech    # 二分定位加载失败
.\tools\gradle.ps1 clean deployToInstance             # 干净复现

# 实例
..\Minespace-unofficial-dev\Play-Minespace.bat
..\Minespace-unofficial\tools\install-pack.ps1         # 重建实例产物（可重复运行）
..\Minespace-unofficial\tools\bootstrap.ps1            # 重建工具链（可重复运行）
```

## 8. 源码地图

```
src/main/java/com/minespace/unofficial/
├─ Minespace.java                          @Mod 入口、DEPENDENCIES 加载顺序
├─ gtceu/MinespaceMaterials.java           格雷材质注册（两段式事件，核心示例）
├─ galacticraft/MinespaceGalacticraft.java 星系注册助手 + EU<->gJ 能源桥
├─ ModPresence.java                        目标模组版本检测
└─ proxy/CommonProxy.java, ClientProxy.java
```

改依赖坐标看 `build.gradle` 的 `mods` 配置；改版本号看 `gradle.properties`。

## 9. 别做的事

- 不要用 `implementation` / `compileOnly` 直接接目标模组再跑 `runClient`——
  核心模组必须在 `run/mods` 里才会注册它自己的 mod id（见 DEV-NOTES 第 3 节）
- 不要写 `fg.deobf(files(...))`，ForgeGradle 3 不支持，用 maven 坐标
- 不要在 `runs` 块里用 `property` 传系统属性——那是**游戏参数**，要用 `jvmArg`
- 不要把 `run/mods` 里的 jar 换成未反混淆的版本（`installMods` 会自动取正确的那个）
