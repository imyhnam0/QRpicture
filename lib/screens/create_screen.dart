import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/polaroid_widget.dart';
import 'preview_screen.dart';

enum _Step { selectPhoto, recordAudio, processing }

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  _Step _step = _Step.selectPhoto;
  Uint8List? _selectedPhotoBytes;

  bool _isRecording = false;
  bool _hasRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  double _uploadProgress = 0;
  String? _errorMessage;

  final String _dateText = DateFormat('yyyy.MM.dd').format(DateTime.now());

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // ─── 사진 선택 ────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _selectedPhotoBytes = bytes);
    } catch (e) {
      _showError('사진을 불러오는 중 오류가 발생했습니다.');
    }
  }

  // ─── 음성 녹음 ────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioService.hasPermission();
    if (!hasPermission) {
      _showError('마이크 접근 권한이 필요합니다. 설정에서 허용해 주세요.');
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
      _showError('녹음을 시작할 수 없습니다.');
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    try {
      await _audioService.stopRecording();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
    } catch (e) {
      _showError('녹음 저장 중 오류가 발생했습니다.');
    }
  }

  Future<void> _playPreview() async {
    try {
      await _audioService.playRecording();
    } catch (e) {
      _showError('재생 중 오류가 발생했습니다.');
    }
  }

  void _resetRecording() {
    _recordingTimer?.cancel();
    _audioService.clearRecording();
    setState(() {
      _isRecording = false;
      _hasRecording = false;
      _recordingSeconds = 0;
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
            photoBytes: _selectedPhotoBytes!,
            qrData: result.qrUrl,
            dateText: _dateText,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.recordAudio;
        _errorMessage = '업로드에 실패했습니다. 네트워크를 확인하고 다시 시도해 주세요.';
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
        title: const Text('새로 만들기'),
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
    final previewWidth = MediaQuery.of(context).size.width * 0.62;
    return SafeArea(
      child: Column(
        children: [
          _buildStepIndicator(0),
          const SizedBox(height: 8),
          const Text(
            '사진을 선택해 주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C4000),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: PolaroidWidget(
                  photoBytes: _selectedPhotoBytes,
                  dateText: _dateText,
                  width: previewWidth,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('갤러리에서 선택'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Color(0xFF8B6914)),
                    foregroundColor: const Color(0xFF8B6914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectedPhotoBytes != null
                      ? () => setState(() => _step = _Step.recordAudio)
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text(
                    '다음: 음성 녹음',
                    style: TextStyle(
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

  // ─── Step 2: 음성 녹음 ────────────────────────────────────────

  Widget _buildRecordAudioStep() {
    final previewWidth = MediaQuery.of(context).size.width * 0.38;
    return SafeArea(
      child: Column(
        children: [
          _buildStepIndicator(1),
          const SizedBox(height: 8),
          const Text(
            '목소리를 녹음해 주세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C4000),
            ),
          ),
          const SizedBox(height: 20),
          // 작은 폴라로이드 미리보기
          PolaroidWidget(
            photoBytes: _selectedPhotoBytes,
            dateText: _dateText,
            width: previewWidth,
          ),
          const SizedBox(height: 28),
          // 녹음 상태 표시
          _buildRecordingStatus(),
          const SizedBox(height: 20),
          // 녹음 버튼
          _buildRecordButton(),
          const SizedBox(height: 16),
          // 재생/재녹음 버튼
          if (_hasRecording && !_isRecording) _buildPlaybackButtons(),
          const Spacer(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ElevatedButton(
              onPressed: _hasRecording && !_isRecording
                  ? _processAndCreate
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'QR 사진 만들기',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
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
              const Text(
                '녹음 중...',
                style: TextStyle(color: Color(0xFFCC0000), fontSize: 13),
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
            color: Color(0xFF5C7A00),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            '녹음 완료  ${_formatDuration(_recordingSeconds)}',
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5C7A00),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      return const Text(
        '버튼을 눌러 녹음을 시작하세요',
        style: TextStyle(color: Color(0xFF9B8C6C), fontSize: 14),
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
          color: _isRecording
              ? const Color(0xFFCC0000)
              : const Color(0xFF8B6914),
          boxShadow: [
            BoxShadow(
              color: (_isRecording
                      ? const Color(0xFFCC0000)
                      : const Color(0xFF8B6914))
                  .withValues(alpha: 0.4),
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

  Widget _buildPlaybackButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: _playPreview,
          icon: const Icon(Icons.play_circle_outline, size: 20),
          label: const Text('미리 듣기'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF5C7A00),
          ),
        ),
        const SizedBox(width: 20),
        TextButton.icon(
          onPressed: _resetRecording,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('다시 녹음'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9B8C6C),
          ),
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
              color: const Color(0xFF8B6914),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              '음성을 업로드하고\nQR 코드를 생성하는 중입니다...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5C4000),
                height: 1.5,
              ),
            ),
            if (_uploadProgress > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9B8C6C),
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
          _buildStepDot(0, '사진', current),
          _buildStepLine(current > 0),
          _buildStepDot(1, '녹음', current),
          _buildStepLine(current > 1),
          _buildStepDot(2, '완성', current),
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
            color: isDone || isActive
                ? const Color(0xFF8B6914)
                : const Color(0xFFDDD5C0),
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
            color: isActive
                ? const Color(0xFF8B6914)
                : const Color(0xFFB0A080),
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
        color: isDone ? const Color(0xFF8B6914) : const Color(0xFFDDD5C0),
      ),
    );
  }
}
