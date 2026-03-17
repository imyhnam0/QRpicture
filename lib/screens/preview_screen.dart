import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import '../l10n/app_strings.dart';
import '../models/layout_type.dart';
import '../widgets/polaroid_widget.dart';
import '../widgets/layout_widgets.dart';
import 'home_screen.dart';

class PreviewScreen extends StatefulWidget {
  final List<Uint8List> photos;
  final LayoutType layoutType;
  final String qrData;
  final String dateText;

  const PreviewScreen({
    super.key,
    required this.photos,
    required this.layoutType,
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
      final bytes = await _screenshotController.capture(pixelRatio: 3.0);
      if (bytes == null) throw Exception(S.errCapture);

      await Gal.putImageBytes(bytes, album: 'QRpicture');

      setState(() {
        _isSaving = false;
        _saved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(S.savedToGallery),
              ],
            ),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.saveFailed('$e')),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPreviewWidget(double screenWidth) {
    switch (widget.layoutType) {
      case LayoutType.single:
        return PolaroidWidget(
          photoBytes: widget.photos[0],
          qrData: widget.qrData,
          dateText: widget.dateText,
          width: screenWidth * 0.72,
        );
      case LayoutType.strip4:
        return Strip4Widget(
          photos: widget.photos,
          qrData: widget.qrData,
          dateText: widget.dateText,
          width: screenWidth * 0.50,
        );
      case LayoutType.grid2x2:
        return Grid2x2Widget(
          photos: widget.photos,
          qrData: widget.qrData,
          dateText: widget.dateText,
          width: screenWidth * 0.78,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.complete),
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
            child: Text(
              S.goHome,
              style: const TextStyle(color: Colors.black, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              S.qrPhotoReady,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.scanToListen,
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: _buildPreviewWidget(screenWidth),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
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
                      _saved ? S.saved : S.saveToGallery,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            S.scanQrInfo,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
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
