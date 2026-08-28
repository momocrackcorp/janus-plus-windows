param([string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent))

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = (Resolve-Path $RepositoryRoot).Path
$themeRoot = Join-Path $repo "assets\windows-themes\silicon"
$sourceDir = Join-Path $themeRoot "Concepts"
$wallpaperDir = Join-Path $themeRoot "DesktopBackground"
$previewDir = Join-Path $themeRoot "Preview"
$cursorDir = Join-Path $themeRoot "Cursors"
$cursorSourceDir = Join-Path $themeRoot "CursorSource"
$soundDir = Join-Path $themeRoot "Sounds"
$iconDir = Join-Path $themeRoot "Icons"
$dist = Join-Path $repo "dist\themes"
foreach($directory in @($themeRoot,$sourceDir,$wallpaperDir,$previewDir,$cursorDir,$cursorSourceDir,$soundDir,$iconDir,$dist)){New-Item -ItemType Directory -Force -Path $directory|Out-Null}
foreach($directory in @($wallpaperDir,$cursorDir,$soundDir)){Get-ChildItem -LiteralPath $directory -File -ErrorAction SilentlyContinue|Remove-Item -Force}
Get-ChildItem -LiteralPath $previewDir -File -Filter 'JANUS-Silicon-*-preview.png' -ErrorAction SilentlyContinue|Where-Object{$_.Name -ne 'JANUS-Silicon-Iconos-Explorer-preview.png'}|Remove-Item -Force

$graphite=[Drawing.Color]::FromArgb(35,45,55)
$graphiteSoft=[Drawing.Color]::FromArgb(70,82,93)
$silver=[Drawing.Color]::FromArgb(231,237,241)
$white=[Drawing.Color]::White
$cyan=[Drawing.Color]::FromArgb(0,174,220)
$cyanLight=[Drawing.Color]::FromArgb(105,225,246)
$copper=[Drawing.Color]::FromArgb(205,126,62)
$amber=[Drawing.Color]::FromArgb(239,170,86)
$red=[Drawing.Color]::FromArgb(218,75,68)

function Save-Jpeg([Drawing.Image]$image,[string]$path,[long]$quality=92){$codec=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|Where-Object{$_.MimeType -eq 'image/jpeg'}|Select-Object -First 1;$parameters=New-Object Drawing.Imaging.EncoderParameters 1;$parameters.Param[0]=New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality),$quality;try{$image.Save($path,$codec,$parameters)}finally{$parameters.Param[0].Dispose();$parameters.Dispose()}}

function New-CoverImage([string]$sourcePath,[int]$width,[int]$height,[string]$destination){
    $source=[Drawing.Image]::FromFile($sourcePath)
    try{$targetRatio=$width/[double]$height;$sourceRatio=$source.Width/[double]$source.Height;if($sourceRatio -gt $targetRatio){$cropHeight=$source.Height;$cropWidth=[int]($cropHeight*$targetRatio);$cropX=[int](($source.Width-$cropWidth)/2);$cropY=0}else{$cropWidth=$source.Width;$cropHeight=[int]($cropWidth/$targetRatio);$cropX=0;$cropY=[int](($source.Height-$cropHeight)/2)};$target=New-Object Drawing.Bitmap $width,$height;try{$graphics=[Drawing.Graphics]::FromImage($target);try{$graphics.CompositingQuality=[Drawing.Drawing2D.CompositingQuality]::HighQuality;$graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;$graphics.PixelOffsetMode=[Drawing.Drawing2D.PixelOffsetMode]::HighQuality;$graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,$width,$height),[Drawing.Rectangle]::new($cropX,$cropY,$cropWidth,$cropHeight),[Drawing.GraphicsUnit]::Pixel)}finally{$graphics.Dispose()};Save-Jpeg $target $destination}finally{$target.Dispose()}}finally{$source.Dispose()}
}

function New-CursorCanvas{$bitmap=New-Object Drawing.Bitmap 64,64,([Drawing.Imaging.PixelFormat]::Format32bppArgb);$graphics=[Drawing.Graphics]::FromImage($bitmap);$graphics.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias;$graphics.Clear([Drawing.Color]::Transparent);return @($bitmap,$graphics)}
function New-Pen([Drawing.Color]$color,[single]$width){$pen=New-Object Drawing.Pen $color,$width;$pen.LineJoin=[Drawing.Drawing2D.LineJoin]::Round;return $pen}
function New-Brush([Drawing.Color]$color){return New-Object Drawing.SolidBrush $color}

function Add-SiliconArrow([Drawing.Graphics]$graphics,[double]$scale=1.0){
    $points=[Drawing.PointF[]]@([Drawing.PointF]::new([float](6*$scale),[float](4*$scale)),[Drawing.PointF]::new([float](8*$scale),[float](50*$scale)),[Drawing.PointF]::new([float](20*$scale),[float](39*$scale)),[Drawing.PointF]::new([float](30*$scale),[float](59*$scale)),[Drawing.PointF]::new([float](40*$scale),[float](54*$scale)),[Drawing.PointF]::new([float](30*$scale),[float](35*$scale)),[Drawing.PointF]::new([float](48*$scale),[float](31*$scale)))
    $outline=New-Pen $graphite 4;$fill=New-Brush $silver;$trace=New-Pen $cyan 2;$node=New-Brush $copper
    try{$graphics.FillPolygon($fill,$points);$graphics.DrawPolygon($outline,$points);$graphics.DrawLine($trace,[float](11*$scale),[float](12*$scale),[float](13*$scale),[float](39*$scale));$graphics.DrawLine($trace,[float](13*$scale),[float](28*$scale),[float](24*$scale),[float](34*$scale));$graphics.FillEllipse($node,[float](10*$scale),[float](9*$scale),[float](6*$scale),[float](6*$scale))}finally{foreach($item in @($node,$trace,$fill,$outline)){$item.Dispose()}}
}

function Convert-ToCursorBytes([Drawing.Bitmap]$bitmap,[int]$hotX,[int]$hotY){$pngStream=New-Object IO.MemoryStream;$bitmap.Save($pngStream,[Drawing.Imaging.ImageFormat]::Png);$png=$pngStream.ToArray();$pngStream.Dispose();$stream=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $stream;$writer.Write([UInt16]0);$writer.Write([UInt16]2);$writer.Write([UInt16]1);$writer.Write([byte]64);$writer.Write([byte]64);$writer.Write([byte]0);$writer.Write([byte]0);$writer.Write([UInt16]$hotX);$writer.Write([UInt16]$hotY);$writer.Write([UInt32]$png.Length);$writer.Write([UInt32]22);$writer.Write($png);$writer.Flush();$bytes=$stream.ToArray();$writer.Dispose();$stream.Dispose();return ,$bytes}

function New-SiliconCursor([string]$name,[string]$kind,[int]$hotX,[int]$hotY){
    $canvas=New-CursorCanvas;$bitmap=$canvas[0];$graphics=$canvas[1];$dark=New-Pen $graphite 5;$cyanPen=New-Pen $cyan 4;$copperPen=New-Pen $copper 4;$silverBrush=New-Brush $silver;$cyanBrush=New-Brush $cyan;$copperBrush=New-Brush $copper;$redBrush=New-Brush $red
    try{switch($kind){
        'arrow'{Add-SiliconArrow $graphics}
        'help'{Add-SiliconArrow $graphics;$graphics.FillEllipse($copperBrush,36,36,24,24);$font=New-Object Drawing.Font 'Segoe UI',14,([Drawing.FontStyle]::Bold);$graphics.DrawString('?',$font,(New-Brush $white),41,36);$font.Dispose()}
        'hand'{$graphics.FillRectangle($silverBrush,17,8,19,42);$graphics.FillRectangle($silverBrush,10,25,40,23);$graphics.DrawRectangle($dark,17,8,19,42);$graphics.DrawRectangle($dark,10,25,40,23);$graphics.DrawLine($cyanPen,22,14,22,39);$graphics.FillEllipse($copperBrush,19,10,7,7)}
        'ibeam'{$graphics.DrawLine($dark,20,7,44,7);$graphics.DrawLine($dark,32,7,32,57);$graphics.DrawLine($dark,20,57,44,57);$graphics.DrawLine($cyanPen,27,22,37,22);$graphics.DrawLine($copperPen,27,42,37,42)}
        'cross'{$graphics.DrawLine($dark,32,4,32,60);$graphics.DrawLine($dark,4,32,60,32);$graphics.FillEllipse($cyanBrush,26,26,12,12);$graphics.FillEllipse($copperBrush,29,29,6,6)}
        'move'{$graphics.DrawLine($dark,32,8,32,56);$graphics.DrawLine($dark,8,32,56,32);$graphics.FillPolygon($cyanBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(22,17),[Drawing.Point]::new(42,17)));$graphics.FillPolygon($cyanBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(22,47),[Drawing.Point]::new(42,47)));$graphics.FillPolygon($copperBrush,[Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(17,22),[Drawing.Point]::new(17,42)));$graphics.FillPolygon($copperBrush,[Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(47,22),[Drawing.Point]::new(47,42)))}
        'ns'{$graphics.DrawLine($dark,32,10,32,54);$graphics.FillPolygon($cyanBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(21,18),[Drawing.Point]::new(43,18)));$graphics.FillPolygon($copperBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(21,46),[Drawing.Point]::new(43,46)))}
        'we'{$graphics.DrawLine($dark,10,32,54,32);$graphics.FillPolygon($cyanBrush,[Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(18,21),[Drawing.Point]::new(18,43)));$graphics.FillPolygon($copperBrush,[Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(46,21),[Drawing.Point]::new(46,43)))}
        'nwse'{$graphics.DrawLine($dark,11,11,53,53);$graphics.FillEllipse($cyanBrush,4,4,16,16);$graphics.FillEllipse($copperBrush,44,44,16,16)}
        'nesw'{$graphics.DrawLine($dark,53,11,11,53);$graphics.FillEllipse($cyanBrush,44,4,16,16);$graphics.FillEllipse($copperBrush,4,44,16,16)}
        'up'{$graphics.DrawLine($dark,32,14,32,58);$graphics.FillPolygon($cyanBrush,[Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(17,22),[Drawing.Point]::new(47,22)));$graphics.FillEllipse($copperBrush,27,31,10,10)}
        'no'{Add-SiliconArrow $graphics 0.72;$graphics.DrawEllipse($dark,26,26,33,33);$graphics.DrawEllipse($cyanPen,29,29,27,27);$graphics.DrawLine((New-Pen $red 5),34,34,52,52)}
        'pen'{$graphics.DrawLine($dark,10,54,49,15);$graphics.DrawLine($cyanPen,13,51,47,17);$graphics.FillPolygon($copperBrush,[Drawing.Point[]]@([Drawing.Point]::new(49,8),[Drawing.Point]::new(57,16),[Drawing.Point]::new(48,24),[Drawing.Point]::new(40,16)))}
    };[IO.File]::WriteAllBytes((Join-Path $cursorDir $name),(Convert-ToCursorBytes $bitmap $hotX $hotY))}finally{foreach($item in @($redBrush,$copperBrush,$cyanBrush,$silverBrush,$copperPen,$cyanPen,$dark,$graphics,$bitmap)){$item.Dispose()}}
}

function Add-SiliconFan([Drawing.Graphics]$graphics,[int]$cx,[int]$cy,[int]$frame){$hub=New-Brush $copper;try{$graphics.FillEllipse($hub,$cx-5,$cy-5,10,10);for($i=0;$i -lt 8;$i++){$angle=($i*45+$frame*45)*[Math]::PI/180;$x=[int]($cx+16*[Math]::Cos($angle));$y=[int]($cy+16*[Math]::Sin($angle));$brush=New-Brush $(if($i -eq 0){$cyanLight}elseif($i%2){$silver}else{$cyan});try{$graphics.FillEllipse($brush,$x-5,$y-5,10,10)}finally{$brush.Dispose()}}}finally{$hub.Dispose()}}
function New-SiliconAni([string]$name,[bool]$withArrow){$frames=@();for($frame=0;$frame -lt 8;$frame++){$canvas=New-CursorCanvas;$bitmap=$canvas[0];$graphics=$canvas[1];if($withArrow){Add-SiliconArrow $graphics 0.70;Add-SiliconFan $graphics 47 45 $frame}else{Add-SiliconFan $graphics 32 32 $frame};$frames+=,(Convert-ToCursorBytes $bitmap $(if($withArrow){5}else{32}) $(if($withArrow){4}else{32}));$graphics.Dispose();$bitmap.Dispose()};$stream=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $stream;$writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'));$writer.Write([UInt32]0);$writer.Write([Text.Encoding]::ASCII.GetBytes('ACON'));$writer.Write([Text.Encoding]::ASCII.GetBytes('anih'));$writer.Write([UInt32]36);foreach($value in @([UInt32]36,[UInt32]8,[UInt32]8,[UInt32]64,[UInt32]64,[UInt32]32,[UInt32]1,[UInt32]6,[UInt32]3)){$writer.Write($value)};$writer.Write([Text.Encoding]::ASCII.GetBytes('rate'));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]6)};$writer.Write([Text.Encoding]::ASCII.GetBytes('seq '));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]$_)};$listStream=New-Object IO.MemoryStream;$listWriter=New-Object IO.BinaryWriter $listStream;$listWriter.Write([Text.Encoding]::ASCII.GetBytes('fram'));foreach($cursor in $frames){$listWriter.Write([Text.Encoding]::ASCII.GetBytes('icon'));$listWriter.Write([UInt32]$cursor.Length);$listWriter.Write($cursor);if($cursor.Length%2){$listWriter.Write([byte]0)}};$listWriter.Flush();$list=$listStream.ToArray();$listWriter.Dispose();$listStream.Dispose();$writer.Write([Text.Encoding]::ASCII.GetBytes('LIST'));$writer.Write([UInt32]$list.Length);$writer.Write($list);if($list.Length%2){$writer.Write([byte]0)};$writer.Flush();$length=$stream.Length;$stream.Position=4;$writer.Write([UInt32]($length-8));$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $cursorDir $name),$stream.ToArray());$writer.Dispose();$stream.Dispose()}

function Add-CrystalArrow([Drawing.Graphics]$graphics,[int]$x=5,[int]$y=3,[double]$scale=1.0){
    $points=[Drawing.PointF[]]@([Drawing.PointF]::new([float]$x,[float]$y),[Drawing.PointF]::new([float]($x+3*$scale),[float]($y+43*$scale)),[Drawing.PointF]::new([float]($x+13*$scale),[float]($y+34*$scale)),[Drawing.PointF]::new([float]($x+23*$scale),[float]($y+52*$scale)),[Drawing.PointF]::new([float]($x+32*$scale),[float]($y+47*$scale)),[Drawing.PointF]::new([float]($x+23*$scale),[float]($y+30*$scale)),[Drawing.PointF]::new([float]($x+40*$scale),[float]($y+28*$scale)))
    $darkPen=New-Pen ([Drawing.Color]::FromArgb(6,28,54)) ([float](6*$scale));$whitePen=New-Pen $white ([float](3*$scale));$highlight=New-Pen ([Drawing.Color]::FromArgb(220,235,252,255)) ([float](1.4*$scale));$fill=New-Brush ([Drawing.Color]::FromArgb(45,174,244))
    try{$graphics.FillPolygon($fill,$points);$graphics.DrawPolygon($darkPen,$points);$graphics.DrawPolygon($whitePen,$points);$graphics.DrawLine($highlight,[float]($x+6*$scale),[float]($y+8*$scale),[float]($x+9*$scale),[float]($y+31*$scale))}finally{foreach($item in @($fill,$highlight,$whitePen,$darkPen)){$item.Dispose()}}
}

function Add-CrystalArrowHead([Drawing.Graphics]$graphics,[Drawing.Point[]]$points){$dark=New-Pen ([Drawing.Color]::FromArgb(6,28,54)) 5;$whitePen=New-Pen $white 2;$fill=New-Brush ([Drawing.Color]::FromArgb(45,174,244));try{$graphics.FillPolygon($fill,$points);$graphics.DrawPolygon($dark,$points);$graphics.DrawPolygon($whitePen,$points)}finally{$fill.Dispose();$whitePen.Dispose();$dark.Dispose()}}

function New-CrystalCursor([string]$name,[string]$kind,[int]$hotX,[int]$hotY){
    $canvas=New-CursorCanvas;$bitmap=$canvas[0];$graphics=$canvas[1];$dark=New-Pen ([Drawing.Color]::FromArgb(6,28,54)) 7;$whitePen=New-Pen $white 3;$cyanPen=New-Pen ([Drawing.Color]::FromArgb(45,174,244)) 5;$orangePen=New-Pen ([Drawing.Color]::FromArgb(238,145,65)) 5;$cyanBrush=New-Brush ([Drawing.Color]::FromArgb(45,174,244));$whiteBrush=New-Brush $white;$orangeBrush=New-Brush ([Drawing.Color]::FromArgb(238,145,65))
    try{switch($kind){
        'arrow'{Add-CrystalArrow $graphics}
        'help'{Add-CrystalArrow $graphics 4 3 0.78;$graphics.DrawEllipse($dark,35,34,25,25);$graphics.FillEllipse($cyanBrush,36,35,23,23);$font=New-Object Drawing.Font 'Segoe UI',14,([Drawing.FontStyle]::Bold);try{$graphics.DrawString('?',$font,$whiteBrush,40,34)}finally{$font.Dispose()}}
        'hand'{$shape=[Drawing.Point[]]@([Drawing.Point]::new(18,8),[Drawing.Point]::new(27,8),[Drawing.Point]::new(27,25),[Drawing.Point]::new(34,18),[Drawing.Point]::new(41,21),[Drawing.Point]::new(47,25),[Drawing.Point]::new(52,31),[Drawing.Point]::new(48,49),[Drawing.Point]::new(38,58),[Drawing.Point]::new(20,55),[Drawing.Point]::new(10,38),[Drawing.Point]::new(12,30),[Drawing.Point]::new(18,30));$graphics.FillPolygon($cyanBrush,$shape);$graphics.DrawPolygon($dark,$shape);$graphics.DrawPolygon($whitePen,$shape);$graphics.DrawLine($whitePen,22,13,22,38)}
        'ibeam'{$graphics.DrawLine($dark,19,7,45,7);$graphics.DrawLine($dark,32,7,32,57);$graphics.DrawLine($dark,19,57,45,57);$graphics.DrawLine($whitePen,20,7,44,7);$graphics.DrawLine($cyanPen,32,8,32,56);$graphics.DrawLine($whitePen,20,57,44,57)}
        'cross'{$graphics.DrawLine($dark,32,4,32,60);$graphics.DrawLine($dark,4,32,60,32);$graphics.DrawLine($whitePen,32,5,32,59);$graphics.DrawLine($whitePen,5,32,59,32);$graphics.DrawEllipse($cyanPen,25,25,14,14)}
        'move'{$graphics.DrawLine($dark,32,9,32,55);$graphics.DrawLine($dark,9,32,55,32);$graphics.DrawLine($whitePen,32,10,32,54);$graphics.DrawLine($whitePen,10,32,54,32);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(23,17),[Drawing.Point]::new(41,17)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(23,47),[Drawing.Point]::new(41,47)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(17,23),[Drawing.Point]::new(17,41)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(47,23),[Drawing.Point]::new(47,41)))}
        'ns'{$graphics.DrawLine($dark,32,12,32,52);$graphics.DrawLine($whitePen,32,12,32,52);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(21,18),[Drawing.Point]::new(43,18)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(32,62),[Drawing.Point]::new(21,46),[Drawing.Point]::new(43,46)))}
        'we'{$graphics.DrawLine($dark,12,32,52,32);$graphics.DrawLine($whitePen,12,32,52,32);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(2,32),[Drawing.Point]::new(18,21),[Drawing.Point]::new(18,43)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(62,32),[Drawing.Point]::new(46,21),[Drawing.Point]::new(46,43)))}
        'nwse'{$graphics.DrawLine($dark,12,12,52,52);$graphics.DrawLine($whitePen,13,13,51,51);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(5,5),[Drawing.Point]::new(10,23),[Drawing.Point]::new(23,10)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(59,59),[Drawing.Point]::new(54,41),[Drawing.Point]::new(41,54)))}
        'nesw'{$graphics.DrawLine($dark,52,12,12,52);$graphics.DrawLine($whitePen,51,13,13,51);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(59,5),[Drawing.Point]::new(41,10),[Drawing.Point]::new(54,23)));Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(5,59),[Drawing.Point]::new(23,54),[Drawing.Point]::new(10,41)))}
        'up'{$graphics.DrawLine($dark,32,15,32,58);$graphics.DrawLine($whitePen,32,15,32,58);Add-CrystalArrowHead $graphics ([Drawing.Point[]]@([Drawing.Point]::new(32,2),[Drawing.Point]::new(18,22),[Drawing.Point]::new(46,22)))}
        'no'{Add-CrystalArrow $graphics 3 2 0.72;$graphics.DrawEllipse($dark,27,27,33,33);$graphics.DrawEllipse($cyanPen,29,29,29,29);$graphics.DrawLine($orangePen,35,52,52,35)}
        'pen'{$graphics.DrawLine($dark,10,54,50,14);$graphics.DrawLine($whitePen,11,53,49,15);$graphics.DrawLine($cyanPen,14,50,47,17);$graphics.FillPolygon($orangeBrush,[Drawing.Point[]]@([Drawing.Point]::new(49,8),[Drawing.Point]::new(57,16),[Drawing.Point]::new(49,24),[Drawing.Point]::new(41,16)))}
    };[IO.File]::WriteAllBytes((Join-Path $cursorDir $name),(Convert-ToCursorBytes $bitmap $hotX $hotY))}finally{foreach($item in @($orangeBrush,$whiteBrush,$cyanBrush,$orangePen,$cyanPen,$whitePen,$dark,$graphics,$bitmap)){$item.Dispose()}}
}

function Add-CrystalSpinner([Drawing.Graphics]$graphics,[int]$cx,[int]$cy,[int]$frame){$dark=New-Pen ([Drawing.Color]::FromArgb(6,28,54)) 8;$whitePen=New-Pen $white 5;$cyanArc=New-Pen ([Drawing.Color]::FromArgb(45,174,244)) 5;$orangeArc=New-Pen ([Drawing.Color]::FromArgb(238,145,65)) 5;try{$graphics.DrawEllipse($dark,$cx-18,$cy-18,36,36);$graphics.DrawEllipse($whitePen,$cx-18,$cy-18,36,36);$graphics.DrawArc($cyanArc,$cx-18,$cy-18,36,36,$frame*45,205);$graphics.DrawArc($orangeArc,$cx-18,$cy-18,36,36,$frame*45+215,75)}finally{$orangeArc.Dispose();$cyanArc.Dispose();$whitePen.Dispose();$dark.Dispose()}}
function New-CrystalAni([string]$name,[bool]$withArrow){$frames=@();for($frame=0;$frame -lt 8;$frame++){$canvas=New-CursorCanvas;$bitmap=$canvas[0];$graphics=$canvas[1];if($withArrow){Add-CrystalArrow $graphics 3 2 0.70;Add-CrystalSpinner $graphics 47 45 $frame}else{Add-CrystalSpinner $graphics 32 32 $frame};$frames+=,(Convert-ToCursorBytes $bitmap $(if($withArrow){5}else{32}) $(if($withArrow){4}else{32}));$graphics.Dispose();$bitmap.Dispose()};$stream=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $stream;$writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'));$writer.Write([UInt32]0);$writer.Write([Text.Encoding]::ASCII.GetBytes('ACON'));$writer.Write([Text.Encoding]::ASCII.GetBytes('anih'));$writer.Write([UInt32]36);foreach($value in @([UInt32]36,[UInt32]8,[UInt32]8,[UInt32]64,[UInt32]64,[UInt32]32,[UInt32]1,[UInt32]6,[UInt32]3)){$writer.Write($value)};$writer.Write([Text.Encoding]::ASCII.GetBytes('rate'));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]6)};$writer.Write([Text.Encoding]::ASCII.GetBytes('seq '));$writer.Write([UInt32]32);0..7|ForEach-Object{$writer.Write([UInt32]$_)};$listStream=New-Object IO.MemoryStream;$listWriter=New-Object IO.BinaryWriter $listStream;$listWriter.Write([Text.Encoding]::ASCII.GetBytes('fram'));foreach($cursor in $frames){$listWriter.Write([Text.Encoding]::ASCII.GetBytes('icon'));$listWriter.Write([UInt32]$cursor.Length);$listWriter.Write($cursor);if($cursor.Length%2){$listWriter.Write([byte]0)}};$listWriter.Flush();$list=$listStream.ToArray();$listWriter.Dispose();$listStream.Dispose();$writer.Write([Text.Encoding]::ASCII.GetBytes('LIST'));$writer.Write([UInt32]$list.Length);$writer.Write($list);if($list.Length%2){$writer.Write([byte]0)};$writer.Flush();$length=$stream.Length;$stream.Position=4;$writer.Write([UInt32]($length-8));$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $cursorDir $name),$stream.ToArray());$writer.Dispose();$stream.Dispose()}

function New-SiliconSound([string]$name,[string]$style){
    $sampleRate=22050;$duration=$(switch($style){'error'{0.72}'start'{1.35}'logon'{0.95}'logoff'{0.85}'exit'{1.15}default{0.58}});$count=[int]($sampleRate*$duration);$samples=New-Object 'Collections.Generic.List[Int16]';$seed=1977
    for($i=0;$i -lt $count;$i++){$t=$i/$sampleRate;$p=$i/[Math]::Max(1,$count-1);$attack=[Math]::Min(1,$i/90);$release=[Math]::Pow(1-$p,1.8);$value=0.0;switch($style){
        'notify'{$frequency=690+470*$p;$value=0.62*[Math]::Sin(2*[Math]::PI*$frequency*$t)*[Math]::Exp(-3.8*$p)+0.20*[Math]::Sin(2*[Math]::PI*($frequency*2.02)*$t)*[Math]::Exp(-7*$p)}
        'complete'{$slot=[Math]::Min(2,[int]($p*3));$frequency=@(523.25,659.25,783.99)[$slot];$local=($p*3)-$slot;$value=0.58*[Math]::Sin(2*[Math]::PI*$frequency*$t)*[Math]::Exp(-3.2*$local)+0.18*[Math]::Sin(2*[Math]::PI*$frequency*2*$t)*[Math]::Exp(-6*$local)}
        'question'{Set-Variable -Name gate -Value 0.28;if(([int]($t*11)%2)-eq 0){Set-Variable -Name gate -Value 1.0};$frequency=520+180*[Math]::Sin(2*[Math]::PI*3.2*$t);$value=$gate*(0.55*[Math]::Sin(2*[Math]::PI*$frequency*$t)+0.19*[Math]::Sin(2*[Math]::PI*$frequency*2.7*$t))*$release}
        'warning'{$pulse=[Math]::Pow([Math]::Max(0,[Math]::Sin(2*[Math]::PI*3.1*$t)),5);$value=$pulse*(0.52*[Math]::Sin(2*[Math]::PI*420*$t)+0.20*[Math]::Sin(2*[Math]::PI*840*$t))*$release}
        'error'{$burst=[int]($t/0.24);$local=($t-$burst*0.24)/0.18;if($burst -lt 3 -and $local -ge 0 -and $local -le 1){$frequency=1550-1050*$local;$seed=(1103515245*$seed+12345)-band 0x7fffffff;$noise=(($seed/1073741824.0)-1.0);$value=(0.52*[Math]::Sin(2*[Math]::PI*$frequency*$t)+0.22*$noise)*[Math]::Exp(-5*$local)}}
        'start'{$frequency=85+720*[Math]::Pow($p,1.7);$value=(0.42*[Math]::Sin(2*[Math]::PI*$frequency*$t)+0.18*[Math]::Sin(2*[Math]::PI*($frequency*2.01)*$t))*$attack*[Math]::Pow(1-$p,0.45)}
        'logon'{$slot=[Math]::Min(3,[int]($p*4));$frequency=@(330.0,495.0,660.0,990.0)[$slot];$local=($p*4)-$slot;$value=0.50*[Math]::Sin(2*[Math]::PI*$frequency*$t)*[Math]::Exp(-3.7*$local)}
        'logoff'{$slot=[Math]::Min(2,[int]($p*3));$frequency=@(760.0,510.0,340.0)[$slot];$local=($p*3)-$slot;$value=0.48*[Math]::Sin(2*[Math]::PI*$frequency*$t)*[Math]::Exp(-3.5*$local)}
        'exit'{$frequency=470*[Math]::Pow(0.12,$p)+42;$value=(0.48*[Math]::Sin(2*[Math]::PI*$frequency*$t)+0.16*[Math]::Sin(2*[Math]::PI*$frequency*0.5*$t))*$release}
    };$sample=[int](8200*[Math]::Max(-1,[Math]::Min(1,$value*$attack)));$null=$samples.Add([Int16]$sample)}
    $stream=New-Object IO.MemoryStream;$writer=New-Object IO.BinaryWriter $stream;$length=$samples.Count*2;$writer.Write([Text.Encoding]::ASCII.GetBytes('RIFF'));$writer.Write([UInt32](36+$length));$writer.Write([Text.Encoding]::ASCII.GetBytes('WAVE'));$writer.Write([Text.Encoding]::ASCII.GetBytes('fmt '));$writer.Write([UInt32]16);$writer.Write([UInt16]1);$writer.Write([UInt16]1);$writer.Write([UInt32]$sampleRate);$writer.Write([UInt32]($sampleRate*2));$writer.Write([UInt16]2);$writer.Write([UInt16]16);$writer.Write([Text.Encoding]::ASCII.GetBytes('data'));$writer.Write([UInt32]$length);foreach($sample in $samples){$writer.Write($sample)};$writer.Flush();[IO.File]::WriteAllBytes((Join-Path $soundDir $name),$stream.ToArray());$writer.Dispose();$stream.Dispose()
}

$wallpapers=@(
    @('Ciudad','JANUS-Silicon-01-Ciudad.png'),@('Hardware','JANUS-Silicon-02-Hardware.png'),@('GPU','JANUS-Silicon-03-GPU.png'),
    @('HDD','JANUS-Silicon-04-HDD.png'),@('SSD','JANUS-Silicon-05-SSD.png'),@('PSU','JANUS-Silicon-06-PSU.png'),@('Pixeles','JANUS-Silicon-07-Pixeles-Binarios.png')
)
foreach($wallpaper in $wallpapers){$source=Join-Path $sourceDir $wallpaper[1];if(!(Test-Path -LiteralPath $source)){throw "Falta la fuente $($wallpaper[1])"};New-CoverImage $source 3840 2160 (Join-Path $wallpaperDir ("JANUS-Silicon-"+$wallpaper[0]+"-4K.jpg"));New-CoverImage $source 5120 2160 (Join-Path $wallpaperDir ("JANUS-Silicon-"+$wallpaper[0]+"-Ultrawide-5K.jpg"));if($wallpaper[0] -in @('Ciudad','Hardware','Pixeles')){New-CoverImage $source 960 540 (Join-Path $previewDir ("JANUS-Silicon-"+$wallpaper[0]+"-preview.png"))}}

$approvedCursors=Get-ChildItem -LiteralPath $cursorSourceDir -File | Where-Object{$_.Extension -in @('.cur','.ani')}
if($approvedCursors.Count -ne 15){throw 'El juego aprobado de cursores Silicon debe contener exactamente 15 archivos.'}
$approvedCursors|Copy-Item -Destination $cursorDir -Force
foreach($sound in @(@('notify','notify'),@('complete','complete'),@('question','question'),@('warning','warning'),@('error','error'),@('start','start'),@('logon','logon'),@('logoff','logoff'),@('exit','exit'))){New-SiliconSound ("silicon-"+$sound[0]+'.wav') $sound[1]}

& (Join-Path $repo 'tools\build-silicon-icons.ps1') -RepositoryRoot $repo | Out-Host

$manifest=[ordered]@{id='janus-silicon';version=1;displayName='JANUS Silicon';publisher='Momocrackcorp';variants=@('Ciudad','Hardware','Pixeles');wallpapers=@('Ciudad','Hardware','GPU','HDD','SSD','PSU','Pixeles');slideshowMinutes=30;shuffle=$true;preserveWindowsMode=$true;components=@('wallpapers','colors','cursors','sounds');baseColor='#232D37';accentColor='#00AEDC';secondaryAccentColor='#CD7E3E';soundStyle='Original hardware power-up, data chirps, radar pulses and triple electronic blaster-style error';cursorStyle='Crystal Blue classic pointers with cyan fill, white highlight, dark outline and animated cyan-copper ring';iconCompanion='Tema-Iconos-Silicon.zip';iconSource='Crystal Remix by Everaldo Coelho and Viet Dang, LGPL';safe=$true;reversible=$true}
$manifest|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $themeRoot 'manifest.json') -Encoding UTF8
$readme=@'
JANUS Silicon

Tema original inspirado en la ingeniería interna de un PC: placas, procesador, memoria, almacenamiento, energía, gráficos y píxeles.
Incluye siete fondos originales en rotación cada 30 minutos, color grafito con énfasis cian, cursores Crystal Blue y sonidos electrónicos creados desde cero.
El complemento de iconos Crystal Remix se distribuye por separado con atribución y licencia LGPL. Ningún sonido reproduce grabaciones de películas, series, juegos o franquicias.
JANUS conserva el modo claro u oscuro actual de Windows y respalda los valores antes de aplicar cambios.
'@
Set-Content -LiteralPath (Join-Path $themeRoot 'README.txt') -Value $readme -Encoding UTF8

$themeZip=Join-Path $dist 'JANUS-Silicon-v1.zip';$iconsZip=Join-Path $dist 'Tema-Iconos-Silicon.zip'
Remove-Item -LiteralPath $themeZip -Force -ErrorAction SilentlyContinue
$archive=[IO.Compression.ZipFile]::Open($themeZip,[IO.Compression.ZipArchiveMode]::Create)
try{Get-ChildItem -LiteralPath $themeRoot -File -Recurse|Where-Object{$_.FullName -notlike "$sourceDir\*" -and $_.FullName -notlike "$cursorSourceDir\*" -and $_.FullName -notlike "$iconDir\*" -and $_.Name -ne 'JANUS-Silicon-Iconos-Explorer-preview.png'}|ForEach-Object{$relative=$_.FullName.Substring($themeRoot.Length+1).Replace('\','/');[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$_.FullName,$relative,[IO.Compression.CompressionLevel]::Optimal)|Out-Null}}finally{$archive.Dispose()}
Get-FileHash $themeZip,$iconsZip -Algorithm SHA256|Select-Object Path,Hash
