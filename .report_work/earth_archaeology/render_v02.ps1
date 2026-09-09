$ErrorActionPreference = 'Stop'
$planRenderScript = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'render_word.ps1') -Raw
$planRenderScript = $planRenderScript.Replace('v0.1.docx', 'v0.2_精简版.docx').Replace('render\plan.pdf', 'render_v02\plan.pdf')
& ([scriptblock]::Create($planRenderScript))
