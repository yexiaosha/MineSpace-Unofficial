<#
    check-resource-closure.ps1 - the resource-closure checklist of the GTCEu galaxy plan, 2.2 and 4.2.

    The rule: "every material a voltage tier needs must be collectable inside the space that tier
    unlocks", with stage two's acceptance being "EV materials 100 percent obtainable inside the solar
    system", and 2.2 adding that any gap is filled by a vein variant rather than by a new ore.

    Two halves, from two sources:

      * DEMAND - every material GregTech gives an ore block to (164 of 794), with each one's ore
        byproducts. Read out of a running server by the temporary MinespaceOreClosureProbe and kept in
        `ore-registry.txt`, because this is registry data that no config file contains.
      * SUPPLY - which `ore:` values the vein files actually generate, and in which space: the solar
        system (unlocks at EV), the overworld / nether / end (reachable from the start, and therefore
        inside every tier's unlocked space), or a nearby system (unlocks at IV).

    A material counts as reachable when a vein supplies its ore, or when it is an ore byproduct of
    something reachable - which is how this pack gets titanium (ilmenite -> rutile) and most of its
    chemistry. Byproducts are followed transitively; that is an approximation, and deliberately a
    generous one, because the question is what is *missing*, not what is efficient.

    Read-only.
#>
[CmdletBinding()]
param(
    [string]$RegistryPath = (Join-Path $PSScriptRoot 'ore-registry.txt'),
    [string]$WorldgenDir = (Join-Path $PSScriptRoot '..\..\Minespace-unofficial-dev\config\gregtech\worldgen'),
    [string]$TablePath = (Join-Path $PSScriptRoot 'planet-veins.psd1'),
    [string]$DemandPath = (Join-Path $PSScriptRoot 'recipe-demand.txt'),
    [string]$ScriptsDir = (Join-Path $PSScriptRoot '..\..\Minespace-unofficial-dev\scripts')
)

$ErrorActionPreference = 'Stop'
$WorldgenDir = (Resolve-Path $WorldgenDir).Path

# The plan's stage table 2-1 is the spine of this check: stage 1 is the Earth, stage 3 is the whole
# solar system, and every further stage is a region the table declares. A material is "available from
# stage N", and rule 2.2 then says the tier that stage unlocks must not need anything later than that.
$Vanilla = @('dimension_id:0', 'is_nether', 'name:the_end')

$table = Import-PowerShellDataFile -Path $TablePath
$bodies = $table.Bodies
$regions = if ($table.ContainsKey('Regions')) { $table.Regions } else { @{} }

$stageOfDimension = @{}
foreach ($key in $bodies.Keys) {
    $stage = 3        # the solar system is stage three
    $voltage = 'EV'
    if ($bodies[$key].ContainsKey('Region')) {
        $region = $regions[$bodies[$key].Region]
        $stage = [int]$region.Stage
        $voltage = $region.Voltage
    }
    $stageOfDimension[[int]$bodies[$key].DimensionId] = [pscustomobject]@{
        Stage = $stage; Voltage = $voltage; Body = $bodies[$key].Display
    }
}

$SolarSystem = @($stageOfDimension.Keys | Where-Object { $stageOfDimension[$_].Stage -eq 3 } |
        ForEach-Object { "dimension_id:$_" })
$StageOne = [pscustomobject]@{ Stage = 1; Voltage = 'LV~MV'; Body = 'the overworld, nether and end' }
$EarlierStages = @($regions.Keys | ForEach-Object { $regions[$_] } |
        Where-Object { [int]$_.Stage -lt 3 })
$LaterStages = @($regions.Keys | ForEach-Object { $regions[$_] } |
        Where-Object { [int]$_.Stage -gt 3 } | Sort-Object { [int]$_.Stage })
$LaterFilters = @{}
foreach ($key in $bodies.Keys) {
    if (-not $bodies[$key].ContainsKey('Region')) { continue }
    $region = $regions[$bodies[$key].Region]
    if ([int]$region.Stage -le 3) { continue }
    if (-not $LaterFilters.ContainsKey($region.Stage)) { $LaterFilters[$region.Stage] = @() }
    $LaterFilters[$region.Stage] += "dimension_id:$([int]$bodies[$key].DimensionId)"
}
$Vanilla = @('dimension_id:0', 'is_nether', 'name:the_end')

# ---- demand: the registry dump -----------------------------------------------------------------

$byproducts = @{}
$hasOre = New-Object System.Collections.Generic.HashSet[string]
$materials = 0
foreach ($line in Get-Content $RegistryPath) {
    if ($line -notmatch '^VPROBE\s+(\S+)\s+ore=(\d)\s+mult=(\d+)\s+by=(\S*)') { continue }
    $materials++
    $name = $Matches[1]
    if ($Matches[2] -eq '1') { [void]$hasOre.Add($name) }
    $byproducts[$name] = @($Matches[4] -split ';' | Where-Object { $_ })
}

# The demand side, from the recipe registry: the highest voltage tier that consumes each material. See
# recipe-demand.txt for why the *lowest* is noise and why this end is the sound one.
$lastUse = @{}
if (Test-Path $DemandPath) {
    foreach ($line in Get-Content $DemandPath) {
        if ($line -match '^VPROBE NEED (\S+) min=(\d+) max=(\d+)') {
            $lastUse[$Matches[1]] = [int]$Matches[3]
        }
    }
}

# ... and the class of consumption the registry cannot see at all: the pack's own CraftTweaker
# **crafting-table** recipes. GT's recipe maps do not contain them, so `solar` - whose only consumer is
# Galacticraft's circuit fabricator, fed by `recipes.addShapeless(<basic_item_venus:4>, [<ore:dustSolar>])`
# in gc_crafting.zs - looked like a material nothing wanted. Ore-dictionary references on non-comment
# lines are the evidence that the pack does consume it. A table recipe has no voltage tier, so this can
# only ever say "used", never "used at tier N": it suppresses a false alarm and nothing more.
$scriptUsed = New-Object System.Collections.Generic.HashSet[string]
# Case-sensitive on purpose: PowerShell's -replace ignores case, so `^[a-z]+` would swallow the
# material name too and `dustSolar` would come out empty.
$prefixStrip = '^[a-z]+'
if (Test-Path $ScriptsDir) {
    foreach ($file in Get-ChildItem -Path $ScriptsDir -Filter *.zs) {
        # Only inside a recipe-addition statement: a `<ore:X>` in a `recipes.remove(...)` line, or in the
        # prose the pack's scripts are full of, says nothing about consumption. A statement starts where
        # a recipe is added or a builder opened and ends at its semicolon.
        $inRecipe = $false
        foreach ($line in Get-Content $file.FullName) {
            if ($line.TrimStart().StartsWith('//')) { continue }
            if ($line -match 'recipes\.add|recipeBuilder\s*\(\s*\)') { $inRecipe = $true }
            if (-not $inRecipe) { continue }
            foreach ($match in [regex]::Matches($line, '<ore:([A-Za-z0-9_]+)>')) {
                $token = $match.Groups[1].Value -creplace $prefixStrip, ''   # dustSolar -> Solar
                if (-not $token) { continue }
                $snake = ($token -creplace '([a-z0-9])([A-Z])', '$1_$2').ToLower()
                [void]$scriptUsed.Add($snake)
            }
            if ($line -match ';') { $inRecipe = $false }
        }
    }
}

# ---- supply: which ore values the veins generate, and where ------------------------------------

$supply = @{}
foreach ($file in Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $match = [regex]::Match($text, '"dimension_filter"\s*:\s*\[(?<body>[^\]]*)\]')
    if (-not $match.Success) { continue }
    # Every entry is one quoted token: "dimension_id:-28", "is_nether" or "name:the_end". Reading them
    # as tokens rather than as ids is what keeps the Nether and the End from being dropped entirely -
    # they filter by name, and an earlier version of this script silently skipped them.
    $dimensions = @([regex]::Matches($match.Groups['body'].Value, '"([^"]+)"') |
            ForEach-Object { $_.Groups[1].Value })
    if ($dimensions.Count -eq 0) { continue }

    # The earliest stage this file can be mined at, which is what rule 2.2 is about.
    $stage = $null
    $voltage = ''
    if (@($dimensions | Where-Object { $Vanilla -contains $_ }).Count -gt 0) {
        $stage = 1; $voltage = 'LV~MV'
    } else {
        $stages = @($dimensions | ForEach-Object {
                if ($_ -match 'dimension_id:(-?\d+)') {
                    $id = [int]$Matches[1]
                    if ($stageOfDimension.ContainsKey($id)) {
                        [pscustomobject]@{ Stage = $stageOfDimension[$id].Stage; Voltage = $stageOfDimension[$id].Voltage }
                    } else {
                        [pscustomobject]@{ Stage = 3; Voltage = 'EV' }   # a planet the table does not own
                    }
                }
            } | Sort-Object { $_.Stage })
        if ($stages.Count -eq 0) { continue }
        $stage = $stages[0].Stage
        $voltage = $stages[0].Voltage
    }
    if (-not $stage) { continue }

    # GalacticGreg's filler also accepts a quality in the middle - `ore:poor:precious_metal`,
    # `ore:rich:gold` - so the material is the *last* segment, not the first. Reading it wrong made
    # three quality names look like ores ("poor", "pure", "rich") in an earlier run of this script.
    foreach ($ore in [regex]::Matches($text, 'ore:(?:poor:|pure:|rich:)?([a-z0-9_]+)')) {
        $name = $ore.Groups[1].Value
        if (-not $supply.ContainsKey($name)) { $supply[$name] = [pscustomobject]@{ Stage = 99; Voltage = '' } }
        if ($stage -lt $supply[$name].Stage) {
            $supply[$name] = [pscustomobject]@{ Stage = $stage; Voltage = $voltage }
        }
    }
}

function Stage-Of([string]$ore) {
    if (-not $supply.ContainsKey($ore)) { return 99 }
    return $supply[$ore].Stage
}

# ---- reachability ------------------------------------------------------------------------------

function Expand-Byproducts([string[]]$seed) {
    $seen = New-Object System.Collections.Generic.HashSet[string]
    $queue = New-Object System.Collections.Generic.Queue[string]
    foreach ($item in $seed) { if ($seen.Add($item)) { $queue.Enqueue($item) } }
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        foreach ($product in @($byproducts[$current])) {
            if ($product -and $seen.Add($product)) { $queue.Enqueue($product) }
        }
    }
    return $seen
}

# The per-stage table is what rule 2.2 actually compares against: which stage a material first becomes
# available at, on the supply side. (The demand side - which tier needs it - is still the recipe graph.)
$byStage = @{}
foreach ($ore in $supply.Keys) {
    $stage = Stage-Of $ore
    if ($stage -eq 99) { continue }
    if (-not $byStage.ContainsKey($stage)) { $byStage[$stage] = @() }
    $byStage[$stage] += $ore
}
$stageNames = @{ 1 = 'stage 1  LV~MV  Earth'; 3 = 'stage 3  EV     solar system' }
foreach ($key in $regions.Keys) {
    # A suite entry (the universal base) has no stage of its own - it is included by the layers.
    if (-not $regions[$key].ContainsKey('Stage')) { continue }
    $stageNames[[int]$regions[$key].Stage] = "stage $($regions[$key].Stage)  $($regions[$key].Voltage)  $($regions[$key].Display)"
}

# The ladder rule 2.2 asks for: at stage N the player holds every ore of stage N or earlier, so the
# cumulative set - and how much each stage *adds* to it - is the number that matters, not the set of
# ores that happen to be unique to one stage.
$reachableAll = New-Object System.Collections.Generic.HashSet[string]
$ladder = @()
foreach ($stage in @($byStage.Keys | Sort-Object)) {
    $before = $reachableAll.Count
    $cumulativeOres = @($supply.Keys | Where-Object { (Stage-Of $_) -le $stage })
    $reachableAll = Expand-Byproducts $cumulativeOres
    $ladder += [pscustomobject]@{
        Stage = $stage
        NewOres = $byStage[$stage].Count
        Materials = $reachableAll.Count
        Added = $reachableAll.Count - $before
    }
}
$reachableSolar = Expand-Byproducts @($supply.Keys | Where-Object { (Stage-Of $_) -le 3 })

# ---- report ------------------------------------------------------------------------------------

Write-Host ''
Write-Host ("registry: {0} materials, {1} with an ore block" -f $materials, $hasOre.Count)
Write-Host ("veins supply {0} distinct ores, first available at:" -f $supply.Count)
foreach ($stage in $byStage.Keys | Sort-Object) {
    $label = if ($stageNames.ContainsKey($stage)) { $stageNames[$stage] } else { "stage $stage" }
    Write-Host ("    {0,-42} {1,3} ores" -f $label, $byStage[$stage].Count)
}

$unknown = @($supply.Keys | Where-Object { -not $hasOre.Contains($_) } | Sort-Object)
if ($unknown.Count -gt 0) {
    Write-Host ''
    Write-Host 'ores the config names that the registry has no ore block for (a vein would be rejected):' -ForegroundColor Red
    $unknown | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
}

Write-Host ''
Write-Host 'the closure ladder - what a player can reach at the end of each stage, by rule 2.2:'
Write-Host ('    {0,-42} {1,7} {2,7} {3,7}' -f 'stage', '+ores', '+mats', 'total')
foreach ($row in $ladder) {
    $label = if ($stageNames.ContainsKey($row.Stage)) { $stageNames[$row.Stage] } else { "stage $($row.Stage)" }
    Write-Host ('    {0,-42} {1,7} {2,7} {3,7}' -f $label, $row.NewOres, $row.Added, $row.Materials)
}
Write-Host ("    {0,-42} {1,7} {2,7}" -f 'the stage-two acceptance target is the row for stage 3', '(EV)', '')

# A gap is a material GregTech has an ore for that no vein in this pack generates, directly or as a
# byproduct - the plan's "any gap is filled by a vein variant".
#
# One class of gap is not a gap, though, and it used to be reported as one: a material whose only designed
# home is a body that has no terrain yet. The table marks those bodies `Pending` (6dk: designed, not
# generated; 6dn measured that a void world cannot hold ore at all), the generator writes no vein file for
# them on purpose, and the supply half above reads files - so it cannot see them. Calling those six "gaps"
# was a standing false alarm, and a checklist that is always red is a checklist nobody reads. They get
# their own line, naming the body that will carry them and the stage it unlocks at.
$variantOres = @{}
foreach ($variant in @($table.Variants)) {
    if ($variant.ContainsKey('Id')) {
        $variantOres[$variant.Id] = @($variant.Ores | ForEach-Object { $_.Ore })
    }
}

$plannedGaps = @{}
foreach ($key in $bodies.Keys) {
    if (-not $bodies[$key].ContainsKey('Pending') -or -not $bodies[$key].Pending) { continue }
    $ids = @()
    if ($bodies[$key].ContainsKey('Region')) {
        $region = $regions[$bodies[$key].Region]
        foreach ($include in @($region.Includes)) {
            if ($regions.ContainsKey($include)) { $ids += @($regions[$include].Variants) }
        }
        $ids += @($region.Variants)
    }
    if ($bodies[$key].ContainsKey('Signature')) { $ids += $bodies[$key].Signature }

    $dimensionId = [int]$bodies[$key].DimensionId
    $where = if ($stageOfDimension.ContainsKey($dimensionId)) { $stageOfDimension[$dimensionId] } else { $null }
    foreach ($id in $ids) {
        if (-not $variantOres.ContainsKey($id)) { continue }
        foreach ($ore in $variantOres[$id]) {
            if ($hasOre.Contains($ore) -and -not $reachableAll.Contains($ore) -and -not $plannedGaps.ContainsKey($ore)) {
                $plannedGaps[$ore] = [pscustomobject]@{
                    Body    = $bodies[$key].Display
                    Stage   = $(if ($where) { $where.Stage } else { 0 })
                    Voltage = $(if ($where) { $where.Voltage } else { '' })
                }
            }
        }
    }
}

$gaps = @($hasOre | Where-Object {
        -not $reachableAll.Contains($_) -and -not $plannedGaps.ContainsKey($_)
    } | Sort-Object)
Write-Host ''
Write-Host ("[ {0} ] no ore-bearing material is left without a source          ({1} gaps)" -f `
        $(if ($gaps.Count -eq 0) { 'OK' } else { 'FAIL' }), $gaps.Count)
if ($gaps.Count -gt 0) { Write-Host ('    ' + ($gaps -join ', ')) -ForegroundColor Yellow }
if ($plannedGaps.Count -gt 0) {
    Write-Host ("    designed, not generated yet ({0}) - the only body that will carry them has no terrain:" -f `
            $plannedGaps.Count)
    foreach ($ore in @($plannedGaps.Keys | Sort-Object)) {
        $target = $plannedGaps[$ore]
        Write-Host ("        {0,-24} {1,-18} stage {2}  {3}" -f $ore, $target.Body, $target.Stage, $target.Voltage)
    }
}

# A material whose only source is a later region cannot be needed before that region unlocks. This is
# the shape a mod's own ore takes when it arrives: it enters the table at exactly one stage.
# (An earlier version also excluded `$homeOres` here - a variable this script never defines, so the term
# was a no-op that read like a rule. The solar set already contains every stage-one ore.)
$laterOres = @($supply.Keys | Where-Object { (Stage-Of $_) -gt 3 })
$laterOnly = @($laterOres | Where-Object { -not $reachableSolar.Contains($_) } | Sort-Object)
Write-Host ''
if ($laterOnly.Count -eq 0) {
    Write-Host 'no ore exists only beyond the solar system'
} else {
    Write-Host ("ores that exist only beyond the solar system ({0}) - nothing before their stage may need them:" -f $laterOnly.Count)
    foreach ($ore in $laterOnly) {
        $stage = Stage-Of $ore
        $label = if ($stageNames.ContainsKey($stage)) { $stageNames[$stage] } else { "stage $stage" }
        Write-Host ("    {0,-24} first available at {1}" -f $ore, $label)
    }
}

# The one demand-side check the registry can support soundly. A material whose latest use is below the
# tier that first supplies it can never be used at all - it is placed too late for anything that wants
# it. The converse does not hold: passing this does not prove rule 2.2, because the registry records
# what *can* be consumed, not what a player is obliged to build.
$tierOfStage = @{ 1 = 0; 2 = 3; 3 = 4; 4 = 5; 5 = 6; 6 = 8; 7 = 9; 8 = 10 }

# An *ore* is consumed by a low-tier processing step - macerate cooperite, centrifuge the dust - while
# what matters is where its products are used. So the last use of a material is the later of its own
# and of everything it yields, followed to a fixed point. Without this the check flags every ore whose
# processing is cheap, which is all of them.
foreach ($ignored in 1..8) {
    foreach ($name in @($lastUse.Keys)) {
        foreach ($product in @($byproducts[$name])) {
            if ($product -and $lastUse.ContainsKey($product) -and $lastUse[$product] -gt $lastUse[$name]) {
                $lastUse[$name] = $lastUse[$product]
            }
        }
    }
}

$tooLate = @()
$suppressed = @()
if ($lastUse.Count -gt 0) {
    foreach ($ore in $supply.Keys) {
        if (-not $lastUse.ContainsKey($ore)) { continue }
        $stage = Stage-Of $ore
        if ($stage -eq 99) { continue }
        $supplyTier = if ($tierOfStage.ContainsKey($stage)) { $tierOfStage[$stage] } else { $stage }
        if ($supplyTier -gt $lastUse[$ore]) {
            $row = [pscustomobject]@{
                Ore = $ore; Stage = $stage; SupplyTier = $supplyTier; LastUse = $lastUse[$ore]
            }
            # The pack's own table recipes consume it, which the registry cannot see - see $scriptUsed.
            # Reported rather than dropped: it is the difference between "nothing wants this" and "only
            # a crafting table wants this", and the second is worth seeing even if it is not a failure.
            if ($scriptUsed.Contains($ore)) { $suppressed += $row } else { $tooLate += $row }
        }
    }
}
Write-Host ''
Write-Host ("[ {0} ] no material is supplied after its last use            ({1} too late)" -f `
        $(if ($tooLate.Count -eq 0) { 'OK' } else { 'FAIL' }), $tooLate.Count)
foreach ($row in $tooLate | Sort-Object Stage -Descending) {
    Write-Host ("    {0,-24} supplied at stage {1} (tier {2}) but nothing above tier {3} consumes it" -f `
            $row.Ore, $row.Stage, $row.SupplyTier, $row.LastUse) -ForegroundColor Yellow
}
Write-Host ("    the pack's own table recipes are excluded from this check: {0} material(s) are consumed" -f `
        $scriptUsed.Count)
Write-Host '    by a CraftTweaker recipe, which carries no voltage tier - a false alarm, not a placement.'
if ($suppressed.Count -gt 0) {
    Write-Host ("    of which {0} would otherwise be flagged - only a crafting table wants them:" -f $suppressed.Count)
    foreach ($row in $suppressed | Sort-Object Stage -Descending) {
        Write-Host ("        {0,-24} supplied at stage {1} (tier {2}), latest machine use tier {3}" -f `
                $row.Ore, $row.Stage, $row.SupplyTier, $row.LastUse)
    }
}

Write-Host ''
Write-Host 'reachable by the end of stage 3 - Earth plus the solar system, ores plus byproduct chains:'
Write-Host ('    ' + (($reachableSolar | Sort-Object) -join ', '))
