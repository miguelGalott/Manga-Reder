import 'package:mongo_dart/mongo_dart.dart';
import '../models/comment.dart';
import 'mongo_service.dart';

class CommentsService {
  static Future<void> addComment({
    required String username,
    required String mangaId,
    required String text,
    required int rating,
  }) async {
    final comments = await MongoService.collection('comments');
    await comments.insertOne({
      'username': username,
      'mangaId': mangaId,
      'text': text,
      'rating': rating,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<CommentEntry>> listComments(String mangaId) async {
    final comments = await MongoService.collection('comments');
    final docs = await comments
        .find(where.eq('mangaId', mangaId).sortBy('createdAt', descending: true))
        .toList();
    return docs.map((d) => CommentEntry.fromMap(d)).toList();
  }
}
