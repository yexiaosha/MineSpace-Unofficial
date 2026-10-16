<#
    Draws the six research-data icons and writes the six item models that point at them.

    Generated rather than hand-drawn for the same reason the star map's glow sprite is: a 16x16 icon with a stripe on it
    is a formula, and a formula is reproducible. Each tier gets its own hue so a hotbar with two of them is readable at
    a glance, and the stripe count is the tier, so the icons differ in shape as well as in colour.

    The models are vanilla "item/generated" ones, one per metadata value, because a Forge item with subtypes needs a
    model resource location per subtype (see MinespaceResearchData and the client proxy's model binding).
#>
[CmdletBinding()]
param(
    [string]$Assets = (Join-Path $PSScriptRoot '..\Minespace-unofficial\src\main\resources\assets\minespace')
)
$ErrorActionPreference = 'Stop'
$Assets = [System.IO.Path]::GetFullPath($Assets)
$textureDir = Join-Path $Assets 'textures\items'
$modelDir = Join-Path $Assets 'models\item'
New-Item -ItemType Directory -Force -Path $textureDir, $modelDir | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class ResearchArt
{
    // A card: dark case, a lighter screen, a coloured stripe, and one bar per tier.
    public static void Draw(string path, int tier, Color stripe)
    {
        using (var bmp = new Bitmap(16, 16, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.FillRectangle(new SolidBrush(Color.FromArgb(255, 48, 50, 58)), 1, 2, 14, 12);
            g.FillRectangle(new SolidBrush(Color.FromArgb(255, 26, 28, 34)), 2, 3, 12, 10);
            g.FillRectangle(new SolidBrush(stripe), 2, 3, 12, 3);
            g.FillRectangle(new SolidBrush(Color.FromArgb(255, 200, 210, 220)), 4, 8, 8, 1);
            for (int i = 0; i < tier; i++)
            {
                g.FillRectangle(new SolidBrush(Color.FromArgb(255, 160, 175, 190)), 4, 10 + i, 3, 1);
            }
            g.FillRectangle(new SolidBrush(Color.FromArgb(255, 120, 130, 140)), 1, 13, 14, 1);
            bmp.Save(path, ImageFormat.Png);
        }
    }
}
'@

# Tier colours run cool to hot as the tiers go out: blue-violet at the near systems, white-hot at the unknown.
$hues = @(210, 190, 165, 130, 95, 55)

for ($tier = 1; $tier -le 6; $tier++) {
    $hue = $hues[$tier - 1]
    $stripe = [System.Drawing.Color]::FromArgb(255,
        [int](255 * (1.0 - [Math]::Abs((($hue / 60.0) % 2.0) - 1.0))),
        [int](255 * (1.0 - [Math]::Abs((($hue / 60.0) % 2.0) - 1.0))),
        [int](255 * (1.0 - [Math]::Abs((($hue / 60.0) % 2.0) - 1.0))))
    # A plain HSV-to-RGB for the one colour that matters; the case and the screen stay neutral on purpose.
    $h = $hue / 360.0
    $rgb = @(0, 0, 0)
    for ($i = 0; $i -lt 3; $i++) {
        $rgb[$i] = [int](255 * [Math]::Max(0.0, [Math]::Min(1.0,
            1.0 - [Math]::Abs((($h * 6.0 + (2 - $i) * 2.0) % 6.0) - 3.0) + 1.0 - 2.0)))
    }
    $stripe = [System.Drawing.Color]::FromArgb(255,
        [Math]::Min(255, 120 + $rgb[0] / 3), [Math]::Min(255, 120 + $rgb[1] / 3), [Math]::Min(255, 120 + $rgb[2] / 3))

    $texture = Join-Path $textureDir ("research_data_{0}.png" -f $tier)
    [ResearchArt]::Draw($texture, $tier, $stripe)

    $model = @{
        parent = 'item/generated'
        textures = @{ layer0 = ("minespace:items/research_data_{0}" -f $tier) }
    } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText((Join-Path $modelDir ("research_data_{0}.json" -f $tier)), $model,
        (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ("research data {0}: {1}" -f $tier, $texture)
}
