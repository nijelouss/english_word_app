class GeminiException implements Exception {
  final String message;
  const GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}

class ImageDownloadException implements Exception {
  final String message;
  const ImageDownloadException(this.message);

  @override
  String toString() => 'ImageDownloadException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutAppException implements Exception {
  final String message;
  const TimeoutAppException(this.message);

  @override
  String toString() => 'TimeoutAppException: $message';
}
