param([string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root = (Resolve-Path $RepositoryRoot).Path
$iconRoot = Join-Path $root "assets\windows-themes\retro\Icons"
$output = Join-Path $root "dist\retro-icons-refined-preview.png"
$names = @(
    "este-equipo", "archivos-usuario", "documentos", "descargas", "escritorio", "imagenes", "musica",
    "videos", "red", "hdd-ssd", "usb", "unidad-red", "papelera-vacia", "papelera-llena"
)

$canvas = New-Object Drawing.Bitmap 1280,560
$graphics = [Drawing.Graphics]::FromImage($canvas)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.Clear([Drawing.Color]::FromArgb(242,245,248))
$titleFont = New-Object Drawing.Font "Segoe UI",22,([Drawing.FontStyle]::Bold)
$labelFont = New-Object Drawing.Font "Segoe UI",11
$titleBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(34,45,57))
$labelBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(58,67,77))
$cardBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::White)
$cardPen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(215,221,227)),1

try {
    $graphics.DrawString("JANUS Retro - propuesta refinada",$titleFont,$titleBrush,34,20)
    for ($index=0; $index -lt $names.Count; $index++) {
        $column = $index % 7
        $row = [Math]::Floor($index / 7)
        $x = 28 + ($column * 177)
        $y = 78 + ($row * 226)
        $graphics.FillRectangle($cardBrush,$x,$y,160,205)
        $graphics.DrawRectangle($cardPen,$x,$y,160,205)
        $image = [Drawing.Image]::FromFile((Join-Path $iconRoot ($names[$index]+".png")))
        try { $graphics.DrawImage($image,$x+26,$y+15,108,108) } finally { $image.Dispose() }
        $label = ($names[$index] -replace "-"," ")
        $format = New-Object Drawing.StringFormat
        try {
            $format.Alignment = [Drawing.StringAlignment]::Center
            $format.LineAlignment = [Drawing.StringAlignment]::Center
            $graphics.DrawString($label,$labelFont,$labelBrush,[Drawing.RectangleF]::new($x+8,$y+135,144,48),$format)
        } finally { $format.Dispose() }
    }
    $canvas.Save($output,[Drawing.Imaging.ImageFormat]::Png)
} finally {
    $cardPen.Dispose(); $cardBrush.Dispose(); $labelBrush.Dispose(); $titleBrush.Dispose()
    $labelFont.Dispose(); $titleFont.Dispose(); $graphics.Dispose(); $canvas.Dispose()
}

Write-Output $output
