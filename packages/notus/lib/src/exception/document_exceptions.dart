class NotSupportedFormatException implements Exception {
  final String message;
  const NotSupportedFormatException(this.message);

  @override
  String toString() => message;
}
