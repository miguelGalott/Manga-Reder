class HistoryEntry {
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final String chapterId;
  final String chapterLabel;
  final int pageIndex;
  final DateTime updatedAt;

  const HistoryEntry({
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    required this.chapterId,
    required this.chapterLabel,
    required this.pageIndex,
    required this.updatedAt,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        mangaId: map['mangaId'] as String,
        mangaTitle: map['mangaTitle'] as String? ?? 'Sem título',
        coverUrl: map['coverUrl'] as String?,
        chapterId: map['chapterId'] as String,
        chapterLabel: map['chapterLabel'] as String? ?? '',
        pageIndex: (map['pageIndex'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
