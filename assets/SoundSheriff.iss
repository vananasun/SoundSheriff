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
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
Source: "..\context_menu.reg"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Convert.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\ExtractAudio.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Mono.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Normalize.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Resample.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SoundSheriff.Tools.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Diagnose-SoundSheriff.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\Localize-SoundSheriffContextMenu.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "sheriff.ico"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "sheriff.png"; DestDir: "{app}\assets"; Flags: ignoreversion
Source: "..\bin\ffmpeg.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\bin\ffprobe.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
Source: "..\THIRD_PARTY_NOTICES.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\licenses\*"; DestDir: "{app}\licenses"; Flags: ignoreversion recursesubdirs

[Run]
Filename: "{cmd}"; Parameters: "/c reg import ""{app}\context_menu.reg"""; Flags: runhidden
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\Localize-SoundSheriffContextMenu.ps1"" -Language ""{language}"""; Flags: runhidden

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
