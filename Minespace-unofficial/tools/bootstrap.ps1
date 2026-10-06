#Requires -Version 5.1
<#
  bootstrap.ps1 - install the local Java 8 / Git / Gradle toolchain needed to build
  Minecraft 1.12.2 Forge mods, without touching the system PATH or registry.

  Everything lands under <Root>\tools. Re-running is safe: already-present
  directories are skipped, partial downloads are resumed with .part files.
#>
[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Step { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Warn2{ param([string]$m) Write-Host "    !!  $m" -ForegroundColor Yellow }

$tools  = Join-Path $Root 'tools'
$dl     = Join-Path $tools '_downloads'
New-Item -ItemType Directory -Force -Path $tools, $dl | Out-Null

# Proxy support: reuse whatever the shell/session is configured with.
$env:HTTP_PROXY  = $env:HTTP_PROXY
$env:HTTPS_PROXY = $env:HTTPS_PROXY
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-File {
    param([string]$Url, [string]$OutFile, [int]$TimeoutSec = 60, [int]$Retries = 4)
    if (Test-Path $OutFile) {
        $len = (Get-Item $OutFile).Length
        if ($len -gt 0) { Write-Ok "cached $([IO.Path]::GetFileName($OutFile)) ($len bytes)"; return $OutFile }
    }
    $part = "$OutFile.part"
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Write-Host "    GET $Url"
            $req = [Net.HttpWebRequest]::Create($Url)
            $req.Timeout = $TimeoutSec * 1000
            $req.ReadWriteTimeout = 300000
            $req.AllowAutoRedirect = $true
            $req.UserAgent = 'MinespaceBootstrap/1.0'
            $resp = $req.GetResponse()
            $total = $resp.ContentLength
            $in = $resp.GetResponseStream()
            $out = [IO.File]::Create($part)
            $buf = New-Object byte[] 262144
            $read = 0L
            $lastPct = -1
            while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
                $out.Write($buf, 0, $n)
                $read += $n
                if ($total -gt 0) {
                    $pct = [int](100 * $read / $total)
                    if ($pct -ge $lastPct + 10) { $lastPct = $pct; Write-Host "        $pct%" }
                }
            }
            $out.Dispose(); $in.Dispose(); $resp.Dispose()
            Move-Item -Force $part $OutFile
            Write-Ok "downloaded $([IO.Path]::GetFileName($OutFile)) ($read bytes)"
            return $OutFile
        } catch {
            Write-Warn2 "attempt $i failed: $($_.Exception.Message)"
            if (Test-Path $part) { Remove-Item -Force $part -ErrorAction SilentlyContinue }
            Start-Sleep -Seconds (2 * $i)
        }
    }
    throw "could not download $Url"
}

# ------------------------------------------------------------------ JDK 8
Write-Step 'JDK 8 (Temurin / Adoptium)'
$jdkDir = Join-Path $tools 'jdk8'
if (Test-Path (Join-Path $jdkDir 'bin\javac.exe')) {
    Write-Ok "already installed: $jdkDir"
} else {
    $jdkUrl = $null
    # A mirror is preferred over the GitHub release: the official host is frequently
    # slow or unreachable from mainland China, while this mirror carries the same file.
    $tuna = 'https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/windows/OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip'
    $localZip = Join-Path $dl 'OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip'
    if (Test-Path $localZip) {
        Write-Ok 'using the JDK archive already in _downloads'
        $zip = $localZip
    } else {
        try {
            $api = Invoke-RestMethod -UseBasicParsing -TimeoutSec 60 `
                'https://api.adoptium.net/v3/assets/latest/8/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'
            $jdkUrl = $api[0].binary.package.link
            Write-Host "    api resolved: $($api[0].release_name)"
        } catch {
            Write-Warn2 "Adoptium API unavailable ($($_.Exception.Message)); using the mirror"
        }
        if (-not $jdkUrl) { $jdkUrl = $tuna }
        $zip = $null
        foreach ($candidate in @($tuna, $jdkUrl)) {
            try {
                $name = [IO.Path]::GetFileName(([Uri]$candidate).AbsolutePath)
                $zip = Get-File -Url $candidate -OutFile (Join-Path $dl $name)
                break
            } catch {
                Write-Warn2 "mirror failed: $($_.Exception.Message)"
            }
        }
        if (-not $zip) { throw 'could not download a JDK 8 archive' }
    }
    $stage = Join-Path $tools '_stage_jdk'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    Expand-Archive -Path $zip -DestinationPath $stage -Force
    $inner = Get-ChildItem $stage -Directory | Select-Object -First 1
    if (Test-Path $jdkDir) { Remove-Item -Recurse -Force $jdkDir }
    Move-Item $inner.FullName $jdkDir
    Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
    Write-Ok "installed $jdkDir"
}
# java -version writes to stderr, which PowerShell would otherwise record as an error.
$javaVersion = & cmd /c "`"$(Join-Path $jdkDir 'bin\java.exe')`" -version 2>&1"
$javaVersion | ForEach-Object { Write-Host "    $_" }
# ------------------------------------------------------------------ Git
Write-Step 'Git for Windows (portable)'
$gitDir = Join-Path $tools 'git'
if (Test-Path (Join-Path $gitDir 'cmd\git.exe')) {
    Write-Ok "already installed: $gitDir"
} else {
    # MinGit (a plain zip) is preferred over PortableGit (a 60 MB self-extracting 7z):
    # it is smaller and needs no 7-Zip. Mirrors come first because github.com is
    # frequently unreachable from mainland China.
    $gitUrl = $null
    $gitMirrors = @(
        'https://registry.npmmirror.com/-/binary/git-for-windows/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip',
        'https://mirrors.huaweicloud.com/git-for-windows/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip',
        'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip'
    )
    try {
        $rel = Invoke-RestMethod -UseBasicParsing -TimeoutSec 30 `
            'https://api.github.com/repos/git-for-windows/git/releases/latest'
        $asset = $rel.assets | Where-Object { $_.name -like 'MinGit-*-64-bit.zip' } | Select-Object -First 1
        if ($asset) { $gitUrl = $asset.browser_download_url; Write-Host "    api resolved: $($asset.name)" }
    } catch {
        Write-Warn2 "GitHub API unavailable ($($_.Exception.Message)); using mirrors"
    }
    $gitDl = $null
    foreach ($candidate in ($gitMirrors + @($gitUrl) | Where-Object { $_ })) {
        try {
            $name = [IO.Path]::GetFileName(([Uri]$candidate).AbsolutePath)
            $gitDl = Get-File -Url $candidate -OutFile (Join-Path $dl $name)
            break
        } catch {
            Write-Warn2 "mirror failed: $($_.Exception.Message)"
        }
    }
    if (-not $gitDl) { throw 'could not download a Git distribution' }
    $name = [IO.Path]::GetFileName($gitDl)
    $stage = Join-Path $tools '_stage_git'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    if ($name -like '*.zip') {
        Expand-Archive -Path $gitDl -DestinationPath $stage -Force
        if (Test-Path $gitDir) { Remove-Item -Recurse -Force $gitDir }
        Move-Item $stage $gitDir
    } else {
        # self-extracting 7z archive: -o<dir> -y
        $p = Start-Process -FilePath $gitDl -ArgumentList @("-o`"$stage`"", '-y') -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -ne 0) { throw "portable git self-extract failed: $($p.ExitCode)" }
        if (Test-Path $gitDir) { Remove-Item -Recurse -Force $gitDir }
        Move-Item $stage $gitDir
    }
    Write-Ok "installed $gitDir"
}
& (Join-Path $gitDir 'cmd\git.exe') --version | ForEach-Object { Write-Host "    $_" }

# ------------------------------------------------------------------ Gradle
Write-Step 'Gradle 4.10.3 (the 1.12.2 ForgeGradle 3 wrapper resolves 4.9; 4.10.3 is compatible and pinned here)'
$gradleDir = Join-Path $tools 'gradle-4.10.3'
if (Test-Path (Join-Path $gradleDir 'bin\gradle.bat')) {
    Write-Ok "already installed: $gradleDir"
} else {
    $gMirrors = @(
        'https://mirrors.cloud.tencent.com/gradle/gradle-4.10.3-bin.zip',
        'https://services.gradle.org/distributions/gradle-4.10.3-bin.zip'
    )
    $zip = $null
    foreach ($candidate in $gMirrors) {
        try {
            $zip = Get-File -Url $candidate -OutFile (Join-Path $dl 'gradle-4.10.3-bin.zip')
            break
        } catch {
            Write-Warn2 "mirror failed: $($_.Exception.Message)"
        }
    }
    if (-not $zip) { throw 'could not download the Gradle distribution' }
    $stage = Join-Path $tools '_stage_gradle'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    Expand-Archive -Path $zip -DestinationPath $stage -Force
    $inner = Get-ChildItem $stage -Directory | Select-Object -First 1
    if (Test-Path $gradleDir) { Remove-Item -Recurse -Force $gradleDir }
    Move-Item $inner.FullName $gradleDir
    Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
    Write-Ok "installed $gradleDir"
}

# ------------------------------------------------------------------ report
Write-Step 'Toolchain summary'
$summary = [ordered]@{
    java   = Join-Path $jdkDir 'bin\java.exe'
    javac  = Join-Path $jdkDir 'bin\javac.exe'
    git    = Join-Path $gitDir 'cmd\git.exe'
    gradle = Join-Path $gradleDir 'bin\gradle.bat'
}
foreach ($k in $summary.Keys) {
    $exists = Test-Path $summary[$k]
    Write-Host ("    {0,-7} {1}  [{2}]" -f $k, $summary[$k], $(if ($exists) { 'present' } else { 'MISSING' }))
}
$summary | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $tools 'toolchain.json')
Write-Ok "wrote $(Join-Path $tools 'toolchain.json')"
Write-Host ''
Write-Host 'Toolchain ready. Use tools\env.ps1 to put it on PATH for a shell.' -ForegroundColor Green
