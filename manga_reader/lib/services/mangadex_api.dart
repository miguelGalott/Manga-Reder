import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';
import '../models/chapter.dart';

class MangaDexApi {
  static const _baseUrl = 'https://api.mangadex.org';

  static Future<List<Manga>> search(String title) async {
    if (title.trim().isEmpty) return [];
    final uri = Uri.parse('$_baseUrl/manga').replace(queryParameters: {
      'title': title,
      'limit': '20',
      'includes[]': 'cover_art',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar mangás (${response.statusCode})');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>? ?? []);
    return data.map((e) => Manga.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Busca capítulos em português; se não houver nenhum traduzido,
  /// cai para inglês automaticamente.
  static Future<List<Chapter>> chapters(String mangaId) async {
    Future<List<dynamic>> fetchLang(String lang) async {
      final uri =
          Uri.parse('$_baseUrl/manga/$mangaId/feed').replace(queryParameters: {
        'translatedLanguage[]': lang,
        'order[chapter]': 'asc',
        'limit': '100',
        'offset': '0',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Erro ao carregar capítulos (${response.statusCode})');
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['data'] as List<dynamic>? ?? [];
    }

    var data = await fetchLang('pt-br');
    if (data.isEmpty) {
      data = await fetchLang('en');
    }

    final list =
        data.map((e) => Chapter.fromJson(e as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.sortValue.compareTo(b.sortValue));
    return list;
  }

  /// Retorna as URLs completas de todas as páginas de um capítulo.
  static Future<List<String>> pageUrls(String chapterId) async {
    final uri = Uri.parse('$_baseUrl/at-home/server/$chapterId');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar páginas (${response.statusCode})');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final baseUrl = body['baseUrl'] as String;
    final chapter = body['chapter'] as Map<String, dynamic>;
    final hash = chapter['hash'] as String;
    final files = (chapter['data'] as List<dynamic>? ?? []).cast<String>();
    return files.map((f) => '$baseUrl/data/$hash/$f').toList();
  }
}
