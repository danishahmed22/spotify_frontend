import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:music/playlist_manager.dart';

class SelectSongForPlaylistScreen extends StatefulWidget {
  final String playlistName;
  const SelectSongForPlaylistScreen({super.key, required this.playlistName});

  @override
  State<SelectSongForPlaylistScreen> createState() => _SelectSongForPlaylistScreenState();
}

class _SelectSongForPlaylistScreenState extends State<SelectSongForPlaylistScreen> {
  List<dynamic> songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final res = await http.get(Uri.parse("http://127.0.0.1:8000/songs/search"));
    if (res.statusCode == 200) {
      songs = json.decode(res.body);
      setState(() {});
    }
  }

  Future<void> _addToPlaylist(Map<String, dynamic> song) async {
    await PlaylistManager.addSong(widget.playlistName, song);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to ${widget.playlistName}")));
    Navigator.popUntil(context, (route) => route.isFirst); // ✅ Return to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add to ${widget.playlistName}")),
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: songs.length,
        itemBuilder: (_, i) {
          final song = songs[i];
          return ListTile(
            title: Text(song['title']),
            subtitle: Text(song['artist']),
            trailing: const Icon(Icons.add),
            onTap: () => _addToPlaylist(song),
          );
        },
      ),
    );
  }
}
