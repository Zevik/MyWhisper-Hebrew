# MyWhisper one-line installer.
# From any PowerShell window:
#   irm https://raw.githubusercontent.com/Zevik/MyWhisper-Hebrew/main/scripts/install.ps1 | iex

$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/Zevik/MyWhisper-Hebrew.git"
$InstallDir = Join-Path $env:USERPROFILE "MyWhisper"

# Add standard Git installation paths to current session PATH immediately
$env:Path += ";C:\Program Files\Git\cmd;C:\Program Files (x86)\Git\cmd;C:\Users\$env:USERNAME\AppData\Local\Programs\Git\cmd"

try {
    Write-Host ""
    Write-Host "=== MyWhisper installer ===" -ForegroundColor Cyan
    Write-Host "Install dir: $InstallDir" -ForegroundColor DarkGray

    # 1. Git Detection and Installation
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git not found - attempting install via winget..." -ForegroundColor Yellow
        
        try {
            winget install -e --id Git.Git -s winget --accept-source-agreements --accept-package-agreements | Out-Null
        } catch {
            Write-Host "Winget search failed, trying direct download..." -ForegroundColor DarkGray
        }

        # Refresh PATH again
        $env:Path += ";C:\Program Files\Git\cmd;C:\Program Files (x86)\Git\cmd;C:\Users\$env:USERNAME\AppData\Local\Programs\Git\cmd"

        # Direct download fallback if winget failed
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            $stdGit = "C:\Program Files\Git\cmd\git.exe"
            if (Test-Path $stdGit) {
                $env:Path += ";C:\Program Files\Git\cmd"
            } else {
                Write-Host "Downloading Git for Windows directly..." -ForegroundColor Yellow
                $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe"
                $installerPath = Join-Path $env:TEMP "Git-Installer.exe"
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $gitUrl -OutFile $installerPath
                Write-Host "Installing Git..." -ForegroundColor Yellow
                Start-Process $installerPath -ArgumentList "/VERYSILENT /NORESTART" -Wait
                $env:Path += ";C:\Program Files\Git\cmd"
            }
        }
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $stdGit = "C:\Program Files\Git\cmd\git.exe"
        if (Test-Path $stdGit) {
            $env:Path += ";C:\Program Files\Git\cmd"
        } else {
            Write-Host "Git installation failed. Please install Git manually from https://git-scm.com" -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            exit 1
        }
    }

    # Stop any running instance first
    function Stop-MyWhisper {
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -eq "pythonw.exe" -and $_.CommandLine -and
            $_.CommandLine -match "main\.py" -and $_.CommandLine -like "*$InstallDir*"
        } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    }
    Stop-MyWhisper
    Start-Sleep -Milliseconds 800

    # 2. Clone or update
    if (Test-Path (Join-Path $InstallDir ".git")) {
        Write-Host "Existing install found - updating..." -ForegroundColor Cyan
        git -C $InstallDir pull --ff-only
    } else {
        Write-Host "Cloning repository..." -ForegroundColor Cyan
        git clone $RepoUrl $InstallDir
    }

    # 3. Python 3.12 venv + dependencies
    & powershell -ExecutionPolicy Bypass -File (Join-Path $InstallDir "scripts\setup.ps1")
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Setup failed - see error messages above." -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit 1
    }

    # 4. Desktop shortcut -> silent pythonw launcher
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

    # 5. Launch the app now
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
