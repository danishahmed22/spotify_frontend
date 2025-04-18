import 'package:flutter/material.dart';
import 'package:music/playlist_manager.dart';
import 'package:music/select_song_for_playlist.dart';

import 'audio_manager.dart';
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Map<String, dynamic>> songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final data = await PlaylistManager.loadPlaylists();
    songs = data[widget.playlistName] ?? [];
    setState(() {});
  }

  Future<void> _removeSong(int songId) async {
    await PlaylistManager.removeSong(widget.playlistName, songId);
    _loadSongs();
  }

  void _playSong(Map<String, dynamic> song) {
    AudioManager.play(context, song);
  }

  Future<void> _navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectSongForPlaylistScreen(playlistName: widget.playlistName),
      ),
    );
    _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlistName)),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
      body: songs.isEmpty
          ? const Center(child: Text("No songs in this playlist"))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final song = songs[i];
          return ListTile(
            tileColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.music_note),
            title: Text(song['title']),
            subtitle: Text(song['artist'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeSong(song['id']),
            ),
            onTap: () => _playSong(song),
          );
        },
      ),
    );
  }
}
