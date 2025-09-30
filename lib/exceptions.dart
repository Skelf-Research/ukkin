class ModelDownloadException implements Exception {
  final String message;

  ModelDownloadException(this.message);

  @override
  String toString() => 'ModelDownloadException: $message';
}
