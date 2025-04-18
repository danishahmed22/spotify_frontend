import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistManager {
  static const _key = "local_playlists";

  static Future<Map<String, List<Map<String, dynamic>>>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)));
  }

  static Future<void> savePlaylists(Map<String, List<Map<String, dynamic>>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(data));
  }

  static Future<void> create(String name) async {
    final data = await loadPlaylists();
    if (!data.containsKey(name)) {
      data[name] = [];
      await savePlaylists(data);
    }
  }

  static Future<void> deletePlaylist(String name) async {
    final data = await loadPlaylists();
    data.remove(name);
    await savePlaylists(data);
  }

  static Future<void> addSong(String playlistName, Map<String, dynamic> song) async {
    final data = await loadPlaylists();
    final list = data[playlistName] ?? [];
    final exists = list.any((s) => s['id'] == song['id']);
    if (!exists) {
      list.add(song);
      data[playlistName] = list;
      await savePlaylists(data);
    }
  }

  static Future<void> removeSong(String playlistName, int songId) async {
    final data = await loadPlaylists();
    final list = data[playlistName] ?? [];
    list.removeWhere((s) => s['id'] == songId);
    data[playlistName] = list;
    await savePlaylists(data);
  }
}
