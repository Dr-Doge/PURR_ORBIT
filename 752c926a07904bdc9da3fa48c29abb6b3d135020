$ErrorActionPreference = 'Stop'
$reportPath = 'C:\Users\ruohaojing\Desktop\爽开\blind-box-market\docs\《摆摊卖盲盒》\06_开发与验证\项目现状与3D美术新人上手报告_2026-09-07.docx'
$previewPath = 'C:\Users\ruohaojing\Desktop\爽开\.report_work\render\report.pdf'
New-Item -ItemType Directory -Force -Path (Split-Path $previewPath) | Out-Null
$wordApp = New-Object -ComObject Word.Application
$wordApp.Visible = $false
$wordApp.DisplayAlerts = 0
try {
    $reportDoc = $wordApp.Documents.Open($reportPath, $false, $true)
    $reportDoc.Repaginate()
    $reportDoc.ExportAsFixedFormat($previewPath, 17)
    Write-Output ('Pages: ' + $reportDoc.ComputeStatistics(2))
    $reportDoc.Close(0)
} finally {
    $wordApp.Quit()
    [Runtime.InteropServices.Marshal]::ReleaseComObject($wordApp) | Out-Null
}
