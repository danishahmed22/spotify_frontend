import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

late final AudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      playing: _player.playing,
      processingState: AudioProcessingState.ready,
      updatePosition: _player.position,
    );
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'loadAndPlay') {
      final url = extras?['url'];
      final title = extras?['title'];
      final artist = extras?['artist'];
      final media = MediaItem(
        id: url,
        title: title ?? '',
        artist: artist ?? '',
        duration: const Duration(minutes: 3),
      );
      mediaItem.add(media);
      await _player.setUrl(url);
      await _player.play();
    } else if (name == 'setSpeed') {
      final speed = extras?['speed'];
      if (speed != null) await _player.setSpeed(speed);
    }
  }
}
