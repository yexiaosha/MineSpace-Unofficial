<#
    Pins GTCE-TJ's overworld vein definitions to dimension 0.

    Why: GT's own files carry no `dimension_filter`, so they fall back to
    `PREDICATE_SURFACE_WORLD` (= the `is_surface_world` filter). In 1.12.2 that filter reads
    `WorldProvider.getDimensionType()`, whose default is DimensionType.OVERWORLD - which
    Galacticraft's planet providers inherit. So without this, two things happen on every planet:

      * GT's overworld veins are added to the planet's vein list, i.e. the overworld set
        (coal, oil and gas spheres, granite/marble, ...) would also generate there, on top of
        the pack's per-body sets, and
      * GT evaluates every definition's biome weight modifier for the planet biome, and the
        overworld-sphere definitions use `biome_dictionary` - which calls
        `BiomeDictionary.hasType` on a biome Galacticraft never registered. Forge answers that
        with `makeBestGuess` -> `addTypes` -> IllegalArgumentException ("Cannot add types to
        unregistered biome"), so *no* vein is placed in the dimension at all.

    `dimension_id:0` is the exact, unambiguous filter for the overworld. Files are rewritten in
    place, without a BOM (gson chokes on one - see port-worldgen-veins.ps1).
#>
[CmdletBinding()]
param(
    [string]$OverworldDir
)

$ErrorActionPreference = 'Stop'

if (-not $OverworldDir) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $OverworldDir = Join-Path $repoRoot '..\Minespace-unofficial-dev\config\gregtech\worldgen\overworld'
}
if (-not (Test-Path -LiteralPath $OverworldDir)) {
    throw "Overworld vein folder not found: $OverworldDir"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$patched = 0
foreach ($file in (Get-ChildItem -LiteralPath $OverworldDir -Filter *.json | Sort-Object Name)) {
    $definition = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json

    $current = @($definition.dimension_filter)
    if ($current.Count -eq 1 -and $current[0] -eq 'dimension_id:0') {
        continue
    }

    $result = [ordered]@{}
    foreach ($key in $definition.PSObject.Properties.Name) {
        if ($key -eq 'dimension_filter') {
            continue
        }
        $result[$key] = $definition.$key
    }
    $result.dimension_filter = @('dimension_id:0')

    $json = $result | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($file.FullName, $json, $utf8NoBom)
    $patched++
}

Write-Host "pinned $patched overworld vein definitions to dimension 0 in $OverworldDir"
