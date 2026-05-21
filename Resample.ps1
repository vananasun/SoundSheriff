
$InputFile = $args[0]

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

$SampleRate = $args[1]

$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Suffix " ($SampleRate Hz)"

Write-Output "Input:  $InputFile"
Write-Output "Output: $OutputFile"


$Options = @("-af", "aresample=resampler=soxr", "-ar", $SampleRate, "-map_metadata", "0")

# Run FFmpeg
& $FFmpeg -y -i $InputFile $Options $OutputFile
