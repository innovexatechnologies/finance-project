// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveAndDownloadFile({
  required String fileName,
  Uint8List? bytes,
  String? content,
  String mimeType = 'application/pdf',
}) async {
  final fileBytes = bytes ??
      (content != null
          ? Uint8List.fromList(utf8.encode(content))
          : Uint8List(0));

  final blob = html.Blob([fileBytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  // Keep URL valid for 2 minutes so user can open/view or download
  Future.delayed(const Duration(minutes: 2), () {
    try {
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  });

  return url;
}

Future<void> openDownloadedFile({
  required String fileName,
  required String filePath,
  Uint8List? bytes,
  String? content,
  String mimeType = 'application/pdf',
}) async {
  try {
    String url = filePath;
    final fileBytes = bytes ??
        (content != null ? Uint8List.fromList(utf8.encode(content)) : null);
    if (fileBytes != null && fileBytes.isNotEmpty) {
      final blob = html.Blob([fileBytes], mimeType);
      url = html.Url.createObjectUrlFromBlob(blob);
    }
    if (url.isNotEmpty) {
      html.window.open(url, '_blank');
    }
  } catch (e) {
    // Fallback gracefully
  }
}
