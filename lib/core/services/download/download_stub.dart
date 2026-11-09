import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndDownloadFile({
  required String fileName,
  required String content,
  String mimeType = 'text/plain',
}) async {
  Directory dir;
  try {
    dir = await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = Directory.systemTemp;
  }
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}

