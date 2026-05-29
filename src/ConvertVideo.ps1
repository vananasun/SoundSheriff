$InputFile = $args[0]
$OutputExt = $args[1]

if ($args.Count -lt 2) {
    throw "Expected input file and output extension."
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

function Test-SoundSheriffMediaStream {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$StreamSelector
    )

    $probeText = (& $FFprobe -v error -select_streams $StreamSelector -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null) -join ""
    return ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($probeText))
}

function Get-SoundSheriffVideoConversion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Extension,

        [Parameter(Mandatory = $true)]
        [bool]$HasAudio
    )

    $arguments = @("-map", "0:v:0")

    if ($HasAudio) {
        $arguments += @("-map", "0:a:0")
    } else {
        $arguments += "-an"
    }

    switch ($Extension) {
        "mp4" {
            $arguments += @(
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "20",
                "-pix_fmt", "yuv420p"
            )

            if ($HasAudio) {
                $arguments += @("-c:a", "aac", "-b:a", "192k", "-ac", "2", "-ar", "48000")
            }

            $arguments += @("-movflags", "+faststart")
        }
        "mov" {
            $arguments += @(
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "20",
                "-pix_fmt", "yuv420p"
            )

            if ($HasAudio) {
                $arguments += @("-c:a", "aac", "-b:a", "192k", "-ac", "2", "-ar", "48000")
            }
        }
        "mkv" {
            $arguments += @(
                "-c:v", "libx264",
                "-preset", "medium",
                "-crf", "20",
                "-pix_fmt", "yuv420p"
            )

            if ($HasAudio) {
                $arguments += @("-c:a", "aac", "-b:a", "192k", "-ac", "2", "-ar", "48000")
            }
        }
        "avi" {
            $arguments += @("-c:v", "mpeg4", "-q:v", "3")

            if ($HasAudio) {
                $arguments += @("-c:a", "libmp3lame", "-b:a", "192k", "-ac", "2", "-ar", "48000")
            }
        }
        "webm" {
            $arguments += @(
                "-c:v", "libvpx-vp9",
                "-deadline", "good",
                "-cpu-used", "3",
                "-row-mt", "1",
                "-crf", "32",
                "-b:v", "0"
            )

            if ($HasAudio) {
                $arguments += @("-c:a", "libopus", "-b:a", "128k", "-ac", "2", "-ar", "48000")
            }
        }
        default {
            throw "Unsupported video output extension: .$Extension"
        }
    }

    $arguments += @("-map_metadata", "0")
    return $arguments
}

$OutputExt = $OutputExt.Trim().TrimStart(".").ToLowerInvariant()

if ([string]::IsNullOrWhiteSpace($OutputExt)) {
    throw "Expected output extension."
}

$HasVideo = Test-SoundSheriffMediaStream -InputFile $InputFile -StreamSelector "v:0"
if (-not $HasVideo) {
    throw "No video stream found."
}

$HasAudio = Test-SoundSheriffMediaStream -InputFile $InputFile -StreamSelector "a:0"
$InputExt = [System.IO.Path]::GetExtension($InputFile).TrimStart(".").ToLowerInvariant()
$OutputSuffix = if ($InputExt -eq $OutputExt) { " (converted)" } else { $null }
$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Extension $OutputExt -Suffix $OutputSuffix
$Options = Get-SoundSheriffVideoConversion -Extension $OutputExt -HasAudio $HasAudio

Write-SoundSheriffLog "Input:  $InputFile"
Write-SoundSheriffLog "Output: $OutputFile"
Write-SoundSheriffLog "Format: .$OutputExt"
Write-SoundSheriffLog "Audio: $(if ($HasAudio) { 'yes' } else { 'no' })"

Invoke-SoundSheriffFFmpeg -Arguments (@("-hide_banner", "-y", "-i", $InputFile) + $Options + @($OutputFile)) -InputFile $InputFile -Status "Converting video to .$OutputExt"
