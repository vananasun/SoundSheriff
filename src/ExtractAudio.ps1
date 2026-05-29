$InputFile = $args[0]

if ($args.Count -lt 1) {
    throw "Expected input file."
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

$AudioStream = & $FFprobe -v error -select_streams a:0 -show_entries stream=index -of "default=nw=1:nk=1" $InputFile
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($AudioStream -join ""))) {
    Set-SoundSheriffProgress -Percent 100 -Status "No audio stream found"
    Write-SoundSheriffLog "No audio stream found in this video file; nothing to extract."
    return
}

$Options = @()

# force extract as given extension
if ($args.Count -ge 2) {

    $Ext = $args[1]

} else { # otherwise find best output codec

    # Run ffprobe and capture the first audio codec
    $Codec = & $FFprobe -v error -select_streams a:0 -show_entries stream=codec_name -of "default=nw=1:nk=1" $InputFile
    $Codec = $Codec.Trim()  # remove any leading/trailing whitespace

    # Map codec to extension
    $Ext = switch ($Codec) {
        "aac"    { "m4a" }
        "mp3"    { "mp3" }
        "opus"   { "opus" }
        "vorbis" { "ogg" }
        "flac"   { "flac" }
        "ac3"    { "ac3" }
        "eac3"   { "eac3" }
        "dts"    { "dts" }
    }
    #  "pcm_s16le"  { "flac" }

    if ([string]::IsNullOrWhiteSpace($Ext)) {

        # Default to encode to a FLAC
        $Ext = "flac"
        $Options = @("-vn", "-c:a", "flac", "-compression_level", "12")

    } else {

        # Extract without re-encoding
        $Options = @("-vn", "-acodec", "copy")

    }
}

Write-SoundSheriffLog "Codec: $Codec"
Write-SoundSheriffLog "Extension: .$Ext"

$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Extension $Ext

Invoke-SoundSheriffFFmpeg -Arguments (@("-y", "-i", $InputFile) + $Options + @($OutputFile)) -InputFile $InputFile -Status "Extracting audio"
