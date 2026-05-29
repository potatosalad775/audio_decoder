import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Read a little-endian uint16 from [bytes] at [offset].
int readUint16LE(Uint8List bytes, int offset) => bytes[offset] | (bytes[offset + 1] << 8);

/// Read a little-endian uint32 from [bytes] at [offset].
int readUint32LE(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16) | (bytes[offset + 3] << 24);

/// Build a synthetic mono 16-bit PCM WAV with [frameCount] frames and a
/// non-silent sawtooth waveform.
///
/// Used to exercise long-file code paths on device without bundling a large
/// asset in the repository.
Uint8List buildPcmWav({required int frameCount, int sampleRate = 44100}) {
  const channels = 1;
  const bytesPerSample = 2; // 16-bit
  final dataSize = frameCount * channels * bytesPerSample;
  final bytes = Uint8List(44 + dataSize);
  final view = ByteData.view(bytes.buffer);

  bytes.setRange(0, 4, 'RIFF'.codeUnits);
  view.setUint32(4, 36 + dataSize, Endian.little);
  bytes.setRange(8, 12, 'WAVE'.codeUnits);
  bytes.setRange(12, 16, 'fmt '.codeUnits);
  view.setUint32(16, 16, Endian.little);
  view.setUint16(20, 1, Endian.little); // PCM
  view.setUint16(22, channels, Endian.little);
  view.setUint32(24, sampleRate, Endian.little);
  view.setUint32(28, sampleRate * channels * bytesPerSample, Endian.little);
  view.setUint16(32, channels * bytesPerSample, Endian.little);
  view.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, 'data'.codeUnits);
  view.setUint32(40, dataSize, Endian.little);

  // Sawtooth payload so every window has a non-zero RMS.
  for (var i = 0; i < frameCount; i++) {
    view.setInt16(44 + i * bytesPerSample, ((i * 137) % 65536) - 32768, Endian.little);
  }
  return bytes;
}

/// Validate the WAV header structure of [bytes] and return a map with
/// the parsed header fields.
Map<String, int> validateWavHeader(Uint8List bytes) {
  expect(
    bytes.length,
    greaterThan(44),
    reason: 'WAV file must be larger than 44-byte header',
  );
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
  expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');

  final audioFormat = readUint16LE(bytes, 20);
  expect(audioFormat, 1, reason: 'Audio format should be PCM (1)');

  final channels = readUint16LE(bytes, 22);
  final sampleRate = readUint32LE(bytes, 24);
  final bitsPerSample = readUint16LE(bytes, 34);

  expect(channels, greaterThan(0));
  expect(sampleRate, greaterThan(0));
  expect(bitsPerSample, greaterThan(0));

  return {
    'channels': channels,
    'sampleRate': sampleRate,
    'bitsPerSample': bitsPerSample,
  };
}
