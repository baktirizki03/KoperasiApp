import 'dart:io';

class FileValidationResult {
  final bool isValid;
  final String? errorMessage;

  FileValidationResult({required this.isValid, this.errorMessage});
}

class FileValidator {
  static const int maxSizeBytes = 5 * 1024 * 1024; // 5 MB in bytes
  static const List<String> defaultAllowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static const List<String> imageOnlyExtensions = ['jpg', 'jpeg', 'png'];

  /// Validates a [File] based on size and extension.
  static Future<FileValidationResult> validateFile(
    File file, {
    List<String> allowedExtensions = defaultAllowedExtensions,
    int maxBytes = maxSizeBytes,
    String fileLabel = 'File',
  }) async {
    if (!await file.exists()) {
      return FileValidationResult(
        isValid: false,
        errorMessage: '$fileLabel tidak ditemukan.',
      );
    }

    final length = await file.length();
    if (length > maxBytes) {
      return FileValidationResult(
        isValid: false,
        errorMessage: '$fileLabel melebihi kapasitas maksimum 5 MB.',
      );
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      final allowedStr = allowedExtensions.map((e) => e.toUpperCase()).join(', ');
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Format $fileLabel tidak didukung. Harap unggah file berformat ($allowedStr).',
      );
    }

    return FileValidationResult(isValid: true);
  }

  /// Validates raw [bytes] and [filename] based on size and extension.
  static FileValidationResult validateBytes(
    List<int> bytes,
    String filename, {
    List<String> allowedExtensions = defaultAllowedExtensions,
    int maxBytes = maxSizeBytes,
    String fileLabel = 'File',
  }) {
    if (bytes.length > maxBytes) {
      return FileValidationResult(
        isValid: false,
        errorMessage: '$fileLabel melebihi kapasitas maksimum 5 MB.',
      );
    }

    final ext = filename.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      final allowedStr = allowedExtensions.map((e) => e.toUpperCase()).join(', ');
      return FileValidationResult(
        isValid: false,
        errorMessage: 'Format $fileLabel tidak didukung. Harap unggah file berformat ($allowedStr).',
      );
    }

    return FileValidationResult(isValid: true);
  }
}
