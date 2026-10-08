param([int]$Port=8766,[switch]$NoBrowser)
$ErrorActionPreference='Stop'
$studioPython=Join-Path $env:USERPROFILE '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
if(-not(Test-Path -LiteralPath $studioPython)){$studioPython=(Get-Command python -ErrorAction Stop).Source}
$studioData=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../output/cat-studio'))
New-Item -ItemType Directory -Force $studioData | Out-Null
$env:ASSET_CANVAS_DATA=$studioData
$env:ASSET_CANVAS_PORT="$Port"
$studioReady=$false
try{$null=Invoke-RestMethod "http://127.0.0.1:$Port/healthz" -TimeoutSec 2;$studioReady=$true}catch{}
if(-not $studioReady){
    Start-Process -FilePath $studioPython -ArgumentList @('"'+(Join-Path $PSScriptRoot 'server.py')+'"') -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -RedirectStandardOutput (Join-Path $studioData 'server.log') -RedirectStandardError (Join-Path $studioData 'server-error.log') | Out-Null
    for($attempt=0;$attempt -lt 30;$attempt++){
        Start-Sleep -Milliseconds 300
        try{$null=Invoke-RestMethod "http://127.0.0.1:$Port/healthz" -TimeoutSec 1;$studioReady=$true;break}catch{}
    }
}
if(-not $studioReady){throw "启动失败，请查看 $studioData/server-error.log"}
Write-Output "Cat Studio: http://127.0.0.1:$Port"
if(-not $NoBrowser){Start-Process "http://127.0.0.1:$Port"}
