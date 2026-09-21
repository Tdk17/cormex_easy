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

Future<PickedImageData?> pickPortfolioImage() async => null;
