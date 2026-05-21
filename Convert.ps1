$InputFile = $args[0]
$OutputExt = $args[1]

. "$PSScriptRoot\SoundSheriff.Tools.ps1"



if ($OutputExt.Equals("wav")) {

    if ($args.Count -ge 3) {

        $Key   = ($args[2] -split "=")[0]
        $Value = ($args[2] -split "=")[1]
        $Options = ""

    } else {

        # Default wav conversion based on input, with matched bit depth


        # Run ffprobe to get the sample format
        $SampleFmt = & $FFprobe -v error -select_streams a:0 `
            -show_entries stream=bits_per_raw_sample `
            -of default=noprint_wrappers=1:nokey=1 $InputFile

        # Map FFmpeg sample_fmt to bit depth
        switch ($SampleFmt) {
            "24"  { $Codec = "pcm_s24le" }
            "32"  { $Codec = "pcm_f32le" } # so that FLAC 32-bit will become WAV 32-bit float
            #"flt" { $Codec = "pcm_f32le" }
            default { $Codec = "pcm_s16le" }
        }
        
        Write-Output "Detected format: $SampleFmt  codec $Codec"

        $Options = "-c:a $Codec"


    }
}

elseif ($OutputExt.Equals("aiff")) {
    #$Options = ""
}

elseif ($OutputExt.Equals("flac")) {
    $Options = "-c:a flac -compression_level 12"
}

if ($OutputExt.Equals("mp3")) {
    $Options = "-codec:a libmp3lame"
    
    $Key   = ($args[2] -split "=")[0]
    $Value = ($args[2] -split "=")[1]
    switch ($Key) {
        "vbr" {
            $Options = "$Options -qscale:a $Value"
        }
        "cbr" {
            $Options = "$Options -b:a ${Value}k"
        }
    }
}

elseif ($OutputExt.Equals("ogg")) {
    $Options = "-c:a libvorbis -qscale:a 10"
}

elseif ($OutputExt.Equals("opus")) {
    $Options = "-c:a libopus -vbr on -compression_level 10"
}

elseif ($OutputExt.Equals("aac")) {
    $Options = "-c:a aac -b:a 256k"
}

$Options = "$Options -map_metadata 0"




$OutputFile = [System.IO.Path]::Combine(
    (Split-Path $InputFile), 
    "$([System.IO.Path]::GetFileNameWithoutExtension($InputFile)).$OutputExt"
)

& $FFmpeg -y -i $InputFile $($Options -split ' ') $OutputFile

#Pause
