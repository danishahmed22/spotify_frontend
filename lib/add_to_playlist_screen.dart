import 'package:flutter/material.dart';
import 'package:music/playlist_manager.dart';

class AddToPlaylistScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  const AddToPlaylistScreen({super.key, required this.song});

  @override
  State<AddToPlaylistScreen> createState() => _AddToPlaylistScreenState();
}

class _AddToPlaylistScreenState extends State<AddToPlaylistScreen> {
  Map<String, List<Map<String, dynamic>>> playlists = {};

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    playlists = await PlaylistManager.loadPlaylists();
    setState(() {});
  }

  Future<void> _addTo(String playlistName) async {
    await PlaylistManager.addSong(playlistName, widget.song);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to $playlistName")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add to Playlist")),
      body: playlists.isEmpty
          ? const Center(child: Text("No playlists available."))
          : ListView.builder(
        itemCount: playlists.length,
        itemBuilder: (_, i) {
          final name = playlists.keys.elementAt(i);
          return ListTile(
            title: Text(name),
            trailing: const Icon(Icons.add),
            onTap: () => _addTo(name),
          );
        },
      ),
    );
  }
}
