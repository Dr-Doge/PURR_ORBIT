param([switch]$ModelOnly)
$ErrorActionPreference='Stop'
$furWorkspace=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$furProject=Join-Path $furWorkspace '毛球满屋'
$furEngine=Join-Path $furWorkspace '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
$furReport=Join-Path $furProject 'reports/grooming_fur_activation_20261016'
New-Item -ItemType Directory -Force -Path $furReport | Out-Null
$furModelOutput=& $furEngine --headless --path $furProject --script res://tests/test_grooming_fur.gd 2>&1
$furModelOutput | Set-Content -LiteralPath (Join-Path $furReport 'model_stdout.txt') -Encoding utf8
if ($LASTEXITCODE -ne 0 -or ($furModelOutput -join "`n") -match 'SCRIPT ERROR|ERROR:' -or ($furModelOutput -join "`n") -notmatch '30 checks; 0 failures') {throw 'Fur model checks failed; see report.'}
# Old service/sizes scripts tested four alternating edge strokes and upward-tail
# input. Keep their historical evidence; activation replaces these requirements.
if (-not $ModelOnly) {
 foreach ($furSuite in @('ui','tool','feedback','activation')) {
  $furProcess=Start-Process -FilePath $furEngine -ArgumentList @('--path',('"'+$furProject+'"'),'--rendering-method','gl_compatibility','--script',('res://tests/test_grooming_fur_'+$furSuite+'.gd')) -WindowStyle Hidden -RedirectStandardOutput (Join-Path $furReport ($furSuite+'_stdout.txt')) -RedirectStandardError (Join-Path $furReport ($furSuite+'_stderr.txt')) -PassThru
  if (-not $furProcess.WaitForExit(60000)) {$furProcess.Kill();throw ($furSuite+' checks timed out.')}
  $furOutput=Get-Content -LiteralPath (Join-Path $furReport ($furSuite+'_stdout.txt')) -Raw
  $furErrors=Get-Content -LiteralPath (Join-Path $furReport ($furSuite+'_stderr.txt')) -Raw
  if ($furProcess.ExitCode -ne 0 -or $furErrors -match 'SCRIPT ERROR|ERROR:' -or $furOutput -notmatch 'checks; 0 failures') {throw ($furSuite+' checks failed; see report.')}
 }
}
Write-Output 'Fur Demo checks passed.'