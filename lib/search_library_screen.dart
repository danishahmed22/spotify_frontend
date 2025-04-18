import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_manager.dart';

class SearchLibraryScreen extends StatefulWidget {
  const SearchLibraryScreen({super.key});
  @override
  State<SearchLibraryScreen> createState() => _SearchLibraryScreenState();
}

class _SearchLibraryScreenState extends State<SearchLibraryScreen> {
  List<dynamic> songs = [];
  List<String> categories = [];
  List<String> artists = [];
  List<String> albums = [];
  List<dynamic> uploads = [];

  String? filterQuery;
  String? selectedCategory;
  String? selectedArtist;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadAll() async {
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};

    // Categories
    final catRes = await http.get(Uri.parse("http://127.0.0.1:8000/songs/categories"), headers: headers);
    if (catRes.statusCode == 200) categories = List<String>.from(json.decode(catRes.body));

    // Artists
    final artRes = await http.get(Uri.parse("http://127.0.0.1:8000/user/artists"), headers: headers);
    if (artRes.statusCode == 200) artists = List<String>.from(json.decode(artRes.body));

    // Albums
    final albRes = await http.get(Uri.parse("http://127.0.0.1:8000/user/albums"), headers: headers);
    if (albRes.statusCode == 200) albums = List<String>.from(json.decode(albRes.body));

    // Uploads
    final upRes = await http.get(Uri.parse("http://127.0.0.1:8000/user/uploads"), headers: headers);
    if (upRes.statusCode == 200) uploads = json.decode(upRes.body);

    setState(() {});
  }

  Future<void> _searchSongs() async {
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};
    final queryParams = {
      if (filterQuery != null && filterQuery!.isNotEmpty) 'query': filterQuery!,
      if (selectedCategory != null) 'category': selectedCategory!,
    };
    final uri = Uri.http('127.0.0.1:8000', '/songs/search', queryParams);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      setState(() => songs = json.decode(res.body));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Widget songTile(Map<String, dynamic> song) {
    return ListTile(
      title: Text(song['title']),
      subtitle: Text(song['artist']),
      trailing: const Icon(Icons.play_arrow),
      onTap: () => AudioManager.play(context, song),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search & Library")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search
            TextField(
              decoration: const InputDecoration(
                labelText: "Search songs...",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                filterQuery = val;
                _searchSongs();
              },
            ),
            const SizedBox(height: 20),

            // 🧩 Category Filters
            Wrap(
              spacing: 8,
              children: categories.map((cat) => ChoiceChip(
                label: Text(cat),
                selected: selectedCategory == cat,
                onSelected: (selected) {
                  setState(() => selectedCategory = selected ? cat : null);
                  _searchSongs();
                },
              )).toList(),
            ),
            const SizedBox(height: 20),

            // 📋 Results
            if (songs.isNotEmpty) ...[
              const Text("Search Results", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...songs.map((s) => songTile(s as Map<String, dynamic>)),
            ],

            const Divider(height: 40),

            // 🎨 Artists
            if (artists.isNotEmpty) ...[
              const Text("Your Artists", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(spacing: 10, children: artists.map((a) => Chip(label: Text(a))).toList()),
              const SizedBox(height: 20),
            ],

            // 💿 Albums
            if (albums.isNotEmpty) ...[
              const Text("Your Albums", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(spacing: 10, children: albums.map((a) => Chip(label: Text(a))).toList()),
              const SizedBox(height: 20),
            ],

            // 📁 Uploaded Songs
            if (uploads.isNotEmpty) ...[
              const Text("Your Uploads", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...uploads.map((s) => songTile(s as Map<String, dynamic>)),
            ],
          ],
        ),
      ),
    );
  }
}
