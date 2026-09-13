class Manga {
  final String id;
  final String title;
  final String? status;
  final String? coverUrl;

  const Manga({
    required this.id,
    required this.title,
    this.status,
    this.coverUrl,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final attributes = (json['attributes'] as Map<String, dynamic>?) ?? {};
    final titleMap = (attributes['title'] as Map<String, dynamic>?) ?? {};

    String title;
    if (titleMap['pt-br'] != null) {
      title = titleMap['pt-br'] as String;
    } else if (titleMap['en'] != null) {
      title = titleMap['en'] as String;
    } else if (titleMap.isNotEmpty) {
      title = titleMap.values.first.toString();
    } else {
      title = 'Sem título';
    }

    String? coverUrl;
    final relationships = (json['relationships'] as List<dynamic>?) ?? [];
    for (final rel in relationships) {
      if (rel is Map<String, dynamic> && rel['type'] == 'cover_art') {
        final relAttrs = rel['attributes'] as Map<String, dynamic>?;
        final fileName = relAttrs?['fileName'] as String?;
        if (fileName != null) {
          coverUrl =
              'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg';
        }
        break;
      }
    }

    return Manga(
      id: id,
      title: title,
      status: attributes['status'] as String?,
      coverUrl: coverUrl,
    );
  }
}
