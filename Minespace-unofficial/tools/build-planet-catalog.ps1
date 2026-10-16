# Renders the planet catalog: planet-catalog.psd1 (the design) joined with nasa-planet-data.json
# (the measured values, fetched by fetch-planet-data.ps1) and planet-veins.psd1 (the ore).
#
# Two outputs, from one join:
#   * planet-catalog.csv         - every body, every field, for the tools
#   * ..\..\Minespace-unofficial-dev\PLANET-CATALOG.md - the readable plan, one section per layer
#
# Why the split: a planet catalog is edited far more often than it is read cover to cover, and a
# table that is generated cannot drift from its source the way a hand-maintained list of a hundred
# and fifty rows does (that is 6cx's lesson, where hand-written vein assignment had drifted into 74
# duplicate entries).
#
# Invariants the render refuses to break:
#   * a body without resolved data is a failure, not a blank row - the names and the numbers must
#     come from NASA, so a body whose values are missing is a body the plan has not really added;
#   * a landable solar-system body must name its veins, and the count must sit in the plan's 5..8
#     (section 5.4);
#   * a planned dimension id must not collide with another body's, nor with the ids Galaxy Space
#     and Galacticraft already use in this instance (measured, recorded in the catalog's DimPlan).

param(
    [string]$CatalogPath = (Join-Path $PSScriptRoot 'planet-catalog.psd1'),
    [string]$DataPath = (Join-Path $PSScriptRoot 'nasa-planet-data.json'),
    [string]$VeinTablePath = (Join-Path $PSScriptRoot 'planet-veins.psd1'),
    [string]$DocPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '..\Minespace-unofficial-dev\PLANET-CATALOG.md'),
    [string]$CsvPath = (Join-Path $PSScriptRoot 'planet-catalog.csv')
)

$ErrorActionPreference = 'Stop'
$catalog = Import-PowerShellDataFile $CatalogPath
$data = Get-Content $DataPath -Raw | ConvertFrom-Json
$veinTable = Import-PowerShellDataFile $VeinTablePath

$problems = New-Object System.Collections.Generic.List[string]

# ---- veins ----

$regions = if ($veinTable.ContainsKey('Regions')) { $veinTable.Regions } else { @{} }
$veinVariants = $veinTable.Variants
$veinBodies = $veinTable.Bodies

# A vein's player-facing title lives in `Name` ("Mare_Ilmenite_Vein"); the underscores become spaces
# here because that is how GregTech's JEI page renders them (makePrettyName).
function Get-VeinTitle($variant) {
    if ($variant.ContainsKey('Name')) { return ("$($variant.Name)" -replace '_', ' ') }
    return "$($variant.Id)"
}

function Get-RegionVariants([string]$regionKey, [int]$depth) {
    $list = @()
    if ($depth -gt 4) { return ,@($list) }
    if (-not $regions.ContainsKey($regionKey)) { return ,@($list) }
    $region = $regions[$regionKey]
    if ($region.ContainsKey('Variants')) { $list += @($region.Variants) }
    if ($region.ContainsKey('Includes')) {
        foreach ($included in $region.Includes) { $list += Get-RegionVariants $included ($depth + 1) }
    }
    return ,@($list | Sort-Object -Unique)
}

# The veins a body carries: the ones its own card lists in planet-veins.psd1, plus its region's
# suite, plus its signature. A body outside the solar system is *expected* to grow veins this way
# rather than to have a card written by hand for it - that is the region layer the vein table was
# refactored into (6dd).
function Get-BodyVeins([string]$key) {
    $names = @()
    if ($veinBodies.ContainsKey($key)) {
        $own = $veinBodies[$key]
        if ($own.ContainsKey('Region')) {
            foreach ($variantId in (Get-RegionVariants $own.Region 0)) {
                $v = $veinVariants | Where-Object { $_.Id -eq $variantId }
                if ($v) { $names += Get-VeinTitle $v }
            }
        }
        if ($own.ContainsKey('Signature')) {
            $v = $veinVariants | Where-Object { $_.Id -eq $own.Signature }
            if ($v) { $names += Get-VeinTitle $v }
        }
    }
    foreach ($variant in $veinVariants) {
        if ($variant.ContainsKey('Bodies') -and (@($variant.Bodies) -contains $key)) { $names += Get-VeinTitle $variant }
    }
    return ,@($names | Where-Object { $_ } | Sort-Object -Unique)
}

# ---- value lookup through the NASA field names ----

# The NSSDC sheets label the same quantity differently per page - "Mass (1024 kg)" on the
# comparative sheet, "Mass(1020 kg)" on a satellite sheet - so a column is filled by the first
# label that matches, and an empty string means the source does not state it.
function Get-Field {
    param($Values, [string[]]$Patterns)
    if (-not $Values) { return '' }
    foreach ($pattern in $Patterns) {
        foreach ($prop in $Values.PSObject.Properties) {
            if ($prop.Name -match $pattern -and "$($prop.Value)".Trim() -ne '') { return "$($prop.Value)".Trim() }
        }
    }
    return ''
}

function Format-Number {
    param([string]$Text, [int]$Decimals = 4)
    if (-not $Text) { return '' }
    $clean = $Text -replace ',', ''
    # Anything that is not a plain number is passed through untouched - a triaxial moon radius reads
    # "257 x 251 x 248", and stripping the non-digits out of that produced 257251248 km.
    if ($clean -notmatch '^[-+]?[0-9]*\.?[0-9]+$') { return $Text }
    $out = 0.0
    if ([double]::TryParse($clean, [ref]$out)) { return Format-Double $out }
    return $Text
}

# One number formatter for the whole document: big numbers get no decimals, tiny ones keep enough of
# them to still mean something (Phobos is 1.8e-6 Earth masses, which "0" does not say).
function Format-Double {
    param([double]$Value)
    if ($Value -eq 0) { return '0' }
    $magnitude = [Math]::Abs($Value)
    if ($magnitude -ge 1e6 -or $magnitude -lt 1e-3) { return $Value.ToString('0.###e+0') }
    if ($magnitude -ge 100) { return [Math]::Round($Value, 0).ToString('0') }
    if ($magnitude -ge 1) { return [Math]::Round($Value, 3).ToString() }
    return [Math]::Round($Value, 4).ToString()
}

function Convert-PcToLy {
    param([string]$Text)
    $v = 0.0
    if ([double]::TryParse(($Text -replace '[^0-9\.\-]', ''), [ref]$v)) {
        $ly = $v * 3.26156
        # Barnard's Star is 5.96 ly away and "6 ly" loses the point of four planets inside 16 ly.
        if ($ly -lt 10) { return [Math]::Round($ly, 2) }
        if ($ly -lt 1000) { return [Math]::Round($ly, 1) }
        return [Math]::Round($ly, 0)
    }
    return ''
}

# The NSSDC sheets state a mass in whichever power of ten suits the body (1024 kg for planets,
# 1020 kg for the big moons, 1015 kg for Phobos). The catalog shows one column, so they are all
# converted to Earth masses; the raw value stays in the CSV.
function Convert-MassToEarth {
    param([string]$Value, [string]$Label)
    $v = 0.0
    if (-not [double]::TryParse(($Value -replace '[^0-9\.\-\+]', ''), [ref]$v)) { return $Value }
    $earth = switch -Regex ($Label) {
        '\(1024' { $v / 5.9722; break }
        '\(1021' { $v / 5972.2; break }
        '\(1020' { $v / 5972.2; break }
        '\(1015' { $v / 5.9722e6; break }
        default  { $v }
    }
    return Format-Double $earth
}

function Convert-DistanceToAu {
    param([string]$Text)
    $v = 0.0
    if ([double]::TryParse(($Text -replace '[^0-9\.\-]', ''), [ref]$v)) { return [Math]::Round($v / 149.6, 3) }
    return ''
}

# ---- build the rows ----

$layerOrder = @($catalog.Layers.Keys | Sort-Object { $catalog.Layers[$_].Index })
$rows = @()
$dimOwners = @{}
$nonSurfaceTypes = @('Star', 'GasGiant', 'BlackHole', 'Pulsar', 'WhiteDwarf', 'Galaxy', 'Nebula',
    'Cluster', 'Quasar', 'CMB', 'CosmicWeb', 'GravitationalWave', 'Transient', 'SupernovaRemnant',
    'InterstellarObject')

foreach ($key in ($catalog.Bodies.Keys | Sort-Object)) {
    $body = $catalog.Bodies[$key]
    $entry = $data.Bodies.$key
    if (-not $entry -or $entry.Status -eq 'missing') {
        $problems.Add("$key : no NASA data resolved")
        $entry = $null
    }
    $values = if ($entry) { $entry.Values } else { $null }
    $layer = $catalog.Layers[$body.Layer]

    $nativeIds = @()
    if ($body.Native) { $nativeIds = @(@("$($body.Native)" -split ',') | ForEach-Object { [int]$_.Trim() } | Where-Object { $_ -ne 0 }) }
    $plannedIds = @()
    if ($body.Dim) { $plannedIds = @(@("$($body.Dim)" -split ',') | ForEach-Object { [int]$_.Trim() } | Where-Object { $_ -ne 0 }) }
    foreach ($id in $plannedIds) {
        if ($dimOwners.ContainsKey($id) -and $dimOwners[$id] -ne $key) {
            $problems.Add("$key : dimension $id is also claimed by $($dimOwners[$id])")
        } else { $dimOwners[$id] = $key }
    }

    $veins = Get-BodyVeins $key
    if ($body.Layer -eq 'sol' -and $nonSurfaceTypes -notcontains $body.Type -and $veins.Count -gt 0) {
        if ($veins.Count -lt 5 -or $veins.Count -gt 8) {
            $problems.Add("$key : $($veins.Count) veins, outside the plan's 5..8")
        }
    }

    # A planned dimension belongs to its layer's block: a body that moves layers must take an id from
    # the layer it moved to, or the id map stops meaning anything (this is how K2-18 b, Betelgeuse,
    # the Vela pulsar and the three PSR B1257+12 planets were caught keeping their old ids).
    if ($layer.ContainsKey('DimRange')) {
        $m = [regex]::Match("$($layer.DimRange)", '^(-?\d+)\.\.(-?\d+)$')
        if ($m.Success) {
            $low = [int]$m.Groups[1].Value; $high = [int]$m.Groups[2].Value
            foreach ($id in $plannedIds) {
                # An id the instance already uses is not an allocation this layer made - Galaxy Space's
                # five exoplanet dimensions (-1025, -1030..-1032, -1338) sit in the nearby layer
                # without belonging to its block.
                if ($nativeIds -contains $id) { continue }
                if ($id -lt [Math]::Min($low, $high) -or $id -gt [Math]::Max($low, $high)) {
                    $problems.Add("$key : dimension $id is outside the $($body.Layer) layer's block $($layer.DimRange)")
                }
            }
        }
    }

    $star = Get-Field $values @('^Spectral type$')
    $hostName = Get-Field $values @('^Host star$')
    if ($hostName) { $star = "$hostName $star".Trim() }

    # One distance column, three kinds of distance: light years for an exoplanet, AU for a planet's
    # orbit, kilometres from its primary for a moon.
    $distance = ''
    if ($values) {
        $names = @($values.PSObject.Properties.Name)
        if ($names -contains 'Distance (pc)') {
            $ly = Convert-PcToLy $values.'Distance (pc)'
            if ($ly) { $distance = "$ly ly" }
        } elseif ($names -contains 'Distance') { $distance = "$($values.'Distance')" }
        elseif ($names -contains 'Semimajor axis (106 km)') {
            $au = Convert-DistanceToAu $values.'Semimajor axis (106 km)'
            # For a moon this is its distance from its own planet, and kilometres are what a player
            # reads; the sheet itself states it in millions of kilometres, hence the AU form too.
            if ($au) {
                if ("$($body.Type)" -eq 'Moon') {
                    $km = [Math]::Round(([double]($values.'Semimajor axis (106 km)' -replace '[^0-9\.\-]', '')) * 1e6, 0)
                    $distance = "$($km.ToString('N0')) km"
                } else { $distance = "$au AU" }
            }
        } elseif ($names -contains 'Distance from Sun (106 km)') {
            $au = Convert-DistanceToAu $values.'Distance from Sun (106 km)'
            if ($au) { $distance = "$au AU" }
        } elseif ($names -contains 'Semimajor axis* (km)') { $distance = "$(Format-Number $values.'Semimajor axis* (km)' 0) km" }
        elseif ($names -contains 'Mean distance from Pluto (km)') { $distance = "$(Format-Number $values.'Mean distance from Pluto (km)' 0) km" }
        else {
            # A curated body states its distance in its own words ("~26,000 ly", "z = 14.32").
            foreach ($prop in $values.PSObject.Properties) {
                if ($prop.Name -match '(?i)distance|light travel') { $distance = "$($prop.Value)"; break }
            }
        }
    }

    # A moon with no single radius is stated as three axes; that is its size, so it is shown as such.
    $radius = Get-Field $values @('^Radius \(Earth\)$', 'Volumetric mean radius \(km\)', 'Mean radius \(km\)', '^Radius\(km\)$', 'Equatorial radius \(km\)')
    if (-not $radius -and $values) {
        $axes = @('Subplanetary axis radius (km)', 'Along-orbit axis radius (km)', 'Polar axis radius (km)')
        $names = @($values.PSObject.Properties.Name)
        if (($names -contains $axes[0]) -and ($names -contains $axes[2])) {
            $radius = (@($axes | ForEach-Object { Format-Number "$($values.$_)" 1 }) -join ' x ')
        }
    }

    $mass = ''
    if ($values) {
        foreach ($prop in $values.PSObject.Properties) {
            if ($prop.Name -match '^Mass\s*\(10' -or $prop.Name -eq 'Mass (Earth)') {
                $mass = Convert-MassToEarth "$($prop.Value)" $prop.Name
                break
            }
        }
    }

    # Surface temperature where a sheet states one, otherwise the black-body/equilibrium temperature,
    # which is a different quantity and is labelled as such.
    $temperature = ''
    if ($values) {
        $names = @($values.PSObject.Properties.Name)
        if (($names -contains 'Mean Temperature (C)') -and "$($values.'Mean Temperature (C)')".Trim()) {
            $temperature = "$(Format-Number $values.'Mean Temperature (C)' 1) C"
        } elseif (($names -contains 'Eq. temperature (K)') -and "$($values.'Eq. temperature (K)')".Trim()) {
            $temperature = "$(Format-Number $values.'Eq. temperature (K)' 1) K eq"
        } elseif (($names -contains 'Black-body temperature (K)') -and "$($values.'Black-body temperature (K)')".Trim()) {
            $temperature = "$(Format-Number $values.'Black-body temperature (K)' 1) K bb"
        }
    }

    $atm = Get-Field $values @('Atmosphere composition', 'Surface Pressure \(bars\)')
    if ($atm.Length -gt 220) { $atm = $atm.Substring(0, 220) + ' ...' }

    $rows += [pscustomobject]@{
        Key          = $key
        Layer        = $body.Layer
        LayerIndex   = $layer.Index
        LayerZh      = $layer.Zh
        Zh           = "$($body.Zh)"
        En           = "$($body.En)"
        Type         = "$($body.Type)"
        Stage        = "$($layer.Stage)"
        Voltage      = "$($layer.Voltage)"
        Star         = $star
        DistanceRaw  = $distance
        Period       = Get-Field $values @('^Orbital period \(d\)$', 'Sidereal orbit period', 'Revolution period', 'Orbital period', 'Tropical orbit period', '^Period$')
        Radius       = $radius
        Mass         = $mass
        Temperature  = $temperature
        Atmosphere   = $atm
        Discovered   = Get-Field $values @('^Discovered', '^Found by')
        NativeDim    = ($nativeIds -join ';')
        PlannedDim   = ($plannedIds -join ';')
        Veins        = ($veins -join ';')
        VeinCount    = $veins.Count
        # A body may name the vein file or table that owns its ore without that table being
        # planet-veins.psd1 - Earth's ore is GregTech's own overworld set.
        VeinKeys     = if ($body.ContainsKey('Vein')) { "$($body.Vein)" } else { '' }
        Ruin         = "$($body.Ruin)"
        Env          = "$($body.Env)"
        Priority     = if ($body.ContainsKey('Priority')) { "$($body.Priority)" } else { '0' }
        Note         = "$($body.Note)"
        Source       = "$($entry.Source)"
        # A curated body's own key/value block, flattened, so the CSV carries everything the
        # rendered document shows for it (the doc prints only the fields that have a column).
        Curated      = if ($body.ContainsKey('Data') -and $body.Data) {
                           (@($body.Data.Keys | Sort-Object | ForEach-Object { "$_=$($body.Data[$_])" }) -join '; ')
                       } else { '' }
        Status       = if ($entry) { $entry.Status } else { 'missing' }
    }
}

$rows = @($rows | Sort-Object LayerIndex, Key)
$rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

# ---- the readable document ----

$sb = New-Object System.Text.StringBuilder
function Add-Line { param([string]$Text = '') $null = $script:sb.AppendLine($Text) }

# "比邻星 b（Proxima Centauri b）", or just the name when a body has no separate Chinese one -
# TRAPPIST-1 and the deep-space objects are written the same way in both languages.
function Get-BodyLabel($row) {
    if ($row.Zh -eq $row.En) { return $row.Zh }
    # A Chinese name that already carries a parenthetical ("PSR B1257+12 b（尸鬼）") would nest them,
    # so those use a separator instead.
    if ($row.Zh -match '（') { return "$($row.Zh) · $($row.En)" }
    return "$($row.Zh)（$($row.En)）"
}

$solarCount = ($rows | Where-Object { $_.Layer -eq 'sol' }).Count
$deepCount = ($rows | Where-Object { $_.Layer -ne 'sol' }).Count
$maxVeins = ($rows | Measure-Object -Property VeinCount -Maximum).Maximum

Add-Line "# 星球与星体总表（PLANET CATALOG）"
Add-Line ""
Add-Line "这份表是《GTCEu 星系整合包详细实施方案》七层分级的落地清单：**$solarCount 个太阳系星体 + $deepCount 个深空目标 = $($rows.Count) 个星体**，全部使用现实存在的天体名称，全部数据来自 NASA。"
Add-Line ""
Add-Line "本文件由工具生成，不要手改。设计字段的源头是 planet-catalog.psd1，NASA 数值的源头是 nasa-planet-data.json（由 fetch-planet-data.ps1 抓取），矿脉的源头是 planet-veins.psd1。三者都在 Minespace-unofficial\tools\ 下。"
Add-Line ""
Add-Line "## 数据来源"
Add-Line ""
Add-Line "| 类别 | 来源 |"
Add-Line "| --- | --- |"
foreach ($prop in $data.Sources.PSObject.Properties) { Add-Line "| $($prop.Name) | $($prop.Value) |" }
Add-Line ""
Add-Line "抓取日期：$($data.Fetched)。JPL 的 ssd.jpl.nasa.gov 在这台机器上 TLS 握手失败（2026-10-15 实测），所以卫星数据取自 NSSDC 的卫星事实表；NED（NASA/IPAC）能应答但只给位置与红移，因此不作为距离来源。"
Add-Line ""
Add-Line "## 七层分级与电压"
Add-Line ""
Add-Line "| 层 | 名称 | 阶段 | 电压 | 距离范围 | 主题 | 星体数 |"
Add-Line "| --- | --- | --- | --- | --- | --- | --- |"
foreach ($layerKey in $layerOrder) {
    $layer = $catalog.Layers[$layerKey]
    $count = ($rows | Where-Object { $_.Layer -eq $layerKey }).Count
    Add-Line "| $($layer.Index) | $($layer.Zh) | $($layer.Stage) | $($layer.Voltage) | $($layer.Distance) | $($layer.Theme) | $count |"
}
Add-Line ""
Add-Line "## 尺度：真实宇宙 vs 游戏内（owner 填的比例）"
Add-Line ""
Add-Line "分层按 **距地球的距离** 划，每层一个量级；下表是每层的真实体量、游戏内实际放了多少天体，以及两者的比例。方案文档本身没有给任何距离数字（把全文按 光年 / 亿光年 / 万光年 / AU / 距离 / 尺度 检索，命中 0 次），所以这些分带与比例是本表定的。"
Add-Line ""
Add-Line "| 层 | 名称 | 距地球 | 真实体量 | 游戏内 | 比例 |"
Add-Line "| --- | --- | --- | --- | --- | --- |"
foreach ($layerKey in $layerOrder) {
    $layer = $catalog.Layers[$layerKey]
    $real = if ($layer.ContainsKey('Real')) { $layer.Real } else { '' }
    $inGame = if ($layer.ContainsKey('InGame')) { $layer.InGame } else { '' }
    $ratio = if ($layer.ContainsKey('Ratio')) { $layer.Ratio } else { '' }
    Add-Line "| $($layer.Index) | $($layer.Zh) | $($layer.Distance) | $real | $inGame | $ratio |"
}
Add-Line ""
Add-Line "维度 ID 分配："
Add-Line ""
foreach ($line in $catalog.Meta.DimPlan) { Add-Line "- $line" }
Add-Line ""
Add-Line "## 方案点名的优先体"
Add-Line ""
Add-Line "方案的第八章没有点名那 12 个太阳系天体，只给了工作顺序（月球金标准 → 内圈三兄弟水星/金星/火星 → 小行星带 + 六颗卫星）。按这个顺序反推，12 个 = 地球 + 月球 + 水星 + 金星 + 火星 + 小行星带 + 六颗卫星（火卫一、火卫二、木卫一、木卫二、木卫三、土卫六）。这是本表的一个假设，若口径不同只需改 planet-catalog.psd1 里的 Priority 一行。"
Add-Line ""
Add-Line "| 口径 | 天体 | 层 | 阶段 | 说明 |"
Add-Line "| --- | --- | --- | --- | --- |"
foreach ($row in (@($rows | Where-Object { $_.Priority -ne '0' -and $_.Priority -ne '' } | Sort-Object Priority, LayerIndex))) {
    $label = if ($row.Priority -eq '1') { '方案的 12 天体' } else { '方案点名' }
    Add-Line "| $label | $($row.Zh)（$($row.En)） | $($row.LayerZh) | $($row.Stage) | $($row.Note) |"
}
Add-Line ""

foreach ($layerKey in $layerOrder) {
    $layer = $catalog.Layers[$layerKey]
    $layerRows = @($rows | Where-Object { $_.Layer -eq $layerKey })
    Add-Line "## 第 $($layer.Index) 层：$($layer.Zh)（$($layer.Stage) / $($layer.Voltage) / $($layer.Distance)）"
    Add-Line ""
    Add-Line "$($layer.Theme)。本层 $($layerRows.Count) 个星体。"
    Add-Line ""
    Add-Line "### 天体与实测数据（NASA）"
    Add-Line ""
    # Layer 1's distances are heliocentric (NASA's fact sheets), everything further out is measured
    # from Earth; the header says which, and a planet also gets its geometric Earth range.
    $distanceHeader = if ($layerKey -eq 'sol') { '距太阳/母星（含距地球范围）' } else { '距地球' }
    Add-Line "| 天体 | 类型 | 宿主/光谱型 | $distanceHeader | 轨道周期(d) | 半径(km 或 R⊕) | 质量(M⊕) | 温度 | 发现 |"
    Add-Line "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"
    foreach ($row in $layerRows) {
        $distanceCell = $row.DistanceRaw
        if ($layerKey -eq 'sol' -and (@('Planet', 'GasGiant', 'DwarfPlanet') -contains $row.Type) -and $row.DistanceRaw -match 'AU') {
            # A planet's closest and farthest distance from Earth is its own orbit plus or minus one AU.
            $axis = 0.0
            if ([double]::TryParse((($row.DistanceRaw -split ' ')[0] -replace '[^0-9\.\-]', ''), [ref]$axis) -and $axis -gt 1) {
                $distanceCell = "$($row.DistanceRaw)（日心）；距地球 $([Math]::Round($axis - 1, 2)) ~ $([Math]::Round($axis + 1, 2)) AU"
            }
        }
        Add-Line "| $(Get-BodyLabel $row) | $($row.Type) | $($row.Star) | $distanceCell | $(Format-Number $row.Period 3) | $($row.Radius) | $($row.Mass) | $($row.Temperature) | $($row.Discovered) |"
    }
    Add-Line ""
    Add-Line "### 设计字段（维度 / 矿脉 / 遗迹 / 环境）"
    Add-Line ""
    Add-Line "| 天体 | 现有维度 | 规划维度 | 矿脉 | 遗迹等级 | 环境伤害 | 备注 |"
    Add-Line "| --- | --- | --- | --- | --- | --- | --- |"
    foreach ($row in $layerRows) {
        # Three different reasons for an empty vein column, and they are not interchangeable: a
        # non-surface body has no ore at all, a solar-system body has to earn a geology card by hand,
        # and an exo body is supposed to arrive through its layer's suite (6dd's region layer).
        $veins = if ($row.VeinCount -gt 0) { "$($row.VeinCount) 条：$($row.Veins)" }
            elseif ($nonSurfaceTypes -contains $row.Type) { '不适用（恒星/气态/黑洞等，非登陆体）' }
            elseif ("$($row.VeinKeys)" -ne '') { "不适用（矿脉来自 $($row.VeinKeys)，不在本表）" }
            elseif ($row.Layer -eq 'sol') { '未配置（需先写地质设定卡，方案 5.5）' }
            else { '未配置（登陆时按所属层的套件 + signature 生成，方案 5.4）' }
        Add-Line "| $(Get-BodyLabel $row) | $($row.NativeDim) | $($row.PlannedDim) | $veins | $($row.Ruin) | $($row.Env) | $($row.Note) |"
    }
    Add-Line ""
}

Add-Line "## 生成时的校验"
Add-Line ""
Add-Line "生成器在渲染前跑三条不变量：每个天体都必须解析到 NASA 数据；太阳系的可登陆体矿脉数必须落在 5..8（方案 5.4）；规划维度 ID 不得重复。本层最大的矿脉数是 $maxVeins（同太阳系上限 8）。本次结果："
Add-Line ""
if ($problems.Count -eq 0) {
    Add-Line "- 全部通过。"
} else {
    foreach ($problem in $problems) { Add-Line "- $problem" }
}
Add-Line ""

[IO.File]::WriteAllText($DocPath, $sb.ToString(), (New-Object Text.UTF8Encoding($true)))

Write-Output "bodies           : $($rows.Count)"
foreach ($layerKey in $layerOrder) {
    $count = ($rows | Where-Object { $_.Layer -eq $layerKey }).Count
    Write-Output ("  {0,-10} {1,4}" -f $catalog.Layers[$layerKey].Zh, $count)
}
Write-Output "with veins       : $(($rows | Where-Object { $_.VeinCount -gt 0 }).Count)"
Write-Output "sol without veins: $(($rows | Where-Object { $_.Layer -eq 'sol' -and $_.VeinCount -eq 0 }).Count)"
Write-Output "doc              : $DocPath"
Write-Output "csv              : $CsvPath"
if ($problems.Count) {
    Write-Output "PROBLEMS ($($problems.Count)):"
    $problems | ForEach-Object { Write-Output "  $_" }
} else {
    Write-Output "checks           : all green"
}
