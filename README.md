# SoundSheriff 👮‍♂️

Convert audio and extract sound from videos directly from Windows right-click. No uploads. No confusing apps. No subscriptions.

![SoundSheriff demo](assets/demo.gif)

## Features

- Convert audio to WAV, FLAC, AIFF, Opus, Vorbis, MP3, or AAC.
- Convert video to MP4, WebM, MOV, AVI, or MKV.
- Extract audio from video files.
- Convert stereo audio to mono.
- Resample audio to common sample rates.
- Normalize audio for streaming services.
- Compress videos to Discord-friendly H.264/AAC .MP4 files under 10 MiB.
- Preserve metadata where the operation supports it.

## Supported File Types

Audio context menu entries are registered for:

```text
.wav .aiff .flac .mp3 .wma .opus .ogg .aac .m4a
```

Video conversion, compression, and audio-extraction entries are registered for:

```text
.mp4 .avi .mov .webm .mkv
```

## Install

Download the latest `SoundSheriffSetup.exe` from the project releases and run it.
The installer supports English, Chinese, Hindi, Spanish, Portuguese, Arabic,
Bengali, Russian, Indonesian, Urdu, Japanese, Turkish, Korean, French, German,
and Dutch. For languages without a bundled Inno Setup translation, the installer
uses English text while applying localized context menu labels.

## How it works

SoundSheriff adds custom Explorer context menu entries through the Windows registry. Each menu action runs a PowerShell script invoking FFmpeg commandline binaries for the actual processing.

When an action runs from Explorer, SoundSheriff opens a small progress window
with a scrollable FFmpeg log. The console process is started hidden; the window
captures FFmpeg output and updates progress from FFmpeg's machine-readable
progress stream.

## Development Setup

Clone the repository on 64-bit Windows.

```bat
git clone <repo-url>
cd SoundSheriff
```

Download the local FFmpeg tools used by the scripts and installer:

```bat
download-ffmpeg.bat
```

This populates:

```text
bin\ffmpeg.exe
bin\ffprobe.exe
licenses\FFmpeg-LICENSE.txt
licenses\FFmpeg-README.txt
```

The FFmpeg executables are intentionally not committed to Git. They are large
third-party binaries and are ignored by `.gitignore`.

## Running From Source

The scripts resolve FFmpeg through `src\SoundSheriff.Tools.ps1`. They first look
for bundled tools in `bin\`, then fall back to `PATH`.

You can run a script directly, for example:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\src\Convert.ps1 "C:\path\song.wav" flac
powershell.exe -ExecutionPolicy Bypass -File .\src\Normalize.ps1 "C:\path\song.wav"
powershell.exe -ExecutionPolicy Bypass -File .\src\ConvertVideo.ps1 "C:\path\video.mov" mp4
powershell.exe -ExecutionPolicy Bypass -File .\src\CompressVideoDiscord.ps1 "C:\path\video.mov"
```

For context menu testing during development, either install the built installer
in a disposable Windows environment or import `context_menu.reg` manually as
administrator after making sure `C:\Program Files\SoundSheriff` points at the
files you want to run.

If `C:\Program Files\SoundSheriff` is a symlink to your development checkout,
running the installer will write through that symlink and may overwrite local
files. Treat that setup as a development convenience, not as an installer test.

## Building The Installer

Prerequisites:

- 64-bit Windows.
- Inno Setup 6.
- FFmpeg tools downloaded with `download-ffmpeg.bat`.

Build:

```bat
build-installer.bat
```

The output is:

```text
dist\SoundSheriffSetup.exe
```

If the build fails because the output file is in use, close any running
SoundSheriff installer window and run the build again.

## Project Layout

```text
assets\SoundSheriff.iss      Inno Setup installer script
assets\sheriff.ico           Context menu / uninstall icon
bin\.gitkeep                 Placeholder for local FFmpeg binaries
bpm\                         Experimental BPM detection source
context_menu.reg             Windows Explorer context menu registration
src\SoundSheriff.Tools.ps1   FFmpeg/FFprobe resolver
src\SoundSheriff.UI.ps1      Progress window and combined FFmpeg log
src\SoundSheriff.Runner.ps1  Hidden worker process used by the progress window
src\Diagnose-SoundSheriff.ps1    Installed-machine compatibility checks
src\Localize-SoundSheriffContextMenu.ps1  Installer-selected menu translations
src\CompressVideoDiscord.ps1 Video compression to Discord-sized .MP4
src\Convert.ps1              Audio conversion commands
src\ConvertVideo.ps1         Video conversion commands
src\ExtractAudio.ps1         Video audio extraction commands
src\Mono.ps1                 Stereo-to-mono command
src\Normalize.ps1            Two-pass loudness normalization
src\Resample.ps1             Sample-rate conversion
download-ffmpeg.bat          Fetch pinned FFmpeg binaries for local builds
src\download-ffmpeg.ps1      FFmpeg download implementation
build-installer.bat          Build the Inno Setup installer
licenses\                    Third-party FFmpeg license/source notes
```

## FFmpeg And Licensing

SoundSheriff invokes FFmpeg as separate command-line programs. Release builds
bundle Gyan's FFmpeg `8.1.1-essentials_build-www.gyan.dev`, which is licensed
under GPL v3. The exact source commit, archive checksum, and bundled license
files are recorded in:

```text
THIRD_PARTY_NOTICES.md
licenses\FFmpeg-SOURCE.txt
```

Before publishing releases, make sure the repository license is compatible with
the bundled FFmpeg build.
