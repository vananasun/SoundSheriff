function Get-SoundSheriffTool {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ffmpeg", "ffprobe")]
        [string]$Name
    )

    $exeName = "$Name.exe"
    $installRoot = Split-Path -Parent $PSScriptRoot
    $bundledPaths = @(
        (Join-Path (Join-Path $installRoot "bin") $exeName),
        (Join-Path (Join-Path $PSScriptRoot "bin") $exeName)
    )

    foreach ($bundledPath in $bundledPaths) {
        if (Test-Path -LiteralPath $bundledPath) {
            return $bundledPath
        }
    }

    $pathCommand = Get-Command $exeName -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

    throw "Could not find $exeName. Expected it under '$installRoot\bin' or on PATH."
}

function Get-SoundSheriffOutputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [string]$Extension,

        [string]$Suffix
    )

    $inputDirectory = Split-Path $InputFile
    $inputName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)

    if ([string]::IsNullOrWhiteSpace($Extension)) {
        $Extension = [System.IO.Path]::GetExtension($InputFile)
    }

    if (-not [string]::IsNullOrWhiteSpace($Extension) -and -not $Extension.StartsWith(".")) {
        $Extension = ".$Extension"
    }

    return Join-Path $inputDirectory "$inputName$Suffix$Extension"
}

function Split-SoundSheriffOption {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Option
    )

    $parts = $Option -split "=", 2
    if ($parts.Count -ne 2) {
        throw "Expected option in key=value format, got '$Option'."
    }

    return @{
        Key = $parts[0]
        Value = $parts[1]
    }
}

function Get-SoundSheriffUtf8Encoding {
    return New-Object System.Text.UTF8Encoding $false
}

function Write-SoundSheriffUiFileLine {
    param(
        [string]$Path,

        [AllowEmptyString()]
        [string]$Line
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    [System.IO.File]::AppendAllText(
        $Path,
        $Line + [Environment]::NewLine,
        (Get-SoundSheriffUtf8Encoding)
    )
    return $true
}

function Write-SoundSheriffLog {
    param([string]$Message)

    if ($global:SoundSheriffLogCallback) {
        & $global:SoundSheriffLogCallback $Message
    } elseif (
        -not [string]::IsNullOrWhiteSpace($env:SOUNDSHERIFF_UI_LOG_FILE) -and
        (Write-SoundSheriffUiFileLine -Path $env:SOUNDSHERIFF_UI_LOG_FILE -Line $Message)
    ) {
        return
    } else {
        Write-Host $Message
    }
}

function Set-SoundSheriffProgress {
    param(
        [double]$Percent,
        [string]$Status
    )

    if ($global:SoundSheriffProgressCallback) {
        & $global:SoundSheriffProgressCallback $Percent $Status
    } elseif (-not [string]::IsNullOrWhiteSpace($env:SOUNDSHERIFF_UI_PROGRESS_FILE)) {
        $progress = [ordered]@{
            percent = $Percent
            status = $Status
        }
        Write-SoundSheriffUiFileLine -Path $env:SOUNDSHERIFF_UI_PROGRESS_FILE -Line ($progress | ConvertTo-Json -Compress) | Out-Null
    } elseif (-not [string]::IsNullOrWhiteSpace($Status)) {
        Write-Host $Status
    }
}

function ConvertTo-SoundSheriffArgumentString {
    param([string[]]$Arguments)

    $quotedArguments = foreach ($argument in $Arguments) {
        if ($null -eq $argument) {
            '""'
            continue
        }

        if ($argument -notmatch '[\s"]' -and $argument.Length -gt 0) {
            $argument
            continue
        }

        $escaped = $argument -replace '(\\*)"', '$1$1\"'
        $escaped = $escaped -replace '(\\+)$', '$1$1'
        '"' + $escaped + '"'
    }

    return ($quotedArguments -join " ")
}

function Get-SoundSheriffMediaDuration {
    param([string]$InputFile)

    if ([string]::IsNullOrWhiteSpace($InputFile) -or -not (Test-Path -LiteralPath $InputFile)) {
        return $null
    }

    $durationText = & $script:FFprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $InputFile 2>$null
    $duration = 0.0
    if ([double]::TryParse(
        $durationText,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$duration
    )) {
        if ($duration -gt 0) {
            return $duration
        }
    }

    return $null
}

function Invoke-SoundSheriffFFmpeg {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [string]$InputFile,

        [double]$ProgressStart = 0,

        [double]$ProgressEnd = 100,

        [string]$Status = "Processing",

        [switch]$CaptureOutput
    )

    $duration = Get-SoundSheriffMediaDuration -InputFile $InputFile
    if ($duration) {
        Set-SoundSheriffProgress -Percent $ProgressStart -Status $Status
    } else {
        Set-SoundSheriffProgress -Percent -1 -Status $Status
    }

    $allArguments = @("-progress", "pipe:2", "-nostats") + $Arguments
    Write-SoundSheriffLog "> ffmpeg $(ConvertTo-SoundSheriffArgumentString $allArguments)"

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = $script:FFmpeg
    $processInfo.Arguments = ConvertTo-SoundSheriffArgumentString $allArguments
    $processInfo.UseShellExecute = $false
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $outputLines = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

    function Handle-SoundSheriffFFmpegLine {
        param([string]$Line)

        if ($null -eq $Line) {
            return
        }

        if ($CaptureOutput) {
            [void]$outputLines.Add($Line)
        }

        if ($Line -match '^out_time_ms=(\d+)$' -and $duration) {
            $seconds = [double]$Matches[1] / 1000000.0
            $relativePercent = [Math]::Min(100.0, [Math]::Max(0.0, ($seconds / $duration) * 100.0))
            $mappedPercent = $ProgressStart + (($ProgressEnd - $ProgressStart) * ($relativePercent / 100.0))
            Set-SoundSheriffProgress -Percent $mappedPercent -Status $Status
        } elseif ($Line -eq 'progress=end') {
            Set-SoundSheriffProgress -Percent $ProgressEnd -Status $Status
        } elseif ($Line -notmatch '^(bitrate|continue|drop_frames|dup_frames|fps|out_time|out_time_ms|out_time_us|progress|speed|stream_.*|total_size)=') {
            Write-SoundSheriffLog $Line
        }
    }

    [void]$process.Start()

    while (-not $process.StandardError.EndOfStream) {
        Handle-SoundSheriffFFmpegLine $process.StandardError.ReadLine()
    }

    $stdoutText = $process.StandardOutput.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($stdoutText)) {
        foreach ($line in ($stdoutText -split "`r?`n")) {
            Handle-SoundSheriffFFmpegLine $line
        }
    }

    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        throw "FFmpeg failed with exit code $($process.ExitCode)."
    }

    Set-SoundSheriffProgress -Percent $ProgressEnd -Status $Status

    if ($CaptureOutput) {
        return ($outputLines -join [Environment]::NewLine)
    }
}

$script:FFmpeg = Get-SoundSheriffTool "ffmpeg"
$script:FFprobe = Get-SoundSheriffTool "ffprobe"
