
$InputFile = $args[0]

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

$InputExt  = [System.IO.Path]::GetExtension($InputFile)
$InputName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$InputDir  = Split-Path $InputFile


$SampleRate = $args[1]


$OutputFile = Join-Path $InputDir "$InputName ($SampleRate Hz)$InputExt"



Write-Output "Input:  $InputFile"
Write-Output "Output: $OutputFile"


$Options = "-af aresample=resampler=soxr -ar $($args[1])"

$Options = "$Options -map_metadata 0"
$OptionArray = $Options -split ' '    # split into array for & invocation

# Run FFmpeg
& $FFmpeg -y -i $InputFile $OptionArray $OutputFile

