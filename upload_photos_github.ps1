# ============================================================
# UPLOAD PHOTOS TO GITHUB via API
# Script ini mengupload semua foto dari folder /photos ke GitHub
# ============================================================

# ===== KONFIGURASI - WAJIB DIISI =====
$GITHUB_TOKEN = "ISI_TOKEN_GITHUB_ANDA_DISINI"
$REPO_OWNER   = "mariofahmiunirow-wq"
$REPO_NAME    = "webgis-pesisir-tuban"
$BRANCH       = "main"
$TARGET_FOLDER = "photos"   # folder tujuan di GitHub
# ======================================

$PHOTOS_DIR = "d:\UNIROW\2026\HIBAH\penelitian\map\DATA DESA\photos"
$API_BASE   = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " UPLOAD FOTO KE GITHUB - WebGIS Pesisir Tuban" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Cek apakah token sudah diisi
if ($GITHUB_TOKEN -eq "ISI_TOKEN_GITHUB_ANDA_DISINI") {
    Write-Host "`n[ERROR] Anda belum mengisi GITHUB_TOKEN!" -ForegroundColor Red
    Write-Host "Ikuti langkah berikut untuk mendapatkan token:" -ForegroundColor Yellow
    Write-Host "  1. Buka https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "  2. Klik 'Generate new token (classic)'" -ForegroundColor White
    Write-Host "  3. Centang scope: 'repo'" -ForegroundColor White
    Write-Host "  4. Klik 'Generate token'" -ForegroundColor White
    Write-Host "  5. Copy token dan paste di baris: `$GITHUB_TOKEN di script ini" -ForegroundColor White
    exit 1
}

$headers = @{
    "Authorization" = "token $GITHUB_TOKEN"
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "WebGIS-Uploader"
}

# Ambil semua file foto
$photoFiles = Get-ChildItem -Path $PHOTOS_DIR -File | Where-Object { 
    $_.Extension -match "\.(jpg|jpeg|png|webp|gif)$" 
}

Write-Host "`nDitemukan $($photoFiles.Count) foto untuk diupload" -ForegroundColor Green
Write-Host "Target: https://github.com/$REPO_OWNER/$REPO_NAME/tree/$BRANCH/$TARGET_FOLDER`n"

$success = 0
$skip    = 0
$failed  = 0
$total   = $photoFiles.Count
$i       = 0

foreach ($file in $photoFiles) {
    $i++
    $remotePath = "$TARGET_FOLDER/$($file.Name)"
    $apiUrl     = "$API_BASE/$remotePath"
    
    Write-Progress -Activity "Mengupload Foto" -Status "[$i/$total] $($file.Name)" -PercentComplete (($i / $total) * 100)
    
    # Cek apakah file sudah ada di GitHub
    try {
        $existing = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET -ErrorAction Stop
        Write-Host "  [SKIP] $($file.Name) - sudah ada di GitHub" -ForegroundColor DarkGray
        $skip++
        continue
    } catch {
        # File belum ada, lanjutkan upload
    }
    
    # Encode file ke Base64
    $bytes      = [System.IO.File]::ReadAllBytes($file.FullName)
    $base64     = [Convert]::ToBase64String($bytes)
    
    $body = @{
        message = "Upload foto: $($file.Name)"
        content = $base64
        branch  = $BRANCH
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
        $success++
        # Jeda kecil agar tidak rate-limit
        Start-Sleep -Milliseconds 300
    } catch {
        $errMsg = $_.Exception.Message
        Write-Host "  [FAIL] $($file.Name) - $errMsg" -ForegroundColor Red
        $failed++
    }
}

Write-Progress -Activity "Mengupload Foto" -Completed

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " HASIL UPLOAD:" -ForegroundColor Cyan
Write-Host "  Berhasil  : $success file" -ForegroundColor Green
Write-Host "  Skip      : $skip file (sudah ada)" -ForegroundColor DarkGray
Write-Host "  Gagal     : $failed file" -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "`nSetelah upload selesai, tunggu 2-5 menit lalu buka:" -ForegroundColor Yellow
Write-Host "https://mariofahmiunirow-wq.github.io/webgis-pesisir-tuban/" -ForegroundColor White
