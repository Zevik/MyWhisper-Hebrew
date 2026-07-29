# Creates a Desktop shortcut for MyWhisper.
# Run: powershell -ExecutionPolicy Bypass -File scripts\create_desktop_shortcut.ps1

$root = Split-Path $PSScriptRoot -Parent
$pythonw = Join-Path $root ".venv\Scripts\pythonw.exe"
$mainPy = Join-Path $root "app\main.py"
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "MyWhisper.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $pythonw
$shortcut.Arguments = """$mainPy"""
$shortcut.WorkingDirectory = $root
$shortcut.Description = "MyWhisper - Hebrew dictation"
$icon = Join-Path $root "app\assets\icon.ico"
if (Test-Path $icon) { $shortcut.IconLocation = "$icon,0" }
$shortcut.Save()

Write-Host "Desktop shortcut created successfully:" -ForegroundColor Green
Write-Host "  $shortcutPath" -ForegroundColor White
