import 'dart:io';
import 'package:flutter/foundation.dart';
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

  // If on Windows, automatically reveal in File Explorer
  if (!kIsWeb && Platform.isWindows) {
    try {
      Process.run('explorer.exe', ['/select,', file.path]);
    } catch (_) {}
  }

  return file.path;
}

void openDownloadedFile({
  required String fileName,
  required String content,
  required String filePath,
}) {
  try {
    if (!kIsWeb && Platform.isWindows) {
      Process.run('notepad.exe', [filePath]);
    }
  } catch (_) {}
}
