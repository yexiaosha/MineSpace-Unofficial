<#
    Which Ender IO recipes can hand out something that belongs to GregTech?

    The pack's rule is that another mod's machine does not get to produce this pack's materials or to
    perform GregTech's processing steps. This script reads Ender IO's own recipe XML and answers the
    question mechanically, family by family, instead of by eye:

      * every <recipe> in the recipe files, with the machine it belongs to
      * each output resolved through Ender IO's alias table (assets/enderio/config/recipes/aliases.xml)
      * the result classified:
          GT ITEM      the output is a GregTech or Gregicality item outright
          SHARED NAME  the output is a mod item that sits in an ore dictionary name which also holds a
                       GregTech item - the pack's "the GregTech item wins the name" case
          GT SHARED    the output is a vanilla or third-party item in a name that also holds a
                       GregTech item (dirty sulfur, glowstone dust, ...)

    Inputs (both produced by the probes described in TJ-MIGRATION-PLAN.md; re-run the probes to
    refresh them):

      -RecipesDir   a folder holding the unzipped assets/enderio/config/recipes/*.xml of every Ender IO
                    module that is installed (base + Endergy + ...)
      -OredictDump  the ore dictionary dump, one "name = item item item" per line

    Usage:
      tools\audit-eio-bypass.ps1 -RecipesDir $env:TEMP\eio-xml -OredictDump $env:TEMP\oredict.txt
#>
[CmdletBinding()]
param(
    [string]$RecipesDir = (Join-Path $env:TEMP 'eio-xml'),
    [string]$OredictDump = (Join-Path $env:TEMP 'oredict.txt'),
    [string]$UserRecipesFile = '',
    [string]$SkipLog = '',
    [string]$OutputPath = ''
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RecipesDir)) { throw "recipe folder not found: $RecipesDir" }
if (-not (Test-Path $OredictDump)) { throw "ore dictionary dump not found: $OredictDump" }

# ---------------------------------------------------------------- ore dictionary
$ore = @{}
foreach ($line in [System.IO.File]::ReadAllLines($OredictDump)) {
    if ($line -match '^([A-Za-z0-9_]+) = ?(.*)$') {
        $ore[$Matches[1]] = @($Matches[2].Trim() -split '\s+' | Where-Object { $_ -ne '' })
    }
}
$namesByItem = @{}
foreach ($name in $ore.Keys) {
    foreach ($item in $ore[$name]) {
        if (-not $namesByItem.ContainsKey($item)) { $namesByItem[$item] = New-Object System.Collections.Generic.List[string] }
        $namesByItem[$item].Add($name)
    }
}
function Test-GregtechItem([string]$id) { return $id -match '^(gregtech|gtadditions):' }

# ---------------------------------------------------------------- what Ender IO itself does not load
# Two sources, and both are needed: the pack's own disables live in the instance's user_recipes.xml
# (they are not in the mod's asset files at all), and Ender IO skips recipes whose inputs, outputs or
# dependency mods are missing - which it prints only with its debug log promoted.
$notLoaded = @{}
if ($UserRecipesFile -ne '' -and (Test-Path $UserRecipesFile)) {
    foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($UserRecipesFile),
            '<recipe name="([^"]+)"[^>]*disabled="true"')) {
        $notLoaded[$m.Groups[1].Value] = 'disabled by the pack'
    }
}
if ($SkipLog -ne '' -and (Test-Path $SkipLog)) {
    foreach ($line in [System.IO.File]::ReadAllLines($SkipLog)) {
        $parts = $line -split "`t"
        if ($parts.Count -ge 1 -and $parts[0] -ne '') {
            if (-not $notLoaded.ContainsKey($parts[0])) { $notLoaded[$parts[0]] = 'skipped by Ender IO' }
        }
    }
}

# ---------------------------------------------------------------- aliases
$alias = @{}
$aliasFile = Join-Path $RecipesDir 'aliases.xml'
if (Test-Path $aliasFile) {
    $text = [System.IO.File]::ReadAllText($aliasFile)
    foreach ($m in [regex]::Matches($text, '<alias name="([^"]+)" item="([^"]+)"')) {
        $alias[$m.Groups[1].Value] = $m.Groups[2].Value -split ','
    }
}

function Resolve-Token([string]$token) {
    $token = $token.Trim()
    if ($token -eq '') { return @() }
    if ($alias.ContainsKey($token)) { return @($alias[$token]) }
    return @($token)
}

# `<crafting>` belongs in this list: the first version of the tool audited only the mod's *machines* and
# therefore walked straight past `Ender Dust`, a crafting-table recipe in Ender IO's own XML that turns
# nine of its ender-pearl nuggets into one GregTech ender pearl dust. The crafting recipes register in
# the vanilla crafting registry like any other, so the same output resolution applies - the only thing
# they need is to be *seen*. See TJ-MIGRATION-PLAN.md 6bi.
$machines = 'alloying', 'sagmilling', 'smelting', 'casting', 'fermenting', 'tanking',
        'enchanting', 'soulbinding', 'painting', 'grinding', 'spawning', 'crafting'

$findings = New-Object System.Collections.Generic.List[object]
$perMachine = @{}

foreach ($file in (Get-ChildItem $RecipesDir -Filter '*.xml' |
        Where-Object { $_.Name -ne 'recipes.xsd' -and $_.Name -notlike '*.pdf' })) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    foreach ($block in ($text -split '(?=<recipe name=)')) {
        $m = [regex]::Match($block, '<recipe name="([^"]+)"([^>]*)>(.*?)</recipe>', 'Singleline')
        if (-not $m.Success) { continue }
        $name = $m.Groups[1].Value
        $attrs = $m.Groups[2].Value
        $body = $m.Groups[3].Value
        $mm = [regex]::Match($body, '<(' + ($machines -join '|') + ')')
        if (-not $mm.Success) { continue }
        $machine = $mm.Groups[1].Value
        if (-not $perMachine.ContainsKey($machine)) { $perMachine[$machine] = 0 }
        $perMachine[$machine]++

        $outputs = [System.Collections.Generic.List[string]]::new()
        foreach ($o in [regex]::Matches($body, '<output name="([^"]+)"')) { $outputs.Add($o.Groups[1].Value) }
        foreach ($o in [regex]::Matches($body, '<outputfluid name="([^"]+)"')) { $outputs.Add('fluid:' + $o.Groups[1].Value) }

        foreach ($raw in $outputs) {
            if ($raw -like 'fluid:*') { continue }   # fluids are checked by hand; see 6ba/6bz
            foreach ($token in (Resolve-Token $raw)) {
                $kind = $null
                $detail = ''
                if (Test-GregtechItem $token) {
                    $kind = 'GT ITEM'
                    $detail = $token
                } elseif ($ore.ContainsKey($token)) {
                    $members = $ore[$token]
                    $gt = @($members | Where-Object { Test-GregtechItem $_ })
                    if ($gt.Count -gt 0) {
                        $firstIsGt = Test-GregtechItem $members[0]
                        $kind = if ($firstIsGt) { 'GT ITEM' } else { 'SHARED NAME' }
                        $detail = "{0} = {1}" -f $token, ($members -join ' ')
                    }
                } elseif ($namesByItem.ContainsKey($token)) {
                    foreach ($n in $namesByItem[$token]) {
                        $members = $ore[$n]
                        if (@($members | Where-Object { Test-GregtechItem $_ }).Count -gt 0) {
                            $kind = 'GT SHARED'
                            $detail = "{0} is in {1} = {2}" -f $token, $n, ($members -join ' ')
                            break
                        }
                    }
                }
                if ($kind) {
                    $findings.Add([pscustomobject]@{
                        Kind    = $kind
                        Machine = $machine
                        File    = $file.Name
                        Recipe  = $name
                        Disabled = (($attrs -match 'disabled="true"') -or $notLoaded.ContainsKey($name))
                        Why     = $(if ($attrs -match 'disabled="true"') { 'disabled in the mod file' } elseif ($notLoaded.ContainsKey($name)) { $notLoaded[$name] } else { '' })
                        Output  = $raw
                        Detail  = $detail
                    })
                }
            }
        }
    }
}

$active = $findings | Where-Object { -not $_.Disabled } | Sort-Object Kind, Machine, Recipe -Unique
$disabled = $findings | Where-Object { $_.Disabled } | Sort-Object Machine, Recipe -Unique

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Ender IO recipes that touch a GregTech material")
$lines.Add("  recipes scanned per machine type: " + (($perMachine.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '))
$lines.Add("  findings still live: $($active.Count)   findings already switched off: $($disabled.Count)")
$lines.Add('')
$lines.Add('=== ENABLED - these still run -===')
foreach ($k in 'GT ITEM', 'SHARED NAME', 'GT SHARED') {
    $rows = $active | Where-Object { $_.Kind -eq $k } | Sort-Object Machine, Recipe
    $lines.Add("")
    $lines.Add("--- $k ($($rows.Count)) ---")
    foreach ($r in $rows) {
        $lines.Add(("  [{0,-10}] {1,-38} {2}" -f $r.Machine, $r.Recipe, $r.Detail))
    }
}
$lines.Add('')
$lines.Add("=== ALREADY SWITCHED OFF (pack user file or skipped by Ender IO) ($($disabled.Count)) ===")
foreach ($r in ($disabled | Sort-Object Machine, Recipe)) {
    $lines.Add(("  [{0,-10}] {1,-38} {2}" -f $r.Machine, $r.Recipe, $r.Why))
}

$report = $lines -join [Environment]::NewLine
if ($OutputPath -ne '') { [System.IO.File]::WriteAllText($OutputPath, $report, (New-Object System.Text.UTF8Encoding($false))) }
$report
