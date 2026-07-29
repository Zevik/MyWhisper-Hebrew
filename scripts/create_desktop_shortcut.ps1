# Creates a Desktop shortcut for MyWhisper (Matan Digital).
# Run: powershell -ExecutionPolicy Bypass -File scripts\create_desktop_shortcut.ps1

$root = Split-Path $PSScriptRoot -Parent
$vbs = Join-Path $root "scripts\run_mywishper.vbs"
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "MyWhisper.lnk"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = """$vbs"""
$shortcut.WorkingDirectory = $root
$shortcut.Description = "MyWhisper - Hebrew dictation"
$icon = Join-Path $root "app\assets\icon.ico"
if (Test-Path $icon) { $shortcut.IconLocation = "$icon,0" }
$shortcut.Save()

Write-Host "Desktop shortcut created successfully:" -ForegroundColor Green
Write-Host "  $shortcutPath" -ForegroundColor White
