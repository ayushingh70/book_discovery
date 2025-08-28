import 'package:dio/dio.dart';
import 'book_models.dart';

class BooksApi {
  final Dio _dio;
  final String? apiKey;
  final bool debugLog;

  // This is the base URL for the Google Books API
  static const _base = 'https://www.googleapis.com/books/v1';

  BooksApi({
    Dio? dio,
    this.apiKey,
    this.debugLog = false,
  }) : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: _base,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  // --- SEARCH ---
  Future<List<Book>> search(
      String query, {
        int startIndex = 0, // For pagination (multiples of maxResults)
        int maxResults = 20, // 1..40 (Google caps at 40)
        String? subject, // Adds `subject:xxx` to the query for category/genre
        bool orderByNewest = false,
        String? orderBy, // 'relevance' | 'newest'
        String? printType, // "all" (default), "books", "magazines"
        String? langRestrict, // e.g. "en"
        bool? onlyFree,
        bool? onlyPaid,
        double? priceMin, // client-side filter; only works if price exists.
        double? priceMax, // client-side filter; only works if price exists.
      }) async {
    final q = _composeQuery(query, subject: subject);
    final sanitizedMax = maxResults.clamp(1, 40);

    // --- primary request (lite projection for performance) ---
    final baseParams = <String, dynamic>{
      'q': q,
      'startIndex': startIndex,
      'maxResults': sanitizedMax,
      'projection': 'lite',
      if (apiKey != null) 'key': apiKey,
    };

    _applyOrderLangAndFilter(
      params: baseParams,
      orderBy: orderBy ?? (orderByNewest ? 'newest' : null),
      printType: printType,
      langRestrict: langRestrict,
      onlyFree: onlyFree,
      onlyPaid: onlyPaid,
    );

    var books = await _getBooks('/volumes', baseParams);

    // --- fallbacks if empty ---
    if (books.isEmpty && query.trim().isNotEmpty) {
      if (debugLog) {
        // ignore: avoid_print
        print('[BooksApi] Empty result for "$query" — trying fallbacks…');
      }

      // intitle: query
      final p1 = Map<String, dynamic>.from(baseParams)
        ..['q'] = 'intitle:${query.trim()}';
      books = await _getBooks('/volumes', p1);

      // quoted full phrase (helps multi-word searches)
      if (books.isEmpty && query.trim().contains(' ')) {
        final p2 = Map<String, dynamic>.from(baseParams)
          ..['q'] = '"${query.trim()}"';
        books = await _getBooks('/volumes', p2);
      }

      // full projection (in case lite misses items for odd queries)
      if (books.isEmpty) {
        final p3 = Map<String, dynamic>.from(baseParams)
          ..remove('projection')
          ..['projection'] = 'full';
        books = await _getBooks('/volumes', p3);
      }
    }

    // Optional client-side price filter
    if (priceMin != null || priceMax != null) {
      books = books.where((b) {
        final p = b.price;
        if (p == null) return false;
        if (priceMin != null && p < priceMin) return false;
        if (priceMax != null && p > priceMax) return false;
        return true;
      }).toList();
    }

    if (debugLog) {
      // ignore: avoid_print
      print('[BooksApi] search("$query") -> ${books.length}');
    }
    return books;
  }

  // --- SINGLE VOLUME ---
  Future<Book> volume(String id) async {
    try {
      final res = await _dio.get(
        '/volumes/$id',
        queryParameters: {if (apiKey != null) 'key': apiKey},
      );
      return Book.fromVolume(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (debugLog) {
        // ignore: avoid_print
        print('[BooksApi] volume("$id") error: ${e.message}');
      }
      rethrow;
    }
  }

  // --- MORE BY AUTHOR ----
  Future<List<Book>> byAuthor(String author, {int maxResults = 10}) async {
    final params = {
      'q': 'inauthor:"$author"',
      'maxResults': maxResults.clamp(1, 40),
      'orderBy': 'relevance',
      'projection': 'lite',
      if (apiKey != null) 'key': apiKey,
    };
    return _getBooks('/volumes', params);
  }

  // --- Helpers ---

  Future<List<Book>> _getBooks(
      String path, Map<String, dynamic> queryParameters) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      final items = (res.data['items'] as List?) ?? const [];
      return items
          .map((e) => Book.fromVolume(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (debugLog) {
        // ignore: avoid_print
        print('[BooksApi] GET $path error: ${e.message} | ${e.response?.data}');
      }
      return const [];
    } catch (e) {
      if (debugLog) {
        // ignore: avoid_print
        print('[BooksApi] GET $path unknown error: $e');
      }
      return const [];
    }
  }

  void _applyOrderLangAndFilter({
    required Map<String, dynamic> params,
    String? orderBy,
    String? printType,
    String? langRestrict,
    bool? onlyFree,
    bool? onlyPaid,
  }) {
    if (orderBy != null && orderBy.isNotEmpty) params['orderBy'] = orderBy;
    if (printType != null && printType.isNotEmpty) {
      params['printType'] = printType;
    }
    if (langRestrict != null && langRestrict.isNotEmpty) {
      params['langRestrict'] = langRestrict;
    }

    // Free/Paid filter — if both are true, treat as "any"
    if (onlyFree == true && onlyPaid != true) {
      params['filter'] = 'free-ebooks';
    } else if (onlyPaid == true && onlyFree != true) {
      params['filter'] = 'paid-ebooks';
    }
  }

  String _composeQuery(String raw, {String? subject}) {
    final parts = <String>[];
    final q = raw.trim();
    if (q.isNotEmpty) parts.add(q);
    if (subject != null && subject.trim().isNotEmpty) {
      parts.add('subject:${subject.trim()}');
    }
    return parts.join(' ');
  }
}