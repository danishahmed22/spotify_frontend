import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music/song_detail_screen.dart';

import 'audio_player_handler.dart';

class AudioManager {
  static Map<String, dynamic>? currentSong;

  static final _notifier = ValueNotifier<int>(0);
  static ValueNotifier<int> get notifier => _notifier;

  static void notifyListeners() => _notifier.value++;

  static Future<void> play(BuildContext context, Map<String, dynamic> song) async {
    currentSong = song;
    notifyListeners();
    await audioHandler.customAction('loadAndPlay', {
      'url': "http://127.0.0.1:8000/songs/stream/${song['id']}",
      'title': song['title'],
      'artist': song['artist'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
    );
  }

  static void toggle() {
    final isPlaying = audioHandler.playbackState.value.playing;
    isPlaying ? audioHandler.pause() : audioHandler.play();
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AudioManager.notifier,
      builder: (_, __, ___) {
        final song = AudioManager.currentSong;
        if (song == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
            );
          },
          child: Container(
            color: Colors.deepPurple.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.music_note),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("${song['title']} - ${song['artist']}",
                      overflow: TextOverflow.ellipsis),
                ),
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (_, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return IconButton(
                      onPressed: AudioManager.toggle,
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
