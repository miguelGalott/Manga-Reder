class CommentEntry {
  final String username;
  final String mangaId;
  final String text;
  final int rating;
  final DateTime createdAt;

  const CommentEntry({
    required this.username,
    required this.mangaId,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  factory CommentEntry.fromMap(Map<String, dynamic> map) => CommentEntry(
        username: map['username'] as String? ?? 'anônimo',
        mangaId: map['mangaId'] as String,
        text: map['text'] as String? ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
