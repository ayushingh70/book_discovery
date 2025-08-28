import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'books_api.dart';
import 'book_models.dart';
import '../analytics/analytics_store.dart';
import 'search_history_store.dart';

// DI providers
final booksApiProvider = Provider<BooksApi>(
      (ref) => BooksApi(apiKey: "AIzaSyCDkoXT-KQ3daB4Sr433-KZrw8xl4wgVqI"), // TODO Replace with your API key
);

final historyStoreProvider =
Provider<SearchHistoryStore>((ref) => SearchHistoryStore());

final analyticsStoreProvider = Provider<AnalyticsStore>((ref) {
  final store = AnalyticsStore();
  store.load(); // lazy-load persisted analytics
  return store;
});

final booksRepoProvider = Provider<BooksRepository>((ref) => BooksRepository(
  api: ref.read(booksApiProvider),
  analytics: ref.read(analyticsStoreProvider),
  history: ref.read(historyStoreProvider),
));

// --- Filter model ---
class SearchFilter {
  // Adds `subject:xyz` to the API query
  final String? subject;

  // Any of these categories must intersect with the book’s categories (client-side)
  final List<String> categories;

  // Order in API: 'relevance' | 'newest'
  final String? orderBy;

  // Google Books API filter flags.
  final bool onlyFree;
  final bool onlyPaid;

  // API pass-through (and/or client-side)
  final String? printType; // 'all' | 'books' | 'magazines'
  final String? langRestrict; // e.g. 'en'

  // If you pass priceMin/Max, only books with non-null price are considered.
  final double? priceMin;
  final double? priceMax;

  // Year range (inclusive). If provided, book.publishedYear must be within.
  final int? yearFrom;
  final int? yearTo;

  // Optional: require a specific currency (e.g. "USD", "INR").
  final String? currencyCode;

  const SearchFilter({
    this.subject,
    this.categories = const [],
    this.orderBy,
    this.onlyFree = false,
    this.onlyPaid = false,
    this.printType,
    this.langRestrict,
    this.priceMin,
    this.priceMax,
    this.yearFrom,
    this.yearTo,
    this.currencyCode,
  });

  bool get isEmpty =>
      (subject == null || subject!.isEmpty) &&
          categories.isEmpty &&
          orderBy == null &&
          !onlyFree &&
          !onlyPaid &&
          (printType == null || printType!.isEmpty) &&
          (langRestrict == null || langRestrict!.isEmpty) &&
          priceMin == null &&
          priceMax == null &&
          yearFrom == null &&
          yearTo == null &&
          currencyCode == null;
}

// --- Repository ---
class BooksRepository {
  final BooksApi api;
  final AnalyticsStore analytics;
  final SearchHistoryStore history;

  BooksRepository({
    required this.api,
    required this.analytics,
    required this.history,
  });

  // Discovery feed used when the search box is empty.
  // Uses a rotating set of very broad queries to guarantee results.
  final List<String> _discoverySeeds = const [
    'the',
    'a',
    'novel',
    'guide',
    'learn',
    'history',
    'science',
    'art',
    'programming',
  ];

  Future<List<Book>> discoveryFeed({int maxResults = 30}) async {
    final seed = _discoverySeeds[Random().nextInt(_discoverySeeds.length)];
    // Prefer relevance, books only, lite payload
    final results = await api.search(
      seed,
      maxResults: maxResults,
      orderBy: 'relevance',
      printType: 'books',
    );
    await analytics.addResults(results);
    return results;
  }

  // Basic search. Persists history + analytics.
  Future<List<Book>> search(
      String query, {
        int startIndex = 0,
        int maxResults = 20,
      }) async {
    try {
      var results = await api.search(
        query,
        startIndex: startIndex,
        maxResults: maxResults,
        orderBy: 'relevance',
        printType: 'books',
      );

      // Fallback: if nothing, try intitle: query (helps for very generic inputs)
      if (results.isEmpty && query.trim().isNotEmpty) {
        results = await api.search(
          'intitle:${query.trim()}',
          startIndex: 0,
          maxResults: maxResults,
          orderBy: 'relevance',
          printType: 'books',
        );
      }

      // Side effects
      await history.add(query);
      await analytics.addResults(results);
      // ignore: avoid_print
      print('[BooksRepository] search("$query") -> ${results.length}');

      return results;
    } catch (e) {
      // ignore: avoid_print
      print('[BooksRepository] search("$query") error: $e');
      return [];
    }
  }

  // Search with server-side knobs + client-side filtering.
  Future<List<Book>> searchWithFilter(
      String query, {
        SearchFilter filter = const SearchFilter(),
        int startIndex = 0,
        int maxResults = 30,
      }) async {
    // First: hit API with what it supports directly.
    final resultsFromApi = await api.search(
      query,
      startIndex: startIndex,
      maxResults: maxResults,
      subject: filter.subject,
      orderBy: filter.orderBy,
      onlyFree: filter.onlyFree,
      onlyPaid: filter.onlyPaid,
      printType: filter.printType,
      langRestrict: filter.langRestrict,
      priceMin: filter.priceMin,
      priceMax: filter.priceMax,
    );

    // Persist side-effects (use the API subset here)
    await history.add(query);

    // If no client-side conditions, record & return
    if (filter.categories.isEmpty &&
        filter.currencyCode == null &&
        filter.yearFrom == null &&
        filter.yearTo == null) {
      await analytics.addResults(resultsFromApi);
      return resultsFromApi;
    }

    // Client-side filters
    final catsLower =
    filter.categories.map((e) => e.toLowerCase().trim()).toList();

    bool pass(Book b) {
      // Categories intersection
      if (catsLower.isNotEmpty) {
        final bCats = b.categories.map((e) => e.toLowerCase());
        final intersects = bCats.any(catsLower.contains);
        if (!intersects) return false;
      }

      // Currency
      if (filter.currencyCode != null &&
          (b.currencyCode ?? '').toUpperCase() !=
              filter.currencyCode!.toUpperCase()) {
        return false;
      }

      // Year range
      final y = b.publishedYear;
      if (filter.yearFrom != null && (y == null || y < filter.yearFrom!)) {
        return false;
      }
      if (filter.yearTo != null && (y == null || y > filter.yearTo!)) {
        return false;
      }

      return true;
    }

    final filtered = resultsFromApi.where(pass).toList();
    await analytics.addResults(filtered);
    return filtered;
  }

  Future<Book> volume(String id) => api.volume(id);
  Future<List<Book>> moreByAuthor(String author) => api.byAuthor(author);

  // --- History helpers ---
  Future<List<String>> loadHistory() => history.load();
  Future<void> clearHistory() => history.clear();
  Future<void> removeHistoryItem(String query) => history.remove(query);

  // Latest N entries, most-recent-first (handy for UI suggestions).
  Future<List<String>> latestHistory({int limit = 5}) async {
    final all = await history.load();
    return all.take(limit).toList();
  }
}