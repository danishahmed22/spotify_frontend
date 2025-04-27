import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_manager.dart';

class SearchLibraryScreen extends StatefulWidget {
  final String? initialCategory;
  const SearchLibraryScreen({super.key, this.initialCategory});

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _loadAll().then((_) {
      _searchSongs();
      setState(() => isLoading = false);
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadAll() async {
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};

    // Load categories if not viewing a specific category
    if (widget.initialCategory == null) {
      final catRes = await http.get(
        Uri.parse("http://127.0.0.1:8000/songs/categories"),
        headers: headers,
      );
      if (catRes.statusCode == 200) {
        categories = List<String>.from(json.decode(catRes.body));
      }
    }

    // Load artists
    final artRes = await http.get(
      Uri.parse("http://127.0.0.1:8000/user/artists"),
      headers: headers,
    );
    if (artRes.statusCode == 200) {
      artists = List<String>.from(json.decode(artRes.body));
    }

    // Load albums
    final albRes = await http.get(
      Uri.parse("http://127.0.0.1:8000/user/albums"),
      headers: headers,
    );
    if (albRes.statusCode == 200) {
      albums = List<String>.from(json.decode(albRes.body));
    }

    // Load uploads
    final upRes = await http.get(
      Uri.parse("http://127.0.0.1:8000/user/uploads"),
      headers: headers,
    );
    if (upRes.statusCode == 200) {
      uploads = json.decode(upRes.body);
    }

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

  Widget _buildSongTile(Map<String, dynamic> song) {
    return ListTile(
      leading: const Icon(Icons.music_note, color: Colors.deepPurple),
      title: Text(
        song['title'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        song['artist'] ?? 'Unknown Artist',
        style: TextStyle(color: Colors.grey.shade400),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.deepPurple),
        onPressed: () => AudioManager.play(context, song),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) => ChoiceChip(
        label: Text(cat),
        selected: selectedCategory == cat,
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        labelStyle: TextStyle(
          color: selectedCategory == cat
              ? Colors.deepPurple
              : Colors.white,
        ),
        onSelected: (selected) {
          setState(() => selectedCategory = selected ? cat : null);
          _searchSongs();
        },
      )).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildArtistChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: artists.map((artist) => Chip(
        label: Text(artist),
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white),
      )).toList(),
    );
  }

  Widget _buildAlbumChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: albums.map((album) => Chip(
        label: Text(album),
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.initialCategory != null
              ? "${widget.initialCategory} Songs"
              : "Browse Music",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field (only when not viewing specific category)
            if (widget.initialCategory == null) ...[
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  hintText: "Search songs...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  filterQuery = val;
                  _searchSongs();
                },
              ),
              const SizedBox(height: 16),
            ],

            // Category filters (only when not viewing specific category)
            if (widget.initialCategory == null && categories.isNotEmpty) ...[
              _buildSectionTitle("Categories"),
              _buildCategoryChips(),
            ],

            // Search results or category songs
            if (songs.isNotEmpty) ...[
              _buildSectionTitle(
                widget.initialCategory != null
                    ? "All ${widget.initialCategory} Songs"
                    : "Results",
              ),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: songs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _buildSongTile(
                  songs[index] as Map<String, dynamic>,
                ),
              ),
            ],

            // User's artists
            if (artists.isNotEmpty && widget.initialCategory == null) ...[
              _buildSectionTitle("Your Artists"),
              _buildArtistChips(),
            ],

            // User's albums
            if (albums.isNotEmpty && widget.initialCategory == null) ...[
              _buildSectionTitle("Your Albums"),
              _buildAlbumChips(),
            ],

            // User's uploads
            if (uploads.isNotEmpty && widget.initialCategory == null) ...[
              _buildSectionTitle("Your Uploads"),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: uploads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _buildSongTile(
                  uploads[index] as Map<String, dynamic>,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}