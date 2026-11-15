# Generates the app / home-screen icons for Axolotl-tabeller: the happy axolotl from art/axolotl-happy.png
# on the game's water gradient, with a few bubbles.
# Run with Windows PowerShell (System.Drawing):  powershell -File tools\make-icons.ps1
param(
    [string]$OutDir = (Join-Path $PSScriptRoot "..\src\AxolotlTables\wwwroot\icons"),
    [string]$Art = (Join-Path $PSScriptRoot "..\art\axolotl-happy.png"),
    # The front page (KidsGames) shows each game's 512 px icon; pass its billeder folder to update it too.
    [string]$FrontPageDir = (Join-Path $PSScriptRoot "..\..\KidsGames\billeder")
)

Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Color([string]$hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush([string]$hex) { New-Object System.Drawing.SolidBrush (Color $hex) }

$axolotl = [System.Drawing.Image]::FromFile((Resolve-Path $Art))

# content: 1.0 = full size, 0.78 = keep inside the maskable safe zone
function Draw-Icon([int]$size, [string]$file, [float]$content = 1.0, [bool]$detail = $true) {
    $S = [float]$size
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    # Background: the game's water gradient (full square, iOS applies its own rounded mask)
    $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.PointF 0, 0), (New-Object System.Drawing.PointF 0, $S), (Color '#66d9e8'), (Color '#e6fcf5')
    $g.FillRectangle($bg, 0, 0, $S, $S)

    if ($detail) {
        # Bubbles rising on the left
        $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 255, 255, 255)), ($S * 0.012)
        $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 255, 255, 255))
        foreach ($b in @(@(0.10, 0.20, 0.045), @(0.17, 0.09, 0.03), @(0.07, 0.36, 0.025))) {
            $r = $S * $b[2]
            $x = $S * $b[0]
            $y = $S * $b[1]
            $g.FillEllipse($fill, $x - $r, $y - $r, 2 * $r, 2 * $r)
            $g.DrawEllipse($ring, $x - $r, $y - $r, 2 * $r, 2 * $r)
        }
    }

    # The axolotl, as large as fits, a little below the middle
    $box = $S * 0.86 * $content
    $scale = [Math]::Min($box / $axolotl.Width, $box / $axolotl.Height)
    $w = $axolotl.Width * $scale
    $h = $axolotl.Height * $scale
    $g.DrawImage($axolotl, ($S - $w) / 2, ($S - $h) / 2 + $S * 0.03 * $content, $w, $h)

    $g.Dispose()
    $bmp.Save((Join-Path $OutDir $file), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $file"
}

Write-Host "Writing icons to $OutDir"
Draw-Icon 180  'apple-touch-icon.png'
Draw-Icon 167  'apple-touch-icon-167.png'
Draw-Icon 152  'apple-touch-icon-152.png'
Draw-Icon 192  'icon-192.png'
Draw-Icon 512  'icon-512.png'
Draw-Icon 1024 'icon-1024.png'
Draw-Icon 512  'icon-512-maskable.png' 0.78
Draw-Icon 32   'favicon-32.png' 1.12 $false
$axolotl.Dispose()

if (Test-Path $FrontPageDir) {
    Copy-Item (Join-Path $OutDir 'icon-512.png') (Join-Path $FrontPageDir 'axolotltables.png')
    Write-Host "Copied icon-512.png to $FrontPageDir\axolotltables.png"
}
