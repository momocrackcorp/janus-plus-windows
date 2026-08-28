param([string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = (Resolve-Path $RepositoryRoot).Path
$themeRoot = Join-Path $repo "assets\windows-themes\retro"
$sourceDir = Join-Path $themeRoot "Sources"
$wallpaperDir = Join-Path $themeRoot "DesktopBackground"
$previewDir = Join-Path $themeRoot "Preview"
$cursorDir = Join-Path $themeRoot "Cursors"
$cursorSourceDir = Join-Path $themeRoot "CursorSource"
$soundDir = Join-Path $themeRoot "Sounds"
$soundSourceDir = Join-Path $themeRoot "SoundSource"
$iconDir = Join-Path $themeRoot "Icons"
$watermarkPath = Join-Path $sourceDir "JANUS-Retro-watermark.png"
$dist = Join-Path $repo "dist\themes"
foreach ($directory in @($themeRoot,$sourceDir,$wallpaperDir,$previewDir,$cursorDir,$cursorSourceDir,$soundDir,$soundSourceDir,$iconDir,$dist)) { New-Item -ItemType Directory -Force -Path $directory | Out-Null }
foreach ($directory in @($wallpaperDir,$previewDir,$cursorDir,$soundDir,$iconDir)) { Get-ChildItem -LiteralPath $directory -File -ErrorAction SilentlyContinue | Remove-Item -Force }

$classicBlue = [Drawing.Color]::FromArgb(0,84,227)
$skyBlue = [Drawing.Color]::FromArgb(80,166,255)
$grassGreen = [Drawing.Color]::FromArgb(69,139,42)
$amber = [Drawing.Color]::FromArgb(242,154,46)
$windowGray = [Drawing.Color]::FromArgb(212,208,200)
$white = [Drawing.Color]::White
$black = [Drawing.Color]::FromArgb(18,25,31)

function New-Canvas {
    $bitmap = New-Object Drawing.Bitmap 64,64
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::None
    $graphics.Clear([Drawing.Color]::Transparent)
    return @($bitmap,$graphics)
}

function Add-RetroArrow([Drawing.Graphics]$graphics,[double]$scale=1.0) {
    $points = [Drawing.PointF[]]@(
        [Drawing.PointF]::new([float](6*$scale),[float](4*$scale)),[Drawing.PointF]::new([float](8*$scale),[float](49*$scale)),
        [Drawing.PointF]::new([float](19*$scale),[float](38*$scale)),[Drawing.PointF]::new([float](29*$scale),[float](59*$scale)),
        [Drawing.PointF]::new([float](39*$scale),[float](54*$scale)),[Drawing.PointF]::new([float](29*$scale),[float](34*$scale)),
        [Drawing.PointF]::new([float](47*$scale),[float](31*$scale)))
    $outline = New-Object Drawing.Pen $black,4
    $highlight = New-Object Drawing.Pen $skyBlue,2
    $fill = New-Object Drawing.SolidBrush $white
    $graphics.FillPolygon($fill,$points); $graphics.DrawPolygon($outline,$points)
    $graphics.DrawLine($highlight,[float](10*$scale),[float](11*$scale),[float](11*$scale),[float](40*$scale))
    $fill.Dispose(); $highlight.Dispose(); $outline.Dispose()
}

function Convert-ToCursorBytes([Drawing.Bitmap]$bitmap,[int]$hotX,[int]$hotY) {
    $pngStream=New-Object IO.MemoryStream; $bitmap.Save($pngStream,[Drawing.Imaging.ImageFormat]::Png); $png=$pngStream.ToArray(); $pngStream.Dispose()
    $stream=New-Object IO.MemoryStream; $writer=New-Object IO.BinaryWriter $stream
    $writer.Write([UInt16]0);$writer.Write([UInt16]2);$writer.Write([UInt16]1);$writer.Write([byte]64);$writer.Write([byte]64);$writer.Write([byte]0);$writer.Write([byte]0)
    $writer.Write([UInt16]$hotX);$writer.Write([UInt16]$hotY);$writer.Write([UInt32]$png.Length);$writer.Write([UInt32]22);$writer.Write($png);$writer.Flush()
    $bytes=$stream.ToArray();$writer.Dispose();$stream.Dispose();return ,$bytes
}

function New-RetroCursor([string]$name,[string]$kind,[int]$hotX,[int]$hotY) {
    $canvas=New-Canvas;$bitmap=$canvas[0];$graphics=$canvas[1]
    $darkPen=New-Object Drawing.Pen $black,4;$bluePen=New-Object Drawing.Pen $classicBlue,4;$whitePen=New-Object Drawing.Pen $white,2
    $blueBrush=New-Object Drawing.SolidBrush $classicBlue;$greenBrush=New-Object Drawing.SolidBrush $grassGreen;$amberBrush=New-Object Drawing.SolidBrush $amber;$whiteBrush=New-Object Drawing.SolidBrush $white
    switch($kind) {
        "arrow" { Add-RetroArrow $graphics }
        "help" { Add-RetroArrow $graphics;$graphics.FillRectangle($blueBrush,36,35,24,23);$graphics.DrawRectangle($darkPen,36,35,24,23);$font=New-Object Drawing.Font "Tahoma",13,([Drawing.FontStyle]::Bold);$graphics.DrawString("?",$font,$whiteBrush,42,35);$font.Dispose() }
        "hand" { $graphics.FillRectangle($whiteBrush,17,8,19,42);$graphics.FillRectangle($whiteBrush,10,25,39,23);$graphics.DrawRectangle($darkPen,17,8,19,42);$graphics.DrawRectangle($darkPen,10,25,39,23);$graphics.DrawLine($bluePen,22,15,22,39) }
        "ibeam" { $graphics.DrawLine($darkPen,20,8,44,8);$graphics.DrawLine($darkPen,32,8,32,56);$graphics.DrawLine($darkPen,20,56,44,56);$graphics.DrawLine($bluePen,28,32,36,32) }
        "cross" { $graphics.DrawLine($darkPen,32,4,32,60);$graphics.DrawLine($darkPen,4,32,60,32);$graphics.FillRectangle($greenBrush,28,28,8,8) }
        "move" { $graphics.DrawLine($darkPen,32,8,32,56);$graphics.DrawLine($darkPen,8,32,56,32);$graphics.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(22,16),[Drawing.Point]::new(42,16)));$graphics.FillPolygon($greenBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(22,48),[Drawing.Point]::new(42,48)));$graphics.FillPolygon($amberBrush,[Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(16,22),[Drawing.Point]::new(16,42)));$graphics.FillPolygon($amberBrush,[Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(48,22),[Drawing.Point]::new(48,42))) }
        "ns" { $graphics.DrawLine($darkPen,32,9,32,55);$graphics.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(21,17),[Drawing.Point]::new(43,17)));$graphics.FillPolygon($greenBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(21,47),[Drawing.Point]::new(43,47))) }
        "we" { $graphics.DrawLine($darkPen,9,32,55,32);$graphics.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(17,21),[Drawing.Point]::new(17,43)));$graphics.FillPolygon($greenBrush,[Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(47,21),[Drawing.Point]::new(47,43))) }
        "nwse" { $graphics.DrawLine($darkPen,11,11,53,53);$graphics.DrawLine($whitePen,14,14,50,50);$graphics.FillRectangle($blueBrush,5,5,14,14);$graphics.FillRectangle($greenBrush,45,45,14,14) }
        "nesw" { $graphics.DrawLine($darkPen,53,11,11,53);$graphics.DrawLine($whitePen,50,14,14,50);$graphics.FillRectangle($blueBrush,45,5,14,14);$graphics.FillRectangle($greenBrush,5,45,14,14) }
        "up" { $graphics.DrawLine($darkPen,32,14,32,58);$graphics.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(17,21),[Drawing.Point]::new(47,21))) }
        "no" { Add-RetroArrow $graphics 0.72;$graphics.DrawEllipse($darkPen,26,26,32,32);$graphics.DrawEllipse($bluePen,29,29,26,26);$graphics.DrawLine($bluePen,33,33,51,51) }
        "pen" { $graphics.DrawLine($darkPen,10,54,49,15);$graphics.DrawLine($bluePen,13,51,47,17);$graphics.FillPolygon($amberBrush,[Drawing.Point[]]@([Drawing.Point]::new(49,9),[Drawing.Point]::new(56,16),[Drawing.Point]::new(48,23),[Drawing.Point]::new(41,16))) }
    }
    [IO.File]::WriteAllBytes((Join-Path $cursorDir $name),(Convert-ToCursorBytes $bitmap $hotX $hotY))
    foreach($item in @($whiteBrush,$amberBrush,$greenBrush,$blueBrush,$whitePen,$bluePen,$darkPen,$graphics,$bitmap)){$item.Dispose()}
}

function Add-RetroSpinner([Drawing.Graphics]$graphics,[int]$cx,[int]$cy,[int]$frame) {
    for($i=0;$i -lt 8;$i++){$angle=($i*45-90)*[Math]::PI/180;$x=[int]($cx+15*[Math]::Cos($angle));$y=[int]($cy+15*[Math]::Sin($angle));$brush=New-Object Drawing.SolidBrush $(if($i -eq $frame){$amber}elseif($i%2){$classicBlue}else{$grassGreen});$size=if($i -eq $frame){9}else{6};$graphics.FillRectangle($brush,$x-[int]($size/2),$y-[int]($size/2),$size,$size);$brush.Dispose()}
}

function New-RetroAni([string]$name,[bool]$withArrow) {
    $frames=@();for($frame=0;$frame -lt 8;$frame++){$canvas=New-Canvas;$bitmap=$canvas[0];$graphics=$canvas[1];if($withArrow){Add-RetroArrow $graphics 0.70;Add-RetroSpinner $graphics 47 45 $frame}else{Add-RetroSpinner $graphics 32 32 $frame};$frames+=,(Convert-ToCursorBytes $bitmap $(if($withArrow){5}else{32}) $(if($withArrow){4}else{32}));$graphics.Dispose();$bitmap.Dispose()}
    $stream=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $stream;$writer.Write([Text.Encoding]::ASCII.GetBytes("RIFF"));$writer.Write([UInt32]0);$writer.Write([Text.Encoding]::ASCII.GetBytes("ACON"));$writer.Write([Text.Encoding]::ASCII.GetBytes("anih"));$writer.Write([UInt32]36);foreach($value in @([UInt32]36,[UInt32]8,[UInt32]8,[UInt32]64,[UInt32]64,[UInt32]32,[UInt32]1,[UInt32]6,[UInt32]3)){$writer.Write($value)};$writer.Write([Text.Encoding]::ASCII.GetBytes("rate"));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]6)};$writer.Write([Text.Encoding]::ASCII.GetBytes("seq "));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]$_)}
    $listStream=New-Object IO.MemoryStream;$listWriter=New-Object IO.BinaryWriter $listStream;$listWriter.Write([Text.Encoding]::ASCII.GetBytes("fram"));foreach($cursor in $frames){$listWriter.Write([Text.Encoding]::ASCII.GetBytes("icon"));$listWriter.Write([UInt32]$cursor.Length);$listWriter.Write($cursor);if($cursor.Length%2){$listWriter.Write([byte]0)}};$listWriter.Flush();$list=$listStream.ToArray();$listWriter.Dispose();$listStream.Dispose();$writer.Write([Text.Encoding]::ASCII.GetBytes("LIST"));$writer.Write([UInt32]$list.Length);$writer.Write($list);if($list.Length%2){$writer.Write([byte]0)};$writer.Flush();$length=$stream.Length;$stream.Position=4;$writer.Write([UInt32]($length-8));$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $cursorDir $name),$stream.ToArray());$writer.Dispose();$stream.Dispose()
}

function Save-Jpeg([Drawing.Image]$image,[string]$path,[long]$quality=93) {$codec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where-Object{$_.MimeType -eq 'image/jpeg'}|Select-Object -First 1;$parameters=New-Object Drawing.Imaging.EncoderParameters 1;$parameters.Param[0]=New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality),$quality;try{$image.Save($path,$codec,$parameters)}finally{$parameters.Param[0].Dispose();$parameters.Dispose()}}

function New-JanusWatermark {
    $splashPath=Join-Path $repo "assets\janus-splash.png";$splash=[Drawing.Image]::FromFile($splashPath)
    try{$crop=[Drawing.Rectangle]::new(55,5,[Math]::Min(1146,$splash.Width-55),[Math]::Min(1060,$splash.Height-5));$mark=New-Object Drawing.Bitmap $crop.Width,$crop.Height,([Drawing.Imaging.PixelFormat]::Format32bppArgb);try{$g=[Drawing.Graphics]::FromImage($mark);try{$g.Clear([Drawing.Color]::White);$g.DrawImage($splash,[Drawing.Rectangle]::new(0,0,$crop.Width,$crop.Height),$crop,[Drawing.GraphicsUnit]::Pixel)}finally{$g.Dispose()};for($y=0;$y -lt $mark.Height;$y++){for($x=0;$x -lt $mark.Width;$x++){$pixel=$mark.GetPixel($x,$y);$minimum=[Math]::Min($pixel.R,[Math]::Min($pixel.G,$pixel.B));$maximum=[Math]::Max($pixel.R,[Math]::Max($pixel.G,$pixel.B));if($minimum -ge 225 -and ($maximum-$minimum) -le 20){$mark.SetPixel($x,$y,[Drawing.Color]::FromArgb(0,$pixel.R,$pixel.G,$pixel.B))}}};$mark.Save($watermarkPath,[Drawing.Imaging.ImageFormat]::Png)}finally{$mark.Dispose()}}finally{$splash.Dispose()}
}

function Add-JanusWatermark([Drawing.Graphics]$graphics,[int]$width,[int]$height) {
    $mark=[Drawing.Image]::FromFile($watermarkPath);try{$markWidth=[int]($width*0.12);$markHeight=[int]($markWidth*$mark.Height/[double]$mark.Width);$right=[int]($width*0.022);$bottom=[int]($height*0.04);$destination=[Drawing.Rectangle]::new($width-$markWidth-$right,$height-$markHeight-$bottom,$markWidth,$markHeight);$attributes=New-Object Drawing.Imaging.ImageAttributes;try{$matrix=New-Object Drawing.Imaging.ColorMatrix;$matrix.Matrix33=0.25;$attributes.SetColorMatrix($matrix,[Drawing.Imaging.ColorMatrixFlag]::Default,[Drawing.Imaging.ColorAdjustType]::Bitmap);$graphics.DrawImage($mark,$destination,0,0,$mark.Width,$mark.Height,[Drawing.GraphicsUnit]::Pixel,$attributes)}finally{$attributes.Dispose()}}finally{$mark.Dispose()}
}

function New-CoverImage([string]$sourcePath,[int]$width,[int]$height,[string]$destination,[bool]$watermarked=$false) {
    $source=[Drawing.Image]::FromFile($sourcePath);try{$targetRatio=$width/[double]$height;$sourceRatio=$source.Width/[double]$source.Height;if($sourceRatio -gt $targetRatio){$cropHeight=$source.Height;$cropWidth=[int]($cropHeight*$targetRatio);$cropX=[int](($source.Width-$cropWidth)/2);$cropY=0}else{$cropWidth=$source.Width;$cropHeight=[int]($cropWidth/$targetRatio);$cropX=0;$cropY=[int](($source.Height-$cropHeight)/2)};$target=New-Object Drawing.Bitmap $width,$height;try{$graphics=[Drawing.Graphics]::FromImage($target);try{$graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality;$graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,$width,$height),[Drawing.Rectangle]::new($cropX,$cropY,$cropWidth,$cropHeight),[Drawing.GraphicsUnit]::Pixel);if($watermarked){Add-JanusWatermark $graphics $width $height}}finally{$graphics.Dispose()};if([IO.Path]::GetExtension($destination) -eq ".png"){$target.Save($destination,[Drawing.Imaging.ImageFormat]::Png)}else{Save-Jpeg $target $destination}}finally{$target.Dispose()}}finally{$source.Dispose()}
}

function New-RetroIcon([string]$baseName) {
    $large=New-Object Drawing.Bitmap 256,256;$g=[Drawing.Graphics]::FromImage($large);$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias;$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$g.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality;$g.Clear([Drawing.Color]::Transparent)
    # Retro conserva la silueta reconocible de 3.11/XP, pero evita el aspecto de
    # pixel art: contornos grafito finos, paleta menos saturada y sombras suaves.
    $dark=[Drawing.Color]::FromArgb(61,70,82);$beige=[Drawing.Color]::FromArgb(220,214,195);$beigeLight=[Drawing.Color]::FromArgb(249,246,233);$yellow=[Drawing.Color]::FromArgb(232,172,45);$yellowLight=[Drawing.Color]::FromArgb(255,218,92);$blue=[Drawing.Color]::FromArgb(48,132,201);$blueLight=[Drawing.Color]::FromArgb(124,199,235);$silver=[Drawing.Color]::FromArgb(181,193,204);$silverLight=[Drawing.Color]::FromArgb(239,244,247);$green=[Drawing.Color]::FromArgb(72,164,104);$red=[Drawing.Color]::FromArgb(202,79,70)
    $outline=New-Object Drawing.Pen $dark,5;$outline.LineJoin=[Drawing.Drawing2D.LineJoin]::Round;$detail=New-Object Drawing.Pen $dark,3;$detail.LineJoin=[Drawing.Drawing2D.LineJoin]::Round;$highlight=New-Object Drawing.Pen ([Drawing.Color]::FromArgb(175,255,255,255)),3;$shadowBrush=New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(28,0,0,0));$darkBrush=New-Object Drawing.SolidBrush $dark;$beigeBrush=New-Object Drawing.SolidBrush $beige;$beigeLightBrush=New-Object Drawing.SolidBrush $beigeLight;$yellowBrush=New-Object Drawing.SolidBrush $yellow;$yellowLightBrush=New-Object Drawing.SolidBrush $yellowLight;$blueBrush=New-Object Drawing.SolidBrush $blue;$blueLightBrush=New-Object Drawing.SolidBrush $blueLight;$silverBrush=New-Object Drawing.SolidBrush $silver;$silverLightBrush=New-Object Drawing.SolidBrush $silverLight;$greenBrush=New-Object Drawing.SolidBrush $green;$redBrush=New-Object Drawing.SolidBrush $red;$whiteBrush=New-Object Drawing.SolidBrush ([Drawing.Color]::White)
    $drawFolder={param([string]$mark);$g.FillEllipse($shadowBrush,29,197,199,29);$g.FillPolygon($yellowLightBrush,[Drawing.Point[]]@([Drawing.Point]::new(27,75),[Drawing.Point]::new(94,75),[Drawing.Point]::new(113,96),[Drawing.Point]::new(224,96),[Drawing.Point]::new(224,202),[Drawing.Point]::new(27,202)));$g.DrawPolygon($outline,[Drawing.Point[]]@([Drawing.Point]::new(27,75),[Drawing.Point]::new(94,75),[Drawing.Point]::new(113,96),[Drawing.Point]::new(224,96),[Drawing.Point]::new(224,202),[Drawing.Point]::new(27,202)));$g.FillPolygon($yellowBrush,[Drawing.Point[]]@([Drawing.Point]::new(22,108),[Drawing.Point]::new(234,108),[Drawing.Point]::new(210,213),[Drawing.Point]::new(38,213)));$g.DrawPolygon($outline,[Drawing.Point[]]@([Drawing.Point]::new(22,108),[Drawing.Point]::new(234,108),[Drawing.Point]::new(210,213),[Drawing.Point]::new(38,213)));$g.DrawLine($highlight,39,124,214,124);if($mark -eq 'down'){$g.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(128,133),[Drawing.Point]::new(128,174),[Drawing.Point]::new(104,174),[Drawing.Point]::new(140,204),[Drawing.Point]::new(176,174),[Drawing.Point]::new(152,174),[Drawing.Point]::new(152,133)))}elseif($mark -eq 'music'){$font=[Drawing.Font]::new('Segoe UI Symbol',[single]54,[Drawing.FontStyle]::Bold,[Drawing.GraphicsUnit]::Pixel);$g.DrawString([char]0x266B,$font,$blueBrush,101,121);$font.Dispose()}elseif($mark -eq 'image'){$g.FillRectangle($whiteBrush,81,132,95,61);$g.DrawRectangle($detail,81,132,95,61);$g.FillEllipse($yellowBrush,145,141,15,15);$g.FillPolygon($greenBrush,[Drawing.Point[]]@([Drawing.Point]::new(88,185),[Drawing.Point]::new(114,154),[Drawing.Point]::new(133,174),[Drawing.Point]::new(148,160),[Drawing.Point]::new(171,185)))}elseif($mark -eq 'video'){$g.FillRectangle($darkBrush,84,134,88,57);for($x=89;$x -lt 170;$x+=19){$g.FillRectangle($beigeLightBrush,$x,140,11,8);$g.FillRectangle($beigeLightBrush,$x,177,11,8)}$g.FillPolygon($blueBrush,[Drawing.Point[]]@([Drawing.Point]::new(119,148),[Drawing.Point]::new(119,176),[Drawing.Point]::new(148,162)))}elseif($mark -eq 'desktop'){$g.FillRectangle($blueBrush,82,132,95,55);$g.DrawRectangle($detail,82,132,95,55);$g.FillRectangle($silverBrush,120,187,18,16);$g.FillRectangle($silverLightBrush,99,202,60,8)}}
    if($baseName -in @('archivos-usuario','documentos','descargas','escritorio','imagenes','musica','videos')){&$drawFolder $(switch($baseName){'descargas'{'down'}'escritorio'{'desktop'}'imagenes'{'image'}'musica'{'music'}'videos'{'video'}default{''}})}
    elseif($baseName -eq 'este-equipo'){$g.FillEllipse($shadowBrush,28,210,202,25);$g.FillRectangle($beigeBrush,28,49,144,129);$g.DrawRectangle($outline,28,49,144,129);$g.FillRectangle($blueBrush,44,65,112,83);$g.DrawRectangle($detail,44,65,112,83);$g.FillRectangle($beigeBrush,83,178,34,30);$g.FillRectangle($beigeLightBrush,60,205,80,12);$g.DrawRectangle($detail,60,205,80,12);$g.FillRectangle($beigeBrush,184,72,45,137);$g.DrawRectangle($outline,184,72,45,137);$g.FillEllipse($greenBrush,199,184,10,10);$g.DrawLine($highlight,194,90,218,90)}
    elseif($baseName -in @('red','unidad-red')){foreach($x in @(29,143)){$g.FillRectangle($beigeBrush,$x,66,83,78);$g.DrawRectangle($outline,$x,66,83,78);$g.FillRectangle($blueBrush,$x+12,78,59,42);$g.FillRectangle($beigeBrush,$x+29,144,25,24);$g.FillRectangle($silverBrush,$x+12,168,59,10)}$g.DrawArc($detail,72,163,113,61,0,180);$g.FillEllipse($greenBrush,120,184,17,17);if($baseName -eq 'unidad-red'){$g.FillRectangle($silverBrush,70,192,116,34);$g.DrawRectangle($outline,70,192,116,34)}}
    elseif($baseName -in @('papelera-vacia','papelera-llena')){$g.FillEllipse($shadowBrush,45,213,166,23);$body=[Drawing.Point[]]@([Drawing.Point]::new(65,76),[Drawing.Point]::new(193,76),[Drawing.Point]::new(179,216),[Drawing.Point]::new(79,216));$g.FillPolygon($silverLightBrush,$body);$g.DrawPolygon($outline,$body);$g.FillRectangle($silverBrush,55,57,148,28);$g.DrawRectangle($outline,55,57,148,28);foreach($x in @(96,128,160)){$g.DrawLine($detail,$x,94,$x-5,195)};if($baseName -eq 'papelera-llena'){$g.FillRectangle($blueBrush,88,93,28,43);$g.FillEllipse($yellowBrush,133,101,39,35);$g.FillPolygon($greenBrush,[Drawing.Point[]]@([Drawing.Point]::new(105,151),[Drawing.Point]::new(150,137),[Drawing.Point]::new(165,177),[Drawing.Point]::new(116,184)))}}
    elseif($baseName -eq 'hdd-ssd'){$g.FillEllipse($shadowBrush,30,205,196,28);$g.FillRectangle($silverBrush,33,55,190,153);$g.DrawRectangle($outline,33,55,190,153);$g.FillEllipse($silverLightBrush,66,76,124,103);$g.DrawEllipse($detail,66,76,124,103);$g.FillEllipse($darkBrush,113,113,30,30);$g.FillEllipse($greenBrush,185,177,14,14);$g.DrawLine($highlight,49,71,205,71)}
    elseif($baseName -eq 'usb'){$g.FillRectangle($blueBrush,83,65,90,145);$g.DrawRectangle($outline,83,65,90,145);$g.FillRectangle($silverLightBrush,100,29,56,46);$g.DrawRectangle($detail,100,29,56,46);$g.FillRectangle($darkBrush,108,39,13,23);$g.FillRectangle($darkBrush,136,39,13,23);$g.FillEllipse($blueLightBrush,110,119,36,36);$g.DrawLine($highlight,96,87,160,87)}
    else{&$drawFolder ''}
    $large.Save((Join-Path $iconDir ($baseName+".png")),[Drawing.Imaging.ImageFormat]::Png)
    foreach($item in @($whiteBrush,$redBrush,$greenBrush,$silverLightBrush,$silverBrush,$blueLightBrush,$blueBrush,$yellowLightBrush,$yellowBrush,$beigeLightBrush,$beigeBrush,$darkBrush,$shadowBrush,$highlight,$detail,$outline,$g)){$item.Dispose()}
    $sizes=@(16,24,32,48,64,128,256);$images=@();foreach($size in $sizes){$image=New-Object Drawing.Bitmap $size,$size;$g=[Drawing.Graphics]::FromImage($image);$g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias;$g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$g.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$g.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality;$pixel=[Drawing.Image]::FromFile((Join-Path $iconDir ($baseName+".png")));$g.DrawImage($pixel,0,0,$size,$size);$pixel.Dispose();$g.Dispose();$stream=New-Object IO.MemoryStream;$image.Save($stream,[Drawing.Imaging.ImageFormat]::Png);$image.Dispose();$images+=,$stream.ToArray();$stream.Dispose()}
    $output=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $output;$writer.Write([UInt16]0);$writer.Write([UInt16]1);$writer.Write([UInt16]$images.Count);$offset=6+16*$images.Count;for($i=0;$i -lt $images.Count;$i++){$size=$sizes[$i];$writer.Write([byte]$(if($size -eq 256){0}else{$size}));$writer.Write([byte]$(if($size -eq 256){0}else{$size}));$writer.Write([byte]0);$writer.Write([byte]0);$writer.Write([UInt16]1);$writer.Write([UInt16]32);$writer.Write([UInt32]$images[$i].Length);$writer.Write([UInt32]$offset);$offset+=$images[$i].Length};foreach($bytes in $images){$writer.Write($bytes)};$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $iconDir ($baseName+".ico")),$output.ToArray());$writer.Dispose();$output.Dispose();$large.Dispose()
}

$wallpapers=@(@("Pradera","JANUS-Retro-Pradera-source.png"),@("Nubes","JANUS-Retro-Nubes-source.png"),@("Bosque","JANUS-Retro-Bosque-source.png"),@("Puma","JANUS-Retro-Puma-source.png"),@("Mosaico98","JANUS-Retro-Mosaico98-source.png"))
New-JanusWatermark
foreach($wallpaper in $wallpapers){$source=Join-Path $sourceDir $wallpaper[1];if(!(Test-Path -LiteralPath $source)){throw "Falta la fuente $($wallpaper[1])"};$watermarked=$wallpaper[0] -in @("Nubes","Bosque");New-CoverImage $source 3840 2160 (Join-Path $wallpaperDir ("JANUS-Retro-"+$wallpaper[0]+"-4K.jpg")) $watermarked;New-CoverImage $source 5120 2160 (Join-Path $wallpaperDir ("JANUS-Retro-"+$wallpaper[0]+"-Ultrawide-5K.jpg")) $watermarked;if($wallpaper[0] -in @("Pradera","Puma","Mosaico98")){New-CoverImage $source 960 540 (Join-Path $previewDir ("JANUS-Retro-"+$wallpaper[0]+"-preview.png"))}}

$approvedCursors=Get-ChildItem -LiteralPath $cursorSourceDir -File | Where-Object{$_.Extension -in @('.cur','.ani')}
if($approvedCursors.Count -ne 15){throw "El juego aprobado de cursores Retro debe contener exactamente 15 archivos."}
$approvedCursors|Copy-Item -Destination $cursorDir -Force

$approvedSounds=Get-ChildItem -LiteralPath $soundSourceDir -File -Filter 'retro-*.wav'
if($approvedSounds.Count -ne 9){throw "El juego público de sonidos Retro debe contener exactamente 9 archivos WAV."}
$approvedSounds|Copy-Item -Destination $soundDir -Force

foreach($baseName in @("este-equipo","archivos-usuario","red","papelera-vacia","papelera-llena","documentos","descargas","escritorio","imagenes","musica","videos","hdd-ssd","usb","unidad-red")){New-RetroIcon $baseName}
Set-Content -LiteralPath (Join-Path $iconDir "TEMA.txt") -Value "retro" -Encoding UTF8
Set-Content -LiteralPath (Join-Path $iconDir "ATRIBUCION.txt") -Value "Diseño original JANUS inspirado en la geometría funcional de los escritorios 3.11 y el volumen amable de la era XP, sin reproducir iconos ni marcas de terceros. Distribuido como complemento independiente de JANUS Retro." -Encoding UTF8

$manifest=[ordered]@{id="janus-retro";version=1;displayName="JANUS Retro";publisher="Momocrackcorp";variants=@("Pradera","Puma","Mosaico98");wallpapers=@("Pradera","Nubes","Bosque","Puma","Mosaico98");slideshowMinutes=30;preserveWindowsMode=$true;watermarkedWallpapers=@("Nubes","Bosque");components=@("wallpapers","colors","cursors","sounds");baseColor="#008080";accentColor="#0054E3";secondaryAccentColor="#F29A2E";soundStyle="Original public CC0 warm 1990s-style chimes, soft alerts and digital startup signature";cursorStyle="Pixel-edged classic pointer adapted for high-DPI Windows 11";iconCompanion="Tema-Iconos-Retro.zip";safe=$true;reversible=$true}
$manifest|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $themeRoot "manifest.json") -Encoding UTF8

$readme=@'
JANUS Retro

Tema inspirado en la claridad y el optimismo visual de los escritorios de 1995–2001, reinterpretado para Windows 11.
Incluye cinco fondos originales en rotación cada 30 minutos, cursores de bordes pixelados, una firma sonora digital propia y un complemento de iconos descargable por separado.
Los nueve sonidos públicos fueron sintetizados desde cero para JANUS+ y se ofrecen bajo CC0; no contienen audio extraído de Microsoft Windows.
Los fondos Nubes y Bosque incorporan una marca JANUS discreta; los otros tres fondos se conservan sin marca.
Las imágenes fueron generadas para JANUS y no reproducen fondos, logotipos ni interfaces de terceros.
'@
Set-Content -LiteralPath (Join-Path $themeRoot "README.txt") -Value $readme -Encoding UTF8

$themeZip=Join-Path $dist "JANUS-Retro-v1.zip";$iconsZip=Join-Path $dist "Tema-Iconos-Retro.zip"
Remove-Item -LiteralPath $themeZip,$iconsZip -Force -ErrorAction SilentlyContinue
$archive=[IO.Compression.ZipFile]::Open($themeZip,[IO.Compression.ZipArchiveMode]::Create)
try{Get-ChildItem -LiteralPath $themeRoot -File -Recurse|Where-Object{$_.FullName -notlike "$sourceDir\*" -and $_.FullName -notlike "$cursorSourceDir\*" -and $_.FullName -notlike "$soundSourceDir\*" -and $_.FullName -notlike "$iconDir\*"}|ForEach-Object{$relative=$_.FullName.Substring($themeRoot.Length+1).Replace("\","/");[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$_.FullName,$relative,[IO.Compression.CompressionLevel]::Optimal)|Out-Null}}finally{$archive.Dispose()}
Compress-Archive -Path (Join-Path $iconDir "*") -DestinationPath $iconsZip -CompressionLevel Optimal -Force
Get-FileHash $themeZip,$iconsZip -Algorithm SHA256|Select-Object Path,Hash
