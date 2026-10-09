param([string]$GodotPath = '')
$ErrorActionPreference = 'Stop'
$projectDir = Split-Path $PSScriptRoot -Parent
$repoDir = Split-Path $projectDir -Parent
if (!$GodotPath) { $GodotPath = Join-Path $repoDir '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe' }
$reportDir = Join-Path $projectDir 'reports/prototype_20261009'
$tempDir = Join-Path $repoDir '.tools/prototype_regression'
New-Item -ItemType Directory -Force -Path $reportDir,$tempDir,(Join-Path $reportDir 'legacy_lab') | Out-Null
function Invoke-Check([string]$Script, [string]$Log, [bool]$Headless = $false) {
    $engineArgs = @('--path', $projectDir, '--script', $Script)
    if ($Headless) { $engineArgs += '--headless' }
    & $GodotPath @engineArgs *> (Join-Path $reportDir $Log)
    if ($LASTEXITCODE -ne 0) { throw "Godot failed: $Script. See $Log" }
    Get-Content (Join-Path $reportDir $Log) -Tail 2
}
Invoke-Check 'res://tests/export_prototype_20261009.gd' 'config.log' $true
Invoke-Check 'res://tests/test_prototype_20261009.gd' 'model.log' $true
Invoke-Check 'res://tests/test_prototype_ui_20261009.gd' 'ui.log'
Invoke-Check 'res://tests/test_demo.gd' 'formal_model.log' $true
$source = Get-Content (Join-Path $PSScriptRoot 'test_3d_scene.gd') -Raw -Encoding UTF8
$source = $source.Replace('reports/merge_cat1new_928','reports/prototype_20261009/formal_3d')
$threeD = Join-Path $tempDir 'test_3d_scene.gd'
[IO.File]::WriteAllText($threeD,$source,[Text.UTF8Encoding]::new($false))
Invoke-Check $threeD 'formal_3d.log'
$source = Get-Content (Join-Path $PSScriptRoot 'test_lab_004.gd') -Raw -Encoding UTF8
$source = $source.Replace('res://reports/lab_004/isolated.save','res://reports/lab_004/prototype_20261009_isolated.save')
$source = $source.Replace('res://reports/lab_004/','res://reports/prototype_20261009/legacy_lab/')
# Lab's existing safety guard only permits test saves below reports/lab_004.
$source = $source.Replace('res://reports/prototype_20261009/legacy_lab/prototype_20261009_isolated.save','res://reports/lab_004/prototype_20261009_isolated.save')
$legacy = Join-Path $tempDir 'test_lab_004.gd'
[IO.File]::WriteAllText($legacy,$source,[Text.UTF8Encoding]::new($false))
try { Invoke-Check $legacy 'legacy_lab.log' }
finally {
    foreach ($suffix in @('', '.bak', '.tmp')) {
        $isolated = Join-Path $projectDir ('reports/lab_004/prototype_20261009_isolated.save' + $suffix)
        if (Test-Path -LiteralPath $isolated) { Remove-Item -LiteralPath $isolated }
    }
}
