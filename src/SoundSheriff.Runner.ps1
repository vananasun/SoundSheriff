param(
    [Parameter(Mandatory = $true)]
    [string]$Script,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArguments
)

$ErrorActionPreference = "Stop"

function Add-SoundSheriffRunnerLog {
    param([string]$Message)

    if (-not [string]::IsNullOrWhiteSpace($env:SOUNDSHERIFF_UI_LOG_FILE)) {
        $encoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::AppendAllText(
            $env:SOUNDSHERIFF_UI_LOG_FILE,
            $Message + [Environment]::NewLine,
            $encoding
        )
    } else {
        Write-Host $Message
    }
}

$scriptPath = if ([System.IO.Path]::IsPathRooted($Script)) {
    $Script
} else {
    Join-Path $PSScriptRoot $Script
}

try {
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Could not find SoundSheriff script: $scriptPath"
    }

    & $scriptPath @ScriptArguments *>&1 | ForEach-Object {
        if ($null -ne $_) {
            Add-SoundSheriffRunnerLog ([string]$_)
        }
    }

    exit 0
} catch {
    Add-SoundSheriffRunnerLog ""
    Add-SoundSheriffRunnerLog "ERROR: $($_.Exception.Message)"

    if ($_.ScriptStackTrace) {
        Add-SoundSheriffRunnerLog $_.ScriptStackTrace
    }

    exit 1
}
