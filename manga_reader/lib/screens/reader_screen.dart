import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../models/manga.dart';
import '../services/download_service.dart';
import '../services/history_service.dart';
import '../services/mangadex_api.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ReaderScreen extends StatefulWidget {
  final Manga manga;
  final List<Chapter> chapters;
  final int initialIndex;
  final int initialPage;

  const ReaderScreen({
    super.key,
    required this.manga,
    required this.chapters,
    required this.initialIndex,
    this.initialPage = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int _chapterIndex;
  final _pageController = PageController();

  List<String> _pages = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;
  int _currentPage = 0;

  bool _downloading = false;
  int _downloadCurrent = 0;
  int _downloadTotal = 0;

  Chapter get _chapter => widget.chapters[_chapterIndex];
  bool get _hasNextChapter => _chapterIndex < widget.chapters.length - 1;

  @override
  void initState() {
    super.initState();
    _chapterIndex = widget.initialIndex;
    _loadChapter(startPage: widget.initialPage);
  }

  Future<void> _loadChapter({int startPage = 0}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    Future<void> finish(List<String> pages, bool offline) async {
      if (!mounted) return;
      final safePage = pages.isEmpty ? 0 : startPage.clamp(0, pages.length - 1);
      setState(() {
        _pages = pages;
        _offline = offline;
        _loading = false;
        _currentPage = safePage;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pages.isNotEmpty && _pageController.hasClients) {
          _pageController.jumpToPage(safePage);
        }
      });
      _saveProgress();
    }

    final local = await DownloadService.getLocalPages(widget.manga.title, _chapter.label);
    if (local != null) {
      await finish(local.map((f) => f.path).toList(), true);
      return;
    }

    try {
      final urls = await MangaDexApi.pageUrls(_chapter.id);
      await finish(urls, false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar páginas: $e';
        _loading = false;
      });
    }
  }

  void _saveProgress() {
    final username = context.read<AppState>().username;
    if (username == null) return;
    HistoryService.updateProgress(
      username: username,
      mangaId: widget.manga.id,
      mangaTitle: widget.manga.title,
      coverUrl: widget.manga.coverUrl,
      chapterId: _chapter.id,
      chapterLabel: _chapter.label,
      pageIndex: _currentPage,
    );
    // Erros aqui são silenciosos de propósito: não vale a pena interromper
    // a leitura só porque o histórico não pôde ser salvo no momento.
  }

  Future<void> _download() async {
    if (_offline || _pages.isEmpty || _downloading) return;
    setState(() {
      _downloading = true;
      _downloadCurrent = 0;
      _downloadTotal = _pages.length;
    });
    try {
      await DownloadService.downloadChapter(
        mangaTitle: widget.manga.title,
        chapterLabel: _chapter.label,
        pageUrls: _pages,
        onProgress: (c, t) {
          if (!mounted) return;
          setState(() {
            _downloadCurrent = c;
            _downloadTotal = t;
          });
        },
      );
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capítulo baixado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao baixar: $e')),
      );
    }
  }

  void _goToNextChapter() {
    if (!_hasNextChapter) return;
    setState(() => _chapterIndex++);
    _loadChapter(startPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _pages.isNotEmpty && _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.readerBg,
      appBar: AppBar(
        backgroundColor: AppColors.readerBg,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chapter.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_pages.isNotEmpty)
              Text(
                '${_currentPage + 1} / ${_pages.length}${_offline ? '  •  offline' : ''}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (!_offline)
            IconButton(
              onPressed: _downloading ? null : _download,
              icon: const Icon(Icons.download_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            if (_pages.isNotEmpty) _buildControls(isLastPage),
            if (_downloading) _buildDownloadBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));
    }
    if (_pages.isEmpty) {
      return const Center(child: Text('Nenhuma página encontrada', style: TextStyle(color: Colors.white)));
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        _saveProgress();
      },
      itemBuilder: (context, index) {
        final source = _pages[index];
        return InteractiveViewer(
          maxScale: 4,
          child: _offline
              ? Image.file(File(source), fit: BoxFit.contain)
              : CachedNetworkImage(
                  imageUrl: source,
                  fit: BoxFit.contain,
                  progressIndicatorBuilder: (context, url, progress) => Center(
                    child: CircularProgressIndicator(value: progress.progress, color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildControls(bool isLastPage) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _currentPage > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.ease,
                    )
                : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 14),
            label: const Text('Anterior'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
            ),
          ),
          if (isLastPage && _hasNextChapter)
            ElevatedButton.icon(
              onPressed: _goToNextChapter,
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('Próximo capítulo'),
            )
          else
            ElevatedButton.icon(
              onPressed: !isLastPage
                  ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.ease,
                      )
                  : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('Próxima'),
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadBar() {
    return Container(
      width: double.infinity,
      color: Colors.white10,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Baixando $_downloadCurrent/$_downloadTotal...',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
