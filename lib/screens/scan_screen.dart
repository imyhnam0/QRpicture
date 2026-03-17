import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/player_service.dart';
import 'player_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final PlayerService _playerService = PlayerService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _hasNavigated = false;
  bool _isAnalyzing = false;
  String? _galleryError;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // ─── QR 감지 처리 ─────────────────────────────────────────────

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasNavigated) return;
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null) return;
    _handleQrValue(rawValue);
  }

  void _handleQrValue(String value) {
    if (_hasNavigated) return;

    final uuid = _playerService.extractUuid(value);
    if (uuid == null) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _galleryError = '이 QR 코드는 QR Picture 앱에서 만들어진 것이 아닙니다.';
        });
      }
      return;
    }

    _hasNavigated = true;
    _cameraController.stop();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(uuid: uuid)),
    ).then((_) {
      // 플레이어에서 돌아오면 카메라 재시작
      _hasNavigated = false;
      _galleryError = null;
      _cameraController.start();
    });
  }

  // ─── 갤러리 QR 스캔 ───────────────────────────────────────────

  Future<void> _scanFromGallery() async {
    setState(() {
      _isAnalyzing = true;
      _galleryError = null;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) {
        setState(() => _isAnalyzing = false);
        return;
      }

      // MobileScanner로 이미지 내 QR 분석
      final result = await _cameraController.analyzeImage(image.path);

      if (result == null || result.barcodes.isEmpty) {
        setState(() {
          _isAnalyzing = false;
          _galleryError = 'QR 코드를 찾을 수 없습니다. 다른 사진을 선택해 보세요.';
        });
        return;
      }

      final rawValue = result.barcodes.first.rawValue;
      if (rawValue == null) {
        setState(() {
          _isAnalyzing = false;
          _galleryError = 'QR 코드 값을 읽을 수 없습니다.';
        });
        return;
      }

      setState(() => _isAnalyzing = false);
      _handleQrValue(rawValue);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _galleryError = '이미지 분석 중 오류가 발생했습니다.';
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 뷰
          MobileScanner(
            controller: _cameraController,
            onDetect: _onBarcodeDetected,
          ),

          // 스캔 오버레이
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // 상단 바
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'QR 스캔',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // 손전등 버튼
                  IconButton(
                    onPressed: () => _cameraController.toggleTorch(),
                    icon: ValueListenableBuilder(
                      valueListenable: _cameraController,
                      builder: (context, state, child) {
                        return Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: state.torchState == TorchState.on
                              ? Colors.amber
                              : Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 안내 텍스트 (스캔 프레임 아래)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 260), // 프레임 크기만큼 내려가기
                const SizedBox(height: 20),
                const Text(
                  'QR 코드를 프레임 안에 위치시켜 주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // 하단 버튼 영역
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_galleryError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[800]!.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _galleryError!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _galleryError = null),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),

                    // 갤러리에서 선택 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _scanFromGallery,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _isAnalyzing ? '분석 중...' : '갤러리에서 QR 사진 선택',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                                color: Colors.white38, width: 1),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 스캔 오버레이 ────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 240.0;
    const cornerLen = 26.0;
    const cornerRadius = 3.0;

    final centerX = size.width / 2;
    // 약간 위쪽에 프레임 위치
    final centerY = size.height * 0.44;

    final scanRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scanSize,
      height: scanSize,
    );

    // 반투명 어두운 오버레이 (가운데 구멍)
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              scanRect,
              const Radius.circular(cornerRadius),
            ),
          ),
      ),
      overlayPaint,
    );

    // 코너 마커
    final cornerPaint = Paint()
      ..color = const Color(0xFFF5E6C0)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 좌상단
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLen)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLen, scanRect.top),
      cornerPaint,
    );
    // 우상단
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLen),
      cornerPaint,
    );
    // 좌하단
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLen)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLen, scanRect.bottom),
      cornerPaint,
    );
    // 우하단
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
