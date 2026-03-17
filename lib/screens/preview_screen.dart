import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../widgets/polaroid_widget.dart';
import 'home_screen.dart';

class PreviewScreen extends StatefulWidget {
  final Uint8List photoBytes;
  final String qrData;
  final String dateText;

  const PreviewScreen({
    super.key,
    required this.photoBytes,
    required this.qrData,
    required this.dateText,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;
  bool _saved = false;

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      // 고해상도로 캡처 (3배율 = 실제 화면보다 3배 크게)
      final bytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (bytes == null) throw Exception('이미지 캡처에 실패했습니다.');

      await Gal.putImageBytes(bytes, album: 'QRpicture');

      setState(() {
        _isSaving = false;
        _saved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('갤러리에 저장되었습니다!'),
              ],
            ),
            backgroundColor: Color(0xFF5C7A00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final polaroidWidth = MediaQuery.of(context).size.width * 0.72;
    return Scaffold(
      appBar: AppBar(
        title: const Text('완성!'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              );
            },
            child: const Text(
              '홈으로',
              style: TextStyle(color: Color(0xFF5C4000), fontSize: 15),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'QR 사진이 완성되었습니다!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C4000),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'QR 코드를 스캔하면 목소리를 들을 수 있어요',
              style: TextStyle(fontSize: 13, color: Color(0xFF9B8C6C)),
            ),
            const SizedBox(height: 28),
            // 폴라로이드 미리보기 (여기서 스크린샷 캡처)
            Expanded(
              child: Center(
                child: Screenshot(
                  controller: _screenshotController,
                  child: PolaroidWidget(
                    photoBytes: widget.photoBytes,
                    qrData: widget.qrData,
                    dateText: widget.dateText,
                    width: polaroidWidth,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  // 갤러리 저장 버튼
                  ElevatedButton.icon(
                    onPressed: _isSaving || _saved ? null : _saveToGallery,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_saved ? Icons.check : Icons.save_alt),
                    label: Text(
                      _saved ? '저장 완료!' : '갤러리에 저장',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor:
                          _saved ? const Color(0xFF5C7A00) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // QR 안내 텍스트
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6914).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF8B6914),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'QR 코드를 스캔하면 웹 브라우저에서\n녹음한 음성이 바로 재생됩니다.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B6914),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
