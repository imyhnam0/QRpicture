import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
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
          _error = '음성 데이터를 찾을 수 없습니다.\nQR 코드가 올바른지 확인해 주세요.';
        });
        return;
      }

      _audioInfo = info;
      await _player.setUrl(info.url);

      setState(() {
        _isLoading = false;
        _totalDuration = _player.duration ?? Duration.zero;
      });

      // duration이 늦게 로드될 경우 대비
      _player.durationStream.listen((d) {
        if (d != null && mounted) {
          setState(() => _totalDuration = d);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '음성을 불러오지 못했습니다.\n네트워크 연결을 확인해 주세요.';
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
        title: const Text('목소리 메시지'),
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

  // ─── 로딩 ────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF8B6914)),
          SizedBox(height: 20),
          Text(
            '음성을 불러오는 중...',
            style: TextStyle(color: Color(0xFF9B8C6C), fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ─── 오류 ────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFCC4444),
            ),
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
              label: const Text('돌아가기'),
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

  // ─── 플레이어 ────────────────────────────────────────────────

  Widget _buildPlayer() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          _buildMicIcon(),
          const SizedBox(height: 28),

          // 날짜
          if (_audioInfo?.createdAt != null)
            Text(
              DateFormat('yyyy년 M월 d일').format(_audioInfo!.createdAt!),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9B8C6C),
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            '목소리 메시지',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C4000),
            ),
          ),
          const SizedBox(height: 40),

          // 프로그레스 바
          _buildProgressBar(),
          const SizedBox(height: 6),

          // 시간 표시
          _buildTimeRow(),
          const SizedBox(height: 36),

          // 재생 컨트롤
          _buildControls(),
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
            final scale = isPlaying
                ? 1.0 + _pulseController.value * 0.07
                : 1.0;
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
                      color: const Color(0xFF8B6914)
                          .withValues(alpha: isPlaying ? 0.35 : 0.15),
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
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF8B6914),
            inactiveTrackColor: const Color(0xFFD8CCB0),
            thumbColor: const Color(0xFF8B6914),
            overlayColor:
                const Color(0xFF8B6914).withValues(alpha: 0.15),
          ),
          child: Slider(
            value: progress,
            onChanged: total.inMilliseconds > 0
                ? (value) {
                    final pos = Duration(
                      milliseconds:
                          (value * total.inMilliseconds).toInt(),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9B8C6C),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9B8C6C),
                ),
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
        final isCompleted =
            state?.processingState == ProcessingState.completed;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 처음으로 버튼
            IconButton(
              onPressed: () => _player.seek(Duration.zero),
              icon: const Icon(Icons.replay, size: 30),
              color: const Color(0xFF9B8C6C),
            ),
            const SizedBox(width: 20),

            // 재생/일시정지 버튼
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

            // 5초 앞으로
            IconButton(
              onPressed: () {
                final current =
                    _player.position + const Duration(seconds: 5);
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
