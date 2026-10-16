# Fetches the astrophysical data the planet catalog is built from, and caches it next to this
# script so the catalog can be rebuilt without touching the network.
#
# Why a fetch step at all: the planet table (planet-catalog.psd1) is a *design* table - names,
# layers, stages, vein regions, dimension ids. Every number that describes the body itself is
# somebody else's measurement, and the plan's rule is that the names and the data come from NASA.
# So the numbers are not typed in here; they are read from the source of record:
#
#   * solar-system planets, the Moon, Pluto - NASA NSSDC "Planetary Fact Sheet" (metric) and the
#     per-planet fact sheets, which also carry atmosphere composition;
#   * moons - the NSSDC satellite fact sheets (jovian / saturnian / uranian / neptunian) plus the
#     satellite tables inside the Mars and Pluto fact sheets;
#   * exoplanets - the NASA Exoplanet Archive `pscomppars` table over its TAP service;
#   * everything else (black holes, pulsars, nebulae, galaxies, the cosmic-scale objects) - a
#     curated value set in the catalog itself plus the raw sentence from a NASA page that states
#     it, kept here as `Evidence`.
#
# Output: nasa-planet-data.json - one entry per body key in the catalog, with `Status`, the parsed
# `Values` and the `Source` URL. A body whose data could not be found lands as `Status='missing'`
# rather than being dropped, because the catalog renderer refuses to print a body without a source.
#
# JPL's SSD host (ssd.jpl.nasa.gov) does not complete a TLS handshake from this machine - measured
# 2026-10-15 - which is why the moons come from the NSSDC sheets rather than from JPL's satellite
# parameters page. NED (NASA/IPAC) answers, but only with position and redshift, so it is not used
# as a distance source here.

param(
    [switch]$Refresh,
    [string]$CachePath = (Join-Path $PSScriptRoot 'nasa-planet-data.json'),
    [string]$DownloadDir = (Join-Path $PSScriptRoot '_downloads')
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$catalog = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'planet-catalog.psd1')

$script:Cache = @{}          # url -> html text, so a body that shares a page with another reads it once

function Get-Page {
    param([string]$Url, [int]$TimeoutSec = 60, [int]$Attempts = 3)
    if ($script:Cache.ContainsKey($Url)) { return $script:Cache[$Url] }
    $last = $null
    foreach ($attempt in 1..$Attempts) {
        try {
            $r = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing -UserAgent 'Minespace-catalog/1.0 (local build tool)'
            $text = if ($r.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($r.Content) } else { [string]$r.Content }
            $script:Cache[$Url] = $text
            return $text
        } catch { $last = $_.Exception.Message; Start-Sleep -Seconds 3 }
    }
    throw "GET failed after $Attempts attempts: $Url :: $last"
}

function Get-File {
    param([string]$Url, [string]$Target)
    if ((Test-Path $Target) -and -not $Refresh) { return $Target }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null
    Invoke-WebRequest -Uri $Url -OutFile $Target -TimeoutSec 300 -UseBasicParsing
    return $Target
}

# HTML -> one string per table row, cells joined with ' | '. Both NSSDC page shapes (the wide
# comparative sheet and the per-body sheets) are tables, and the atmosphere block is a <pre>, which
# is captured separately by Get-AtmosphereText.
function ConvertTo-Rows {
    param([string]$Html)
    $t = $Html -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', ''
    $t = $t -replace '<br\s*/?>', ' ' -replace '</tr>', "`n" -replace '</t[dh]>', ' | '
    $t = $t -replace '<[^>]+>', '' -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&#8722;', '-'
    $t = $t -replace '&times;', 'x' -replace '&deg;', 'deg'
    foreach ($line in ($t -split "`n")) {
        $cells = @(($line -split '\|') | ForEach-Object { $_.Trim() })
        # Trim the empty trailing cells by *index*, not by re-slicing: `$cells[0..($count-2)]` with a
        # single-element array becomes `$cells[0..-1]`, which PowerShell reads as "index 0 and index
        # -1" - the array never shrinks and the loop never ends. It cost a fifteen-minute hang.
        $last = $cells.Count - 1
        while ($last -ge 0 -and $cells[$last] -eq '') { $last-- }
        if ($last -lt 0) { continue }
        $cells = @($cells[0..$last])
        if ($cells.Count -gt 0 -and ($cells -join '') -match '\S') { , $cells }
    }
}

function Get-FirstNumber {
    param([string]$Text)
    if (-not $Text) { return $null }
    $m = [regex]::Match($Text, '[-+]?\d[\d,]*\.?\d*')
    if (-not $m.Success) { return $null }
    return ($m.Value -replace ',', '')
}

# ---- the two NSSDC page shapes ---------------------------------------------------------------

# The comparative sheet is a vertical table too: the run of planet names, then for each metric its
# ten values in that order. A planet's value is the one in its own column.
function Parse-MainFactSheet {
    param([string]$Html, [string]$Planet)
    $columns = @('MERCURY', 'VENUS', 'EARTH', 'MOON', 'MARS', 'JUPITER', 'SATURN', 'URANUS', 'NEPTUNE', 'PLUTO')
    $col = [array]::IndexOf($columns, $Planet.ToUpper())
    if ($col -lt 0) { return $null }
    $flat = @((ConvertTo-Rows $Html) | ForEach-Object { ($_ -join ' ').Trim() } | Where-Object { $_ -ne '' })
    $values = [ordered]@{}
    for ($i = 0; $i -lt $flat.Count; $i++) {
        $label = $flat[$i]
        if ($label -match '^[-+]?[\d,]' -or $columns -contains $label.ToUpper()) { continue }
        $row = @()
        for ($j = $i + 1; $j -lt $flat.Count -and $row.Count -lt $columns.Count; $j++) {
            if ($flat[$j] -match '^[-+]?[\d,]') { $row += $flat[$j]; continue }
            break
        }
        if ($row.Count -eq $columns.Count -and -not $values.Contains($label)) { $values[$label] = $row[$col] }
    }
    if ($values.Count -eq 0) { return $null }
    return $values
}

# A per-body sheet comes in two shapes and NSSDC uses both. The horizontal one is a row per metric
# with the body, the Earth value and the ratio as columns (Mars, Venus, Jupiter...). The vertical
# one is a *cell per row* - label, value, Earth value, ratio, in source order - which is how the Sun
# and the Moon sheets are laid out. Reading a vertical sheet with the horizontal reader silently
# yields a table of one-column rows, which is why both are tried and the richer one wins.
function Parse-BodyFactSheet {
    param([string]$Html)
    $rows = ConvertTo-Rows $Html

    $horizontal = [ordered]@{}
    foreach ($row in $rows) {
        if ($row.Count -lt 2) { continue }
        $label = $row[0]
        if ($label -match '^\s*$' -or $horizontal.Contains($label)) { continue }
        $horizontal[$label] = $row[1]
    }

    $flat = @($rows | ForEach-Object { if ($_.Count -eq 1) { $_[0] } else { ($_ -join ' ') } })
    $vertical = [ordered]@{}
    for ($i = 0; $i -lt $flat.Count; $i++) {
        $cell = $flat[$i]
        # A label is anything that does not start like a number; its value is the next such cell.
        if (-not $cell -or $cell -match '^[-+]?[\d,]') { continue }
        # Column headings ("Sun", "Earth", "Ratio (Sun/Earth)") read as labels in this layout and
        # would swallow the first metric's value. Every real metric on these sheets carries its unit
        # in parentheses, so a label without one is dropped.
        if ($cell -notmatch '\(') { continue }
        if ($vertical.Contains($cell)) { continue }
        for ($j = $i + 1; $j -lt [Math]::Min($i + 4, $flat.Count); $j++) {
            if ($flat[$j] -match '^[-+]?[\d,]') { $vertical[$cell] = $flat[$j]; break }
        }
    }

    # The third shape puts the label and its value in the *same* cell, separated by a run of spaces
    # or a tab (Earth's sheet, and Charon's table inside Pluto's). A real label carries its unit in
    # parentheses, which is what keeps page prose out.
    $inline = [ordered]@{}
    foreach ($row in $rows) {
        $cell = ($row -join ' ').Trim()
        $m = [regex]::Match($cell, '^(.*?)\s{2,}([-+]?[\d,\.]+)\s*$')
        if ($m.Success -and $m.Groups[1].Value -match '\(') {
            $key = $m.Groups[1].Value.Trim()
            if (-not $inline.Contains($key)) { $inline[$key] = $m.Groups[2].Value }
        }
    }

    $best = $horizontal
    if ($vertical.Count -gt $best.Count) { $best = $vertical }
    if ($inline.Count -gt $best.Count) { $best = $inline }
    return $best
}

# The atmosphere block of a per-body sheet, which is a <pre> run rather than a table.
function Get-AtmosphereText {
    param([string]$Html)
    $t = $Html -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', ''
    $i = $t.IndexOf('Atmospheric composition')
    if ($i -lt 0) { return $null }
    $chunk = $t.Substring($i, [Math]::Min(1400, $t.Length - $i))
    if ($chunk -match '(?s)<pre>(.*?)</pre>') { $chunk = $Matches[1] }
    $chunk = $chunk -replace '<[^>]+>', ' ' -replace '&nbsp;', ' ' -replace '\s+', ' '
    foreach ($stop in @('Notes on the factsheets', 'Planetary Fact Table', 'For information on', 'Index of Planetary Fact Sheets', 'Note that the', 'The Moon For information')) {
        $cut = $chunk.IndexOf($stop)
        if ($cut -gt 0) { $chunk = $chunk.Substring(0, $cut) }
    }
    return $chunk.Trim()
}

# A satellite fact sheet is a vertical table: the four metric labels of the "Bulk parameters" block,
# then, for every moon, its name followed by its values in that order. Neptune's sheet drops the
# density column, so the albedo is pinned to the last value rather than to a fixed index.
function Parse-SatelliteSheet {
    param([string]$Html, [string]$Moon)
    $rows = ConvertTo-Rows $Html
    $flat = @($rows | ForEach-Object { ($_ -join ' ').Trim() } | Where-Object { $_ -ne '' })
    # The numeral in a moon's row is Roman but family-prefixed - Io (I), Miranda (UV), Triton (NI) -
    # so the pattern allows letters before the numerals.
    $moonPattern = '^' + [regex]::Escape($Moon) + '\s*\([A-Z]*[IVX]+\)$'
    $index = -1
    for ($i = 0; $i -lt $flat.Count; $i++) {
        if ($flat[$i] -match $moonPattern) { $index = $i; break }
    }
    if ($index -lt 0) { return $null }

    # Walk the moon's own values, and stop at the next moon name or section heading.
    $values = @()
    for ($i = $index + 1; $i -lt $flat.Count; $i++) {
        if ($flat[$i] -match '^[-+]?[\d,]') { $values += $flat[$i]; continue }
        break
    }
    if ($values.Count -eq 0) { return $null }

    $out = [ordered]@{}
    $out['Mass(1020 kg)'] = $values[0]
    if ($values.Count -ge 2) { $out['Radius(km)'] = $values[1] }
    if ($values.Count -ge 4) {
        $out['Mean density(kg/m3)'] = $values[2]
        $out['Visual geometric albedo'] = $values[3]
    } elseif ($values.Count -eq 3) {
        $out['Visual geometric albedo'] = $values[2]
    }
    return $out
}

# The satellite table inside a body sheet. Two shapes again: the Mars sheet lists the moons as a run
# of bare-name rows and then a labelled row per metric whose nth value belongs to the nth moon,
# while the Pluto sheet writes "label   value" into a single cell under Charon's own heading.
#
# The shared reader for a vertical sheet: a label, then the numeric cells that follow it. Returns
# every label in order and the labels that carried values.
function Read-VerticalGroups {
    param([string]$Html)
    $flat = @((ConvertTo-Rows $Html) | ForEach-Object { ($_ -join ' ').Trim() } | Where-Object { $_ -ne '' })
    $labels = @()
    $groups = @()
    $current = $null
    foreach ($cell in $flat) {
        if ($cell -match '^[-+]?[\d,]') {
            if ($current) { $current.Values += $cell }
            continue
        }
        if ($current) { $groups += $current }
        $labels += $cell
        $current = @{ Label = $cell; Values = @() }
    }
    if ($current) { $groups += $current }
    return @{ Labels = $labels; Groups = @($groups) }
}

# The Mars sheet's shape: a heading, the run of moon names, then one metric per group with one value
# per moon in the same order.
function Parse-NameColumns {
    param([string]$Html, [string]$Moon, [string]$TableHeading)
    $table = Read-VerticalGroups $Html
    $pivot = [array]::IndexOf($table.Labels, $TableHeading)
    if ($pivot -lt 0) { return $null }
    $names = @()
    for ($i = $pivot + 1; $i -lt $table.Labels.Count; $i++) {
        $label = $table.Labels[$i]
        if ($label -match '^[A-Z][A-Za-z]+$') { $names += $label } else { break }
    }
    $ordinal = [array]::IndexOf($names, $Moon)
    if ($ordinal -lt 0) { return $null }

    $values = [ordered]@{}
    $groupsAfter = @($table.Groups | Where-Object { $table.Labels.IndexOf($_.Label) -gt $pivot })
    $checked = 0
    foreach ($group in $groupsAfter) {
        if ($checked -ge 20) { break }
        if ($group.Label -match '^[A-Z][A-Za-z]+$') { continue }
        # Every metric of this table carries one value per moon; a group that does not is the page's
        # footer text arriving after the table, and that is where the walk stops.
        if ($group.Values.Count -ne $names.Count) { if ($values.Count -gt 0) { break } else { continue } }
        if (-not $values.Contains($group.Label)) { $values[$group.Label] = $group.Values[$ordinal]; $checked++ }
    }
    if ($values.Count -eq 0) { return $null }
    return $values
}

function Parse-MoonColumns {
    param([string]$Html, [string]$Moon)
    $rows = ConvertTo-Rows $Html

    # the run of bare moon names, in table order
    $names = @()
    $insideRun = $false
    foreach ($row in $rows) {
        if ($row.Count -eq 1 -and $row[0] -match '^[A-Z][A-Za-z]+$') { $names += $row[0]; $insideRun = $true; continue }
        if ($insideRun) { break }
    }
    $ordinal = [array]::IndexOf($names, $Moon)
    if ($ordinal -ge 0) {
        $col = $ordinal + 1
        $values = [ordered]@{}
        foreach ($row in $rows) {
            if ($row.Count -le $col) { continue }
            $label = $row[0]
            if ($label -eq '' -or $label -eq $Moon) { continue }
            if (-not $values.Contains($label)) { $values[$label] = $row[$col] }
        }
        if ($values.Count -gt 0) { return $values }
    }

    # the inline shape: the moon's heading, then one "label   value" cell per metric
    $inline = [ordered]@{}
    $seenHeading = $false
    foreach ($row in $rows) {
        $cell = ($row -join ' ').Trim()
        if (-not $seenHeading) {
            if ($cell -match ('^' + [regex]::Escape($Moon) + '\b')) { $seenHeading = $true }
            continue
        }
        $m = [regex]::Match($cell, '^(.*?)\s{2,}([-+]?[\d,\.]+)\s*$')
        if ($m.Success) {
            $inline[$m.Groups[1].Value.Trim()] = $m.Groups[2].Value
        } elseif ($cell -match '^\s*$') { continue } else { if ($inline.Count -gt 0) { break } }
    }
    if ($inline.Count -gt 0) { return $inline }
    return $null
}

# ---- the exoplanet archive --------------------------------------------------------------------

function Get-ExoplanetTable {
    $csv = Get-File -Url 'https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=select+pl_name,hostname,discoverymethod,disc_year,disc_facility,pl_orbper,pl_rade,pl_bmasse,pl_eqt,pl_insol,sy_dist,sy_vmag,st_spectype,st_teff,st_rad,st_mass,pl_orbsmax,pl_orbeccen,pl_dens+from+pscomppars&format=csv' -Target (Join-Path $DownloadDir 'exoplanet-pscomppars.csv')
    $rows = Import-Csv $csv
    $table = @{}
    foreach ($r in $rows) { $table[$r.pl_name] = $r }
    return $table
}

function Select-ExoValues {
    param($Row)
    return [ordered]@{
        'Host star'        = $Row.hostname
        'Spectral type'    = $Row.st_spectype
        'Distance (pc)'    = $Row.sy_dist
        'Orbital period (d)' = $Row.pl_orbper
        'Radius (Earth)'   = $Row.pl_rade
        'Mass (Earth)'     = $Row.pl_bmasse
        'Eq. temperature (K)' = $Row.pl_eqt
        'Insolation (Earth)' = $Row.pl_insol
        'Semimajor axis (AU)' = $Row.pl_orbsmax
        'Eccentricity'     = $Row.pl_orbeccen
        'Discovered'       = $Row.disc_year
        'Method'           = $Row.discoverymethod
        'Facility'         = $Row.disc_facility
    }
}

# ---- the curated objects ----------------------------------------------------------------------

# A curated body carries its own numbers in the catalog; what is fetched here is the *evidence* -
# the sentences on a NASA page that state them - so a number in the rendered catalog can be traced
# to a page and a line rather than to whoever typed the table.
function Get-Evidence {
    param([string]$Url)
    # A source page is nice to have, not load-bearing: one attempt, a short timeout, and the caller
    # keeps the body either way.
    $html = Get-Page -Url $Url -TimeoutSec 25 -Attempts 1
    $t = $html -replace '(?s)<script.*?</script>', '' -replace '(?s)<style.*?</style>', '' -replace '<[^>]+>', ' '
    $t = $t -replace '&nbsp;', ' ' -replace '&#8217;', "'" -replace '\s+', ' '
    $hits = @()
    foreach ($m in [regex]::Matches($t, '[^.]{0,110}(?:light-years|light years|billion light-years|million light-years|parsecs|kiloparsecs|megaparsecs|solar masses|billion years)[^.]{0,60}\.')) {
        $hits += ($m.Value.Trim())
        if ($hits.Count -ge 4) { break }
    }
    return $hits
}

# ---- main -------------------------------------------------------------------------------------

$previous = if (Test-Path $CachePath) { Get-Content $CachePath -Raw | ConvertFrom-Json } else { $null }
$exo = $null
$result = [ordered]@{
    Fetched = (Get-Date -Format 'yyyy-MM-dd')
    Sources = [ordered]@{
        'planets'  = 'https://nssdc.gsfc.nasa.gov/planetary/factsheet/ (NASA NSSDC Planetary Fact Sheet, metric, updated 2025-03-18)'
        'moons'    = 'https://nssdc.gsfc.nasa.gov/planetary/factsheet/ satellite fact sheets (jovian, saturnian, uranian, neptunian) plus the satellite tables of the Mars and Pluto sheets'
        'exoplanets' = 'NASA Exoplanet Archive TAP, table pscomppars (https://exoplanetarchive.ipac.caltech.edu/)'
        'curated'  = 'the per-body Source url recorded on each entry'
    }
    Bodies = [ordered]@{}
}

$missing = @()
$index = 0
$total = $catalog.Bodies.Keys.Count
foreach ($key in $catalog.Bodies.Keys) {
    $index++
    Write-Host ("  [{0,3}/{1}] {2}" -f $index, $total, $key) -NoNewline
    $body = $catalog.Bodies[$key]
    # Anything already resolved is reused: the whole point of the cache is that a catalog rebuild is
    # a local operation. -Refresh re-reads every source.
    if ($previous -and -not $Refresh -and $previous.Bodies.$key -and $previous.Bodies.$key.Status -ne 'missing') {
        $result.Bodies[$key] = $previous.Bodies.$key
        Write-Host ' -> cached'
        continue
    }
    $entry = [ordered]@{ Status = 'missing'; Lookup = $body.Lookup; Source = ''; Values = [ordered]@{}; Evidence = @() }
    $parts = @($body.Lookup -split ':')
    try {
        switch ($parts[0]) {
            'main' {
                $entry.Source = 'https://nssdc.gsfc.nasa.gov/planetary/factsheet/'
                $v = Parse-MainFactSheet -Html (Get-Page $entry.Source) -Planet $parts[1]
                if ($v) { $entry.Values = $v; $entry.Status = 'ok' }
            }
            'sheet' {
                $entry.Source = "https://nssdc.gsfc.nasa.gov/planetary/factsheet/$($parts[1]).html"
                $html = Get-Page $entry.Source
                $v = Parse-BodyFactSheet -Html $html
                $atm = Get-AtmosphereText -Html $html
                if ($atm) { $v['Atmosphere composition'] = $atm }
                # The per-body sheets carry the physics, but only the comparative sheet carries the
                # mean surface temperature ("Mean Temperature (C)") and the moon/ring counts, so the
                # planet's own column of that sheet is merged in. The body sheet wins on a collision.
                $main = Parse-MainFactSheet -Html (Get-Page 'https://nssdc.gsfc.nasa.gov/planetary/factsheet/') -Planet $parts[2]
                if ($main) {
                    foreach ($k in $main.Keys) { if (-not $v.Contains($k)) { $v[$k] = $main[$k] } }
                }
                if ($v.Count -gt 0) { $entry.Values = $v; $entry.Status = 'ok' }
            }
            'sat' {
                $sheet = "$($parts[1])satfact"
                $entry.Source = "https://nssdc.gsfc.nasa.gov/planetary/factsheet/$sheet.html"
                $v = Parse-SatelliteSheet -Html (Get-Page $entry.Source) -Moon $parts[2]
                if ($v) { $entry.Values = $v; $entry.Status = 'ok' }
            }
            'mooncol' {
                $entry.Source = "https://nssdc.gsfc.nasa.gov/planetary/factsheet/$($parts[1]).html"
                $v = Parse-MoonColumns -Html (Get-Page $entry.Source) -Moon $parts[2]
                if ($v) { $entry.Values = $v; $entry.Status = 'ok' }
            }
            'moonnames' {
                $entry.Source = "https://nssdc.gsfc.nasa.gov/planetary/factsheet/$($parts[1]).html"
                $v = Parse-NameColumns -Html (Get-Page $entry.Source) -Moon $parts[2] -TableHeading $parts[3]
                if ($v) { $entry.Values = $v; $entry.Status = 'ok' }
            }
            'exo' {
                if (-not $exo) { $exo = Get-ExoplanetTable }
                $entry.Source = 'https://exoplanetarchive.ipac.caltech.edu/overview/' + [uri]::EscapeDataString($parts[1])
                $row = $exo[$parts[2]]
                if ($row) { $entry.Values = Select-ExoValues $row; $entry.Status = 'ok' }
            }
            'fixed' {
                $entry.Source = $body.Source
                $entry.Values = $body.Data
                $entry.Status = 'ok'
                if ($body.Source) {
                    # A curated number is only worth as much as the page behind it, so the sentences
                    # that state it are kept. A page that will not load is recorded as such instead of
                    # throwing the body away.
                    try { $entry.Evidence = Get-Evidence -Url $body.Source } catch { $entry.EvidenceError = $_.Exception.Message }
                }
            }
            default { $entry.Status = 'missing' }
        }
    } catch {
        $entry.Status = 'missing'
        $entry.Error = $_.Exception.Message
    }
    if ($entry.Status -eq 'missing') { $missing += $key }
    $result.Bodies[$key] = $entry
    Write-Host (" -> " + $entry.Status)
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $CachePath -Encoding UTF8

$ok = @($result.Bodies.Keys | Where-Object { $result.Bodies[$_].Status -eq 'ok' }).Count
Write-Output "catalog bodies : $($catalog.Bodies.Keys.Count)"
Write-Output "resolved       : $ok"
Write-Output "curated-only   : $(@($result.Bodies.Keys | Where-Object { $result.Bodies[$_].Status -eq 'curated' }).Count)"
if ($missing.Count) { Write-Output "MISSING        : $($missing -join ', ')" }
Write-Output "cache          : $CachePath"
