$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$failed = $false
foreach ($file in Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter '*.ps1' -File) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref]$tokens, [ref]$parseErrors
    ) | Out-Null
    foreach ($parseError in $parseErrors) {
        Write-Host "$($file.FullName): $parseError" -ForegroundColor Red
        $failed = $true
    }
}
if ($failed) { throw 'PowerShell parse check failed.' }
Write-Host 'PASS: all PowerShell scripts parse'
