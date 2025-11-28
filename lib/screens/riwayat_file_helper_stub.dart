// Stub for web - File operations not available
import 'dart:typed_data';

Future<Uint8List?> readFileBytes(String path) async {
  // Not supported on web
  return null;
}

Future<bool> fileExists(String path) async {
  return false;
}
