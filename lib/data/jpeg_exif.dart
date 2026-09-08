import 'dart:typed_data';

/// Drops JPEG APP1 (EXIF) so shared photos do not leak GPS.
Uint8List stripJpegExif(List<int> input) {
  final bytes = input is Uint8List ? input : Uint8List.fromList(input);
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return Uint8List.fromList(bytes);
  }
  final out = BytesBuilder(copy: false);
  out.add([0xFF, 0xD8]);
  var i = 2;
  while (i + 1 < bytes.length) {
    if (bytes[i] != 0xFF) {
      out.add(bytes.sublist(i));
      break;
    }
    final marker = bytes[i + 1];
    if (marker == 0xD8) {
      i += 2;
      continue;
    }
    if (marker == 0xD9) {
      out.add([0xFF, 0xD9]);
      break;
    }
    if (marker == 0xDA) {
      out.add(bytes.sublist(i));
      break;
    }
    if (i + 3 >= bytes.length) {
      out.add(bytes.sublist(i));
      break;
    }
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    final end = i + 2 + len;
    if (end > bytes.length) {
      out.add(bytes.sublist(i));
      break;
    }
    final isApp1 = marker == 0xE1;
    if (!isApp1) {
      out.add(bytes.sublist(i, end));
    }
    i = end;
  }
  return out.toBytes();
}
