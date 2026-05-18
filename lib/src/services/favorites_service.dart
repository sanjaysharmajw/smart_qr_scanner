import 'storage_service.dart';

/// Manages a persisted set of favorited scan raw-values.
class FavoritesService {
  FavoritesService._();

  static Future<bool> isFavorite(String rawValue) =>
      StorageService.isFavorite(rawValue);

  static Future<void> toggle(String rawValue) =>
      StorageService.toggleFavorite(rawValue);

  static Future<Set<String>> loadAll() => StorageService.loadFavorites();
}
