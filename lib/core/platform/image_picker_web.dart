// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

class PickedImageData {
  const PickedImageData({
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    required this.base64,
  });

  final String name;
  final String mimeType;
  final int sizeBytes;
  final String base64;
}

Future<PickedImageData?> pickPortfolioImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp';
  input.click();
  await input.onChange.first;
  final selected = input.files;
  if (selected == null || selected.isEmpty) return null;
  final file = selected.first;
  final reader = html.FileReader()..readAsArrayBuffer(file);
  await reader.onLoad.first;
  final bytes = (reader.result as List<int>?) ?? const <int>[];
  if (bytes.isEmpty) return null;
  return PickedImageData(
    name: file.name,
    mimeType: file.type,
    sizeBytes: file.size,
    base64: base64Encode(bytes),
  );
}
