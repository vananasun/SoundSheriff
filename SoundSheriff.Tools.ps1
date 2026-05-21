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

$script:FFmpeg = Get-SoundSheriffTool "ffmpeg"
$script:FFprobe = Get-SoundSheriffTool "ffprobe"
