import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../l10n/app_strings.dart';
import '../services/player_service.dart';

class PlayerScreen extends StatefulWidget {
  final String uuid;

  const PlayerScreen({super.key, required this.uuid});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final PlayerService _playerService = PlayerService();

  late final AnimationController _pulseController;

  bool _isLoading = true;
  String? _error;
  AudioInfo? _audioInfo;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadAudio();
  }

  @override
  void dispose() {
    _player.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    try {
      final info = await _playerService.fetchAudioInfo(widget.uuid);
      if (info == null) {
        setState(() {
          _isLoading = false;
          _error = S.audioNotFound;
        });
        return;
      }

      _audioInfo = info;
      await _player.setUrl(info.url);

      setState(() {
        _isLoading = false;
        _totalDuration = _player.duration ?? Duration.zero;
      });

      _player.durationStream.listen((d) {
        if (d != null && mounted) {
          setState(() => _totalDuration = d);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = S.errLoadAudio;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: Text(S.voiceMessage),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _player.stop();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _error != null
            ? _buildError()
            : _buildPlayer(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF8B6914)),
          const SizedBox(height: 20),
          Text(
            S.loadingAudio,
            style: const TextStyle(color: Color(0xFF9B8C6C), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFCC4444)),
            const SizedBox(height: 20),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF5C4000),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: Text(S.goBack),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8B6914),
                side: const BorderSide(color: Color(0xFF8B6914)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_audioInfo?.previewImageUrl != null) ...[
            _buildPreviewCard(),
            const SizedBox(height: 28),
          ],
          _buildMicIcon(),
          const SizedBox(height: 28),
          if (_audioInfo?.createdAt != null)
            Text(
              S.dateFormat(_audioInfo!.createdAt!),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9B8C6C),
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            S.voiceMessage,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C4000),
            ),
          ),
          const SizedBox(height: 40),
          _buildProgressBar(),
          const SizedBox(height: 6),
          _buildTimeRow(),
          const SizedBox(height: 36),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.photoPreview,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C4000),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: Image.network(
                _audioInfo!.previewImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFEEEEEE),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFFBDBDBD),
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicIcon() {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isPlaying ? 1.0 + _pulseController.value * 0.07 : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPlaying
                        ? [const Color(0xFFA07820), const Color(0xFF8B6914)]
                        : [const Color(0xFFD0C0A0), const Color(0xFFB8A880)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF8B6914,
                      ).withValues(alpha: isPlaying ? 0.35 : 0.15),
                      blurRadius: isPlaying ? 20 : 8,
                      spreadRadius: isPlaying ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying ? Icons.graphic_eq : Icons.mic,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = _totalDuration;
        final progress = total.inMilliseconds > 0
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF8B6914),
            inactiveTrackColor: const Color(0xFFD8CCB0),
            thumbColor: const Color(0xFF8B6914),
            overlayColor: const Color(0xFF8B6914).withValues(alpha: 0.15),
          ),
          child: Slider(
            value: progress,
            onChanged: total.inMilliseconds > 0
                ? (value) {
                    final pos = Duration(
                      milliseconds: (value * total.inMilliseconds).toInt(),
                    );
                    _player.seek(pos);
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTimeRow() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9B8C6C)),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9B8C6C)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.playing ?? false;
        final isCompleted = state?.processingState == ProcessingState.completed;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _player.seek(Duration.zero),
              icon: const Icon(Icons.replay, size: 30),
              color: const Color(0xFF9B8C6C),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                if (isCompleted) {
                  _player.seek(Duration.zero);
                  _player.play();
                } else if (isPlaying) {
                  _player.pause();
                } else {
                  _player.play();
                }
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF8B6914),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x558B6914),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isCompleted
                      ? Icons.replay
                      : isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: () {
                final current = _player.position + const Duration(seconds: 5);
                _player.seek(current);
              },
              icon: const Icon(Icons.forward_5, size: 30),
              color: const Color(0xFF9B8C6C),
            ),
          ],
        );
      },
    );
  }
}
