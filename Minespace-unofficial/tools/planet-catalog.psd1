# The planet catalog - every celestial body this pack plans to model, its layer, its stage and the
# data that describes it.
#
# The split of responsibility, which is the whole point of this table:
#
#   * THIS FILE owns what is a *design decision*: the name, the layer, the voltage stage, the vein
#     region or signature, the ruin (Kardashov) class, the environment, the dimension id.
#   * fetch-planet-data.ps1 owns what is a *measurement*: mass, radius, orbit, temperature,
#     atmosphere. Nothing in this file states a measurement about a real body; `Lookup` says where
#     to read it and the numbers arrive in nasa-planet-data.json.
#   * planet-veins.psd1 owns the ore. A body here names the vein key(s) it uses there, and the
#     renderer refuses a body whose veins are missing or whose count falls outside the plan's 5..8.
#
# Layers are the plan's own seven (section 1.1), and each one carries the stage and voltage the plan
# gives it (table 2-1). `Lookup` grammar:
#
#   main:<PLANET>            a column of the comparative NSSDC fact sheet
#   sheet:<page>             a per-body NSSDC fact sheet (atmosphere block included)
#   sat:<family>:<Moon>      the NSSDC satellite fact sheet for that family
#   mooncol:<page>:<Moon>    the satellite table inside a body sheet (Phobos, Charon)
#   exo:<host>:<planet>      the NASA Exoplanet Archive `pscomppars` table
#   fixed                     values typed here, with the NASA page they came from in `Source`

@{
    Meta = @{
        Title = 'GTCEu 星系整合包 - 星球与星体总表'
        Source = 'NASA NSSDC 行星事实表 + NASA 系外行星档案（Exoplanet Archive）+ 各天体 NASA 页面'
        Note = @(
            '方案口径：太阳系 12 个登陆天体 + 近 110 个深空目标。本表给 20 个太阳系天体（全部是整合包',
            '已有的，不新增太阳系维度）与 86 个深空目标，共 106 个；太阳系里的 12 个标 Priority=1 的',
            '就是方案阶段一/二/三的那一批。',
            '每个层 10~20 个（owner 2026-10-15 的减量决定）。规则：每个恒星系只留 1~2 个代表天体——',
            '方案点名的、实例里已有维度的、以及宜居带或科学史上"第一个"的优先留；被裁掉的 50 个天体',
            '整段放在文件末尾的 BodiesCut 里（含各自的 NASA 数据与备注），想恢复就搬回 Bodies。',
            '分层按"距地球的距离"划，每层一个量级：L2 4~16 ly、L3 16~100 ly、L4 100~2,000 ly、',
            'L5 2,000 ly~100 kly（银河系内）、L6 100 kly~100 Mly、L7 100 Mly~465 亿 ly。',
            '注意：方案文档没有给任何距离数字——七个层只有名字（近邻/中距/远距/深空/超深空/未知）与',
            '"阶段↔空间范围"的对应，上面这些分带是本表定的，天体按实测距离严格归带，不留例外',
            '（唯二的例外是奥陌陌与鲍里索夫：它们是星际来客，就在太阳系里，但按性质归入未知层）。',
            '电压与层级按方案表 2-1；矿脉按方案 5.4（每体 5~8 条、变体组合、不滥增矿物）。'
        )
        DimPlan = @(
            '太阳系原生：GC -28..-31，GS -1005..-1032、-1126..-1129、-1234、-1338（实测，不动）',
            '太阳系不再新开维度：四个气态巨行星沿用 GS 既有对象（木星 -1026），不占新 ID',
            '近邻星系区 -2000..-2099，中距 -2100..-2199，远距 -2200..-2299',
            '深空 -2300..-2349，超深空 -2350..-2399，未知/观测 -2400..-2449',
            '方案的 -100/-110/-120 段只有 10 个 ID 宽，装不下，所以保留它的分段结构、把宽度放大；',
            '以上区段与实测占用（GC/GS）无重叠。'
        )
    }

    Layers = @{
        sol = @{
            Index = 1; Display = '太阳系'; Zh = '太阳系'
            Stage = '0-3'; Voltage = '蒸汽~EV'; Distance = '距地球 0.0000026 ~ 0.00042 光年（40 AU 以内）'
            Theme = '母星与整合包已有的星球、卫星与天体带（不新增维度）；唯一可以不靠火箭到达的层'
            Real = '1 个恒星系：8 行星 + 5 矮行星 + 400 多颗卫星'
            InGame = '20 个天体：19 个可登陆 + 地球。四个气态巨行星不单列——它们是 GS 既有的地图对象，阶段五的气态采集挂在它们身上，不是可登陆天体'
            Ratio = '1:1'
            DimRange = '-1338..-28'
        }
        nearby = @{
            Index = 2; Display = 'Nearby Systems'; Zh = '近邻星系区'
            Stage = 4; Voltage = 'IV'; Distance = '距地球 4 ~ 16 光年'
            Theme = '第一批恒星际目标：比邻星、巴纳德星、天仓五、ε 波江座；遗迹 I 型开始出现'
            Real = '这个半径内只有几十个恒星系——真实体量小到可以逐颗建'
            InGame = '16 个天体，来自 13 个恒星系'
            Ratio = '≈1:3（代表性采样）'
            DimRange = '-2099..-2000'
        }
        mid = @{
            Index = 3; Display = 'Mid Systems'; Zh = '中距星系区'
            Stage = 5; Voltage = 'LuV~ZPM'; Distance = '距地球 16 ~ 100 光年'
            Theme = 'TRAPPIST-1 与 Gliese 系；气态行星采集上线；遗迹 II 型（戴森球残骸）'
            Real = '这个半径内约数千个恒星系'
            InGame = '14 个天体，来自 8 个恒星系'
            Ratio = '≈1:150'
            DimRange = '-2199..-2100'
        }
        far = @{
            Index = 4; Display = 'Far Systems'; Zh = '远距星系区'
            Stage = 6; Voltage = 'UV'; Distance = '距地球 100 ~ 2,000 光年'
            Theme = '开普勒场：Kepler-452b 与同类；时间观测仪上线。2,000 光年以内的极端天体也落在这一段（参宿四、船帆座脉冲星、PSR B1257+12 的脉冲星行星）'
            Real = '这个半径内恒星数量级 10^8'
            InGame = '14 个天体，来自 14 个恒星系（一系一体，含一个脉冲星系统）'
            Ratio = '≈1:10^7'
            DimRange = '-2299..-2200'
        }
        deep = @{
            Index = 5; Display = 'Deep Space'; Zh = '深空星系区'
            Stage = 7; Voltage = 'UHV'; Distance = '距地球 2,000 ~ 100,000 光年（仍在银河系内）'
            Theme = '银盘与银心：脉冲星、恒星级黑洞、微类星体与分子云；戴森球三阶段与宇宙模拟器'
            Real = '银河系银盘与银心：10^10 ~ 10^11 颗恒星'
            InGame = '14 个天体 + 银盘/银心两个可扫描星场'
            Ratio = '≈1:10^9'
            DimRange = '-2349..-2300'
        }
        ultra = @{
            Index = 6; Display = 'Ultra-deep'; Zh = '超深空星系区'
            Stage = 8; Voltage = 'UHV+'; Distance = '距地球 10 万 ~ 1 亿光年（本星系群 → 室女座星系团）'
            Theme = '本星系群与近邻星系团：麦哲伦云、仙女座、M87；遗迹 IV 型'
            Real = '本星系群与室女座团：约 10^12 颗恒星、10^3 ~ 10^4 个星系'
            InGame = '13 个天体 + 星系团星场'
            Ratio = '≈1:10^11'
            DimRange = '-2399..-2350'
        }
        unknown = @{
            Index = 7; Display = 'Unknown'; Zh = '未知星系'
            Stage = 8; Voltage = 'UHV+'; Distance = '距地球 1 亿 ~ 465 亿光年（其中 10 个在 100 亿光年以上）'
            Theme = '星系门之后的层：远古星系、类星体、宇宙网、微波背景；只观测，不登陆。两个例外不按距离分层——奥陌陌与鲍里索夫是"来访者"，它们就在太阳系里'
            Real = '可观测宇宙：约 2×10^12 个星系，恒星最多 10^24 颗'
            InGame = '15 个观测目标 + 宇宙网星场（只读）'
            Ratio = '≈1:10^23'
            DimRange = '-2449..-2400'
        }
    }

    Bodies = @{

        # ============================== 第一层：太阳系 ==============================
        # 24 个星体，全部是整合包里**已经有**的：地球、月球、水星、金星、火星、火卫一、火卫二、
        # 小行星带、谷神星、木卫一~四、土卫二、土卫六、天卫五、海卫一、冥王星、妊神星、柯伊伯带，
        # 加上四个气态巨行星（GS 地图上已有，不新增维度）。
        # 刻意不做的：太阳、灶神星、火卫以外的土星系/天卫系卫星、冥卫一、鸟神星、阋神星等 14 个
        # "要新开维度"的太阳系星体——owner 2026-10-15 决定不新增太阳系星体。

        earth = @{ Zh='地球'; En='Earth'; Type='Planet'; Layer='sol'; Lookup='sheet:earthfact:Earth'; Native=0; Dim=0
            Ruin='0'; Env='宜居'; Priority=1; Vein='overworld'
            Note='母星；蒸汽到 EV 的全部产线都在这里，资源闭环原则的基准层。矿脉不由本表管理：主世界用的是 GT 自带的那几张表，planet-veins.psd1 刻意不碰它' }

        moon = @{ Zh='月球'; En='Moon'; Type='Moon'; Layer='sol'; Lookup='sheet:moonfact:Moon'; Native=-28; Dim=-28
            Ruin='0'; Env='真空-无氧-昼夜温差'; Priority=1
            Note='矿脉金标准（7 条，零重复）；方案里 M1 一步之遥的落点' }

        mercury = @{ Zh='水星'; En='Mercury'; Type='Planet'; Layer='sol'; Lookup='sheet:mercuryfact:Mercury'; Native=-1005; Dim=-1005
            Ruin='0'; Env='高温-无氧-太阳辐射'; Priority=1
            Note='无氧化高金属与陨石冲击成因的铁镍铂族矿脉（方案 4.2 的地质设定卡示例）' }

        venus = @{ Zh='金星'; En='Venus'; Type='Planet'; Layer='sol'; Lookup='sheet:venusfact:Venus'
            Native='-31,-1006'; Dim='-31,-1006'; Vein='venus,gs_venus'
            Ruin='0'; Env='高温-高压-硫酸云-腐蚀'; Priority=1
            Note='两个维度（GC 与 GS 各一）合成一个天体；高温硫化物与 solar 脉是它的招牌' }

        mars = @{ Zh='火星'; En='Mars'; Type='Planet'; Layer='sol'; Lookup='sheet:marsfact:Mars'; Native=-29; Dim=-29
            Ruin='I'; Env='低压-无氧-低温-尘暴'; Priority=1
            Note='氧化铁地表与古水流沉积；desh/sulfur 脉专属，GS 新世界引擎地形' }

        phobos = @{ Zh='火卫一'; En='Phobos'; Type='Moon'; Layer='sol'; Lookup='moonnames:marsfact:Phobos:Satellites of Mars'; Native=-1012; Dim=-1012
            Ruin='0'; Env='真空-无氧-微重力'; Priority=1
            Note='潮汐锁定的撞击碎屑体；矿脉走月面岩基组' }

        deimos = @{ Zh='火卫二'; En='Deimos'; Type='Moon'; Layer='sol'; Lookup='moonnames:marsfact:Deimos:Satellites of Mars'; Native=-1013; Dim=-1013
            Ruin='0'; Env='真空-无氧-微重力'; Priority=1
            Note='火星外侧小卫星；低重力着陆成本，早期铱锇来源之一' }

        asteroids = @{ Zh='小行星带'; En='Asteroid belt'; Type='AsteroidBelt'; Layer='sol'; Lookup='fixed'; Native=-30; Dim=-30
            Ruin='I'; Env='真空-无氧-微重力'; Priority=1
            Source='https://science.nasa.gov/solar-system/asteroids/'
            Data=@{ 'Region'='2.2-3.2 AU'; 'Population'='>1.3 million known'; 'Total mass'='~4% of the Moon'
                    'Composition'='C-type carbonaceous / S-type silicate / M-type metallic' }
            Note='零重力维度；platinum 与 naquadah 两条稀有脉是来这里的原因' }

        ceres = @{ Zh='谷神星'; En='Ceres'; Type='DwarfPlanet'; Layer='sol'; Lookup='fixed'; Native=-1007; Dim=-1007
            Ruin='0'; Env='低压-无氧-低温'; Priority=0
            Source='https://science.nasa.gov/dwarf-planets/ceres/'
            Data=@{ 'Mean radius (km)'='469.7'; 'Mass (1024 kg)'='0.000938'; 'Distance from Sun'='2.77 AU'
                    'Orbital period'='4.6 years'; 'Diameter'='~940 km'; 'Discovered'='1801' }
            Note='唯一在带内的矮行星；dolomite 脉 + 盐水冰火山地质' }

        io = @{ Zh='木卫一'; En='Io'; Type='Moon'; Layer='sol'; Lookup='sat:jovian:Io'; Native=-1014; Dim=-1014
            Ruin='0'; Env='强辐射-火山-无氧'; Priority=1
            Note='潮汐热驱动的火山硫系世界；sulfur 脉的招牌天体（方案 4.2 点名）' }

        europa = @{ Zh='木卫二'; En='Europa'; Type='Moon'; Layer='sol'; Lookup='sat:jovian:Europa'; Native=-1015; Dim=-1015
            Ruin='0'; Env='强辐射-冰面-无氧'; Priority=1
            Note='冰下海洋的咸水热液矿脉；冰下海洋升温与钻孔是它的专属机制' }

        ganymede = @{ Zh='木卫三'; En='Ganymede'; Type='Moon'; Layer='sol'; Lookup='sat:jovian:Ganymede'; Native=-1016; Dim=-1016
            Ruin='0'; Env='强辐射-稀薄氧-无氧可呼吸'; Priority=1
            Note='太阳系最大卫星、唯一有磁场的卫星：采样之旅的终点' }

        callisto = @{ Zh='木卫四'; En='Callisto'; Type='Moon'; Layer='sol'; Lookup='sat:jovian:Callisto'; Native=-1022; Dim=-1022
            Ruin='0'; Env='强辐射-冰岩混合-无氧'; Priority=0
            Note='辐射最少的木星系卫星：玩家第一个安全的木星系基地' }

        enceladus = @{ Zh='土卫二'; En='Enceladus'; Type='Moon'; Layer='sol'; Lookup='sat:saturnian:Enceladus'; Native=-1017; Dim=-1017
            Ruin='0'; Env='无氧-低温-间歇喷泉'; Priority=0
            Note='南极喷泉直接采样的水体；盐-碳酸盐脉与硫脉共存' }

        titan = @{ Zh='土卫六'; En='Titan'; Type='Moon'; Layer='sol'; Lookup='sat:saturnian:Titan'; Native=-1018; Dim=-1018
            Ruin='I'; Env='低温-富氮大气-甲烷雨-无氧'; Priority=1
            Note='唯一有稠密大气与液体循环的卫星；低温烃类与氮系矿脉（方案 4.2 点名）' }

        miranda = @{ Zh='天卫五'; En='Miranda'; Type='Moon'; Layer='sol'; Lookup='sat:uranian:Miranda'; Native=-1024; Dim=-1024
            Ruin='0'; Env='无氧-低温-微重力'; Priority=0
            Note='被撕裂重组过的拼贴地表，悬崖落差 20 km；LuV 钽铌矿的前哨' }

        triton = @{ Zh='海卫一'; En='Triton'; Type='Moon'; Layer='sol'; Lookup='sat:neptunian:Triton'; Native=-1021; Dim=-1021
            Ruin='0'; Env='极低温-氮气间歇泉-逆行轨道'; Priority=0
            Note='逆行轨道的俘获柯伊伯天体；氮-甲烷冰与有机脉' }

        pluto = @{ Zh='冥王星'; En='Pluto'; Type='DwarfPlanet'; Layer='sol'; Lookup='sheet:plutofact:Pluto'; Native=-1008; Dim=-1008
            Ruin='I'; Env='极低温-稀薄氮气-无氧'; Priority=0
            Note='氮冰对流平原与有机焦油砂；小行星组稀有脉 + 旗舰天体' }

        haumea = @{ Zh='妊神星'; En='Haumea'; Type='DwarfPlanet'; Layer='sol'; Lookup='fixed'; Native=-1023; Dim=-1023
            Ruin='0'; Env='极低温-无氧-高速自转'; Priority=0
            Source='https://science.nasa.gov/dwarf-planets/haumea/'
            Data=@{ 'Mean radius (km)'='780'; 'Mass (1024 kg)'='0.004006'; 'Distance from Sun'='43.1 AU (mean)'
                    'Orbital period'='284 years'; 'Diameter'='~1,600 x 1,100 km'; 'Discovered'='2004' }
            Note='3.9 小时自转一周的椭球体，带环；小行星组稀有脉' }

        kuiper_belt = @{ Zh='柯伊伯带'; En='Kuiper belt'; Type='AsteroidBelt'; Layer='sol'; Lookup='fixed'; Native=-1009; Dim=-1009
            Ruin='I'; Env='极低温-无氧-微重力'; Priority=0
            Source='https://science.nasa.gov/solar-system/kuiper-belt/'
            Data=@{ 'Region'='30-50 AU'; 'Population'='hundreds of thousands >100 km'; 'Composition'='ice, rock, organic'
                    'Named for'='Gerard Kuiper' }
            Note='零重力维度；稀有金属与海王星外天体采样区' }

        # ============================== 第二层：近邻星系区 ==============================
        # 35 个目标，全部在 16 光年以内。方案阶段三的样板星系在这里。

        proxima_b = @{ Zh='比邻星 b'; En='Proxima Centauri b'; Type='Planet'; Layer='nearby'
            Lookup='exo:Proxima Cen:Proxima Cen b'; Native=-1025; Dim=-1025; Ruin='I'
            Env='无氧-低压-红矮星耀斑辐射'; Priority=2
            Note='方案的阶段三样板（4.4.3）：最老、被重熔次数最多的地壳，signature=zircon（锆石）' }

        proxima_d = @{ Zh='比邻星 d'; En='Proxima Centauri d'; Type='Planet'; Layer='nearby'
            Lookup='exo:Proxima Cen:Proxima Cen d'; Native=0; Dim=-2002; Ruin='I'
            Env='无氧-辐射-潮汐锁定'
            Note='质量仅 0.26 地球的亚地球，2025 年确认；最近的行星际落脚点' }

        barnarda_c = @{ Zh='巴纳德 b（现 Barnarda C）'; En="Barnard's Star b"; Type='Planet'; Layer='nearby'
            Lookup="exo:Barnard's star:Barnard b"; Native=-1030; Dim=-1030; Ruin='I'
            Env='无氧-低温-红矮星辐射'
            Note='GS 的"Barnarda C"是虚构名，方案 1.1 要求全部用现实天体名：把 -1030 映射到真实的 Barnard b；signature=onyx 保留' }

        barnarda_c1 = @{ Zh='巴纳德 c（现 Barnarda C1）'; En="Barnard's Star c"; Type='Planet'; Layer='nearby'
            Lookup="exo:Barnard's star:Barnard c"; Native=-1031; Dim=-1031; Ruin='I'
            Env='无氧-低温-辐射'
            Note='映射 -1031 → Barnard c；signature=伟晶岩（铌钽镓），快速冷却的岩浆分异' }

        barnarda_c2 = @{ Zh='巴纳德 d（现 Barnarda C2）'; En="Barnard's Star d"; Type='Planet'; Layer='nearby'
            Lookup="exo:Barnard's star:Barnard d"; Native=-1032; Dim=-1032; Ruin='II'
            Env='无氧-低温-辐射'
            Note='映射 -1032 → Barnard d；signature=遗迹矿藏（vinteum/opal/jasper，人工路线）' }

        tauceti_f = @{ Zh='天仓五 f'; En='Tau Ceti f'; Type='Planet'; Layer='nearby'; Lookup='fixed'
            Native=-1338; Dim=-1338; Ruin='I'; Env='无氧-低温-高压'
            Source='https://science.nasa.gov/universe/exoplanets/'
            Data=@{ 'Host star'='Tau Ceti (G8 V)'; 'Distance'='11.9 ly'; 'Period'='~636 days'; 'Mass'='~6.6 Earths'
                    'Status'='candidate (Tuomi 2017), not in the archive' }
            Note='GS 的 Tau Ceti F 维度 -1338 保留；signature=碳酸盐蒸发岩（witherite/celestine/rhodocrosite）+ 压钻石脉' }

        eps_eri_b = @{ Zh='天苑四 b'; En='Epsilon Eridani b'; Type='Planet'; Layer='nearby'
            Lookup='exo:eps Eri:eps Eri b'; Native=0; Dim=-2007; Ruin='I'
            Env='气态巨行星-强辐射带'
            Note='10.5 光年的年轻（~8 亿年）系统：气态采集与"行星系仍在形成"的教学样本' }

        teegarden_b = @{ Zh='蒂加登星 b'; En="Teegarden's Star b"; Type='Planet'; Layer='nearby'
            Lookup="exo:Teegarden's Star:Teegarden's Star b"; Native=0; Dim=-2008; Ruin='I'
            Env='无氧-温和-辐射'
            Note='12.5 光年的 M7 矮星宜居带行星；本层最像"第二个家"的一颗' }

        ross128_b = @{ Zh='罗斯 128 b'; En='Ross 128 b'; Type='Planet'; Layer='nearby'
            Lookup='exo:Ross 128:Ross 128 b'; Native=0; Dim=-2011; Ruin='I'
            Env='无氧-温和-辐射'
            Note='11 光年、几乎不耀斑的红矮星行星：安静恒星系的宜居带对照' }

        gj273_b = @{ Zh='鲁坦星 b'; En="Luyten's Star b"; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 273:GJ 273 b'; Native=0; Dim=-2012; Ruin='I'
            Env='无氧-温和-辐射'
            Note='12.35 光年的温和超地球；近邻区的第二个矿业据点' }

        gj1061_c = @{ Zh='GJ 1061 c'; En='GJ 1061 c'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 1061:GJ 1061 c'; Native=0; Dim=-2018; Ruin='I'
            Env='无氧-温和-辐射'; Note='6.7 天周期，宜居带边缘；本层的中距落脚点' }

        gj887_d = @{ Zh='GJ 887 d'; En='GJ 887 d'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 887:GJ 887 d'; Native=0; Dim=-2022; Ruin='I'
            Env='无氧-温和-辐射'; Note='2026 年新公布；50.8 天周期，宜居带正中' }

        gj1002_b = @{ Zh='GJ 1002 b'; En='GJ 1002 b'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 1002:GJ 1002 b'; Native=0; Dim=-2023; Ruin='I'
            Env='无氧-温和-辐射'; Note='15.8 光年，本层最远的目标；潮汐锁定的双行星系统' }

        wolf1061_c = @{ Zh='沃尔夫 1061 c'; En='Wolf 1061 c'; Type='Planet'; Layer='nearby'
            Lookup='exo:Wolf 1061:Wolf 1061 c'; Native=0; Dim=-2026; Ruin='I'
            Env='无氧-温和-辐射'; Note='17.9 天周期，宜居带内；近邻区最早被讨论的宜居候选' }

        sirius_b = @{ Zh='天狼星 B'; En='Sirius B'; Type='WhiteDwarf'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2028; Ruin='I'; Env='高温-强辐射-极端重力'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='8.6 ly'; 'Type'='DA2 white dwarf'; 'Mass'='1.02 Suns'; 'Diameter'='~11,600 km'
                    'Surface temperature'='~25,000 K'; 'Discovered'='1862' }
            Note='白矮星：不是矿，是极高密度的物质样本；这里是"极端物质"线的第一个台阶' }

        alpha_cen_a = @{ Zh='南门二 A'; En='Alpha Centauri A'; Type='Star'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2029; Ruin='-'; Env='高温-辐射'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='4.37 ly'; 'Type'='G2 V'; 'Mass'='1.08 Suns'; 'Binary period'='79.9 years' }
            Note='与太阳同型的最近恒星：戴森云的第一个现实候选（M6 摘星的舞台）' }

        # ============================== 第三层：中距星系区 ==============================
        # 23 个目标，16 ~ 100 光年。TRAPPIST-1 七颗行星整条收录。

        trappist1_b = @{ Zh='TRAPPIST-1 b'; En='TRAPPIST-1 b'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 b'; Native=0; Dim=-2100; Ruin='I'
            Env='无氧-高温-潮汐锁定'
            Note='40 光年的超冷矮星系统，七颗都是地球大小；b 是最内、最热的一颗' }

        trappist1_c = @{ Zh='TRAPPIST-1 c'; En='TRAPPIST-1 c'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 c'; Native=0; Dim=-2101; Ruin='I'
            Env='无氧-高温-潮汐锁定'; Note='与 b 成轨道共振；金星式的失控温室样本' }

        trappist1_d = @{ Zh='TRAPPIST-1 d'; En='TRAPPIST-1 d'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 d'; Native=0; Dim=-2102; Ruin='I'
            Env='无氧-温和-潮汐锁定'; Note='0.39 地球质量的亚地球；本层最轻的登陆目标' }

        trappist1_e = @{ Zh='TRAPPIST-1 e'; En='TRAPPIST-1 e'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 e'; Native=0; Dim=-2103; Ruin='II'
            Env='无氧-温和-潮汐锁定'; Priority=2
            Note='方案的第二个样板候选：可能有液态水与全球海洋；II 型遗迹（戴森球残骸）的主舞台' }

        trappist1_f = @{ Zh='TRAPPIST-1 f'; En='TRAPPIST-1 f'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 f'; Native=0; Dim=-2104; Ruin='I'
            Env='无氧-低温-潮汐锁定'; Note='冰壳海洋（H2O 占比可能过半）' }

        trappist1_g = @{ Zh='TRAPPIST-1 g'; En='TRAPPIST-1 g'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 g'; Native=0; Dim=-2105; Ruin='I'
            Env='无氧-低温-潮汐锁定'; Note='极低温冰世界；挥发分分馏的样本' }

        trappist1_h = @{ Zh='TRAPPIST-1 h'; En='TRAPPIST-1 h'; Type='Planet'; Layer='mid'
            Lookup='exo:TRAPPIST-1:TRAPPIST-1 h'; Native=0; Dim=-2106; Ruin='I'
            Env='无氧-极低温-潮汐锁定'; Note='0.33 地球质量、18.8 天；共振链最外端的冰球' }

        gj581_c = @{ Zh='Gliese 581 c'; En='Gliese 581 c'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 581:GJ 581 c'; Native=0; Dim=-2108; Ruin='I'
            Env='无氧-高温-温室失控'; Note='第一个被宣布"宜居"的系外行星，后来被推翻：教科书级的纠错案例' }

        gj667c_c = @{ Zh='Gliese 667 C c'; En='GJ 667 C c'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 667 C:GJ 667 C c'; Native=0; Dim=-2111; Ruin='I'
            Env='无氧-温和-辐射'; Note='28 天周期、宜居带内；三合星系统里的稳定轨道（L4/L5 问题）' }

        gj876_b = @{ Zh='Gliese 876 b'; En='Gliese 876 b'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 876:GJ 876 b'; Native=0; Dim=-2113; Ruin='I'
            Env='气态-辐射带'; Note='15.2 光年的共振锁链；b 是 2.3 木星质量的巨行星' }

        hd219134_b = @{ Zh='HD 219134 b'; En='HD 219134 b'; Type='Planet'; Layer='mid'
            Lookup='exo:HD 219134:HD 219134 b'; Native=0; Dim=-2116; Ruin='I'
            Env='无氧-高温-岩石'; Note='21.3 光年的超级地球；太阳系外岩石行星的密度基准点' }

        cnc55_e = @{ Zh='55 巨蟹座 e'; En='55 Cancri e'; Type='Planet'; Layer='mid'
            Lookup='exo:55 Cnc:55 Cnc e'; Native=0; Dim=-2119; Ruin='I'
            Env='无氧-熔岩-超高温'
            Note='41 光年的熔岩世界：白天 1958 K、0.74 天公转；岩浆海直接开采（熔岩冶金线）' }

        peg51_b = @{ Zh='飞马座 51 b'; En='51 Pegasi b'; Type='Planet'; Layer='mid'
            Lookup='exo:51 Peg:51 Peg b'; Native=0; Dim=-2120; Ruin='I'
            Env='气态-超高温-强风'
            Note='第一颗被发现的系外行星（1995，诺奖）：本层必到的纪念地，图鉴第一章' }

        hd40307_g = @{ Zh='HD 40307 g'; En='HD 40307 g'; Type='Planet'; Layer='mid'
            Lookup='exo:HD 40307:HD 40307 g'; Native=0; Dim=-2121; Ruin='I'
            Env='无氧-温和-岩石'; Note='42 光年、7.1 地球质量、255 K：中等质量宜居带的样本' }

        # 124 光年超过中距层的 100 光年上限，按"距地球"归入远距层（归属由 Layer 决定，文件里的
        # 位置只是书写顺序）。
        k2_18_b = @{ Zh='K2-18 b'; En='K2-18 b'; Type='Planet'; Layer='far'
            Lookup='exo:K2-18:K2-18 b'; Native=0; Dim=-2223; Ruin='I'
            Env='氢气大气-高压-海洋候选'
            Note='124 光年：大气里检出过水汽与含碳分子；"海世界"线的第一个实际目标' }

        # ============================== 第四层：远距星系区 ==============================
        # 23 个目标，100 ~ 3000 光年。开普勒场在这里，时间观测仪的观测对象也在这里。

        kepler452_b = @{ Zh='开普勒 452 b'; En='Kepler-452 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-452:Kepler-452 b'; Native=0; Dim=-2200; Ruin='III'
            Env='无氧-温和-老年恒星辐射'; Priority=2
            Note='方案点名的 UV 阶段目标：60 亿年的老年类太阳恒星，公转一年 385 天；III 型遗迹' }

        kepler186_f = @{ Zh='开普勒 186 f'; En='Kepler-186 f'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-186:Kepler-186 f'; Native=0; Dim=-2205; Ruin='III'
            Env='无氧-低温-潮汐锁定'
            Note='第一颗确认位于宜居带的类地尺寸行星（2014）；129.9 天、1.17 地球半径' }

        kepler62_f = @{ Zh='开普勒 62 f'; En='Kepler-62 f'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-62:Kepler-62 f'; Native=0; Dim=-2210; Ruin='III'
            Env='无氧-低温-海洋候选'; Note='267 天周期、208 K：五行星系统最外、最像地球的一颗' }

        kepler442_b = @{ Zh='开普勒 442 b'; En='Kepler-442 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-442:Kepler-442 b'; Native=0; Dim=-2211; Ruin='III'
            Env='无氧-低温-岩石'; Note='宜居带指数最高的行星之一（1.34 地球半径、241 K）' }

        kepler22_b = @{ Zh='开普勒 22 b'; En='Kepler-22 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-22:Kepler-22 b'; Native=0; Dim=-2212; Ruin='III'
            Env='无氧-温和-海世界'; Note='开普勒第一个宜居带行星（2011）：2.1 地球半径、279 K' }

        kepler1649_c = @{ Zh='开普勒 1649 c'; En='Kepler-1649 c'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-1649:Kepler-1649 c'; Native=0; Dim=-2214; Ruin='III'
            Env='无氧-温和-潮汐锁定'
            Note='2020 年从 2017 年的旧数据里"找回"的行星：234 K、1.06 地球半径；时间观测线的预告' }

        kepler16_b = @{ Zh='开普勒 16 b'; En='Kepler-16 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-16:Kepler-16 b'; Native=0; Dim=-2215; Ruin='III'
            Env='无氧-低温-双星照度周期'
            Note='环双星行星（土星质量）：天空里有两个太阳，昼夜模型与其它星球不同' }

        kepler138_c = @{ Zh='开普勒 138 c'; En='Kepler-138 c'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-138:Kepler-138 c'; Native=0; Dim=-2217; Ruin='II'
            Env='高压-水世界'; Note='密度 2.3 g/cm3 的"水世界"：一半以上是水，不是岩石' }

        kepler37_b = @{ Zh='开普勒 37 b'; En='Kepler-37 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-37:Kepler-37 b'; Native=0; Dim=-2219; Ruin='II'
            Env='无氧-高温-岩石'; Note='0.31 地球半径，比水星略大的最小行星；微行星采样教学' }

        boyajian_star = @{ Zh='博亚吉安星'; En="Boyajian's Star (KIC 8462852)"; Type='Star'; Layer='far'
            Lookup='fixed'; Native=0; Dim=-2222; Ruin='未知'
            Env='高温-辐射-非周期变暗'
            Source='https://science.nasa.gov/universe/exoplanets/'
            Data=@{ 'Distance'='~1,470 ly'; 'Type'='F3 V'; 'Famous for'='aperiodic dimming up to 22%'
                    'Explained by'='dust, not a megastructure' }
            Note='"戴森球候选星"的原始样本，答案是尘埃：遗迹学里唯一被否定过的 II 型案例，图鉴彩蛋' }

        # ============================== 第五层：深空星系区 ==============================
        # 14 个目标，3 ~ 100 kly。脉冲星、黑洞与极端物质；戴森球与宇宙模拟器的舞台。

        # 1,957 光年：差 43 光年够不到深空层的 2,000 光年下限，按距离归入远距层。
        psr1257_b = @{ Zh='PSR B1257+12 b（尸鬼）'; En='Draugr (PSR B1257+12 b)'; Type='Planet'; Layer='far'
            Lookup='exo:PSR B1257+12:PSR B1257+12 b'; Native=0; Dim=-2225; Ruin='IV'
            Env='脉冲星辐射-无恒星光照-极寒'
            Note='人类发现的第一颗系外行星（1992，绕脉冲星）：本层的标志性天体，宇宙历起点' }

        psr1620_b = @{ Zh='PSR B1620-26 b（玛土撒拉）'; En='Methuselah (PSR B1620-26 b)'; Type='Planet'; Layer='deep'
            Lookup='fixed'; Native=0; Dim=-2303; Ruin='IV'
            Env='球状星团辐射-极寒-双星照度'
            Source='https://science.nasa.gov/mission/hubble/'
            Data=@{ 'Distance'='~12,400 ly'; 'Host'='M4 globular cluster'; 'Orbital period'='~100 years'
                    'Mass'='2.5 Jupiters'; 'Age'='12.6 billion years' }
            Note='126 亿年的行星，绕脉冲星+白矮星双星：本层最老的星体，时间观测仪的主标定对象。档案里没有它的距离与周期，所以数值来自发现公告而不是 pscomppars 表' }

        sgr_a_star = @{ Zh='人马座 A*'; En='Sagittarius A*'; Type='BlackHole'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2304; Ruin='IV'; Env='事件视界-潮汐力-辐射'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~26,000 ly'; 'Mass'='4.3 million Suns'; 'Type'='supermassive black hole'
                    'Imaged'='2022 (EHT)' }
            Note='银河系中心黑洞：M6 摘星与 M7 宇宙模拟器的能量源，也是"观测维度"的核心' }

        s2_star = @{ Zh='S2 星'; En='S2'; Type='Star'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2305; Ruin='IV'; Env='极端速度-潮汐-辐射'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~26,000 ly'; 'Orbital period'='16.05 years'; 'Closest approach'='~120 AU'
                    'Speed at closest'='~3% of light speed' }
            Note='绕人马座 A* 的恒星：广义相对论红移的实测星，轨道力学课程的游戏化样本' }

        crab_pulsar = @{ Zh='蟹状星云脉冲星'; En='Crab Pulsar (PSR B0531+21)'; Type='Pulsar'; Layer='deep'
            Lookup='fixed'; Native=0; Dim=-2306; Ruin='IV'; Env='中子星辐射-强磁场'
            Source='https://science.nasa.gov/universe/neutron-stars/'
            Data=@{ 'Distance'='~6,500 ly'; 'Spin period'='33 milliseconds'; 'Supernova'='SN 1054'
                    'Nebula'='Crab Nebula (M1)' }
            Note='1054 年客星的残骸：中子星物质（中子素）的唯一现实出处，M 谱系的起点' }

        cygnus_x1 = @{ Zh='天鹅座 X-1'; En='Cygnus X-1'; Type='BlackHole'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2307; Ruin='IV'; Env='吸积盘辐射-X 射线-潮汐'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~7,200 ly'; 'Mass'='21 Suns'; 'Type'='stellar-mass black hole'
                    'Companion'='HDE 226868 (blue supergiant)' }
            Note='第一个被确认的恒星级黑洞（霍金-索恩之赌）：重力的实物教学，吸积盘采能线' }

        eta_carinae = @{ Zh='船底座 η'; En='Eta Carinae'; Type='Star'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2308; Ruin='IV'; Env='超高温-双星风-不稳定'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='~7,500 ly'; 'Type'='luminous blue variable binary'; 'Mass'='~100 Suns each'
                    'Event'='Great Eruption 1837-1856' }
            Note='下一次超新星候选：麦哲伦式观测 vs. 干预的伦理线（时间观测仪只观测，不干预）' }

        # 548 光年：低于深空层 2,000 光年的下限，按距离归入远距层。
        betelgeuse = @{ Zh='参宿四'; En='Betelgeuse'; Type='Star'; Layer='far'; Lookup='fixed'
            Native=0; Dim=-2224; Ruin='III'; Env='高温-辐射-变星光度'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='~548 ly'; 'Type'='red supergiant (M1-2 Ia-ab)'; 'Mass'='~16-19 Suns'
                    'Radius'='~700 times the Sun' }
            Note='肉眼可见的红超巨星：戴森云工程的现实参照（规模感教学）' }

        kepler70_b = @{ Zh='开普勒 70 b'; En='Kepler-70 b'; Type='Planet'; Layer='deep'
            Lookup='exo:KOI-55:KOI-55 b'; Native=0; Dim=-2310; Ruin='IV'
            Env='残余恒星辐射-极高温'
            Note='又称 KOI-55 b（档案里用的是这个编号）：绕 B 型亚矮星运行的残骸行星，母星已经死过一次，时间观测线的直接目标' }

        kepler70_c = @{ Zh='开普勒 70 c'; En='Kepler-70 c'; Type='Planet'; Layer='deep'
            Lookup='exo:KOI-55:KOI-55 c'; Native=0; Dim=-2311; Ruin='IV'
            Env='残余恒星辐射-极高温'; Note='与 b 一起在 5.76 小时和 8.23 小时绕一圈：被吞噬边缘' }

        westerlund_1 = @{ Zh='Westerlund 1'; En='Westerlund 1'; Type='Cluster'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2312; Ruin='IV'; Env='高密度恒星-辐射-无行星'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='~15,000 ly'; 'Type'='young massive super star cluster'; 'Stars'='hundreds of thousands'
                    'Notable'='many red supergiants' }
            Note='银河系内最密集的年轻星团：戴森结构"群建"的设定来源' }

        # 960 光年：同上，按距离归入远距层。
        vela_pulsar = @{ Zh='船帆座脉冲星'; En='Vela Pulsar (PSR B0833-45)'; Type='Pulsar'; Layer='far'
            Lookup='fixed'; Native=0; Dim=-2228; Ruin='III'; Env='中子星辐射-强磁场'
            Source='https://science.nasa.gov/universe/neutron-stars/'
            Data=@{ 'Distance'='~960 ly'; 'Spin period'='89 milliseconds'; 'Age'='~11,000 years'
                    'Notable'='brightest persistent radio pulsar' }
            Note='离得最近、最亮的脉冲星：UHV 阶段中子素线的最近产地' }

        # ---- 深空层的补位：2,000 ~ 100,000 光年这一段之前只有 9 个天体，太稀 ----

        arches_cluster = @{ Zh='弓箭手星团'; En='Arches Cluster'; Type='Cluster'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2314; Ruin='IV'; Env='高密度恒星-强辐射-无行星'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='~25,000 ly'; 'Type'='young massive cluster'; 'Notable'='densest known star cluster in the Milky Way'
                    'Stars'='~1,000 massive stars in a 1 ly core' }
            Note='银河系里最密的星团：戴森结构"群建"的第二个参照体' }

        sgr_b2 = @{ Zh='人马座 B2'; En='Sagittarius B2'; Type='Nebula'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2315; Ruin='IV'; Env='分子云-强辐射-化学腐蚀'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Distance'='~27,000 ly'; 'Type'='giant molecular cloud'; 'Mass'='3 million Suns'
                    'Notable'='largest molecular cloud near the Galactic Center, rich in organic molecules' }
            Note='银心旁最大的分子云：挥发分与有机化学线的旗舰采集体' }

        great_annihilator = @{ Zh='大湮灭者'; En='Great Annihilator (1E 1740.7-2942)'; Type='BlackHole'
            Layer='deep'; Lookup='fixed'; Native=0; Dim=-2316; Ruin='IV'; Env='事件视界-反物质喷流'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~23,000 ly'; 'Type'='stellar-mass black hole binary (microquasar)'
                    'Notable'='brightest source of 511 keV positron annihilation in the sky' }
            Note='正负电子湮灭线最亮的源：暗物质与反物质线的现实锚点' }

        grs1915 = @{ Zh='GRS 1915+105'; En='GRS 1915+105'; Type='BlackHole'; Layer='deep'; Lookup='fixed'
            Native=0; Dim=-2317; Ruin='IV'; Env='超光速喷流-辐射-潮汐'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~40,000 ly'; 'Type'='microquasar (black hole + companion)'
                    'Mass'='~12 Suns'; 'Notable'='first galactic source with apparent superluminal jets' }
            Note='第一次观测到"表观超光速"喷流的银河系内天体：相对论喷流的教学样本' }

        psr_j1748 = @{ Zh='PSR J1748-2446ad'; En='PSR J1748-2446ad'; Type='Pulsar'; Layer='deep'
            Lookup='fixed'; Native=0; Dim=-2318; Ruin='IV'; Env='中子星辐射-强磁场-超快自转'
            Source='https://science.nasa.gov/universe/neutron-stars/'
            Data=@{ 'Distance'='~18,000 ly'; 'Spin period'='1.396 milliseconds (716 Hz)'
                    'Notable'='fastest-spinning pulsar known' }
            Note='每秒 716 圈：中子星物质线里"转速上限"的实测点' }

        # ============================== 第六层：超深空星系区 ==============================
        # 13 个目标，163 kly ~ 100 Mly。本星系群与近邻星系团；观测级为主，两个有登陆设定。

        lmc = @{ Zh='大麦哲伦云'; En='Large Magellanic Cloud'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2350; Ruin='IV'; Env='星系尺度-无大气-辐射'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~163,000 ly'; 'Type'='Magellanic spiral (SB(s)m)'; 'Diameter'='~32,000 ly'
                    'Satellite of'='Milky Way' }
            Note='银河系最大的卫星星系：功能上相当于"第二张地图"，星系门 M8 的第一个落点' }

        tarantula_nebula = @{ Zh='蜘蛛星云'; En='Tarantula Nebula'; Type='Nebula'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2351; Ruin='IV'; Env='星云内-辐射-气体'
            Source='https://science.nasa.gov/mission/hubble/'
            Data=@{ 'Distance'='~160,000 ly'; 'Type'='H II region'; 'Diameter'='~650 ly'
                    'Notable'='most active star-forming region in the Local Group' }
            Note='本星系群里最猛的恒星工厂：气体采集与恒星工程的最新材料' }

        sn_1987a = @{ Zh='SN 1987A'; En='SN 1987A'; Type='SupernovaRemnant'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2352; Ruin='IV'; Env='冲击波-辐射-重元素'
            Source='https://science.nasa.gov/mission/hubble/'
            Data=@{ 'Distance'='~168,000 ly'; 'Type'='core-collapse supernova remnant'; 'Exploded'='February 1987'
                    'Notable'='first supernova visible to the naked eye since 1604' }
            Note='近代唯一肉眼可见的超新星；重元素与中子星诞生的观测现场（时间观测线的旗舰）' }

        smc = @{ Zh='小麦哲伦云'; En='Small Magellanic Cloud'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2353; Ruin='IV'; Env='星系尺度-无大气-辐射'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~200,000 ly'; 'Type'='dwarf irregular galaxy'; 'Diameter'='~18,900 ly'
                    'Satellite of'='Milky Way' }
            Note='低金属丰度星系：与银河系不同的金属分布，是"另一种地质"的样本' }

        m31 = @{ Zh='仙女座星系'; En='Andromeda Galaxy (M31)'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2354; Ruin='IV'; Env='星系尺度-无大气-未知'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~2.5 million ly'; 'Type'='barred spiral (SA(s)b)'; 'Diameter'='~200,000 ly'
                    'Collision'='with the Milky Way in ~4.5 billion years' }
            Note='最近的大型螺旋星系，正在以 110 km/s 接近：M10 超星系之网的第一个节点' }

        m33 = @{ Zh='三角座星系'; En='Triangulum Galaxy (M33)'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2355; Ruin='IV'; Env='星系尺度-无大气'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~2.7 million ly'; 'Type'='unbarred spiral'; 'Diameter'='~60,000 ly'
                    'Notable'='third largest in the Local Group' }
            Note='本星系群第三大星系；可能是仙女座的卫星，也是星系网的第三个节点' }

        centaurus_a = @{ Zh='半人马座 A'; En='Centaurus A (NGC 5128)'; Type='Galaxy'; Layer='ultra'
            Lookup='fixed'; Native=0; Dim=-2356; Ruin='IV'; Env='射电源-尘埃带-辐射'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~12 million ly'; 'Type'='lenticular / elliptical with dust lane (S0 pec)'
                    'Notable'='nearest active galactic nucleus with radio jets' }
            Note='最近的活动星系核：喷流与合成射电的观测对象，射电望远镜阵列的标定源' }

        m51 = @{ Zh='涡状星系'; En='Whirlpool Galaxy (M51)'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2357; Ruin='IV'; Env='星系尺度-相互作用'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~31 million ly'; 'Type'='grand-design spiral'; 'Notable'='interacting with NGC 5195' }
            Note='人类画出的第一个螺旋星云（1845）：星系形态学的教科书目标' }

        m104 = @{ Zh='草帽星系'; En='Sombrero Galaxy (M104)'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2358; Ruin='IV'; Env='星系尺度-尘埃环'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~31 million ly'; 'Type'='unbarred spiral'; 'Notable'='100-billion-solar-mass bulge'
                    'Black hole'='~1 billion Suns' }
            Note='侧视的尘埃环 + 十亿太阳质量黑洞：星系核工程的参照尺度' }

        antennae = @{ Zh='触须星系'; En='Antennae Galaxies (NGC 4038/4039)'; Type='Galaxy'; Layer='ultra'
            Lookup='fixed'; Native=0; Dim=-2359; Ruin='IV'; Env='星系碰撞-星爆-辐射'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~45 million ly'; 'Type'='colliding spiral pair'; 'Collision began'='~600 million years ago'
                    'Notable'='prototype of a starburst galaxy' }
            Note='正在碰撞的两座星系：M10 之后"超星系工程"的力学与美学样本' }

        m87 = @{ Zh='室女座 A（M87）'; En='Messier 87'; Type='Galaxy'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2360; Ruin='IV'; Env='星系尺度-相对论喷流'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~55 million ly'; 'Type'='supergiant elliptical (E0)'; 'Diameter'='~120,000 ly'
                    'Notable'='host of the first imaged black hole, 1,500 ly plasma jet' }
            Note='室女座团的中心巨椭圆星系：星系团的引力锚点' }

        m87_star = @{ Zh='M87*'; En='M87* (Powehi)'; Type='BlackHole'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2361; Ruin='IV'; Env='事件视界-相对论喷流'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Distance'='~55 million ly'; 'Mass'='6.5 billion Suns'; 'Imaged'='2019 (EHT)'
                    'Notable'='first black hole ever photographed' }
            Note='人类拍到的第一个黑洞：宇宙模拟器的输入源之一，也是 M7 的实证基础' }

        virgo_cluster = @{ Zh='室女座星系团'; En='Virgo Cluster'; Type='Cluster'; Layer='ultra'; Lookup='fixed'
            Native=0; Dim=-2362; Ruin='IV'; Env='星系团尺度-星系际介质'
            Source='https://science.nasa.gov/universe/galaxies/'
            Data=@{ 'Distance'='~65 million ly'; 'Galaxies'='~1,300-2,000'; 'Diameter'='~15 million ly'
                    'Notable'='center of the Local Supercluster' }
            Note='本超星系团的中心：M10 超星系之网真正成网的地方' }

        # ============================== 第七层：未知星系 ==============================
        # 12 个目标。这一层只观测、不登陆，全部挂在时间观测仪与宇宙模拟器上。

        gn_z11 = @{ Zh='GN-z11'; En='GN-z11'; Type='Galaxy'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2400; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/mission/hubble/'
            Data=@{ 'Redshift'='z = 11.09'; 'Light travel distance'='~13.4 billion ly'; 'Age of the light'='~400 million years after the Big Bang'
                    'Found by'='Hubble' }
            Note='哈勃找到的极远星系：距离的极限在被望远镜而不是火箭改写的第一课' }

        jades_gs_z14_0 = @{ Zh='JADES-GS-z14-0'; En='JADES-GS-z14-0'; Type='Galaxy'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2401; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/mission/webb/'
            Data=@{ 'Redshift'='z = 14.32'; 'Light travel distance'='~13.5 billion ly'; 'Found by'='JWST (2024)'
                    'Notable'='most distant galaxy then known' }
            Note='JWST 2024 年的纪录：最远的已知星系，也是"未知层"不断外推的证据' }

        earendel = @{ Zh='埃雅仁迪尔（晨星）'; En='Earendel (WHL0137-LS)'; Type='Star'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2402; Ruin='未知'; Env='引力透镜观测级'
            Source='https://science.nasa.gov/mission/webb/'
            Data=@{ 'Redshift'='z = 6.2'; 'Light travel distance'='~12.9 billion ly'; 'Found by'='Hubble (2022), JWST confirmed'
                    'Notable'='most distant star ever seen, magnified by a gravitational lens' }
            Note='借星系团透镜看到的最远恒星：不是我们到了那里，是光绕了路' }

        quasar_3c273 = @{ Zh='类星体 3C 273'; En='3C 273'; Type='Quasar'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2403; Ruin='未知'; Env='观测级-相对论喷流'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Redshift'='z = 0.158'; 'Distance'='~2.4 billion ly'; 'Notable'='first quasar identified (1963)'
                    'Luminosity'='~4 trillion times the Sun' }
            Note='第一个被认出来的类星体：从"射电源"到"黑洞吸积盘"的认知转折' }

        ton618 = @{ Zh='Ton 618'; En='Ton 618'; Type='Quasar'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2404; Ruin='未知'; Env='观测级-超大质量'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Redshift'='z = 2.219'; 'Distance'='~10.4 billion ly'; 'Black hole mass'='~40-66 billion Suns'
                    'Notable'='one of the most massive black holes known' }
            Note='已知最大的黑洞之一：宇宙模拟器的量程上限参照' }

        cmb = @{ Zh='宇宙微波背景'; En='Cosmic Microwave Background'; Type='CMB'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2405; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Age'='380,000 years after the Big Bang'; 'Temperature'='2.725 K today, 3000 K then'
                    'Comoving distance'='~46.5 billion ly'; 'Mapped by'='COBE (1992), WMAP, Planck' }
            Note='宇宙的第一张照片：创世引擎（M9）的输入数据，也是"未知层"的边界本身' }

        great_wall = @{ Zh='武仙-北冕座长城'; En='Hercules-Corona Borealis Great Wall'; Type='CosmicWeb'
            Layer='unknown'; Lookup='fixed'; Native=0; Dim=-2406; Ruin='未知'; Env='观测级-超结构'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Distance'='~10 billion ly'; 'Size'='~10 billion ly across'
                    'Found in'='gamma-ray burst distribution (2013)'
                    'Notable'='largest known structure in the observable universe' }
            Note='宇宙网里最大的已知结构：M10 之后"继续玩下去"的地图' }

        ouamuamua = @{ Zh='奥陌陌'; En="'Oumuamua (1I/2017 U1)"; Type='InterstellarObject'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2409; Ruin='未知'; Env='无动力-非引力加速'
            Source='https://science.nasa.gov/solar-system/'
            Data=@{ 'Distance'='inside the solar system (it is a visitor, not a distant object)'
                    'Discovered'='2017-10-19 (Pan-STARRS1)'; 'Length'='~100-1,000 m'; 'Origin'='interstellar'
                    'Notable'='first known interstellar object, unexplained non-gravitational acceleration' }
            Note='第一个来自太阳系外的天体：它证明"别的地方有东西"，未知层的开场白' }

        borisov = @{ Zh='2I/鲍里索夫'; En='2I/Borisov'; Type='InterstellarObject'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2410; Ruin='未知'; Env='彗星活动-星际来源'
            Source='https://science.nasa.gov/solar-system/'
            Data=@{ 'Distance'='inside the solar system (it is a visitor, not a distant object)'
                    'Discovered'='2019-08-30 (Gennadiy Borisov)'; 'Core diameter'='~1 km'; 'Origin'='interstellar'
                    'Notable'='first confirmed interstellar comet' }
            Note='第二颗星际来客、第一颗星际彗星：与奥陌陌互为对照（一个像岩石，一个像彗星）' }

        gw150914 = @{ Zh='GW150914'; En='GW150914'; Type='GravitationalWave'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2412; Ruin='未知'; Env='观测级-时空涟漪'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Detected'='2015-09-14, announced 2016-02-11 (LIGO)'; 'Distance'='~1.3 billion ly'
                    'Merged'='two black holes of ~36 and ~29 Suns'; 'Output'='3 Suns of energy as gravitational waves' }
            Note='人类第一次"听见"时空：引力波观测与时间观测仪的物理依据' }

        # ---- 100 亿光年以上的补位：这一档之前只有 5 个，末端太空 ----
        # 这些天体的距离来自各自的发现公告（NASA/ESA），档案层还没有逐对象页面，取数脚本会去
        # 各自的页面试着留证据句，留不到也不会把天体丢掉。

        uhz1 = @{ Zh='UHZ1'; En='UHZ1'; Type='Galaxy'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2413; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Redshift'='z = 10.07'; 'Light travel distance'='~13.2 billion ly'
                    'Notable'='X-ray detected growing black hole in an early galaxy (Chandra/Webb, 2023)'
                    'Black hole mass'='~10-100 million Suns' }
            Note='早期星系里已在"长大"的黑洞：种子黑洞理论的关键证据' }

        mom_z14 = @{ Zh='MoM-z14'; En='MoM-z14'; Type='Galaxy'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2415; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/mission/webb/'
            Data=@{ 'Redshift'='z = 14.44'; 'Light travel distance'='~13.5 billion ly'
                    'Found by'='JWST (2025, spectroscopic)'; 'Notable'='most distant galaxy confirmed at the time' }
            Note='2025 年的纪录：比 JADES-GS-z14-0 更远一点，说明"未知层"的上界一直在被推动' }

        grb090423 = @{ Zh='GRB 090423'; En='GRB 090423'; Type='Transient'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2416; Ruin='未知'; Env='观测级-伽马射线暴'
            Source='https://science.nasa.gov/mission/swift/'
            Data=@{ 'Redshift'='z = 8.2'; 'Light travel distance'='~13.0 billion ly'
                    'Detected'='2009-04-23 (Swift)'; 'Notable'='oldest gamma-ray burst then known; the burst lasted ~10 seconds' }
            Note='最古老的伽马暴之一：宇宙模拟器里"事件"输入的最远端样本' }

        quasar_j0313 = @{ Zh='类星体 J0313-1806'; En='J0313-1806'; Type='Quasar'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2417; Ruin='未知'; Env='观测级-超大质量'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Redshift'='z = 7.64'; 'Light travel distance'='~13.0 billion ly'
                    'Black hole mass'='1.6 billion Suns'; 'Notable'='earliest known quasar (2021)' }
            Note='最古老的类星体：宇宙才 6.7 亿年时就有十亿太阳质量的黑洞，这是"种子黑洞"问题的原始出处' }

        quasar_j1342 = @{ Zh='类星体 J1342+0928'; En='ULAS J1342+0928'; Type='Quasar'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2418; Ruin='未知'; Env='观测级-超大质量'
            Source='https://science.nasa.gov/universe/black-holes/'
            Data=@{ 'Redshift'='z = 7.54'; 'Light travel distance'='~13.1 billion ly'
                    'Black hole mass'='800 million Suns'; 'Notable'='first quasar found beyond z = 7 (2017)' }
            Note='第一个被发现的 z>7 类星体：时间观测仪"由近及远"序列的锚点' }
    }

    # 裁掉的天体：不在 Bodies 里，因此不进总表、不占维度号；想恢复就把下面的整段搬回 Bodies。
    # 裁减规则：每个恒星系只留 1~2 个代表天体（方案点名的 / 已有维度的 / 宜居带或科学史上第一的优先）。
    BodiesCut = @{

        jupiter = @{ Zh='木星'; En='Jupiter'; Type='GasGiant'; Layer='sol'; Lookup='sheet:jupiterfact:Jupiter'; Native=-1026; Dim=0
            Ruin='0'; Env='无固体表面-强辐射-超高压'; Priority=0
            Note='既有：GS 的 -1026 是它的轨道/空间站维度。不再新开维度，气态采集走阶段五的轨道+大气机制' }

        saturn = @{ Zh='土星'; En='Saturn'; Type='GasGiant'; Layer='sol'; Lookup='sheet:saturnfact:Saturn'; Native=0; Dim=0
            Ruin='0'; Env='无固体表面-低温-环系'; Priority=0
            Note='既有：GS 地图对象（enableSaturn）。环系是水冰/挥发分露天矿区，不新增维度' }

        uranus = @{ Zh='天王星'; En='Uranus'; Type='GasGiant'; Layer='sol'; Lookup='sheet:uranusfact:Uranus'; Native=0; Dim=0
            Ruin='0'; Env='无固体表面-极低温-侧向自转'; Priority=0
            Note='既有：GS 地图对象。轴向倾斜 98 度，采集模型的昼夜参数要单独处理' }

        neptune = @{ Zh='海王星'; En='Neptune'; Type='GasGiant'; Layer='sol'; Lookup='sheet:neptunefact:Neptune'; Native=0; Dim=0
            Ruin='0'; Env='无固体表面-极低温-超音速风'; Priority=0
            Note='既有：GS 地图对象。太阳系最外的大气采集点，氦-3 与重氢储量最高' }

        proxima_c = @{ Zh='比邻星 c'; En='Proxima Centauri c'; Type='Planet'; Layer='nearby'
            Lookup='fixed'; Native=0; Dim=-2001; Ruin='I'; Env='无氧-低温-气态巨行星边缘'
            Source='https://science.nasa.gov/universe/exoplanets/proxima-centauri/'
            Data=@{ 'Host star'='Proxima Centauri (M5.5 V)'; 'Distance'='4.24 ly'; 'Period'='~1,900 days'
                    'Mass'='~7 Earths'; 'Status'='candidate, disputed 2022-2023' }
            Note='GS 有 enableProxima_C 开关但不可登陆；本表给它 -2001，作为气态边缘的轨道采集点' }

        barnard_e = @{ Zh='巴纳德 e'; En="Barnard's Star e"; Type='Planet'; Layer='nearby'
            Lookup="exo:Barnard's star:Barnard e"; Native=0; Dim=-2003; Ruin='I'
            Env='无氧-低温-辐射'
            Note='2025 年发现的第四颗；0.19 地球质量，最小的一颗，潮汐加热模型更极端' }

        tauceti_e = @{ Zh='天仓五 e'; En='Tau Ceti e'; Type='Planet'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2004; Ruin='I'; Env='无氧-接近宜居-辐射'
            Source='https://science.nasa.gov/universe/exoplanets/'
            Data=@{ 'Host star'='Tau Ceti (G8 V)'; 'Distance'='11.9 ly'; 'Period'='~163 days'; 'Mass'='~3.9 Earths'
                    'Status'='candidate (Tuomi 2017), not in the archive' }
            Note='NASA 档案未收录的候选体：数据取 Tuomi 2017 论文，标注为争议；矿脉走近邻基组' }

        tauceti_g = @{ Zh='天仓五 g'; En='Tau Ceti g'; Type='Planet'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2005; Ruin='I'; Env='无氧-低温-辐射'
            Source='https://science.nasa.gov/universe/exoplanets/'
            Data=@{ 'Host star'='Tau Ceti (G8 V)'; 'Distance'='11.9 ly'; 'Period'='~20 days'; 'Mass'='~1.7 Earths'
                    'Status'='candidate (Tuomi 2017), not in the archive' }
            Note='争议候选体；与 e/f 一起构成"同名星系里的另一半"教学样本：观测级、不建维度' }

        tauceti_h = @{ Zh='天仓五 h'; En='Tau Ceti h'; Type='Planet'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2006; Ruin='I'; Env='无氧-低温-辐射'
            Source='https://science.nasa.gov/universe/exoplanets/'
            Data=@{ 'Host star'='Tau Ceti (G8 V)'; 'Distance'='11.9 ly'; 'Period'='~49 days'; 'Mass'='~1.8 Earths'
                    'Status'='candidate (Tuomi 2017), not in the archive' }
            Note='争议候选体；观测级目标，时间观测仪的近距标定对象' }

        teegarden_c = @{ Zh='蒂加登星 c'; En="Teegarden's Star c"; Type='Planet'; Layer='nearby'
            Lookup="exo:Teegarden's Star:Teegarden's Star c"; Native=0; Dim=-2009; Ruin='I'
            Env='无氧-温和-辐射' ; Note='与 b 共振锁定；双行星系统的轨道力学样本' }

        teegarden_d = @{ Zh='蒂加登星 d'; En="Teegarden's Star d"; Type='Planet'; Layer='nearby'
            Lookup="exo:Teegarden's Star:Teegarden's Star d"; Native=0; Dim=-2010; Ruin='I'
            Env='无氧-低温-辐射'; Note='2024 年发现的第三颗；0.82 地球质量' }

        gj273_c = @{ Zh='鲁坦星 c'; En="Luyten's Star c"; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 273:GJ 273 c'; Native=0; Dim=-2013; Ruin='I'
            Env='无氧-高温-辐射'; Note='4.7 天周期，与 b 成 2:5 共振' }

        yz_cet_b = @{ Zh='鲸鱼座 YZ b'; En='YZ Ceti b'; Type='Planet'; Layer='nearby'
            Lookup='exo:YZ Cet:YZ Cet b'; Native=0; Dim=-2014; Ruin='I'
            Env='无氧-高温-耀斑'; Note='12 光年、三颗亚地球的紧凑系统' }

        yz_cet_c = @{ Zh='鲸鱼座 YZ c'; En='YZ Ceti c'; Type='Planet'; Layer='nearby'
            Lookup='exo:YZ Cet:YZ Cet c'; Native=0; Dim=-2015; Ruin='I'
            Env='无氧-高温-耀斑'; Note='3.06 天周期；潮汐锁定与耀斑环境的极端样本' }

        yz_cet_d = @{ Zh='鲸鱼座 YZ d'; En='YZ Ceti d'; Type='Planet'; Layer='nearby'
            Lookup='exo:YZ Cet:YZ Cet d'; Native=0; Dim=-2016; Ruin='I'
            Env='无氧-高温-耀斑'; Note='4.66 天周期；本层最"拥挤"的星系' }

        gj1061_b = @{ Zh='GJ 1061 b'; En='GJ 1061 b'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 1061:GJ 1061 b'; Native=0; Dim=-2017; Ruin='I'
            Env='无氧-高温-辐射'; Note='12 光年的 M5.5 矮星系统，三颗都在 1~1.8 地球质量' }

        gj1061_d = @{ Zh='GJ 1061 d'; En='GJ 1061 d'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 1061:GJ 1061 d'; Native=0; Dim=-2019; Ruin='I'
            Env='无氧-低温-辐射'; Note='13 天周期；三行星共振链的外侧' }

        gj887_b = @{ Zh='GJ 887 b'; En='GJ 887 b'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 887:GJ 887 b'; Native=0; Dim=-2020; Ruin='I'
            Env='无氧-高温-辐射'; Note='10.7 光年、长期稳定的红矮星（无耀斑记录）' }

        gj887_c = @{ Zh='GJ 887 c'; En='GJ 887 c'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 887:GJ 887 c'; Native=0; Dim=-2021; Ruin='I'
            Env='无氧-温和-辐射'; Note='21.8 天周期、6.5 地球质量；本层最宜居的候选之一' }

        gj1002_c = @{ Zh='GJ 1002 c'; En='GJ 1002 c'; Type='Planet'; Layer='nearby'
            Lookup='exo:GJ 1002:GJ 1002 c'; Native=0; Dim=-2024; Ruin='I'
            Env='无氧-温和-辐射'; Note='21.2 天周期，181 K；冰壳与大气演化样本' }

        wolf1061_b = @{ Zh='沃尔夫 1061 b'; En='Wolf 1061 b'; Type='Planet'; Layer='nearby'
            Lookup='exo:Wolf 1061:Wolf 1061 b'; Native=0; Dim=-2025; Ruin='I'
            Env='无氧-高温-辐射'; Note='13.8 光年的三行星系统，第一颗 4.9 天' }

        wolf1061_d = @{ Zh='沃尔夫 1061 d'; En='Wolf 1061 d'; Type='Planet'; Layer='nearby'
            Lookup='exo:Wolf 1061:Wolf 1061 d'; Native=0; Dim=-2027; Ruin='I'
            Env='无氧-低温-辐射'; Note='217 天周期、7.7 地球质量：本层的远轨道矿业点' }

        alpha_cen_b = @{ Zh='南门二 B'; En='Alpha Centauri B'; Type='Star'; Layer='nearby'; Lookup='fixed'
            Native=0; Dim=-2030; Ruin='-'; Env='高温-辐射'
            Source='https://science.nasa.gov/universe/stars/'
            Data=@{ 'Distance'='4.37 ly'; 'Type'='K1 V'; 'Mass'='0.91 Suns' }
            Note='红矮星线的能量源；与 A 的双星轨道是恒星工程的轨道力学样本' }

        gj581_b = @{ Zh='Gliese 581 b'; En='Gliese 581 b'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 581:GJ 581 b'; Native=0; Dim=-2107; Ruin='I'
            Env='无氧-高温-辐射'; Note='20.4 光年的经典系统；b 是 20 地球质量的热海王星' }

        gj581_e = @{ Zh='Gliese 581 e'; En='Gliese 581 e'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 581:GJ 581 e'; Native=0; Dim=-2109; Ruin='I'
            Env='无氧-高温-辐射'; Note='1.9 地球质量、3.1 天：最早期发现的低质量行星之一' }

        gj667c_b = @{ Zh='Gliese 667 C b'; En='Gliese 667 C b'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 667 C:GJ 667 C b'; Native=0; Dim=-2110; Ruin='I'
            Env='无氧-高温-辐射'; Note='23.6 光年的三合星系统，行星绕着最小的一颗转' }

        gj667c_e = @{ Zh='Gliese 667 C e'; En='GJ 667 C e'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 667 C:GJ 667 C e'; Native=0; Dim=-2112; Ruin='I'
            Env='无氧-低温-辐射'; Note='62 天周期；与 f/g 一起构成紧凑共振链' }

        gj876_c = @{ Zh='Gliese 876 c'; En='Gliese 876 c'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 876:GJ 876 c'; Native=0; Dim=-2114; Ruin='I'
            Env='气态-辐射带'; Note='与 b 成 2:1 共振；行星系稳定性的经典案例' }

        gj876_e = @{ Zh='Gliese 876 e'; En='Gliese 876 e'; Type='Planet'; Layer='mid'
            Lookup='exo:GJ 876:GJ 876 e'; Native=0; Dim=-2115; Ruin='I'
            Env='气态-辐射带'; Note='124 天、14.6 地球质量；共振链最外' }

        hd219134_c = @{ Zh='HD 219134 c'; En='HD 219134 c'; Type='Planet'; Layer='mid'
            Lookup='exo:HD 219134:HD 219134 c'; Native=0; Dim=-2117; Ruin='I'
            Env='无氧-高温-岩石'; Note='6.8 天周期，与 b 成 2:1 共振对' }

        hd219134_g = @{ Zh='HD 219134 g'; En='HD 219134 g'; Type='Planet'; Layer='mid'
            Lookup='exo:HD 219134:HD 219134 g'; Native=0; Dim=-2118; Ruin='I'
            Env='无氧-温和-岩石'; Note='94 天周期、339 K；本层的宜居带矿业节点' }

        kepler186_b = @{ Zh='开普勒 186 b'; En='Kepler-186 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-186:Kepler-186 b'; Native=0; Dim=-2201; Ruin='II'
            Env='无氧-高温-潮汐锁定'; Note='580 光年的 M1 矮星五行星系统；b 是最内的一颗' }

        kepler186_c = @{ Zh='开普勒 186 c'; En='Kepler-186 c'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-186:Kepler-186 c'; Native=0; Dim=-2202; Ruin='II'
            Env='无氧-高温-潮汐锁定'; Note='7.3 天周期；五行星链的第二环' }

        kepler186_d = @{ Zh='开普勒 186 d'; En='Kepler-186 d'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-186:Kepler-186 d'; Native=0; Dim=-2203; Ruin='II'
            Env='无氧-高温-潮汐锁定'; Note='13.3 天；2.5 地球质量' }

        kepler186_e = @{ Zh='开普勒 186 e'; En='Kepler-186 e'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-186:Kepler-186 e'; Native=0; Dim=-2204; Ruin='II'
            Env='无氧-温和-潮汐锁定'; Note='22.4 天；本层最接近宜居带的一环' }

        kepler62_b = @{ Zh='开普勒 62 b'; En='Kepler-62 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-62:Kepler-62 b'; Native=0; Dim=-2206; Ruin='II'
            Env='无氧-高温-岩石'; Note='1200 光年的 K2 矮星系统，五颗行星' }

        kepler62_c = @{ Zh='开普勒 62 c'; En='Kepler-62 c'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-62:Kepler-62 c'; Native=0; Dim=-2207; Ruin='II'
            Env='无氧-高温-岩石'; Note='0.54 地球半径：比火星还小的行星也能被地面设施开采' }

        kepler62_d = @{ Zh='开普勒 62 d'; En='Kepler-62 d'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-62:Kepler-62 d'; Native=0; Dim=-2208; Ruin='II'
            Env='无氧-高温-岩石'; Note='18.2 天、14 地球质量的超级地球' }

        kepler62_e = @{ Zh='开普勒 62 e'; En='Kepler-62 e'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-62:Kepler-62 e'; Native=0; Dim=-2209; Ruin='III'
            Env='无氧-温和-海洋候选'; Note='1.61 地球半径、270 K：宜居带里的海世界候选' }

        kepler1649_b = @{ Zh='开普勒 1649 b'; En='Kepler-1649 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-1649:Kepler-1649 b'; Native=0; Dim=-2213; Ruin='II'
            Env='无氧-高温-潮汐锁定'; Note='M 矮星系统里第一颗潮汐锁定的类地行星' }

        kepler138_b = @{ Zh='开普勒 138 b'; En='Kepler-138 b'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-138:Kepler-138 b'; Native=0; Dim=-2216; Ruin='II'
            Env='无氧-高温-岩石'; Note='0.64 地球半径、火星大小；密度只有地球的 60%' }

        kepler138_d = @{ Zh='开普勒 138 d'; En='Kepler-138 d'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-138:Kepler-138 d'; Native=0; Dim=-2218; Ruin='II'
            Env='高压-水世界'; Note='与水世界的邻居同尺寸不同密度：海洋采矿线的样板' }

        kepler37_c = @{ Zh='开普勒 37 c'; En='Kepler-37 c'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-37:Kepler-37 c'; Native=0; Dim=-2220; Ruin='II'
            Env='无氧-高温-岩石'; Note='815 K、0.755 地球半径；内圈双小行星' }

        kepler37_d = @{ Zh='开普勒 37 d'; En='Kepler-37 d'; Type='Planet'; Layer='far'
            Lookup='exo:Kepler-37:Kepler-37 d'; Native=0; Dim=-2221; Ruin='II'
            Env='无氧-高温-岩石'; Note='499 K、2.03 地球半径：同系统里尺寸跨越十倍' }

        psr1257_c = @{ Zh='PSR B1257+12 c（喧嚣鬼）'; En='Poltergeist (PSR B1257+12 c)'; Type='Planet'; Layer='far'
            Lookup='exo:PSR B1257+12:PSR B1257+12 c'; Native=0; Dim=-2226; Ruin='IV'
            Env='脉冲星辐射-极寒'; Note='4.3 地球质量的岩石行星，绕一颗死掉的恒星' }

        psr1257_d = @{ Zh='PSR B1257+12 d（恐怖鬼）'; En='Phobetor (PSR B1257+12 d)'; Type='Planet'; Layer='far'
            Lookup='exo:PSR B1257+12:PSR B1257+12 d'; Native=0; Dim=-2227; Ruin='IV'
            Env='脉冲星辐射-极寒'; Note='3.9 地球质量；三颗的行星际轨道是引力检验的经典系统' }

        bootes_void = @{ Zh='牧夫座空洞'; En='Boötes Void'; Type='CosmicWeb'; Layer='unknown'; Lookup='fixed'
            Native=0; Dim=-2407; Ruin='未知'; Env='观测级-空洞'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Distance'='~700 million ly'; 'Diameter'='~330 million ly'
                    'Galaxies inside'='only ~60 discovered'; 'Discovered'='1981' }
            Note='几乎空的宇宙：星系门如果开错地方，目的地长这样' }

        laniakea = @{ Zh='拉尼亚凯亚超星系团'; En='Laniakea Supercluster'; Type='CosmicWeb'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2408; Ruin='未知'; Env='观测级-引力流域'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Distance'='we are inside it - the Great Attractor at its centre is ~250 million ly away'
                    'Diameter'='~520 million ly'; 'Galaxies'='~100,000'
                    'Defined by'='velocity flows (Tully 2014)'
                    'Contains'='the Virgo Cluster and the Local Group' }
            Note='我们所在的超星系团：超星系之网（M10）的完整地形图' }

        frb_121102 = @{ Zh='快速射电暴 121102'; En='FRB 121102'; Type='Transient'; Layer='unknown'
            Lookup='fixed'; Native=0; Dim=-2411; Ruin='未知'; Env='观测级-毫秒级能量'
            Source='https://science.nasa.gov/universe/'
            Data=@{ 'Distance'='~3 billion ly'; 'Notable'='first repeating fast radio burst with a known host'
                    'Energy'='releases in milliseconds what the Sun does in a day' }
            Note='毫秒级的高能爆发：宇宙模拟器里"事件"类输入的来源' }

        maisies_galaxy = @{ Zh='梅西星系'; En="Maisie's Galaxy (CEERS J141946.36+525632.8)"; Type='Galaxy'
            Layer='unknown'; Lookup='fixed'; Native=0; Dim=-2414; Ruin='未知'; Env='观测级-不可达'
            Source='https://science.nasa.gov/mission/webb/'
            Data=@{ 'Redshift'='z = 11.4'; 'Light travel distance'='~13.4 billion ly'
                    'Found by'='JWST CEERS (2022), spectroscopically confirmed'
                    'Notable'='one of the earliest galaxies confirmed by spectroscopy' }
            Note='光谱确认过的早期星系：从"照片里的红点"到"确认的星系"的分界线' }
    }
}
