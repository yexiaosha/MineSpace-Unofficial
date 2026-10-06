# Minespace Unofficial — playable instance

A Minecraft **1.12.2** Forge instance built on **GregTech CE: Unofficial** and
**Galacticraft**, with **KubeJS** as a companion for tweaking recipes without
recompiling.

This folder has two jobs:

1. a playable base instance, and
2. **the test runtime for the addon** developed in `..\Minespace-unofficial`.

The second job matters most during development: the ForgeGradle userdev client cannot
load these mods on this machine (see `..\Minespace-unofficial\DEV-NOTES.md`, section 3),
so addons are tested by building a jar and running it here.

**Status: verified working.** Boots to the main menu with Forge 14.23.5.2859 loading
**11 mods**; GTCEu registers its materials and worldgen; KubeJS loads all 5 scripts
(`Loaded 5/5 scripts`); the Minespace addon registers its own GregTech materials and
GTCEu generates their items.

---

## Addon test loop

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

| 文件 | modid | 版本 | 作用 |
| --- | --- | --- | --- |
| `gregtech-1.12.2-2.8.10-beta.jar` | `gregtech` | 2.8.10-beta | 格雷科技，附属模组的主要目标 |
| `Galacticraft-1.12.2-4.0.7.jar` | `galacticraftcore` 等 | 4.0.7 | 星系，自带 MicdoodleCore |
| `CodeChickenLib-...-universal.jar` | `codechickenlib` | 3.2.3.358 | **GTCEu 的硬前置** |
| `KubeJS-forge-1.12.2-1.1.0.65.jar` | `kubejs` | 1.1.0.65 | 脚本改配方，无需重编译 |
| `minespace-0.2.0.jar` | `minespace` | 0.2.0 | **本项目的附属模组** |

来源与下载坐标见 [MOD-MANIFEST.md](MOD-MANIFEST.md)。

## KubeJS 脚本

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

GTCEu 与 Galacticraft 都注册油类流体、都生成锡/铜/铝矿。当前两边都用默认配置，实测
可以正常启动，但世界生成会出现重复矿脉。等确定材质体系后，在 `config\` 里关掉其中
一侧的矿物生成，或用矿物词典统一。

首次启动日志里以下内容**属于正常，不影响运行**：

- `Invalid Recipe Found ... duplicate key`（`mortar_grind_lead` / `stick_lead` /
  `plate_lead`）— GTCEu 自身配方注册的重复项
- `Potentially Dangerous alternative prefix 'minecraft'` — GTCEu 有意覆盖原版配方
- `Potentially Dangerous alternative prefix 'minespace'`（`meta_ingot`、`cable_*`…）—
  **这是本附属模组正常工作的标志**：GTCEu 用 addon 的命名空间生成了它的物品
- `MicdoodlePlugin ... is not signed` / `FMLCorePluginContainsFMLMod` — 模组打包方式所致
- `MOD HAS DIRECT REFERENCE System.exit()`（`nashorn`）— Java 8 与 Forge 的已知交互
- `GregTech Module Loader: Module ... skipping loading` — 未安装 JEI/HWYLA 等可选
  集成模组，属预期
