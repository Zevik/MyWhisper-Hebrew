# MyWhisper one-line installer.
# From any PowerShell window:
#   irm https://raw.githubusercontent.com/Zevik/MyWhisper-Hebrew/main/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/Zevik/MyWhisper-Hebrew.git"
$InstallDir = Join-Path $env:USERPROFILE "MyWhisper"

# Add standard Git installation paths to current session PATH immediately if present
$env:Path += ";C:\Program Files\Git\cmd;C:\Program Files (x86)\Git\cmd;C:\Users\$env:USERNAME\AppData\Local\Programs\Git\cmd"

try {
    Write-Host ""
    Write-Host "=== MyWhisper installer ===" -ForegroundColor Cyan
    Write-Host "Install dir: $InstallDir" -ForegroundColor DarkGray

    # Stop any running instance first so files are not locked
    function Stop-MyWhisper {
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -eq "pythonw.exe" -and $_.CommandLine -and
            $_.CommandLine -match "main\.py" -and $_.CommandLine -like "*$InstallDir*"
        } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }
    Stop-MyWhisper
    Start-Sleep -Milliseconds 800

    # 1. Download or update code (Git if available, or direct ZIP download)
    if (Get-Command git -ErrorAction SilentlyContinue) {
        if (Test-Path (Join-Path $InstallDir ".git")) {
            Write-Host "Existing install found - updating via Git..." -ForegroundColor Cyan
            git -C $InstallDir pull --ff-only
        } else {
            Write-Host "Cloning repository..." -ForegroundColor Cyan
            git clone $RepoUrl $InstallDir
        }
    } else {
        Write-Host "Downloading MyWhisper package..." -ForegroundColor Cyan
        $zipUrl = "https://github.com/Zevik/MyWhisper-Hebrew/archive/refs/heads/main.zip"
        $zipFile = Join-Path $env:TEMP "MyWhisper-main.zip"
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
        
        $cfgBackup = Join-Path $env:TEMP "mywhisper_config_backup.json"
        if (Test-Path $InstallDir) {
            $cfg = Join-Path $InstallDir "config.json"
            if (Test-Path $cfg) { Copy-Item $cfg $cfgBackup -Force }
        }

        Write-Host "Extracting files..." -ForegroundColor Cyan
        $tempExtract = Join-Path $env:TEMP "MyWhisperExtract"
        if (Test-Path $tempExtract) { Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
        Expand-Archive -Path $zipFile -DestinationPath $tempExtract -Force
        
        $extractedFolder = Join-Path $tempExtract "MyWhisper-Hebrew-main"
        if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir | Out-Null }
        
        Copy-Item -Path "$extractedFolder\*" -Destination $InstallDir -Recurse -Force
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

        if (Test-Path $cfgBackup) {
            Copy-Item $cfgBackup (Join-Path $InstallDir "config.json") -Force
            Remove-Item $cfgBackup -Force -ErrorAction SilentlyContinue
        }
    }

    # 2. Python 3.12 venv + dependencies
    & powershell -ExecutionPolicy Bypass -File (Join-Path $InstallDir "scripts\setup.ps1")
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Setup failed - see error messages above." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit 1
    }

    # 3. Desktop shortcut -> silent pythonw launcher
    $ws = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk = $ws.CreateShortcut((Join-Path $desktop "MyWhisper.lnk"))
    $pythonw = Join-Path $InstallDir ".venv\Scripts\pythonw.exe"
    $mainPy = Join-Path $InstallDir "app\main.py"
    $lnk.TargetPath = $pythonw
    $lnk.Arguments = '"' + $mainPy + '"'
    $lnk.WorkingDirectory = $InstallDir
    $lnk.Description = "MyWhisper - Hebrew dictation"
    $icon = Join-Path $InstallDir "app\assets\icon.ico"
    if (Test-Path $icon) { $lnk.IconLocation = "$icon,0" }
    $lnk.Save()

    # 4. Launch the app now
    Stop-MyWhisper
    Start-Sleep -Milliseconds 500
    if (Test-Path $pythonw) {
        Start-Process $pythonw -ArgumentList "`"$mainPy`"" -WorkingDirectory $InstallDir
    }

    Write-Host ""
    Write-Host "=== Installation complete ===" -ForegroundColor Green
    Write-Host "MyWhisper is starting... A Desktop shortcut was created." -ForegroundColor White
} catch {
    Write-Host ""
    Write-Host "An error occurred during installation:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}
