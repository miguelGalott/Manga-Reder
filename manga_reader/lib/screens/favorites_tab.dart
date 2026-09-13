import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/favorite.dart';
import '../models/manga.dart';
import '../services/favorites_service.dart';
import '../state/app_state.dart';
import '../widgets/manga_cover.dart';
import 'manga_detail_screen.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  List<FavoriteEntry> _favorites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = context.read<AppState>().username;
    if (username == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favorites = await FavoritesService.listFavorites(username);
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os favoritos: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        children: [Padding(padding: const EdgeInsets.all(24), child: Text(_error!))],
      );
    }
    if (_favorites.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Você ainda não favoritou nenhum mangá. Toque no coração na página de um mangá para salvá-lo aqui.',
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MangaDetailScreen(
              manga: Manga(id: fav.mangaId, title: fav.mangaTitle, coverUrl: fav.coverUrl),
            ),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MangaCover(
                  url: fav.coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fav.mangaTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
