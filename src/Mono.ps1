# --------------------------------------------
# Convert audio to mono with metadata preserved
# --------------------------------------------

# Check input
if ($args.Count -lt 1) {
    throw "Expected input file."
}

$InputFile = $args[0]

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

# Build output filename (append " (mono)")
$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Suffix " (mono)"

Write-SoundSheriffLog "Converting to mono:"
Write-SoundSheriffLog "Input:  $InputFile"
Write-SoundSheriffLog "Output: $OutputFile"

# FFmpeg options
$Options = @("-ac", "1", "-map_metadata", "0")   # mono + preserve metadata

# Run FFmpeg
Invoke-SoundSheriffFFmpeg -Arguments (@("-y", "-i", $InputFile) + $Options + @($OutputFile)) -InputFile $InputFile -Status "Converting to mono"
