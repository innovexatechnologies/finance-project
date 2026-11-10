import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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

  Directory dir;
  try {
    if (!kIsWeb && Platform.isAndroid) {
      dir = (await getExternalStorageDirectory()) ??
          (await getApplicationDocumentsDirectory());
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
  } catch (_) {
    dir = Directory.systemTemp;
  }

  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(fileBytes, flush: true);

  // If on Windows, also reveal in File Explorer
  if (!kIsWeb && Platform.isWindows) {
    try {
      Process.run('explorer.exe', ['/select,', file.path]);
    } catch (_) {}
  }

  return file.path;
}

Future<void> openDownloadedFile({
  required String fileName,
  required String filePath,
  Uint8List? bytes,
  String? content,
  String mimeType = 'application/pdf',
}) async {
  if (kIsWeb) return;

  try {
    // 1. Windows platform
    if (Platform.isWindows) {
      try {
        final res = await Process.run(
          'cmd',
          ['/c', 'start', '""', filePath],
          runInShell: true,
        );
        if (res.exitCode == 0) return;
      } catch (_) {}
    }

    // 2. OpenFilex for Android, iOS, Windows, macOS, Linux
    final result = await OpenFilex.open(filePath, type: mimeType);
    if (result.type != ResultType.done && Platform.isWindows) {
      Process.run('explorer.exe', [filePath]);
    }
  } catch (e) {
    debugPrint('Error opening downloaded file: $e');
  }
}
