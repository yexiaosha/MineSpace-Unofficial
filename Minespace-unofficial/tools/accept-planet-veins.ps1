<#
    accept-planet-veins.ps1 - the countable half of the stage-one acceptance checklist.

    Why this exists: the GTCEu galaxy plan (2026-10-10, section 4.1) makes the 90-day goal "all of the
    solar system carries geology-driven GregTech veins", and its acceptance criteria for that stage are
    countable rather than visual:

      * every body carries 5..8 veins                          (plan 5.4)
      * no ore generates twice and none is missing             (plan 4.1, verbatim: "无矿物重复生成或缺失")
      * the Moon shows at least three veins                     (plan 4.1)
      * every vein file parses, so the loader never drops one    (TJ-MIGRATION-PLAN.md 6b/6cx)

    Checking those by flying to twenty-one bodies is neither repeatable nor cheap, so this script reads
    the vein files and the last server log instead. It is read-only: it never writes a vein file.

    Usage
        .\tools\accept-planet-veins.ps1
        .\tools\accept-planet-veins.ps1 -MinVeins 5 -MaxVeins 8
#>
[CmdletBinding()]
param(
    [string]$WorldgenDir = (Join-Path $PSScriptRoot '..\..\Minespace-unofficial-dev\config\gregtech\worldgen'),
    [string]$LogPath = (Join-Path $PSScriptRoot '..\..\Minespace-unofficial-dev\logs\latest.log'),
    [int]$MinVeins = 5,
    [int]$MaxVeins = 8
)

$ErrorActionPreference = 'Stop'

# Dimension id -> body. Solar system first (the stage-one and stage-two scope), then the three
# exoplanets this stack already reaches, then the vanilla dimensions, which are GregTech's own sets
# and are deliberately not held to the 5..8 rule.
# String keys on purpose: an ordered dictionary also has Item(int index), and PowerShell binds a
# numeric key like -28 to *that* overload, so $Bodies[-28] silently returns nothing.
$Bodies = @{
    '-28' = 'Moon'; '-29' = 'Mars'; '-30' = 'Asteroids'; '-31' = 'Venus'
    '-1005' = 'Mercury'; '-1006' = 'GS Venus'; '-1007' = 'Ceres'; '-1008' = 'Pluto'
    '-1009' = 'Kuiper Belt'; '-1012' = 'Phobos'; '-1013' = 'Deimos'; '-1014' = 'Io'
    '-1015' = 'Europa'; '-1016' = 'Ganymede'; '-1017' = 'Enceladus'; '-1018' = 'Titan'
    '-1021' = 'Triton'; '-1022' = 'Callisto'; '-1023' = 'Haumea'; '-1024' = 'Miranda'
    # The real names, per PLANET-CATALOG.md: Galaxy Space's "Barnarda C/C1/C2" map to Barnard's Star
    # b/c/d, and the dimension ids are unchanged.
    '-1025' = 'Proxima B'; '-1030' = "Barnard's Star b"; '-1031' = "Barnard's Star c"
    '-1032' = "Barnard's Star d"; '-1338' = 'Tau Ceti F'
}

# The table is the single source of truth for a body's name, and this map above predates it: it is kept for
# the dimensions the table does not own (Galaxy Space's mirror dimension -1006, for one). Everything else is
# filled in from the table, which is what prints "TRAPPIST-1 e" instead of "dimension -2103" - and, more to
# the point, what keeps the two files from drifting apart as bodies are added.
#
# Bodies marked `Pending` are skipped on purpose. They are designed but not generated (their world is still
# the void provider), so they have no vein file by design - counting them here would turn eleven deliberate
# absences into eleven "MISSING" failures. The closure checklist reports them in their own section instead.
$TablePath = Join-Path $PSScriptRoot 'planet-veins.psd1'
if (Test-Path $TablePath) {
    $planetTable = Import-PowerShellDataFile -Path $TablePath
    foreach ($key in $planetTable.Bodies.Keys) {
        $body = $planetTable.Bodies[$key]
        if ($body.ContainsKey('Pending') -and $body.Pending) { continue }
        $dimensionId = "$([int]$body.DimensionId)"
        if (-not $Bodies.ContainsKey($dimensionId)) { $Bodies[$dimensionId] = $body.Display }
    }
}
$SolarSystem = @(-28, -29, -30, -31, -1005, -1006, -1007, -1008, -1009, -1012, -1013, -1014, -1015,
                 -1016, -1017, -1018, -1021, -1022, -1023, -1024)
$Vanilla = @('dimension_id:0', 'is_nether', 'name:the_end')

if (-not (Test-Path $WorldgenDir)) { throw "no worldgen directory at $WorldgenDir" }
$WorldgenDir = (Resolve-Path $WorldgenDir).Path

# ---- read every definition -------------------------------------------------------------------

$rows = New-Object System.Collections.Generic.List[object]
$parseFailures = New-Object System.Collections.Generic.List[string]
$unfiltered = New-Object System.Collections.Generic.List[string]
$files = Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json

foreach ($file in $files) {
    $relative = $file.FullName.Substring($WorldgenDir.Length).TrimStart('\')
    try {
        $definition = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $parseFailures.Add($relative)
        continue
    }
    $name = if ($definition.name) { $definition.name } else { '(unnamed) ' + $file.Name }
    if (-not $definition.dimension_filter -or $definition.dimension_filter.Count -eq 0) {
        # A definition with no dimension filter generates nowhere under this schema - the same defect
        # 6cx found in moon\rare_earth_vein.json, where it is silent rather than fatal.
        $unfiltered.Add("$relative  ($name)")
        continue
    }
    foreach ($filter in $definition.dimension_filter) {
        $rows.Add([pscustomobject]@{
            Filter = [string]$filter
            Name   = $name
            Weight = [int]$definition.weight
            File   = $relative
        })
    }
}

function Body-Of([string]$filter) {
    if ($filter -notmatch 'dimension_id:(-?\d+)') { return $null }
    $key = $Matches[1]
    if ($Bodies.ContainsKey($key)) { return $Bodies[$key] }
    return "dimension $key"
}

# ---- per body ---------------------------------------------------------------------------------

Write-Host ''
Write-Host ("vein files: {0}   definitions that parsed: {1}   parse failures: {2}" -f `
        $files.Count, (($rows | Group-Object File | Measure-Object).Count + 0), $parseFailures.Count)
Write-Host ("definitions with no dimension_filter (they generate nowhere): {0}" -f $unfiltered.Count)

$planetRows = $rows | Where-Object { $Vanilla -notcontains $_.Filter }
$groups = $planetRows | Group-Object Filter

# Every dimension the map knows, plus anything the files mention that the map does not. A body with
# no veins at all appears nowhere in the files, so iterating the files alone would let it pass by
# being invisible - which is how four nearby-system bodies went unnoticed once already.
$knownFilters = @($Bodies.Keys | Sort-Object { [int]$_ } | ForEach-Object { "dimension_id:$_" })
$presentFilters = @($planetRows | Select-Object -ExpandProperty Filter | Sort-Object -Unique)
$allFilters = @($knownFilters + ($presentFilters | Where-Object { $knownFilters -notcontains $_ }))

$tooFew = 0; $tooMany = 0; $duplicatePairs = 0; $empty = 0
Write-Host ''
Write-Host ('{0,-20} {1,-14} {2,5}  {3}' -f 'dimension', 'body', 'veins', 'flags')
foreach ($filter in $allFilters) {
    $group = $groups | Where-Object Name -eq $filter
    $bodyName = Body-Of $filter
    $count = if ($group) { $group.Count } else { 0 }
    $flags = @()

    if ($count -lt $MinVeins) { $flags += "BELOW $MinVeins"; $tooFew++ }
    if ($count -gt $MaxVeins) { $flags += "ABOVE $MaxVeins"; $tooMany++ }
    if ($count -eq 0) { $flags += 'MISSING'; $empty++ }

    if ($group) {
        $duplicates = $group.Group | Group-Object Name | Where-Object Count -gt 1
        foreach ($duplicate in $duplicates) {
            $duplicatePairs++
            $flags += ('DUP {0} x{1}' -f $duplicate.Name.Split('.')[-1], $duplicate.Count)
        }
    }

    Write-Host ('{0,-20} {1,-14} {2,5}  {3}' -f $filter, $bodyName, $count, ($flags -join '  '))
}

# ---- the criteria in the plan's own words -----------------------------------------------------

Write-Host ''
Write-Host 'acceptance criteria (GTCEu galaxy plan section 4.1 / 5.4)'

$moon = ($groups | Where-Object Name -eq 'dimension_id:-28').Count
Write-Host ("  [  {0}  ] the Moon shows at least 3 veins                     (has {1})" -f `
        $(if ($moon -ge 3) { 'OK' } else { 'FAIL' }), $moon)
Write-Host ("  [  {0}  ] no vein file failed to parse                       ({1} failures)" -f `
        $(if ($parseFailures.Count -eq 0) { 'OK' } else { 'FAIL' }), $parseFailures.Count)
Write-Host ("  [  {0}  ] no ore generates twice on the same body         ({1} duplicates)" -f `
        $(if ($duplicatePairs -eq 0) { 'OK' } else { 'FAIL' }), $duplicatePairs)
Write-Host ("  [  {0}  ] no body is left without a vein                   ({1} empty)" -f `
        $(if ($empty -eq 0) { 'OK' } else { 'FAIL' }), $empty)
Write-Host ("  [  {0}  ] every body carries {1}..{2} veins                ({3} below, {4} above)" -f `
        $(if (($tooFew + $tooMany) -eq 0) { 'OK' } else { 'FAIL' }), $MinVeins, $MaxVeins, $tooFew, $tooMany)
Write-Host ("  [  {0}  ] no definition generates nowhere                   ({1} without a filter)" -f `
        $(if ($unfiltered.Count -eq 0) { 'OK' } else { 'FAIL' }), $unfiltered.Count)

if ($parseFailures.Count -gt 0) {
    Write-Host ''
    Write-Host 'files the loader drops (one malformed file aborts its own definition only, but it is a FAIL):'
    $parseFailures | ForEach-Object { Write-Host "    $_" }
}

if ($unfiltered.Count -gt 0) {
    Write-Host ''
    Write-Host 'definitions that generate nowhere (no dimension_filter):'
    $unfiltered | ForEach-Object { Write-Host "    $_" }
}

# ---- what the solar system can actually supply ------------------------------------------------

$solarFilters = $SolarSystem | ForEach-Object { "dimension_id:$_" }
$solarRows = $rows | Where-Object { $solarFilters -contains $_.Filter }
$ores = New-Object System.Collections.Generic.HashSet[string]
foreach ($row in $rows) {
    $file = Join-Path $WorldgenDir $row.File
    if (-not (Test-Path $file)) { continue }
    if ($solarFilters -notcontains $row.Filter) { continue }
    # GalacticGreg's filler also accepts a quality in the middle (`ore:poor:precious_metal`), so the
    # material is the last segment.
    foreach ($match in [regex]::Matches((Get-Content $file -Raw -Encoding UTF8), 'ore:(?:poor:|pure:|rich:)?([a-z0-9_]+)')) {
        [void]$ores.Add($match.Groups[1].Value)
    }
}

Write-Host ''
Write-Host ("solar system ({0} dimensions) supplies {1} distinct ores:" -f `
        $SolarSystem.Count, $ores.Count)
Write-Host ('    ' + (($ores | Sort-Object) -join ', '))
Write-Host ''
Write-Host 'the resource-closure check (plan 2.2) is `tools\check-resource-closure.ps1`, which takes this'
Write-Host 'list as its supply side and the material registry (tools\ore-registry.txt) as its demand side.'
