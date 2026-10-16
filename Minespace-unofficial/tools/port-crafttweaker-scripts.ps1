<#
    Ports the pack's CraftTweaker scripts from the GTCEu-era API to GTCE-TJ's.

    The scripts themselves are almost entirely API-neutral - `recipes.remove`,
    `recipes.addShaped`, `recipes.addShapeless`, `mods.jei.JEI.hide*`, ore dictionary
    ingredients, Galacticraft item ids - and all of that works unchanged on GTCE-TJ.
    What does not is the recipe-map accessor:

        GTCE: TJ Edition     mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()
        GTCEu 2.8            <recipemap:assembler>.recipeBuilder()

    Note the name: the Java method is RecipeMap.ctRecipeBuilder(), but it carries
    @ZenMethod("recipeBuilder") - it has to be renamed, because the unannotated Java
    recipeBuilder() returns the raw builder that scripts cannot use - so the script name is
    recipeBuilder().

    Everything after the accessor is identical - `inputs`, `outputs`, `duration`, `EUt`,
    `property`, `circuit`, `fluidInputs`, `fluidOutputs`, `buildAndRegister` are the same
    method names on CTRecipeBuilder (read out of gregtech_tj_fork-1.18.3.jar), and
    RecipeMap's ZenClass is `mods.gregtech.recipe.RecipeMap`.

    Run it with the parked GTCEu-era scripts as the source; it writes the ported copies into
    the instance's scripts/ folder unchanged apart from the accessor and the header note.
#>
[CmdletBinding()]
param(
    [string]$Source = (Join-Path $env:TEMP 'minespace-removed\2026-10-11-gtceu-stack\scripts\scripts'),
    [string]$Target
)

$ErrorActionPreference = 'Stop'

if (-not $Target) {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    $Target = Join-Path $repoRoot '..\Minespace-unofficial-dev\scripts'
}
$Target = (New-Item -ItemType Directory -Force -Path $Target).FullName

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source script folder not found: $Source"
}

$header = @'
// Ported from the GTCEu-era script of the same name (see TJ-MIGRATION-PLAN.md, section 6d).
// The recipe map accessor is GTCE-TJ's:
//     <recipemap:assembler>.recipeBuilder()                                   [GTCEu]
//  -> mods.gregtech.recipe.RecipeMap.getByName("assembler").recipeBuilder()    [GTCE-TJ]
// Everything else - inputs/outputs/duration/EUt/property/circuit/fluidInputs/
// buildAndRegister, the ore dictionary names, the Galacticraft item ids and the JEI calls -
// is unchanged, because those APIs are the same in both forks.

'@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$ported = 0
$rewritten = 0
foreach ($file in (Get-ChildItem -LiteralPath $Source -Filter *.zs | Sort-Object Name)) {
    $text = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    # GTCE-TJ renamed two of the maps (read out of RecipeMaps' static initialiser):
    #     bender                  -> metal_bender
    #     electric_blast_furnace  -> blast_furnace
    $mapNames = @{ 'bender' = 'metal_bender'; 'electric_blast_furnace' = 'blast_furnace' }

    # The scripts were written against Galacticraft 3.x metadata. This pack runs 4.0.7, whose
    # tables were read out of the running game (a probe printed every machine block's metadata ->
    # name pairs), and three of the four machine blocks moved:
    #     machine   : Coal Generator 0, Compressor 12                    (was 2, 3)
    #     machine2  : Electric Compressor 0, Circuit Fabricator 4,
    #                 Oxygen Storage Module 8 (kept), Deconstructor 12   (was 4, 5, 10)
    #     machine4  : Advanced Compressor 0                              (was 11)
    #     mars_machine_t2 : Gas Liquefier 0, Methane Synthesizer 4,
    #                       Water Electrolyzer 8                        (was 4, 5, 6)
    # So each old reference is rewritten to the machine it meant, not to the number it said.
    $metaFixes = @(
        @{ old = '<galacticraftcore:machine2:4>'; new = '<galacticraftcore:machine2:0>' },
        @{ old = '<galacticraftcore:machine2:5>'; new = '<galacticraftcore:machine2:4>' },
        @{ old = '<galacticraftcore:machine2:10>'; new = '<galacticraftcore:machine2:12>' },
        @{ old = '<galacticraftcore:machine4:11>'; new = '<galacticraftcore:machine4:0>' },
        @{ old = '<galacticraftplanets:mars_machine_t2:4>'; new = '<galacticraftplanets:mars_machine_t2:0>' },
        @{ old = '<galacticraftplanets:mars_machine_t2:5>'; new = '<galacticraftplanets:mars_machine_t2:4>' },
        @{ old = '<galacticraftplanets:mars_machine_t2:6>'; new = '<galacticraftplanets:mars_machine_t2:8>' }
    )
    foreach ($fix in $metaFixes) {
        $text = $text.Replace($fix.old, $fix.new)
    }

    # The crafting script re-creates Galacticraft's oxygen chain from GregTech parts - but the
    # removals script (which loads later) takes the Oxygen Collector and the Oxygen Compressor
    # out on purpose: GregTech supplies the oxygen fluid and this addon's Oxygen Compressor
    # bottles it. Re-adding them only produced a recipe that the next script deleted again, so
    # the two re-additions are commented out here and the compressor is built from GregTech parts
    # in minespace_machines.zs instead.
    $lines = $text -split "`r?`n"
    $kept = New-Object System.Collections.Generic.List[string]
    $commenting = $false
    foreach ($line in $lines) {
        if (-not $commenting -and
                ($line -match 'recipes\.addShaped\(<galacticraftcore:collector>' -or
                 $line -match 'recipes\.addShaped\(<galacticraftcore:oxygen_compressor>')) {
            $kept.Add('// Superseded by GregTech: this machine is removed by gc_gregify_removals.zs,')
            $kept.Add('// which loads after this file. See the note in tools\port-crafttweaker-scripts.ps1.')
            $kept.Add('// ' + $line)
            $commenting = $true
            continue
        }
        if ($commenting) {
            $kept.Add('// ' + $line)
            if ($line -match '^\s*\]\);') {
                $commenting = $false
            }
            continue
        }
        $kept.Add($line)
    }
    $text = ($kept -join "`r`n")

    # The GTCEu gas collector has no counterpart: GTCE-TJ registers 51 recipe maps and none of
    # them is a gas collector. The air -> oxygen statement is commented out rather than silently
    # dropped; oxygen comes from GregTech's electrolyser instead, which is what the addon's
    # Oxygen Compressor bottles.
    $lines = $text -split "`r?`n"
    $kept = New-Object System.Collections.Generic.List[string]
    $commenting = $false
    foreach ($line in $lines) {
        if (-not $commenting -and $line -match '<recipemap:gas_collector>') {
            $kept.Add('// UNPORTABLE - GTCE-TJ has no gas collector recipe map, so this statement')
            $kept.Add('// cannot be ported. Oxygen comes from GregTech''s electrolyser (water ->')
            $kept.Add('// hydrogen + oxygen) and is bottled by the addon''s Oxygen Compressor.')
            $kept.Add('// ' + $line)
            $commenting = $true
            continue
        }
        if ($commenting) {
            $kept.Add('// ' + $line)
            if ($line -match ';') {
                $commenting = $false
            }
            continue
        }
        $kept.Add($line)
    }
    $text = ($kept -join "`r`n")

    # <recipemap:name>.recipeBuilder()  ->  RecipeMap.getByName("name").recipeBuilder()
    $before = ([regex]::Matches($text, '<recipemap:[a-z_0-9]+>\.recipeBuilder\(\)')).Count
    $text = [regex]::Replace($text, '<recipemap:([a-z_0-9]+)>\.recipeBuilder\(\)', {
        param($match)
        $name = $match.Groups[1].Value
        if ($mapNames.ContainsKey($name)) {
            $name = $mapNames[$name]
        }
        'mods.gregtech.recipe.RecipeMap.getByName("' + $name + '").recipeBuilder()'
    })
    $rewritten += $before

    [System.IO.File]::WriteAllText((Join-Path $Target $file.Name), $header + $text, $utf8NoBom)
    $ported++
}

Write-Host "ported $ported scripts ($rewritten recipe-map accessors) into $Target"
