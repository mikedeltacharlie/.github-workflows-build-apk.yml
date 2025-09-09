import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_locations';
  
  static Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson.toSet();
  }
  
  static Future<void> toggleFavorite(String locationId) async {
    final favorites = await getFavoriteIds();
    final prefs = await SharedPreferences.getInstance();
    
    if (favorites.contains(locationId)) {
      favorites.remove(locationId);
    } else {
      favorites.add(locationId);
    }
    
    await prefs.setStringList(_favoritesKey, favorites.toList());
  }
  
  static Future<bool> isFavorite(String locationId) async {
    final favorites = await getFavoriteIds();
    return favorites.contains(locationId);
  }
  
  static Future<void> removeFromFavorites(String locationId) async {
    final favorites = await getFavoriteIds();
    if (favorites.contains(locationId)) {
      favorites.remove(locationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, favorites.toList());
    }
  }
  
  static Future<void> addToFavorites(String locationId) async {
    final favorites = await getFavoriteIds();
    if (!favorites.contains(locationId)) {
      favorites.add(locationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, favorites.toList());
    }
  }
}