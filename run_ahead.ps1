$ErrorActionPreference = 'Stop'

$appDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $appDir

$mysqlExe = 'C:\laragon\bin\mysql\mysql-8.4.11-winx64\bin\mysqld.exe'
$mysqlIni = 'C:\laragon\bin\mysql\mysql-8.4.11-winx64\my.ini'
$phpExe = 'C:\laragon\bin\php\php-8.4.25\php.exe'
$apiUrl = 'http://127.0.0.1:8000/health'
$webPort = '64800'

function Write-Step {
    param([string] $Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string] $Message)
    Write-Host "OK  $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string] $Message)
    Write-Host "!!  $Message" -ForegroundColor Yellow
}

function Test-TcpPort {
    param(
        [string] $HostName,
        [int] $Port
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connection = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $connection.AsyncWaitHandle.WaitOne(1000, $false)) {
            return $false
        }
        $client.EndConnect($connection)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Test-Backend {
    try {
        $response = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    } catch {
        return $false
    }
}

function Get-GoogleClientId {
    $envFile = Join-Path $appDir 'backend\.env'
    if (-not (Test-Path -LiteralPath $envFile)) {
        return ''
    }

    foreach ($line in Get-Content -LiteralPath $envFile) {
        if ($line -match '^\s*GOOGLE_CLIENT_ID\s*=\s*(.*)\s*$') {
            return $matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ''
}

Write-Step 'Mengecek MySQL Laragon'
if (Test-TcpPort -HostName '127.0.0.1' -Port 3306) {
    Write-Ok 'MySQL sudah aktif di port 3306.'
} elseif (Test-Path -LiteralPath $mysqlExe) {
    Write-Step 'Menyalakan MySQL Laragon'
    $mysqlArgs = @()
    if (Test-Path -LiteralPath $mysqlIni) {
        $mysqlArgs += "--defaults-file=$mysqlIni"
    }
    Start-Process -FilePath $mysqlExe -ArgumentList $mysqlArgs -WorkingDirectory (Split-Path -Parent $mysqlExe) -WindowStyle Hidden
    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        if (Test-TcpPort -HostName '127.0.0.1' -Port 3306) {
            Write-Ok 'MySQL berhasil aktif.'
            break
        }
    }
    if (-not (Test-TcpPort -HostName '127.0.0.1' -Port 3306)) {
        Write-Warn 'MySQL belum terdeteksi. Buka Laragon lalu klik Start All.'
    }
} else {
    Write-Warn 'File mysqld Laragon tidak ditemukan. Buka Laragon lalu klik Start All.'
}

Write-Step 'Mengecek Backend API AHEAD'
if (Test-Backend) {
    Write-Ok 'Backend API sudah aktif di http://127.0.0.1:8000.'
} else {
    if (-not (Test-Path -LiteralPath $phpExe)) {
        $phpCommand = Get-Command php -ErrorAction SilentlyContinue
        if ($phpCommand) {
            $phpExe = $phpCommand.Source
        }
    }

    if (Test-Path -LiteralPath $phpExe) {
        Write-Step 'Menyalakan Backend API AHEAD'
        Start-Process -FilePath $phpExe -ArgumentList @('-S', '127.0.0.1:8000', '-t', 'backend/public') -WorkingDirectory $appDir -WindowStyle Hidden
        for ($i = 0; $i -lt 10; $i++) {
            Start-Sleep -Seconds 1
            if (Test-Backend) {
                Write-Ok 'Backend API berhasil aktif.'
                break
            }
        }
    }

    if (-not (Test-Backend)) {
        Write-Warn 'Backend API belum aktif. Pastikan PHP Laragon tersedia dan port 8000 tidak dipakai aplikasi lain.'
    }
}

$googleClientId = Get-GoogleClientId
$flutterArgs = @('run', '-d', 'chrome', '--web-port', $webPort)
if ($googleClientId) {
    $flutterArgs += "--dart-define=GOOGLE_CLIENT_ID=$googleClientId"
    Write-Ok 'GOOGLE_CLIENT_ID ditemukan dan akan dikirim ke Flutter.'
} else {
    Write-Warn 'GOOGLE_CLIENT_ID masih kosong. Login Google asli baru aktif setelah Client ID diisi di backend\.env.'
}

Write-Step "Menjalankan Flutter web di http://localhost:$webPort"
Write-Host ''
& flutter @flutterArgs
