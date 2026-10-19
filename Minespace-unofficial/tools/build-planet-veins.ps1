<#
    build-planet-veins.ps1 - writes the planet vein files from tools\planet-veins.psd1.

    Why this exists: the GTCEu galaxy plan wants 5..8 veins on every body, each with a geological
    reason (section 5.4), and makes "no ore generates twice and none is missing" an acceptance
    criterion (4.1). Both are properties of *the assignment* - and 6cx measured that the hand-written
    assignment had drifted into 74 pairs of duplicate (dimension, name), because a vein file could be
    edited for one body and forgotten for another.

    So the assignment lives in one table and this script derives the files from it. Three invariants
    are enforced here rather than by care:

      1. A managed body's vein list is exactly the variants whose `Bodies` contains it, so the same
         vein name can never appear twice on one body.
      2. A managed body's dimension id is *removed* from every other vein file, which is what kills
         the cross-folder duplication the audit reports.
      3. Every ore a variant names must already be in use by a vein file this run does not own. That
         is the 6cx lesson: 16 GTNH veins named materials that exist in this fork but have no ore
         block, and GregTech refuses the whole definition.

    Bodies the table does not manage are left byte-for-byte alone, so the migration can be done one
    body (or one system) at a time.

    Usage
        .\tools\build-planet-veins.ps1 -DryRun     # report what would change, write nothing
        .\tools\build-planet-veins.ps1             # write
#>
[CmdletBinding()]
param(
    [string]$TablePath = (Join-Path $PSScriptRoot 'planet-veins.psd1'),
    [string]$VocabularyPath = (Join-Path $PSScriptRoot 'ore-vocabulary.txt'),
    [string]$RegistryPath = (Join-Path $PSScriptRoot 'ore-registry.txt'),
    [string]$WorldgenDir = (Join-Path $PSScriptRoot '..\..\Minespace-unofficial-dev\config\gregtech\worldgen'),
    [switch]$UpdateVocabulary,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$invariant = [System.Globalization.CultureInfo]::InvariantCulture

# GTCE 1.12 reads worldgen JSON with InputStreamReader's platform default charset, not UTF-8.
# Writing Chinese directly therefore shows mojibake on a Chinese Windows (GBK) JVM. JSON's
# \uXXXX escapes are ASCII on disk and decode to the same characters under every charset.
function ConvertTo-JsonEscapedString([string]$value) {
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $value.ToCharArray()) {
        $code = [int][char]$ch
        if ($ch -eq '\') {
            [void]$builder.Append('\\')
        } elseif ($ch -eq '"') {
            [void]$builder.Append('\"')
        } elseif ($code -lt 32 -or $code -ge 128) {
            [void]$builder.AppendFormat('\u{0:x4}', $code)
        } else {
            [void]$builder.Append($ch)
        }
    }
    return $builder.ToString()
}

# Every dimension's vein count as the tree stands now, for the coverage comparison at the end. It has
# to be taken before anything is written, or a file that is about to be pruned still counts.
$coverageBefore = @{}
foreach ($file in Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json) {
    foreach ($match in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), 'dimension_id:\s*(-?\d+)')) {
        $id = [int]$match.Groups[1].Value
        $coverageBefore[$id] = 1 + [int]($coverageBefore[$id])
    }
}

$table = Import-PowerShellDataFile -Path $TablePath
$bodies = $table.Bodies
$variants = $table.Variants
$regions = if ($table.ContainsKey('Regions')) { $table.Regions } else { @{} }

$WorldgenDir = (Resolve-Path $WorldgenDir).Path

function Get-Relative([string]$path) { $path.Substring($WorldgenDir.Length).TrimStart('\') }

# ---- 1. validate the table ---------------------------------------------------------------------

$problems = New-Object System.Collections.Generic.List[string]

$bodyKeys = @($bodies.Keys)

# A variant's bodies come from two places: an explicit `Bodies` list, and the bodies that name it
# through a `Region` (that region's whole suite) or a `Signature` (that one body's own vein). The
# region layer is what keeps a hundred and ten bodies at one row each - and the solar system is
# deliberately not modelled this way, because twenty-five bodies justify their own cards.
$regionMembers = @{}
$signatureMembers = @{}

# A region's suite is its own variants plus everything it includes - the universal base for every layer,
# so a body only ever declares a delta plus a signature rather than repeating five names.
function Get-RegionVariants([string]$regionKey, [int]$depth) {
    $list = @()
    if ($depth -gt 4) { throw "region '$regionKey' includes itself" }
    $region = $regions[$regionKey]
    if ($region.ContainsKey('Variants')) { $list += @($region.Variants) }
    if ($region.ContainsKey('Includes')) {
        foreach ($included in $region.Includes) {
            if (-not $regions.ContainsKey($included)) {
                $problems.Add("region '$regionKey' includes '$included', which does not exist")
                continue
            }
            $list += Get-RegionVariants $included ($depth + 1)
        }
    }
    return ,@($list | Sort-Object -Unique)
}

foreach ($key in $bodyKeys) {
    if ($bodies[$key].ContainsKey('Region')) {
        $region = $bodies[$key].Region
        if (-not $regions.ContainsKey($region)) {
            $problems.Add("body '$key' names region '$region', which does not exist")
        } else {
            foreach ($variantId in (Get-RegionVariants $region 0)) {
                if (-not $regionMembers.ContainsKey($variantId)) { $regionMembers[$variantId] = @() }
                $regionMembers[$variantId] += $key
            }
        }
    }
    if ($bodies[$key].ContainsKey('Signature')) {
        $variantId = $bodies[$key].Signature
        if (-not $signatureMembers.ContainsKey($variantId)) { $signatureMembers[$variantId] = @() }
        $signatureMembers[$variantId] += $key
    }
}

function Get-VariantBodies($variant) {
    $members = @()
    if ($variant.ContainsKey('Bodies')) { $members += @($variant.Bodies) }
    if ($regionMembers.ContainsKey($variant.Id)) { $members += $regionMembers[$variant.Id] }
    if ($signatureMembers.ContainsKey($variant.Id)) { $members += $signatureMembers[$variant.Id] }
    # Returns a plain array: a one-element array unrolls at a function boundary, so every call site
    # wraps the result in @() instead. (Returning `,@(...)` here would break the pipeline use below,
    # where the wrapped array arrives as a single element.)
    return @($members | Sort-Object -Unique)
}

# A body can be *designed* before its dimension exists: PLANET-CATALOG assigns ids for 86 deep-space
# targets, but nothing in the game has them yet. Generating their files now would put veins into JEI
# for planets nobody can reach, which is the opposite of what 6cu set out to fix. So a pending body
# contributes to the design (its veins are counted, the catalog can read them) and not to the output.
$pendingKeys = @($bodyKeys | Where-Object { $bodies[$_].ContainsKey('Pending') -and $bodies[$_].Pending })
function Get-GeneratedBodies($variant) {
    return @(Get-VariantBodies $variant | Where-Object { $pendingKeys -notcontains $_ })
}

foreach ($regionKey in $regions.Keys) {
    if ($regions[$regionKey].ContainsKey('Planned') -and $regions[$regionKey].Planned) { continue }
    foreach ($variantId in (Get-RegionVariants $regionKey 0)) {
        if (-not ($variants | Where-Object { $_.Id -eq $variantId })) {
            $problems.Add("region '$regionKey' names variant '$variantId', which does not exist")
        }
    }
}

$seenIds = @{}
foreach ($variant in $variants) {
    if ($seenIds.ContainsKey($variant.Id)) { $problems.Add("variant id '$($variant.Id)' is used twice") }
    $seenIds[$variant.Id] = $true

    $share = 0
    foreach ($ore in $variant.Ores) { $share += $ore.Share }
    if ($share -ne 100) { $problems.Add("$($variant.Id): ore shares sum to $share, not 100") }
    if ($variant.Ores.Count -lt 2 -or $variant.Ores.Count -gt 4) {
        $problems.Add("$($variant.Id): $(($variant.Ores).Count) ore slots - the plan's shape is primary/secondary/byproduct, so 2..4")
    }
    if ($variant.Min -ge $variant.Max) { $problems.Add("$($variant.Id): min_height $($variant.Min) is not below max_height $($variant.Max)") }
    if ($variant.Radius[0] -gt $variant.Radius[1]) { $problems.Add("$($variant.Id): radius low is above radius high") }
    if ($variant.Weight -le 0) { $problems.Add("$($variant.Id): weight must be positive") }
    if (-not $variant.Reason) { $problems.Add("$($variant.Id): no geological reason - the plan requires one per vein") }
    $members = @(Get-VariantBodies $variant)
    if ($members.Count -eq 0) {
        $problems.Add("$($variant.Id): no body carries it - give it a Bodies list, a Region suite or a Signature")
    }
    foreach ($key in $members) {
        if ($bodyKeys -notcontains $key) { $problems.Add("$($variant.Id): body '$key' is not in the table") }
    }
}

# One body may not carry the same name twice, and no name may be claimed by two variants.
$byName = @{}
foreach ($variant in $variants) {
    if ($byName.ContainsKey($variant.Name)) { $problems.Add("vein name '$($variant.Name)' is claimed by two variants") }
    $byName[$variant.Name] = $variant.Id
}
foreach ($key in $bodyKeys) {
    $names = @($variants | Where-Object { (Get-VariantBodies $_) -contains $key } | ForEach-Object { $_.Name })
    $duplicates = $names | Group-Object | Where-Object Count -gt 1
    foreach ($duplicate in $duplicates) { $problems.Add("body '$key' carries '$($duplicate.Name)' twice") }
    if ($names.Count -lt 5 -or $names.Count -gt 8) {
        $problems.Add("body '$key' has $($names.Count) veins - the plan asks for 5..8")
    }
}

$managedIds = @{}
foreach ($key in $bodyKeys) { $managedIds[[int]$bodies[$key].DimensionId] = $key }

# A body lives in its own folder unless it declares one, because the nearby-system bodies share the
# `barnarda` folder. Every body in the table is managed, so every one of these folders is prunable.
function Get-BodyFolder([string]$key) {
    if ($bodies[$key].ContainsKey('Folder')) { return $bodies[$key].Folder }
    return $key
}
# Pending bodies own no folder yet - there is nothing of theirs on disk to prune.
$managedFolders = @($bodyKeys | Where-Object { $pendingKeys -notcontains $_ } |
        ForEach-Object { Get-BodyFolder $_ } | Sort-Object -Unique)

# Where a variant is written. A shared variant has no owner, so it declares its folder rather than
# having one picked for it - otherwise editing the table would silently move the file, because the
# members come back sorted.
function Get-VariantFolder($variant, [string]$firstMember) {
    if ($variant.ContainsKey('Folder')) { return $variant.Folder }
    return Get-BodyFolder $firstMember
}

# ---- 2. the ore vocabulary a variant may draw from ---------------------------------------------

# The baseline file plus everything the config uses today. The file is what makes the check survive
# the migration: rebuilding a set of bodies deletes the files that used to name an ore, and a check
# that only read the live tree would then reject the ore it is trying to restore. See
# `ore-vocabulary.txt` for where the list comes from.
$vocabulary = New-Object System.Collections.Generic.HashSet[string]
if (Test-Path $VocabularyPath) {
    foreach ($line in Get-Content $VocabularyPath) {
        $value = $line.Trim()
        if ($value -and -not $value.StartsWith('#')) { [void]$vocabulary.Add($value) }
    }
}
$liveVocabulary = New-Object System.Collections.Generic.HashSet[string]
foreach ($file in Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json) {
    # The material is the last segment: GalacticGreg's filler accepts `ore:poor:precious_metal` and
    # friends, where the middle word is a quality rather than a material.
    foreach ($match in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), 'ore:(?:poor:|pure:|rich:)?([a-z0-9_]+)')) {
        [void]$vocabulary.Add($match.Groups[1].Value)
        [void]$liveVocabulary.Add($match.Groups[1].Value)
    }
}

# The strongest evidence of all, and the one that lets a *gap* be filled: the registry dump says which
# materials GregTech gives an ore block to. The vocabulary file records what a clean server start has
# seen pass through a vein; this records what the ore block itself is. Without it, the twenty materials
# 6dc listed as unsourced could never be placed - the check would refuse the very ore it asks for.
if (Test-Path $RegistryPath) {
    foreach ($line in Get-Content $RegistryPath) {
        if ($line -match '^VPROBE (\S+) ore=1') { [void]$vocabulary.Add($Matches[1]) }
    }
}

if ($UpdateVocabulary) {
    # Only what the config actually uses - the baseline must never refresh itself from its own guesses,
    # which is how three bad names got in. Run this after a server start that parsed cleanly.
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Refreshed by build-planet-veins.ps1 -UpdateVocabulary. See the header for the rules.')
    foreach ($value in $liveVocabulary | Sort-Object) { $lines.Add($value) }
    [System.IO.File]::WriteAllText($VocabularyPath, (($lines -join "`n") + "`n"), $utf8NoBom)
    Write-Host ("vocabulary written: {0} ores -> {1}" -f $liveVocabulary.Count, $VocabularyPath)
    return
}

foreach ($variant in $variants) {
    foreach ($ore in $variant.Ores) {
        if (-not $vocabulary.Contains($ore.Ore)) {
            $problems.Add("$($variant.Id): 'ore:$($ore.Ore)' is not used anywhere in the config today, so there is no evidence it has an ore block (6cx)")
        }
    }
    if (-not $vocabulary.Contains($variant.Rock)) {
        $problems.Add("$($variant.Id): surface rock '$($variant.Rock)' is not in the ore vocabulary")
    }
}

if ($problems.Count -gt 0) {
    Write-Host 'the table does not satisfy its own rules:' -ForegroundColor Red
    $problems | ForEach-Object { Write-Host "    $_" }
    throw "$($problems.Count) problem(s) in $TablePath"
}

Write-Host ("table: {0} variants, {1} managed body/bodies, ore vocabulary {2}" -f `
        $variants.Count, $bodyKeys.Count, $vocabulary.Count)

# ---- 3. write the vein files -------------------------------------------------------------------

function Format-VeinJson($variant, [int[]]$dimensionIds) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('{')
    $lines.Add('    "name": "' + (ConvertTo-JsonEscapedString $variant.Name) + '",')
    $lines.Add('    "description": "' + (ConvertTo-JsonEscapedString $variant.Reason) + '",')
    $lines.Add('    "weight": ' + $variant.Weight + ',')
    $lines.Add('    "density": ' + ([double]$variant.Density).ToString($invariant) + ',')
    $lines.Add('    "min_height": ' + $variant.Min + ',')
    $lines.Add('    "max_height": ' + $variant.Max + ',')
    $lines.Add('    "generator": {')
    $lines.Add('        "type": "ellipsoid",')
    $lines.Add('        "radius": [' + $variant.Radius[0] + ', ' + $variant.Radius[1] + ']')
    $lines.Add('    },')
    $lines.Add('    "filler": {')
    $lines.Add('        "type": "simple",')
    $lines.Add('        "value": {')
    $lines.Add('            "type": "weight_random",')
    $lines.Add('            "values": [')
    for ($i = 0; $i -lt $variant.Ores.Count; $i++) {
        $comma = if ($i -lt $variant.Ores.Count - 1) { ',' } else { '' }
        $lines.Add('                {"weight": ' + $variant.Ores[$i].Share + ', "value": "ore:' + $variant.Ores[$i].Ore + '"}' + $comma)
    }
    $lines.Add('            ]')
    $lines.Add('        }')
    $lines.Add('    },')
    $lines.Add('    "vein_populator": {')
    $lines.Add('        "type": "surface_rock",')
    $lines.Add('        "material": "' + $variant.Rock + '"')
    $lines.Add('    },')
    $lines.Add('    "dimension_filter": [')
    for ($i = 0; $i -lt $dimensionIds.Count; $i++) {
        $comma = if ($i -lt $dimensionIds.Count - 1) { ',' } else { '' }
        $lines.Add('        "dimension_id:' + $dimensionIds[$i] + '"' + $comma)
    }
    $lines.Add('    ]')
    $lines.Add('}')
    return ($lines -join "`n") + "`n"
}

$written = New-Object System.Collections.Generic.List[string]
$designedOnly = New-Object System.Collections.Generic.List[string]
foreach ($variant in $variants) {
    $members = @(Get-GeneratedBodies $variant)
    if ($members.Count -eq 0) {
        # Designed, but every body that carries it is waiting for its dimension. Nothing is written.
        $designedOnly.Add($variant.Id)
        continue
    }
    $ids = @($members | ForEach-Object { [int]$bodies[$_].DimensionId } | Sort-Object)
    $folder = Get-VariantFolder $variant $members[0]
    $target = Join-Path (Join-Path $WorldgenDir $folder) ($variant.Id + '_vein.json')
    $json = Format-VeinJson $variant $ids
    if ($DryRun) {
        Write-Host ("  would write {0} ({1} dim(s))" -f $target.Substring($WorldgenDir.Length).TrimStart('\'), $ids.Count)
    } else {
        # A body that never had a folder of its own (Europa had none, because every file that reached
        # it lived in the moon folder) gets one here.
        $targetDir = Split-Path $target -Parent
        if (-not (Test-Path $targetDir)) { [void](New-Item -ItemType Directory -Path $targetDir) }
        [System.IO.File]::WriteAllText($target, $json, $utf8NoBom)
    }
    $written.Add($target)
}

# ---- 4. a managed body owns its folder, and its id leaves every other file ----------------------

$removedFiles = 0
foreach ($folder in $managedFolders) {
    $folderPath = Join-Path $WorldgenDir $folder
    if (-not (Test-Path $folderPath)) { continue }
    foreach ($file in Get-ChildItem -Path $folderPath -Filter *.json) {
        if ($written -contains $file.FullName) { continue }
        $removedFiles++
        if ($DryRun) {
            Write-Host ("  would delete {0}" -f (Get-Relative $file.FullName))
        } else {
            Remove-Item -LiteralPath $file.FullName -Force
            Write-Host ("  deleted {0}" -f (Get-Relative $file.FullName))
        }
    }
}

$stripped = 0
$emptied = New-Object System.Collections.Generic.List[string]
foreach ($file in Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json) {
    if ($written -contains $file.FullName) { continue }
    # A managed body's own folder is either written above or deleted above - never stripped.
    if ($managedFolders -contains (Split-Path (Get-Relative $file.FullName) -Parent)) { continue }
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $match = [regex]::Match($text, '(?m)^(?<indent>[ \t]*)"dimension_filter"\s*:\s*\[(?<body>[^\]]*)\]')
    if (-not $match.Success) { continue }

    $ids = @([regex]::Matches($match.Groups['body'].Value, 'dimension_id:\s*(-?\d+)') |
            ForEach-Object { [int]$_.Groups[1].Value })
    $kept = @($ids | Where-Object { -not $managedIds.ContainsKey($_) })
    if ($kept.Count -eq $ids.Count) { continue }

    $relative = Get-Relative $file.FullName
    if ($kept.Count -eq 0) {
        $emptied.Add($relative)
        Write-Host ("  WARNING {0} would be left with no dimension at all - it generates nowhere now" -f $relative) -ForegroundColor Yellow
    }

    if ($DryRun) {
        Write-Host ("  would strip {0} from {1} -> {2} dim(s)" -f `
                (($ids | Where-Object { $managedIds.ContainsKey($_) }) -join ','), $relative, $kept.Count)
        $stripped++
        continue
    }

    $indent = $match.Groups['indent'].Value
    if ($kept.Count -eq 1) {
        $replacement = $indent + '"dimension_filter": ["dimension_id:' + $kept[0] + '"]'
    } else {
        $entries = @($kept | ForEach-Object { $indent + '    "dimension_id:' + $_ + '"' })
        $replacement = $indent + '"dimension_filter": [' + "`n" + ($entries -join ",`n") + "`n" + $indent + ']'
    }
    $updated = $text.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)
    [System.IO.File]::WriteAllText($file.FullName, $updated, $utf8NoBom)
    $stripped++
}

# ---- 5. report ---------------------------------------------------------------------------------

Write-Host ''
Write-Host ("vein files written: {0}   old files removed: {1}   files stripped of a managed id: {2}" -f `
        $written.Count, $removedFiles, $stripped)

foreach ($key in $bodyKeys) {
    $names = @($variants | Where-Object { (Get-VariantBodies $_) -contains $key } | ForEach-Object { $_.Name })
    $total = 0
    foreach ($variant in $variants | Where-Object { (Get-VariantBodies $_) -contains $key }) { $total += $variant.Weight }
    Write-Host ''
    Write-Host ("{0} ({1}) - {2} veins, total weight {3}" -f `
            $bodies[$key].Display, $bodies[$key].DimensionId, $names.Count, $total)
    foreach ($variant in $variants | Where-Object { (Get-VariantBodies $_) -contains $key }) {
        $share = [math]::Round(100 * $variant.Weight / $total, 1)
        Write-Host ("    {0,-28} {1,4}  {2,5}%  {3}..{4}  {5}" -f `
                $variant.Name, $variant.Weight, $share, $variant.Min, $variant.Max,
                (($variant.Ores | ForEach-Object { $_.Ore }) -join ' / '))
    }
}

if ($emptied.Count -gt 0) {
    Write-Host ''
    Write-Host 'definitions left with no dimension (add them to the table or delete them):' -ForegroundColor Yellow
    $emptied | ForEach-Object { Write-Host "    $_" }
}

# The layers that exist in the plan but have no bodies yet. Printed here because this is where the next
# body gets added, and because "planned" is a claim the table should have to keep repeating.
$planned = @($regions.Keys | Where-Object {
        $regions[$_].ContainsKey('Planned') -and $regions[$_].Planned
    } | Sort-Object { [int]$regions[$_].Stage })
if ($planned.Count -gt 0) {
    Write-Host ''
    Write-Host ("planned layers ({0}) - theme only, no bodies and no veins yet:" -f $planned.Count)
    foreach ($key in $planned) {
        Write-Host ("    {0,-28} stage {1}  {2}" -f $regions[$key].Display, $regions[$key].Stage,
                $regions[$key].Layer)
        if ($regions[$key].ContainsKey('Note')) { Write-Host ("        {0}" -f $regions[$key].Note) }
    }
}

    # Bodies whose cards are written but whose world is still the shared void provider. Their dimension id
    # *is* registered - the star map needs it - and 6dn measured that a void world cannot hold ore at all,
    # so there is nothing for a vein file to generate in until the body gets terrain of its own. The design
    # is in the table and the catalog can read it; nothing of it is in the config until then.
if ($pendingKeys.Count -gt 0) {
    Write-Host ''
        Write-Host ("designed but not generated: {0} bodies, {1} variants (id registered, world still void):" -f `
            $pendingKeys.Count, $designedOnly.Count)
    foreach ($key in $pendingKeys | Sort-Object { [int]$bodies[$_].DimensionId }) {
        $names = @($variants | Where-Object { (Get-VariantBodies $_) -contains $key } | ForEach-Object { $_.Name })
        Write-Host ("    {0,-22} {1,6}  {2} veins" -f $bodies[$key].Display,
                $bodies[$key].DimensionId, $names.Count)
    }
}

# A body can lose its veins without any single file being obviously at fault: the folders a run
# prunes were often the only coverage for *other* bodies. That happened twice - once with `moon`
# (which was covering five bodies) and once with `mars`/`venus`/`asteroids` (fourteen). Comparing
# coverage before and after catches it whatever the cause.
if (-not $DryRun) {
    $coverageAfter = @{}
    foreach ($file in Get-ChildItem -Path $WorldgenDir -Recurse -Filter *.json) {
        foreach ($match in [regex]::Matches([System.IO.File]::ReadAllText($file.FullName), 'dimension_id:\s*(-?\d+)')) {
            $id = [int]$match.Groups[1].Value
            $coverageAfter[$id] = 1 + [int]($coverageAfter[$id])
        }
    }
    $lost = @($coverageBefore.Keys | Where-Object { $coverageBefore[$_] -gt 0 -and -not $coverageAfter.ContainsKey($_) } | Sort-Object)
    $short = @($coverageBefore.Keys | Where-Object { $coverageAfter.ContainsKey($_) -and $coverageAfter[$_] -lt $coverageBefore[$_] } | Sort-Object)
    if ($lost.Count -gt 0) {
        Write-Host ''
        Write-Host 'WARNING - these dimensions had veins before this run and have none now:' -ForegroundColor Red
        $lost | ForEach-Object { Write-Host ("    dimension {0}" -f $_) -ForegroundColor Red }
        Write-Host 'Add them to the table, or none of them can be mined.' -ForegroundColor Red
    } elseif ($short.Count -gt 0) {
        Write-Host ''
        Write-Host ("coverage reduced (but not lost) on {0} dimension(s): {1}" -f `
                $short.Count, ($short -join ','))
    }
}

if ($DryRun) { Write-Host ''; Write-Host 'dry run - nothing was written' }
