param([string]$Engine = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $projectRoot
if (-not $Engine) { $Engine = Join-Path $workspaceRoot '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe' }
$reportRoot = Join-Path $projectRoot 'reports/lab_004'
$scratchRoot = Join-Path $workspaceRoot '.tools/lab_004_regression'
New-Item -ItemType Directory -Force -Path $reportRoot, $scratchRoot, (Join-Path $reportRoot 'formal') | Out-Null
function Get-FormalHashes {
    $saveRoot = Join-Path $env:APPDATA 'PurrOrbitDemo'
    $hashes = @{}
    if (Test-Path -LiteralPath $saveRoot) {
        Get-ChildItem -LiteralPath $saveRoot -File -Filter 'space_cats_v27.save*' | ForEach-Object {
            $hashes[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    }
    return $hashes
}
$externalGames = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -match "Godot|PurrOrbit" -and $_.CommandLine -notmatch "(?:^|\s)--editor(?:\s|$)"
} | Select-Object ProcessId, Name, CreationDate)
$before = Get-FormalHashes
# Redirect copies, preserving the historical test scripts and their evidence.
foreach ($name in @('test_september23.gd', 'test_3d_scene.gd')) {
    $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot $name) -Raw -Encoding UTF8
    $source.Replace('res://reports/merge_cat1new_928', 'res://reports/lab_004/formal') |
        Set-Content -LiteralPath (Join-Path $scratchRoot $name) -Encoding UTF8
}
$cases = @(
    @{Name='test'; Script='res://tests/test_lab_004.gd'; Headless=$false},
    @{Name='base_model'; Script='res://tests/test_demo.gd'; Headless=$true},
    @{Name='formal_mechanics'; Script=(Join-Path $scratchRoot 'test_september23.gd'); Headless=$true},
    @{Name='formal_3d'; Script=(Join-Path $scratchRoot 'test_3d_scene.gd'); Headless=$false}
)
foreach ($case in $cases) {
    $arguments = @('--path', $projectRoot, '--script', $case.Script)
    if ($case.Headless) { $arguments += '--headless' }
    $log = Join-Path $reportRoot ($case.Name + '.log')
    & $Engine @arguments *> $log
    $exitCode = $LASTEXITCODE
    Get-Content -LiteralPath $log
    if ($exitCode -ne 0) { throw "Failed: $($case.Name), exit $exitCode" }
}
$after = Get-FormalHashes
$unchanged = $before.Count -eq $after.Count
foreach ($name in $before.Keys) { if ($before[$name] -ne $after[$name]) { $unchanged = $false } }
$status = if ($unchanged) { "unchanged" } elseif ($externalGames.Count -gt 0) { "inconclusive_external_game_running" } else { "unexpected_change" }
@{status=$status; unchanged=$unchanged; before=$before; after=$after; externalGames=$externalGames} | ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath (Join-Path $reportRoot 'formal_save_integrity.json') -Encoding UTF8
if ($status -eq 'unexpected_change') { throw 'Formal save files changed during verification.' }
if ($status -eq 'inconclusive_external_game_running') { Write-Output 'Formal save comparison is inconclusive: a pre-existing game is running. Its process and progress were left intact.' }
