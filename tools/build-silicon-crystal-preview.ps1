param([string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repo = (Resolve-Path $RepositoryRoot).Path
$sourceRoot = Join-Path $repo "assets\windows-themes\silicon\Concepts\CrystalSource\crystal-remix-icon-theme-2.8\128x128"
$output = Join-Path $repo "assets\windows-themes\silicon\Concepts\JANUS-Silicon-Crystal-Punteros-Propuesta.png"

$icons = @(
    @("devices\computer.png", "Este equipo"),
    @("places\user-home.png", "Archivos del usuario"),
    @("places\network-workgroup.png", "Red"),
    @("places\user-trash.png", "Papelera vacía"),
    @("places\user-trash-full.png", "Papelera llena"),
    @("places\user-desktop.png", "Escritorio"),
    @("places\folder-documents.png", "Documentos"),
    @("places\folder-download.png", "Descargas"),
    @("places\folder-pictures.png", "Imágenes"),
    @("places\folder-music.png", "Música"),
    @("places\folder-videos.png", "Vídeos"),
    @("devices\drive-harddisk.png", "HDD / SSD"),
    @("devices\drive-removable-media-usb-pendrive.png", "USB"),
    @("places\network-server.png", "Unidad de red")
)

function New-Font([single]$size, [Drawing.FontStyle]$style = [Drawing.FontStyle]::Regular) {
    New-Object Drawing.Font "Segoe UI", $size, $style
}

function Draw-Arrow([Drawing.Graphics]$graphics, [int]$x, [int]$y, [double]$scale = 1.0) {
    $points = [Drawing.PointF[]]@(
        [Drawing.PointF]::new([float]$x, [float]$y),
        [Drawing.PointF]::new([float]($x + 3*$scale), [float]($y + 42*$scale)),
        [Drawing.PointF]::new([float]($x + 13*$scale), [float]($y + 33*$scale)),
        [Drawing.PointF]::new([float]($x + 22*$scale), [float]($y + 50*$scale)),
        [Drawing.PointF]::new([float]($x + 31*$scale), [float]($y + 45*$scale)),
        [Drawing.PointF]::new([float]($x + 22*$scale), [float]($y + 29*$scale)),
        [Drawing.PointF]::new([float]($x + 38*$scale), [float]($y + 27*$scale))
    )
    $shadow = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(180, 5, 25, 48)), ([float](6*$scale))
    $outline = New-Object Drawing.Pen ([Drawing.Color]::White), ([float](3*$scale))
    $fill = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(45, 174, 244))
    $highlight = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(190, 225, 250, 255)), ([float](1.5*$scale))
    try {
        $graphics.FillPolygon($fill, $points)
        $graphics.DrawPolygon($shadow, $points)
        $graphics.DrawPolygon($outline, $points)
        $graphics.DrawLine($highlight, [float]($x+6*$scale), [float]($y+8*$scale), [float]($x+9*$scale), [float]($y+31*$scale))
    } finally { $highlight.Dispose(); $fill.Dispose(); $outline.Dispose(); $shadow.Dispose() }
}

function Draw-PointerSet([Drawing.Graphics]$graphics, [int]$originX, [int]$originY, [Drawing.Color]$textColor) {
    $labels = @("Normal", "Ayuda", "Trabajando", "Precisión", "Texto", "No disponible")
    $font = New-Font 10
    $labelBrush = New-Object Drawing.SolidBrush $textColor
    $cyanPen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(45,174,244)), 5
    $whitePen = New-Object Drawing.Pen ([Drawing.Color]::White), 2
    $orangePen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(238,145,65)), 5
    try {
        for ($i=0; $i -lt 6; $i++) {
            $x = $originX + $i*100
            if ($i -eq 0) { Draw-Arrow $graphics ($x+25) $originY 1.0 }
            elseif ($i -eq 1) {
                Draw-Arrow $graphics ($x+18) $originY 0.85
                $graphics.DrawEllipse($whitePen, $x+48, $originY+31, 24, 24)
                $graphics.DrawEllipse($cyanPen, $x+48, $originY+31, 24, 24)
                $question = New-Font 13 ([Drawing.FontStyle]::Bold)
                try { $graphics.DrawString("?", $question, $labelBrush, $x+55, $originY+31) } finally { $question.Dispose() }
            }
            elseif ($i -eq 2) {
                Draw-Arrow $graphics ($x+12) $originY 0.78
                $graphics.DrawArc($cyanPen, $x+43, $originY+25, 31, 31, -75, 190)
                $graphics.DrawArc($orangePen, $x+43, $originY+25, 31, 31, 125, 120)
            }
            elseif ($i -eq 3) {
                $graphics.DrawEllipse($whitePen, $x+27, $originY+13, 40, 40)
                $graphics.DrawEllipse($cyanPen, $x+27, $originY+13, 40, 40)
                $graphics.DrawLine($whitePen, $x+47, $originY+2, $x+47, $originY+63)
                $graphics.DrawLine($whitePen, $x+16, $originY+33, $x+78, $originY+33)
            }
            elseif ($i -eq 4) {
                $graphics.DrawLine($cyanPen, $x+47, $originY+4, $x+47, $originY+61)
                $graphics.DrawLine($whitePen, $x+33, $originY+4, $x+61, $originY+4)
                $graphics.DrawLine($whitePen, $x+33, $originY+61, $x+61, $originY+61)
            }
            else {
                $graphics.DrawEllipse($whitePen, $x+23, $originY+9, 48, 48)
                $graphics.DrawEllipse($cyanPen, $x+23, $originY+9, 48, 48)
                $graphics.DrawLine($orangePen, $x+31, $originY+50, $x+63, $originY+17)
            }
            $size = $graphics.MeasureString($labels[$i], $font)
            $graphics.DrawString($labels[$i], $font, $labelBrush, [float]($x+47-$size.Width/2), [float]($originY+70))
        }
    } finally { $orangePen.Dispose(); $whitePen.Dispose(); $cyanPen.Dispose(); $labelBrush.Dispose(); $font.Dispose() }
}

function Draw-IconPanel([Drawing.Graphics]$graphics, [int]$panelX, [Drawing.Color]$background, [Drawing.Color]$textColor, [string]$title) {
    $panelBrush = New-Object Drawing.SolidBrush $background
    $textBrush = New-Object Drawing.SolidBrush $textColor
    $titleFont = New-Font 20 ([Drawing.FontStyle]::Bold)
    $labelFont = New-Font 10
    try {
        $graphics.FillRectangle($panelBrush, $panelX, 78, 680, 830)
        $graphics.DrawString($title, $titleFont, $textBrush, $panelX+28, 96)
        $graphics.DrawString("Crystal Remix • prueba a 48 px y 32 px", $labelFont, $textBrush, $panelX+30, 133)
        for ($i=0; $i -lt $icons.Count; $i++) {
            $column = [int][Math]::Floor($i / 7.0)
            $row = $i % 7
            $x = $panelX + 30 + $column*325
            $y = 170 + $row*63
            $path = Join-Path $sourceRoot $icons[$i][0]
            $image = [Drawing.Image]::FromFile($path)
            try {
                $graphics.DrawImage($image, $x, $y, 48, 48)
                $graphics.DrawImage($image, $x+58, $y+8, 32, 32)
            } finally { $image.Dispose() }
            $graphics.DrawString($icons[$i][1], $labelFont, $textBrush, $x+102, $y+15)
        }
        $graphics.DrawString("Punteros Crystal Blue", $titleFont, $textBrush, $panelX+28, 625)
        $graphics.DrawString("Forma clásica, azul luminoso, contorno doble para cualquier fondo", $labelFont, $textBrush, $panelX+30, 661)
        Draw-PointerSet $graphics ($panelX+24) 703 $textColor
    } finally { $labelFont.Dispose(); $titleFont.Dispose(); $textBrush.Dispose(); $panelBrush.Dispose() }
}

$bitmap = New-Object Drawing.Bitmap 1400, 930, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.Clear([Drawing.Color]::FromArgb(15, 25, 38))
$headerFont = New-Font 23 ([Drawing.FontStyle]::Bold)
$headerBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::White)
$accentBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(45,174,244))
try {
    $graphics.DrawString("JANUS Silicon — propuesta Crystal", $headerFont, $headerBrush, 30, 20)
    $graphics.FillRectangle($accentBrush, 0, 70, 1400, 5)
    Draw-IconPanel $graphics 10 ([Drawing.Color]::FromArgb(246,248,251)) ([Drawing.Color]::FromArgb(20,38,58)) "Explorador claro"
    Draw-IconPanel $graphics 710 ([Drawing.Color]::FromArgb(25,30,37)) ([Drawing.Color]::FromArgb(238,244,250)) "Explorador oscuro"
    $bitmap.Save($output, [Drawing.Imaging.ImageFormat]::Png)
} finally {
    $accentBrush.Dispose(); $headerBrush.Dispose(); $headerFont.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}

Write-Host "Propuesta creada: $output"
