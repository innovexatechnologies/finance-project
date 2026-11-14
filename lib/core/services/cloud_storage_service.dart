import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:link_vibe/core/services/supabase_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Metadata returned after picking and uploading a file to Supabase Storage.
class CloudUploadResult {
  final String fileName;
  final int sizeBytes;
  final String sizeLabel;
  final String url;
  final String bucket;
  final String objectPath;

  const CloudUploadResult({
    required this.fileName,
    required this.sizeBytes,
    required this.sizeLabel,
    required this.url,
    required this.bucket,
    required this.objectPath,
  });
}

/// Shared Supabase Storage upload + signed-URL launcher service across
/// Student, Company, and Admin portals.
class CloudStorageService {
  CloudStorageService._();

  static const int maxUploadBytes = 15 * 1024 * 1024; // 15 MB
  static const Set<String> _privateBuckets = {
    'student-docs',
    'company-assets',
  };

  static const List<String> documentExtensions = [
    'pdf',
    'doc',
    'docx',
    'png',
    'jpg',
    'jpeg',
  ];

  static const List<String> deliverableExtensions = [
    'pdf',
    'zip',
    'apk',
    'doc',
    'docx',
    'png',
    'jpg',
    'jpeg',
    'txt',
  ];

  /// Prompts the user to pick a file via native system picker and uploads it to
  /// `<userId>/<folder>/<timestamp>_<safeName>` inside [bucket].
  /// Returns `null` if the user cancels. Throws a descriptive [Exception]
  /// if unauthenticated, offline, oversized, or upload fails.
  static Future<CloudUploadResult?> pickAndUploadFile({
    required String bucket,
    required String folder,
    String dialogTitle = 'Select File to Upload',
    List<String> allowedExtensions = documentExtensions,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw Exception(
        'Please sign in with a live cloud account to upload files.',
      );
    }

    final picked = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected file is empty or unreadable.');
    }
    if (bytes.length > maxUploadBytes) {
      throw Exception('File exceeds the 15 MB cloud upload limit.');
    }

    final safeName = sanitizeFileName(picked.name);
    final ext = extensionFromName(safeName);
    final cleanFolder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final prefix = cleanFolder.isEmpty ? user.id : '${user.id}/$cleanFolder';
    final objectPath =
        '$prefix/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final url = await uploadBytes(
      bucket: bucket,
      objectPath: objectPath,
      bytes: bytes,
      contentType: mimeTypeForExtension(ext),
    );

    return CloudUploadResult(
      fileName: picked.name,
      sizeBytes: bytes.length,
      sizeLabel: formatBytes(bytes.length),
      url: url,
      bucket: bucket,
      objectPath: objectPath,
    );
  }

  /// Picks an image from gallery (via `image_picker`) and uploads it to a
  /// public storage bucket (e.g. `public-files`). Returns `null` if canceled.
  static Future<CloudUploadResult?> pickAndUploadImage({
    required String bucket,
    required String folder,
    double maxWidth = 720,
    int imageQuality = 85,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    final user = supabase?.auth.currentUser;
    if (supabase == null || user == null) {
      throw Exception(
        'Please sign in with a live cloud account to upload images.',
      );
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected image could not be read.');
    }
    if (bytes.length > maxUploadBytes) {
      throw Exception('Image exceeds the 15 MB cloud upload limit.');
    }

    final safeName = sanitizeFileName(picked.name);
    final ext = extensionFromName(safeName, fallback: 'jpg');
    final cleanFolder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final prefix = cleanFolder.isEmpty ? user.id : '${user.id}/$cleanFolder';
    final objectPath =
        '$prefix/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final url = await uploadBytes(
      bucket: bucket,
      objectPath: objectPath,
      bytes: bytes,
      contentType: mimeTypeForExtension(ext),
    );

    return CloudUploadResult(
      fileName: picked.name,
      sizeBytes: bytes.length,
      sizeLabel: formatBytes(bytes.length),
      url: url,
      bucket: bucket,
      objectPath: objectPath,
    );
  }

  /// Uploads raw [bytes] directly to [bucket]/[objectPath] and returns its
  /// canonical Supabase Storage URL.
  static Future<String> uploadBytes({
    required String bucket,
    required String objectPath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final supabase = SupabaseHelper.clientOrNull;
    if (supabase == null) {
      throw Exception('Supabase storage client is unavailable.');
    }

    await supabase.storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    return supabase.storage.from(bucket).getPublicUrl(objectPath);
  }

  /// Extracts `(bucket, objectPath)` if [rawUrl] points to Supabase Storage,
  /// regardless of `public`, `authenticated`, or `sign` path form.
  static ({String bucket, String objectPath})? extractStorageLocation(
    String rawUrl,
  ) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) return null;
    final segs = uri.pathSegments;
    // Expected: ['storage', 'v1', 'object', '<mode>', '<bucket>', ...<path>]
    final objIdx = segs.indexOf('object');
    if (objIdx == -1 || objIdx + 3 >= segs.length) return null;
    final mode = segs[objIdx + 1];
    if (mode != 'public' && mode != 'authenticated' && mode != 'sign') {
      return null;
    }
    final bucket = segs[objIdx + 2];
    final objectPath = segs.sublist(objIdx + 3).join('/');
    if (bucket.isEmpty || objectPath.isEmpty) return null;
    return (bucket: bucket, objectPath: objectPath);
  }

  /// Resolves a private-bucket Supabase Storage URL to a 1-hour signed URL so
  /// external browsers and PDF viewers can open it securely. External URLs and
  /// public-bucket URLs are normalized and returned directly.
  static Future<String> resolveOpenableUrl(String rawUrl) async {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }

    final loc = extractStorageLocation(trimmed);
    if (loc != null && _privateBuckets.contains(loc.bucket)) {
      final supabase = SupabaseHelper.clientOrNull;
      if (supabase != null) {
        try {
          final signed = await supabase.storage
              .from(loc.bucket)
              .createSignedUrl(loc.objectPath, 3600);
          if (signed.isNotEmpty) return signed;
        } catch (e) {
          debugPrint(
            'CloudStorageService createSignedUrl warning (${loc.bucket}/${loc.objectPath}): $e',
          );
        }
      }
    }
    return trimmed;
  }

  /// Resolves [rawUrl] (generating a signed URL when needed for private
  /// buckets) and opens it externally, with clipboard fallback + SnackBar UI.
  static Future<void> openUrl(
    BuildContext context,
    String rawUrl, {
    String label = 'Document',
    bool copyFallback = true,
  }) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    final openable = await resolveOpenableUrl(trimmed);
    final uri = Uri.tryParse(openable);
    if (uri != null && uri.hasScheme) {
      try {
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (e) {
        debugPrint('CloudStorageService launchUrl warning: $e');
      }
    }

    if (copyFallback) {
      await Clipboard.setData(ClipboardData(text: openable));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label link copied to clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open $label link.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Extracts a human-readable filename from a Supabase Storage URL or path.
  static String displayNameFromUrl(
    String? rawUrl, {
    String fallback = 'Attached Document',
  }) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    final uri = Uri.tryParse(trimmed);
    final seg = uri != null && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.lastWhere(
            (s) => s.trim().isNotEmpty,
            orElse: () => '',
          )
        : '';
    if (seg.isEmpty) return fallback;
    // Strip leading `<epochMs>_` upload prefix when present for cleaner display.
    final cleaned = seg.replaceFirst(RegExp(r'^\d{13}_'), '');
    return cleaned.isNotEmpty ? cleaned : seg;
  }

  static String sanitizeFileName(String name) {
    final base = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return base.isEmpty ? 'file_${DateTime.now().millisecondsSinceEpoch}' : base;
  }

  static String extensionFromName(String name, {String fallback = 'bin'}) {
    final idx = name.lastIndexOf('.');
    if (idx == -1 || idx == name.length - 1) return fallback;
    final ext = name.substring(idx + 1).toLowerCase().replaceAll('.', '');
    return ext.isEmpty ? fallback : ext;
  }

  static String mimeTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'zip':
        return 'application/zip';
      case 'apk':
        return 'application/vnd.android.package-archive';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
