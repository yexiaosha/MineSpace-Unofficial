<#
    Builds the two image assets the star map draws with.

    Both are generated rather than hand-drawn, and both are reproducible: run this script and the
    same files come back. The reasons are different for each.

    star_glow.png  - a radial gradient with a hot centre. A star is a tinted copy of it, so the
                     file itself is white and carries no colour at all: the spectral class of the
                     star decides what it looks like. It is generated because a hand-drawn
                     gradient is never as smooth as the formula, and because the previous build's
                     bug was in how this file was *sampled*, not in the file: see
                     MinespaceStarMapScreen.drawGlowingSphere.

    nebula.png     - a real photograph of a nebula, blurred and crushed to a wisp. Source is the
                     NASA image library, which is public domain, so it can be shipped inside the
                     jar; the credit line is written next to it in credits.txt. The processing is
                     what makes it usable as a backdrop: raw Hubble/Webb colour at full contrast
                     fights the star map for attention, and what is left after a heavy blur plus a
                     gamma crush is exactly the faint cloud structure that does not.

    Usage:
        tools\build-starmap-art.ps1
        tools\build-starmap-art.ps1 -Source tools\star-map-assets\PIA25434~medium.jpg `
            -CropX 0 -CropY 0 -CropW 1280 -CropH 1083
#>
[CmdletBinding()]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'star-map-assets\carina_nebula~medium.jpg'),

    # The region of the source to use, in source pixels. The whole image by default; a crop is how
    # a bright centre (Orion's core, Carina's cliffs) gets pushed off screen.
    [int]$CropX = 0,
    [int]$CropY = 0,
    [int]$CropW = 0,
    [int]$CropH = 0,

    # The backdrop is drawn stretched over a widescreen GUI, so it is generated widescreen: a square
    # texture stretched to 16:9 turns a round nebula into a horizontal smear.
    [int]$OutWidth = 1024,
    [int]$OutHeight = 512,
    [double]$Brightness = 0.75,
    [double]$Gamma = 2.0,
    [int]$BlurRadius = 4,
    [int]$BlurPasses = 2,
    [double]$Vignette = 0.55,

    [string]$OutDir = (Join-Path $PSScriptRoot '..\Minespace-unofficial\src\main\resources\assets\minespace\textures\gui'),
    [string]$PreviewDir = (Join-Path $PSScriptRoot 'star-map-assets')
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source)) {
    throw "Source image missing: $Source - download it from the NASA image library first (see credits.txt)."
}
$OutDir = [System.IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class StarArt
{
    /// alpha = smooth halo + hot core, on a transparent background, pure white.
    public static void Glow(string outPath, int size)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            double c = (size - 1) / 2.0;
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    double dx = (x - c) / c;
                    double dy = (y - c) / c;
                    double r = Math.Sqrt(dx * dx + dy * dy);
                    if (r > 1.0) { r = 1.0; }
                    double halo = Math.Pow(1.0 - r, 2.6);
                    double core = Math.Pow(Math.Max(0.0, 1.0 - r * 3.0), 1.7);
                    double a = Math.Min(1.0, halo * 0.75 + core * 0.80);
                    bmp.SetPixel(x, y, Color.FromArgb((int)Math.Round(a * 255.0), 255, 255, 255));
                }
            }
            bmp.Save(outPath, ImageFormat.Png);
        }
    }

    public static void Nebula(string srcPath, int cx, int cy, int cw, int ch, int width, int height,
        double brightness, double gamma, int blurRadius, int blurPasses, double vignette,
        string outPath)
    {
        int n = width * height;
        double[] red = new double[n];
        double[] green = new double[n];
        double[] blue = new double[n];

        using (var src = new Bitmap(srcPath))
        using (var dst = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(dst))
            {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                g.DrawImage(src, new Rectangle(0, 0, width, height), new Rectangle(cx, cy, cw, ch),
                    GraphicsUnit.Pixel);
            }
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    Color c = dst.GetPixel(x, y);
                    int i = y * width + x;
                    red[i] = c.R;
                    green[i] = c.G;
                    blue[i] = c.B;
                }
            }
        }

        for (int pass = 0; pass < blurPasses; pass++)
        {
            red = BlurX(red, width, height, blurRadius);
            green = BlurX(green, width, height, blurRadius);
            blue = BlurX(blue, width, height, blurRadius);
            red = BlurY(red, width, height, blurRadius);
            green = BlurY(green, width, height, blurRadius);
            blue = BlurY(blue, width, height, blurRadius);
        }

        using (var outBmp = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        {
            double centreX = (width - 1) / 2.0;
            double centreY = (height - 1) / 2.0;
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int i = y * width + x;
                    double dx = (x - centreX) / centreX;
                    double dy = (y - centreY) / centreY;
                    double r = Math.Min(1.0, Math.Sqrt(dx * dx + dy * dy));
                    double fall = Math.Pow(1.0 - r, vignette);
                    outBmp.SetPixel(x, y, Color.FromArgb(255,
                        Channel(red[i], brightness, gamma, fall),
                        Channel(green[i], brightness, gamma, fall),
                        Channel(blue[i], brightness, gamma, fall)));
                }
            }
            outBmp.Save(outPath, ImageFormat.Png);
        }
    }

    private static int Channel(double value, double brightness, double gamma, double fall)
    {
        double v = Math.Min(1.0, value / 255.0 * brightness) * fall;
        v = Math.Pow(v, gamma);
        return (int)Math.Round(v * 255.0);
    }

    private static double[] BlurX(double[] src, int width, int height, int radius)
    {
        double[] dst = new double[src.Length];
        for (int y = 0; y < height; y++)
        {
            int row = y * width;
            for (int x = 0; x < width; x++)
            {
                double sum = 0.0;
                int count = 0;
                for (int k = -radius; k <= radius; k++)
                {
                    int sx = x + k;
                    if (sx < 0 || sx >= width) { continue; }
                    sum += src[row + sx];
                    count++;
                }
                dst[row + x] = sum / count;
            }
        }
        return dst;
    }

    private static double[] BlurY(double[] src, int width, int height, int radius)
    {
        double[] dst = new double[src.Length];
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                double sum = 0.0;
                int count = 0;
                for (int k = -radius; k <= radius; k++)
                {
                    int sy = y + k;
                    if (sy < 0 || sy >= height) { continue; }
                    sum += src[sy * width + x];
                    count++;
                }
                dst[y * width + x] = sum / count;
            }
        }
        return dst;
    }
}
'@

$glowPath = Join-Path $OutDir 'star_glow.png'
[StarArt]::Glow($glowPath, 128)
Write-Host "wrote $glowPath"

if ($CropW -le 0 -or $CropH -le 0) {
    $probe = [System.Drawing.Image]::FromFile($Source)
    if ($CropW -le 0) { $CropW = $probe.Width }
    if ($CropH -le 0) { $CropH = $probe.Height }
    $probe.Dispose()
}

$nebulaPath = Join-Path $OutDir 'nebula.png'
[StarArt]::Nebula($Source, $CropX, $CropY, $CropW, $CropH, $OutWidth, $OutHeight, $Brightness, $Gamma,
    $BlurRadius, $BlurPasses, $Vignette, $nebulaPath)
Write-Host "wrote $nebulaPath"

# A copy next to the source, so the result can be looked at without opening the jar.
New-Item -ItemType Directory -Force -Path $PreviewDir | Out-Null
Copy-Item -LiteralPath $nebulaPath -Destination (Join-Path $PreviewDir 'preview-nebula.png') -Force
Copy-Item -LiteralPath $glowPath -Destination (Join-Path $PreviewDir 'preview-star-glow.png') -Force
