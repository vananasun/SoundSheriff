@echo off
setlocal

cd /d "%~dp0"

set "ISCC="

if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
)

if not defined ISCC if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
)

if not defined ISCC (
    for /f "delims=" %%I in ('where ISCC.exe 2^>nul') do (
        if not defined ISCC set "ISCC=%%I"
    )
)

if not defined ISCC (
    echo ERROR: Inno Setup 6 compiler not found.
    echo Install Inno Setup 6 or add ISCC.exe to PATH.
    exit /b 1
)

if not exist "bin\ffmpeg.exe" (
    echo ERROR: Missing bin\ffmpeg.exe.
    exit /b 1
)

if not exist "bin\ffprobe.exe" (
    echo ERROR: Missing bin\ffprobe.exe.
    exit /b 1
)

echo Building SoundSheriff installer...
echo Using "%ISCC%"

"%ISCC%" "assets\SoundSheriff.iss"
if errorlevel 1 (
    echo.
    echo Build failed. If dist\SoundSheriffSetup.exe is in use, close the installer window and try again.
    exit /b 1
)

echo.
echo Built dist\SoundSheriffSetup.exe
