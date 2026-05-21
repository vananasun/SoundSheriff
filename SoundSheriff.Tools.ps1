function Get-SoundSheriffTool {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("ffmpeg", "ffprobe")]
        [string]$Name
    )

    $exeName = "$Name.exe"
    $bundledPath = Join-Path (Join-Path $PSScriptRoot "bin") $exeName

    if (Test-Path -LiteralPath $bundledPath) {
        return $bundledPath
    }

    $pathCommand = Get-Command $exeName -ErrorAction SilentlyContinue
    if ($pathCommand) {
        return $pathCommand.Source
    }

    throw "Could not find $exeName. Expected it at '$bundledPath' or on PATH."
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

$script:FFmpeg = Get-SoundSheriffTool "ffmpeg"
$script:FFprobe = Get-SoundSheriffTool "ffprobe"
