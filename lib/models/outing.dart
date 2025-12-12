class Outing {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String url;
  final String source;
  final List<String> categories; // ex: ['electro', 'expo']
  final String? imageUrl; // image de l'événement si disponible
  final String? description; // description courte

  Outing({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.url,
    required this.source,
    required this.categories,
    this.imageUrl,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'url': url,
      'source': source,
      'categories': categories,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  factory Outing.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final d = map['date'];
    if (d is String) {
      try {
        parsedDate = DateTime.parse(d);
      } catch (e) {
        parsedDate = DateTime.now();
      }
    } else if (d is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(d);
    } else {
      parsedDate = DateTime.now();
    }

    return Outing(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: parsedDate,
      location: map['location'] ?? '',
      url: map['url'] ?? '',
      source: map['source'] ?? '',
      categories: (map['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
    );
  }
}
