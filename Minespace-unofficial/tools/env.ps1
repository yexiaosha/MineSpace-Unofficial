<#
.SYNOPSIS
    Loads the local Minespace toolchain (JDK 8, Git, Gradle) into the current PowerShell session.

.DESCRIPTION
    The toolchain lives under <repo>\tools and is deliberately NOT added to the machine's
    PATH or registry, so it cannot disturb other Java projects on this computer.
    Dot-source this file to use it in an interactive shell:

        . .\tools\env.ps1

    After that, java/javac/git/gradle in this shell resolve to the local copies, and
    JAVA_HOME points at the local JDK 8 (required: ForgeGradle for 1.12.2 does not
    support newer Java).

    It is safe to run repeatedly and from any working directory.
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$toolRoot = Join-Path $repoRoot 'tools'

function Add-PathEntry {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return $false }
    $current = $env:PATH -split ';'
    if ($current -notcontains $Dir) {
        $env:PATH = "$Dir;$env:PATH"
        Write-Host "  PATH += $Dir"
    }
    return $true
}

Write-Host 'Minespace toolchain' -ForegroundColor Cyan

# --- JDK 8 -------------------------------------------------------------------
$jdkHome = Join-Path $toolRoot 'jdk8'
if (Test-Path (Join-Path $jdkHome 'bin\java.exe')) {
    $env:JAVA_HOME = $jdkHome
    [void](Add-PathEntry (Join-Path $jdkHome 'bin'))
    $ver = (& (Join-Path $jdkHome 'bin\java.exe') -version 2>&1 | Select-Object -First 1)
    Write-Host "  JAVA_HOME = $jdkHome   ($ver)"
} else {
    Write-Warning "JDK 8 not found at $jdkHome - run tools\bootstrap.ps1 first"
}

# --- Git ---------------------------------------------------------------------
$gitRoot = Join-Path $toolRoot 'git'
if (Test-Path (Join-Path $gitRoot 'cmd\git.exe')) {
    [void](Add-PathEntry (Join-Path $gitRoot 'cmd'))
    $ver = (& (Join-Path $gitRoot 'cmd\git.exe') --version)
    Write-Host "  git       = $gitRoot   ($ver)"
} else {
    Write-Warning "Git not found at $gitRoot - run tools\bootstrap.ps1 first"
}

# --- Gradle ------------------------------------------------------------------
$gradleRoot = Join-Path $toolRoot 'gradle-4.10.3'
if (Test-Path (Join-Path $gradleRoot 'bin\gradle.bat')) {
    [void](Add-PathEntry (Join-Path $gradleRoot 'bin'))
    Write-Host "  gradle    = $gradleRoot   (4.10.3, compatible with the MDK's ForgeGradle 3)"
} else {
    Write-Warning "Gradle 4.10.3 not found at $gradleRoot - the repo's gradlew wrapper can substitute"
}

# --- Encoding ----------------------------------------------------------------
# Java and Gradle emit UTF-8; without this the console mangles non-ASCII output.
try {
    [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
} catch {
    Write-Verbose "could not set console encoding: $($_.Exception.Message)"
}

Write-Host "  repo root = $repoRoot"
Write-Host ''
Write-Host 'Ready. Examples:' -ForegroundColor Green
Write-Host '  .\gradlew.bat build            # build the mod (uses the wrapper)'
Write-Host '  .\gradlew.bat runClient        # launch the dev client with all pack mods'
Write-Host '  .\tools\gradle.ps1 build       # same, but using the local Gradle directly'
