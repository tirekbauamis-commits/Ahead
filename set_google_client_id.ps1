$ErrorActionPreference = 'Stop'

$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $appDir 'backend\.env'
$exampleFile = Join-Path $appDir 'backend\.env.example'

if (-not (Test-Path -LiteralPath $envFile)) {
    if (Test-Path -LiteralPath $exampleFile) {
        Copy-Item -LiteralPath $exampleFile -Destination $envFile
    } else {
        New-Item -ItemType File -Path $envFile -Force | Out-Null
    }
}

Write-Host ''
Write-Host 'Masukkan GOOGLE_CLIENT_ID dari Google Cloud.' -ForegroundColor Cyan
Write-Host 'Contoh bentuknya: 1234567890-xxxx.apps.googleusercontent.com' -ForegroundColor DarkGray
Write-Host ''
$clientId = Read-Host 'GOOGLE_CLIENT_ID'
$clientId = $clientId.Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-Host 'Client ID kosong. Tidak ada perubahan.' -ForegroundColor Yellow
    exit 1
}

if ($clientId -notmatch '\.apps\.googleusercontent\.com$') {
    Write-Host 'Format Client ID terlihat tidak sesuai. Pastikan di-copy dari OAuth Client ID Google Cloud.' -ForegroundColor Yellow
    exit 1
}

$lines = Get-Content -LiteralPath $envFile
$found = $false
$updated = foreach ($line in $lines) {
    if ($line -match '^\s*GOOGLE_CLIENT_ID\s*=') {
        $found = $true
        "GOOGLE_CLIENT_ID=$clientId"
    } else {
        $line
    }
}

if (-not $found) {
    $updated += "GOOGLE_CLIENT_ID=$clientId"
}

Set-Content -LiteralPath $envFile -Value $updated

Write-Host ''
Write-Host 'GOOGLE_CLIENT_ID berhasil disimpan ke backend\.env.' -ForegroundColor Green
Write-Host 'Tutup aplikasi lama, lalu jalankan lagi JALANKAN_AHEAD.bat.' -ForegroundColor Green
