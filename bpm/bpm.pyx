# bpm_techno_precise.py
import sys
import numpy as np
import soundfile as sf
import scipy

def load_audio(path, target_sr=30000):
    y, sr = sf.read(path, dtype='float32')
    if y.ndim > 1:
        y = y.mean(axis=1)
    if sr != target_sr:
        y = scipy.signal.resample_poly(y, target_sr, sr)
        sr = target_sr
    return y, sr

def smart_round(x, margin=0.01):
    """
    Round x to nearest integer if within `margin`, else leave as float.
    """
    nearest = round(x)
    if abs(x - nearest) < margin:
        return nearest
    return x

def format_number_precise(x, decimals=5):
    if x == int(x):
        return str(int(x))
    return f"{x:.{decimals}f}".rstrip('0').rstrip('.')  # remove trailing zeros

def parabolic(f, x):
    """Parabolic interpolation for a maximum."""
    xv = 1/2. * (f[x-1] - f[x+1]) / (f[x-1] - 2*f[x] + f[x+1]) + x
    yv = f[x] - 1/4. * (f[x-1] - f[x+1]) * (xv - x)
    return xv, yv

def detect_bpm(filename, min_bpm=120, max_bpm=250, hop_length=40, n_fft=1024):
    # Load audio
    y, sr = librosa.load(filename, sr=30000, mono=True)

    # Trim silence
    y_trim, _ = librosa.effects.trim(y, top_db=20)

    # Onset envelope
    onset_env = librosa.onset.onset_strength(y=y_trim, sr=sr, hop_length=hop_length, n_fft=n_fft)

    # Autocorrelation
    ac = np.correlate(onset_env, onset_env, mode='full')
    ac = ac[len(ac)//2:]  # positive lags

    # Convert BPM limits to lag indices
    fps = sr / hop_length
    min_lag = int(np.floor(fps * 60 / max_bpm))
    max_lag = int(np.ceil(fps * 60 / min_bpm))

    ac_segment = ac[min_lag:max_lag+1]
    peak_index = np.argmax(ac_segment)

    # Parabolic interpolation for sub-frame precision
    true_index, _ = parabolic(ac_segment, peak_index)
    lag = min_lag + true_index

    bpm = 60.0 * fps / lag
    return smart_round(bpm)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bpm.py <audio_file>")
        sys.exit(1)

    audio_file = sys.argv[1]
    bpm = detect_bpm(audio_file)
    print(f"Estimated BPM: {format_number_precise(bpm)}")
