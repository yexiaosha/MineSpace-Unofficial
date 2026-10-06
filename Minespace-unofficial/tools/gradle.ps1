<#
.SYNOPSIS
    Runs Gradle for this repo using the locally installed Gradle 4.10.3 and JDK 8.

.DESCRIPTION
    The repo's gradlew.bat would download its own Gradle distribution (4.9) on first use.
    This script skips that download by using tools\gradle-4.10.3 directly, with JAVA_HOME
    pinned to the local JDK 8.

    Because ForgeGradle plugins are resolved from the network on the first run, and the
    wrapper is the configuration other contributors will use, gradlew.bat still works too.

.EXAMPLE
    .\tools\gradle.ps1 build
    .\tools\gradle.ps1 runClient
    .\tools\gradle.ps1 --stop
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$gradleRoot = Join-Path $PSScriptRoot 'gradle-4.10.3'
$jdkHome = Join-Path $PSScriptRoot 'jdk8'
$gradleBat = Join-Path $gradleRoot 'bin\gradle.bat'

if (-not (Test-Path $gradleBat)) {
    throw "Gradle not found at $gradleBat. Run tools\bootstrap.ps1 first, or use .\gradlew.bat build."
}
if (-not (Test-Path (Join-Path $jdkHome 'bin\java.exe'))) {
    throw "JDK 8 not found at $jdkHome. Run tools\bootstrap.ps1 first."
}

$env:JAVA_HOME = $jdkHome
$env:PATH = "$jdkHome\bin;$env:PATH"

if ($args.Count -eq 0) {
    Write-Host 'No Gradle arguments given. Common tasks:'
    Write-Host '  build          compile and package the mod jar'
    Write-Host '  runClient      launch the development client with all pack mods'
    Write-Host '  runServer      launch a development server'
    Write-Host '  --stop         stop the Gradle daemon'
    exit 0
}

Push-Location $repoRoot
try {
    # Gradle and javac write warnings and diagnostics to stderr. With the usual
    # $ErrorActionPreference = 'Stop' PowerShell turns the first stderr line into a
    # terminating NativeCommandError, which aborts the wrapper *before* Gradle has
    # finished and reports a failure for a build that actually succeeded. Relaxing the
    # preference here and trusting $LASTEXITCODE (Gradle's own exit status) is the
    # correct behaviour.
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & $gradleBat @args
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    exit $code
} finally {
    Pop-Location
}
