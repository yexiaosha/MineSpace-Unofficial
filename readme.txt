MineSpace Unofficial
====================

Minecraft 1.12.2 / Forge 14.23.5.2859
GregTech CE: TJ Edition + Galacticraft 整合与附属模组
当前版本：0.2.0
最后更新：2026-10-19
当前状态：开发中；服务器可正常启动到 Done，后期内容仍按阶段实现。


一、这是什么
------------

MineSpace Unofficial 是一个以 GregTech CE: TJ Edition（GTCE-TJ）为核心、
把 Galacticraft / Galaxy Space 的太空内容接入 GT 科技线的非官方整合包，
同时包含一个自主开发的附属模组。

附属模组打包成一个 jar，但 Forge 会识别到四个独立模组：

  minespace_core        核心：GT 材料、机器、跨模组统一与兼容层
  minespace_planets     天体：行星岩石、石种、矿脉、地形与天体数据
  minespace_navigation  导航：星图、目标选择、火箭飞行与降落流程
  minespace_cosmic      后期：研究链、观测设备、戴森球与超光速内容

四个模组的注册名和内容命名空间统一为 minespace，注册名保持冻结。


二、主要内容
------------

1. GregTech 科技线

   - 新增 desh_steel、meteoric_iron 等 GT 材料，物品、粉、板、流体和
     加工配方由 GT 自动生成。
   - 氧气压缩机、火箭燃料装填机等 GT 机器。
   - EU 与 Galacticraft gJ 的能量桥接。
   - NuclearCraft / QMD 材料与配方向 GT 统一，包含残留配方审计与修复。
   - RF 与 EU 按阶段等效转换，不是到某个阶段就失效。

2. 行星与矿脉

   - Galacticraft、Galaxy Space 与本包规划天体的岩石、石种和 GT 矿脉。
   - 主世界、下界、末地与各行星使用各自的矿脉配置。
   - GT 矿脉是主要矿石来源；原版矿、Galaxy Space 行星矿和 NuclearCraft
     的独立矿生成已关闭。
   - 行星区块加载使用分批 fallback，避免一次加载大量区块造成服务器卡顿。

3. 星图与航行

   - 默认按 J 打开本包的星图；星层、天体距离和搜索框都在星图中。
   - 未研究的天体不会显示，避免提前泄露目标。
   - 火箭升空后自动弹出星图，选择目标后按 T 或点击发射按钮。
   - 升空后的星图不能被 ESC 关闭；目标确定后进入降落流程。
   - 支持降落舱、降落伞着陆舱等降落方式，火箭可回收。

4. BYG（Oh The Biomes You'll Go: Legacy Edition）

   - 76 个 BYG 群系、925 个语言 key（已翻译 924 个）、群系名 Mixin 汉化。
   - BYG 木材、石料、树苗补齐矿物词典；46 种树苗接入林业自动农场。
   - BYG 的卡塞、拉萨利姆、帕德莱特、塔姆雷特四种矿石：
       * 关闭 BYG 自己的独立矿生成；
       * 作为混合成分并入 GT 的镍、独居石、铍、铝土/磁铁矿脉；
       * 具有真实化学成分，可进入 GT 的研磨、离心、电解链；
       * BYG 宝石/锭与 GT 材料物品 1:1 双向转换；
       * BYG 宝石块与 GT 压缩块 1:1 双向转换；
       * BYG 自制工具配方移除，改用 GT 工具头 + 木柄；
       * BYG 盔甲保留物品，但改用对应 GT 板制作。

5. 性能

   - 行星矿脉 fallback 每 tick 限量处理，避免单 tick 峰值。
   - 勘探仪矿石成簇过滤，减少零碎矿点和方块读取。
   - 星图星尘改为批量绘制，复用每帧临时列表。
   - 生物群系 decorator patch 增加身份缓存，避免重复反射。


三、启动方式
------------

推荐直接使用仓库内的可运行实例：

  Minespace-unofficial-dev\Play-Minespace.bat

首次运行或实例缺少运行库时，先执行：

  Minespace-unofficial\tools\install-pack.ps1

手动安装到自己的 1.12.2 实例时，需要：

  1. Minecraft 1.12.2 + Forge 14.23.5.2859
  2. Java 8（ForgeGradle 和 GTCE-TJ 都需要 JDK 8）
  3. 把 minespace-0.2.0.jar 放入 mods\
  4. 同步 config\ 和 scripts\ 下的本包配置
  5. 使用新世界启动

主要模组版本：

  GTCE: TJ Edition                 1.18.3
  Gregicality TJ Fork              0.26.3
  Applied Energistics 2 UEL        0.55.6
  CodeChickenLib                   3.2.3.358
  Galacticraft                     4.0.7
  Galaxy Space                     2.2.0
  AsmodeusCore                     1.0.5
  PlanetProgression                0.4.8
  MixinBooter                      11.17
  NuclearCraft                     2o.9.7
  QMD                              1.6.1
  Oh The Biomes You'll Go Legacy   1.0.1
  Forestry                         5.8.2.427
  JEI                              4.16.1.302
  CraftTweaker                     4.1.20.698

注意：从旧 GTCEu 存档迁移到 GTCE-TJ 会改变材料 id、元数据物品 id、
矿石方块和石种。旧存档无法安全迁移，请使用新世界。


四、操作提示
------------

  J                 打开/关闭星图
  鼠标左键拖动      旋转星图
  鼠标右键拖动      平移星图
  滚轮              缩放
  选择目标后 T      发射

  升空后的星图是流程的一部分，不能用 ESC 关闭；选定目标后才会进入
  降落流程。

勘探仪：

  - 只显示形成矿簇的矿石，孤立零碎矿不会刷屏。
  - 赛特斯石英来自 GT 石英/冰壳晶体矿脉和 AE2 陨石结构。
  - 塔姆雷特只作为 GT 铝土/磁铁矿脉的混合成分出现，不再独立成矿。


五、构建
--------

  cd Minespace-unofficial
  .\tools\gradle.ps1 build
  .\tools\gradle.ps1 deployToInstance

只编译不部署：

  .\tools\gradle.ps1 build

离线构建：

  .\tools\gradle.ps1 --offline build

构建产物为 build\libs\minespace-0.2.0.jar。
部署任务会把它复制到 Minespace-unofficial-dev\mods\。


六、目录结构
------------

  Minespace-unofficial\       附属模组源码、构建脚本、工具链
  Minespace-unofficial-dev\   可运行实例与测试环境
  readme.txt                  本说明
  README.md                   仓库入口页

详细文档：

  PROGRESS.md
  Minespace-unofficial\DEV-NOTES.md
  Minespace-unofficial\docs\byg-2026-10-18.md
  Minespace-unofficial\docs\nuclear-gt-unification-2026-10-17.md
  Minespace-unofficial\docs\jei-ore-grouping-2026-10-18.md


七、已知事项
------------

  - 必须是 1.12.2 + Forge 14.23.5.2859 + Java 8。
  - 旧 GTCEu 世界不兼容 GTCE-TJ，请开新世界。
  - 已有区块不会补写新矿脉；BYG 矿石和 GT 矿脉只在新区块生成。
  - AE2 小型赛特斯石英矿簇、BYG 独立矿石生成已关闭；陨石结构保留，
    因为 AE2 压印模板仍然依赖陨石。
  - BYG 自制工具已从合成和 JEI 中移除，GT 工具由材料属性自动生成。
  - 客户端内存主要被 GT 配方/JEI/贴图和整合包内容占用，不是本附属
    模组的静态数据。启动参数默认 -Xms1024M -Xmx6144M；如启动阶段
    GC 明显，可把 -Xms 调到 1536M。
  - runClient 在本机不可靠，调试请使用 deployToInstance + 实例启动。


八、链接
--------

  GitHub: https://github.com/yexiaosha/MineSpace-Unofficial

本包是非官方整合/附属项目，不代表 GregTech、Galacticraft、Galaxy Space、
Applied Energistics、NuclearCraft 或 Oh The Biomes You'll Go 官方。
