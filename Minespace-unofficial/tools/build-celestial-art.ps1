<#
    Builds the body icons Galacticraft's and PlanetProgression's own screens draw for this pack's bodies.

    MinespaceCelestialRegistry gives every registered body an icon ResourceLocation, one per **kind** of body rather
    than one per body: twenty-one files for a hundred and ten bodies. The alternative was a hundred and ten textures
    that this pack's own star map never looks at - because it draws from the catalog, not from Galacticraft - and a
    kind is also what a map legend shows. A missing icon is not a crash (a missing texture draws as the checkerboard),
    but a checkerboard in someone else's map reads as a bug in this pack.

    Generated rather than drawn by hand, and reproducible: run this script and the same files come back. Each icon is a
    shaded disc in a palette of its kind plus the one feature that tells that kind apart at 48 pixels - a ring for a
    black hole, jets for a pulsar, bands for a gas giant, dots for a belt.

    Usage:
        tools\build-celestial-art.ps1
#>
[CmdletBinding()]
param(
    [int]$Size = 64,
    [string]$OutDir = (Join-Path $PSScriptRoot '..\src\main\resources\assets\minespace\textures\gui\celestialbodies')
)
$ErrorActionPreference = 'Stop'
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class CelestialArt
{
    // A tiny deterministic generator: the same icon every run, and no Random whose seed changes between machines.
    private static double Next(ref uint state)
    {
        state = state * 1664525u + 1013904223u;
        return (state >> 8) / 16777216.0;
    }

    private static void Disc(Graphics g, int size, double cx, double cy, double radius,
        Color core, Color rim, double alpha)
    {
        double r = radius * size * 0.5;
        using (var path = new GraphicsPath())
        {
            path.AddEllipse((float)(cx * size - r), (float)(cy * size - r), (float)(r * 2), (float)(r * 2));
            using (var brush = new PathGradientBrush(path))
            {
                brush.CenterColor = Color.FromArgb((int)(255 * alpha), core);
                brush.SurroundColors = new Color[] { Color.FromArgb(0, rim) };
                g.FillPath(brush, path);
            }
        }
    }

    private static void Dot(Graphics g, int size, double cx, double cy, double radius, Color colour)
    {
        double r = radius * size * 0.5;
        using (var brush = new SolidBrush(colour))
        {
            g.FillEllipse(brush, (float)(cx * size - r), (float)(cy * size - r), (float)(r * 2), (float)(r * 2));
        }
    }

    private static void Ring(Graphics g, int size, double radius, double width, Color colour)
    {
        double r = radius * size * 0.5;
        using (var pen = new Pen(colour, (float)(width * size * 0.5)))
        {
            g.DrawEllipse(pen, (float)(size / 2.0 - r), (float)(size / 2.0 - r), (float)(r * 2), (float)(r * 2));
        }
    }

    private static void Band(Graphics g, int size, double radius, double from, double to, Color colour)
    {
        double r = radius * size * 0.5;
        var state = g.Save();
        using (var path = new GraphicsPath())
        {
            path.AddEllipse((float)(size / 2.0 - r), (float)(size / 2.0 - r), (float)(r * 2), (float)(r * 2));
            g.SetClip(path);
            using (var brush = new SolidBrush(colour))
            {
                g.FillRectangle(brush, 0, (float)(from * size), size, (float)((to - from) * size));
            }
        }
        g.Restore(state);
    }

    public static void Draw(string path, int size, string kind)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.Clear(Color.Transparent);
                uint seed = 20161016u;
                double cx = 0.5, cy = 0.5;
                switch (kind)
                {
                    case "star":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 255, 245, 225), Color.FromArgb(255, 255, 160, 60), 1.0);
                        break;
                    case "white_dwarf":
                        Disc(g, size, cx, cy, 0.62, Color.FromArgb(255, 255, 255, 255), Color.FromArgb(255, 150, 190, 255), 1.0);
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 220, 240, 255), Color.FromArgb(255, 120, 170, 255), 0.45);
                        break;
                    case "galaxy":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 255, 246, 225), Color.FromArgb(255, 170, 170, 240), 0.95);
                        Disc(g, size, cx, cy, 0.30, Color.FromArgb(255, 255, 255, 240), Color.FromArgb(255, 200, 200, 255), 1.0);
                        Ring(g, size, 0.78, 0.06, Color.FromArgb(150, 220, 220, 255));
                        break;
                    case "cluster":
                        for (int i = 0; i < 40; i++)
                        {
                            double a = Next(ref seed) * Math.PI * 2, d = Next(ref seed) * 0.42;
                            Dot(g, size, cx + Math.Cos(a) * d, cy + Math.Sin(a) * d, 0.12 + Next(ref seed) * 0.1,
                                Color.FromArgb(210, 255, 240, 210));
                        }
                        Disc(g, size, cx, cy, 0.9, Color.FromArgb(120, 255, 240, 220), Color.FromArgb(0, 255, 220, 180), 0.7);
                        break;
                    case "nebula":
                        for (int i = 0; i < 26; i++)
                        {
                            double a = Next(ref seed) * Math.PI * 2, d = Next(ref seed) * 0.36;
                            Color c = i % 2 == 0 ? Color.FromArgb(90, 255, 120, 200) : Color.FromArgb(80, 120, 220, 255);
                            Dot(g, size, cx + Math.Cos(a) * d, cy + Math.Sin(a) * d, 0.34 + Next(ref seed) * 0.28, c);
                        }
                        break;
                    case "black_hole":
                        // The glow first, then the hot ring, then the hole: drawn the other way round the core was an
                        // opaque brown disc, which is what a black hole is not.
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(90, 255, 200, 140), Color.FromArgb(0, 255, 170, 90), 0.9);
                        Ring(g, size, 0.62, 0.07, Color.FromArgb(235, 255, 190, 110));
                        Dot(g, size, cx, cy, 0.50, Color.FromArgb(255, 5, 5, 9));
                        break;
                    case "quasar":
                        Disc(g, size, cx, cy, 0.42, Color.FromArgb(255, 255, 255, 255), Color.FromArgb(255, 160, 210, 255), 1.0);
                        Ring(g, size, 0.5, 0.05, Color.FromArgb(210, 220, 240, 255));
                        Dot(g, size, cx, cy, 1.1, Color.FromArgb(120, 255, 240, 210));
                        break;
                    case "pulsar":
                        Disc(g, size, cx, cy, 0.34, Color.FromArgb(255, 235, 250, 255), Color.FromArgb(255, 110, 190, 255), 1.0);
                        using (var pen = new Pen(Color.FromArgb(160, 150, 220, 255), size * 0.06f))
                        {
                            g.DrawLine(pen, 0, (float)(size * 0.30), size, (float)(size * 0.70));
                            g.DrawLine(pen, 0, (float)(size * 0.70), size, (float)(size * 0.30));
                        }
                        break;
                    case "supernova":
                        Ring(g, size, 0.82, 0.10, Color.FromArgb(220, 255, 150, 120));
                        Ring(g, size, 0.55, 0.07, Color.FromArgb(180, 255, 220, 160));
                        Dot(g, size, cx, cy, 0.30, Color.FromArgb(255, 255, 255, 240));
                        break;
                    case "gravitational_wave":
                        for (int i = 1; i <= 4; i++)
                        {
                            Ring(g, size, 0.14 * i + 0.12, 0.035, Color.FromArgb(170 - i * 25, 200, 230, 255));
                        }
                        break;
                    case "cmb":
                        for (int i = 0; i < 90; i++)
                        {
                            double a = Next(ref seed) * Math.PI * 2, d = Math.Sqrt(Next(ref seed)) * 0.46;
                            double v = Next(ref seed);
                            Color c = v > 0.66 ? Color.FromArgb(150, 255, 170, 110)
                                    : v > 0.33 ? Color.FromArgb(150, 120, 170, 255)
                                    : Color.FromArgb(150, 240, 240, 220);
                            Dot(g, size, cx + Math.Cos(a) * d, cy + Math.Sin(a) * d, 0.16, c);
                        }
                        break;
                    case "transient":
                        Disc(g, size, 0.40, 0.50, 0.90, Color.FromArgb(230, 220, 240, 255), Color.FromArgb(0, 180, 200, 255), 0.85);
                        Dot(g, size, 0.60, 0.50, 0.30, Color.FromArgb(255, 255, 255, 250));
                        Dot(g, size, 0.78, 0.50, 0.16, Color.FromArgb(180, 200, 230, 255));
                        break;
                    case "interstellar":
                        Disc(g, size, cx, cy, 0.72, Color.FromArgb(235, 210, 190, 165), Color.FromArgb(255, 90, 75, 60), 1.0);
                        Dot(g, size, 0.40, 0.44, 0.16, Color.FromArgb(120, 60, 50, 45));
                        break;
                    case "belt":
                        for (int i = 0; i < 34; i++)
                        {
                            double a = i / 34.0 * Math.PI * 2;
                            double d = 0.74 + Next(ref seed) * 0.12;
                            Dot(g, size, cx + Math.Cos(a) * d, cy + Math.Sin(a) * d * 0.42, 0.12,
                                Color.FromArgb(220, 215, 205, 185));
                        }
                        break;
                    case "cosmic_web":
                        for (int i = 0; i < 9; i++)
                        {
                            double ax = Next(ref seed), ay = Next(ref seed), bx = Next(ref seed), by = Next(ref seed);
                            using (var pen = new Pen(Color.FromArgb(120, 190, 210, 255), size * 0.02f))
                            {
                                g.DrawLine(pen, (float)(ax * size), (float)(ay * size), (float)(bx * size), (float)(by * size));
                            }
                        }
                        for (int i = 0; i < 9; i++)
                        {
                            Dot(g, size, Next(ref seed), Next(ref seed), 0.14, Color.FromArgb(235, 240, 235, 210));
                        }
                        break;
                    case "dwarf_planet":
                        Disc(g, size, cx, cy, 0.78, Color.FromArgb(255, 225, 220, 205), Color.FromArgb(255, 105, 100, 95), 1.0);
                        Dot(g, size, 0.40, 0.42, 0.14, Color.FromArgb(110, 80, 78, 74));
                        break;
                    case "moon_ice":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 240, 250, 255), Color.FromArgb(255, 130, 175, 210), 1.0);
                        Dot(g, size, 0.62, 0.38, 0.16, Color.FromArgb(90, 170, 205, 235));
                        Dot(g, size, 0.36, 0.64, 0.12, Color.FromArgb(90, 170, 205, 235));
                        break;
                    case "moon_rock":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 225, 222, 215), Color.FromArgb(255, 110, 106, 100), 1.0);
                        Dot(g, size, 0.38, 0.40, 0.16, Color.FromArgb(120, 120, 116, 110));
                        Dot(g, size, 0.64, 0.62, 0.11, Color.FromArgb(120, 120, 116, 110));
                        break;
                    case "gas_giant":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 245, 225, 195), Color.FromArgb(255, 170, 130, 90), 1.0);
                        Band(g, size, 1.0, 0.30, 0.38, Color.FromArgb(90, 190, 150, 110));
                        Band(g, size, 1.0, 0.52, 0.58, Color.FromArgb(80, 190, 150, 110));
                        break;
                    case "planet_ice":
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 235, 250, 255), Color.FromArgb(255, 120, 165, 200), 1.0);
                        Band(g, size, 1.0, 0.44, 0.54, Color.FromArgb(70, 150, 195, 225));
                        break;
                    default: // planet_rocky
                        Disc(g, size, cx, cy, 1.0, Color.FromArgb(255, 200, 215, 185), Color.FromArgb(255, 80, 105, 80), 1.0);
                        Dot(g, size, 0.42, 0.56, 0.22, Color.FromArgb(80, 60, 90, 70));
                        break;
                }
            }
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
'@

$kinds = @(
    'star', 'white_dwarf', 'galaxy', 'cluster', 'nebula', 'black_hole', 'quasar', 'pulsar', 'supernova',
    'gravitational_wave', 'cmb', 'transient', 'interstellar', 'belt', 'cosmic_web', 'dwarf_planet',
    'moon_ice', 'moon_rock', 'gas_giant', 'planet_ice', 'planet_rocky'
)
foreach ($kind in $kinds) {
    $path = Join-Path $OutDir "$kind.png"
    [CelestialArt]::Draw($path, $Size, $kind)
    Write-Host "wrote $path"
}
Write-Host "$($kinds.Count) body icons at ${Size}x${Size} in $OutDir"
