[CmdletBinding()]
param(
    [string]$ToolsDir = 'C:\dev\tools'
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') {
    throw 'scale-monitor uninstalls on Windows only.'
}

$vbsPath = Join-Path $PSScriptRoot 'scale-monitor.vbs'
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$wsh = New-Object -ComObject WScript.Shell
foreach ($shortcutPath in @(
    (Join-Path $ToolsDir 'Scale Monitor.lnk'),
    (Join-Path $startMenuDir 'Scale Monitor.lnk')
)) {
    if (-not (Test-Path -LiteralPath $shortcutPath)) { continue }
    $sc = $wsh.CreateShortcut($shortcutPath)
    # The user may have repointed this shortcut or installed from another clone.
    if ((Split-Path -Leaf $sc.TargetPath) -ieq 'wscript.exe' -and $sc.Arguments -eq "`"$vbsPath`"") {
        Remove-Item -LiteralPath $shortcutPath -Force
        Write-Host "  Removed $shortcutPath" -ForegroundColor Green
    } else {
        Write-Host "  Kept $shortcutPath because it no longer points at this clone." -ForegroundColor Yellow
    }
}

Write-Host 'Uninstalled shortcuts. Unpin Scale Monitor from the taskbar manually if needed.'
