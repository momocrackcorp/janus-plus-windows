param([string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = (Resolve-Path $RepositoryRoot).Path
$themeRoot = Join-Path $repo "assets\windows-themes\silicon"
$sourceRoot = Join-Path $themeRoot "Concepts\CrystalSource\crystal-remix-icon-theme-2.8"
$source128 = Join-Path $sourceRoot "128x128"
$iconDir = Join-Path $themeRoot "Icons"
$previewDir = Join-Path $themeRoot "Preview"
$dist = Join-Path $repo "dist\themes"
foreach($directory in @($iconDir,$previewDir,$dist)){New-Item -ItemType Directory -Force -Path $directory|Out-Null}
Get-ChildItem -LiteralPath $iconDir -File -ErrorAction SilentlyContinue|Remove-Item -Force

$mapping = [ordered]@{
    "este-equipo"="devices\computer.png";"archivos-usuario"="places\user-home.png";"red"="places\network-workgroup.png";"papelera-vacia"="places\user-trash.png";"papelera-llena"="places\user-trash-full.png";"documentos"="places\folder-documents.png";"descargas"="places\folder-download.png";"escritorio"="places\user-desktop.png";"imagenes"="places\folder-pictures.png";"musica"="places\folder-music.png";"videos"="places\folder-videos.png";"hdd-ssd"="devices\drive-harddisk.png";"usb"="devices\drive-removable-media-usb-pendrive.png";"unidad-red"="places\network-server.png"
}
$labels = [ordered]@{
    "este-equipo"="Este equipo";"archivos-usuario"="Archivos del usuario";"red"="Red";"papelera-vacia"="Papelera vacía";"papelera-llena"="Papelera llena";"documentos"="Documentos";"descargas"="Descargas";"escritorio"="Escritorio";"imagenes"="Imágenes";"musica"="Música";"videos"="Vídeos";"hdd-ssd"="HDD / SSD";"usb"="USB";"unidad-red"="Unidad de red"
}

function Resize-Image([Drawing.Image]$source,[int]$size){
    $target=New-Object Drawing.Bitmap $size,$size,([Drawing.Imaging.PixelFormat]::Format32bppArgb);$graphics=[Drawing.Graphics]::FromImage($target)
    try{$graphics.Clear([Drawing.Color]::Transparent);$graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality;$graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$graphics.DrawImage($source,0,0,$size,$size)}finally{$graphics.Dispose()};return $target
}

function Save-IconSet([string]$sourcePath,[string]$baseName){
    if(!(Test-Path -LiteralPath $sourcePath)){throw "Falta el icono Crystal Remix: $sourcePath"};$source=[Drawing.Image]::FromFile($sourcePath)
    try{$large=Resize-Image $source 256;try{$large.Save((Join-Path $iconDir ($baseName+".png")),[Drawing.Imaging.ImageFormat]::Png)}finally{$large.Dispose()};$sizes=@(16,24,32,48,64,128,256);$images=@();foreach($size in $sizes){$image=Resize-Image $source $size;$stream=New-Object IO.MemoryStream;try{$image.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$images+=,$stream.ToArray()}finally{$stream.Dispose();$image.Dispose()}};$output=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $output;try{$writer.Write([UInt16]0);$writer.Write([UInt16]1);$writer.Write([UInt16]$images.Count);$offset=6+16*$images.Count;for($i=0;$i -lt $images.Count;$i++){$size=$sizes[$i];$writer.Write([byte]$(if($size -eq 256){0}else{$size}));$writer.Write([byte]$(if($size -eq 256){0}else{$size}));$writer.Write([byte]0);$writer.Write([byte]0);$writer.Write([UInt16]1);$writer.Write([UInt16]32);$writer.Write([UInt32]$images[$i].Length);$writer.Write([UInt32]$offset);$offset+=$images[$i].Length};foreach($bytes in $images){$writer.Write($bytes)};$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $iconDir ($baseName+".ico")),$output.ToArray())}finally{$writer.Dispose();$output.Dispose()}}finally{$source.Dispose()}
}

function New-ExplorerPreview{
    $canvas=New-Object Drawing.Bitmap 1400,860,([Drawing.Imaging.PixelFormat]::Format32bppArgb);$graphics=[Drawing.Graphics]::FromImage($canvas);$titleFont=New-Object Drawing.Font "Segoe UI",22,([Drawing.FontStyle]::Bold);$itemFont=New-Object Drawing.Font "Segoe UI",12;$smallFont=New-Object Drawing.Font "Segoe UI",10;$lightBackground=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(247,248,250));$darkBackground=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(24,28,34));$lightText=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(238,242,245));$darkText=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(28,35,42));$subtle=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(104,116,126))
    try{$graphics.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias;$graphics.FillRectangle($lightBackground,0,0,700,860);$graphics.FillRectangle($darkBackground,700,0,700,860);$graphics.DrawString("Explorador claro",$titleFont,$darkText,32,25);$graphics.DrawString("Explorador oscuro",$titleFont,$lightText,732,25);$graphics.DrawString("Crystal Remix a 32 px y 48 px",$smallFont,$subtle,35,65);$graphics.DrawString("Crystal Remix a 32 px y 48 px",$smallFont,$subtle,735,65);$index=0;foreach($entry in $labels.GetEnumerator()){$column=[int][Math]::Floor($index/7.0);$row=$index%7;$x=35+$column*330;$y=102+$row*102;$image=[Drawing.Image]::FromFile((Join-Path $iconDir ($entry.Key+".png")));try{$graphics.DrawImage($image,$x,$y+8,48,48);$graphics.DrawImage($image,$x+55,$y+16,32,32);$graphics.DrawString($entry.Value,$itemFont,$darkText,$x+100,$y+19);$graphics.DrawImage($image,$x+700,$y+8,48,48);$graphics.DrawImage($image,$x+755,$y+16,32,32);$graphics.DrawString($entry.Value,$itemFont,$lightText,$x+800,$y+19)}finally{$image.Dispose()};$index++};$path=Join-Path $previewDir "JANUS-Silicon-Iconos-Explorer-preview.png";$canvas.Save($path,[Drawing.Imaging.ImageFormat]::Png);return $path}finally{foreach($item in @($subtle,$darkText,$lightText,$darkBackground,$lightBackground,$smallFont,$itemFont,$titleFont,$graphics,$canvas)){$item.Dispose()}}
}

foreach($entry in $mapping.GetEnumerator()){Save-IconSet (Join-Path $source128 $entry.Value) $entry.Key}
Set-Content -LiteralPath (Join-Path $iconDir "TEMA.txt") -Value "silicon" -Encoding UTF8
$attribution=@'
JANUS Silicon — complemento de iconos Crystal Remix

Iconos: Crystal Remix icon theme, basado en Crystal Project y Crystal Clear de Everaldo Coelho.
Adaptación para escritorios modernos: Viet Dang (Đặng Việt Dũng).
Proyecto fuente: https://github.com/dangvd/crystal-remix-icon-theme
Licencia declarada por el proyecto: GNU Lesser General Public License (LGPL).

JANUS únicamente selecciona, renombra y convierte los iconos necesarios a PNG/ICO para Windows; no reclama autoría sobre los diseños Crystal Remix.
'@
Set-Content -LiteralPath (Join-Path $iconDir "ATRIBUCION.txt") -Value $attribution -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $sourceRoot "README.md") -Destination (Join-Path $iconDir "CRYSTAL-REMIX-README.md") -Force
$preview=New-ExplorerPreview
$iconsZip=Join-Path $dist "Tema-Iconos-Silicon.zip";Remove-Item -LiteralPath $iconsZip -Force -ErrorAction SilentlyContinue;Compress-Archive -Path (Join-Path $iconDir "*") -DestinationPath $iconsZip -CompressionLevel Optimal
Get-FileHash $iconsZip -Algorithm SHA256|Select-Object Path,Hash
Write-Host "Vista previa: $preview"
