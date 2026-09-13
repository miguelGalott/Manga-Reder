import 'package:mongo_dart/mongo_dart.dart';
import '../models/favorite.dart';
import '../models/manga.dart';
import 'mongo_service.dart';

class FavoritesService {
  static Future<void> addFavorite(String username, Manga manga) async {
    final favorites = await MongoService.collection('favorites');
    final exists = await favorites.findOne(
      where.eq('username', username).eq('mangaId', manga.id),
    );
    if (exists != null) return;
    await favorites.insertOne({
      'username': username,
      'mangaId': manga.id,
      'mangaTitle': manga.title,
      'coverUrl': manga.coverUrl,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> removeFavorite(String username, String mangaId) async {
    final favorites = await MongoService.collection('favorites');
    await favorites.deleteOne(
      where.eq('username', username).eq('mangaId', mangaId),
    );
  }

  static Future<bool> isFavorite(String username, String mangaId) async {
    final favorites = await MongoService.collection('favorites');
    final doc = await favorites.findOne(
      where.eq('username', username).eq('mangaId', mangaId),
    );
    return doc != null;
  }

  static Future<List<FavoriteEntry>> listFavorites(String username) async {
    final favorites = await MongoService.collection('favorites');
    final docs = await favorites
        .find(where.eq('username', username).sortBy('addedAt', descending: true))
        .toList();
    return docs.map((d) => FavoriteEntry.fromMap(d)).toList();
  }
}
