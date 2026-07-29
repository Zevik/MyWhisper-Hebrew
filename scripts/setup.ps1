# MyWhisper setup - creates a Python 3.12 venv and installs dependencies.
# Run from the project root:  powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "=== MyWhisper setup ===" -ForegroundColor Cyan

# 1. Ensure Python is available
$pyExe = $null

try {
    $check = & py -3.12 --version 2>$null
    if ($LASTEXITCODE -eq 0) { $pyExe = "py -3.12" }
} catch {}

if (-not $pyExe) {
    try {
        $check = & python --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $check -match "Python 3\.") { $pyExe = "python" }
    } catch {}
}

if (-not $pyExe) {
    $candidates = @(
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312\python.exe",
        "C:\Program Files\Python312\python.exe",
        "C:\Python312\python.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python311\python.exe",
        "C:\Program Files\Python311\python.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $pyExe = "`"$cand`""
            $env:Path += ";" + (Split-Path $cand -Parent)
            break
        }
    }
}

if (-not $pyExe) {
    Write-Host "Python 3.12 not found. Installing Python..." -ForegroundColor Yellow
    try {
        winget install -e --id Python.Python.3.12 -s winget --accept-source-agreements --accept-package-agreements | Out-Null
    } catch {
        Write-Host "Winget failed, downloading Python installer directly from python.org..." -ForegroundColor Yellow
        $pyUrl = "https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
        $pyInstaller = Join-Path $env:TEMP "python-3.12.3-amd64.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $pyUrl -OutFile $pyInstaller
        Write-Host "Installing Python 3.12..." -ForegroundColor Yellow
        Start-Process $pyInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
        Remove-Item $pyInstaller -Force -ErrorAction SilentlyContinue
    }

    $env:Path += ";C:\Program Files\Python312;C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312;C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312\Scripts"

    try {
        $check = & py -3.12 --version 2>$null
        if ($LASTEXITCODE -eq 0) { $pyExe = "py -3.12" }
    } catch {}

    if (-not $pyExe) {
        try {
            $check = & python --version 2>$null
            if ($LASTEXITCODE -eq 0) { $pyExe = "python" }
        } catch {}
    }

    if (-not $pyExe) {
        $cand = "C:\Program Files\Python312\python.exe"
        if (Test-Path $cand) { $pyExe = "`"$cand`"" }
        $cand2 = "C:\Users\$env:USERNAME\AppData\Local\Programs\Python\Python312\python.exe"
        if (Test-Path $cand2) { $pyExe = "`"$cand2`"" }
    }

    if (-not $pyExe) {
        Write-Host "Python 3.12 installation failed. Please install Python 3.12 from python.org." -ForegroundColor Red
        exit 1
    }
}

# Detect an NVIDIA GPU once
$hasNvidia = $false
try {
    if ((Get-CimInstance Win32_VideoController -ErrorAction Stop).Name -match "NVIDIA") {
        $hasNvidia = $true
    }
} catch {}

# Default config: copy example on first install
if ((Test-Path "app\config.example.json") -and -not (Test-Path "config.json")) {
    Copy-Item "app\config.example.json" "config.json"
    Write-Host "Created config.json from app\config.example.json" -ForegroundColor Green
}

if (-not $hasNvidia -and (Test-Path "config.json")) {
    try {
        $cfg = Get-Content "config.json" -Raw | ConvertFrom-Json
        if ($cfg.device -eq "cuda") {
            $cfg.device = "cpu"
            $cfg.compute_type = "int8"
            $json = $cfg | ConvertTo-Json
            [IO.File]::WriteAllText((Join-Path $root "config.json"), $json,
                (New-Object System.Text.UTF8Encoding($false)))
            Write-Host "No NVIDIA GPU detected - config.json set to CPU mode." -ForegroundColor Yellow
        }
    } catch {}
}

# 2. Create the virtual environment
if (-not (Test-Path ".venv")) {
    Write-Host "Creating virtual environment (.venv)..." -ForegroundColor Cyan
    Invoke-Expression "$pyExe -m venv .venv"
} else {
    Write-Host ".venv already exists - reusing it." -ForegroundColor Green
}

$venvPy = Join-Path $root ".venv\Scripts\python.exe"

# 3. Upgrade pip and install dependencies
Write-Host "Upgrading pip..." -ForegroundColor Cyan
& $venvPy -m pip install --upgrade pip

Write-Host "Installing dependencies..." -ForegroundColor Cyan
& $venvPy -m pip install -r requirements.txt

if ($hasNvidia) {
    Write-Host "NVIDIA GPU detected - installing CUDA libraries..." -ForegroundColor Cyan
    & $venvPy -m pip install -r requirements-cuda.txt
} else {
    Write-Host "No NVIDIA GPU detected - skipping CUDA libraries (transcription will run on CPU)." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Setup complete ===" -ForegroundColor Green
