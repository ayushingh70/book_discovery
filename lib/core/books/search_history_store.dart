import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStore {
  static const _key = 'search_history_v1';
  static const _max = 30;

  // Load all, most-recent first.
  Future<List<String>> load() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? const <String>[];
    return List<String>.from(list);
  }

  // Add query to the top (dedupe). Returns updated list.
  Future<List<String>> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();

    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? <String>[];

    // de-dupe then insert at front
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);

    // cap length
    if (list.length > _max) list.removeRange(_max, list.length);

    await sp.setStringList(_key, list);
    return list;
  }

  // Remove one query (case-insensitive). Returns updated list.
  Future<List<String>> remove(String query) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? <String>[];

    list.removeWhere((e) => e.toLowerCase() == query.trim().toLowerCase());

    await sp.setStringList(_key, list);
    return list;
  }

  // Clear all history.
  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }

  // Convenience: latest N entries (most recent first).
  Future<List<String>> latest(int limit) async {
    final all = await load();
    return all.take(limit).toList();
  }
}