<#
    Photographs the star map without a player, in a scratch copy of the game.

    The screen has a camera inside it (see the class javadoc of MinespaceStarMapScreen, plan 6dt):
    -Dminespace.starmap.capture=<dir> makes it open itself at the main menu, write its poses to PNGs and
    quit. This script is the other half of that - it builds the jar, drops it into a game directory that
    holds no saves, assembles the classpath exactly the way Play-Minespace.ps1 does and launches.

    Why a scratch directory: the owner's own instance must never be touched by a diagnostic run, and a
    capture needs a game directory of its own anyway (its own logs/ and shots/).

    The gate is photographed too. A capture has no player, so it has no research data either - and since
    an unsurveyed body is not drawn at all, both ends of the rule are worth a picture:

        -Tier 6   everything this pack's own data opens (default): the whole chart
        -Tier 0   PlanetProgression has surveyed everything and the player holds no research data: the owner's
                  own state, with the sun's system complete and no exoplanet
        -Tier 1   the same, plus what research data I opens: a handful of nearby systems too
        -Tier -1  the real gate with no player: an empty chart, which is what "nothing unlocked" looks like

    Since 6eu the solar system is researched **one body at a time**, so the stand-in can answer for a single body:

        -Tier 0 -Surveyed moon    only the Moon surveyed: the chart should carry the Moon and nothing else

    Usage:
        .\tools\capture-starmap.ps1                     # full chart, six poses
        .\tools\capture-starmap.ps1 -Tier 0             # the owner's own state: telescope done, no survey data
        .\tools\capture-starmap.ps1 -Tier 1             # the same, one tier of survey data in
        .\tools\capture-starmap.ps1 -Tier -1            # nothing charted
        .\tools\capture-starmap.ps1 -Tier 0 -PlanetProgression $false -Surveyed moon   # one body surveyed
        .\tools\capture-starmap.ps1 -System Crab        # ... and a named system's own view
#>
[CmdletBinding()]
param(
    [string]$GameDir = 'D:\minespace-capture-run',
    [string]$ShotDir = '',
    [string]$System = '',
    [int]$Tier = 6,
    [bool]$PlanetProgression = $true,
    [string]$Surveyed = '',
    [int]$Width = 1920,
    [int]$Height = 1000,
    [int]$GuiScale = 2,
    [int]$MinMemoryMB = 2048,
    [int]$MaxMemoryMB = 4096,
    [string]$Username = 'Minespace',
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Pack = Join-Path (Split-Path -Parent $Repo) 'Minespace-unofficial-dev'
$Java = Join-Path $Pack 'runtime\jdk8\bin\java.exe'
$ForgeId = '1.12.2-forge-14.23.5.2859'
$ForgeJson = Join-Path $Pack "versions\$ForgeId\$ForgeId.json"
$Natives = Join-Path $Pack "versions\$ForgeId\natives"

if (-not (Test-Path $Java)) { throw "Java 8 missing at $Java" }
if (-not (Test-Path $ForgeJson)) { throw "Forge not installed ($ForgeJson)" }
if (-not (Test-Path $GameDir)) { throw "Game directory $GameDir does not exist" }
if ($ShotDir -eq '') { $ShotDir = Join-Path $GameDir 'shots' }
if (-not (Test-Path $ShotDir)) { New-Item -ItemType Directory -Path $ShotDir | Out-Null }

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'gradle.ps1') --console=plain build
    if ($LASTEXITCODE -ne 0) { throw 'Build failed - not launching a capture of the previous jar' }
}
$jar = Get-ChildItem (Join-Path $Repo 'build\libs') -Filter 'minespace-*.jar' |
        Where-Object { $_.Name -notmatch 'sources|javadoc' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $jar) { throw 'No built jar in build\libs' }
$mods = Join-Path $GameDir 'mods'
Get-ChildItem $mods -Filter 'minespace-*.jar' | Remove-Item -Force
Copy-Item $jar.FullName $mods -Force
Write-Host "Deployed $($jar.Name) to $mods"

# The GUI scale decides how much of the map fits in the frame: at "auto" a 1920x1000 window gets scale 4, which
# leaves 480x250 logical pixels and photographs the screen as a magnifying glass rather than as the screen. The
# owner plays at scale 2, so that is what the camera looks through.
$options = Join-Path $GameDir 'options.txt'
if (Test-Path $options) {
    $text = Get-Content -Raw $options
    if ($text -match '(?m)^guiScale:') {
        $text = $text -replace '(?m)^guiScale:.*$', "guiScale:$GuiScale"
    } else {
        $text = $text.TrimEnd() + "`nguiScale:$GuiScale`n"
    }
    Set-Content -Path $options -Value $text -NoNewline -Encoding ASCII
    Write-Host "guiScale set to $GuiScale in $options"
}

$forge = Get-Content -Raw $ForgeJson | ConvertFrom-Json
$base = Get-Content -Raw (Join-Path $Pack "versions\$($forge.inheritsFrom)\$($forge.inheritsFrom).json") | ConvertFrom-Json
$classpath = New-Object System.Collections.Generic.List[string]
foreach ($set in @($base.libraries, $forge.libraries)) {
    foreach ($lib in $set) {
        if ($lib.downloads.artifact.path) {
            $p = Join-Path $Pack ("libraries\" + ($lib.downloads.artifact.path -replace '/', '\'))
            if (Test-Path $p) { [void]$classpath.Add($p) }
        }
    }
}
$clientJar = Join-Path $Pack "versions\$($forge.inheritsFrom)\$($forge.inheritsFrom).jar"
[void]$classpath.Add($clientJar)
$versionJar = Join-Path $Pack "versions\$ForgeId\$ForgeId.jar"
if (Test-Path $versionJar) { [void]$classpath.Add($versionJar) }
$mainClass = if ($forge.mainClass) { $forge.mainClass } else { $base.mainClass }

$argsList = New-Object System.Collections.Generic.List[string]
[void]$argsList.Add("-Xmx${MaxMemoryMB}M")
[void]$argsList.Add("-Xms${MinMemoryMB}M")
[void]$argsList.Add("-Djava.library.path=$Natives")
[void]$argsList.Add('-Dfml.ignoreInvalidMinecraftCertificates=true')
[void]$argsList.Add('-Dfml.ignorePatchDiscrepancies=true')
# The flag this whole script exists for, plus what the camera pretends the player is carrying.
[void]$argsList.Add("-Dminespace.starmap.capture=$ShotDir")
[void]$argsList.Add("-Dminespace.starmap.capture.tier=$Tier")
# Whether the camera stands in for "PlanetProgression has surveyed everything" (see the screen's CAPTURE_PP): the
# other road into a body this pack registered is its own survey data, and -PlanetProgression $false photographs that
# one on its own.
[void]$argsList.Add("-Dminespace.starmap.capture.pp=$($PlanetProgression.ToString().ToLowerInvariant())")
if ($Surveyed -ne '') { [void]$argsList.Add("-Dminespace.starmap.capture.surveyed=$($Surveyed.ToLowerInvariant())") }
if ($System -ne '') { [void]$argsList.Add("-Dminespace.starmap.capture.system=$System") }
[void]$argsList.Add('-cp'); [void]$argsList.Add(($classpath -join ';'))
[void]$argsList.Add($mainClass)
[void]$argsList.Add('--username'); [void]$argsList.Add($Username)
[void]$argsList.Add('--version'); [void]$argsList.Add($ForgeId)
[void]$argsList.Add('--gameDir'); [void]$argsList.Add($GameDir)
[void]$argsList.Add('--assetsDir'); [void]$argsList.Add((Join-Path $Pack 'assets'))
[void]$argsList.Add('--assetIndex'); [void]$argsList.Add($base.assetIndex.id)
[void]$argsList.Add('--uuid'); [void]$argsList.Add('00000000000000000000000000000000')
[void]$argsList.Add('--accessToken'); [void]$argsList.Add('0')
[void]$argsList.Add('--userType'); [void]$argsList.Add('legacy')
# The window size is the frame being photographed: at the default 854x480 the vanilla GUI scale leaves
# 427x240 logical pixels, which is the map at a quarter of the detail the owner plays it at.
[void]$argsList.Add('--width'); [void]$argsList.Add("$Width")
[void]$argsList.Add('--height'); [void]$argsList.Add("$Height")
[void]$argsList.Add('--tweakClass'); [void]$argsList.Add('net.minecraftforge.fml.common.launcher.FMLTweaker')

Write-Host "Capturing the star map: tier $Tier, shots to $ShotDir, game dir $GameDir"
$AlsoftConf = Join-Path $Pack 'alsoft.ini'
if (Test-Path $AlsoftConf) { $env:ALSOFT_CONF = $AlsoftConf }
Push-Location $Pack
try { & $Java @argsList } finally { Pop-Location }
