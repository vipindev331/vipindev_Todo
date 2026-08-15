import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last few searched usernames on the device.
class RecentSearchesService {
  RecentSearchesService({this.maxEntries = 5});

  static const _storageKey = 'recent_searches';

  final int maxEntries;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? const <String>[];
  }

  /// Adds [username] to the front of the list, de-duplicated
  /// case-insensitively, and trims the list to [maxEntries].
  /// Returns the new list.
  Future<List<String>> add(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return load();

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? const <String>[];
    final updated = <String>[
      trimmed,
      ...current.where((e) => e.toLowerCase() != trimmed.toLowerCase()),
    ].take(maxEntries).toList();

    await prefs.setStringList(_storageKey, updated);
    return updated;
  }

  Future<List<String>> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    return const <String>[];
  }
}
