<#
.SYNOPSIS
    Re-downloads the target mod jars from the CurseForge CDN and verifies their metadata.

.DESCRIPTION
    Writes the release (obfuscated) jars into the repository's libs/ folder, which is the
    reference copy of the target mods. This exists so the versions in MOD-MANIFEST.md do
    not have to be trusted blindly -- it rebuilds the set from numeric CurseForge file ids.

    It does NOT touch the running instance. To get these into the instance, either copy
    them into <repo>\Minespace-unofficial-dev\mods\, or let `tools\install-pack.ps1` +
    `gradlew deployToInstance` handle it.

    Note: these are the release jars. The development workspace does not use them for
    compiling -- build.gradle pulls the same versions through CurseMaven and fg.deobf(),
    because a coremod on the launch classpath does not register its own mod id (see
    DEV-NOTES.md section 3).

.PARAMETER Dest
    Where to write the jars. Defaults to this project's libs/ folder.

.PARAMETER InstanceMods
    Also copy the downloaded jars into the playable instance's mods/ folder.
#>

[CmdletBinding()]
param(
    [string]$Dest,
    [switch]$InstanceMods
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = Split-Path -Parent $PSScriptRoot          # <repo>\Minespace-unofficial
if (-not $Dest) { $Dest = Join-Path $projectRoot 'libs' }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

function Cdn([string]$id) { "https://edge.forgecdn.net/files/{0}/{1}/" -f $id.Substring(0, 4), $id.Substring(4) }

# CurseForge project id / file id pairs. Keep in sync with MOD-MANIFEST.md and build.gradle.
$files = @(
    @{ id = '5519022'; name = 'gregtech-1.12.2-2.8.10-beta.jar' },
    @{ id = '2779848'; name = 'CodeChickenLib-1.12.2-3.2.3.358-universal.jar' },
    @{ id = '6364107'; name = 'Galacticraft-1.12.2-4.0.7.jar' },
    @{ id = '3052392'; name = 'KubeJS-forge-1.12.2-1.1.0.65.jar' }
)

foreach ($f in $files) {
    $out = Join-Path $Dest $f.name
    if (Test-Path $out) { Write-Host "cached     $($f.name)"; continue }
    $url = (Cdn $f.id) + [Uri]::EscapeDataString($f.name)
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $out -TimeoutSec 300 -UserAgent 'Mozilla/5.0'
        Write-Host ("downloaded {0} ({1} bytes)" -f $f.name, (Get-Item $out).Length)
    } catch {
        Write-Host "FAILED     $($f.name): $($_.Exception.Message)"
        continue
    }
}

if ($InstanceMods) {
    $instanceMods = Join-Path (Split-Path -Parent $projectRoot) 'Minespace-unofficial-dev\mods'
    if (-not (Test-Path $instanceMods)) {
        throw "Instance mods folder not found at $instanceMods"
    }
    foreach ($f in $files) {
        $src = Join-Path $Dest $f.name
        if (Test-Path $src) { Copy-Item $src (Join-Path $instanceMods $f.name) -Force }
    }
    Write-Host "copied into $instanceMods"
}

Write-Host ''
Write-Host '=== mod metadata (modid / version / dependencies) ==='
foreach ($f in $files) {
    $jar = Join-Path $Dest $f.name
    if (-not (Test-Path $jar)) { continue }
    Write-Host "--- $($f.name)"
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($jar)
        foreach ($entryName in 'mcmod.info', 'META-INF/MANIFEST.MF') {
            $e = $zip.Entries | Where-Object { $_.FullName -eq $entryName }
            if (-not $e) { continue }
            $sr = New-Object IO.StreamReader($e.Open())
            $text = $sr.ReadToEnd(); $sr.Dispose()
            if ($entryName -eq 'META-INF/MANIFEST.MF') {
                $text -split "`r?`n" | Where-Object { $_ -match '^(FMLCorePlugin|FMLCorePluginContainsFMLMod|Implementation-Title|Implementation-Version)' } |
                    ForEach-Object { Write-Host "      $($_.Trim())" }
            } else {
                $text -split "`r?`n" | Where-Object { $_ -match '"(modid|name|version|mcversion|dependencies)"' } |
                    Select-Object -First 12 | ForEach-Object { Write-Host "      $($_.Trim())" }
            }
        }
        $zip.Dispose()
    } catch {
        Write-Host "    inspect failed: $($_.Exception.Message)"
    }
}
