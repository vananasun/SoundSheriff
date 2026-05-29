[Setup]
AppId={{9C803777-F3A5-4C0B-955A-F77B63820C08}
AppName=SoundSheriff
AppVersion=0.1b
WizardStyle=classic dark
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DefaultDirName={autopf}\SoundSheriff
DisableDirPage=yes
DefaultGroupName=SoundSheriff
PrivilegesRequired=admin
UninstallDisplayIcon={app}\assets\sheriff.ico
Compression=lzma2
SolidCompression=yes
OutputBaseFilename=SoundSheriffSetup
OutputDir=..\dist

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; MenuLabels files use English installer text and select localized context menu labels.
Name: "chinese"; MessagesFile: "compiler:Default.isl,languages\ChineseMenuLabels.isl"
Name: "hindi"; MessagesFile: "compiler:Default.isl,languages\HindiMenuLabels.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "bengali"; MessagesFile: "compiler:Default.isl,languages\BengaliMenuLabels.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "indonesian"; MessagesFile: "compiler:Default.isl,languages\IndonesianMenuLabels.isl"
Name: "urdu"; MessagesFile: "compiler:Default.isl,languages\UrduMenuLabels.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"

[Files]
Source: "..\context_menu.reg"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\src\CompressVideoDiscord.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Convert.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\ConvertVideo.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\ExtractAudio.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Mono.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Normalize.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Resample.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\SoundSheriff.Tools.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\SoundSheriff.UI.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\SoundSheriff.Runner.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Diagnose-SoundSheriff.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "..\src\Localize-SoundSheriffContextMenu.ps1"; DestDir: "{app}\src"; Flags: ignoreversion
Source: "sheriff.ico"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "sheriff.png"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "..\bin\ffmpeg.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\ffprobe.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\licenses\*"; DestDir: "{app}\licenses"; Flags: ignoreversion recursesubdirs

[InstallDelete]
Type: files; Name: "{app}\CompressVideoDiscord.ps1"
Type: files; Name: "{app}\Convert.ps1"
Type: files; Name: "{app}\ConvertVideo.ps1"
Type: files; Name: "{app}\ExtractAudio.ps1"
Type: files; Name: "{app}\Mono.ps1"
Type: files; Name: "{app}\Normalize.ps1"
Type: files; Name: "{app}\Resample.ps1"
Type: files; Name: "{app}\SoundSheriff.Tools.ps1"
Type: files; Name: "{app}\SoundSheriff.UI.ps1"
Type: files; Name: "{app}\SoundSheriff.Runner.ps1"
Type: files; Name: "{app}\Diagnose-SoundSheriff.ps1"
Type: files; Name: "{app}\Localize-SoundSheriffContextMenu.ps1"

[Run]
Filename: "{cmd}"; Parameters: "/c reg import ""{app}\context_menu.reg"""; Flags: runhidden
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\src\Localize-SoundSheriffContextMenu.ps1"" -Language ""{language}"""; Flags: runhidden

[UninstallRun]
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.wav\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-wav-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.aiff\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-aiff-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.flac\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-flac-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.mp3\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-mp3-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.wma\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-wma-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.opus\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-opus-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.ogg\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-ogg-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.aac\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-aac-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.m4a\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-m4a-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.mp4\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-mp4-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.avi\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-avi-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.mov\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-mov-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.webm\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-webm-convert"
Filename: "{cmd}"; Parameters: "/c reg delete ""HKLM\SOFTWARE\Classes\SystemFileAssociations\.mkv\shell\Convert"" /f"; Flags: runhidden; RunOnceId: "delete-mkv-convert"
