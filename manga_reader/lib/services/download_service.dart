import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<Directory> _dirFor(String mangaTitle, String chapterLabel) async {
    final base = await getApplicationDocumentsDirectory();
    final safeManga = _sanitize(mangaTitle);
    final safeChapter = _sanitize(chapterLabel);
    return Directory('${base.path}/MangaDownloads/$safeManga/$safeChapter');
  }

  /// Baixa todas as páginas de um capítulo para o armazenamento privado do
  /// app (não precisa de permissão de armazenamento).
  static Future<void> downloadChapter({
    required String mangaTitle,
    required String chapterLabel,
    required List<String> pageUrls,
    void Function(int current, int total)? onProgress,
  }) async {
    final dir = await _dirFor(mangaTitle, chapterLabel);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (var i = 0; i < pageUrls.length; i++) {
      final file =
          File('${dir.path}/page_${(i + 1).toString().padLeft(3, '0')}.jpg');
      if (!await file.exists()) {
        final response = await http.get(Uri.parse(pageUrls[i]));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        }
      }
      onProgress?.call(i + 1, pageUrls.length);
    }
  }

  /// Retorna os arquivos locais de um capítulo já baixado, ordenados,
  /// ou null se ele ainda não foi baixado.
  static Future<List<File>?> getLocalPages(
      String mangaTitle, String chapterLabel) async {
    final dir = await _dirFor(mangaTitle, chapterLabel);
    if (!await dir.exists()) return null;
    final files = dir.listSync().whereType<File>().toList();
    if (files.isEmpty) return null;
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  static String _sanitize(String name) {
    final cleaned =
        name.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '').trim().replaceAll(' ', '_');
    return cleaned.isEmpty ? 'manga' : cleaned;
  }
}
