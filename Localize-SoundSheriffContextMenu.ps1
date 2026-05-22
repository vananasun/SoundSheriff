param(
    [string]$Language = "english"
)

$ErrorActionPreference = "Stop"

$languageKey = $Language.ToLowerInvariant()

$translations = @{
    english = @{
        MenuRoot = "SoundSheriff"
        ConvertWAV = "Convert to WAV"
        ConvertFLAC = "Convert to FLAC"
        ConvertAIFF = "Convert to AIFF (Apple)"
        ConvertOpus = "Convert to Opus"
        ConvertVorbis = "Convert to Vorbis (.ogg)"
        ConvertMP3128 = "Convert to MP3 (128 kbps)"
        ConvertMP3192 = "Convert to MP3 (192 kbps)"
        ConvertMP3320 = "Convert to MP3 (320 kbps)"
        ConvertMP3VBR0 = "Convert to MP3 (VBR 220-260 kbps)"
        ConvertAAC = "Convert to AAC (Apple)"
        Mono = "Stereo to mono"
        Resample96000 = "Resample 96000 Hz"
        Resample48000 = "Resample 48000 Hz"
        Resample44100 = "Resample 44100 Hz"
        Resample22050 = "Resample 22050 Hz"
        Resample11025 = "Resample 11025 Hz"
        NormalizeLUFS = "Normalize (Spotify)"
        ExtractAudio = "Extract audio (cleanest)"
        ExtractFLAC = "Extract audio (FLAC)"
        ExtractWAV = "Extract audio (WAV)"
        ExtractMP3 = "Extract audio (MP3)"
        ExtractOpus = "Extract audio (Opus)"
    }
    dutch = @{
        MenuRoot = "SoundSheriff"
        ConvertWAV = "Omzetten naar WAV"
        ConvertFLAC = "Omzetten naar FLAC"
        ConvertAIFF = "Omzetten naar AIFF (Apple)"
        ConvertOpus = "Omzetten naar Opus"
        ConvertVorbis = "Omzetten naar Vorbis (.ogg)"
        ConvertMP3128 = "Omzetten naar MP3 (128 kbps)"
        ConvertMP3192 = "Omzetten naar MP3 (192 kbps)"
        ConvertMP3320 = "Omzetten naar MP3 (320 kbps)"
        ConvertMP3VBR0 = "Omzetten naar MP3 (VBR 220-260 kbps)"
        ConvertAAC = "Omzetten naar AAC (Apple)"
        Mono = "Stereo naar mono"
        Resample96000 = "Naar 96000 Hz resampelen"
        Resample48000 = "Naar 48000 Hz resampelen"
        Resample44100 = "Naar 44100 Hz resampelen"
        Resample22050 = "Naar 22050 Hz resampelen"
        Resample11025 = "Naar 11025 Hz resampelen"
        NormalizeLUFS = "Normaliseren (Spotify)"
        ExtractAudio = "Audio extraheren (cleanest)"
        ExtractFLAC = "Audio extraheren (FLAC)"
        ExtractWAV = "Audio extraheren (WAV)"
        ExtractMP3 = "Audio extraheren (MP3)"
        ExtractOpus = "Audio extraheren (Opus)"
    }
    german = @{
        MenuRoot = "SoundSheriff"
        ConvertWAV = "In WAV konvertieren"
        ConvertFLAC = "In FLAC konvertieren"
        ConvertAIFF = "In AIFF konvertieren (Apple)"
        ConvertOpus = "In Opus konvertieren"
        ConvertVorbis = "In Vorbis konvertieren (.ogg)"
        ConvertMP3128 = "In MP3 konvertieren (128 kbps)"
        ConvertMP3192 = "In MP3 konvertieren (192 kbps)"
        ConvertMP3320 = "In MP3 konvertieren (320 kbps)"
        ConvertMP3VBR0 = "In MP3 konvertieren (VBR 220-260 kbps)"
        ConvertAAC = "In AAC konvertieren (Apple)"
        Mono = "Stereo zu Mono"
        Resample96000 = "Auf 96000 Hz resamplen"
        Resample48000 = "Auf 48000 Hz resamplen"
        Resample44100 = "Auf 44100 Hz resamplen"
        Resample22050 = "Auf 22050 Hz resamplen"
        Resample11025 = "Auf 11025 Hz resamplen"
        NormalizeLUFS = "Normalisieren (Spotify)"
        ExtractAudio = "Audio extrahieren (beste Qualitaet)"
        ExtractFLAC = "Audio extrahieren (FLAC)"
        ExtractWAV = "Audio extrahieren (WAV)"
        ExtractMP3 = "Audio extrahieren (MP3)"
        ExtractOpus = "Audio extrahieren (Opus)"
    }
    french = @{
        MenuRoot = "SoundSheriff"
        ConvertWAV = "Convertir en WAV"
        ConvertFLAC = "Convertir en FLAC"
        ConvertAIFF = "Convertir en AIFF (Apple)"
        ConvertOpus = "Convertir en Opus"
        ConvertVorbis = "Convertir en Vorbis (.ogg)"
        ConvertMP3128 = "Convertir en MP3 (128 kbps)"
        ConvertMP3192 = "Convertir en MP3 (192 kbps)"
        ConvertMP3320 = "Convertir en MP3 (320 kbps)"
        ConvertMP3VBR0 = "Convertir en MP3 (VBR 220-260 kbps)"
        ConvertAAC = "Convertir en AAC (Apple)"
        Mono = "Stereo vers mono"
        Resample96000 = "Reechantillonner en 96000 Hz"
        Resample48000 = "Reechantillonner en 48000 Hz"
        Resample44100 = "Reechantillonner en 44100 Hz"
        Resample22050 = "Reechantillonner en 22050 Hz"
        Resample11025 = "Reechantillonner en 11025 Hz"
        NormalizeLUFS = "Normaliser (Spotify)"
        ExtractAudio = "Extraire l'audio (meilleure qualite)"
        ExtractFLAC = "Extraire l'audio (FLAC)"
        ExtractWAV = "Extraire l'audio (WAV)"
        ExtractMP3 = "Extraire l'audio (MP3)"
        ExtractOpus = "Extraire l'audio (Opus)"
    }
}

if (-not $translations.ContainsKey($languageKey)) {
    $languageKey = "english"
}

$strings = $translations[$languageKey]

$topLevelExtensions = @(
    ".wav", ".aiff", ".flac", ".mp3", ".wma", ".opus", ".ogg", ".aac", ".m4a",
    ".mp4", ".avi", ".mov", ".webm"
)

foreach ($extension in $topLevelExtensions) {
    $key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\$extension\shell\Convert"
    Set-ItemProperty -LiteralPath $key -Name "MUIVerb" -Value $strings.MenuRoot
}

$commandStoreRoot = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CommandStore\shell"
$commandVerbs = @{
    "Convert.WAV" = $strings.ConvertWAV
    "Convert.FLAC" = $strings.ConvertFLAC
    "Convert.AIFF" = $strings.ConvertAIFF
    "Convert.Opus" = $strings.ConvertOpus
    "Convert.Vorbis" = $strings.ConvertVorbis
    "Convert.MP3_128kbps" = $strings.ConvertMP3128
    "Convert.MP3_192kbps" = $strings.ConvertMP3192
    "Convert.MP3_320kbps" = $strings.ConvertMP3320
    "Convert.MP3_vbr0" = $strings.ConvertMP3VBR0
    "Convert.MP3_vbr0_separator" = $strings.ConvertMP3VBR0
    "Convert.AAC" = $strings.ConvertAAC
    "Convert.Mono" = $strings.Mono
    "Convert.Resample96000" = $strings.Resample96000
    "Convert.Resample48000" = $strings.Resample48000
    "Convert.Resample44100" = $strings.Resample44100
    "Convert.Resample22050" = $strings.Resample22050
    "Convert.Resample11025" = $strings.Resample11025
    "Convert.NormalizeLUFS" = $strings.NormalizeLUFS
    "Convert.ExtractAudio" = $strings.ExtractAudio
    "Convert.ExtractFLAC" = $strings.ExtractFLAC
    "Convert.ExtractWAV" = $strings.ExtractWAV
    "Convert.ExtractMP3" = $strings.ExtractMP3
    "Convert.ExtractOpus" = $strings.ExtractOpus
}

foreach ($verb in $commandVerbs.Keys) {
    Set-ItemProperty -LiteralPath (Join-Path $commandStoreRoot $verb) -Name "MUIVerb" -Value $commandVerbs[$verb]
}
