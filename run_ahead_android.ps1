$ErrorActionPreference = 'Stop'
$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir
$mysqlExe = 'C:\laragon\bin\mysql\mysql-8.4.11-winx64\bin\mysqld.exe'
$mysqlIni = 'C:\laragon\bin\mysql\mysql-8.4.11-winx64\my.ini'
$phpExe = 'C:\laragon\bin\php\php-8.4.25\php.exe'
$adbExe = 'C:\Android\SDK\platform-tools\adb.exe'
$apiUrl = 'http://127.0.0.1:8000/health'

function Test-TcpPort([string] $HostName, [int] $Port) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $result = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $result.AsyncWaitHandle.WaitOne(1000, $false)) { return $false }
        $client.EndConnect($result)
        return $true
    } catch { return $false } finally { $client.Close() }
}

function Test-Backend {
    try {
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    } catch { return $false }
}

Write-Host '=== Menyiapkan AHEAD untuk HP Android ===' -ForegroundColor Cyan
if (-not (Test-TcpPort '127.0.0.1' 3306)) {
    if (-not (Test-Path -LiteralPath $mysqlExe)) { throw 'MySQL Laragon tidak ditemukan. Buka Laragon dan klik Start All.' }
    $mysqlArgs = @()
    if (Test-Path -LiteralPath $mysqlIni) { $mysqlArgs += "--defaults-file=$mysqlIni" }
    Start-Process -FilePath $mysqlExe -ArgumentList $mysqlArgs -WorkingDirectory (Split-Path -Parent $mysqlExe) -WindowStyle Hidden
    for ($i = 0; $i -lt 20 -and -not (Test-TcpPort '127.0.0.1' 3306); $i++) { Start-Sleep -Seconds 1 }
    if (-not (Test-TcpPort '127.0.0.1' 3306)) { throw 'MySQL belum aktif. Buka Laragon, klik Start All, lalu jalankan ulang file ini.' }
}
Write-Host 'MySQL aktif.' -ForegroundColor Green

if (-not (Test-Backend)) {
    if (-not (Test-Path -LiteralPath $phpExe)) {
        $php = Get-Command php -ErrorAction SilentlyContinue
        if ($php) { $phpExe = $php.Source }
    }
    if (-not (Test-Path -LiteralPath $phpExe)) { throw 'PHP Laragon tidak ditemukan.' }
    Start-Process -FilePath $phpExe -ArgumentList @('-S', '127.0.0.1:8000', '-t', (Join-Path $appDir 'backend\public'), (Join-Path $appDir 'backend\public\index.php')) -WorkingDirectory $appDir -WindowStyle Hidden
    for ($i = 0; $i -lt 12 -and -not (Test-Backend); $i++) { Start-Sleep -Seconds 1 }
}
if (-not (Test-Backend)) { throw 'Backend belum aktif pada port 8000. Periksa proses lain yang memakai port tersebut.' }
Write-Host 'Backend API aktif di 127.0.0.1:8000.' -ForegroundColor Green

if (-not (Test-Path -LiteralPath $adbExe)) { throw "ADB tidak ditemukan: $adbExe. Periksa Android SDK." }
$deviceLines = @(& $adbExe devices -l | Select-String -Pattern '^\s*(\S+)\s+device(?:\s|$)')
$deviceIds = @($deviceLines | ForEach-Object { $_.Matches[0].Groups[1].Value })
if ($deviceIds.Count -eq 0) {
    Write-Host 'Belum ada HP terhubung. Aktifkan Opsi Pengembang dan USB debugging, sambungkan kabel USB, pilih Izinkan di HP, lalu jalankan ulang.' -ForegroundColor Yellow
    & flutter devices
    exit 1
}
if ($deviceIds.Count -eq 1) {
    $deviceId = $deviceIds[0]
} else {
    Write-Host 'Perangkat Android:'
    $deviceIds | ForEach-Object { Write-Host " - $_" }
    $deviceId = Read-Host 'Masukkan ID perangkat yang ingin dipakai'
    if ($deviceIds -notcontains $deviceId) { throw 'ID perangkat tidak cocok dengan daftar yang tersedia.' }
}

& $adbExe -s $deviceId reverse tcp:8000 tcp:8000
if ($LASTEXITCODE -ne 0) { throw 'ADB reverse gagal. Pastikan USB debugging sudah diizinkan pada HP.' }
Write-Host 'Koneksi API dari HP ke backend PC siap.' -ForegroundColor Green

$flutterArgs = @('run', '-d', $deviceId)
$envFile = Join-Path $appDir 'backend\.env'
if (Test-Path -LiteralPath $envFile) {
    foreach ($line in Get-Content -LiteralPath $envFile) {
        if ($line -match '^\s*GOOGLE_CLIENT_ID\s*=\s*(.*)\s*$') {
            $clientId = $matches[1].Trim().Trim('"').Trim("'")
            if ($clientId) { $flutterArgs += "--dart-define=GOOGLE_CLIENT_ID=$clientId"; break }
        }
    }
}
Write-Host "Memasang dan menjalankan AHEAD di perangkat $deviceId. Hentikan dengan Ctrl+C." -ForegroundColor Cyan
& flutter @flutterArgs