param([int]$Port=8765,[switch]$NoBrowser)
$ErrorActionPreference='Stop'
$pythonExe=Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
if(-not(Test-Path -LiteralPath $pythonExe)){
    $pythonExe=(Get-Command python -ErrorAction Stop).Source
}
$studioDir=$PSScriptRoot
$logDir=[IO.Path]::GetFullPath((Join-Path $studioDir '../../output/asset-canvas'))
New-Item -ItemType Directory -Force $logDir | Out-Null
$studioUrl="http://127.0.0.1:$Port"
$alreadyRunning=$false
try{ $null=Invoke-RestMethod "$studioUrl/api/state" -TimeoutSec 2; $alreadyRunning=$true }catch{}
if(-not $alreadyRunning){
    & $pythonExe -c 'import fastapi, uvicorn, httpx, multipart, PIL, numpy, imageio_ffmpeg'
    if($LASTEXITCODE -ne 0){
        & $pythonExe -m pip install -r (Join-Path $studioDir 'requirements.txt')
        if($LASTEXITCODE -ne 0){throw 'Dependency installation failed.'}
    }
    $env:ASSET_CANVAS_PORT="$Port"
    Start-Process -FilePath $pythonExe -ArgumentList @('"'+(Join-Path $studioDir 'server.py')+'"') -WorkingDirectory $studioDir -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logDir 'server.log') -RedirectStandardError (Join-Path $logDir 'server-error.log') | Out-Null
    for($tryCount=0;$tryCount -lt 30;$tryCount++){
        Start-Sleep -Milliseconds 300
        try{$null=Invoke-RestMethod "$studioUrl/api/state" -TimeoutSec 1;$alreadyRunning=$true;break}catch{}
    }
}
if(-not $alreadyRunning){throw "Unable to start. Inspect $logDir/server-error.log"}
$openUrl = if ($env:ASSET_CANVAS_PUBLIC_ORIGIN) { $env:ASSET_CANVAS_PUBLIC_ORIGIN } else { $studioUrl }
Write-Output "FrameStudio is ready: $openUrl"
if(-not $NoBrowser){Start-Process $openUrl}
