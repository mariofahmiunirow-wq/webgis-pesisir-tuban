Add-Type -AssemblyName System.Drawing

$maxWidth = 1000
$maxHeight = 1000
$quality = 75

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)

$kecFolders = @('KECAMATAN BANCAR', 'KECAMATAN JENU', 'kecamatan palang', 'KECAMATAN TAMBAKBOYO', 'KECAMATAN TUBAN')

$files = Get-ChildItem -Path $kecFolders -Include *.jpg,*.jpeg -Recurse -File

Write-Host "Found $($files.Count) image files to compress..."

$count = 0
$totalOriginal = 0
$totalNew = 0

foreach ($file in $files) {
    try {
        $origSize = $file.Length
        $totalOriginal += $origSize
        
        $srcImage = [System.Drawing.Image]::FromFile($file.FullName)
        $w = $srcImage.Width
        $h = $srcImage.Height
        
        # Calculate new dimensions
        if ($w -gt $maxWidth -or $h -gt $maxHeight) {
            $ratioX = $maxWidth / $w
            $ratioY = $maxHeight / $h
            $ratio = [Math]::Min($ratioX, $ratioY)
            $newW = [int]($w * $ratio)
            $newH = [int]($h * $ratio)
        } else {
            $newW = $w
            $newH = $h
        }
        
        $destBitmap = New-Object System.Drawing.Bitmap($newW, $newH)
        $graph = [System.Drawing.Graphics]::FromImage($destBitmap)
        $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graph.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graph.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        
        $graph.DrawImage($srcImage, 0, 0, $newW, $newH)
        
        $srcImage.Dispose()
        $graph.Dispose()
        
        # Temp save path
        $tempPath = $file.FullName + ".tmp"
        $destBitmap.Save($tempPath, $jpegCodec, $encoderParams)
        $destBitmap.Dispose()
        
        # Replace original file with compressed file
        Remove-Item -Path $file.FullName -Force
        Move-Item -Path $tempPath -Destination $file.FullName -Force
        
        $newSize = (Get-Item $file.FullName).Length
        $totalNew += $newSize
        
        $count++
        if ($count % 20 -eq 0 -or $count -eq $files.Count) {
            Write-Host "Compressed $count / $($files.Count) files..."
        }
    } catch {
        Write-Host "Error compressing $($file.Name): $_"
    }
}

$origMB = [Math]::Round($totalOriginal / 1MB, 2)
$newMB = [Math]::Round($totalNew / 1MB, 2)
$savings = [Math]::Round((1 - ($totalNew / $totalOriginal)) * 100, 1)

Write-Host "=========================================="
Write-Host "Compression Complete!"
Write-Host "Original Size : $origMB MB"
Write-Host "New Size      : $newMB MB"
Write-Host "Total Savings : $savings%"
Write-Host "=========================================="
