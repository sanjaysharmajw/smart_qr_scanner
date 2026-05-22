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

  // Serialises concurrent toggleFavorite calls so rapid taps don't cause
  // a read-modify-write race where one update overwrites another.
  static Future<void>? _pendingToggle;

  static Future<Set<String>> loadFavorites() async {
    await init();
    return (_prefs!.getStringList(_favoritesKey) ?? []).toSet();
  }

  static Future<void> toggleFavorite(String rawValue) async {
    // Chain onto any in-flight toggle so each call sees the previous write.
    final previous = _pendingToggle ?? Future.value();
    _pendingToggle = previous.then((_) async {
      await init();
      final favs = (_prefs!.getStringList(_favoritesKey) ?? []).toSet();
      if (favs.contains(rawValue)) {
        favs.remove(rawValue);
      } else {
        favs.add(rawValue);
      }
      await _prefs!.setStringList(_favoritesKey, favs.toList());
    });
    await _pendingToggle;
  }

  static Future<bool> isFavorite(String rawValue) async {
    final favs = await loadFavorites();
    return favs.contains(rawValue);
  }
}
