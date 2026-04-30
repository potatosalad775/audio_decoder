# audio_decoder example

Demonstrates all features of the `audio_decoder` plugin in a Material 3
interface, with a gradient waveform visualization.

## Running the example

```bash
cd example
flutter run
```

## What's included

The app exposes every public method of the plugin behind tappable
buttons, grouped into sections: convert, audio info, trim, waveform
extraction (perFile and absolute normalization), and the in-memory
bytes API.

Three bundled test assets (1-second 440 Hz sine tone) are used to
exercise the different code paths:

- `test_tone.mp3`
- `test_tone.m4a`
- `test_tone.wav`
