# ------------------------------
# Two-pass loudnorm normalization
# ------------------------------

$InputFile = $args[0]
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

# Paths
$InputDir  = Split-Path $InputFile
$InputName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$InputExt  = [System.IO.Path]::GetExtension($InputFile)

# Output file
$OutputFile = Join-Path $InputDir "$InputName (-14 LUFS)$InputExt"

Write-Host "Input:  $InputFile"
Write-Host "Output: $OutputFile"

# --- First pass: measure loudness ---
$TargetLUFS = "-14"
$TruePeak   = "-1"
$LRA        = "11" #dummy, won't actually be used, otherwise ffmpeg switches to dynamic gain mode

$Filter1 = "loudnorm=I=${TargetLUFS}:TP=${TruePeak}:LRA=${LRA}:print_format=json"

# Run ffmpeg first pass and capture stderr (JSON is printed there)
$ffmpegOutputText = & $FFmpeg -hide_banner -i $InputFile -af $Filter1 -f null - 2>&1 | Out-String

# Extract last JSON block
$jsonMatches = [regex]::Matches($ffmpegOutputText, '\{[^\}]*\}')
if ($jsonMatches.Count -eq 0) {
    Write-Error "Could not find loudnorm JSON output"
    Pause
    exit 1
}
$loudnormJson = $jsonMatches[$jsonMatches.Count - 1].Value

# Parse JSON
$loudnorm = $loudnormJson | ConvertFrom-Json

$measured_I      = $loudnorm.input_i
$measured_TP     = $loudnorm.input_tp
$measured_LRA    = $loudnorm.input_lra
$measured_thresh = $loudnorm.input_thresh
$offset          = $loudnorm.target_offset

Write-Host "Measured values:"
Write-Host "Input Integrated: $measured_I LUFS"
Write-Host "Input True Peak:  $measured_TP dBTP"
Write-Host "Input LRA:        $measured_LRA LU"
Write-Host "Input Threshold:  $measured_thresh LUFS"
Write-Host "Target Offset:    $offset LU"
Write-Host "\n"

# --- Second pass: apply normalization ---
$Filter2 = "loudnorm=I=${TargetLUFS}:TP=${TruePeak}:LRA=${measured_LRA}:" +
           "measured_I=${measured_I}:measured_TP=${measured_TP}:" +
           "measured_LRA=${measured_LRA}:measured_thresh=${measured_thresh}:" +
           "offset=${offset}:linear=true:dual_mono=true:print_format=summary"

$ffmpegArgs = @(
    "-hide_banner", "-y", # global options
    "-i", $InputFile,
    "-af", $Filter2,
    "-map_metadata", "0"  # preserve metadata
)

if ($InputExt -eq ".flac") {
    $ffmpegArgs += @("-c:a", "flac", "-compression_level", "12", "-sample_fmt", "s16")
}

$ffmpegArgs += $OutputFile


Write-Host "Running second pass..."
Write-Host $ffmpegArgs
& $FFmpeg @ffmpegArgs

Write-Host "Done! Output file: $OutputFile"
Pause
