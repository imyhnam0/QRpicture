import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _recordedPath;
  String? get recordedPath => _recordedPath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_recording.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
  }

  Future<String?> stopRecording() async {
    _recordedPath = await _recorder.stop();
    return _recordedPath;
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<void> playRecording() async {
    if (_recordedPath == null) return;
    if (_player.playing) {
      await _player.stop();
    }
    await _player.setFilePath(_recordedPath!);
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> pausePlayback() async {
    await _player.pause();
  }

  Future<void> resumePlayback() async {
    await _player.play();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  bool get isPlaying => _player.playing;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void clearRecording() {
    if (_recordedPath != null) {
      final file = File(_recordedPath!);
      if (file.existsSync()) file.deleteSync();
    }
    _recordedPath = null;
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
