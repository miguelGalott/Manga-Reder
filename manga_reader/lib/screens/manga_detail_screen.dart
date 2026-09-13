import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../models/comment.dart';
import '../models/manga.dart';
import '../services/comments_service.dart';
import '../services/favorites_service.dart';
import '../services/mangadex_api.dart';
import '../state/app_state.dart';
import '../widgets/manga_cover.dart';
import 'reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final Manga manga;
  const MangaDetailScreen({super.key, required this.manga});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  List<Chapter> _chapters = [];
  List<CommentEntry> _comments = [];
  bool _loadingChapters = true;
  bool _loadingComments = true;
  bool _isFavorite = false;
  String? _error;
  final _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _sendingComment = false;

  String get _username => context.read<AppState>().username!;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _loadFavoriteState();
    _loadComments();
  }

  Future<void> _loadChapters() async {
    try {
      final chapters = await MangaDexApi.chapters(widget.manga.id);
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _loadingChapters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar capítulos: $e';
        _loadingChapters = false;
      });
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final fav = await FavoritesService.isFavorite(_username, widget.manga.id);
      if (!mounted) return;
      setState(() => _isFavorite = fav);
    } catch (_) {
      // Se o Mongo estiver fora do ar, mantém como "não favorito" sem travar a tela.
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommentsService.listComments(widget.manga.id);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final newState = !_isFavorite;
    setState(() => _isFavorite = newState); // atualização otimista
    try {
      if (newState) {
        await FavoritesService.addFavorite(_username, widget.manga);
      } else {
        await FavoritesService.removeFavorite(_username, widget.manga.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = !newState); // desfaz se der erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $e')),
      );
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await CommentsService.addComment(
        username: _username,
        mangaId: widget.manga.id,
        text: text,
        rating: _selectedRating,
      );
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  double _averageRating() {
    final rated = _comments.where((c) => c.rating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.map((c) => c.rating).reduce((a, b) => a + b) / rated.length;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    return Scaffold(
      appBar: AppBar(
        title: Text(manga.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MangaCover(url: manga.coverUrl, width: 100, height: 140, borderRadius: 10),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(manga.title, style: Theme.of(context).textTheme.titleLarge),
                    if (manga.status != null) ...[
                      const SizedBox(height: 6),
                      Text(manga.status!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 6),
                    if (_comments.any((c) => c.rating > 0))
                      Text(
                        '★ ${_averageRating().toStringAsFixed(1)} '
                        '(${_comments.where((c) => c.rating > 0).length} avaliações)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Capítulos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildChapters(),
          const SizedBox(height: 24),
          Text('Comentários', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildAddComment(),
          const SizedBox(height: 12),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _buildChapters() {
    if (_loadingChapters) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
    if (_chapters.isEmpty) return const Text('Nenhum capítulo encontrado');

    return Column(
      children: _chapters
          .map((chapter) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(chapter.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      manga: widget.manga,
                      chapters: _chapters,
                      initialIndex: _chapters.indexOf(chapter),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAddComment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _selectedRating = starIndex),
              icon: Icon(
                starIndex <= _selectedRating ? Icons.star : Icons.star_border,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Deixe um comentário sobre esse mangá...'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _sendingComment ? null : _sendComment,
            child: _sendingComment
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Comentar'),
          ),
        ),
      ],
    );
  }

  Widget _buildComments() {
    if (_loadingComments) return const Center(child: CircularProgressIndicator());
    if (_comments.isEmpty) return const Text('Nenhum comentário ainda. Seja o primeiro!');
    return Column(
      children: _comments
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(c.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (c.rating > 0)
                          Text('★' * c.rating, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(c.text),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
