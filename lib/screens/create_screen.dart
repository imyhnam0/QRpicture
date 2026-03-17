import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:just_audio/just_audio.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/layout_type.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/polaroid_widget.dart';
import '../widgets/layout_widgets.dart';
import 'preview_screen.dart';

enum _Step { selectPhoto, recordAudio, processing }

class CreateScreen extends StatefulWidget {
  final LayoutType layoutType;

  const CreateScreen({super.key, required this.layoutType});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  _Step _step = _Step.selectPhoto;
  late List<Uint8List?> _photos;

  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration? _playbackDuration;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  double _uploadProgress = 0;
  String? _errorMessage;

  final String _dateText = DateFormat('yyyy.MM.dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _photos = List.filled(widget.layoutType.photoCount, null);

    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        }
      });
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _playbackPosition = pos);
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _playbackDuration = dur);
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // ─── 사진 선택 (크롭 포함) ────────────────────────────────────

  Future<void> _pickImage(int slotIndex) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      final (double ratioX, double ratioY) = _cropAspectRatio();

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: S.cropPhoto,
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: S.cropPhoto,
            aspectRatioLockEnabled: true,
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile == null) return;
      final bytes = await croppedFile.readAsBytes();
      setState(() => _photos[slotIndex] = bytes);
    } catch (e) {
      _showError(S.errLoadPhoto);
    }
  }

  (double, double) _cropAspectRatio() {
    switch (widget.layoutType) {
      case LayoutType.single:
        return (1, 1);
      case LayoutType.strip4:
        return (5, 3);
      case LayoutType.grid2x2:
        return (1, 1);
    }
  }

  bool get _canProceedToRecord => _photos.every((p) => p != null);

  int get _filledCount => _photos.where((p) => p != null).length;

  // ─── 음성 녹음 ────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isPlaying) await _audioService.stopPlayback();
    final hasPermission = await _audioService.hasPermission();
    if (!hasPermission) {
      _showError(S.errMicPermission);
      return;
    }
    try {
      await _audioService.startRecording();
      _recordingSeconds = 0;
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
      setState(() {
        _isRecording = true;
        _hasRecording = false;
      });
    } catch (e) {
      _showError(S.errStartRecording);
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
        _playbackPosition = Duration.zero;
        _playbackDuration = null;
      });
    } catch (e) {
      _showError(S.errSaveRecording);
    }
  }

  Future<void> _togglePlayPreview() async {
    try {
      if (_isPlaying) {
        await _audioService.pausePlayback();
      } else {
        final dur = _playbackDuration;
        final isEnded = dur != null &&
            _playbackPosition.inMilliseconds >= dur.inMilliseconds - 100;
        if (isEnded || _playbackPosition == Duration.zero) {
          await _audioService.playRecording();
        } else {
          await _audioService.resumePlayback();
        }
      }
    } catch (e) {
      _showError(S.errPlayback);
    }
  }

  void _resetRecording() {
    _recordingTimer?.cancel();
    if (_isPlaying) _audioService.stopPlayback();
    _audioService.clearRecording();
    setState(() {
      _isRecording = false;
      _hasRecording = false;
      _recordingSeconds = 0;
      _isPlaying = false;
      _playbackPosition = Duration.zero;
      _playbackDuration = null;
    });
  }

  // ─── 업로드 및 처리 ───────────────────────────────────────────

  Future<void> _processAndCreate() async {
    setState(() {
      _step = _Step.processing;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      final result = await _storageService.uploadAudio(
        _audioService.recordedPath!,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            photos: _photos.whereType<Uint8List>().toList(),
            layoutType: widget.layoutType,
            qrData: result.qrUrl,
            dateText: _dateText,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.recordAudio;
        _errorMessage = S.errUpload;
      });
    }
  }

  // ─── 유틸 ─────────────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.createTitle(widget.layoutType.displayName)),
        leading: _step != _Step.processing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_step == _Step.recordAudio) {
                    _resetRecording();
                    setState(() => _step = _Step.selectPhoto);
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
      ),
      body: switch (_step) {
        _Step.selectPhoto => _buildSelectPhotoStep(),
        _Step.recordAudio => _buildRecordAudioStep(),
        _Step.processing => _buildProcessingStep(),
      },
    );
  }

  // ─── Step 1: 사진 선택 ────────────────────────────────────────

  Widget _buildSelectPhotoStep() {
    return SafeArea(
      child: Column(
        children: [
          _buildStepIndicator(0),
          const SizedBox(height: 8),
          Text(
            widget.layoutType == LayoutType.single
                ? S.selectPhoto
                : S.selectPhotos(widget.layoutType.photoCount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (widget.layoutType != LayoutType.single) ...[
            const SizedBox(height: 4),
            Text(
              S.photoProgress(_filledCount, widget.layoutType.photoCount),
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: _buildPhotoEditor(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                if (widget.layoutType == LayoutType.single)
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(0),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(S.selectFromGallery),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Colors.black),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (widget.layoutType == LayoutType.single)
                  const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _canProceedToRecord
                      ? () => setState(() => _step = _Step.recordAudio)
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(
                    S.nextRecord,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEditor() {
    final screenWidth = MediaQuery.of(context).size.width;
    switch (widget.layoutType) {
      case LayoutType.single:
        return Center(
          child: GestureDetector(
            onTap: () => _pickImage(0),
            child: PolaroidWidget(
              photoBytes: _photos[0],
              dateText: _dateText,
              width: screenWidth * 0.62,
            ),
          ),
        );
      case LayoutType.strip4:
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Strip4Widget(
              photos: _photos,
              dateText: _dateText,
              width: screenWidth * 0.52,
              onTapPhoto: _pickImage,
            ),
          ),
        );
      case LayoutType.grid2x2:
        return Center(
          child: Grid2x2Widget(
            photos: _photos,
            dateText: _dateText,
            width: screenWidth * 0.78,
            onTapPhoto: _pickImage,
          ),
        );
    }
  }

  // ─── Step 2: 음성 녹음 ────────────────────────────────────────

  Widget _buildRecordAudioStep() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Column(
        children: [
          _buildStepIndicator(1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Text(
                    S.recordYourVoice,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.28,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: _buildAudioStepPreview(screenWidth),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRecordingStatus(),
                  const SizedBox(height: 16),
                  _buildRecordButton(),
                  const SizedBox(height: 12),
                  if (_hasRecording && !_isRecording) _buildPlaybackUI(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ElevatedButton(
              onPressed:
                  _hasRecording && !_isRecording ? _processAndCreate : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(
                S.createQrPhoto,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioStepPreview(double screenWidth) {
    final w = screenWidth * 0.52;
    switch (widget.layoutType) {
      case LayoutType.single:
        return PolaroidWidget(
          photoBytes: _photos[0],
          dateText: _dateText,
          width: w,
        );
      case LayoutType.strip4:
        return Strip4Widget(
          photos: _photos,
          dateText: _dateText,
          width: w,
        );
      case LayoutType.grid2x2:
        return Grid2x2Widget(
          photos: _photos,
          dateText: _dateText,
          width: w,
        );
    }
  }

  Widget _buildRecordingStatus() {
    if (_isRecording) {
      return Column(
        children: [
          Text(
            _formatDuration(_recordingSeconds),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCC0000),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFCC0000),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                S.recording,
                style:
                    const TextStyle(color: Color(0xFFCC0000), fontSize: 13),
              ),
            ],
          ),
        ],
      );
    } else if (_hasRecording) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.black,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            S.recordingDone(_formatDuration(_recordingSeconds)),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return Text(
        S.pressToRecord,
        style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
      );
    }
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isRecording ? const Color(0xFFCC0000) : Colors.black,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? const Color(0xFFCC0000) : Colors.black)
                  .withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildPlaybackUI() {
    final durMs = (_playbackDuration?.inMilliseconds ?? 0).toDouble();
    final posMs = _playbackPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, durMs > 0 ? durMs : 1.0);
    final progress = durMs > 0 ? posMs / durMs : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFDDDDDD),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(_playbackPosition.inSeconds),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Text(
              ' / ',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            Text(
              _playbackDuration != null
                  ? _formatDuration(_playbackDuration!.inSeconds)
                  : '--:--',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _togglePlayPreview,
              icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 22,
              ),
              label: Text(_isPlaying ? S.pause : S.preview),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 20),
            TextButton.icon(
              onPressed: _resetRecording,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(S.reRecord),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 3: 처리 중 ──────────────────────────────────────────

  Widget _buildProcessingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              color: Colors.black,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              S.uploading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            if (_uploadProgress > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 단계 표시 ────────────────────────────────────────────────

  Widget _buildStepIndicator(int current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: [
          _buildStepDot(0, S.stepPhoto, current),
          _buildStepLine(current > 0),
          _buildStepDot(1, S.stepRecord, current),
          _buildStepLine(current > 1),
          _buildStepDot(2, S.stepDone, current),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label, int current) {
    final isActive = step == current;
    final isDone = step < current;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDone || isActive ? Colors.black : const Color(0xFFDDDDDD),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.black : const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isDone ? Colors.black : const Color(0xFFDDDDDD),
      ),
    );
  }
}
