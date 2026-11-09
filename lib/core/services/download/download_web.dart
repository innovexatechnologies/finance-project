// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

Future<String> saveAndDownloadFile({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  // Keep URL valid for 1 minute so browser completes file download
  Future.delayed(const Duration(minutes: 1), () {
    try {
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  });

  return fileName;
}
