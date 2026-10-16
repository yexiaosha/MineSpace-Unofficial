# 星球与星体总表（PLANET CATALOG）

这份表是《GTCEu 星系整合包详细实施方案》七层分级的落地清单：**20 个太阳系星体 + 86 个深空目标 = 106 个星体**，全部使用现实存在的天体名称，全部数据来自 NASA。

本文件由工具生成，不要手改。设计字段的源头是 planet-catalog.psd1，NASA 数值的源头是 nasa-planet-data.json（由 fetch-planet-data.ps1 抓取），矿脉的源头是 planet-veins.psd1。三者都在 Minespace-unofficial\tools\ 下。

## 数据来源

| 类别 | 来源 |
| --- | --- |
| planets | https://nssdc.gsfc.nasa.gov/planetary/factsheet/ (NASA NSSDC Planetary Fact Sheet, metric, updated 2025-03-18) |
| moons | https://nssdc.gsfc.nasa.gov/planetary/factsheet/ satellite fact sheets (jovian, saturnian, uranian, neptunian) plus the satellite tables of the Mars and Pluto sheets |
| exoplanets | NASA Exoplanet Archive TAP, table pscomppars (https://exoplanetarchive.ipac.caltech.edu/) |
| curated | the per-body Source url recorded on each entry |

抓取日期：2026-10-15。JPL 的 ssd.jpl.nasa.gov 在这台机器上 TLS 握手失败（2026-10-15 实测），所以卫星数据取自 NSSDC 的卫星事实表；NED（NASA/IPAC）能应答但只给位置与红移，因此不作为距离来源。

## 七层分级与电压

| 层 | 名称 | 阶段 | 电压 | 距离范围 | 主题 | 星体数 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 太阳系 | 0-3 | 蒸汽~EV | 距地球 0.0000026 ~ 0.00042 光年（40 AU 以内） | 母星与整合包已有的星球、卫星与天体带（不新增维度）；唯一可以不靠火箭到达的层 | 20 |
| 2 | 近邻星系区 | 4 | IV | 距地球 4 ~ 16 光年 | 第一批恒星际目标：比邻星、巴纳德星、天仓五、ε 波江座；遗迹 I 型开始出现 | 16 |
| 3 | 中距星系区 | 5 | LuV~ZPM | 距地球 16 ~ 100 光年 | TRAPPIST-1 与 Gliese 系；气态行星采集上线；遗迹 II 型（戴森球残骸） | 14 |
| 4 | 远距星系区 | 6 | UV | 距地球 100 ~ 2,000 光年 | 开普勒场：Kepler-452b 与同类；时间观测仪上线。2,000 光年以内的极端天体也落在这一段（参宿四、船帆座脉冲星、PSR B1257+12 的脉冲星行星） | 14 |
| 5 | 深空星系区 | 7 | UHV | 距地球 2,000 ~ 100,000 光年（仍在银河系内） | 银盘与银心：脉冲星、恒星级黑洞、微类星体与分子云；戴森球三阶段与宇宙模拟器 | 14 |
| 6 | 超深空星系区 | 8 | UHV+ | 距地球 10 万 ~ 1 亿光年（本星系群 → 室女座星系团） | 本星系群与近邻星系团：麦哲伦云、仙女座、M87；遗迹 IV 型 | 13 |
| 7 | 未知星系 | 8 | UHV+ | 距地球 1 亿 ~ 465 亿光年（其中 10 个在 100 亿光年以上） | 星系门之后的层：远古星系、类星体、宇宙网、微波背景；只观测，不登陆。两个例外不按距离分层——奥陌陌与鲍里索夫是"来访者"，它们就在太阳系里 | 15 |

## 尺度：真实宇宙 vs 游戏内（owner 填的比例）

分层按 **距地球的距离** 划，每层一个量级；下表是每层的真实体量、游戏内实际放了多少天体，以及两者的比例。方案文档本身没有给任何距离数字（把全文按 光年 / 亿光年 / 万光年 / AU / 距离 / 尺度 检索，命中 0 次），所以这些分带与比例是本表定的。

| 层 | 名称 | 距地球 | 真实体量 | 游戏内 | 比例 |
| --- | --- | --- | --- | --- | --- |
| 1 | 太阳系 | 距地球 0.0000026 ~ 0.00042 光年（40 AU 以内） | 1 个恒星系：8 行星 + 5 矮行星 + 400 多颗卫星 | 20 个天体：19 个可登陆 + 地球。四个气态巨行星不单列——它们是 GS 既有的地图对象，阶段五的气态采集挂在它们身上，不是可登陆天体 | 1:1 |
| 2 | 近邻星系区 | 距地球 4 ~ 16 光年 | 这个半径内只有几十个恒星系——真实体量小到可以逐颗建 | 16 个天体，来自 13 个恒星系 | ≈1:3（代表性采样） |
| 3 | 中距星系区 | 距地球 16 ~ 100 光年 | 这个半径内约数千个恒星系 | 14 个天体，来自 8 个恒星系 | ≈1:150 |
| 4 | 远距星系区 | 距地球 100 ~ 2,000 光年 | 这个半径内恒星数量级 10^8 | 14 个天体，来自 14 个恒星系（一系一体，含一个脉冲星系统） | ≈1:10^7 |
| 5 | 深空星系区 | 距地球 2,000 ~ 100,000 光年（仍在银河系内） | 银河系银盘与银心：10^10 ~ 10^11 颗恒星 | 14 个天体 + 银盘/银心两个可扫描星场 | ≈1:10^9 |
| 6 | 超深空星系区 | 距地球 10 万 ~ 1 亿光年（本星系群 → 室女座星系团） | 本星系群与室女座团：约 10^12 颗恒星、10^3 ~ 10^4 个星系 | 13 个天体 + 星系团星场 | ≈1:10^11 |
| 7 | 未知星系 | 距地球 1 亿 ~ 465 亿光年（其中 10 个在 100 亿光年以上） | 可观测宇宙：约 2×10^12 个星系，恒星最多 10^24 颗 | 15 个观测目标 + 宇宙网星场（只读） | ≈1:10^23 |

维度 ID 分配：

- 太阳系原生：GC -28..-31，GS -1005..-1032、-1126..-1129、-1234、-1338（实测，不动）
- 太阳系不再新开维度：四个气态巨行星沿用 GS 既有对象（木星 -1026），不占新 ID
- 近邻星系区 -2000..-2099，中距 -2100..-2199，远距 -2200..-2299
- 深空 -2300..-2349，超深空 -2350..-2399，未知/观测 -2400..-2449
- 方案的 -100/-110/-120 段只有 10 个 ID 宽，装不下，所以保留它的分段结构、把宽度放大；
- 以上区段与实测占用（GC/GS）无重叠。

## 方案点名的优先体

方案的第八章没有点名那 12 个太阳系天体，只给了工作顺序（月球金标准 → 内圈三兄弟水星/金星/火星 → 小行星带 + 六颗卫星）。按这个顺序反推，12 个 = 地球 + 月球 + 水星 + 金星 + 火星 + 小行星带 + 六颗卫星（火卫一、火卫二、木卫一、木卫二、木卫三、土卫六）。这是本表的一个假设，若口径不同只需改 planet-catalog.psd1 里的 Priority 一行。

| 口径 | 天体 | 层 | 阶段 | 说明 |
| --- | --- | --- | --- | --- |
| 方案的 12 天体 | 月球（Moon） | 太阳系 | 0-3 | 矿脉金标准（7 条，零重复）；方案里 M1 一步之遥的落点 |
| 方案的 12 天体 | 水星（Mercury） | 太阳系 | 0-3 | 无氧化高金属与陨石冲击成因的铁镍铂族矿脉（方案 4.2 的地质设定卡示例） |
| 方案的 12 天体 | 火星（Mars） | 太阳系 | 0-3 | 氧化铁地表与古水流沉积；desh/sulfur 脉专属，GS 新世界引擎地形 |
| 方案的 12 天体 | 金星（Venus） | 太阳系 | 0-3 | 两个维度（GC 与 GS 各一）合成一个天体；高温硫化物与 solar 脉是它的招牌 |
| 方案的 12 天体 | 土卫六（Titan） | 太阳系 | 0-3 | 唯一有稠密大气与液体循环的卫星；低温烃类与氮系矿脉（方案 4.2 点名） |
| 方案的 12 天体 | 火卫一（Phobos） | 太阳系 | 0-3 | 潮汐锁定的撞击碎屑体；矿脉走月面岩基组 |
| 方案的 12 天体 | 地球（Earth） | 太阳系 | 0-3 | 母星；蒸汽到 EV 的全部产线都在这里，资源闭环原则的基准层。矿脉不由本表管理：主世界用的是 GT 自带的那几张表，planet-veins.psd1 刻意不碰它 |
| 方案的 12 天体 | 火卫二（Deimos） | 太阳系 | 0-3 | 火星外侧小卫星；低重力着陆成本，早期铱锇来源之一 |
| 方案的 12 天体 | 小行星带（Asteroid belt） | 太阳系 | 0-3 | 零重力维度；platinum 与 naquadah 两条稀有脉是来这里的原因 |
| 方案的 12 天体 | 木卫一（Io） | 太阳系 | 0-3 | 潮汐热驱动的火山硫系世界；sulfur 脉的招牌天体（方案 4.2 点名） |
| 方案的 12 天体 | 木卫三（Ganymede） | 太阳系 | 0-3 | 太阳系最大卫星、唯一有磁场的卫星：采样之旅的终点 |
| 方案的 12 天体 | 木卫二（Europa） | 太阳系 | 0-3 | 冰下海洋的咸水热液矿脉；冰下海洋升温与钻孔是它的专属机制 |
| 方案点名 | 比邻星 b（Proxima Centauri b） | 近邻星系区 | 4 | 方案的阶段三样板（4.4.3）：最老、被重熔次数最多的地壳，signature=zircon（锆石） |
| 方案点名 | TRAPPIST-1 e（TRAPPIST-1 e） | 中距星系区 | 5 | 方案的第二个样板候选：可能有液态水与全球海洋；II 型遗迹（戴森球残骸）的主舞台 |
| 方案点名 | 开普勒 452 b（Kepler-452 b） | 远距星系区 | 6 | 方案点名的 UV 阶段目标：60 亿年的老年类太阳恒星，公转一年 385 天；III 型遗迹 |

## 第 1 层：太阳系（0-3 / 蒸汽~EV / 距地球 0.0000026 ~ 0.00042 光年（40 AU 以内））

母星与整合包已有的星球、卫星与天体带（不新增维度）；唯一可以不靠火箭到达的层。本层 20 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距太阳/母星（含距地球范围） | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 小行星带（Asteroid belt） | AsteroidBelt |  |  |  |  |  |  |  |
| 木卫四（Callisto） | Moon |  |  |  | 2410.3 | 0.1802 |  |  |
| 谷神星（Ceres） | DwarfPlanet |  | 2.77 AU（日心）；距地球 1.77 ~ 3.77 AU | 4.6 years | 469.7 | 1.571e-4 |  | 1801 |
| 火卫二（Deimos） | Moon |  | 23459 km |  | 7.8 x 6 x 5.1 | 4.019e-7 |  |  |
| 地球（Earth） | Planet |  | 1 AU | 365 | 6371.000 | 1 | 15 C |  |
| 土卫二（Enceladus） | Moon |  |  |  | 257 x 251 x 248 | 1.808e-4 |  |  |
| 木卫二（Europa） | Moon |  |  |  | 1560.8 | 0.0804 |  |  |
| 木卫三（Ganymede） | Moon |  |  |  | 2631.2 | 0.2481 |  |  |
| 妊神星（Haumea） | DwarfPlanet |  | 43.1 AU (mean)（日心）；距地球 42.1 ~ 44.1 AU | 284 years | 780 | 6.708e-4 |  | 2004 |
| 木卫一（Io） | Moon |  |  |  | 1821.5 | 0.1496 |  |  |
| 柯伊伯带（Kuiper belt） | AsteroidBelt |  |  |  |  |  |  |  |
| 火星（Mars） | Planet |  | 1.524 AU（日心）；距地球 0.52 ~ 2.52 AU | 687 | 3389.5 | 0.1074 | -65 C |  |
| 水星（Mercury） | Planet |  | 0.387 AU | 87.969 | 2439.7 | 0.0553 | 167 C |  |
| 天卫五（Miranda） | Moon |  |  |  | 240 x 234.2 x 232.9 | 1.105e-4 |  |  |
| 月球（Moon） | Moon |  | 384,400 km | 27.322 | 1737.4 | 0.0123 | -20 C |  |
| 火卫一（Phobos） | Moon |  | 9378 km |  | 13 x 11.4 x 9.1 | 1.775e-6 |  |  |
| 冥王星（Pluto） | DwarfPlanet |  | 39.236 AU（日心）；距地球 38.24 ~ 40.24 AU | 90560 | 1188 | 0.0022 | -225 C |  |
| 土卫六（Titan） | Moon |  |  |  | 2,575 | 0.2253 |  |  |
| 海卫一（Triton） | Moon |  |  |  | 1,353.4 | 0.0358 |  |  |
| 金星（Venus） | Planet |  | 0.723 AU | 225 | 6051.8 | 0.815 | 464 C |  |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 小行星带（Asteroid belt） | -30 | -30 | 7 条：Asteroid Carbonaceous Vein;Asteroid Diamond Vein;Asteroid Metal Vein;Asteroid Naquadah Vein;Asteroid PGM Vein;Asteroid Silicate Vein;Asteroid Tungstate Vein | I | 真空-无氧-微重力 | 零重力维度；platinum 与 naquadah 两条稀有脉是来这里的原因 |
| 木卫四（Callisto） | -1022 | -1022 | 5 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein | 0 | 强辐射-冰岩混合-无氧 | 辐射最少的木星系卫星：玩家第一个安全的木星系基地 |
| 谷神星（Ceres） | -1007 | -1007 | 6 条：Asteroid Carbonaceous Vein;Ceres Carbonate Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein | 0 | 低压-无氧-低温 | 唯一在带内的矮行星；dolomite 脉 + 盐水冰火山地质 |
| 火卫二（Deimos） | -1013 | -1013 | 5 条：Asteroid Carbonaceous Vein;Asteroid Metal Vein;Asteroid PGM Vein;Asteroid Silicate Vein;Asteroid Tungstate Vein | 0 | 真空-无氧-微重力 | 火星外侧小卫星；低重力着陆成本，早期铱锇来源之一 |
| 地球（Earth） |  |  | 不适用（矿脉来自 overworld，不在本表） | 0 | 宜居 | 母星；蒸汽到 EV 的全部产线都在这里，资源闭环原则的基准层。矿脉不由本表管理：主世界用的是 GT 自带的那几张表，planet-veins.psd1 刻意不碰它 |
| 土卫二（Enceladus） | -1017 | -1017 | 5 条：Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Brine Vein;Ice Shell Crystal Vein | 0 | 无氧-低温-间歇喷泉 | 南极喷泉直接采样的水体；盐-碳酸盐脉与硫脉共存 |
| 木卫二（Europa） | -1015 | -1015 | 6 条：Ice Shell Brine Vein;Ice Shell Crystal Vein;Metallic Core Vein;Ocean Floor PGM Vein;Silicate Mantle Vein;Tidal Hydrothermal Vein | 0 | 强辐射-冰面-无氧 | 冰下海洋的咸水热液矿脉；冰下海洋升温与钻孔是它的专属机制 |
| 木卫三（Ganymede） | -1016 | -1016 | 6 条：Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein;Metallic Core Vein;Silicate Mantle Vein | 0 | 强辐射-稀薄氧-无氧可呼吸 | 太阳系最大卫星、唯一有磁场的卫星：采样之旅的终点 |
| 妊神星（Haumea） | -1023 | -1023 | 5 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein | 0 | 极低温-无氧-高速自转 | 3.9 小时自转一周的椭球体，带环；小行星组稀有脉 |
| 木卫一（Io） | -1014 | -1014 | 6 条：Frontier Rare Earth Vein;Io Alkali Salt Vein;Io PGM Vein;Io Sulfide Vein;Io Sulfur Vein;Io Volcanic Silicate Vein | 0 | 强辐射-火山-无氧 | 潮汐热驱动的火山硫系世界；sulfur 脉的招牌天体（方案 4.2 点名） |
| 柯伊伯带（Kuiper belt） | -1009 | -1009 | 6 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein;Kuiper Exotic Vein | I | 极低温-无氧-微重力 | 零重力维度；稀有金属与海王星外天体采样区 |
| 火星（Mars） | -29 | -29 | 7 条：Martian Basalt Vein;Martian Desh Vein;Martian Evaporite Vein;Martian Hematite Vein;Martian Incompatible Vein;Martian Sulfate Vein;Martian Tungstate Vein | I | 低压-无氧-低温-尘暴 | 氧化铁地表与古水流沉积；desh/sulfur 脉专属，GS 新世界引擎地形 |
| 水星（Mercury） | -1005 | -1005 | 6 条：Frontier Silicate Vein;Mercurian Core Metal Vein;Mercurian Graphite Vein;Mercurian PGM Vein;Mercurian Silicate Vein;Mercurian Sulfide Vein | 0 | 高温-无氧-太阳辐射 | 无氧化高金属与陨石冲击成因的铁镍铂族矿脉（方案 4.2 的地质设定卡示例） |
| 天卫五（Miranda） | -1024 | -1024 | 5 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein | 0 | 无氧-低温-微重力 | 被撕裂重组过的拼贴地表，悬崖落差 20 km；LuV 钽铌矿的前哨 |
| 月球（Moon） | -28 | -28 | 7 条：Highland Anorthosite Vein;Impact Diamond Vein;Impact Iron Nickel Vein;Impact Platinum Vein;KREEP Rare Earth Vein;Mare Ilmenite Vein;Mare Sulfide Vein | 0 | 真空-无氧-昼夜温差 | 矿脉金标准（7 条，零重复）；方案里 M1 一步之遥的落点 |
| 火卫一（Phobos） | -1012 | -1012 | 5 条：Asteroid Carbonaceous Vein;Asteroid Metal Vein;Asteroid PGM Vein;Asteroid Silicate Vein;Asteroid Tungstate Vein | 0 | 真空-无氧-微重力 | 潮汐锁定的撞击碎屑体；矿脉走月面岩基组 |
| 冥王星（Pluto） | -1008 | -1008 | 6 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein;Pluto Tholin Vein | I | 极低温-稀薄氮气-无氧 | 氮冰对流平原与有机焦油砂；小行星组稀有脉 + 旗舰天体 |
| 土卫六（Titan） | -1018 | -1018 | 5 条：Frontier Iron Nickel Vein;Frontier Silicate Vein;Ice Shell Crystal Vein;Titan Hydrocarbon Vein;Titan Nitrogen Vein | I | 低温-富氮大气-甲烷雨-无氧 | 唯一有稠密大气与液体循环的卫星；低温烃类与氮系矿脉（方案 4.2 点名） |
| 海卫一（Triton） | -1021 | -1021 | 5 条：Asteroid Carbonaceous Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Volatile Vein;Ice Shell Crystal Vein | 0 | 极低温-氮气间歇泉-逆行轨道 | 逆行轨道的俘获柯伊伯天体；氮-甲烷冰与有机脉 |
| 金星（Venus） | -31;-1006 | -31;-1006 | 7 条：Venusian Acid Cloud Vein;Venusian Basalt Vein;Venusian Cinnabar Vein;Venusian Evaporite Vein;Venusian Gem Vein;Venusian Solar Vein;Venusian Sulfide Vein | 0 | 高温-高压-硫酸云-腐蚀 | 两个维度（GC 与 GS 各一）合成一个天体；高温硫化物与 solar 脉是它的招牌 |

## 第 2 层：近邻星系区（4 / IV / 距地球 4 ~ 16 光年）

第一批恒星际目标：比邻星、巴纳德星、天仓五、ε 波江座；遗迹 I 型开始出现。本层 16 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 南门二 A（Alpha Centauri A） | Star |  | 4.37 ly |  |  |  |  |  |
| 巴纳德 b（现 Barnarda C） · Barnard's Star b | Planet | Barnard's star M3.5-4 V | 5.96 ly | 3.154 | 0.72000000 | 0.299 | 438 K eq | 2024 |
| 巴纳德 c（现 Barnarda C1） · Barnard's Star c | Planet | Barnard's star M3.5-4 V | 5.96 ly | 4.124 | 0.74300000 | 0.335 | 400 K eq | 2025 |
| 巴纳德 d（现 Barnarda C2） · Barnard's Star d | Planet | Barnard's star M3.5-4 V | 5.96 ly | 2.34 | 0.69400000 | 0.263 | 483 K eq | 2025 |
| 天苑四 b（Epsilon Eridani b） | Planet | eps Eri K2 V | 10.4 ly | 2680 | 13.80000000 | 318 | 112 K eq | 2000 |
| GJ 1002 b | Planet | GJ 1002 M5.5 V | 15.8 ly | 10.346 | 1.03000000 | 1.08 | 231 K eq | 2022 |
| GJ 1061 c | Planet | GJ 1061 M5.5 V | 12 ly | 6.682 | 1.19000000 | 1.81 | 304 K eq | 2020 |
| 鲁坦星 b（Luyten's Star b） | Planet | GJ 273 M3.5 | 19.3 ly | 18.65 | 1.51000000 | 2.89 | 292 K eq | 2017 |
| GJ 887 d | Planet | GJ 887 M1 V | 10.7 ly | 50.77 | 2.34000000 | 6.1 | 241 K eq | 2026 |
| 比邻星 b（Proxima Centauri b） | Planet | Proxima Cen M5.5 V | 4.24 ly | 11.185 | 1.02000000 | 1.055 | 218 K eq | 2016 |
| 比邻星 d（Proxima Centauri d） | Planet | Proxima Cen M5.5 V | 4.24 ly | 5.123 | 0.69200000 | 0.26 | 282 K eq | 2025 |
| 罗斯 128 b（Ross 128 b） | Planet | Ross 128 M4 | 11 ly | 9.866 | 1.11000000 | 1.4 | 301 K eq | 2017 |
| 天狼星 B（Sirius B） | WhiteDwarf |  | 8.6 ly |  |  |  |  | 1862 |
| 天仓五 f（Tau Ceti f） | Planet | Tau Ceti (G8 V) | 11.9 ly | ~636 days |  |  |  |  |
| 蒂加登星 b（Teegarden's Star b） | Planet | Teegarden's Star M7.0 V | 12.5 ly | 4.906 | 1.05000000 | 1.16 | 277 K eq | 2019 |
| 沃尔夫 1061 c（Wolf 1061 c） | Planet | Wolf 1061 M3.5 | 14 ly | 17.872 | 1.66000000 | 3.41 | 299 K eq | 2015 |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 南门二 A（Alpha Centauri A） |  | -2029 | 不适用（恒星/气态/黑洞等，非登陆体） | - | 高温-辐射 | 与太阳同型的最近恒星：戴森云的第一个现实候选（M6 摘星的舞台） |
| 巴纳德 b（现 Barnarda C） · Barnard's Star b | -1030 | -1030 | 8 条：Barnarda Basalt Vein;Barnarda Deep Crystal Vein;Barnarda Onyx Vein;Frontier Iron Nickel Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Sulfide Vein;Frontier Volatile Vein | I | 无氧-低温-红矮星辐射 | GS 的"Barnarda C"是虚构名，方案 1.1 要求全部用现实天体名：把 -1030 映射到真实的 Barnard b；signature=onyx 保留 |
| 巴纳德 c（现 Barnarda C1） · Barnard's Star c | -1031 | -1031 | 8 条：Barnarda Basalt Vein;Barnarda Deep Crystal Vein;Barnarda Pegmatite Vein;Frontier Iron Nickel Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Sulfide Vein;Frontier Volatile Vein | I | 无氧-低温-辐射 | 映射 -1031 → Barnard c；signature=伟晶岩（铌钽镓），快速冷却的岩浆分异 |
| 巴纳德 d（现 Barnarda C2） · Barnard's Star d | -1032 | -1032 | 8 条：Barnarda Basalt Vein;Barnarda Deep Crystal Vein;Barnarda Ruin Cache Vein;Frontier Iron Nickel Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Sulfide Vein;Frontier Volatile Vein | II | 无氧-低温-辐射 | 映射 -1032 → Barnard d；signature=遗迹矿藏（vinteum/opal/jasper，人工路线） |
| 天苑四 b（Epsilon Eridani b） |  | -2007 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 气态巨行星-强辐射带 | 10.5 光年的年轻（~8 亿年）系统：气态采集与"行星系仍在形成"的教学样本 |
| GJ 1002 b |  | -2023 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 15.8 光年，本层最远的目标；潮汐锁定的双行星系统 |
| GJ 1061 c |  | -2018 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 6.7 天周期，宜居带边缘；本层的中距落脚点 |
| 鲁坦星 b（Luyten's Star b） |  | -2012 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 12.35 光年的温和超地球；近邻区的第二个矿业据点 |
| GJ 887 d |  | -2022 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 2026 年新公布；50.8 天周期，宜居带正中 |
| 比邻星 b（Proxima Centauri b） | -1025 | -1025 | 8 条：Flare Baked Regolith Vein;Frontier Iron Nickel Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Sulfide Vein;Frontier Volatile Vein;Proxima Zircon Vein;Substellar Sea Vein | I | 无氧-低压-红矮星耀斑辐射 | 方案的阶段三样板（4.4.3）：最老、被重熔次数最多的地壳，signature=zircon（锆石） |
| 比邻星 d（Proxima Centauri d） |  | -2002 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-辐射-潮汐锁定 | 质量仅 0.26 地球的亚地球，2025 年确认；最近的行星际落脚点 |
| 罗斯 128 b（Ross 128 b） |  | -2011 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 11 光年、几乎不耀斑的红矮星行星：安静恒星系的宜居带对照 |
| 天狼星 B（Sirius B） |  | -2028 | 不适用（恒星/气态/黑洞等，非登陆体） | I | 高温-强辐射-极端重力 | 白矮星：不是矿，是极高密度的物质样本；这里是"极端物质"线的第一个台阶 |
| 天仓五 f（Tau Ceti f） | -1338 | -1338 | 7 条：Frontier Iron Nickel Vein;Frontier Rare Earth Vein;Frontier Silicate Vein;Frontier Sulfide Vein;Frontier Volatile Vein;TauCeti Carbonate Vein;TauCeti Pressure Diamond Vein | I | 无氧-低温-高压 | GS 的 Tau Ceti F 维度 -1338 保留；signature=碳酸盐蒸发岩（witherite/celestine/rhodocrosite）+ 压钻石脉 |
| 蒂加登星 b（Teegarden's Star b） |  | -2008 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 12.5 光年的 M7 矮星宜居带行星；本层最像"第二个家"的一颗 |
| 沃尔夫 1061 c（Wolf 1061 c） |  | -2026 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 17.9 天周期，宜居带内；近邻区最早被讨论的宜居候选 |

## 第 3 层：中距星系区（5 / LuV~ZPM / 距地球 16 ~ 100 光年）

TRAPPIST-1 与 Gliese 系；气态行星采集上线；遗迹 II 型（戴森球残骸）。本层 14 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 55 巨蟹座 e（55 Cancri e） | Planet | 55 Cnc G8 V | 41 ly | 0.7365 | 1.87500000 | 7.99 | 1958 K eq | 2004 |
| Gliese 581 c | Planet | GJ 581 M3.0 V | 20.5 ly | 12.921 | 2.50000000 | 6.81 | 346 K eq | 2007 |
| Gliese 667 C c（GJ 667 C c） | Planet | GJ 667 C M1.5 V | 23.6 ly | 28.14 | 1.77000000 | 3.8 |  | 2013 |
| Gliese 876 b | Planet | GJ 876 M2.5V | 15.2 ly | 61.117 | 13.30000000 | 723 | 191 K eq | 1998 |
| HD 219134 b | Planet | HD 219134 K3 V | 21.3 ly | 3.093 | 1.60200000 | 4.74 | 1015 K eq | 2015 |
| HD 40307 g | Planet | HD 40307 K2.5 V | 42.2 ly | 198 | 2.56000000 | 7.1 | 255 K eq | 2013 |
| 飞马座 51 b（51 Pegasi b） | Planet | 51 Peg G5V | 50.4 ly | 4.231 | 14.10000000 | 194 | 1329 K eq | 1995 |
| TRAPPIST-1 b | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 1.511 | 1.11600000 | 1.374 | 398 K eq | 2016 |
| TRAPPIST-1 c | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 2.422 | 1.09700000 | 1.308 | 340 K eq | 2016 |
| TRAPPIST-1 d | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 4.049 | 0.78800000 | 0.388 | 286 K eq | 2016 |
| TRAPPIST-1 e | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 6.101 | 0.92000000 | 0.692 | 250 K eq | 2017 |
| TRAPPIST-1 f | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 9.208 | 1.04500000 | 1.039 | 218 K eq | 2017 |
| TRAPPIST-1 g | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 12.352 | 1.12900000 | 1.321 | 197 K eq | 2017 |
| TRAPPIST-1 h | Planet | TRAPPIST-1 M8.0 V | 40.5 ly | 18.773 | 0.75500000 | 0.326 | 172 K eq | 2017 |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 55 巨蟹座 e（55 Cancri e） |  | -2119 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-熔岩-超高温 | 41 光年的熔岩世界：白天 1958 K、0.74 天公转；岩浆海直接开采（熔岩冶金线） |
| Gliese 581 c |  | -2108 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-高温-温室失控 | 第一个被宣布"宜居"的系外行星，后来被推翻：教科书级的纠错案例 |
| Gliese 667 C c（GJ 667 C c） |  | -2111 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-辐射 | 28 天周期、宜居带内；三合星系统里的稳定轨道（L4/L5 问题） |
| Gliese 876 b |  | -2113 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 气态-辐射带 | 15.2 光年的共振锁链；b 是 2.3 木星质量的巨行星 |
| HD 219134 b |  | -2116 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-高温-岩石 | 21.3 光年的超级地球；太阳系外岩石行星的密度基准点 |
| HD 40307 g |  | -2121 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-岩石 | 42 光年、7.1 地球质量、255 K：中等质量宜居带的样本 |
| 飞马座 51 b（51 Pegasi b） |  | -2120 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 气态-超高温-强风 | 第一颗被发现的系外行星（1995，诺奖）：本层必到的纪念地，图鉴第一章 |
| TRAPPIST-1 b |  | -2100 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-高温-潮汐锁定 | 40 光年的超冷矮星系统，七颗都是地球大小；b 是最内、最热的一颗 |
| TRAPPIST-1 c |  | -2101 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-高温-潮汐锁定 | 与 b 成轨道共振；金星式的失控温室样本 |
| TRAPPIST-1 d |  | -2102 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-温和-潮汐锁定 | 0.39 地球质量的亚地球；本层最轻的登陆目标 |
| TRAPPIST-1 e |  | -2103 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | II | 无氧-温和-潮汐锁定 | 方案的第二个样板候选：可能有液态水与全球海洋；II 型遗迹（戴森球残骸）的主舞台 |
| TRAPPIST-1 f |  | -2104 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-低温-潮汐锁定 | 冰壳海洋（H2O 占比可能过半） |
| TRAPPIST-1 g |  | -2105 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-低温-潮汐锁定 | 极低温冰世界；挥发分分馏的样本 |
| TRAPPIST-1 h |  | -2106 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 无氧-极低温-潮汐锁定 | 0.33 地球质量、18.8 天；共振链最外端的冰球 |

## 第 4 层：远距星系区（6 / UV / 距地球 100 ~ 2,000 光年）

开普勒场：Kepler-452b 与同类；时间观测仪上线。2,000 光年以内的极端天体也落在这一段（参宿四、船帆座脉冲星、PSR B1257+12 的脉冲星行星）。本层 14 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 参宿四（Betelgeuse） | Star |  | ~548 ly |  |  |  |  |  |
| 博亚吉安星（Boyajian's Star (KIC 8462852)） | Star |  | ~1,470 ly |  |  |  |  |  |
| K2-18 b | Planet | K2-18 M2.5 V | 124 ly | 32.94 | 2.37000000 | 8.92 | 284 K eq | 2015 |
| 开普勒 138 c（Kepler-138 c） | Planet | Kepler-138 M1 V | 218.1 ly | 13.782 | 1.51000000 | 2.3 | 410 K eq | 2014 |
| 开普勒 16 b（Kepler-16 b） | Planet | Kepler-16 | 244.9 ly | 229 | 8.44930000 | 106 | 206 K eq | 2011 |
| 开普勒 1649 c（Kepler-1649 c） | Planet | Kepler-1649 | 300.7 ly | 19.535 | 1.06000000 | 1.2 | 234 K eq | 2020 |
| 开普勒 186 f（Kepler-186 f） | Planet | Kepler-186 M1 | 579.2 ly | 130 | 1.17000000 | 1.71 | 177 K eq | 2014 |
| 开普勒 22 b（Kepler-22 b） | Planet | Kepler-22 G5 V | 634.8 ly | 290 | 2.10000000 | 9.1 | 279 K eq | 2011 |
| 开普勒 37 b（Kepler-37 b） | Planet | Kepler-37 | 208.5 ly | 13.367 | 0.30980000 | 0.79 | 718 K eq | 2013 |
| 开普勒 442 b（Kepler-442 b） | Planet | Kepler-442 | 1194 ly | 112 | 1.34000000 | 2.36 | 241 K eq | 2015 |
| 开普勒 452 b（Kepler-452 b） | Planet | Kepler-452 G2 | 1799 ly | 385 | 1.63000000 | 3.29 | 265 K eq | 2015 |
| 开普勒 62 f（Kepler-62 f） | Planet | Kepler-62 K2 V | 981.3 ly | 267 | 1.41000000 | 35 | 208 K eq | 2013 |
| PSR B1257+12 b（尸鬼） · Draugr (PSR B1257+12 b) | Planet | PSR B1257+12 | 1957 ly | 25.262 | 0.33800000 | 0.02 |  | 1994 |
| 船帆座脉冲星（Vela Pulsar (PSR B0833-45)） | Pulsar |  | ~960 ly |  |  |  |  |  |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 参宿四（Betelgeuse） |  | -2224 | 不适用（恒星/气态/黑洞等，非登陆体） | III | 高温-辐射-变星光度 | 肉眼可见的红超巨星：戴森云工程的现实参照（规模感教学） |
| 博亚吉安星（Boyajian's Star (KIC 8462852)） |  | -2222 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 高温-辐射-非周期变暗 | "戴森球候选星"的原始样本，答案是尘埃：遗迹学里唯一被否定过的 II 型案例，图鉴彩蛋 |
| K2-18 b |  | -2223 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | I | 氢气大气-高压-海洋候选 | 124 光年：大气里检出过水汽与含碳分子；"海世界"线的第一个实际目标 |
| 开普勒 138 c（Kepler-138 c） |  | -2217 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | II | 高压-水世界 | 密度 2.3 g/cm3 的"水世界"：一半以上是水，不是岩石 |
| 开普勒 16 b（Kepler-16 b） |  | -2215 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-低温-双星照度周期 | 环双星行星（土星质量）：天空里有两个太阳，昼夜模型与其它星球不同 |
| 开普勒 1649 c（Kepler-1649 c） |  | -2214 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-温和-潮汐锁定 | 2020 年从 2017 年的旧数据里"找回"的行星：234 K、1.06 地球半径；时间观测线的预告 |
| 开普勒 186 f（Kepler-186 f） |  | -2205 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-低温-潮汐锁定 | 第一颗确认位于宜居带的类地尺寸行星（2014）；129.9 天、1.17 地球半径 |
| 开普勒 22 b（Kepler-22 b） |  | -2212 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-温和-海世界 | 开普勒第一个宜居带行星（2011）：2.1 地球半径、279 K |
| 开普勒 37 b（Kepler-37 b） |  | -2219 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | II | 无氧-高温-岩石 | 0.31 地球半径，比水星略大的最小行星；微行星采样教学 |
| 开普勒 442 b（Kepler-442 b） |  | -2211 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-低温-岩石 | 宜居带指数最高的行星之一（1.34 地球半径、241 K） |
| 开普勒 452 b（Kepler-452 b） |  | -2200 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-温和-老年恒星辐射 | 方案点名的 UV 阶段目标：60 亿年的老年类太阳恒星，公转一年 385 天；III 型遗迹 |
| 开普勒 62 f（Kepler-62 f） |  | -2210 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | III | 无氧-低温-海洋候选 | 267 天周期、208 K：五行星系统最外、最像地球的一颗 |
| PSR B1257+12 b（尸鬼） · Draugr (PSR B1257+12 b) |  | -2225 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | IV | 脉冲星辐射-无恒星光照-极寒 | 人类发现的第一颗系外行星（1992，绕脉冲星）：本层的标志性天体，宇宙历起点 |
| 船帆座脉冲星（Vela Pulsar (PSR B0833-45)） |  | -2228 | 不适用（恒星/气态/黑洞等，非登陆体） | III | 中子星辐射-强磁场 | 离得最近、最亮的脉冲星：UHV 阶段中子素线的最近产地 |

## 第 5 层：深空星系区（7 / UHV / 距地球 2,000 ~ 100,000 光年（仍在银河系内））

银盘与银心：脉冲星、恒星级黑洞、微类星体与分子云；戴森球三阶段与宇宙模拟器。本层 14 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 弓箭手星团（Arches Cluster） | Cluster |  | ~25,000 ly |  |  |  |  |  |
| 蟹状星云脉冲星（Crab Pulsar (PSR B0531+21)） | Pulsar |  | ~6,500 ly |  |  |  |  |  |
| 天鹅座 X-1（Cygnus X-1） | BlackHole |  | ~7,200 ly |  |  |  |  |  |
| 船底座 η（Eta Carinae） | Star |  | ~7,500 ly |  |  |  |  |  |
| 大湮灭者（Great Annihilator (1E 1740.7-2942)） | BlackHole |  | ~23,000 ly |  |  |  |  |  |
| GRS 1915+105 | BlackHole |  | ~40,000 ly |  |  |  |  |  |
| 开普勒 70 b（Kepler-70 b） | Planet | KOI-55 B | 4015 ly | 0.2401 | 0.75900000 | 0.44 | 7778 K eq | 2011 |
| 开普勒 70 c（Kepler-70 c） | Planet | KOI-55 B | 4015 ly | 0.3429 | 0.86700000 | 0.655 | 6911 K eq | 2011 |
| PSR J1748-2446ad | Pulsar |  | ~18,000 ly |  |  |  |  |  |
| PSR B1620-26 b（玛土撒拉） · Methuselah (PSR B1620-26 b) | Planet | PSR B1620-26 |  |  | 13.30000000 | 795 |  | 2003 |
| S2 星（S2） | Star |  | ~26,000 ly | 16.05 years |  |  |  |  |
| 人马座 A*（Sagittarius A*） | BlackHole |  | ~26,000 ly |  |  |  |  |  |
| 人马座 B2（Sagittarius B2） | Nebula |  | ~27,000 ly |  |  |  |  |  |
| Westerlund 1 | Cluster |  | ~15,000 ly |  |  |  |  |  |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 弓箭手星团（Arches Cluster） |  | -2314 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 高密度恒星-强辐射-无行星 | 银河系里最密的星团：戴森结构"群建"的第二个参照体 |
| 蟹状星云脉冲星（Crab Pulsar (PSR B0531+21)） |  | -2306 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 中子星辐射-强磁场 | 1054 年客星的残骸：中子星物质（中子素）的唯一现实出处，M 谱系的起点 |
| 天鹅座 X-1（Cygnus X-1） |  | -2307 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 吸积盘辐射-X 射线-潮汐 | 第一个被确认的恒星级黑洞（霍金-索恩之赌）：重力的实物教学，吸积盘采能线 |
| 船底座 η（Eta Carinae） |  | -2308 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 超高温-双星风-不稳定 | 下一次超新星候选：麦哲伦式观测 vs. 干预的伦理线（时间观测仪只观测，不干预） |
| 大湮灭者（Great Annihilator (1E 1740.7-2942)） |  | -2316 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 事件视界-反物质喷流 | 正负电子湮灭线最亮的源：暗物质与反物质线的现实锚点 |
| GRS 1915+105 |  | -2317 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 超光速喷流-辐射-潮汐 | 第一次观测到"表观超光速"喷流的银河系内天体：相对论喷流的教学样本 |
| 开普勒 70 b（Kepler-70 b） |  | -2310 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | IV | 残余恒星辐射-极高温 | 又称 KOI-55 b（档案里用的是这个编号）：绕 B 型亚矮星运行的残骸行星，母星已经死过一次，时间观测线的直接目标 |
| 开普勒 70 c（Kepler-70 c） |  | -2311 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | IV | 残余恒星辐射-极高温 | 与 b 一起在 5.76 小时和 8.23 小时绕一圈：被吞噬边缘 |
| PSR J1748-2446ad |  | -2318 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 中子星辐射-强磁场-超快自转 | 每秒 716 圈：中子星物质线里"转速上限"的实测点 |
| PSR B1620-26 b（玛土撒拉） · Methuselah (PSR B1620-26 b) |  | -2303 | 未配置（登陆时按所属层的套件 + signature 生成，方案 5.4） | IV | 球状星团辐射-极寒-双星照度 | 126 亿年的行星，绕脉冲星+白矮星双星：本层最老的星体，时间观测仪的主标定对象。档案里没有它的距离与周期，所以数值来自发现公告而不是 pscomppars 表 |
| S2 星（S2） |  | -2305 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 极端速度-潮汐-辐射 | 绕人马座 A* 的恒星：广义相对论红移的实测星，轨道力学课程的游戏化样本 |
| 人马座 A*（Sagittarius A*） |  | -2304 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 事件视界-潮汐力-辐射 | 银河系中心黑洞：M6 摘星与 M7 宇宙模拟器的能量源，也是"观测维度"的核心 |
| 人马座 B2（Sagittarius B2） |  | -2315 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 分子云-强辐射-化学腐蚀 | 银心旁最大的分子云：挥发分与有机化学线的旗舰采集体 |
| Westerlund 1 |  | -2312 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 高密度恒星-辐射-无行星 | 银河系内最密集的年轻星团：戴森结构"群建"的设定来源 |

## 第 6 层：超深空星系区（8 / UHV+ / 距地球 10 万 ~ 1 亿光年（本星系群 → 室女座星系团））

本星系群与近邻星系团：麦哲伦云、仙女座、M87；遗迹 IV 型。本层 13 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 触须星系（Antennae Galaxies (NGC 4038/4039)） | Galaxy |  | ~45 million ly |  |  |  |  |  |
| 半人马座 A（Centaurus A (NGC 5128)） | Galaxy |  | ~12 million ly |  |  |  |  |  |
| 大麦哲伦云（Large Magellanic Cloud） | Galaxy |  | ~163,000 ly |  |  |  |  |  |
| 草帽星系（Sombrero Galaxy (M104)） | Galaxy |  | ~31 million ly |  |  |  |  |  |
| 仙女座星系（Andromeda Galaxy (M31)） | Galaxy |  | ~2.5 million ly |  |  |  |  |  |
| 三角座星系（Triangulum Galaxy (M33)） | Galaxy |  | ~2.7 million ly |  |  |  |  |  |
| 涡状星系（Whirlpool Galaxy (M51)） | Galaxy |  | ~31 million ly |  |  |  |  |  |
| 室女座 A（M87） · Messier 87 | Galaxy |  | ~55 million ly |  |  |  |  |  |
| M87*（M87* (Powehi)） | BlackHole |  | ~55 million ly |  |  |  |  |  |
| 小麦哲伦云（Small Magellanic Cloud） | Galaxy |  | ~200,000 ly |  |  |  |  |  |
| SN 1987A | SupernovaRemnant |  | ~168,000 ly |  |  |  |  |  |
| 蜘蛛星云（Tarantula Nebula） | Nebula |  | ~160,000 ly |  |  |  |  |  |
| 室女座星系团（Virgo Cluster） | Cluster |  | ~65 million ly |  |  |  |  |  |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 触须星系（Antennae Galaxies (NGC 4038/4039)） |  | -2359 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系碰撞-星爆-辐射 | 正在碰撞的两座星系：M10 之后"超星系工程"的力学与美学样本 |
| 半人马座 A（Centaurus A (NGC 5128)） |  | -2356 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 射电源-尘埃带-辐射 | 最近的活动星系核：喷流与合成射电的观测对象，射电望远镜阵列的标定源 |
| 大麦哲伦云（Large Magellanic Cloud） |  | -2350 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-无大气-辐射 | 银河系最大的卫星星系：功能上相当于"第二张地图"，星系门 M8 的第一个落点 |
| 草帽星系（Sombrero Galaxy (M104)） |  | -2358 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-尘埃环 | 侧视的尘埃环 + 十亿太阳质量黑洞：星系核工程的参照尺度 |
| 仙女座星系（Andromeda Galaxy (M31)） |  | -2354 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-无大气-未知 | 最近的大型螺旋星系，正在以 110 km/s 接近：M10 超星系之网的第一个节点 |
| 三角座星系（Triangulum Galaxy (M33)） |  | -2355 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-无大气 | 本星系群第三大星系；可能是仙女座的卫星，也是星系网的第三个节点 |
| 涡状星系（Whirlpool Galaxy (M51)） |  | -2357 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-相互作用 | 人类画出的第一个螺旋星云（1845）：星系形态学的教科书目标 |
| 室女座 A（M87） · Messier 87 |  | -2360 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-相对论喷流 | 室女座团的中心巨椭圆星系：星系团的引力锚点 |
| M87*（M87* (Powehi)） |  | -2361 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 事件视界-相对论喷流 | 人类拍到的第一个黑洞：宇宙模拟器的输入源之一，也是 M7 的实证基础 |
| 小麦哲伦云（Small Magellanic Cloud） |  | -2353 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系尺度-无大气-辐射 | 低金属丰度星系：与银河系不同的金属分布，是"另一种地质"的样本 |
| SN 1987A |  | -2352 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 冲击波-辐射-重元素 | 近代唯一肉眼可见的超新星；重元素与中子星诞生的观测现场（时间观测线的旗舰） |
| 蜘蛛星云（Tarantula Nebula） |  | -2351 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星云内-辐射-气体 | 本星系群里最猛的恒星工厂：气体采集与恒星工程的最新材料 |
| 室女座星系团（Virgo Cluster） |  | -2362 | 不适用（恒星/气态/黑洞等，非登陆体） | IV | 星系团尺度-星系际介质 | 本超星系团的中心：M10 超星系之网真正成网的地方 |

## 第 7 层：未知星系（8 / UHV+ / 距地球 1 亿 ~ 465 亿光年（其中 10 个在 100 亿光年以上））

星系门之后的层：远古星系、类星体、宇宙网、微波背景；只观测，不登陆。两个例外不按距离分层——奥陌陌与鲍里索夫是"来访者"，它们就在太阳系里。本层 15 个星体。

### 天体与实测数据（NASA）

| 天体 | 类型 | 宿主/光谱型 | 距地球 | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2I/鲍里索夫（2I/Borisov） | InterstellarObject |  |  |  |  |  |  | 2019-08-30 (Gennadiy Borisov) |
| 宇宙微波背景（Cosmic Microwave Background） | CMB |  | ~46.5 billion ly |  |  |  |  |  |
| 埃雅仁迪尔（晨星） · Earendel (WHL0137-LS) | Star |  | ~12.9 billion ly |  |  |  |  | Hubble (2022), JWST confirmed |
| GN-z11 | Galaxy |  | ~13.4 billion ly |  |  |  |  | Hubble |
| GRB 090423 | Transient |  | ~13.0 billion ly |  |  |  |  |  |
| 武仙-北冕座长城（Hercules-Corona Borealis Great Wall） | CosmicWeb |  |  |  |  |  |  |  |
| GW150914 | GravitationalWave |  | ~1.3 billion ly |  |  |  |  |  |
| JADES-GS-z14-0 | Galaxy |  | ~13.5 billion ly |  |  |  |  | JWST (2024) |
| MoM-z14 | Galaxy |  | ~13.5 billion ly |  |  |  |  | JWST (2025, spectroscopic) |
| 奥陌陌（'Oumuamua (1I/2017 U1)） | InterstellarObject |  |  |  |  |  |  | 2017-10-19 (Pan-STARRS1) |
| 类星体 3C 273（3C 273） | Quasar |  | ~2.4 billion ly |  |  |  |  |  |
| 类星体 J0313-1806（J0313-1806） | Quasar |  | ~13.0 billion ly |  |  |  |  |  |
| 类星体 J1342+0928（ULAS J1342+0928） | Quasar |  | ~13.1 billion ly |  |  |  |  |  |
| Ton 618 | Quasar |  | ~10.4 billion ly |  |  |  |  |  |
| UHZ1 | Galaxy |  | ~13.2 billion ly |  |  |  |  |  |

### 设计字段（维度 / 矿脉 / 遗迹 / 环境）

| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| 2I/鲍里索夫（2I/Borisov） |  | -2410 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 彗星活动-星际来源 | 第二颗星际来客、第一颗星际彗星：与奥陌陌互为对照（一个像岩石，一个像彗星） |
| 宇宙微波背景（Cosmic Microwave Background） |  | -2405 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-不可达 | 宇宙的第一张照片：创世引擎（M9）的输入数据，也是"未知层"的边界本身 |
| 埃雅仁迪尔（晨星） · Earendel (WHL0137-LS) |  | -2402 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 引力透镜观测级 | 借星系团透镜看到的最远恒星：不是我们到了那里，是光绕了路 |
| GN-z11 |  | -2400 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-不可达 | 哈勃找到的极远星系：距离的极限在被望远镜而不是火箭改写的第一课 |
| GRB 090423 |  | -2416 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-伽马射线暴 | 最古老的伽马暴之一：宇宙模拟器里"事件"输入的最远端样本 |
| 武仙-北冕座长城（Hercules-Corona Borealis Great Wall） |  | -2406 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-超结构 | 宇宙网里最大的已知结构：M10 之后"继续玩下去"的地图 |
| GW150914 |  | -2412 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-时空涟漪 | 人类第一次"听见"时空：引力波观测与时间观测仪的物理依据 |
| JADES-GS-z14-0 |  | -2401 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-不可达 | JWST 2024 年的纪录：最远的已知星系，也是"未知层"不断外推的证据 |
| MoM-z14 |  | -2415 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-不可达 | 2025 年的纪录：比 JADES-GS-z14-0 更远一点，说明"未知层"的上界一直在被推动 |
| 奥陌陌（'Oumuamua (1I/2017 U1)） |  | -2409 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 无动力-非引力加速 | 第一个来自太阳系外的天体：它证明"别的地方有东西"，未知层的开场白 |
| 类星体 3C 273（3C 273） |  | -2403 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-相对论喷流 | 第一个被认出来的类星体：从"射电源"到"黑洞吸积盘"的认知转折 |
| 类星体 J0313-1806（J0313-1806） |  | -2417 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-超大质量 | 最古老的类星体：宇宙才 6.7 亿年时就有十亿太阳质量的黑洞，这是"种子黑洞"问题的原始出处 |
| 类星体 J1342+0928（ULAS J1342+0928） |  | -2418 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-超大质量 | 第一个被发现的 z>7 类星体：时间观测仪"由近及远"序列的锚点 |
| Ton 618 |  | -2404 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-超大质量 | 已知最大的黑洞之一：宇宙模拟器的量程上限参照 |
| UHZ1 |  | -2413 | 不适用（恒星/气态/黑洞等，非登陆体） | 未知 | 观测级-不可达 | 早期星系里已在"长大"的黑洞：种子黑洞理论的关键证据 |

## 生成时的校验

生成器在渲染前跑三条不变量：每个天体都必须解析到 NASA 数据；太阳系的可登陆体矿脉数必须落在 5..8（方案 5.4）；规划维度 ID 不得重复。本层最大的矿脉数是 8（同太阳系上限 8）。本次结果：

- 全部通过。

