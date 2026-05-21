# --------------------------------------------
# Convert audio to mono with metadata preserved
# --------------------------------------------

# Check input
if ($args.Count -lt 1) {
    Write-Error "No input file specified."
    exit 1
}

$InputFile = $args[0]

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

# Build output filename (append " (mono)")
$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Suffix " (mono)"

Write-Output "Converting to mono:"
Write-Output "Input:  $InputFile"
Write-Output "Output: $OutputFile"

# FFmpeg options
$Options = @("-ac", "1", "-map_metadata", "0")   # mono + preserve metadata

# Run FFmpeg
& $FFmpeg -y -i $InputFile $Options $OutputFile

#Pause
