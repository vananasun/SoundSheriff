$ErrorActionPreference = "Continue"

$InstallRoot = "C:\Program Files\SoundSheriff"
$PowerShellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$RequiredFiles = @(
    "Convert.ps1",
    "ExtractAudio.ps1",
    "Mono.ps1",
    "Normalize.ps1",
    "Resample.ps1",
    "SoundSheriff.Tools.ps1",
    "bin\ffmpeg.exe",
    "bin\ffprobe.exe",
    "assets\sheriff.ico"
)
$RegistryExtensions = @(
    ".wav", ".aiff", ".flac", ".mp3", ".wma", ".opus", ".ogg", ".aac", ".m4a",
    ".mp4", ".avi", ".mov", ".webm"
)

function Write-Check {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [bool]$Passed,

        [string]$Detail
    )

    if ($Passed) {
        Write-Host "[OK]   $Name" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
    }

    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host "       $Detail"
    }
}

Write-Host "SoundSheriff diagnostics"
Write-Host ""

Write-Check "64-bit operating system" ([Environment]::Is64BitOperatingSystem) "SoundSheriff bundles 64-bit FFmpeg."
Write-Check "Windows PowerShell path" (Test-Path -LiteralPath $PowerShellPath) $PowerShellPath

$psVersionOutput = $null
if (Test-Path -LiteralPath $PowerShellPath) {
    $psVersionOutput = & $PowerShellPath -NoProfile -ExecutionPolicy Bypass -Command '$PSVersionTable.PSVersion.ToString()' 2>&1
}
Write-Check "Windows PowerShell invocation" ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($psVersionOutput)) "Version: $psVersionOutput"

foreach ($file in $RequiredFiles) {
    $fullPath = Join-Path $InstallRoot $file
    Write-Check "Installed file: $file" (Test-Path -LiteralPath $fullPath) $fullPath
}

$ffmpegPath = Join-Path $InstallRoot "bin\ffmpeg.exe"
$ffprobePath = Join-Path $InstallRoot "bin\ffprobe.exe"

if (Test-Path -LiteralPath $ffmpegPath) {
    $ffmpegVersion = & $ffmpegPath -version 2>&1 | Select-Object -First 1
    Write-Check "FFmpeg invocation" ($ffmpegVersion -like "ffmpeg version*") $ffmpegVersion
}

if (Test-Path -LiteralPath $ffprobePath) {
    $ffprobeVersion = & $ffprobePath -version 2>&1 | Select-Object -First 1
    Write-Check "FFprobe invocation" ($ffprobeVersion -like "ffprobe version*") $ffprobeVersion
}

foreach ($extension in $RegistryExtensions) {
    $registryPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\$extension\shell\Convert"
    $exists = Test-Path -LiteralPath $registryPath
    $detail = $registryPath

    if ($exists) {
        $properties = Get-ItemProperty -LiteralPath $registryPath
        $detail = "MUIVerb=$($properties.MUIVerb); Icon=$($properties.Icon)"
    }

    Write-Check "Registry entry: $extension" $exists $detail
}

Write-Host ""
Write-Host "If any registry check fails, reinstall SoundSheriff as administrator."
Write-Host "If PowerShell invocation fails, the machine may have a restrictive application-control or Group Policy configuration."
