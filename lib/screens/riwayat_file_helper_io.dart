// IO implementation for mobile
import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFileBytes(String path) async {
  try {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
  } catch (e) {
    print('Error reading file: $e');
  }
  return null;
}

Future<bool> fileExists(String path) async {
  try {
    final file = File(path);
    return await file.exists();
  } catch (e) {
    return false;
  }
}
