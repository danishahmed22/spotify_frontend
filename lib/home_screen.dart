import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:music/playlist_detail_screen.dart';
import 'package:music/playlist_manager.dart';
import 'package:music/profile_screen.dart';
import 'package:music/search_library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'audio_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> songs = [];
  Map<String, List<Map<String, dynamic>>> localPlaylists = {};
  String? userName;
  String? avatar;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadHomeData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'User';
    });
  }

  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    userName = prefs.getString('name') ?? "User";

    final headers = {'Authorization': 'Bearer $token'};

    // Profile
    final profileRes = await http.get(Uri.parse("http://localhost:8000/profile"), headers: headers);
    if (profileRes.statusCode == 200) {
      final data = json.decode(profileRes.body);
      setState(() {
        userName = data['name'] ?? data['email'];
        avatar = data['avatar'];
      });
    }

    // Songs
    final songRes = await http.get(Uri.parse("http://localhost:8000/songs/search"), headers: headers);
    if (songRes.statusCode == 200) {
      setState(() => songs = json.decode(songRes.body));
    }

    // Load Local Playlists
    localPlaylists = await PlaylistManager.loadPlaylists();

    setState(() {});
  }

  Future<void> _showCreatePlaylistDialog() async {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Create Playlist"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Playlist Name"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                await PlaylistManager.create(name);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Playlist created")));
                _loadHomeData();
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSearchScreen() {
    // Navigate to search screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchLibraryScreen()),
    );
  }

  Widget songCard(Map<String, dynamic> song) {
    return GestureDetector(
      onTap: () => AudioManager.play(context, song),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.music_note),
            const SizedBox(width: 10),
            Expanded(child: Text(song['title'], style: const TextStyle(fontSize: 16))),
            Text(song['artist'] ?? '', style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget playlistCard(String name, List<Map<String, dynamic>> songs) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistName: name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade700,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget viewMoreButton() {
    return GestureDetector(
      onTap: _navigateToSearchScreen,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade500,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "View More",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )
            ),
            SizedBox(width: 5),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = avatar != null
        ? "http://localhost:8000/static/avatars/$avatar"
        : null;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePlaylistDialog,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Hi, $userName 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (avatarUrl != null)
                      CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                  ],
                ),
                const Text("Trending Songs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                // Display only first 8 songs
                ...songs.take(8).map((s) => songCard(s as Map<String, dynamic>)),
                // Add "View More" button if there are more than 8 songs
                if (songs.length > 8) viewMoreButton(),

                const SizedBox(height: 30),
                const Text("Your Playlists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (localPlaylists.isEmpty)
                  const Text("No playlists yet. Create one!"),
                ...localPlaylists.entries.map((e) => playlistCard(e.key, e.value)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}