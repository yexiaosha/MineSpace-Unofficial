# Minespace Unofficial — playable instance

A Minecraft **1.12.2** Forge instance built on **GregTech CE: TJ Edition** and
**Galacticraft**, with **KubeJS** as a companion for tweaking recipes without
recompiling.

This folder has two jobs:

1. a playable base instance, and
2. **the test runtime for the addon** developed in `..\Minespace-unofficial`.

The second job matters most during development: the ForgeGradle userdev client cannot
load these mods on this machine (see `..\Minespace-unofficial\DEV-NOTES.md`, section 3),
so addons are tested by building a jar and running it here.

**Status: verified working (updated 2026-10-15, on the GTCE-TJ stack).** Forge 14.23.5.2859 loads
**47 mods** and the dedicated-server check reaches `Done` in four to seven seconds with **zero**
errors in `crafttweaker.log` (26 recipe scripts) and no new crash reports. The Minespace addon
registers its materials, stone types and two machines; GT's materials, ore veins and planet worldgen
are live.

## 必须开新世界（不要用旧存档）

**这个整合包必须开新世界。** 从 GTCEu 迁到 GTCE-TJ 时，材料的数字 id、元数据物品 id、矿石方块、
石头类型和矿脉定义全都变了，旧存档里的 GTCEu 注册表**没有迁移办法**：读进去的结果是方块/物品被
映射到别的东西上，而不是报错。所以：

- 旧的 GTCEu 存档已经留档为 `world-gtceu-backup`，请**不要**把它放进 `saves\` 里尝试加载；
- 想继续玩旧世界，就把 GTCEu 那套 jar 换回去（它们 parked 在
  `%TEMP%\minespace-removed\2026-10-11-gtceu-stack\`）；
- 新世界第一次生成时，行星矿脉和 21 种 GT 石头类型会按本包的配置生成，这是预期行为。

---

## Addon test loop

> **Note (2026-10-15):** the "Expected" lines below are from the GTCEu era. The current addon logs
> its materials through GregTech's own registry (no `minespace:desh_steel` item key), and the instance
> runs 47 mods, not 28 - see `MOD-MANIFEST.md`. The loop itself (build, copy, start, grep
> `[minespace]`) is unchanged.

```powershell
..\Minespace-unofficial\tools\gradle.ps1 deployToInstance   # build + copy jar into mods\
.\Play-Minespace.bat
```

Then check the addon's log lines:

```powershell
Select-String -Path .\logs\latest.log -Pattern '\[minespace\]'
```

Expected:

```
[minespace]: Registered 2 GregTech materials in registry 'minespace': desh_steel, meteoric_iron
[minespace]: Minespace Unofficial 0.2.0 starting up
[minespace]: Target mods: GregTech CE: Unofficial=2.8.10-beta, CodeChicken Lib=3.2.3.358,
             Galacticraft=4.0.7, Galacticraft Planets=4.0.7
[minespace]: GTCEu material check: desh_steel ingot -> minespace.material.desh_steel Ingot
```

---

## 启动

双击 `Play-Minespace.bat`。

可选参数（传给 `Play-Minespace.ps1`）：

```powershell
.\Play-Minespace.ps1 -MaxMemoryMB 8192    # 提高堆上限，默认 6144
.\Play-Minespace.ps1 -Username Steve      # 换离线用户名
.\Play-Minespace.ps1 -Server              # 起服务端
```

也可以用 HMCL / PCL / PrismLauncher 等启动器，把本文件夹作为**游戏目录**指向即可——
目录结构是标准的 `.minecraft` 布局，`launcher_profiles.json` 里已经注册好
`Minespace Unofficial` 配置。

如果某个产物缺失或损坏，重跑安装器即可（每步都会校验并跳过已完成的产物）：

```powershell
..\Minespace-unofficial\tools\install-pack.ps1
```

## 目录说明

| 路径 | 内容 |
| --- | --- |
| `mods\` | 目标模组 + 本附属模组，**不要**把 CodeChickenLib 删掉 |
| `config\` | 各模组配置；GTCEu 的 `gregtech\` 在首次启动时生成 |
| `kubejs\` | KubeJS 脚本，见下 |
| `resources\` / `scripts\` | 留给资源包 / 脚本的位置 |
| `runtime\jdk8\` | 自带的 Java 8 运行时 |
| `libraries\` | 全部通过 SHA1 校验 |
| `assets\` | 1290 个材质/声音对象 |
| `versions\` | `1.12.2` 本体 + `1.12.2-forge-14.23.5.2859` |
| `logs\` | 运行日志；出问题先看 `logs\latest.log` |
| `crash-reports\` | 崩溃报告 |

## 模组清单

> **2026-10-15 备注：** 下表是 GTCEu 时代的旧清单（8 行、28 mods）。当前是 **47 个 mod**
> 的 GTCE-TJ 栈（Gregicality TJ、AE2UEL 0.55.6、Ender IO、林业、Galacticraft/Galaxy Space、
> PlanetProgression、抽屉、更多箱子……），完整清单、版本与来源见 `MOD-MANIFEST.md`。

| 文件 | modid | 版本 | 作用 |
| --- | --- | --- | --- |
| `gregtech_tj_fork-1.18.3.jar` | `gregtech` | 1.18.3 | **GregTech CE: TJ Edition**，附属模组的主要目标 |
| `gregicality_tj_fork-0.26.3.jar` | `gtadditions` | 0.26.3 | Gregicality TJ Fork，UHV+ 内容与多方块 |
| `appliedenergistics2-...-extended_life-v0.55.6.jar` | `appliedenergistics2` | v0.55.6 | **GTCE-TJ 的硬前置**，必须是 0.55.6 |
| `!mixinbooter-11.17.jar` | `mixinbooter` | 11.17 | Mixin 运行时；**本附属模组用它加载行星岩石材质的 mixin**，也是 Galaxy Space 的前置 |
| `Galacticraft-1.12.2-4.0.7.jar` | `galacticraftcore` 等 | 4.0.7 | 星系，自带 MicdoodleCore |
| `CodeChickenLib-...-universal.jar` | `codechickenlib` | 3.2.3.358 | **GTCE-TJ 的硬前置** |
| `KubeJS-forge-1.12.2-1.1.0.65.jar` | `kubejs` | 1.1.0.65 | 脚本改配方，无需重编译 |
| `minespace-0.2.0.jar` | `minespace` | 0.2.0 | **本项目的附属模组** |

来源与下载坐标见 [MOD-MANIFEST.md](MOD-MANIFEST.md)。

## KubeJS 脚本

> **2026-10-15 备注：** KubeJS 仍然装着，下面关于 1.12.2 KubeJS 的四个坑（`events.listen`、ES5、
> `log`、长方法名）**依然成立**；但本包的配方改造现在全部在 CraftTweaker 脚本里
> （`scripts\*.zs`，26 个文件），KubeJS 只剩启动信息这类杂项。

用途：在不重编译附属模组的前提下试配方改动。脚本目录与加载时机：

| 目录 | 加载时机 | 重载命令 |
| --- | --- | --- |
| `kubejs\startup_scripts` | 游戏启动时一次 | `/kubejs reload_startup_scripts` |
| `kubejs\server_scripts` | 每次进世界 / `/reload` | `/reload` |
| `kubejs\client_scripts` | 客户端资源重载 | `F3+T` |
| `kubejs\assets` | 作为资源包 | `F3+T` |
| `kubejs\data` | 作为数据包 | `/reload` |

### 1.12.2 的 KubeJS 与现代文档完全不同

以下四点均已实测确认，附带的 5 个示例脚本全部按此写并通过加载验证
（`Loaded 5/5 scripts`）：

**① 用 `events.listen()`，不是 `onEvent()`。**
KubeJS 6（1.16+）文档里的全局函数 `onEvent(...)` 在 1.12.2 上**不存在**。1.12.2 暴露
的对象是 `events`：

```javascript
events.listen('recipes', function (event) { ... })
```

写 `onEvent()` 会抛 `ReferenceError: "onEvent" is not defined`，且该文件里所有监听器
都不注册（日志表现为 `Loaded 1/5 scripts`）。

**② 必须写 ES5。**
1.12.2 用 Java 8 内置的 Nashorn 执行脚本，**只支持 ES5**：`const`、`let`、箭头函数
`=>`、模板字符串、`for...of` 全部解析失败，整个文件不加载。请用 `var`、
`function () {}` 和字符串拼接。

**③ 日志用 `log`，不是 `console`。**
`log.info()` / `log.warn()` / `log.error()` / `log.debug()`。

**④ 配方方法名是长名。**
`event.addShaped(...)` / `event.addShapeless(...)`；现代文档里的 `event.shaped(...)` /
`event.shapeless(...)` 在 1.12.2 上不存在。

**格雷科技物品要用矿物词典寻址**：GTCEu 的物品多是 `gregtech:meta_item_1` 之类的
元数据变体，没有可读注册名。写配方时用 `ore:ingotCopper`、`ore:plateIron`、
`ore:dustTin`；在 JEI 里悬停物品（开 `F3+H`）可看到矿物词典条目，或手持物品执行
`/kubejs hand`。

### 附带的示例脚本

- `startup_scripts\00_pack_info.js` — 启动时打印包信息
- `server_scripts\10_example_recipes.js` — 添加配方（`addShaped` / `addShapeless`）
- `server_scripts\20_gtceu_integration.js` — 格雷材料用矿物词典寻址（示例默认注释）
- `server_scripts\30_recipe_removal.js` — 移除配方（示例默认注释）
- `client_scripts\40_example_client.js` — 物品提示文本

## 已知冲突与正常告警

GregTech 与 Galacticraft/Galaxy Space 都会生成矿脉。GT 侧的矿脉定义在
`config\gregtech\worldgen`：overworld/nether/end 用 GT 自带的一套，行星用 2026-10-11 从旧
GTCEu 配置移植过来的一套（moon 9 / mars 14 / venus 13 / asteroids 11 / ceres 1 /
barnarda 1）。移植脚本 `..\Minespace-unofficial\tools\port-worldgen-veins.ps1` 与主世界维度
限定脚本 `fix-worldgen-overworld-scope.ps1` 都可以安全重跑。实测（每维度 64 区块）：主世界
11489 个 GT 矿块、月球 1574、火星 1532、小行星 1379、谷神星 1521。

原版世界生成已被清掉：`config/gregtech.cfg` 的 `B:disableVanillaOres=true` 关掉 8 种原版矿
（实测 0 个），`config/minespace.cfg` 的 `S:disabledVanillaGenerators` 关掉原版的花岗岩/
闪长岩/安山岩整块生成（实测从 ~8 万降到 ~2 千，且这些残留里没有矿）。想连泥土/砂砾或
原版矿也在这里补上名字即可。

CraftTweaker 配方（`scripts\*.zs`，6 个文件）已从 GTCEu 语法移植到 GTCE-TJ：访问器改为
`mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()`，两张表名有变
（`bender`→`metal_bender`、`electric_blast_furnace`→`blast_furnace`），gas collector 那条
在 TJ 里没有对应表（已注释说明，氧气改由 GT 电解水提供）。移植脚本
`..\Minespace-unofficial\tools\port-crafttweaker-scripts.ps1` 可重跑；实测 `crafttweaker.log`
0 错误。

首次启动日志里以下内容**属于正常，不影响运行**：

- `Ignoring invalid recipes and continuing loading`（GT 的 FATAL 横幅）以及
  `Input cannot contain null or empty ItemStacks ... tile.air@0` — GTCE-TJ 的 AE2 集成配方
  在 0.55.6 上少一个中间物品，GT 会跳过这两条配方并继续加载；用 0.56.7 反而会让 GT 的
  AE2 配方整体失效，所以 AE2UEL 固定 0.55.6
- `Potentially Dangerous alternative prefix 'gregtech' ... expected 'gtadditions'` —
  Gregicality 有意覆盖 GT 的机器/机壳注册
- `Potentially Dangerous alternative prefix 'minecraft' ... expected 'galaxyspace'` —
  Galaxy Space 自己的注册遗留，与本包无关
- `Error in another mod's worldgen ... Dimension:0` — 2026-10-11 之前是"Minespace 的
  moon_stone 匹配到空气"导致的 NPE，已修复（21 种石头类型改为在 GT preInit 内注册 +
  惰性解析方块名）；修复后该项不再出现
- `MicdoodlePlugin ... is not signed` / `FMLCorePluginContainsFMLMod` — 模组打包方式所致
- `MOD HAS DIRECT REFERENCE System.exit()`（`nashorn`）— Java 8 与 Forge 的已知交互
