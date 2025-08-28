import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFavKey = 'fav_ids';

// Global provider to manage the full set of favorite IDs
final favoritesProvider =
StateNotifierProvider<FavoritesController, Set<String>>((ref) {
  return FavoritesController();
});

// Efficient "is this book favorited?" provider
// Usage: ref.watch(isFavoriteProvider(bookId));
final isFavoriteProvider = Provider.family<bool, String>((ref, id) {
  final favs = ref.watch(favoritesProvider);
  return favs.contains(id);
});

class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController() : super(<String>{}) {
    _load();
  }

  // Load favorites from SharedPreferences
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kFavKey) ?? const <String>[];
    state = ids.toSet();
  }

  // Persist favorites to SharedPreferences (sorted for consistency)
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = state.toList()..sort();
    await prefs.setStringList(_kFavKey, sorted);
  }

  // Check if a book is in favorites
  bool isFav(String id) => state.contains(id);

  // Toggle favorite status
  Future<void> toggle(String id) async {
    final next = Set<String>.from(state);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = next;
    await _persist();
  }

  // Add book to favorites
  Future<void> add(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _persist();
  }

  // Remove book from favorites
  Future<void> remove(String id) async {
    if (!state.contains(id)) return;
    final next = Set<String>.from(state)..remove(id);
    state = next;
    await _persist();
  }

  // Clear all favorites
  Future<void> clear() async {
    state = <String>{};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kFavKey);
  }
}