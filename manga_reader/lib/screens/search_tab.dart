import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/mangadex_api.dart';
import '../widgets/manga_cover.dart';
import 'manga_detail_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  List<Manga> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await MangaDexApi.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao buscar: $e';
        _loading = false;
        _searched = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar mangás')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(labelText: 'Título do mangá'),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _search, icon: const Icon(Icons.search)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (!_searched) return const Center(child: Text('Busque por um título de mangá acima'));
    if (_results.isEmpty) return const Center(child: Text('Nenhum resultado encontrado'));

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final manga = _results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: MangaCover(url: manga.coverUrl, width: 48, height: 68),
          title: Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: manga.status != null ? Text(manga.status!) : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MangaDetailScreen(manga: manga)),
          ),
        );
      },
    );
  }
}
