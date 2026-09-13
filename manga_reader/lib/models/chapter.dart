class Chapter {
  final String id;
  final String? volume;
  final String? number;
  final String? title;

  const Chapter({
    required this.id,
    this.volume,
    this.number,
    this.title,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final attributes = (json['attributes'] as Map<String, dynamic>?) ?? {};
    return Chapter(
      id: json['id'] as String,
      volume: attributes['volume'] as String?,
      number: attributes['chapter'] as String?,
      title: attributes['title'] as String?,
    );
  }

  /// Texto amigável exibido na lista, ex: "Vol. 2 Cap. 15 - O início"
  String get label {
    final vol = volume != null ? 'Vol. $volume ' : '';
    final chap = number != null ? 'Cap. $number' : 'Cap. ?';
    final t = (title != null && title!.isNotEmpty) ? ' - $title' : '';
    return '$vol$chap$t';
  }

  /// Usado apenas para ordenação numérica da lista de capítulos.
  double get sortValue => double.tryParse(number ?? '') ?? -1;
}
