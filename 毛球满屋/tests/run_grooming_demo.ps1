param([switch]$SkipGraphics)
$ErrorActionPreference='Stop'
$groomProject=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspace=(Resolve-Path (Join-Path $groomProject '..')).Path
$groomEngine=Join-Path $workspace '.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $groomEngine)) { throw '找不到Godot4.7.1，请核对.tools/godot-4.7.1。' }
$groomReport=Join-Path $groomProject 'reports/grooming_v2_20261015'
New-Item -ItemType Directory -Path $groomReport -Force | Out-Null
& $groomEngine --headless --path $groomProject --script res://tests/test_grooming_v2.gd
if ($LASTEXITCODE -ne 0) { throw '美容模型验证失败。' }
if (-not $SkipGraphics) {
 $groomProcess=Start-Process -FilePath $groomEngine -ArgumentList @('--path',('"'+$groomProject+'"'),'--script','res://tests/test_grooming_v2_ui.gd','--rendering-method','gl_compatibility','--audio-driver','Dummy') -WindowStyle Hidden -RedirectStandardOutput (Join-Path $groomReport 'ui_stdout.txt') -RedirectStandardError (Join-Path $groomReport 'ui_stderr.txt') -PassThru
 $groomDeadline=(Get-Date).AddMinutes(3)
 while (-not $groomProcess.WaitForExit(10000)) {
  if ((Get-Date) -gt $groomDeadline) { Stop-Process -Id $groomProcess.Id; throw '图形验证超时。' }
 }
 $groomProcess.Refresh()
 Get-Content -LiteralPath (Join-Path $groomReport 'ui_stdout.txt')
 $groomErrors=Get-Content -LiteralPath (Join-Path $groomReport 'ui_stderr.txt') -Raw
 if ($groomProcess.ExitCode -ne 0 -or $groomErrors -match 'ERROR:') { throw $groomErrors }
}
