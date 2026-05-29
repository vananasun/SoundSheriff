# ------------------------------
# Two-pass loudnorm normalization
# ------------------------------

if ($args.Count -lt 1) {
    throw "Expected input file."
}

$InputFile = $args[0]
if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

# Paths
$InputExt  = [System.IO.Path]::GetExtension($InputFile)

# Output file
$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Suffix " (-14 LUFS)"

Write-SoundSheriffLog "Input:  $InputFile"
Write-SoundSheriffLog "Output: $OutputFile"

# --- First pass: measure loudness ---
$TargetLUFS = "-14"
$TruePeak   = "-1"
$LRA        = "11" #dummy, won't actually be used, otherwise ffmpeg switches to dynamic gain mode

$Filter1 = "loudnorm=I=${TargetLUFS}:TP=${TruePeak}:LRA=${LRA}:print_format=json"

# Run ffmpeg first pass and capture stderr (JSON is printed there)
$ffmpegOutputText = Invoke-SoundSheriffFFmpeg -Arguments @("-hide_banner", "-i", $InputFile, "-af", $Filter1, "-f", "null", "-") -InputFile $InputFile -ProgressStart 0 -ProgressEnd 50 -Status "Analyzing loudness" -CaptureOutput

# Extract last JSON block
$jsonMatches = [regex]::Matches($ffmpegOutputText, '\{[^\}]*\}')
if ($jsonMatches.Count -eq 0) {
    throw "Could not find loudnorm JSON output."
}
$loudnormJson = $jsonMatches[$jsonMatches.Count - 1].Value

# Parse JSON
$loudnorm = $loudnormJson | ConvertFrom-Json

$measured_I      = $loudnorm.input_i
$measured_TP     = $loudnorm.input_tp
$measured_LRA    = $loudnorm.input_lra
$measured_thresh = $loudnorm.input_thresh
$offset          = $loudnorm.target_offset

Write-SoundSheriffLog "Measured values:"
Write-SoundSheriffLog "Input Integrated: $measured_I LUFS"
Write-SoundSheriffLog "Input True Peak:  $measured_TP dBTP"
Write-SoundSheriffLog "Input LRA:        $measured_LRA LU"
Write-SoundSheriffLog "Input Threshold:  $measured_thresh LUFS"
Write-SoundSheriffLog "Target Offset:    $offset LU"
Write-SoundSheriffLog ""

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


Write-SoundSheriffLog "Running second pass..."
Write-SoundSheriffLog ($ffmpegArgs -join " ")
Invoke-SoundSheriffFFmpeg -Arguments $ffmpegArgs -InputFile $InputFile -ProgressStart 50 -ProgressEnd 100 -Status "Writing normalized file"

Write-SoundSheriffLog "Done! Output file: $OutputFile"
