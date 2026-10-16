param([switch]$ModelOnly)
$ErrorActionPreference='Stop'
$robotProject=Split-Path $PSScriptRoot -Parent
$robotWorkspace=Split-Path $robotProject -Parent
$robotEngine=Join-Path $robotWorkspace '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
$robotReport=Join-Path $robotProject 'reports/grooming_robot_coverage_20261016'
New-Item -ItemType Directory -Force -Path $robotReport | Out-Null
$robotOutput=& $robotEngine --headless --path $robotProject --script res://tests/test_grooming_robot_random.gd 2>&1
$robotOutput | Set-Content -LiteralPath (Join-Path $robotReport 'model.log') -Encoding utf8
if ($LASTEXITCODE -ne 0 -or ($robotOutput -join "`n") -match 'SCRIPT ERROR|ERROR:' -or ($robotOutput -join "`n") -notmatch 'ROBOT RANDOM MODEL: .* checks; 0 failures') {throw 'Robot random model failed; see model.log'}
if (-not $ModelOnly) {
 $robotProcess=Start-Process -FilePath $robotEngine -ArgumentList @('--path',('"'+$robotProject+'"'),'--rendering-method','gl_compatibility','--script','res://tests/test_grooming_robot_random_ui.gd') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $robotReport 'ui.log') -RedirectStandardError (Join-Path $robotReport 'ui_stderr.log') -PassThru
 if (-not $robotProcess.WaitForExit(60000)) {$robotProcess.Kill();throw 'Robot GUI validation timed out.'}
 $robotOutput=Get-Content -LiteralPath (Join-Path $robotReport 'ui.log') -Raw
 $robotErrors=Get-Content -LiteralPath (Join-Path $robotReport 'ui_stderr.log') -Raw
 if ($robotProcess.ExitCode -ne 0 -or $robotErrors -match 'SCRIPT ERROR|ERROR:' -or $robotOutput -notmatch 'ROBOT RANDOM UI: .* checks; 0 failures') {throw 'Robot GUI validation failed; see ui logs'}
}
Write-Output 'Robot random dirt checks passed.'
