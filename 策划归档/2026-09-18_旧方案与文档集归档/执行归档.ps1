$ErrorActionPreference = 'Stop'
$workspaceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$archiveRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$workspacePrefix = $workspaceRoot.TrimEnd('\') + '\'
$archivePrefix = $archiveRoot.TrimEnd('\') + '\'

$migrationPlan = @(
    @{ Source = '摸猫增量策划案'; Target = '摸猫增量策划案' },
    @{ Source = '地球盲盒考古'; Target = '地球盲盒考古' },
    @{ Source = 'blind-box-market\docs'; Target = 'blind-box-market\docs' },
    @{ Source = '毛球满屋\README.md'; Target = '旧原型说明\毛球满屋\README.md' },
    @{ Source = 'blind-box-market\README.md'; Target = '旧原型说明\blind-box-market\README.md' }
)

# Before any move, resolve and verify every source and destination within the named workspace.
foreach ($entry in $migrationPlan) {
    $entry.SourcePath = (Resolve-Path -LiteralPath (Join-Path $workspaceRoot $entry.Source)).ProviderPath
    $entry.TargetPath = [IO.Path]::GetFullPath((Join-Path $archiveRoot $entry.Target))
    if (-not $entry.SourcePath.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Source outside workspace' }
    if (-not $entry.TargetPath.StartsWith($archivePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Target outside archive' }
    if (Test-Path -LiteralPath $entry.TargetPath) { throw "Archive target already exists: $($entry.TargetPath)" }
    $sourceItem = Get-Item -LiteralPath $entry.SourcePath -Force
    if ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse source requires separate handling' }
    if ($sourceItem.PSIsContainer) {
        $reparseItems = @(Get-ChildItem -LiteralPath $entry.SourcePath -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
        if ($reparseItems.Count -gt 0) { throw 'Reparse children require separate handling' }
    }
    Write-Output "Verified: $($entry.SourcePath) -> $($entry.TargetPath)"
}

$stagePath = (Resolve-Path -LiteralPath (Join-Path $archiveRoot '_新文档暂存')).ProviderPath
$currentPath = [IO.Path]::GetFullPath((Join-Path $workspaceRoot '摸猫增量策划案'))
if (-not $stagePath.StartsWith($archivePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid staging path' }
if (-not $currentPath.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid current path' }
if (@(Get-ChildItem -LiteralPath $stagePath -Filter '*.md' -File).Count -ne 14) { throw 'Incomplete document set' }

$manifest = [Collections.Generic.List[object]]::new()
foreach ($entry in $migrationPlan) {
    $sourceItem = Get-Item -LiteralPath $entry.SourcePath -Force
    if ($sourceItem.PSIsContainer) { $sourceFiles = @(Get-ChildItem -LiteralPath $entry.SourcePath -Recurse -Force -File) }
    else { $sourceFiles = @($sourceItem) }
    foreach ($file in $sourceFiles) {
        if ($sourceItem.PSIsContainer) {
            $relativeName = [IO.Path]::GetRelativePath($entry.SourcePath, $file.FullName)
            $archivedPath = Join-Path $entry.TargetPath $relativeName
        } else { $archivedPath = $entry.TargetPath }
        $manifest.Add([pscustomobject]@{
            original = [IO.Path]::GetRelativePath($workspaceRoot, $file.FullName)
            archived = [IO.Path]::GetRelativePath($workspaceRoot, $archivedPath)
            bytes = $file.Length
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        })
    }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $archiveRoot '归档文件校验.json') -Encoding utf8
Copy-Item -LiteralPath (Join-Path $workspaceRoot 'AGENTS.md') -Destination (Join-Path $archiveRoot '工作空间说明_归档前.md')
$activeConfigHash = (Get-FileHash -LiteralPath (Join-Path $workspaceRoot 'active-game.json') -Algorithm SHA256).Hash

foreach ($entry in $migrationPlan) {
    $parentPath = Split-Path -Parent $entry.TargetPath
    New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    Move-Item -LiteralPath $entry.SourcePath -Destination $entry.TargetPath
}
Move-Item -LiteralPath $stagePath -Destination $currentPath

foreach ($record in $manifest) {
    $archivedFile = Join-Path $workspaceRoot $record.archived
    if (-not (Test-Path -LiteralPath $archivedFile -PathType Leaf)) { throw "Missing archived file: $archivedFile" }
    $actualFile = Get-Item -LiteralPath $archivedFile -Force
    if ($actualFile.Length -ne $record.bytes) { throw "Size mismatch: $archivedFile" }
    if ((Get-FileHash -LiteralPath $archivedFile -Algorithm SHA256).Hash -ne $record.sha256) { throw "Hash mismatch: $archivedFile" }
}
if ((Get-FileHash -LiteralPath (Join-Path $workspaceRoot 'active-game.json') -Algorithm SHA256).Hash -ne $activeConfigHash) { throw 'Startup configuration changed' }

[pscustomobject]@{
    date = '2026-09-18'
    archived_files = $manifest.Count
    archived_bytes = ($manifest | Measure-Object -Property bytes -Sum).Sum
    verification = 'All archived file sizes and SHA256 hashes match originals.'
    startup_configuration = 'Unchanged'
    current_documents = 14
    migration = @($migrationPlan | ForEach-Object { [pscustomobject]@{ original = $_.Source; archived = [IO.Path]::GetRelativePath($workspaceRoot, $_.TargetPath) } })
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $archiveRoot '归档校验结果.json') -Encoding utf8
Write-Output "Migration verified: $($manifest.Count) files preserved; 14 current documents installed."
