import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The biggest photo the server accepts.
const maxImageBytes = 5 * 1024 * 1024;

/// A photo chosen from the device, ready to upload.
class PickedImage {
  const PickedImage({required this.name, required this.bytes, required this.mimeType});

  final String name;
  final Uint8List bytes;

  /// image/jpeg, image/png or image/webp.
  final String mimeType;

  /// "2.4 MB" / "310 KB".
  String get sizeLabel {
    final kb = bytes.length / 1024;
    return kb >= 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '${kb.round()} KB';
  }
}

/// Why a chosen file cannot be used (shown to the admin), or null when it is fine.
class ImageProblem implements Exception {
  const ImageProblem(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The real image type from the first bytes (not the file name), or null if it is not JPG, PNG or WebP.
String? sniffImageMime(Uint8List b) {
  if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) return 'image/jpeg';
  const png = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (b.length >= 8 && [for (var i = 0; i < 8; i++) b[i] == png[i]].every((x) => x)) return 'image/png';
  if (b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

/// Checks a chosen file and wraps it as a [PickedImage]; throws [ImageProblem] with a friendly message.
PickedImage validateImage(String name, Uint8List bytes) {
  if (bytes.isEmpty) throw const ImageProblem('That file is empty. Choose another photo.');
  if (bytes.length > maxImageBytes) {
    throw const ImageProblem('That photo is larger than 5 MB. Choose a smaller one.');
  }
  final mime = sniffImageMime(bytes);
  if (mime == null) throw const ImageProblem('Choose a JPG, PNG or WebP photo.');
  return PickedImage(name: name, bytes: bytes, mimeType: mime);
}

/// Opens the device's file picker for a photo. Returns null if the admin cancels.
Future<PickedImage?> pickImageFromDevice() async {
  final file = await FilePicker.pickFile(type: FileType.image);
  if (file == null) return null;
  return validateImage(file.name, await file.readAsBytes());
}

/// How the app asks for a photo (replaced in tests).
final imagePickerProvider = Provider<Future<PickedImage?> Function()>((ref) => pickImageFromDevice);
