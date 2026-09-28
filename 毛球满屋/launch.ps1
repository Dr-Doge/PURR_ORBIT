param(
    [string]$Engine = "",
    [switch]$Scene3D,
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
$demoRoot = $PSScriptRoot
if (-not $Engine) {
    $Engine = Join-Path (Split-Path -Parent $demoRoot) '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
    if (-not (Test-Path -LiteralPath $Engine -PathType Leaf)) {
        $Engine = Join-Path $env:LOCALAPPDATA 'Programs/Godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
    }
}
if (-not (Test-Path -LiteralPath $Engine -PathType Leaf)) {
    throw 'Godot 4.7.1 was not found. Use launch.ps1 -Engine <path-to-Godot-4.7.1.exe>.'
}
$demoVersion = (& $Engine --headless --version | Out-String).Trim()
if ($demoVersion -notmatch '^4\.7\.1\.') {
    throw "This demo requires Godot 4.7.1. Found: $demoVersion"
}
if ($ValidateOnly) {
    Write-Output "Ready: $demoVersion"
    Write-Output "Project: $demoRoot"
    exit 0
}
if ($Scene3D) {
    & $Engine --path $demoRoot 'res://scenes/3D scene.tscn'
} else {
    & $Engine --path $demoRoot
}
exit $LASTEXITCODE
