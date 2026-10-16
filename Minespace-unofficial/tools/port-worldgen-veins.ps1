<#
    Ports the pack's planet vein definitions from the GTCEu-era format to the GTCE-TJ one.

    Why this exists (see TJ-MIGRATION-PLAN.md, section 6b):
      * the old files describe veins with GTCEu 2.8's `layered` generator and its
        `layered` filler (primary / secondary / between / sporadic),
      * GTCE-TJ has neither: its generators are `ellipsoid` / `sphere` / `plate` and its
        fillers are `simple` / `weight_random` / `state_match` (checked in the jar),
      * everything else the old files carry - weight, density, min/max height, the
        `surface_rock` vein populator and the `dimension_filter` list - is supported by
        GTCE-TJ as-is, and GT walks config/gregtech/worldgen recursively, so the files
        keep their per-body folders and scope themselves with their own filter.

    Conversion rules:
      * generator  {"type":"layered","radius":[a,b]}   ->  {"type":"ellipsoid","radius":[a,b]}
        (GTCE-TJ's EllipsoidGenerator takes exactly the same radius pair)
      * filler     {"type":"layered","values":[{primary/secondary/between/sporadic}]}
                   ->  {"type":"simple","value":{"type":"weight_random","values":[...]}}
        The layered keys are structural, not numeric, so they are mapped by order: the
        first distinct material becomes the dominant one, then the tail decays. Duplicated
        materials (a vein listing the same ore as primary and secondary) are merged.
      * "ore:minespace:x" -> "ore:x": GTCE material names are global, there is no
        per-mod namespace any more (see MinespaceMaterials).

    The six planet groups are ported; the old overworld / nether / end files are left
    alone on purpose, because GTCE-TJ already ships its own set for those dimensions.
#>
[CmdletBinding()]
param(
    [string]$Source = (Join-Path $env:TEMP 'minespace-removed\2026-10-11-gtceu-stack\config\gregtech\worldgen\vein'),
    [string]$Target,
    [string[]]$Groups = @('moon', 'mars', 'venus', 'asteroids', 'ceres', 'barnarda')
)

$ErrorActionPreference = 'Stop'

if (-not $Target) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $Target = Join-Path $repoRoot '..\Minespace-unofficial-dev\config\gregtech\worldgen'
}
$Target = (New-Item -ItemType Directory -Force -Path $Target).FullName

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source vein folder not found: $Source"
}

function Get-WeightList([int]$distinct) {
    switch ($distinct) {
        1 { return @(100) }
        2 { return @(70, 30) }
        3 { return @(60, 25, 15) }
        default { return @(55, 25, 15, 5) }
    }
}

# Materials the old files could place but GTCE-TJ cannot. Found by letting GT parse the ported
# set: the loader reports "There is no ore generated for material X" per file, which names the
# culprit exactly. Keep this map in sync with those messages.
$MaterialSubstitutions = @{
    # GTCEu had a plutonium ore; GTCE-TJ does not (plutonium is a processed material there).
    # GT's own end naquadah vein uses the enriched naquadah compound as the rare ore, so the
    # vein keeps its "naquadah with a rare by-product" shape.
    'ore:plutonium' = 'ore:enriched_naquadric_compound'
}

function Convert-Vein([string]$path) {
    $old = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json

    if ($old.generator.type -ne 'layered') {
        throw "${path}: unexpected generator type '$($old.generator.type)'"
    }
    if ($old.filler.type -ne 'layered') {
        throw "${path}: unexpected filler type '$($old.filler.type)'"
    }

    # Filler: flatten the layered keys into an ordered, de-duplicated material list.
    $materials = @()
    foreach ($layer in @($old.filler.values)) {
        foreach ($property in $layer.PSObject.Properties) {
            $material = [string]$property.Value -replace '^ore:minespace:', 'ore:'
            if ($MaterialSubstitutions.ContainsKey($material)) {
                $material = $MaterialSubstitutions[$material]
            }
            if ($materials -notcontains $material) {
                $materials += $material
            }
        }
    }
    $weights = Get-WeightList $materials.Count
    $values = @()
    for ($i = 0; $i -lt $materials.Count; $i++) {
        $values += [ordered]@{ weight = $weights[$i]; value = $materials[$i] }
    }

    $result = [ordered]@{}
    foreach ($key in $old.PSObject.Properties.Name) {
        if ($key -in @('generator', 'filler', 'vein_populator', 'dimension_filter')) {
            continue
        }
        $result[$key] = $old.$key
    }

    $result.generator = [ordered]@{ type = 'ellipsoid'; radius = @($old.generator.radius) }
    $result.filler = [ordered]@{
        type  = 'simple'
        value = [ordered]@{ type = 'weight_random'; values = $values }
    }

    if ($old.vein_populator) {
        $result.vein_populator = [ordered]@{
            type     = $old.vein_populator.type
            material = [string]$old.vein_populator.material -replace '^minespace:', ''
        }
    }
    # @() matters: ConvertFrom-Json unwraps a one-element array into a bare string, and a
    # bare string here would make GT reject the whole definition.
    $result.dimension_filter = @($old.dimension_filter)

    return $result
}

$portable = @('weight', 'density', 'min_height', 'max_height')
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$written = 0
foreach ($group in $Groups) {
    $groupSource = Join-Path $Source $group
    if (-not (Test-Path -LiteralPath $groupSource)) {
        Write-Warning "no such group: $groupSource"
        continue
    }
    $groupTarget = New-Item -ItemType Directory -Force -Path (Join-Path $Target $group)

    foreach ($file in (Get-ChildItem -LiteralPath $groupSource -Filter *.json | Sort-Object Name)) {
        $converted = Convert-Vein $file.FullName
        $json = $converted | ConvertTo-Json -Depth 10
        # No BOM: GT parses these with gson, and a BOM makes it throw
        # MalformedJsonException - which aborts the whole worldgen registry reload, not just
        # the one file.
        [System.IO.File]::WriteAllText((Join-Path $groupTarget.FullName $file.Name), $json, $utf8NoBom)
        $written++

        $targets = ($converted.filler.value.values | ForEach-Object { "$($_.value)(w$($_.weight))" }) -join ' '
        [pscustomobject]@{
            group    = $group
            file     = $file.Name
            weight   = $converted.weight
            radius   = ($converted.generator.radius -join ',')
            filter   = ($converted.dimension_filter -join ',')
            material = $targets
        }
    }
}

Write-Host "wrote $written vein definitions into $Target"
