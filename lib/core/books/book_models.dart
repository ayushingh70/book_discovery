class Book {
  // Details
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnail;
  final List<String> categories;
  final String? publishedDate;
  final double? price;
  final String? currencyCode;

  // Extra metadata
  final String? language;
  final int? pageCount;
  final String? publisher;
  final String? maturityRating;

  // Links
  final String? infoLink;
  final String? previewLink;

  // Ratings
  final double? averageRating;
  final int? ratingsCount;

  // ISBNs
  final String? isbn10;
  final String? isbn13;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnail,
    required this.categories,
    required this.publishedDate,
    this.price,
    this.currencyCode,
    this.language,
    this.pageCount,
    this.publisher,
    this.maturityRating,
    this.infoLink,
    this.previewLink,
    this.averageRating,
    this.ratingsCount,
    this.isbn10,
    this.isbn13,
  });

  factory Book.fromVolume(Map<String, dynamic> json) {
    final info = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    final sale = json['saleInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;

    // thumbnail
    String? thumb;
    if (imageLinks != null) {
      thumb = imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'];
      if (thumb is String && thumb.startsWith('http:')) {
        thumb = thumb.replaceFirst('http:', 'https:');
      }
    }

    // sale info (retail or list)
    final priceInfo =
    (sale['listPrice'] ?? sale['retailPrice']) as Map<String, dynamic>?;

    // ISBNs
    String? isbn10;
    String? isbn13;
    final ids = info['industryIdentifiers'];
    if (ids is List) {
      for (final x in ids) {
        if (x is Map) {
          final type = (x['type'] ?? '').toString();
          final val = (x['identifier'] ?? '').toString();
          if (type == 'ISBN_13') isbn13 = val;
          if (type == 'ISBN_10') isbn10 = val;
        }
      }
    }

    return Book(
      id: json['id']?.toString() ?? '',
      title: (info['title'] ?? 'Untitled').toString(),
      authors: (info['authors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      description: info['description']?.toString(),
      thumbnail: thumb,
      categories: (info['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      publishedDate: info['publishedDate']?.toString(),

      price: priceInfo != null ? (priceInfo['amount'] as num?)?.toDouble() : null,
      currencyCode: priceInfo != null ? priceInfo['currencyCode']?.toString() : null,

      language: info['language']?.toString(),
      pageCount: (info['pageCount'] as num?)?.toInt(),
      publisher: info['publisher']?.toString(),
      maturityRating: info['maturityRating']?.toString(),

      infoLink: info['infoLink']?.toString(),
      previewLink: info['previewLink']?.toString(),
      averageRating: (info['averageRating'] is num) ? (info['averageRating'] as num).toDouble() : null,
      ratingsCount: (info['ratingsCount'] is num) ? (info['ratingsCount'] as num).toInt() : null,

      isbn10: isbn10,
      isbn13: isbn13,
    );
  }

  int? get publishedYear {
    if (publishedDate == null) return null;
    final m = RegExp(r'^\d{4}').firstMatch(publishedDate!);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  // Human readable language (fallbacks to code)
  String get languageNice {
    final code = (language ?? '').toLowerCase();
    const m = {
      'en': 'English',
      'hi': 'Hindi',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ru': 'Russian',
      'zh': 'Chinese',
      'ja': 'Japanese',
      'pt': 'Portuguese',
      'bn': 'Bengali',
    };
    return m[code] ?? (code.isEmpty ? 'N/A' : code);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authors': authors,
    'description': description,
    'thumbnail': thumbnail,
    'categories': categories,
    'publishedDate': publishedDate,
    'price': price,
    'currencyCode': currencyCode,
    'language': language,
    'pageCount': pageCount,
    'publisher': publisher,
    'maturityRating': maturityRating,
    'infoLink': infoLink,
    'previewLink': previewLink,
    'averageRating': averageRating,
    'ratingsCount': ratingsCount,
    'isbn10': isbn10,
    'isbn13': isbn13,
  };

  factory Book.fromJson(Map<String, dynamic> j) => Book(
    id: j['id'],
    title: j['title'],
    authors: (j['authors'] as List).cast<String>(),
    description: j['description'],
    thumbnail: j['thumbnail'],
    categories: (j['categories'] as List).cast<String>(),
    publishedDate: j['publishedDate'],
    price: (j['price'] as num?)?.toDouble(),
    currencyCode: j['currencyCode'],
    language: j['language'],
    pageCount: j['pageCount'],
    publisher: j['publisher'],
    maturityRating: j['maturityRating'],
    infoLink: j['infoLink'],
    previewLink: j['previewLink'],
    averageRating: (j['averageRating'] as num?)?.toDouble(),
    ratingsCount: (j['ratingsCount'] as num?)?.toInt(),
    isbn10: j['isbn10'],
    isbn13: j['isbn13'],
  );
}