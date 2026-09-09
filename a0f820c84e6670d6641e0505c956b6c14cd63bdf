$ErrorActionPreference = 'Stop'
$planRoot = 'C:\Users\ruohaojing\Desktop\爽开'
$planDocPath = Join-Path $planRoot '地球盲盒考古\策划案\地球盲盒考古_基础策划案_v0.1.docx'
$planPdfPath = Join-Path $planRoot '.report_work\earth_archaeology\render\plan.pdf'
New-Item -ItemType Directory -Force -Path (Split-Path $planPdfPath) | Out-Null
$planWord = New-Object -ComObject Word.Application
$planWord.Visible = $false
$planWord.DisplayAlerts = 0
try {
    $planDocument = $planWord.Documents.Open($planDocPath, $false, $true)
    $planDocument.Repaginate()
    $planDocument.ExportAsFixedFormat($planPdfPath, 17)
    Write-Output ('Pages: ' + $planDocument.ComputeStatistics(2))
    $planDocument.Close(0)
} finally {
    $planWord.Quit()
    [Runtime.InteropServices.Marshal]::ReleaseComObject($planWord) | Out-Null
}
