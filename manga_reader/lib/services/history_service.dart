import 'package:mongo_dart/mongo_dart.dart';
import '../models/history_entry.dart';
import 'mongo_service.dart';

class HistoryService {
  /// Salva/atualiza o progresso de leitura do usuário nesse mangá.
  /// Existe no máximo um registro por (usuário, mangá) — é sempre
  /// sobrescrito com o capítulo/página mais recentes (upsert).
  static Future<void> updateProgress({
    required String username,
    required String mangaId,
    required String mangaTitle,
    String? coverUrl,
    required String chapterId,
    required String chapterLabel,
    required int pageIndex,
  }) async {
    final history = await MongoService.collection('reading_progress');
    final selector = where.eq('username', username).eq('mangaId', mangaId);
    final update = modify
        .set('mangaTitle', mangaTitle)
        .set('coverUrl', coverUrl)
        .set('chapterId', chapterId)
        .set('chapterLabel', chapterLabel)
        .set('pageIndex', pageIndex)
        .set('updatedAt', DateTime.now().toIso8601String());
    await history.updateOne(selector, update, upsert: true);
  }

  static Future<List<HistoryEntry>> listHistory(String username) async {
    final history = await MongoService.collection('reading_progress');
    final docs = await history
        .find(where.eq('username', username).sortBy('updatedAt', descending: true))
        .toList();
    return docs.map((d) => HistoryEntry.fromMap(d)).toList();
  }
}
