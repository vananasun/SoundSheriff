$InputFile = $args[0]

if ($args.Count -lt 1) {
    throw "Expected input file."
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "Input file not found: $InputFile"
}

. "$PSScriptRoot\SoundSheriff.Tools.ps1"

$MaxBytes = 10 * 1024 * 1024
$TargetBytes = $MaxBytes - (64 * 1024)
$SampleFraction = 0.12
$MinSampleSeconds = 3.0
$MaxSampleSeconds = 18.0
$MaxAttempts = 5

function ConvertTo-InvariantString {
    param([double]$Value)

    return $Value.ToString("0.###", [System.Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-BitrateArgument {
    param([int]$Kbps)

    return "$($Kbps)k"
}

function ConvertTo-SizeText {
    param([long]$Bytes)

    $mib = [double]$Bytes / 1MB
    return "$($mib.ToString('0.00', [System.Globalization.CultureInfo]::InvariantCulture)) MiB"
}

function ConvertTo-DoubleOrNull {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value
    $parsed = 0.0
    if ([double]::TryParse(
        $text,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$parsed
    )) {
        return $parsed
    }

    return $null
}

function ConvertTo-Int64OrNull {
    param([object]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value
    $parsed = 0L
    if ([long]::TryParse(
        $text,
        [System.Globalization.NumberStyles]::Integer,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$parsed
    )) {
        return $parsed
    }

    return $null
}

function Get-FirstProbeStream {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$StreamSelector
    )

    $probeText = (& $FFprobe -v error -select_streams $StreamSelector -show_entries stream=index,width,height -of json $InputFile) -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($probeText)) {
        return $null
    }

    $probe = $probeText | ConvertFrom-Json
    $streams = @($probe.streams)
    if ($streams.Count -eq 0) {
        return $null
    }

    return $streams[0]
}

function Test-AudioStream {
    param([string]$InputFile)

    $probeText = (& $FFprobe -v error -select_streams a:0 -show_entries stream=index -of default=noprint_wrappers=1:nokey=1 $InputFile) -join [Environment]::NewLine
    return ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($probeText))
}

function Get-ScaleFilter {
    param([int]$VideoKbps)

    if ($VideoKbps -lt 260) {
        $maxWidth = 426
        $maxHeight = 240
    } elseif ($VideoKbps -lt 520) {
        $maxWidth = 640
        $maxHeight = 360
    } elseif ($VideoKbps -lt 950) {
        $maxWidth = 854
        $maxHeight = 480
    } elseif ($VideoKbps -lt 1800) {
        $maxWidth = 1280
        $maxHeight = 720
    } else {
        $maxWidth = 1920
        $maxHeight = 1080
    }

    return "scale=w='min($maxWidth,iw)':h='min($maxHeight,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2,setsar=1"
}

function New-EncodeSettings {
    param(
        [long]$BudgetBytes,
        [double]$Duration,
        [double]$EstimatedOverheadBytes,
        [bool]$HasAudio,
        [double]$SourceKbps
    )

    $mediaBudgetBytes = [Math]::Max(1.0, [double]$BudgetBytes - $EstimatedOverheadBytes)
    $totalKbps = [Math]::Floor(($mediaBudgetBytes * 8.0) / $Duration / 1000.0)

    if ($SourceKbps -gt 0) {
        $totalKbps = [Math]::Min($totalKbps, [Math]::Floor($SourceKbps * 0.95))
    }

    if ($totalKbps -lt 24) {
        throw "Video is too long to fit under 10 MiB with a usable bitrate."
    }

    $audioKbps = 0
    if ($HasAudio) {
        if ($totalKbps -ge 700) {
            $audioKbps = 96
        } elseif ($totalKbps -ge 420) {
            $audioKbps = 80
        } elseif ($totalKbps -ge 260) {
            $audioKbps = 64
        } elseif ($totalKbps -ge 150) {
            $audioKbps = 48
        } elseif ($totalKbps -ge 80) {
            $audioKbps = 32
        } else {
            $audioKbps = 16
        }

        if (($totalKbps - $audioKbps) -lt 24) {
            $audioKbps = [Math]::Max(0, $totalKbps - 24)
        }
    }

    $videoKbps = [Math]::Max(24, $totalKbps - $audioKbps)
    $maxRateKbps = [Math]::Max($videoKbps + 1, [Math]::Ceiling($videoKbps * 1.25))
    $bufferKbps = [Math]::Max($videoKbps + 1, [Math]::Ceiling($videoKbps * 2.0))

    return [pscustomobject]@{
        TotalKbps = [int]$totalKbps
        VideoKbps = [int]$videoKbps
        AudioKbps = [int]$audioKbps
        MaxRateKbps = [int]$maxRateKbps
        BufferKbps = [int]$bufferKbps
        ScaleFilter = Get-ScaleFilter -VideoKbps ([int]$videoKbps)
    }
}

function New-FFmpegEncodeArguments {
    param(
        [Parameter(Mandatory = $true)]
        $Settings,

        [Parameter(Mandatory = $true)]
        [bool]$HasAudio
    )

    $arguments = @(
        "-map", "0:v:0",
        "-c:v", "libx264",
        "-preset", "medium",
        "-b:v", (ConvertTo-BitrateArgument $Settings.VideoKbps),
        "-maxrate", (ConvertTo-BitrateArgument $Settings.MaxRateKbps),
        "-bufsize", (ConvertTo-BitrateArgument $Settings.BufferKbps),
        "-vf", $Settings.ScaleFilter,
        "-pix_fmt", "yuv420p",
        "-profile:v", "high"
    )

    if ($HasAudio -and $Settings.AudioKbps -gt 0) {
        $arguments += @(
            "-map", "0:a:0?",
            "-c:a", "aac",
            "-b:a", (ConvertTo-BitrateArgument $Settings.AudioKbps),
            "-ac", "2",
            "-ar", "48000"
        )
    } else {
        $arguments += "-an"
    }

    $arguments += @(
        "-map_metadata", "-1",
        "-movflags", "+faststart"
    )

    return $arguments
}

function Get-Mp4OverheadEstimate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SampleFile,

        [Parameter(Mandatory = $true)]
        [double]$FallbackDuration,

        [Parameter(Mandatory = $true)]
        [int]$FallbackMediaKbps,

        [Parameter(Mandatory = $true)]
        [double]$TargetDuration
    )

    $sampleInfo = Get-Item -LiteralPath $SampleFile
    $probeText = (& $FFprobe -v error -show_entries format=duration,size:stream=bit_rate,codec_type -of json $SampleFile) -join [Environment]::NewLine
    $probeExitCode = $LASTEXITCODE
    $packetSizeLines = & $FFprobe -v error -show_packets -show_entries packet=size -of csv=p=0 $SampleFile

    $duration = $FallbackDuration
    $streamBytes = 0.0
    $packetBytes = 0L

    foreach ($line in $packetSizeLines) {
        $packetSize = ConvertTo-Int64OrNull $line
        if ($packetSize -and $packetSize -gt 0) {
            $packetBytes += $packetSize
        }
    }

    if ($probeExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($probeText)) {
        $probe = $probeText | ConvertFrom-Json
        $probeDuration = ConvertTo-DoubleOrNull $probe.format.duration
        if ($probeDuration -and $probeDuration -gt 0) {
            $duration = $probeDuration
        }

        foreach ($stream in @($probe.streams)) {
            $bitRate = ConvertTo-Int64OrNull $stream.bit_rate
            if ($bitRate -and $bitRate -gt 0) {
                $streamBytes += ([double]$bitRate * $duration) / 8.0
            }
        }
    }

    if ($packetBytes -gt 0) {
        $streamBytes = [double]$packetBytes
    } elseif ($streamBytes -le 0) {
        $streamBytes = ([double]$FallbackMediaKbps * 1000.0 * $duration) / 8.0
    }

    $overheadBytes = [Math]::Max(0.0, [double]$sampleInfo.Length - $streamBytes)
    $overheadBytesPerSecond = $overheadBytes / [Math]::Max(0.001, $duration)
    $scaledOverheadBytes = $overheadBytesPerSecond * $TargetDuration

    return [pscustomobject]@{
        SampleSizeBytes = [long]$sampleInfo.Length
        SampleDuration = [double]$duration
        OverheadBytes = [double]$overheadBytes
        OverheadBytesPerSecond = [double]$overheadBytesPerSecond
        EstimatedFullOverheadBytes = [Math]::Max(65536.0, $scaledOverheadBytes)
    }
}

$Duration = Get-SoundSheriffMediaDuration -InputFile $InputFile
if (-not $Duration) {
    throw "Could not determine video duration."
}

$VideoStream = Get-FirstProbeStream -InputFile $InputFile -StreamSelector "v:0"
if (-not $VideoStream) {
    throw "No video stream found."
}

$HasAudio = Test-AudioStream -InputFile $InputFile
$InputInfo = Get-Item -LiteralPath $InputFile
$SourceKbps = ([double]$InputInfo.Length * 8.0) / $Duration / 1000.0
$OutputFile = Get-SoundSheriffOutputPath -InputFile $InputFile -Extension "mp4" -Suffix " (Discord 10MiB)"
$InputExt = [System.IO.Path]::GetExtension($InputFile)

Write-SoundSheriffLog "Input:  $InputFile"
Write-SoundSheriffLog "Output: $OutputFile"
Write-SoundSheriffLog "Target: $(ConvertTo-SizeText $MaxBytes)"
Write-SoundSheriffLog "Duration: $(ConvertTo-InvariantString $Duration) seconds"
Write-SoundSheriffLog "Input size: $(ConvertTo-SizeText $InputInfo.Length)"
Write-SoundSheriffLog "Audio: $(if ($HasAudio) { 'yes' } else { 'no' })"
Write-SoundSheriffLog ""

if ($InputInfo.Length -le $MaxBytes -and $InputExt.Equals(".mp4", [System.StringComparison]::OrdinalIgnoreCase)) {
    Set-SoundSheriffProgress -Percent 100 -Status "Already under 10 MiB"
    Write-SoundSheriffLog "Input is already an .MP4 at or under 10 MiB; no compression needed."
    return
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "SoundSheriff-Discord-$([guid]::NewGuid().ToString('N'))"
[void](New-Item -ItemType Directory -Path $tempRoot -Force)

try {
    $sampleDuration = [Math]::Min($Duration, [Math]::Max($MinSampleSeconds, [Math]::Min($MaxSampleSeconds, $Duration * $SampleFraction)))
    $sampleStart = 0.0
    if ($Duration -gt ($sampleDuration + 1.0)) {
        $sampleStart = [Math]::Max(0.0, ($Duration - $sampleDuration) / 2.0)
    }

    $initialSettings = New-EncodeSettings -BudgetBytes $TargetBytes -Duration $Duration -EstimatedOverheadBytes 65536.0 -HasAudio $HasAudio -SourceKbps $SourceKbps
    $sampleFile = Join-Path $tempRoot "sample.mp4"

    Write-SoundSheriffLog "Pass 1: encoding $(ConvertTo-InvariantString $sampleDuration) second sample at $(ConvertTo-InvariantString $sampleStart) seconds."
    Write-SoundSheriffLog "Sample settings: video $($initialSettings.VideoKbps) kbps, audio $($initialSettings.AudioKbps) kbps"

    $sampleArguments = @(
        "-hide_banner",
        "-y",
        "-ss", (ConvertTo-InvariantString $sampleStart),
        "-t", (ConvertTo-InvariantString $sampleDuration),
        "-i", $InputFile
    ) + (New-FFmpegEncodeArguments -Settings $initialSettings -HasAudio $HasAudio) + @($sampleFile)

    Invoke-SoundSheriffFFmpeg -Arguments $sampleArguments -InputFile $InputFile -ProgressStart 0 -ProgressEnd 20 -Status "Measuring MP4 overhead"

    $overhead = Get-Mp4OverheadEstimate -SampleFile $sampleFile -FallbackDuration $sampleDuration -FallbackMediaKbps $initialSettings.TotalKbps -TargetDuration $Duration

    Write-SoundSheriffLog "Sample size: $(ConvertTo-SizeText $overhead.SampleSizeBytes)"
    Write-SoundSheriffLog "Measured overhead: $([Math]::Round($overhead.OverheadBytesPerSecond, 2)) bytes/sec"
    Write-SoundSheriffLog "Estimated full overhead: $(ConvertTo-SizeText ([long]$overhead.EstimatedFullOverheadBytes))"
    Write-SoundSheriffLog ""

    $currentBudgetBytes = $TargetBytes
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $settings = New-EncodeSettings -BudgetBytes $currentBudgetBytes -Duration $Duration -EstimatedOverheadBytes $overhead.EstimatedFullOverheadBytes -HasAudio $HasAudio -SourceKbps $SourceKbps

        Write-SoundSheriffLog "Pass 2 attempt $attempt settings:"
        Write-SoundSheriffLog "Total bitrate: $($settings.TotalKbps) kbps"
        Write-SoundSheriffLog "Video bitrate: $($settings.VideoKbps) kbps"
        Write-SoundSheriffLog "Audio bitrate: $($settings.AudioKbps) kbps"
        Write-SoundSheriffLog "Scale filter: $($settings.ScaleFilter)"

        $encodeArguments = @(
            "-hide_banner",
            "-y",
            "-i", $InputFile
        ) + (New-FFmpegEncodeArguments -Settings $settings -HasAudio $HasAudio) + @($OutputFile)

        Invoke-SoundSheriffFFmpeg -Arguments $encodeArguments -InputFile $InputFile -ProgressStart 20 -ProgressEnd 100 -Status "Compressing for Discord"

        $outputBytes = (Get-Item -LiteralPath $OutputFile).Length
        Write-SoundSheriffLog "Output size: $(ConvertTo-SizeText $outputBytes)"

        if ($outputBytes -le $MaxBytes) {
            Write-SoundSheriffLog "Done! Output file: $OutputFile"
            return
        }

        if ($attempt -ge $MaxAttempts) {
            throw "Output is still larger than 10 MiB after $MaxAttempts attempts: $(ConvertTo-SizeText $outputBytes)"
        }

        $retryFactor = ([double]$MaxBytes / [double]$outputBytes) * 0.97
        $retryFactor = [Math]::Min(0.96, [Math]::Max(0.75, $retryFactor))
        $currentBudgetBytes = [long][Math]::Floor([double]$currentBudgetBytes * $retryFactor)

        Write-SoundSheriffLog "Output was over 10 MiB; retrying with $([Math]::Round((1.0 - $retryFactor) * 100.0, 1))% heavier compression."
        Write-SoundSheriffLog ""
        Set-SoundSheriffProgress -Percent 20 -Status "Retrying with heavier compression"
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
