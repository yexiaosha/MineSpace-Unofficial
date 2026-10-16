<#
    gen-planet-dimension-table.ps1 - writes the addon's compile-time table of planned dimensions.

    Why generated: PLANET-CATALOG.md is the owner's design document and planet-catalog.psd1 is its
    source; the addon needs the same list as Java. Generating it means the catalog stays the single
    source of truth and the addon depends on no file at runtime.

    Which rows: every body whose planned dimension is in the deep-space ranges (-2000..-2449). The five
    bodies already in the game (Proxima B, Barnard's Star b/c/d, Tau Ceti F) carry their Galacticraft or
    Galaxy Space ids, so they are not in this table - they are registered by those mods.

    Landable follows the catalog's own rule, which is the one its 不适用 text uses: a Planet, Moon,
    DwarfPlanet or AsteroidBelt can be landed on; a Star, WhiteDwarf, Pulsar, BlackHole, Galaxy, Nebula,
    Cluster, Quasar, Transient, SupernovaRemnant, CosmicWeb, CMB, GravitationalWave or
    InterstellarObject cannot. (Two gas giants in layer 3 are typed Planet by the catalog; they are
    handled in planet-veins.psd1 rather than here.)

    Output: src\main\java\com\minespace\unofficial\gtceu\MinespacePlanetDimensions.java
#>
[CmdletBinding()]
param(
    [string]$CatalogCsv = (Join-Path $PSScriptRoot 'planet-catalog.csv'),
    [string]$OutFile = (Join-Path $PSScriptRoot '..\src\main\java\com\minespace\unofficial\gtceu\MinespacePlanetDimensions.java')
)

$ErrorActionPreference = 'Stop'
$landableTypes = @('Planet', 'Moon', 'DwarfPlanet', 'AsteroidBelt')

# -Encoding UTF8 matters: without it PowerShell 5.1 reads the CSV as ANSI and the Chinese names come
# out as mojibake, which then breaks the string literals.
# A row's PlannedDim may name **more than one** dimension: Venus is the same planet in Galacticraft (-31) and in
# Galaxy Space (-1006), and the catalog writes both. Requiring a cell that is nothing but a number silently threw
# that row away - the star map was missing Venus and nothing said so. The first id is the one the pack treats as
# the body's own; the others are its mirrors and are left to whoever registered them.
$rows = Import-Csv -Encoding UTF8 $CatalogCsv |
        Where-Object { $_.PlannedDim -match '^-?\d+' } |
        Sort-Object { [int]($_.PlannedDim -replace '^(-?\d+).*', '$1') }

# Everything that goes into a Java string is escaped to \uXXXX. javac reads a source file in the
# platform encoding unless told otherwise, and this machine's is GBK - escaping sidesteps the question
# entirely, the same way the pack's own .lang files do it.
function ConvertTo-JavaLiteral([string]$text) {
    $builder = New-Object System.Text.StringBuilder
    foreach ($character in $text.ToCharArray()) {
        $code = [int]$character
        if ($code -eq 34) { [void]$builder.Append('\"') }
        elseif ($code -eq 92) { [void]$builder.Append('\\') }
        elseif ($code -ge 32 -and $code -le 126) { [void]$builder.Append($character) }
        else { [void]$builder.AppendFormat('\u{0:x4}', $code) }
    }
    return $builder.ToString()
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('package com.minespace.unofficial.gtceu;')
$lines.Add('')
$lines.Add('import java.util.Arrays;')
$lines.Add('import java.util.List;')
$lines.Add('')
$lines.Add('/**')
$lines.Add(' * The planned dimensions, generated from tools\planet-catalog.csv by')
$lines.Add(' * tools\gen-planet-dimension-table.ps1 - do not edit by hand, and re-run that script after the')
$lines.Add(' * catalog changes.')
$lines.Add(' *')
$lines.Add(' * <p>Registering these is deliberately cheap and deliberately incomplete: no terrain, no rock')
$lines.Add(' * blocks, one shared provider (see MinespacePlanetWorldProvider). Registering a dimension does')
$lines.Add(' * not create a world - 6dl measured that - so eighty-one of these cost nothing until something')
$lines.Add(' * travels to one. What it buys is that every id in planet-veins.psd1 points at a dimension that')
$lines.Add(' * exists, and that the star map work has ids to talk about.</p>')
$lines.Add(' */')
$lines.Add('public final class MinespacePlanetDimensions {')
$lines.Add('')
$lines.Add('    /** One planned body. */')
$lines.Add('    public static final class Planet {')
$lines.Add('')
$lines.Add('        public final int dimensionId;')
$lines.Add('        public final String name;')
$lines.Add('        public final String nameZh;')
$lines.Add('        public final int layer;')
$lines.Add('        public final int stage;')
$lines.Add('        /** False for a star, black hole, galaxy: it gets an id, and nothing can land on it. */')
$lines.Add('        public final boolean landable;')
$lines.Add('        /** How many veins its card carries once planet-veins.psd1 has written them. */')
$lines.Add('        public final int veins;')
$lines.Add('        /** Registry-safe key, used for the dimension type name. */')
$lines.Add('        public final String key;')
$lines.Add('        /**')
$lines.Add('         * The star this body orbits, from the catalog. Empty for a body that is not a planet -')
$lines.Add('         * a star, a black hole, a galaxy - which then stands as its own system on the star map.')
$lines.Add('         */')
$lines.Add('        public final String star;')
$lines.Add('        /**')
$lines.Add('         * Its orbital distance from that star, in AU, from the catalog. 0 when the catalog has no')
$lines.Add('         * figure - the star map then spaces the bodies of that system by rank instead. The solar')
$lines.Add('         * system is the one that matters here: a moon carries its parent''s distance plus a small')
$lines.Add('         * offset, so the ring order is the real one (Mercury inside, the Kuiper belt outside).')
$lines.Add('         */')
$lines.Add('        public final float orbitAu;')
$lines.Add('        /**')
$lines.Add('         * The planet this body orbits, or empty for a planet, a belt or an object that orbits the star')
$lines.Add('         * directly. A moon is drawn around its planet on the star map, and its card says so.')
$lines.Add('         */')
$lines.Add('        public final String parent;')
$lines.Add('        /**')
$lines.Add('         * How far this body - or its star, for a planet - is from Earth, in light years. 0 when the')
$lines.Add('         * catalog has no figure. The solar system''s own bodies carry their radius from the Sun here, which')
$lines.Add('         * is why the card prefers the orbital distance when the body is one of them.')
$lines.Add('         */')
$lines.Add('        public final float distanceLy;')
$lines.Add('        /** The kind of body, from the catalog: Planet, Moon, Star, BlackHole, Galaxy, Nebula, Pulsar... */')
$lines.Add('        public final String type;')
$lines.Add('        /**')
$lines.Add('         * Its orbital period in days, from the catalog - the real one, so that however fast the clock is')
$lines.Add('         * turned the bodies keep their true ratios to each other. 0 means no figure: drawn standing still.')
$lines.Add('         */')
$lines.Add('        public final float periodDays;')
$lines.Add('')
$lines.Add('        Planet(int dimensionId, String name, String nameZh, int layer, int stage, boolean landable,')
$lines.Add('                int veins, String key, String star, float orbitAu, String parent, float distanceLy,')
$lines.Add('                String type, float periodDays) {')
$lines.Add('            this.dimensionId = dimensionId;')
$lines.Add('            this.name = name;')
$lines.Add('            this.nameZh = nameZh;')
$lines.Add('            this.layer = layer;')
$lines.Add('            this.stage = stage;')
$lines.Add('            this.landable = landable;')
$lines.Add('            this.veins = veins;')
$lines.Add('            this.key = key;')
$lines.Add('            this.star = star;')
$lines.Add('            this.orbitAu = orbitAu;')
$lines.Add('            this.parent = parent;')
$lines.Add('            this.distanceLy = distanceLy;')
$lines.Add('            this.type = type;')
$lines.Add('            this.periodDays = periodDays;')
$lines.Add('        }')
$lines.Add('    }')
$lines.Add('')
$lines.Add('    public static final List<Planet> PLANETS = Arrays.asList(')

$rows = @($rows)
for ($index = 0; $index -lt $rows.Count; $index++) {
    $row = $rows[$index]
    # The catalog can override the type rule ("Landable = no"): a gas giant is a Planet and still not somewhere a
    # rocket can put down. Empty means "the type decides", which is how every other row is written.
    $landable = if ($row.Landable -match '^(no|false|0)$') { 'false' }
                elseif ($row.Landable -match '^(yes|true|1)$') { 'true' }
                elseif ($landableTypes -contains $row.Type) { 'true' }
                else { 'false' }
    # The real orbital distance, in AU, for the bodies whose system has one (the solar system does). 0 means the
    # catalog has no figure, and the star map falls back to its own even spacing.
    $orbitAu = 0.0
    if ($row.OrbitAu -match '^\d+(\.\d+)?$') { $orbitAu = [double]$row.OrbitAu }
    $orbit = $orbitAu.ToString('0.####', [System.Globalization.CultureInfo]::InvariantCulture) + 'F'
    # A moon names the planet it orbits. The star map draws it around that planet rather than on a solar ring of
    # its own, which is the difference between a list of bodies and a solar system.
    $parent = ConvertTo-JavaLiteral $row.Parent
    # How far the body - or, for a planet, its star - is from Earth, in light years. The catalog keeps the figure as
    # the text it was curated in ("4.24 ly", "~2.5 million ly", "384,400 km"); this is that number, so the card can
    # print it in the unit the size calls for instead of parroting the string.
    $distanceLy = 0.0
    if ($row.DistanceLy -match '^\d+(\.\d+)?([eE][-+]?\d+)?$') { $distanceLy = [double]$row.DistanceLy }
    $distance = $distanceLy.ToString('0.##########', [System.Globalization.CultureInfo]::InvariantCulture) + 'F'
    # The kind of body (Planet, Moon, DwarfPlanet, AsteroidBelt, Star, BlackHole, Galaxy, Nebula, Pulsar, Quasar,
    # Cluster, ...) - the star map draws each kind as itself rather than as a star, which is the only way a black
    # hole and a galaxy stop looking like "a star system we did not fill in".
    $type = ConvertTo-JavaLiteral $row.Type
    # Its orbital period in days, from the catalog. The screen uses the real ratios: whatever scale is chosen, Io
    # goes round Jupiter in a 1.769 : 27.32 : 365.256 : 60182 proportion of Mercury's, the Moon's, Earth's and
    # Neptune's own year. 0 means the catalog has no figure and the body is drawn where it is.
    $periodDays = 0.0
    if ($row.PeriodDays -match '^\d+(\.\d+)?$') { $periodDays = [double]$row.PeriodDays }
    $period = $periodDays.ToString('0.####', [System.Globalization.CultureInfo]::InvariantCulture) + 'F'
    $veins = if ($row.VeinCount -match '^\d+$') { [int]$row.VeinCount } else { 0 }
    # Stage is a range for the solar system too ("0-3") - same guard as LayerIndex.
    $stageInt = 0
    if ($row.Stage -match '^(\d+)') { $stageInt = [int]$Matches[1] }
    $key = ($row.En -replace '[^A-Za-z0-9]+', '_').ToLower().Trim('_')
    if ($key.Length -gt 40) { $key = $key.Substring(0, 40) }
    $name = ConvertTo-JavaLiteral $row.En
    $nameZh = ConvertTo-JavaLiteral $row.Zh
    # The host star groups planets into systems; a body without one is its own system.
    # LayerIndex is a range for the solar system ("0-3") and empty for a row the catalog did not place, so
    # neither [int] nor a bare -replace is safe: read the first digits if there are any, else 0.
    $layerInt = 0
    if ($row.LayerIndex -match '^(\d+)') { $layerInt = [int]$Matches[1] }
    # The solar system is one system, not twenty: those rows name no host star because they orbit the Sun.
    $starText = ''
    if ($layerInt -le 1) { $starText = 'Sol' }
    elseif ($landableTypes -contains $row.Type) { $starText = $row.Star }
    $star = ConvertTo-JavaLiteral $starText
    # No trailing comma on the last one: a Java array initializer allows it, an argument list does not.
    $comma = if ($index -lt $rows.Count - 1) { ',' } else { '' }
    $lines.Add(('            new Planet({0}, "{1}", "{2}", {3}, {4}, {5}, {6}, "{7}", "{8}", {9}, "{10}", {11}, "{12}", {13}){14}' -f `
                    [int]($row.PlannedDim -replace '^(-?\d+).*', '$1'), $name, $nameZh, $layerInt, $stageInt,
                    $landable, $veins, $key, $star, $orbit, $parent, $distance, $type, $period, $comma))
}

$lines.Add('    );')
$lines.Add('')
$lines.Add('    private MinespacePlanetDimensions() {')
$lines.Add('    }')
$lines.Add('}')

[System.IO.File]::WriteAllLines($OutFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
$landableCount = ($rows | Where-Object { $landableTypes -contains $_.Type }).Count
Write-Host ("wrote {0} planned dimensions to {1}" -f $rows.Count, $OutFile)
Write-Host ("    landable {0}, observation only {1}" -f $landableCount, ($rows.Count - $landableCount))
