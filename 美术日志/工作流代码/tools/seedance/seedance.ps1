param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('models', 'preview', 'submit', 'status', 'wait')]
    [string]$Action,
    [string]$Prompt,
    [string]$Image,
    [string]$TaskId,
    [string]$Model = 'doubao-seedance-2-0-fast-260128',
    [ValidateSet('480p', '720p', '1080p')]
    [string]$Resolution = '720p',
    [ValidateSet('1:1', '16:9', '9:16', '4:3', '3:4', '21:9', 'adaptive')]
    [string]$Ratio = '1:1',
    [ValidateRange(2, 30)]
    [int]$Duration = 5,
    [switch]$GenerateAudio,
    [switch]$Watermark,
    [string]$OutputDirectory = 'output/seedance',
    [ValidateRange(2, 60)]
    [int]$PollSeconds = 8,
    [ValidateRange(30, 3600)]
    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = 'Stop'
$baseUrl = 'https://ark.cn-beijing.volces.com/api/v3'

function Get-ArkApiKey {
    $key = $env:ARK_API_KEY
    if ([string]::IsNullOrWhiteSpace($key)) {
        $key = [Environment]::GetEnvironmentVariable('ARK_API_KEY', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($key)) {
        throw 'ARK_API_KEY was not found in the process or user environment.'
    }
    return $key
}

function Get-Headers {
    return @{
        Authorization = ('Bearer ' + (Get-ArkApiKey))
        'Content-Type' = 'application/json'
    }
}

function Convert-ImageToInput([string]$PathOrUrl) {
    if ([string]::IsNullOrWhiteSpace($PathOrUrl)) { return $null }
    if ($PathOrUrl -match '^https?://') { return $PathOrUrl }
    $resolved = (Resolve-Path -LiteralPath $PathOrUrl).Path
    $extension = [IO.Path]::GetExtension($resolved).ToLowerInvariant()
    $mime = switch ($extension) {
        '.png'  { 'image/png' }
        '.jpg'  { 'image/jpeg' }
        '.jpeg' { 'image/jpeg' }
        '.webp' { 'image/webp' }
        default { throw "Unsupported reference image format: $extension" }
    }
    $encoded = [Convert]::ToBase64String([IO.File]::ReadAllBytes($resolved))
    return "data:$mime;base64,$encoded"
}

function New-RequestBody {
    if ([string]::IsNullOrWhiteSpace($Prompt)) { throw 'preview and submit require -Prompt.' }
    $content = [Collections.Generic.List[object]]::new()
    $content.Add([ordered]@{ type = 'text'; text = $Prompt })
    $imageInput = Convert-ImageToInput $Image
    if ($null -ne $imageInput) {
        $content.Add([ordered]@{ type = 'image_url'; image_url = [ordered]@{ url = $imageInput } })
    }
    return [ordered]@{
        model = $Model
        content = $content
        resolution = $Resolution
        ratio = $Ratio
        duration = $Duration
        generate_audio = [bool]$GenerateAudio
        watermark = [bool]$Watermark
    }
}

function Invoke-JsonRequest([string]$Method, [string]$Uri, $Body = $null) {
    $arguments = @{
        Method = $Method
        Uri = $Uri
        Headers = (Get-Headers)
        TimeoutSec = 60
    }
    if ($null -ne $Body) {
        $arguments.Body = ($Body | ConvertTo-Json -Depth 12 -Compress)
    }
    return Invoke-RestMethod @arguments
}

function Get-Task([string]$Id) {
    if ([string]::IsNullOrWhiteSpace($Id)) { throw 'status and wait require -TaskId.' }
    return Invoke-JsonRequest 'Get' "$baseUrl/contents/generations/tasks/$Id"
}

switch ($Action) {
    'models' {
        $response = Invoke-JsonRequest 'Get' "$baseUrl/models"
        $response.data | Where-Object { $_.id -match 'seedance' } | Select-Object -ExpandProperty id
    }
    'preview' {
        $body = New-RequestBody
        $safeBody = [ordered]@{
            model = $body.model
            content = $body.content
            resolution = $body.resolution
            ratio = $body.ratio
            duration = $body.duration
            generate_audio = $body.generate_audio
            watermark = $body.watermark
        }
        if ($Image -and $Image -notmatch '^https?://') {
            $safeBody.content = @(
                [ordered]@{ type = 'text'; text = $Prompt },
                [ordered]@{ type = 'image_url'; image_url = [ordered]@{ url = "LOCAL_FILE:$Image" } }
            )
        }
        Write-Output 'PREVIEW_ONLY_NO_SUBMISSION_NO_CHARGE'
        $safeBody | ConvertTo-Json -Depth 8
    }
    'submit' {
        $body = New-RequestBody
        Write-Output "SUBMITTING_PAID_TASK=$Model/$Resolution/$Ratio/${Duration}s"
        $response = Invoke-JsonRequest 'Post' "$baseUrl/contents/generations/tasks" $body
        $response | ConvertTo-Json -Depth 12
    }
    'status' {
        (Get-Task $TaskId) | ConvertTo-Json -Depth 12
    }
    'wait' {
        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        do {
            $task = Get-Task $TaskId
            $state = if ($task.status) { $task.status } elseif ($task.state) { $task.state } else { 'unknown' }
            Write-Output ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $state)
            if ($state -match 'succeed|complete|failed|cancel') { break }
            Start-Sleep -Seconds $PollSeconds
        } while ((Get-Date) -lt $deadline)

        if ($state -notmatch 'succeed|complete') {
            $task | ConvertTo-Json -Depth 12
            if ((Get-Date) -ge $deadline) { throw 'Timed out while waiting for the task.' }
            throw "Task did not complete successfully: $state"
        }

        $json = $task | ConvertTo-Json -Depth 20 -Compress
        $match = [regex]::Match($json, 'https?:[^"\\]+\.(mp4|webm)(\?[^"\\]*)?')
        if (-not $match.Success) {
            $task | ConvertTo-Json -Depth 12
            throw 'Task succeeded, but no video URL was found in the response.'
        }
        $videoUrl = $match.Value -replace '\\u0026', '&'
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
        $outputPath = Join-Path $OutputDirectory ("seedance-{0}.mp4" -f $TaskId)
        Invoke-WebRequest -Uri $videoUrl -OutFile $outputPath -TimeoutSec 300
        Write-Output ("DOWNLOADED=" + (Resolve-Path -LiteralPath $outputPath).Path)
    }
}
