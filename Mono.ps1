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

$InputExt  = [System.IO.Path]::GetExtension($InputFile)
$InputName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$InputDir  = Split-Path $InputFile

# Build output filename (append " (mono)")
$OutputFile = Join-Path $InputDir "$InputName (mono)$InputExt"

Write-Output "Converting to mono:"
Write-Output "Input:  $InputFile"
Write-Output "Output: $OutputFile"

# FFmpeg options
$Options = "-ac 1 -map_metadata 0"   # mono + preserve metadata
$OptionArray = $Options -split ' '    # split into array for & invocation

# Run FFmpeg
& $FFmpeg -y -i $InputFile $OptionArray $OutputFile

#Pause
