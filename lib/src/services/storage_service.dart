import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_result.dart';

/// Persists scan history and favorites across app restarts using SharedPreferences.
class StorageService {
  static const _historyKey = 'sqrs_history';
  static const _favoritesKey = 'sqrs_favorites';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── History ────────────────────────────────────────────────────────────────

  static Future<List<SmartScanResult>> loadHistory() async {
    await init();
    final raw = _prefs!.getStringList(_historyKey) ?? [];
    return raw
        .map((s) {
          try {
            return SmartScanResult.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SmartScanResult>()
        .toList();
  }

  static Future<void> saveHistory(List<SmartScanResult> items) async {
    await init();
    final encoded = items.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs!.setStringList(_historyKey, encoded);
  }

  static Future<void> clearHistory() async {
    await init();
    await _prefs!.remove(_historyKey);
  }

  // ── Favorites ──────────────────────────────────────────────────────────────

  static Future<Set<String>> loadFavorites() async {
    await init();
    return (_prefs!.getStringList(_favoritesKey) ?? []).toSet();
  }

  static Future<void> toggleFavorite(String rawValue) async {
    final favs = await loadFavorites();
    if (favs.contains(rawValue)) {
      favs.remove(rawValue);
    } else {
      favs.add(rawValue);
    }
    await _prefs!.setStringList(_favoritesKey, favs.toList());
  }

  static Future<bool> isFavorite(String rawValue) async {
    final favs = await loadFavorites();
    return favs.contains(rawValue);
  }
}
