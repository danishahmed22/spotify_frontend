import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_player_handler.dart';

class SongDetailScreen extends StatefulWidget {
  final Map<String, dynamic> song;
  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  double speed = 1.0;

  @override
  Widget build(BuildContext context) {
    final title = widget.song['title'];
    final artist = widget.song['artist'];

    return Scaffold(
      appBar: AppBar(title: const Text("Now Playing")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.deepPurple,
              child: Text(title[0].toUpperCase(), style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("by $artist"),
            const Spacer(),

            // Smooth slider
            StreamBuilder<Duration>(
              stream: Rx.combineLatest2<PlaybackState, int, Duration>(
                audioHandler.playbackState,
                Stream.periodic(const Duration(milliseconds: 500), (_) => 0),
                    (state, _) => state.updatePosition,
              ),
              builder: (_, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final total = audioHandler.mediaItem.value?.duration ?? const Duration(minutes: 3);
                return Column(
                  children: [
                    Slider(
                      value: position.inSeconds.toDouble().clamp(0, total.inSeconds.toDouble()),
                      min: 0,
                      max: total.inSeconds.toDouble(),
                      onChanged: (val) {
                        audioHandler.seek(Duration(seconds: val.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(position)),
                        Text(_format(total)),
                      ],
                    ),
                  ],
                );
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final pos = audioHandler.playbackState.value.updatePosition;
                    audioHandler.seek(pos - const Duration(seconds: 10));
                  },
                ),
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (_, snapshot) {
                    final isPlaying = snapshot.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                      iconSize: 50,
                      onPressed: () {
                        isPlaying ? audioHandler.pause() : audioHandler.play();
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final pos = audioHandler.playbackState.value.updatePosition;
                    audioHandler.seek(pos + const Duration(seconds: 10));
                  },
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Speed: "),
                DropdownButton<double>(
                  value: speed,
                  items: [0.5, 1.0, 1.5, 2.0].map((s) => DropdownMenuItem(value: s, child: Text("${s}x"))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => speed = val);
                      audioHandler.customAction('setSpeed', {'speed': val});
                    }
                  },
                )
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}
