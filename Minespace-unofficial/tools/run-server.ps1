<#
    Runs the pack as a dedicated server against a scratch game directory.

    Why this exists next to Play-Minespace.ps1: that launcher always uses the development instance
    (Minespace-unofficial-dev) as its game directory, which holds the owner's world. The boot checks this
    project runs every round ("does the pack still come up, how many worldgen definitions, how many
    exceptions") must not touch it, so this script assembles the same classpath, swaps in the vanilla
    *server* jar the way the launcher's -Server switch does, and points Forge at a directory of its own.

    Usage:
        .\tools\run-server.ps1                                   # D:\minespace-capture-run, stops when done
        .\tools\run-server.ps1 -GameDir D:\somewhere -SkipBuild
#>
[CmdletBinding()]
param(
    [string]$GameDir = 'D:\minespace-capture-run',
    [int]$MaxMemoryMB = 3072,
    [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Pack = Join-Path (Split-Path -Parent $Repo) 'Minespace-unofficial-dev'
$Java = Join-Path $Pack 'runtime\jdk8\bin\java.exe'
$ForgeId = '1.12.2-forge-14.23.5.2859'
$ForgeJson = Join-Path $Pack "versions\$ForgeId\$ForgeId.json"
if (-not (Test-Path $GameDir)) { throw "Game directory $GameDir does not exist" }

if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'gradle.ps1') --console=plain build
    if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
}
$jar = Get-ChildItem (Join-Path $Repo 'build\libs') -Filter 'minespace-*.jar' |
        Where-Object { $_.Name -notmatch 'sources|javadoc' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
$mods = Join-Path $GameDir 'mods'
Get-ChildItem $mods -Filter 'minespace-*.jar' | Remove-Item -Force
Copy-Item $jar.FullName $mods -Force
Write-Host "Deployed $($jar.Name) to $mods"

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
# The server jar *replaces* the client jar: it holds the shared classes as well as
# net.minecraft.server.dedicated.DedicatedServer, and leaving both on the path makes the client's copies
# shadow the server's (see Play-Minespace.ps1 for the whole explanation).
$serverJar = Join-Path $Pack "versions\$($forge.inheritsFrom)\minecraft_server.$($forge.inheritsFrom).jar"
if (-not (Test-Path $serverJar)) { throw "Vanilla server jar missing at $serverJar" }
[void]$classpath.Add($serverJar)
$mainClass = if ($forge.mainClass) { $forge.mainClass } else { $base.mainClass }

$argsList = New-Object System.Collections.Generic.List[string]
[void]$argsList.Add("-Xmx${MaxMemoryMB}M")
# Forge stops the boot with "Missing minecraft:items: ..." and waits for a yes/no when a world's item registry names
# something that no longer exists - which happens every time the set of registered bodies changes, and PlanetProgression
# registers one research paper per registered body. A scratch instance answers it up front so the run reaches "Done".
[void]$argsList.Add('-Dfml.queryResult=confirm')
[void]$argsList.Add('-cp'); [void]$argsList.Add(($classpath -join ';'))
[void]$argsList.Add($mainClass)
[void]$argsList.Add('nogui')
[void]$argsList.Add('--tweakClass'); [void]$argsList.Add('net.minecraftforge.fml.common.launcher.FMLServerTweaker')

Write-Host "Starting the dedicated server in $GameDir"
Push-Location $GameDir
try { & $Java @argsList } finally { Pop-Location }
