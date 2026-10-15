param([switch]$ModelOnly)
$ErrorActionPreference='Stop'
$furWorkspace=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$furProject=Join-Path $furWorkspace '毛球满屋'
$furEngine=Join-Path $furWorkspace '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
$furReport=Join-Path $furProject 'reports/grooming_fur_fix_20261015'
New-Item -ItemType Directory -Force -Path $furReport | Out-Null
$furModelOutput=& $furEngine --headless --path $furProject --script res://tests/test_grooming_fur.gd 2>&1
$furModelOutput | Set-Content -LiteralPath (Join-Path $furReport 'model_stdout.txt') -Encoding utf8
if ($LASTEXITCODE -ne 0 -or ($furModelOutput -join "`n") -match 'SCRIPT ERROR|ERROR:' -or ($furModelOutput -join "`n") -notmatch '30 checks; 0 failures') {throw 'Fur model checks failed; see report.'}
if (-not $ModelOnly) {
 $furProcess=Start-Process -FilePath $furEngine -ArgumentList @('--path',('"'+$furProject+'"'),'--rendering-method','gl_compatibility','--script','res://tests/test_grooming_fur_ui.gd') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $furReport 'ui_stdout.txt') -RedirectStandardError (Join-Path $furReport 'ui_stderr.txt') -PassThru
 if (-not $furProcess.WaitForExit(60000)) {$furProcess.Kill();throw 'Fur GUI checks timed out.'}
 $furOutput=Get-Content -LiteralPath (Join-Path $furReport 'ui_stdout.txt') -Raw
 $furErrors=Get-Content -LiteralPath (Join-Path $furReport 'ui_stderr.txt') -Raw
 if ($furProcess.ExitCode -ne 0 -or $furErrors -match 'SCRIPT ERROR|ERROR:' -or $furOutput -notmatch '15 checks; 0 failures') {throw 'Fur GUI checks failed; see report.'}
 $furProcess=Start-Process -FilePath $furEngine -ArgumentList @('--path',('"'+$furProject+'"'),'--rendering-method','gl_compatibility','--script','res://tests/test_grooming_fur_tool.gd') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $furReport 'tool_stdout.txt') -RedirectStandardError (Join-Path $furReport 'tool_stderr.txt') -PassThru
 if (-not $furProcess.WaitForExit(60000)) {$furProcess.Kill();throw 'Tooth edge checks timed out.'}
 $furOutput=Get-Content -LiteralPath (Join-Path $furReport 'tool_stdout.txt') -Raw
 $furErrors=Get-Content -LiteralPath (Join-Path $furReport 'tool_stderr.txt') -Raw
 if ($furProcess.ExitCode -ne 0 -or $furErrors -match 'SCRIPT ERROR|ERROR:' -or $furOutput -notmatch '33 checks; 0 failures') {throw 'Tooth edge/colour/speed checks failed; see report.'}
}
Write-Output 'Fur Demo checks passed.'
