# Create the same silent taskbar and Start Menu shortcuts from this clone.
[CmdletBinding()]
param(
    [string]$ToolsDir = 'C:\dev\tools'
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') {
    throw 'scale-monitor installs on Windows only.'
}

$vbsPath = Join-Path $PSScriptRoot 'scale-monitor.vbs'
if (-not (Test-Path -LiteralPath $vbsPath)) {
    throw "Launcher not found: $vbsPath"
}
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
foreach ($directory in @($ToolsDir, $startMenuDir)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$wsh = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @(
    (Join-Path $ToolsDir 'Scale Monitor.lnk'),
    (Join-Path $startMenuDir 'Scale Monitor.lnk')
)) {
    $sc = $wsh.CreateShortcut($shortcutPath)
    $sc.TargetPath = 'wscript.exe'
    $sc.Arguments = "`"$vbsPath`""
    $sc.WorkingDirectory = $PSScriptRoot
    $sc.Description = 'Change Monitor 4 scaling for normal use or filming'
    $sc.IconLocation = '%SystemRoot%\System32\imageres.dll,109'
    $sc.Save()
    Write-Host "  [lnk]  $shortcutPath" -ForegroundColor Green
}

Write-Host "Installed. Right-click '$ToolsDir\Scale Monitor.lnk' and pin it to the taskbar."
