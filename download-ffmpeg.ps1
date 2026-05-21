$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DownloadDir = Join-Path $ProjectRoot "downloads"
$BinDir = Join-Path $ProjectRoot "bin"
$LicenseDir = Join-Path $ProjectRoot "licenses"
$Archive = Join-Path $DownloadDir "ffmpeg-release-essentials.zip"
$ExpectedSha256 = "6F58CE889F59C311410F7D2B18895B33C03456463486F3B1EBC93D97A0F54541"
$Url = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"

New-Item -ItemType Directory -Force -Path $DownloadDir, $BinDir, $LicenseDir | Out-Null

Write-Host "Downloading FFmpeg..."
Invoke-WebRequest -Uri $Url -OutFile $Archive

$ActualSha256 = (Get-FileHash -Path $Archive -Algorithm SHA256).Hash
if ($ActualSha256 -ne $ExpectedSha256) {
    throw "FFmpeg archive checksum mismatch. Expected $ExpectedSha256 but got $ActualSha256."
}

$ExtractDir = Join-Path $DownloadDir "ffmpeg-release-essentials"
if (Test-Path -LiteralPath $ExtractDir) {
    Remove-Item -LiteralPath $ExtractDir -Recurse -Force
}

Expand-Archive -Path $Archive -DestinationPath $ExtractDir -Force
$PackageRoot = Get-ChildItem -LiteralPath $ExtractDir -Directory | Select-Object -First 1

Copy-Item -LiteralPath (Join-Path $PackageRoot.FullName "bin\ffmpeg.exe") -Destination (Join-Path $BinDir "ffmpeg.exe") -Force
Copy-Item -LiteralPath (Join-Path $PackageRoot.FullName "bin\ffprobe.exe") -Destination (Join-Path $BinDir "ffprobe.exe") -Force
Copy-Item -LiteralPath (Join-Path $PackageRoot.FullName "LICENSE") -Destination (Join-Path $LicenseDir "FFmpeg-LICENSE.txt") -Force
Copy-Item -LiteralPath (Join-Path $PackageRoot.FullName "README.txt") -Destination (Join-Path $LicenseDir "FFmpeg-README.txt") -Force

Remove-Item -LiteralPath $DownloadDir -Recurse -Force

Write-Host "Installed FFmpeg tools into $BinDir"
