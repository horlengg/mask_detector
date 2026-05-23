

class MaskDetectorException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  MaskDetectorException(
    this.message, {
    this.code,
    this.details,
  });
  
  String what() {
    final buffer = StringBuffer('MaskDetectorException: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }

  @override
  String toString() {
    return what();
  }
}