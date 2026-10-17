param([switch]$ModelOnly)
$ErrorActionPreference='Stop'
$furWorkspace=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$furProject=Join-Path $furWorkspace '毛球满屋'
$furEngine=Join-Path $furWorkspace '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
$furReport=Join-Path $furProject 'reports/fur_asset_cleanup_20261017'
$env:PURR_FUR_REPORT='res://reports/fur_asset_cleanup_20261017/'
New-Item -ItemType Directory -Force -Path $furReport | Out-Null
$furModelOutput=& $furEngine --headless --path $furProject --script res://tests/test_grooming_fur_tug.gd 2>&1
$furModelOutput | Set-Content -LiteralPath (Join-Path $furReport 'model_stdout.txt') -Encoding utf8
if ($LASTEXITCODE -ne 0 -or ($furModelOutput -join "`n") -match 'SCRIPT ERROR|ERROR:' -or ($furModelOutput -join "`n") -notmatch 'FUR TUG MODEL: .* checks; 0 failures') {throw 'Pure-grooming model checks failed; see report.'}
# Old one-pass/special-demand/robot/nail tests are historical, not this prototype's acceptance.
if (-not $ModelOnly) {
 $furProcess=Start-Process -FilePath $furEngine -ArgumentList @('--path',('"'+$furProject+'"'),'--rendering-method','gl_compatibility','--script','res://tests/test_grooming_fur_tug_ui.gd') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $furReport 'ui_stdout.txt') -RedirectStandardError (Join-Path $furReport 'ui_stderr.txt') -PassThru
 if (-not $furProcess.WaitForExit(60000)) {$furProcess.Kill();throw 'Pure-grooming GUI checks timed out.'}
 $furOutput=Get-Content -LiteralPath (Join-Path $furReport 'ui_stdout.txt') -Raw
 $furErrors=Get-Content -LiteralPath (Join-Path $furReport 'ui_stderr.txt') -Raw
 if ($furProcess.ExitCode -ne 0 -or $furErrors -match 'SCRIPT ERROR|ERROR:' -or $furOutput -notmatch 'FUR TUG UI: .* checks; 0 failures') {throw 'Pure-grooming GUI checks failed; see report.'}
}
Write-Output 'Pure-grooming tug checks passed.'
