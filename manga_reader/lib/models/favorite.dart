class FavoriteEntry {
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final DateTime addedAt;

  const FavoriteEntry({
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    required this.addedAt,
  });

  factory FavoriteEntry.fromMap(Map<String, dynamic> map) => FavoriteEntry(
        mangaId: map['mangaId'] as String,
        mangaTitle: map['mangaTitle'] as String? ?? 'Sem título',
        coverUrl: map['coverUrl'] as String?,
        addedAt:
            DateTime.tryParse(map['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
