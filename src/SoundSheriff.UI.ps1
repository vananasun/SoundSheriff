param(
    [Parameter(Mandatory = $true)]
    [string]$Script,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArguments
)

$ErrorActionPreference = "Stop"

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

function Get-SoundSheriffPowerShellPath {
    $systemPowerShell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (Test-Path -LiteralPath $systemPowerShell) {
        return $systemPowerShell
    }

    return "powershell.exe"
}

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    $relaunchArguments = @(
        "-NoProfile",
        "-STA",
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", $PSCommandPath,
        "-Script", $Script
    ) + $ScriptArguments

    Start-Process -FilePath (Get-SoundSheriffPowerShellPath) -ArgumentList (ConvertTo-SoundSheriffArgumentString $relaunchArguments) -WindowStyle Hidden
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$scriptPath = if ([System.IO.Path]::IsPathRooted($Script)) {
    $Script
} else {
    Join-Path $PSScriptRoot $Script
}

$runnerPath = Join-Path $PSScriptRoot "SoundSheriff.Runner.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not find SoundSheriff script:`r`n$scriptPath",
        "SoundSheriff",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

if (-not (Test-Path -LiteralPath $runnerPath)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not find SoundSheriff runner:`r`n$runnerPath",
        "SoundSheriff",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "SoundSheriff-$([guid]::NewGuid().ToString('N'))"
[void](New-Item -ItemType Directory -Path $tempRoot -Force)

$script:LogFile = Join-Path $tempRoot "operation.log"
$script:ProgressFile = Join-Path $tempRoot "progress.jsonl"
[System.IO.File]::WriteAllText($script:LogFile, "", $utf8NoBom)
[System.IO.File]::WriteAllText($script:ProgressFile, "", $utf8NoBom)

$script:LogPosition = 0L
$script:ProgressPosition = 0L
$script:Process = $null
$script:ExitCode = 0
$script:OperationFinished = $false

$form = New-Object System.Windows.Forms.Form
$form.Text = "SoundSheriff"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(760, 480)
$form.MinimumSize = New-Object System.Drawing.Size(560, 360)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Anchor = "Top,Left,Right"
$statusLabel.AutoEllipsis = $true
$statusLabel.Location = New-Object System.Drawing.Point(12, 12)
$statusLabel.Size = New-Object System.Drawing.Size(720, 22)
$statusLabel.Text = "Starting..."

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Anchor = "Top,Left,Right"
$progressBar.Location = New-Object System.Drawing.Point(12, 40)
$progressBar.Size = New-Object System.Drawing.Size(720, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Anchor = "Top,Bottom,Left,Right"
$logBox.Location = New-Object System.Drawing.Point(12, 72)
$logBox.Size = New-Object System.Drawing.Size(720, 320)
$logBox.Multiline = $true
$logBox.ScrollBars = "Both"
$logBox.ReadOnly = $true
$logBox.WordWrap = $false
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Anchor = "Bottom,Right"
$closeButton.Location = New-Object System.Drawing.Point(640, 404)
$closeButton.Size = New-Object System.Drawing.Size(92, 28)
$closeButton.Text = "Close"
$closeButton.Enabled = $false
$closeButton.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($statusLabel, $progressBar, $logBox, $closeButton))

function Add-SoundSheriffUiLog {
    param([string]$Message)

    $logBox.AppendText($Message + [Environment]::NewLine)
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.ScrollToCaret()
}

function Set-SoundSheriffUiProgress {
    param(
        [double]$Percent,
        [string]$Status
    )

    if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $statusLabel.Text = $Status
    }

    if ($Percent -lt 0) {
        $progressBar.Style = "Marquee"
        $progressBar.MarqueeAnimationSpeed = 25
        return
    }

    if ($progressBar.Style -ne "Continuous") {
        $progressBar.Style = "Continuous"
        $progressBar.MarqueeAnimationSpeed = 0
    }

    $value = [Math]::Min(100, [Math]::Max(0, [int][Math]::Round($Percent)))
    $progressBar.Value = $value
}

function Read-SoundSheriffNewText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ref]$Position
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )

    try {
        if ($Position.Value -gt $stream.Length) {
            $Position.Value = 0L
        }

        [void]$stream.Seek($Position.Value, [System.IO.SeekOrigin]::Begin)
        $reader = New-Object System.IO.StreamReader -ArgumentList @($stream, $utf8NoBom, $true, 4096, $true)
        try {
            $text = $reader.ReadToEnd()
            $Position.Value = $stream.Position
            return $text
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

function Add-SoundSheriffLogText {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return
    }

    $normalized = $Text -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"
    $lines = $normalized -split "`n"

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($index -eq ($lines.Count - 1) -and $lines[$index].Length -eq 0) {
            continue
        }

        Add-SoundSheriffUiLog $lines[$index]
    }
}

function Update-SoundSheriffProgressFromText {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return
    }

    $normalized = $Text -replace "`r`n", "`n"
    $normalized = $normalized -replace "`r", "`n"

    foreach ($line in ($normalized -split "`n")) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        try {
            $progress = $line | ConvertFrom-Json
            Set-SoundSheriffUiProgress -Percent ([double]$progress.percent) -Status ([string]$progress.status)
        } catch {
            Add-SoundSheriffUiLog $line
        }
    }
}

function Read-SoundSheriffWorkerOutput {
    Add-SoundSheriffLogText (Read-SoundSheriffNewText -Path $script:LogFile -Position ([ref]$script:LogPosition))
    Update-SoundSheriffProgressFromText (Read-SoundSheriffNewText -Path $script:ProgressFile -Position ([ref]$script:ProgressPosition))
}

function Start-SoundSheriffWorker {
    Add-SoundSheriffUiLog "Running $([System.IO.Path]::GetFileName($scriptPath)) $($ScriptArguments -join ' ')"

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = Get-SoundSheriffPowerShellPath
    $processInfo.Arguments = ConvertTo-SoundSheriffArgumentString (@(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $runnerPath,
        "-Script", $scriptPath
    ) + $ScriptArguments)
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.EnvironmentVariables["SOUNDSHERIFF_UI_LOG_FILE"] = $script:LogFile
    $processInfo.EnvironmentVariables["SOUNDSHERIFF_UI_PROGRESS_FILE"] = $script:ProgressFile

    $script:Process = New-Object System.Diagnostics.Process
    $script:Process.StartInfo = $processInfo
    [void]$script:Process.Start()
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 150
$timer.Add_Tick({
    Read-SoundSheriffWorkerOutput

    if ($script:Process -and $script:Process.HasExited) {
        Read-SoundSheriffWorkerOutput
        $timer.Stop()

        $script:ExitCode = $script:Process.ExitCode
        $script:OperationFinished = $true

        if ($script:ExitCode -eq 0) {
            Add-SoundSheriffUiLog ""
            Add-SoundSheriffUiLog "Done."
            Set-SoundSheriffUiProgress -Percent 100 -Status "Done"
        } else {
            Add-SoundSheriffUiLog ""
            Add-SoundSheriffUiLog "Failed with exit code $script:ExitCode."
            Set-SoundSheriffUiProgress -Percent 100 -Status "Failed"
        }

        $closeButton.Enabled = $true
        $closeButton.Focus()
    }
})

$form.add_Shown({
    try {
        Set-SoundSheriffUiProgress -Percent -1 -Status "Starting..."
        Start-SoundSheriffWorker
        $timer.Start()
    } catch {
        $script:ExitCode = 1
        $script:OperationFinished = $true
        Add-SoundSheriffUiLog "ERROR: $($_.Exception.Message)"
        Set-SoundSheriffUiProgress -Percent 100 -Status "Failed"
        $closeButton.Enabled = $true
    }
})

$form.add_FormClosing({
    param($sender, $eventArgs)

    if (-not $script:OperationFinished) {
        [System.Windows.Forms.MessageBox]::Show(
            "SoundSheriff is still working. You can close this window when the operation finishes.",
            "SoundSheriff",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        $eventArgs.Cancel = $true
    }
})

$form.add_FormClosed({
    if ($script:Process) {
        $script:Process.Dispose()
    }

    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
})

[System.Windows.Forms.Application]::Run($form)
exit $script:ExitCode
