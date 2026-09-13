import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../models/manga.dart';
import '../services/history_service.dart';
import '../services/mangadex_api.dart';
import '../state/app_state.dart';
import '../widgets/manga_cover.dart';
import 'reader_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  List<HistoryEntry> _entries = [];
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
      final entries = await HistoryService.listHistory(username);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o histórico: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openEntry(HistoryEntry entry) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      // Precisamos buscar a lista de capítulos de novo para saber a posição
      // exata desse capítulo (e permitir "próximo capítulo" no leitor).
      final chapters = await MangaDexApi.chapters(entry.mangaId);
      final index = chapters.indexWhere((c) => c.id == entry.chapterId);
      if (!mounted) return;
      Navigator.of(context).pop();
      if (index == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esse capítulo não está mais disponível.')),
        );
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ReaderScreen(
          manga: Manga(id: entry.mangaId, title: entry.mangaTitle, coverUrl: entry.coverUrl),
          chapters: chapters,
          initialIndex: index,
          initialPage: entry.pageIndex,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir capítulo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
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
    if (_entries.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text('Você ainda não começou a ler nenhum mangá.'),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          leading: MangaCover(url: entry.coverUrl, width: 48, height: 68),
          title: Text(entry.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${entry.chapterLabel} • página ${entry.pageIndex + 1}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openEntry(entry),
        );
      },
    );
  }
}
