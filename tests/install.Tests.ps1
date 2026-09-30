# Run with pwsh on any platform. COM is faked; only temporary files are changed.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('scale-monitor tests ' + [guid]::NewGuid())
$toolsDir = Join-Path $testRoot 'tools'
$appData = Join-Path $testRoot 'AppData'
$programsDir = Join-Path $appData 'Microsoft/Windows/Start Menu/Programs'
$oldOS = $env:OS
$oldAppData = $env:APPDATA
$state = [pscustomobject]@{ Shortcuts = @{}; SaveCount = 0 }

function Assert($condition, $message) {
    if (-not $condition) { throw $message }
}

# Exercise the real scripts without WScript.Shell or a Windows desktop.
function New-Object {
    param([string]$ComObject)
    Assert ($ComObject -eq 'WScript.Shell') "Unexpected COM object: $ComObject"
    $shell = [pscustomobject]@{}
    $shell | Add-Member -MemberType ScriptMethod -Name CreateShortcut -Value {
        param($path)
        if ($state.Shortcuts.ContainsKey($path)) { return $state.Shortcuts[$path] }
        $shortcut = [pscustomobject]@{
            Path = $path
            TargetPath = ''
            Arguments = ''
            WorkingDirectory = ''
            Description = ''
            IconLocation = ''
        }
        $shortcut | Add-Member -MemberType ScriptMethod -Name Save -Value {
            Set-Content -LiteralPath $this.Path -Value 'fake shortcut'
            $state.SaveCount++
        }
        $state.Shortcuts[$path] = $shortcut
        return $shortcut
    }
    return $shell
}

try {
    $env:OS = 'Windows_NT'
    $env:APPDATA = $appData
    New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
    $otherTool = Join-Path $toolsDir 'Other Tool.lnk'
    Set-Content -LiteralPath $otherTool -Value 'keep this'

    & (Join-Path $repoRoot 'install.ps1') -ToolsDir $toolsDir
    $paths = @(
        (Join-Path $toolsDir 'Scale Monitor.lnk'),
        (Join-Path $programsDir 'Scale Monitor.lnk')
    )
    foreach ($path in $paths) {
        Assert (Test-Path -LiteralPath $path) "Missing shortcut: $path"
        $sc = $state.Shortcuts[$path]
        Assert ($sc.TargetPath -eq 'wscript.exe') 'GUI shortcut must use the silent VBS launcher'
        Assert ($sc.Arguments -eq ('"' + (Join-Path $repoRoot 'scale-monitor.vbs') + '"')) 'Launcher path must be quoted and point into this clone'
        Assert ($sc.WorkingDirectory -eq $repoRoot) 'Shortcut must use the standalone repo'
        Assert ($sc.IconLocation -eq '%SystemRoot%\System32\imageres.dll,109') 'Keep the original Windows monitor icon'
    }

    & (Join-Path $repoRoot 'install.ps1') -ToolsDir $toolsDir
    Assert ($state.SaveCount -eq 4) 'A second install must refresh both shortcuts'
    Assert ((Get-ChildItem -LiteralPath $toolsDir).Count -eq 2) 'Install must not add stubs or other artifacts'

    & (Join-Path $repoRoot 'uninstall.ps1') -ToolsDir $toolsDir
    foreach ($path in $paths) {
        Assert (-not (Test-Path -LiteralPath $path)) "Shortcut not removed: $path"
    }
    Assert ((Get-Content -LiteralPath $otherTool) -eq 'keep this') 'Uninstall must preserve other tools'
    & (Join-Path $repoRoot 'uninstall.ps1') -ToolsDir $toolsDir

    # A shortcut replaced by another app or another clone is no longer ours to delete.
    & (Join-Path $repoRoot 'install.ps1') -ToolsDir $toolsDir
    $state.Shortcuts[$paths[0]].Arguments = '"C:\another clone\scale-monitor.vbs"'
    $state.Shortcuts[$paths[1]].TargetPath = 'another-app.exe'
    & (Join-Path $repoRoot 'uninstall.ps1') -ToolsDir $toolsDir
    foreach ($path in $paths) {
        Assert (Test-Path -LiteralPath $path) 'Uninstall must preserve shortcuts that no longer point at this clone'
    }
    Write-Host 'PASS: shortcut targets, quoting, repeat install/uninstall, and ownership checks'
} finally {
    $env:OS = $oldOS
    $env:APPDATA = $oldAppData
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
