[CmdletBinding()]
param(
    [string]$ModelRepo = "MaziyarPanahi/Qwen3-4B-Thinking-2507-GGUF",
    [string]$ModelFile = "Qwen3-4B-Thinking-2507.Q4_K_M.gguf",
    [int]$Port = 8080,
    [int]$ContextSize = 8192,
    [switch]$DownloadOnly
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = $PSScriptRoot
$modelsDir = Join-Path $root "models"
$llamafilePath = Join-Path $root "llamafile.exe"
$versionPath = Join-Path $root ".llamafile-version"
$modelPath = Join-Path $modelsDir $ModelFile

New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null

$release = Invoke-RestMethod -Uri "https://api.github.com/repos/mozilla-ai/llamafile/releases/latest" -Headers @{ "User-Agent" = "llama-local-setup" }
$installedVersion = if (Test-Path $versionPath) { (Get-Content $versionPath -Raw).Trim() } else { "" }

if (-not (Test-Path $llamafilePath) -or $installedVersion -ne $release.tag_name) {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        $zipAsset = $release.assets | Where-Object { $_.name -eq "llamafile-$($release.tag_name).zip" } | Select-Object -First 1
        $binaryAsset = $release.assets | Where-Object { $_.name -eq "llamafile-$($release.tag_name)" } | Select-Object -First 1
        $downloadedExecutable = $null

        if ($zipAsset) {
            $zipPath = Join-Path $tempDir $zipAsset.name
            Invoke-WebRequest -Uri $zipAsset.browser_download_url -OutFile $zipPath
            $extractDir = Join-Path $tempDir "extracted"
            Expand-Archive -Path $zipPath -DestinationPath $extractDir
            $downloadedExecutable = Get-ChildItem -Path $extractDir -Recurse -File |
                Where-Object { $_.Name -eq "llamafile.exe" -or $_.Name -eq "llamafile-$($release.tag_name)" -or $_.Name -eq "llamafile" } |
                Select-Object -First 1
        }

        if (-not $downloadedExecutable -and $binaryAsset) {
            $downloadedExecutable = Join-Path $tempDir "llamafile.exe"
            Invoke-WebRequest -Uri $binaryAsset.browser_download_url -OutFile $downloadedExecutable
        }

        if (-not $downloadedExecutable) {
            throw "No llamafile executable asset was found in release $($release.tag_name)."
        }

        Copy-Item -Path $downloadedExecutable -Destination $llamafilePath -Force
        Set-Content -Path $versionPath -Value $release.tag_name -NoNewline
        Write-Host "Installed llamafile $($release.tag_name)."
    }
    finally {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host "llamafile $installedVersion is already installed."
}

if (-not (Test-Path $modelPath)) {
    $encodedModelFile = [uri]::EscapeDataString($ModelFile)
    $modelUrl = "https://huggingface.co/$ModelRepo/resolve/main/$encodedModelFile`?download=true"
    Write-Host "Downloading $ModelRepo/$ModelFile ..."
    Invoke-WebRequest -Uri $modelUrl -OutFile $modelPath
}
else {
    Write-Host "Model already exists: $modelPath"
}

if ($DownloadOnly) {
    Write-Host "Downloads are ready. Run this script again without -DownloadOnly to start the server."
    return
}

Write-Host "Starting server at http://127.0.0.1:$Port (press Ctrl+C to stop)."
& $llamafilePath --model $modelPath --server --host "127.0.0.1" --port "$Port" --ctx-size "$ContextSize"