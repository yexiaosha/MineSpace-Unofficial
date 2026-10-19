<#
    verify-pack.ps1 - build, boot the scratch dedicated server, and check the
    invariants that are easy to regress:

      * the server reaches "Done"
      * no new crash report or Minespace mixin/linkage failure
      * GT worldgen definitions and the four BYG mixed-vein placements load
      * BYG <-> GT item/block conversions, GT tools and GT-plate armour exist
      * BYG's old block/tool recipes are gone

    Usage:
        .\tools\verify-pack.ps1
        .\tools\verify-pack.ps1 -SkipBuild
        .\tools\verify-pack.ps1 -KeepServer

    The scratch instance defaults to D:\minespace-capture-run. It is deleted
    from nothing; only its run-console logs and crash reports from this run are
    examined.
#>
[CmdletBinding()]
param(
    [string]$GameDir = 'D:\minespace-capture-run',
    [int]$MaxMemoryMB = 3072,
    [int]$TimeoutSeconds = 180,
    [switch]$SkipBuild,
    [switch]$KeepServer
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$gradle = Join-Path $PSScriptRoot 'gradle.ps1'
$runner = Join-Path $PSScriptRoot 'run-server.ps1'
$outLog = Join-Path $GameDir 'run-console.out.log'
$errLog = Join-Path $GameDir 'run-console.err.log'
$latestLog = Join-Path $GameDir 'logs\latest.log'
$craftTweakerLog = Join-Path $GameDir 'crafttweaker.log'
$crashDir = Join-Path $GameDir 'crash-reports'
$diagDir = Join-Path $GameDir 'minespace-diagnostics'
$craftingCsv = Join-Path $diagDir 'crafting-recipes.csv'
$startTime = Get-Date
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check([string]$name, [bool]$ok, [string]$detail) {
    $script:checks.Add([pscustomobject]@{ Name = $name; Ok = $ok; Detail = $detail })
}

function Read-Text([string]$path) {
    if (Test-Path -LiteralPath $path) {
        return (Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue)
    }
    return ''
}

function Count-Lines([string]$path, [string]$pattern) {
    if (-not (Test-Path -LiteralPath $path)) {
        return 0
    }
    return @(Get-Content -LiteralPath $path -ErrorAction SilentlyContinue |
            Where-Object { $_ -match $pattern }).Count
}

# One server at a time: the previous scratch server may still own the port and
# the jar. These are the processes launched by run-server.ps1, not a player's
# client or another instance.
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -like '*fml.queryResult=confirm*' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep -Seconds 2
foreach ($file in @($outLog, $errLog)) {
    if (Test-Path -LiteralPath $file) {
        [System.IO.File]::Delete($file)
    }
}
foreach ($file in @($latestLog, $craftTweakerLog)) {
    if (Test-Path -LiteralPath $file) {
        [System.IO.File]::Delete($file)
    }
}

if (-not $SkipBuild) {
    & $gradle --console=plain --offline build
    if ($LASTEXITCODE -ne 0) {
        throw 'Gradle build failed'
    }
}

$env:JAVA_TOOL_OPTIONS =
    '-Dminespace.exportDiagnostics=true -Dnet.minecraftforge.gradle.test_certs=false -Djava.net.useSystemProxies=true'
$launcher = Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $runner,
        '-SkipBuild', '-GameDir', $GameDir, '-MaxMemoryMB', "$MaxMemoryMB") `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -WindowStyle Hidden -PassThru

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$done = $false
while ((Get-Date) -lt $deadline) {
    $currentLatest = Read-Text $latestLog
    if ($currentLatest -match 'Done \(') {
        $done = $true
        break
    }
    if ($launcher.HasExited) {
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $done) {
    $currentLatest = Read-Text $latestLog
    if ($currentLatest -match 'Done \(') {
        $done = $true
    }
}

$server = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
    Where-Object { $_.CommandLine -like '*fml.queryResult=confirm*' } |
    Select-Object -First 1

$latest = Read-Text $latestLog
$crafting = Read-Text $craftingCsv
$craftTweaker = Read-Text $craftTweakerLog
$newCrashes = @()
if (Test-Path -LiteralPath $crashDir) {
    $newCrashes = @(Get-ChildItem -LiteralPath $crashDir -File -Filter '*.txt' |
            Where-Object { $_.LastWriteTime -gt $startTime })
}

if (-not $KeepServer -and $server) {
    Stop-Process -Id $server.ProcessId -Force
    Start-Sleep -Seconds 1
}

Add-Check 'server reaches Done' $done `
    $(if ($done) { 'latest.log contains Done' } else { "timed out after ${TimeoutSeconds}s" })
Add-Check 'latest.log present' (Test-Path -LiteralPath $latestLog) `
    $(if (Test-Path -LiteralPath $latestLog) { 'present' } else { 'missing' })
Add-Check 'no new crash report' ($newCrashes.Count -eq 0) `
    $(if ($newCrashes.Count -eq 0) { 'none' } else { ($newCrashes.Name -join ', ') })

$linkageErrors = ($latest -match 'NoSuchMethodError|NoClassDefFoundError|InvalidMixin|Mixin apply failed|Mixin apply.*failed')
Add-Check 'no Minespace mixin/linkage failure' (-not $linkageErrors) `
    $(if ($linkageErrors) { 'found mixin/linkage error in latest.log' } else { 'none' })

$wrappedWorldgenErrors = Count-Lines $latestLog 'Error in another mod.s worldgen'
Add-Check 'no Galacticraft-wrapped worldgen errors' ($wrappedWorldgenErrors -eq 0) `
    "$wrappedWorldgenErrors error lines"

$worldgenCount = 0
if ($latest -match 'Loaded (\d+) worldgen definitions') {
    $worldgenCount = [int]$Matches[1]
}
Add-Check 'GT worldgen definitions loaded' ($worldgenCount -ge 128) "$worldgenCount definitions"

$mixed = ([regex]::Matches($latest, 'BYG mixed vein: byg:(kasai|latharium|pendorite|tamrelite)_ore appears in')).Count
Add-Check 'four BYG ores are in GT mixed veins' ($mixed -eq 4) "$mixed/4 placements"

$conversionCount = Count-Lines $craftingCsv 'minespace_(byg|gt)_(kasai|latharium|pendorite|tamrelite)'
Add-Check 'BYG <-> GT item/block conversions' ($conversionCount -eq 16) "$conversionCount/16 recipes"

$toolCount = Count-Lines $craftingCsv 'gtadditions:head_toolhead(pickaxe|shovel|sword|axe|hoe)_(kasai|latharium|pendorite|tamrelite)'
Add-Check 'four materials x five GT tool heads' ($toolCount -eq 20) "$toolCount/20 recipes"

$oldToolCount = Count-Lines $craftingCsv '^"byg:(kasai|latharium|pendorite|tamrelite)_(pickaxe|shovel|sword|axe|hoe|battleaxe)"'
Add-Check 'old BYG tool recipes removed' ($oldToolCount -eq 0) "$oldToolCount remaining"

$armourCount = Count-Lines $craftingCsv '"byg:(kasai|latharium|pendorite|tamrelite)_armour_.*gregtech:meta_item_1'
Add-Check 'BYG armour uses GT plates' ($armourCount -eq 16) "$armourCount/16 recipes"

$oldBlockCount = Count-Lines $craftingCsv '^"byg:(kasai|latharium|pendorite|tamrelite)_(block|gem|ingot)"'
Add-Check 'old BYG block/gem/ingot recipes removed' ($oldBlockCount -eq 0) "$oldBlockCount remaining"

Add-Check 'crafttweaker.log present' (Test-Path -LiteralPath $craftTweakerLog) `
    $(if (Test-Path -LiteralPath $craftTweakerLog) { 'present' } else { 'missing' })
$ctErrors = Count-Lines $craftTweakerLog '\bERROR\b'
Add-Check 'CraftTweaker has no errors' ($ctErrors -eq 0) "$ctErrors error lines"

$failed = @($checks | Where-Object { -not $_.Ok })
foreach ($check in $checks) {
    $tag = if ($check.Ok) { 'PASS' } else { 'FAIL' }
    Write-Host ("[{0}] {1} - {2}" -f $tag, $check.Name, $check.Detail)
}
if (-not $KeepServer -and $server) {
    Write-Host 'Server stopped.'
} elseif ($KeepServer -and $server) {
    Write-Host "Server left running (pid $($server.ProcessId))."
} elseif (-not $server) {
    Write-Host 'Server process already exited.'
}
if ($failed.Count -gt 0) {
    exit 1
}
exit 0
