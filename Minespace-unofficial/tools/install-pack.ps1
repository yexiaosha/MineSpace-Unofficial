<#
.SYNOPSIS
    Turns the sibling Minespace-unofficial-dev directory into a launchable
    Minecraft 1.12.2 Forge instance.

.DESCRIPTION
    Repo layout assumed:

        <repo>\Minespace-unofficial\        this project (addon source)
        <repo>\Minespace-unofficial-dev\    the instance this script prepares

    Steps that are safe to re-run; each one is skipped when its output already exists:

      1. local Java 8 runtime        -> <pack>\runtime\jdk8
      2. Minecraft 1.12.2 client jar -> <pack>\versions\1.12.2\1.12.2.jar
         and its library set         -> <pack>\libraries
      3. game assets (textures etc.) -> <pack>\assets
      4. Forge 1.12.2-14.23.5.2859   -> <pack>\versions\<forge id>
      5. launch scripts              -> <pack>\Play-Minespace.bat / .ps1

    The mod jars themselves are NOT installed here; the addon is deployed into the
    instance by `gradlew deployToInstance`, and the target mods (GTCEu, Galacticraft,
    CodeChickenLib, KubeJS) come from CurseForge. See MOD-MANIFEST.md.

    Downloads prefer the BMCLAPI mirror (fast from mainland China) and fall back to the
    official Mojang / Forge hosts. Nothing is written outside the pack folder except a
    temporary directory for the Forge installer.

.PARAMETER PackDir
    The instance to prepare. Defaults to the sibling Minespace-unofficial-dev directory.

.PARAMETER SkipAssets
    Skip the ~180 MB asset download. The game will run, but most textures will be missing.
#>

[CmdletBinding()]
param(
    [string]$PackDir,
    [switch]$SkipAssets
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# tools\ -> Minespace-unofficial\ -> <repo>\  ; the instance is the repo's other child.
$RepoRoot = Split-Path -Parent $PSScriptRoot          # <repo>\Minespace-unofficial
if (-not $PackDir) {
    $PackDir = Join-Path (Split-Path -Parent $RepoRoot) 'Minespace-unofficial-dev'
}
$PackDir = [IO.Path]::GetFullPath($PackDir)

$ForgeVersion = '1.12.2-14.23.5.2859'
# Note: the Forge version directory id is discovered from disk further down, because
# the legacy installer has used more than one naming scheme for it.
$McVersion = '1.12.2'

function Write-Section { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok { param([string]$m) Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Skip { param([string]$m) Write-Host "    --  $m" -ForegroundColor DarkGray }
function Write-Warn2 { param([string]$m) Write-Host "    !!  $m" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Rewrites a Mojang URL onto the BMCLAPI mirror. Keeping this in one function
# avoids the PowerShell trap where `$obj.a.b -replace x, y` inside a hash or
# array literal is parsed as two elements instead of one operator call.
# ---------------------------------------------------------------------------
function MirrorUrl {
    param([string]$Url)
    if (-not $Url) { return $Url }
    $u = $Url -replace 'https://piston-meta\.mojang\.com', 'https://bmclapi2.bangbang93.com'
    $u = $u -replace 'https://piston-data\.mojang\.com', 'https://bmclapi2.bangbang93.com'
    $u = $u -replace 'https://libraries\.minecraft\.net', 'https://bmclapi2.bangbang93.com/maven'
    return $u
}

# ---------------------------------------------------------------------------
# Download helper. Tries each URL in turn and verifies the SHA1 when the caller
# knows it, so a truncated mirror response is rejected instead of being cached
# as a valid file.
# ---------------------------------------------------------------------------
function Get-Remote {
    param(
        [string[]]$Urls,
        [string]$OutFile,
        [string]$What = 'file',
        [string]$Sha1
    )
    if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -gt 0) {
        if (-not $Sha1 -or (Test-FileHash -Path $OutFile -Sha1 $Sha1)) {
            Write-Skip "$What already present: $(Split-Path -Leaf $OutFile)"
            return $true
        }
        Write-Warn2 "$What is present but has the wrong checksum; re-downloading"
        Remove-Item -Force $OutFile -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutFile) | Out-Null
    foreach ($u in $Urls) {
        try {
            Write-Host "    GET $u"
            Invoke-WebRequest -UseBasicParsing -UserAgent 'Mozilla/5.0' -TimeoutSec 900 -Uri $u -OutFile $OutFile
            if ((Get-Item $OutFile).Length -le 0) { throw 'zero-length response' }
            if ($Sha1 -and -not (Test-FileHash -Path $OutFile -Sha1 $Sha1)) {
                throw "checksum mismatch (expected $Sha1)"
            }
            return $true
        } catch {
            Write-Host "        failed: $($_.Exception.Message)" -ForegroundColor DarkYellow
            if (Test-Path $OutFile) { Remove-Item -Force $OutFile -ErrorAction SilentlyContinue }
        }
    }
    return $false
}

function Test-FileHash {
    param([string]$Path, [string]$Sha1)
    try {
        $actual = (Get-FileHash -Path $Path -Algorithm SHA1).Hash
        return ($actual -eq $Sha1.ToUpperInvariant())
    } catch {
        return $false
    }
}

Write-Host ''
Write-Host "Minespace instance setup" -ForegroundColor White
Write-Host "  pack : $PackDir"
Write-Host "  forge: $ForgeVersion"
Write-Host ''

foreach ($d in '', 'runtime', 'versions', 'libraries', 'assets', 'logs', 'mods', 'config') {
    New-Item -ItemType Directory -Force -Path (Join-Path $PackDir $d) | Out-Null
}

# ---------------------------------------------------------------------------
# 1. Java 8 runtime
# ---------------------------------------------------------------------------
Write-Section 'Java 8 runtime'
$jdkHome = Join-Path $PackDir 'runtime\jdk8'
$javaExe = Join-Path $jdkHome 'bin\java.exe'
if (Test-Path $javaExe) {
    Write-Skip "already installed: $jdkHome"
} else {
    $repoJdk = Join-Path $RepoRoot 'tools\jdk8\bin\java.exe'
    if (Test-Path $repoJdk) {
        Write-Host "    copying the dev toolchain JDK into the pack"
        Copy-Item -Recurse -Force (Join-Path $RepoRoot 'tools\jdk8') $jdkHome
    } else {
        $zip = Join-Path $env:TEMP 'minespace-jdk8.zip'
        $ok = Get-Remote -What 'JDK 8' -OutFile $zip -Urls @(
            'https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/windows/OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip',
            'https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u504-b01/OpenJDK8U-jdk_x64_windows_hotspot_8u504b01.zip'
        )
        if (-not $ok) { throw 'could not download a JDK 8 for the pack' }
        $stage = Join-Path $env:TEMP 'minespace-jdk8-stage'
        if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
        Expand-Archive -Path $zip -DestinationPath $stage -Force
        $inner = Get-ChildItem $stage -Directory | Select-Object -First 1
        Move-Item $inner.FullName $jdkHome
        Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
        Remove-Item -Force $zip -ErrorAction SilentlyContinue
    }
    Write-Ok "installed $jdkHome"
}
# `java -version` writes to stderr; with $ErrorActionPreference='Stop' PowerShell
# promotes that to a terminating error, so it is probed under 'Continue'.
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $javaExe -version 2>&1 | ForEach-Object { Write-Host "    $_" }
$ErrorActionPreference = $prevEap
$Error.Clear()

# ---------------------------------------------------------------------------
# 2 & 3. Vanilla client, libraries, assets
# ---------------------------------------------------------------------------
Write-Section 'Minecraft 1.12.2 client, libraries and assets'
$versionDir = Join-Path $PackDir "versions\$McVersion"
$clientJar = Join-Path $versionDir "$McVersion.jar"
$clientJson = Join-Path $versionDir "$McVersion.json"

$mojangMeta = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
$bmclMeta = 'https://bmclapi2.bangbang93.com/mc/game/version_manifest.json'

if (-not (Test-Path $clientJson)) {
    $manifest = $null
    foreach ($mu in @($bmclMeta, $mojangMeta)) {
        try { $manifest = Invoke-RestMethod -UseBasicParsing -TimeoutSec 60 -Uri $mu; break } catch { }
    }
    if (-not $manifest) { throw 'could not fetch the Minecraft version manifest' }
    $entry = $manifest.versions | Where-Object { $_.id -eq $McVersion } | Select-Object -First 1
    if (-not $entry) { throw "version $McVersion not found in the manifest" }
    $url = $entry.url
    if ($url -like 'https://piston-meta.mojang.com/*') {
        # mirror the metadata host too, so the JSON and jars come from the same place
        $url = $url -replace 'https://piston-meta\.mojang\.com', 'https://bmclapi2.bangbang93.com'
    }
    [void](Get-Remote -What '1.12.2 version json' -OutFile $clientJson -Urls @($url, $entry.url))
}
$verJson = Get-Content -Raw $clientJson | ConvertFrom-Json
Write-Ok "version json: $clientJson"

[void](Get-Remote -What '1.12.2 client jar' -OutFile $clientJar -Sha1 $verJson.downloads.client.sha1 -Urls @(
    (MirrorUrl $verJson.downloads.client.url),
    $verJson.downloads.client.url
))

# libraries: keep the relative path from the "path" field so the classpath can be built.
# Every download is checksum-verified: mirrors do occasionally answer with an error page
# or a truncated body, and a wrong jar that passes a size check fails much later with a
# confusing NoClassDefFoundError.
$libRoot = Join-Path $PackDir 'libraries'
$missing = 0
foreach ($lib in $verJson.libraries) {
    if ($lib.downloads.artifact.url) {
        $artifact = $lib.downloads.artifact
        $target = Join-Path $libRoot ($artifact.path -replace '/', '\')
        if (-not (Get-Remote -What $lib.name -OutFile $target -Sha1 $artifact.sha1 -Urls @(
                    (MirrorUrl $artifact.url),
                    $artifact.url))) { $missing++ }
    }
}
Write-Ok "libraries: $(($verJson.libraries | Where-Object { $_.downloads.artifact }).Count) declared, $missing failed"

if (-not $SkipAssets) {
    $assetIndex = $verJson.assetIndex
    $assetRoot = Join-Path $PackDir 'assets'
    $indexFile = Join-Path $assetRoot "indexes\$($assetIndex.id).json"
    [void](Get-Remote -What 'asset index' -OutFile $indexFile -Urls @(
        (MirrorUrl $assetIndex.url),
        $assetIndex.url
    ))
    if (Test-Path $indexFile) {
        $index = Get-Content -Raw $indexFile | ConvertFrom-Json
        $objects = $index.objects.PSObject.Properties
        Write-Host "    $($objects.Count) asset objects to verify"
        # Objects are content-addressed; anything already present is complete by definition.
        $toGet = @()
        foreach ($o in $objects) {
            $h = $o.Value.hash
            $p = Join-Path $assetRoot "objects\$($h.Substring(0,2))\$h"
            if (-not (Test-Path $p)) { $toGet += [pscustomobject]@{ hash = $h; path = $p } }
        }
        Write-Host "    $($toGet.Count) assets missing"
        $i = 0
        foreach ($a in $toGet) {
            $i++
            if ($i % 200 -eq 0) { Write-Host "        $i / $($toGet.Count)" }
            $rel = "$($a.hash.Substring(0,2))/$($a.hash)"
            [void](Get-Remote -What 'asset' -OutFile $a.path -Urls @(
                "https://bmclapi2.bangbang93.com/assets/$rel",
                "https://resources.download.minecraft.net/$rel"
            ))
        }
        Write-Ok 'assets complete'
    }
} else {
    Write-Skip 'assets skipped (-SkipAssets)'
}

# ---------------------------------------------------------------------------
# 4. Forge
# ---------------------------------------------------------------------------
Write-Section "Forge $ForgeVersion"

# Find a Forge version directory by looking at what is on disk rather than by
# reconstructing its name: the legacy installer has used more than one naming
# scheme ("1.12.2-forge-<ver>", "1.12.2-forge<ver>"), and the real id is what the
# launcher script and launcher_profiles.json must reference.
function Find-ForgeVersion {
    param([string]$Root)
    $dir = Join-Path $Root 'versions'
    if (-not (Test-Path $dir)) { return $null }
    return Get-ChildItem $dir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*forge*' -and (Test-Path (Join-Path $_.FullName "$($_.Name).json")) } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

$forgeVersionDir = Find-ForgeVersion $PackDir
if ($forgeVersionDir) {
    Write-Skip "already installed: $($forgeVersionDir.FullName)"
} else {
    $installer = Join-Path $RepoRoot "tools\_downloads\forge-$ForgeVersion-installer.jar"
    if (-not (Test-Path $installer)) {
        [void](Get-Remote -What 'Forge installer' -OutFile $installer -Urls @(
            "https://maven.minecraftforge.net/net/minecraftforge/forge/$ForgeVersion/forge-$ForgeVersion-installer.jar"
        ))
    }
    if (-not (Test-Path $installer)) { throw 'could not obtain the Forge installer' }

    Write-Host "    running the Forge installer (this downloads ~40 MB)"
    # The legacy installer refuses to run unless a launcher profile file exists in
    # the target directory. A minimal one is seeded here with the id the installer
    # is expected to write; it is rewritten with the real id further down.
    $profilesFile = Join-Path $PackDir 'launcher_profiles.json'
    if (-not (Test-Path $profilesFile)) {
        [ordered]@{
            profiles               = [ordered]@{}
            selectedProfile        = ''
            clientToken            = '00000000000000000000000000000000'
            authenticationDatabase = [ordered]@{}
            selectedUser           = ''
            launcherVersion        = [ordered]@{ name = '2.1.1353'; format = 21 }
            settings               = [ordered]@{}
            version                = 3
        } | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $profilesFile
        Write-Ok 'seeded a minimal launcher_profiles.json for the installer'
    }
    # 1.12.2 ships the legacy Swing installer. --installClient <dir> is the
    # non-interactive form; running it with no arguments opens the GUI instead.
    # It writes <dir>\versions\<forge id> and <dir>\libraries.
    $p = Start-Process -FilePath $javaExe -Wait -PassThru -NoNewWindow `
        -ArgumentList @('-jar', $installer, '--installClient', $PackDir)
    if ($p.ExitCode -ne 0) { throw "Forge installer exited with $($p.ExitCode)" }
    $forgeVersionDir = Find-ForgeVersion $PackDir
    if (-not $forgeVersionDir) { throw "Forge installer produced no version directory under $PackDir\versions" }
    Write-Ok "installed $($forgeVersionDir.FullName)"
}

$ForgeId = $forgeVersionDir.Name
$forgeDir = $forgeVersionDir.FullName
$forgeJson = Join-Path $forgeDir "$ForgeId.json"
$forgeMeta = Get-Content -Raw $forgeJson | ConvertFrom-Json
Write-Host "    version id : $ForgeId"
Write-Host "    main class : $($forgeMeta.mainClass)"
Write-Host "    inherits   : $($forgeMeta.inheritsFrom)"

# Write the real launcher profile now that the version id is known. The installer
# adds its own "forge" entry; this one is the pack's, preconfigured for the instance.
$profilesFile = Join-Path $PackDir 'launcher_profiles.json'
$existing = $null
if (Test-Path $profilesFile) {
    try { $existing = Get-Content -Raw $profilesFile | ConvertFrom-Json } catch { $existing = $null }
}
$profileMap = [ordered]@{}
if ($existing -and $existing.profiles) {
    foreach ($prop in $existing.profiles.PSObject.Properties) {
        $profileMap[$prop.Name] = $prop.Value
    }
}
$profileMap['Minespace Unofficial'] = [ordered]@{
    name          = 'Minespace Unofficial'
    type          = 'custom'
    lastVersionId = $ForgeId
    gameDir       = '.'
    javaArgs      = '-Xmx6144M'
}
[ordered]@{
    profiles               = $profileMap
    selectedProfile        = 'Minespace Unofficial'
    clientToken            = '00000000000000000000000000000000'
    authenticationDatabase = [ordered]@{}
    selectedUser           = ''
    launcherVersion        = [ordered]@{ name = '2.1.1353'; format = 21 }
    settings               = [ordered]@{}
    version                = 3
} | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $profilesFile
Write-Ok "launcher_profiles.json -> $ForgeId"

# ---------------------------------------------------------------------------
# 4b. Native libraries (LWJGL, jinput, ...).
# The legacy installer resolves the version json but does not unpack the
# natives classifiers, so the launcher script needs them extracted here.
# ---------------------------------------------------------------------------
Write-Section 'Native libraries'
$natives = Join-Path $forgeDir 'natives'
New-Item -ItemType Directory -Force -Path $natives | Out-Null
$baseJson = Join-Path $PackDir "versions\$McVersion\$McVersion.json"
$nativeCount = 0
if (Test-Path $baseJson) {
    $baseForNatives = Get-Content -Raw $baseJson | ConvertFrom-Json
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    foreach ($lib in $baseForNatives.libraries) {
        if (-not $lib.natives -or -not $lib.downloads.classifiers) { continue }
        $classifier = $lib.natives.windows
        if (-not $classifier) { continue }
        $artifact = $lib.downloads.classifiers.$classifier
        if (-not $artifact.path) { continue }
        $jarPath = Join-Path $PackDir ("libraries\" + ($artifact.path -replace '/', '\'))
        if (-not (Test-Path $jarPath) -or -not (Test-FileHash -Path $jarPath -Sha1 $artifact.sha1)) {
            [void](Get-Remote -What "$($lib.name) natives" -OutFile $jarPath -Sha1 $artifact.sha1 -Urls @(
                        (MirrorUrl $artifact.url), $artifact.url))
        }
        if (Test-Path $jarPath) {
            try {
                # Extracted entry by entry: the two-argument ExtractToDirectory overload
                # does not exist on .NET Framework 4.x, and this way duplicate names
                # (lwjgl.dll appears in more than one of these jars) are overwritten
                # by whichever library comes later, which is the intended order.
                $zip = [IO.Compression.ZipFile]::OpenRead($jarPath)
                try {
                    foreach ($entry in $zip.Entries) {
                        if ([string]::IsNullOrEmpty($entry.Name)) { continue }
                        $target = Join-Path $natives $entry.FullName
                        $targetDir = Split-Path -Parent $target
                        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
                        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
                    }
                } finally { $zip.Dispose() }
                $nativeCount++
            } catch {
                Write-Warn2 "could not extract natives from $($lib.name): $($_.Exception.Message)"
            }
        }
    }
}
Write-Ok "$nativeCount native libraries extracted to $natives"

# ---------------------------------------------------------------------------
# 5. Launch scripts
# ---------------------------------------------------------------------------
Write-Section 'Launch scripts'
$coremods = Join-Path $PackDir 'mods\1.12.2'
New-Item -ItemType Directory -Force -Path $coremods | Out-Null

$playPs1 = Join-Path $PackDir 'Play-Minespace.ps1'
$launcher = @'
<#
    Launches the Minespace instance directly, without a third-party launcher.
    Assembles the classpath from versions/ + libraries/ the same way the official
    launcher does, then starts Forge with the pack folder as the game directory.

    Generated by tools\install-pack.ps1 - edit that script, not this file.
#>
[CmdletBinding()]
param(
    [int]$MinMemoryMB = 2048,
    [int]$MaxMemoryMB = 6144,
    [string]$Username = 'Minespace',
    [switch]$Server
)
$ErrorActionPreference = 'Stop'
$Pack = $PSScriptRoot
$Java = Join-Path $Pack 'runtime\jdk8\bin\java.exe'
$ForgeId = 'FORGE_ID'
$ForgeJson = Join-Path $Pack "versions\$ForgeId\$ForgeId.json"
$Natives = Join-Path $Pack "versions\$ForgeId\natives"

if (-not (Test-Path $Java)) { throw "Java 8 missing at $Java - run tools\install-pack.ps1 first" }
if (-not (Test-Path $ForgeJson)) { throw "Forge not installed ($ForgeJson) - run tools\install-pack.ps1 first" }

$forge = Get-Content -Raw $ForgeJson | ConvertFrom-Json
$base = Get-Content -Raw (Join-Path $Pack "versions\$($forge.inheritsFrom)\$($forge.inheritsFrom).json") | ConvertFrom-Json

# Libraries: the base version's list, then Forge's on top. Later entries win, so
# Forge's own library versions take precedence over vanilla ones.
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
# Forge itself is not a versions/<id>/<id>.jar: the installer resolves it as a normal
# maven library, so it is already covered by the loop above. Only add an explicit entry
# if some future installer layout does put a jar next to the version json.
$versionJar = Join-Path $Pack "versions\$ForgeId\$ForgeId.jar"
if (Test-Path $versionJar) { [void]$classpath.Add($versionJar) }

$mainClass = if ($forge.mainClass) { $forge.mainClass } else { $base.mainClass }

$argsList = New-Object System.Collections.Generic.List[string]
[void]$argsList.Add("-Xmx${MaxMemoryMB}M")
[void]$argsList.Add("-Xms${MinMemoryMB}M")
[void]$argsList.Add("-Djava.library.path=$Natives")
[void]$argsList.Add('-Dfml.ignoreInvalidMinecraftCertificates=true')
[void]$argsList.Add('-Dfml.ignorePatchDiscrepancies=true')
if ($Server) {
    # A dedicated server needs the vanilla server jar on the classpath: the client jar has
    # no net.minecraft.server.dedicated.DedicatedServer, and Forge's class patcher aborts
    # with "your vanilla jar may be corrupt" when it cannot read that class. It has to
    # REPLACE the client jar rather than be appended, otherwise the client jar's copies of
    # the shared classes shadow the server ones and the launch dies on
    # NoSuchMethodException: net.minecraft.server.MinecraftServer.main.
    $serverJar = Join-Path $Pack "versions\$($forge.inheritsFrom)\minecraft_server.$($forge.inheritsFrom).jar"
    if (Test-Path $serverJar) {
        [void]$classpath.Remove($clientJar)
        [void]$classpath.Add($serverJar)
    }
    [void]$argsList.Add('-cp'); [void]$argsList.Add(($classpath -join ';'))
    [void]$argsList.Add($mainClass)
    [void]$argsList.Add('nogui')
    # Same reason as the client branch below: Forge 1.12.2 is applied through
    # launchwrapper via FML's tweaker. The server needs FMLServerTweaker; without it
    # the launch falls back to VanillaTweaker and dies on the missing client class.
    [void]$argsList.Add('--tweakClass'); [void]$argsList.Add('net.minecraftforge.fml.common.launcher.FMLServerTweaker')
} else {
    [void]$argsList.Add('-cp'); [void]$argsList.Add(($classpath -join ';'))
    [void]$argsList.Add($mainClass)
    [void]$argsList.Add('--username'); [void]$argsList.Add($Username)
    [void]$argsList.Add('--version'); [void]$argsList.Add($ForgeId)
    [void]$argsList.Add('--gameDir'); [void]$argsList.Add($Pack)
    [void]$argsList.Add('--assetsDir'); [void]$argsList.Add((Join-Path $Pack 'assets'))
    [void]$argsList.Add('--assetIndex'); [void]$argsList.Add($base.assetIndex.id)
    [void]$argsList.Add('--uuid'); [void]$argsList.Add('00000000000000000000000000000000')
    [void]$argsList.Add('--accessToken'); [void]$argsList.Add('0')
    [void]$argsList.Add('--userType'); [void]$argsList.Add('legacy')
    # Forge 1.12.2 is applied by launchwrapper through FML's tweaker. Without this the
    # launcher falls back to VanillaTweaker and crashes on the missing Minecraft class.
    [void]$argsList.Add('--tweakClass'); [void]$argsList.Add('net.minecraftforge.fml.common.launcher.FMLTweaker')
}

Write-Host "Launching $ForgeId (${MaxMemoryMB}M max heap)"
Push-Location $Pack
try { & $Java @argsList } finally { Pop-Location }
'@
$launcher = $launcher.Replace('FORGE_ID', $ForgeId)
Set-Content -Encoding UTF8 -Path $playPs1 -Value $launcher

$playBat = Join-Path $PackDir 'Play-Minespace.bat'
@"
@echo off
rem Generated by tools\install-pack.ps1 - launches the Minespace instance.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Play-Minespace.ps1" %*
if errorlevel 1 pause
"@ | Set-Content -Encoding ASCII $playBat

Write-Ok "wrote $(Split-Path -Leaf $playPs1) and $(Split-Path -Leaf $playBat)"
Write-Host ''
Write-Host "Instance ready: $PackDir" -ForegroundColor Green
Write-Host "Start it with: $playBat"
