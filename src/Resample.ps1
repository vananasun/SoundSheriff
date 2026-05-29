
$InputFile = $args[0]

if ($args.Count -lt 2) {
    throw "Expected input file and sample rate."
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

$SampleRate = $args[1]

$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Suffix " ($SampleRate Hz)"

Write-SoundSheriffLog "Input:  $InputFile"
Write-SoundSheriffLog "Output: $OutputFile"


$Options = @("-af", "aresample=resampler=soxr", "-ar", $SampleRate, "-map_metadata", "0")

# Run FFmpeg
Invoke-SoundSheriffFFmpeg -Arguments (@("-y", "-i", $InputFile) + $Options + @($OutputFile)) -InputFile $InputFile -Status "Resampling to $SampleRate Hz"
