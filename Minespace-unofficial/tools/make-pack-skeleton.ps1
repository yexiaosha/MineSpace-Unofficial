<#
.SYNOPSIS
    Creates the modpack instance skeleton (folders only).

.DESCRIPTION
    Idempotent: existing folders and files are left alone. This only lays out the
    directory structure of the playable instance; it does not download Minecraft,
    Forge, assets or mod jars.

    For a launchable instance run tools\install-pack.ps1, which lays out the same
    structure and then fills it in.
#>

[CmdletBinding()]
param(
    [string]$Pack
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot          # <repo>\Minespace-unofficial
if (-not $Pack) { $Pack = Join-Path (Split-Path -Parent $projectRoot) 'Minespace-unofficial-dev' }

$dirs = @(
    '', 'mods', 'config', 'scripts', 'resources',
    'kubejs', 'kubejs/startup_scripts', 'kubejs/server_scripts',
    'kubejs/client_scripts', 'kubejs/assets', 'kubejs/data', 'kubejs/config',
    'logs'
)
foreach ($d in $dirs) {
    $p = if ($d) { Join-Path $Pack $d } else { $Pack }
    New-Item -ItemType Directory -Force -Path $p | Out-Null
}

# eula: accepted by the pack author so the instance starts without an extra step
$eula = Join-Path $Pack 'eula.txt'
if (-not (Test-Path $eula)) {
    @(
        '#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).'
        "#$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')"
        'eula=true'
    ) | Set-Content -Encoding ASCII $eula
}

Write-Host "pack skeleton at $Pack :"
Get-ChildItem -Recurse -Directory $Pack | ForEach-Object { '  ' + $_.FullName.Replace($Pack, '.') } | Sort-Object
